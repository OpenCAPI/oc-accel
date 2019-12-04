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

#include <libosnap.h>
#include <libocxl.h>
#include <osnap_tools.h>
#include <osnap_internal.h>
#include <osnap_queue.h>
#include <osnap_global_regs.h>    /* Include SNAP Core (global) Regs */
#include <osnap_hls_if.h>    /* Include SNAP -> HLS */


/* Trace hardware implementation */
static unsigned int snap_trace = 0x0;

#define snap_trace_enabled()  (snap_trace & 0x0001)
#define reg_trace_enabled()   (snap_trace & 0x0002)
#define sim_trace_enabled()   (snap_trace & 0x0004)
#define poll_trace_enabled()  (snap_trace & 0x0010)

int action_trace_enabled (void)
{
    return snap_trace & 0x0008;
}

int block_trace_enabled (void)
{
    return snap_trace & 0x0020;
}

int cache_trace_enabled (void)
{
    return snap_trace & 0x0040;
}

int stat_trace_enabled (void)
{
    return snap_trace & 0x0080;
}

int pp_trace_enabled (void)
{
    return snap_trace & 0x0100;
}

#define software_action_enabled()  (snap_config & 0x01)

#define snap_trace(fmt, ...) do { \
        if (snap_trace_enabled()) \
            fprintf(stderr, "D " fmt, ## __VA_ARGS__); \
    } while (0)

#define reg_trace(fmt, ...) do { \
        if (reg_trace_enabled()) \
            fprintf(stderr, "R " fmt, ## __VA_ARGS__); \
    } while (0)

#define sim_trace(fmt, ...) do { \
        if (sim_trace_enabled()) \
            fprintf(stderr, "S " fmt, ## __VA_ARGS__); \
    } while (0)

#define poll_trace(fmt, ...) do { \
        if (poll_trace_enabled()) \
            fprintf(stderr, "P " fmt, ## __VA_ARGS__); \
    } while (0)

#define        INVALID_SAT 0x0ffffffff

struct snap_card {
    void* priv;
    ocxl_afu_h afu_h;
    bool master;                    /* True if this is Master Device */
    int cir;                        /* Context id */
    ocxl_endian mmio_endian;
    ocxl_mmio_h mmio_global;
    ocxl_mmio_h mmio_per_pasid;

    uint32_t action_base;
    uint16_t vendor_id;
    uint16_t device_id;
    snap_action_type_t action_type; /* Action Type for attach */
    snap_action_flag_t action_flags;
    uint32_t sat;                   /* Short Action Type */
    bool start_attach;
    snap_action_flag_t flags;       /* Flags from Application */
    uint16_t seq;                   /* Seq Number */
    int afu_fd;

    struct snap_sim_action* action; /* software simulation mode */
    size_t errinfo_size;            /* Size of errinfo */
    void* errinfo;                  /* Err info Buffer */
    ocxl_event event;               /* Buffer to keep event from IRQ */
    ocxl_irq_h afu_irq;             /* The IRQ handler. TODO: add support to multi process */ 
    uint64_t irq_ea;                /* The IRQ EA/obj_handler. TODO: add support to multi process */ 
    unsigned int attach_timeout_sec;
    unsigned int queue_length;      /* unused */
    uint64_t cap_reg;               /* Capability Register */
    const char* name;               /* Card name */
};

/* Translate Card ID to Name */
struct card_2_name {
    const int card_id;
    const char card_name[16];
};

/* Limit Card names to max of 15 Bytes */
struct card_2_name snap_card_2_name_tab[] = {
	{.card_id = AD9V3_OC_CARD,  .card_name = "AD9V3"},
	{.card_id = AD9H3_OC_CARD,  .card_name = "AD9H3"},
	{.card_id = AD9H7_OC_CARD,  .card_name = "AD9H7"},
	{.card_id = -1,             .card_name = "INVALID"}
};

/* Search snap_card_2_name_tab to for card name */
static const char* snap_card_id_2_name (int card_id)
{
    int i = 0;

    while (-1 != snap_card_2_name_tab[i].card_id) {
        if (card_id == snap_card_2_name_tab[i].card_id) {
            break;
        }

        i++;
    }

    /* Return card name */
    return snap_card_2_name_tab[i].card_name;
}


