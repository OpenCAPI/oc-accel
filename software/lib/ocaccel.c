/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>
#include <endian.h>
#include <sys/time.h>
#include <malloc.h>
#include <ctype.h>

#include <libocaccel.h>
#include <libocxl.h>
#include <ocaccel_global_regs.h>
#include <ocaccel_internal.h>


/* Trace hardware implementation */
static unsigned int ocaccel_trace = 0x0;

int ocaccel_lib_trace_enabled (void)
{
    return ocaccel_trace & 0x0001;
}

int ocaccel_action_trace_enabled (void)
{
    return ocaccel_trace & 0x0080;
}

union ocaccel_capability {
    uint64_t reg;
    struct capability {
        uint8_t card_type;
        uint8_t action_template;
        uint8_t infra_template;
        uint8_t kernel_num;
        uint8_t capi_ver;
        uint8_t other1;
        uint16_t other2;
    } fields;
};

union action_name {
    char name[8];
    uint64_t reg;
};

union kernel_name {
    char name[4];
    uint32_t reg;
};

struct ocaccel_card {
    ocxl_afu_h afu_h;
    ocxl_endian mmio_endian;
    ocxl_mmio_h mmio_global;
    ocxl_mmio_h mmio_per_pasid;

    uint16_t vendor_id;
    uint16_t device_id;
    int afu_fd;

    size_t errinfo_size;
    void* errinfo;
    ocxl_event event;
    ocxl_irq_h afu_irq;
    uint64_t irq_ea;
    union ocaccel_capability cap;
    const char* name;
    char action_name[33]; // TODO: 32 characters from 4 64-bit registers with 1 extra '\0'
};

/* Translate Card ID to Name */
struct card_2_name {
    const int card_id;
    const char card_name[16];
};

/* Limit Card names to max of 15 Bytes */
struct card_2_name ocaccel_card_2_name_tab[] = {
    {.card_id = AD9V3_OC_CARD,  .card_name = "AD9V3"},
    {.card_id = AD9H3_OC_CARD,  .card_name = "AD9H3"},
    {.card_id = AD9H7_OC_CARD,  .card_name = "AD9H7"},
    {.card_id = -1,             .card_name = "INVALID"}
};

static const char* ocaccel_trim_str (char* str)
{
    char* end;

    // Trim leading space
    while (isspace ((unsigned char)*str)) {
        str++;
    }

    if (*str == 0) { // All spaces?
        return str;
    }

    // Trim trailing space
    end = str + strlen (str) - 1;

    while (end > str && isspace ((unsigned char)*end)) {
        end--;
    }

    // Write new null terminator character
    end[1] = '\0';

    return str;
}

/* Search ocaccel_card_2_name_tab to for card name */
static const char* ocaccel_card_id_2_name (int card_id)
{
    int i = 0;

    while (-1 != ocaccel_card_2_name_tab[i].card_id) {
        if (card_id == ocaccel_card_2_name_tab[i].card_id) {
            break;
        }

        i++;
    }

    /* Return card name */
    return ocaccel_card_2_name_tab[i].card_name;
}