/*        Get Time in msec */
static unsigned long tget_ms (void)
{
    struct timeval now;
    unsigned long tms;

    gettimeofday (&now, NULL);
    tms = (unsigned long) (now.tv_sec * 1000) +
          (unsigned long) (now.tv_usec / 1000);
    return tms;
}

static void* hw_snap_card_alloc_dev (const char* path,
                                     uint16_t vendor_id,
                                     uint16_t device_id)
{
    struct snap_card* dn;
    uint64_t reg;
    int rc;
    ocxl_err err;

    dn = calloc (1, sizeof (*dn));

    if (NULL == dn) {
        goto __snap_alloc_err;
    }

    dn->priv = NULL;

    snap_trace ("%s Enter %s\n", __func__, path);

    // Device path, two choices:
    // /dev/ocxl/IBM,oc-snap.0007:00:00.1.0
    // IBM,oc-snap
    if (strstr ((char*)path, "ocxl") == NULL) {
        err = ocxl_afu_open ((char*)path, &dn->afu_h);    //open by simple name
    } else {
        err = ocxl_afu_open_from_dev ((char*)path, &dn->afu_h);    //open by device path
    }


    if (err != OCXL_OK) {
        goto __snap_alloc_err;
    }

    dn->sat = INVALID_SAT;        // Invalid Short Action Type stands for not attached
    dn->action_type = 0xffffffff;
    dn->vendor_id = vendor_id;
    dn->device_id = device_id;

    //Create Err Buffer (not used)
    dn->errinfo = NULL;
    dn->errinfo_size = 0;
    snap_trace ("  %s: errinfo_size: %d VendorID: %x DeviceID: %x\n", __func__,
                (int)dn->errinfo_size, (int)vendor_id, (int)device_id);

    //Set afu handle and call ocxl attach
    dn->afu_fd = ocxl_afu_get_event_fd (dn->afu_h);
    rc = ocxl_afu_attach (dn->afu_h, 0);

    if (0 != rc) {
        goto __snap_alloc_err;
    }

    //mmap
    dn->mmio_endian = OCXL_MMIO_HOST_ENDIAN;

    if (ocxl_mmio_map (dn->afu_h, OCXL_PER_PASID_MMIO, &dn->mmio_per_pasid) == -1) {
        snap_trace ("  %s: Error Can not mmap\n", __func__);
        goto __snap_alloc_err;
    }

    if (ocxl_mmio_map (dn->afu_h, OCXL_GLOBAL_MMIO, &dn->mmio_global) == -1) {
        snap_trace ("  %s: Error Can not mmap\n", __func__);
        goto __snap_alloc_err;
    }

    snap_trace ("mmio_mapped\n");


    // Read and save Capability reg
    ocxl_mmio_read64 (dn->mmio_global, SNAP_CAP, dn->mmio_endian, &reg);
    dn->cap_reg = reg;
    // Get SNAP Card Name
    dn->name = snap_card_id_2_name ((int) (reg & 0xff));

    snap_trace ("%s Exit %p OK Context: %d Master: %d Card: %s\n", __func__,
                dn, dn->cir, dn->master, dn->name);
    return (struct snap_card*)dn;

__snap_alloc_err:

    if (dn->errinfo) {
        free (dn->errinfo);
    }

    if (dn->afu_h) {
        ocxl_afu_close (dn->afu_h);
    }

    if (dn) {
        free (dn);
    }

    snap_trace ("%s Exit Err\n", __func__);
    return NULL;
}

// Register Access
// Action registers are 32bits and in PER_PASID space
static int hw_mmio_per_pasid_write32 (struct snap_card* card,
                                      uint64_t offset, uint32_t data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        reg_trace ("  %s(%p, %llx, %lx)\n", __func__, card,
                   (long long)offset, (long)data);
        rc = ocxl_mmio_write32 (card->mmio_per_pasid, offset, card->mmio_endian,
                                data);
    } else {
        reg_trace ("  %s Error\n", __func__);
        errno = EINVAL;
    }

    return rc;
}

static int hw_mmio_per_pasid_read32 (struct snap_card* card,
                                     uint64_t offset, uint32_t* data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_read32 (card->mmio_per_pasid, offset, card->mmio_endian,
                               data);
        reg_trace ("  %s(%p, %llx, %lx) %d\n", __func__, card,
                   (long long)offset, (long)*data, rc);
    } else {
        reg_trace ("  %s Error\n", __func__);
        errno = EINVAL;
    }

    return rc;
}

// Snap_core registers are 64bits and in GLOBAL space
static int hw_mmio_global_write64 (struct snap_card* card,
                                   uint64_t offset, uint64_t data)
{
    int rc = -1;

    reg_trace ("  %s(%p, %llx, %llx)\n", __func__, card,
               (long long)offset, (long long)data);

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_write64 (card->mmio_global, offset, card->mmio_endian,
                                data);
    } else {
        errno = EINVAL;
    }

    return rc;
}

static int hw_mmio_global_read64 (struct snap_card* card,
                                  uint64_t offset, uint64_t* data)
{
    int rc = -1;

    if ((card) && (card->afu_h)) {
        rc = ocxl_mmio_read64 (card->mmio_global, offset, card->mmio_endian,
                               data);
    } else {
        errno = EINVAL;
    }

    reg_trace ("  %s(%p, %llx, %llx) %d\n", __func__, card,
               (long long)offset, (long long)*data, rc);

    return rc;
}

static void hw_snap_card_free (struct snap_card* card)
{
    if (!card) {
        return;
    }

    if (card->errinfo) {
        __free (card->errinfo);
        card->errinfo = NULL;
    }

    if (card->afu_h) {
        ocxl_afu_close (card->afu_h);
        card->afu_h = NULL;
    }

    __free (card);
}

//FIXME: irq procedure needs to be revised
static int hw_wait_irq (struct snap_card* card, int timeout_sec/*, int expect_irq*/)
{
    int rc = 0;

    snap_trace ("  %s: Enter fd: %d Flags: 0x%x  Timeout: %d sec\n",
                __func__, card->afu_fd,
                card->flags, timeout_sec);

__hw_wait_irq_retry:

    if (!ocxl_afu_event_check (card->afu_h, -1, &card->event, 1)) {
	rc = EINTR;
        snap_trace ("    Timeout......\n");
    } else {
        snap_trace ("    Event is Pending ......\n");
    }

    if (0 == rc) {
        switch (card->event.type) {

        case OCXL_EVENT_IRQ:
            snap_trace ("  %s: OCXL_EVENT_IRQ\n"
                        "      irq=%d,  count=%lld\n", __func__,
                        (int)card->event.irq.irq,
                        (long long)card->event.irq.count);

            // TODO: expect_irq is useless
            //if (expect_irq != card->event.irq.irq) {
            if (card->irq_ea != card->event.irq.handle) {
                snap_trace ("  %s:     Wrong IRQ.. Retry ! Get: %lx, expect: %lx\n", __func__,
                        card->event.irq.handle, card->irq_ea);
                goto __hw_wait_irq_retry;
            }

            rc = 0;
            break;

        case OCXL_EVENT_TRANSLATION_FAULT: {
            ocxl_event_translation_fault* ds =
                &card->event.translation_fault;

            snap_trace ("  %s: OCXL_EVENT_TRANSLATION_FAULT\n", __func__);
            snap_trace ("      addr=%08llx, dsisr=%08llx\n",
                        (long long)ds->addr,
                        (long long)ds->dsisr);
            rc = EFAULT;
            break;
        }

        default:
            snap_trace ("  %s: AFU_ERROR type=%d\n",
                        __func__, card->event.type);
            rc = EINTR;
            break;
        }
    }

    snap_trace ("  %s: Exit fd: %d rc: %d\n", __func__,
                card->afu_fd, rc);
    return rc;
}