static void* hw_ocaccel_card_alloc_dev (const char* path,
                                        uint16_t vendor_id,
                                        uint16_t device_id)
{
    struct ocaccel_card* dn;
    union action_name act_name;
    uint64_t reg;
    int rc;
    int i;
    ocxl_err err;

    dn = calloc (1, sizeof (*dn));

    if (NULL == dn) {
        goto __ocaccel_alloc_err;
    }

    ocaccel_lib_trace ("%s Enter %s\n", __func__, path);

    // Device path, two choices:
    // /dev/ocxl/IBM,oc-snap.0007:00:00.1.0
    // IBM,oc-snap
    if (strstr ((char*)path, "ocxl") == NULL) {
        err = ocxl_afu_open ((char*)path, &dn->afu_h);    //open by simple name
    } else {
        err = ocxl_afu_open_from_dev ((char*)path, &dn->afu_h);    //open by device path
    }


    if (err != OCXL_OK) {
        goto __ocaccel_alloc_err;
    }

    dn->vendor_id = vendor_id;
    dn->device_id = device_id;

    //Create Err Buffer (not used)
    dn->errinfo = NULL;
    dn->errinfo_size = 0;
    ocaccel_lib_trace ("  %s: errinfo_size: %d VendorID: %x DeviceID: %x\n", __func__,
                       (int)dn->errinfo_size, (int)vendor_id, (int)device_id);

    //Set afu handle and call ocxl attach
    dn->afu_fd = ocxl_afu_get_event_fd (dn->afu_h);
    rc = ocxl_afu_attach (dn->afu_h, 0);

    if (0 != rc) {
        goto __ocaccel_alloc_err;
    }

    //mmap
    dn->mmio_endian = OCXL_MMIO_HOST_ENDIAN;

    if (ocxl_mmio_map (dn->afu_h, OCXL_PER_PASID_MMIO, &dn->mmio_per_pasid) == -1) {
        ocaccel_lib_trace ("  %s: Error Can not mmap\n", __func__);
        goto __ocaccel_alloc_err;
    }

    if (ocxl_mmio_map (dn->afu_h, OCXL_GLOBAL_MMIO, &dn->mmio_global) == -1) {
        ocaccel_lib_trace ("  %s: Error Can not mmap\n", __func__);
        goto __ocaccel_alloc_err;
    }

    ocaccel_lib_trace ("mmio_mapped\n");


    // Read and save Capability reg
    ocxl_mmio_read64 (dn->mmio_global, OCACCEL_REG_CAPABILITY, dn->mmio_endian, &reg);
    dn->cap.reg = reg;
    // Get OCACCEL Card Name
    dn->name = ocaccel_card_id_2_name ((int) (dn->cap.fields.card_type));

    // Read and save the action name
    char tmp_name[33];

    for (i = 0; i < 4; i++) {
        ocxl_mmio_read64 (dn->mmio_global, OCACCEL_REG_ACTION_NAME_STR1 + (i * 8), dn->mmio_endian, &reg);
        act_name.reg = reg;
        memcpy (tmp_name + (i * 8), act_name.name, 8);
    }

    tmp_name[32] = '\0';
    strcpy (dn->action_name, ocaccel_trim_str (tmp_name));

    ocaccel_lib_trace ("%s Exit %p OK Card: %s Action: %s \n", __func__,
                       dn, dn->name, dn->action_name);
    return (struct ocaccel_card*)dn;

__ocaccel_alloc_err:

    if (dn->errinfo) {
        free (dn->errinfo);
    }

    if (dn->afu_h) {
        ocxl_afu_close (dn->afu_h);
    }

    if (dn) {
        free (dn);
    }

    ocaccel_lib_trace ("%s Exit Err\n", __func__);
    return NULL;
}

// Register Access
// Action registers are 32bits and in PER_PASID space
static int hw_mmio_per_pasid_write32 (struct ocaccel_card* card,
                                      uint64_t offset, uint32_t data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        ocaccel_lib_trace ("  %s(%p, %llx, %lx)\n", __func__, card,
                           (long long)offset, (long)data);
        rc = ocxl_mmio_write32 (card->mmio_per_pasid, offset, card->mmio_endian,
                                data);
    } else {
        ocaccel_lib_trace ("  %s Error\n", __func__);
        errno = EINVAL;
    }

    return rc;
}

static int hw_mmio_per_pasid_read32 (struct ocaccel_card* card,
                                     uint64_t offset, uint32_t* data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_read32 (card->mmio_per_pasid, offset, card->mmio_endian,
                               data);
        ocaccel_lib_trace ("  %s(%p, %llx, %lx) %d\n", __func__, card,
                           (long long)offset, (long)*data, rc);
    } else {
        ocaccel_lib_trace ("  %s Error\n", __func__);
        errno = EINVAL;
    }

    return rc;
}

// ocaccel registers are 64bits and in GLOBAL space
static int hw_mmio_global_write64 (struct ocaccel_card* card,
                                   uint64_t offset, uint64_t data)
{
    int rc = -1;

    ocaccel_lib_trace ("  %s(%p, %llx, %llx)\n", __func__, card,
                       (long long)offset, (long long)data);

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_write64 (card->mmio_global, offset, card->mmio_endian,
                                data);
    } else {
        errno = EINVAL;
    }

    return rc;
}

static int hw_mmio_global_read64 (struct ocaccel_card* card,
                                  uint64_t offset, uint64_t* data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_read64 (card->mmio_global, offset, card->mmio_endian,
                               data);
    } else {
        errno = EINVAL;
    }

    ocaccel_lib_trace ("  %s(%p, %llx, %llx) %d\n", __func__, card,
                       (long long)offset, (long long)*data, rc);

    return rc;
}

static void hw_ocaccel_card_free (struct ocaccel_card* card)
{
    if (!card) {
        return;
    }

    if (card->errinfo) {
        free (card->errinfo);
        card->errinfo = NULL;
    }

    if (card->afu_h) {
        ocxl_afu_close (card->afu_h);
        card->afu_h = NULL;
    }

    free (card);
}