static struct snap_action* hw_attach_action (struct snap_card* card,
        snap_action_type_t action_type,
        snap_action_flag_t action_flags,
        int timeout_sec)
{
    int rc = 0;
    struct snap_action* action = NULL;

    if (card == NULL) {
        errno = EINVAL;
        return NULL;
    }

    snap_trace ("%s Enter Action: 0x%x Old Action: %x "
                "Flags: 0x%x Base: %x timeout: %d sec Seq: %x\n",
                __func__, action_type, card->action_type, action_flags,
                card->action_base, timeout_sec, card->seq);

    if (action_type != card->action_type) {
        card->start_attach = true;
        card->attach_timeout_sec = timeout_sec; /* Save timeout */
    }

    card->flags = action_flags;

    snap_trace ("Set start_attach\n");

    // TODO: Attach IRQ is currently not supported in oc-accel
    if (SNAP_ATTACH_IRQ & card->flags) {
        rc = hw_wait_irq (card, timeout_sec );
    }

    /* Return Pointer if all went well */
    if (0 == rc) {
        action = (struct snap_action*)card;
    }

    snap_trace ("%s Exit rc: %d Action: %p Base: 0x%x\n", __func__,
                rc, action, card->action_base);

    return action;
}

static int hw_detach_action (struct snap_action* action)
{
    int rc = 0;
    struct snap_card* card;

    if (action == NULL) {
        snap_trace ("%s Error NULL Action\n", __func__);
        errno = EINVAL;
        return -1;
    }

    card = (struct snap_card*)action;
    snap_trace ("%s Enter Action: 0x%x "
                "Base: %x timeout: %d sec Seq: 0x%x\n",
                __func__, card->action_type, card->action_base,
                card->attach_timeout_sec, card->seq);

    card->start_attach = true;              /* Set Flag to Attach next Time again */
    return rc;
}

static int hw_card_ioctl (struct snap_card* card, unsigned int cmd, unsigned long parm)
{
    int rc = 0;
    unsigned long rc_val = 0;
    unsigned long* arg = (unsigned long*)parm;

    if (NULL == arg) {
        snap_trace ("  %s Error Missing parm\n", __func__);
        return -1;
    }

    switch (cmd) {
    case GET_CARD_TYPE:
        rc_val = (unsigned long) (card->cap_reg & 0xff);
        snap_trace ("  %s GET CARD_TYPE: %d\n", __func__, (int)rc_val);
        *arg = rc_val;
        break;

    case GET_NVME_ENABLED:
        if (card->cap_reg & SNAP_NVME_ENA) {
            rc_val = 1;
        } else {
            rc_val = 0;
        }

        snap_trace ("  %s GET NVME: %d\n", __func__, (int)rc_val);
        *arg = rc_val;
        break;

    case GET_SDRAM_SIZE:
        rc_val = (unsigned long) (card->cap_reg >> 16);  /* in MB */
        rc_val = rc_val & 0xffff;    /* Mask bits 16 ... 31 */
        snap_trace ("  %s Get MEM: %d MB\n", __func__, (int)rc_val);
        *arg = rc_val;
        break;

    case GET_DMA_ALIGN:
        /* Data alignment for DMA transfers to/from Host */
        /* Value a means that transfers need to be 2^a B aligned */
        rc_val = (unsigned long) (card->cap_reg >> 32) & 0xf; /* Get Bits 32 .. 35 */
        rc_val = 1 << rc_val;
        snap_trace ("  %s Get DMA align: %d Bytes\n", __func__, (int)rc_val);
        *arg = rc_val;
        break;

    case GET_DMA_MIN_SIZE:
        /* Minimum size for DMA transfers to/from Host */
        /* Value t means that minimum transfer size is 2^t B */
        rc_val = (unsigned long) (card->cap_reg >> 36) & 0xf; /* Get Bits 36 .. 39 */
        rc_val = 1 << rc_val;
        snap_trace ("  %s Get DMA Min Size: %d Bytes\n", __func__, (int)rc_val);
        *arg = rc_val;
        break;

    case GET_CARD_NAME:
        snap_trace ("  %s Get Card name: %s\n", __func__, card->name);
        strcpy ((char*)parm, card->name);
        break;

    case SET_SDRAM_SIZE:
        card->cap_reg = (card->cap_reg & 0xffff) | (parm << 16);
        snap_trace ("  %s Set MEM: %d MB\n", __func__, (int)parm);
        break;

    default:
        snap_trace ("  %s Invalid CMD %d Error\n", __func__, cmd);
        *arg = 0;
        rc = -1;
        break;
    }

    return rc;
}