//FIXME: irq procedure needs to be revised
static int hw_wait_irq (struct ocaccel_card* card, int timeout_sec/*, int expect_irq*/)
{
    int rc = 0;

    ocaccel_lib_trace ("  %s: Enter fd: %d Timeout: %d sec\n",
                       __func__, card->afu_fd,
                       timeout_sec);

__hw_wait_irq_retry:

    if (!ocxl_afu_event_check (card->afu_h, -1, &card->event, 1)) {
        rc = EINTR;
        ocaccel_lib_trace ("    Timeout......\n");
    } else {
        ocaccel_lib_trace ("    Event is Pending ......\n");
    }

    if (0 == rc) {
        switch (card->event.type) {

        case OCXL_EVENT_IRQ:
            ocaccel_lib_trace ("  %s: OCXL_EVENT_IRQ\n"
                               "      irq=%d,  count=%lld\n", __func__,
                               (int)card->event.irq.irq,
                               (long long)card->event.irq.count);

            // TODO: expect_irq is useless
            //if (expect_irq != card->event.irq.irq) {
            if (card->irq_ea != card->event.irq.handle) {
                ocaccel_lib_trace ("  %s:     Wrong IRQ.. Retry ! Get: %lx, expect: %lx\n", __func__,
                                   card->event.irq.handle, card->irq_ea);
                goto __hw_wait_irq_retry;
            }

            rc = 0;
            break;

        case OCXL_EVENT_TRANSLATION_FAULT: {
            ocxl_event_translation_fault* ds =
                &card->event.translation_fault;

            ocaccel_lib_trace ("  %s: OCXL_EVENT_TRANSLATION_FAULT\n", __func__);
            ocaccel_lib_trace ("      addr=%08llx, dsisr=%08llx\n",
                               (long long)ds->addr,
                               (long long)ds->dsisr);
            rc = EFAULT;
            break;
        }

        default:
            ocaccel_lib_trace ("  %s: AFU_ERROR type=%d\n",
                               __func__, card->event.type);
            rc = EINTR;
            break;
        }
    }

    ocaccel_lib_trace ("  %s: Exit fd: %d rc: %d\n", __func__,
                       card->afu_fd, rc);
    return rc;
}

static int hw_card_ioctl (struct ocaccel_card* card, unsigned int cmd, char* arg)
{
    int rc = 0;
    uint8_t value = 0;

    if (NULL == arg) {
        ocaccel_lib_trace ("  %s Error Missing arg\n", __func__);
        return -1;
    }

    switch (cmd) {
    case GET_CARD_TYPE:
        value = card->cap.fields.card_type;
        ocaccel_lib_trace ("  %s GET CARD_TYPE: %d\n", __func__, (int)value);
        *arg = value;
        break;

    case GET_ACTION_TEMPLATE:
        value = card->cap.fields.action_template;
        ocaccel_lib_trace ("  %s GET ACTION_TEMPLATE: %d\n", __func__, (int)value);
        *arg = value;
        break;

    case GET_INFRA_TEMPLATE:
        value = card->cap.fields.infra_template;
        ocaccel_lib_trace ("  %s GET INFRA_TEMPLATE: %d\n", __func__, (int)value);
        *arg = value;
        break;

    case GET_KERNEL_NUMBER:
        value = card->cap.fields.kernel_num;
        ocaccel_lib_trace ("  %s GET KERNEL_NUMBER: %d\n", __func__, (int)value);
        *arg = value;
        break;

    case GET_CAPI_VERSION:
        value = card->cap.fields.capi_ver;
        ocaccel_lib_trace ("  %s GET CAPI_VERSION: %d\n", __func__, (int)value);
        *arg = value;
        break;

    case GET_CARD_NAME:
        ocaccel_lib_trace ("  %s Get Card name: %s\n", __func__, card->name);
        strcpy ((char*)arg, card->name);
        break;

    case GET_ACTION_NAME:
        ocaccel_lib_trace ("  %s Get Action name: %s\n", __func__, card->action_name);
        strcpy ((char*)arg, card->action_name);
        break;

    default:
        ocaccel_lib_trace ("  %s Invalid CMD %d Error\n", __func__, cmd);
        *arg = 0;
        rc = -1;
        break;
    }

    return rc;
}

/* Hardware version of the lowlevel functions */
static struct ocaccel_funcs hardware_funcs = {
    .card_alloc_dev                        = hw_ocaccel_card_alloc_dev,
    .mmio_per_pasid_write32                = hw_mmio_per_pasid_write32,
    .mmio_per_pasid_read32                 = hw_mmio_per_pasid_read32,
    .mmio_global_write64                   = hw_mmio_global_write64,
    .mmio_global_read64                    = hw_mmio_global_read64,
    .card_free                             = hw_ocaccel_card_free,
    .card_ioctl                            = hw_card_ioctl,
};

/* We access the hardware via this function pointer struct */
static struct ocaccel_funcs* df = &hardware_funcs;

struct ocaccel_card* ocaccel_card_alloc_dev (const char* path,
        uint16_t vendor_id,
        uint16_t device_id)
{
    return df->card_alloc_dev (path, vendor_id, device_id);
}

int ocaccel_action_write32 (struct ocaccel_card* _card,
                            uint64_t offset, uint32_t data)
{
    int rc;
    rc = df->mmio_per_pasid_write32 (_card, offset, data);
    return rc;
}