/* Hardware version of the lowlevel functions */
static struct snap_funcs hardware_funcs = {
    .card_alloc_dev = hw_snap_card_alloc_dev,
    .attach_action = hw_attach_action,       /* attach Action */
    .detach_action = hw_detach_action,       /* detach Action */
    .mmio_per_pasid_write32 = hw_mmio_per_pasid_write32,
    .mmio_per_pasid_read32 = hw_mmio_per_pasid_read32,
    .mmio_global_write64 = hw_mmio_global_write64,
    .mmio_global_read64 = hw_mmio_global_read64,
    .card_free = hw_snap_card_free,
    .card_ioctl = hw_card_ioctl,
};

/* We access the hardware via this function pointer struct */
static struct snap_funcs* df = &hardware_funcs;

struct snap_card* snap_card_alloc_dev (const char* path,
                                       uint16_t vendor_id,
                                       uint16_t device_id)
{
    return df->card_alloc_dev (path, vendor_id, device_id);
}

struct snap_action* snap_attach_action (struct snap_card* card,
                                        snap_action_type_t action_type,
                                        snap_action_flag_t action_flags,
                                        int timeout_ms)
{
    return df->attach_action (card, action_type, action_flags, timeout_ms);
}

int snap_detach_action (struct snap_action* action)
{
    int rc;

    snap_trace ("%s Enter\n", __func__);
    rc = df->detach_action (action);
    snap_trace ("%s Exit rc: %d\n", __func__, rc);
    return rc;
}

int snap_action_write32 (struct snap_card* _card,
                         uint64_t offset, uint32_t data)
{
    int rc;
    rc = df->mmio_per_pasid_write32 (_card, offset, data);
    return rc;
}

int snap_action_read32 (struct snap_card* _card,
                        uint64_t offset, uint32_t* data)
{
    int rc;
    rc = df->mmio_per_pasid_read32 (_card, offset, data);
    return rc;
}


int snap_global_write64 (struct snap_card* _card,
                         uint64_t offset, uint64_t data)
{
    int rc;

    rc = df->mmio_global_write64 (_card, offset, data);
    return rc;
}

int snap_global_read64 (struct snap_card* _card,
                        uint64_t offset, uint64_t* data)
{
    int rc;

    rc = df->mmio_global_read64 (_card, offset, data);
    return rc;
}


void snap_card_free (struct snap_card* _card)
{
    df->card_free (_card);
}

int snap_card_ioctl (struct snap_card* _card, unsigned int cmd, unsigned long arg)
{
    return df->card_ioctl (_card, cmd, arg);
}

/*****************************************************************************
 *        Below are functions defined for HLS action.
 *        For HDL actions, you can use "snap_action_start" and "snap_action_complete"
 *        if you have implemented the same register of ACTION_CONTROL which is defined
 *        in snap_hls_if.h
 ****************************************************************************/

int snap_action_start (struct snap_action* action)
{
    struct snap_card* card = (struct snap_card*)action;

    snap_trace ("%s: START Action 0x%x Flags %x\n", __func__, card->action_type, card->flags);

    /* Enable Ready IRQ if set by application */
    if (SNAP_ACTION_DONE_IRQ  & card->flags) {
        snap_action_write32 (card, ACTION_IRQ_APP, ACTION_IRQ_APP_DONE);
        snap_action_write32 (card, ACTION_IRQ_CONTROL, ACTION_IRQ_CONTROL_ON);
    }

    return snap_action_write32 (card, ACTION_CONTROL, ACTION_CONTROL_START);
}

int snap_action_stop (struct snap_action* action __unused)
{
    /* FIXME Missing */
    return 0;
}

int snap_action_is_idle (struct snap_action* action, int* rc)
{
    int _rc = 0;
    uint32_t action_data = 0;
    struct snap_card* card = (struct snap_card*)action;

    _rc = snap_action_read32 (card, ACTION_CONTROL, &action_data);

    if (rc) {
        *rc = _rc;
    }

    return (action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE;
}

int snap_action_wait_interrupt(struct snap_action *action, int *rc, int timeout)
{
    //uint32_t action_data = 0;
    struct snap_card *card = (struct snap_card *)action;
    //int _rc = hw_wait_irq(card, timeout, SNAP_ACTION_IRQ_NUM);
    int _rc = hw_wait_irq(card, timeout /*, SNAP_ACTION_IRQ_NUM*/);

    if (NULL != rc)
        *rc = _rc;

    return _rc;
}

int snap_action_completed (struct snap_action* action, int* rc, int timeout)
{
    int _rc = 0;
    uint32_t action_data = 0;
    struct snap_card* card = (struct snap_card*)action;
    unsigned long t0;
    int dt, timeout_ms;

    if (SNAP_ACTION_DONE_IRQ & card->flags) {
        snap_trace ("Wait for IRQ\n");
        hw_wait_irq (card, timeout);
        snap_action_write32 (card, ACTION_IRQ_STATUS, ACTION_IRQ_STATUS_DONE);
        snap_action_write32 (card, ACTION_IRQ_APP, 0);
        snap_action_write32 (card, ACTION_IRQ_CONTROL, ACTION_IRQ_CONTROL_OFF);
        _rc = snap_action_read32 (card, ACTION_CONTROL, &action_data);
    } else {
        snap_trace ("Poll until timeout\n");
        /* Busy poll timout sec */
        t0 = tget_ms();
        dt = 0;
        timeout_ms = timeout * 1000;

        while (dt < timeout_ms) {
            _rc = snap_action_read32 (card, ACTION_CONTROL, &action_data);

            if ((action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE) {
                break;
            }

            dt = (int) (tget_ms() - t0);
        }
    }

    if (rc) {
        *rc = _rc;
    }

    //return is_completed
    return (action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE;
}

int snap_action_assign_irq (struct snap_action* action, uint32_t action_irq_ea_reg_addr)
{
    struct snap_card* card = (struct snap_card*)action;
    int rc = -1;

    snap_trace ("%s: Assign IRQ EA on reg 0x%x\n", __func__, action_irq_ea_reg_addr);

    // TODO: need to discuss if this is the best way to handle IRQ
    rc = ocxl_irq_alloc(card->afu_h, NULL, &(card->afu_irq));

    if (OCXL_OK != rc) {
        snap_trace ("%s: Failed to allocate IRQ handler.\n", __func__);
        return -1;
    }

    // TODO: Need to write EA to AFU's register.
    card->irq_ea = ocxl_irq_get_handle(card->afu_h, card->afu_irq);
    snap_trace ("%s: IRQ EA: %lx.\n", __func__, card->irq_ea);

    snap_action_write32 (card, (action_irq_ea_reg_addr + 4), (uint32_t) ((card->irq_ea & 0xFFFFFFFF00000000) >> 32));
    snap_action_write32 (card, action_irq_ea_reg_addr,  (uint32_t) (card->irq_ea & 0x00000000FFFFFFFF));

    return 0;
}

/**
 * Synchronous way to send a job away.  First step : set registers
 * This function writes through MMIO interface the registers
 * to the action / in the FPGA internal memory
 *
 * @action        handle to streaming framework action/action
 * @cjob        streaming framework job
 * @return        0 on success.
 */

int snap_action_sync_execute_job_set_regs (struct snap_action* action,
        struct snap_job* cjob)
{
    int rc = 0;
    unsigned int i;
    struct snap_card* card = (struct snap_card*)action;
    struct snap_queue_workitem job;
    uint32_t action_addr;
    uint32_t* job_data;
    unsigned int mmio_in, mmio_out;

    /* Size must be less than addr[6] */
    if (cjob->wout_size > SNAP_JOBSIZE) {
        snap_trace ("  %s: err: wout_size too large %d > %d\n", __func__,
                    cjob->wout_size, SNAP_JOBSIZE);
        snap_trace ("      win_addr  = %llx size = %d\n",
                    (long long)cjob->win_addr, cjob->win_size);
        snap_trace ("      wout_addr = %llx size = %d\n",
                    (long long)cjob->wout_addr, cjob->wout_size);

        errno = EINVAL;
        return -1;
    }

    /* job.short_action = 0x00; */        /* Set later */
    job.flags = 0x01; /* FIXME Set Flag to Execute */
    job.seq = 0x0000; /* Set later */
    job.retc = 0x00000000;
    job.priv_data = 0xdeadbeefc0febabeull;

    /* Fill workqueue cacheline which we need to transfer to the action */
    if (cjob->win_size <= (6 * 16)) {
        memcpy (&job.user, (void*) (unsigned long)cjob->win_addr,
                MIN (cjob->win_size, sizeof (job.user)));
        mmio_out = cjob->win_size / sizeof (uint32_t);
    } else {
        job.user.ext.addr  = cjob->win_addr;
        job.user.ext.size  = cjob->win_size;
        job.user.ext.type  = SNAP_ADDRTYPE_HOST_DRAM;
        job.user.ext.flags = (SNAP_ADDRFLAG_EXT |
                              SNAP_ADDRFLAG_END);
        mmio_out = sizeof (job.user.ext) / sizeof (uint32_t);
    }

    mmio_in = 16 / sizeof (uint32_t) + mmio_out;

    snap_trace ("    win_size: %d wout_size: %d mmio_in: %d mmio_out: %d\n",
                cjob->win_size, cjob->wout_size, mmio_in, mmio_out);

    job.short_action = card->sat;/* Set correct Value after attach */
    job.seq = card->seq++; /* Set correct Value after attach */

    snap_trace ("%s: PASS PARAMETERS to Short Action %d Seq: %x\n",
                __func__, job.short_action, job.seq);

    /* __hexdump(stderr, &job, sizeof(job)); */

    /* Pass action control and job to the action, should be 128
       bytes or a little less */
    job_data = (uint32_t*) (unsigned long)&job;

    for (i = 0, action_addr = ACTION_PARAMS_IN; i < mmio_in;
         i++, action_addr += sizeof (uint32_t)) {
        rc = snap_action_write32 (card, action_addr, job_data[i]);

        if (rc != 0) {
            goto __snap_action_sync_execute_job_exit;
        }
    }

__snap_action_sync_execute_job_exit:
    snap_action_stop (action);
    return rc;
}

/**
 * Synchronous way to send a job away.  Last step : check completion
 * This function check the completion of the action, manage the IRQ
 * if needed, and read all action registers through MMIO interface
 *
 * @action        handle to streaming framework action/action
 * @cjob        streaming framework job
 * timeout_sec  timeout used if polling mode
 * @return        0 on success.
 */

int snap_action_sync_execute_job_check_completion (struct snap_action* action,
        struct snap_job* cjob,
        unsigned int timeout_sec)
{
    int rc;
    unsigned int i;
    int completed;
    struct snap_card* card = (struct snap_card*)action;
    struct snap_queue_workitem job;
    uint32_t action_addr;
    uint32_t* job_data;
    unsigned int mmio_out;

    completed = snap_action_completed (action, &rc, timeout_sec);

    /* Issue #360 */
    if (rc != 0) {
        snap_trace ("%s: EIO rc=%d completed=%d\n", __func__,
                    rc, completed);
        rc = SNAP_EIO;
        goto __snap_action_sync_execute_job_exit;
    }

    if (completed == 0) {
        /* Not done */
        snap_trace ("%s: rc=%d\n", __func__, rc);

        if (rc == 0) {
            errno = ETIME;
            rc = SNAP_ETIMEDOUT;
        }

        goto __snap_action_sync_execute_job_exit;
    }

    /* job.short_action = 0x00; */        /* Set later */
    job.flags = 0x01; /* FIXME Set Flag to Execute */
    job.seq = 0x0000; /* Set later */
    job.retc = 0x00000000;
    job.priv_data = 0xdeadbeefc0febabeull;

    /* Fill workqueue cacheline which we need to transfer to the action */
    if (cjob->win_size <= (6 * 16)) {
        memcpy (&job.user, (void*) (unsigned long)cjob->win_addr,
                MIN (cjob->win_size, sizeof (job.user)));
        mmio_out = cjob->win_size / sizeof (uint32_t);
    } else {
        job.user.ext.addr  = cjob->win_addr;
        job.user.ext.size  = cjob->win_size;
        job.user.ext.type  = SNAP_ADDRTYPE_HOST_DRAM;
        job.user.ext.flags = (SNAP_ADDRFLAG_EXT |
                              SNAP_ADDRFLAG_END);
        mmio_out = sizeof (job.user.ext) / sizeof (uint32_t);
    }

    /* Get RETC (0x184) back to the caller */
    rc = snap_action_read32 (card, ACTION_RETC_OUT, &cjob->retc);

    if (rc != 0) {
        goto __snap_action_sync_execute_job_exit;
    }

    snap_trace ("%s: RETURN RESULTS %ld bytes (%d)\n", __func__,
                mmio_out * sizeof (uint32_t), mmio_out);

    /* Get job results max 6*16 bytes back to the caller */
    if (cjob->wout_addr == 0) {
        /* No out Address, mmio_out is set */
        job_data = (uint32_t*) (unsigned long)cjob->win_addr;
    } else {
        job_data = (uint32_t*) (unsigned long)cjob->wout_addr;
        mmio_out = cjob->wout_size / sizeof (uint32_t);
    }

    /* No need to read back 0x190, 0x194, 0x198 and 0x19c .... */
    for (i = 0, action_addr = ACTION_PARAMS_OUT + 0x10; i < mmio_out;
         i++, action_addr += sizeof (uint32_t)) {
        rc = snap_action_read32 (card, action_addr, &job_data[i]);

        if (rc != 0) {
            goto __snap_action_sync_execute_job_exit;
        }

        snap_trace ("  %s: %d Addr: %x Data: %x\n", __func__, i,
                    action_addr, job_data[i]);
    }

__snap_action_sync_execute_job_exit:
    snap_action_stop (action);
    return rc;
}

/**
 * Synchronous way to send a job away. Blocks until job is done.
 * These 3 steps can be called separately from the application
 * BUT manage carefully the action timeout
 *  * 1rst step: write Action registers into the FPGA
 *  * 2nd  step: start the Action
 *  *      step: processing - exchange data
 *  * 3rd  step: check completion and manage IRQ if needed
 *
 * @action        handle to streaming framework action/action
 * @cjob        streaming framework job
 * @return        0 on success.
 */

int snap_action_sync_execute_job (struct snap_action* action,
                                  struct snap_job* cjob,
                                  unsigned int timeout_sec)
{
    int rc;

    /* Set action registers through MMIO */
    rc = snap_action_sync_execute_job_set_regs (action, cjob);

    if (rc != 0) {
        return rc;
    }

    /* Start Action */
    snap_action_start (action);

    /* Wait for finish */
    rc = snap_action_sync_execute_job_check_completion (action, cjob,
            timeout_sec);
    return rc;
}


uint32_t snap_action_get_pasid(struct snap_card *card)
{
    return ocxl_afu_get_pasid(card->afu_h);
}

/* Software version of the lowlevel functions */
/* Abandoned */
//static struct snap_funcs software_funcs = {
//        .card_alloc_dev = NULL,
//        .attach_action = NULL, /* attach Action */
//        .detach_action = NULL, /* detach Action */
//        .mmio_per_pasid_write32 = NULL,
//        .mmio_per_pasid_read32 = NULL,
//        .mmio_global_write64 = NULL,
//        .mmio_global_read64 = NULL,
//        .card_free = NULL,
//        .card_ioctl = NULL,
//};

/**********************************************************************
 * LIBRARY INITIALIZATION
 *********************************************************************/

static void _init (void) __attribute__ ((constructor));

static void _init (void)
{
    const char* trace_env;

    trace_env = getenv ("SNAP_TRACE");

    if (trace_env != NULL) {
        snap_trace = strtol (trace_env, (char**)NULL, 0);
    }
}