int ocaccel_action_read32 (struct ocaccel_card* _card,
                           uint64_t offset, uint32_t* data)
{
    int rc;
    rc = df->mmio_per_pasid_read32 (_card, offset, data);
    return rc;
}


int ocaccel_global_write64 (struct ocaccel_card* _card,
                            uint64_t offset, uint64_t data)
{
    int rc;

    rc = df->mmio_global_write64 (_card, offset, data);
    return rc;
}

int ocaccel_global_read64 (struct ocaccel_card* _card,
                           uint64_t offset, uint64_t* data)
{
    int rc;

    rc = df->mmio_global_read64 (_card, offset, data);
    return rc;
}


void ocaccel_card_free (struct ocaccel_card* _card)
{
    df->card_free (_card);
}

int ocaccel_card_ioctl (struct ocaccel_card* _card, unsigned int cmd, char* arg)
{
    return df->card_ioctl (_card, cmd, arg);
}

int ocaccel_action_wait_interrupt (struct ocaccel_card* card, int* rc, int timeout)
{
    int _rc = hw_wait_irq (card, timeout /*, OCACCEL_OCACCEL_KERNEL_IRQ_NUM*/);

    if (NULL != rc) {
        *rc = _rc;
    }

    return _rc;
}

int ocaccel_action_assign_irq (struct ocaccel_card* card, uint32_t action_irq_ea_reg_addr)
{
    int rc = -1;

    ocaccel_lib_trace ("%s: Assign IRQ EA on reg 0x%x\n", __func__, action_irq_ea_reg_addr);

    // TODO: need to discuss if this is the best way to handle IRQ
    rc = ocxl_irq_alloc (card->afu_h, NULL, & (card->afu_irq));

    if (OCXL_OK != rc) {
        ocaccel_lib_trace ("%s: Failed to allocate IRQ handler.\n", __func__);
        return -1;
    }

    // TODO: Need to write EA to AFU's register.
    card->irq_ea = ocxl_irq_get_handle (card->afu_h, card->afu_irq);
    ocaccel_lib_trace ("%s: IRQ EA: %lx.\n", __func__, card->irq_ea);

    ocaccel_action_write32 (card, (action_irq_ea_reg_addr + 4), (uint32_t) ((card->irq_ea & 0xFFFFFFFF00000000) >> 32));
    ocaccel_action_write32 (card, action_irq_ea_reg_addr, (uint32_t) (card->irq_ea & 0x00000000FFFFFFFF));

    return 0;
}

uint32_t ocaccel_action_get_pasid (struct ocaccel_card* card)
{
    return ocxl_afu_get_pasid (card->afu_h);
}

int ocaccel_get_kernel_name (struct ocaccel_card* card, int kernel_id, char* arg)
{
    uint64_t reg_base = OCACCEL_BASE_PER_KERNEL * kernel_id + OCACCEL_BASE_KERNEL_HELPER;
    uint32_t reg = 0;
    char tmp_name[33];
    union kernel_name kern_name;

    for (int i = 0; i < 8; i++) {
        if (ocaccel_action_read32 (card, reg_base + OCACCEL_KERNEL_NAME_STR1 + (i * 4), &reg)) {
            ocaccel_lib_trace ("ERROR: failed to read kernel name register!\n");
            return -1;
        }

        kern_name.reg = reg;
        memcpy (tmp_name + (i * 4), kern_name.name, 4);

        reg = 0;
    }

    tmp_name[32] = '\0';
    strcpy (arg, ocaccel_trim_str (tmp_name));

    return 0;
}

void* ocaccel_malloc (size_t size)
{
    unsigned int page_size = sysconf (_SC_PAGESIZE);
    return memalign (page_size, OCACCEL_ROUND_UP (size, OCACCEL_MEMBUS_WIDTH));
}

unsigned long ocaccel_tget_ms (void)
{
    struct timeval now;
    unsigned long tms;

    gettimeofday (&now, NULL);
    tms = (unsigned long) (now.tv_sec * 1000) +
          (unsigned long) (now.tv_usec / 1000);
    return tms;
}

unsigned long ocaccel_tget_us (void)
{
    struct timeval now;
    unsigned long tus;

    gettimeofday (&now, NULL);
    tus = (unsigned long) (now.tv_sec * 1000000) +
          (unsigned long) (now.tv_usec);
    return tus;
}

/**********************************************************************
 * LIBRARY INITIALIZATION
 *********************************************************************/

static void _init (void) __attribute__ ((constructor));

static void _init (void)
{
    const char* trace_env;

    trace_env = getenv ("OCACCEL_TRACE");

    if (trace_env != NULL) {
        ocaccel_trace = strtol (trace_env, (char**)NULL, 0);
    }
}
