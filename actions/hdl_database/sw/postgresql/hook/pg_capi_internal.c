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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <time.h>
#include <getopt.h>
#include <ctype.h>

#include <osnap_tools.h>
#include <osnap_action_regs.h>

#include "fregex.h"
#include "pg_capi_internal.h"
#include "mt/interface/Interface.h"

int verbose_level = 0;

void print_error (const char* file, const char* func, const char* line, int rc)
{
    printf ("ERROR: %s %s failed in line %s with return code %d\n", file, func, line, rc);
}

int64_t diff_time (struct timespec* t_beg, struct timespec* t_end)
{
    if (t_end == NULL || t_beg == NULL) {
        return 0;
    }

    return ((t_end-> tv_sec - t_beg-> tv_sec) * 1000000000L + t_end-> tv_nsec - t_beg-> tv_nsec);
}

void print_time (uint64_t elapsed, uint64_t size)
{
    int t;
    float fsize = (float)size / (1024 * 1024);
    float ft;

    if (elapsed > 10000) {
        t = (int)elapsed / 1000;
        ft = (1000 / (float)t) * fsize;
        elog (INFO, " end after %d msec (%0.3f MB/sec)\n", t, ft);
    } else {
        t = (int)elapsed;
        ft = (1000000 / (float)t) * fsize;
        elog (INFO, " end after %d usec (%0.3f MB/sec)\n", t, ft);
    }
}

void print_time_text (const char* text, uint64_t elapsed, uint64_t size)
{
    int t;
    float fsize = (float)size / (1024 * 1024);
    float ft;

    if (elapsed > 10000) {
        t = (int)elapsed / 1000;
        ft = (1000 / (float)t) * fsize;

        if (0 == size) {
            elog (INFO, "%s run time: %d msec", text, t);
        } else {
            elog (INFO, "%s run time: %d msec (%0.3f MB/sec)", text, t, ft);
        }
    } else {
        t = (int)elapsed;
        ft = (1000000 / (float)t) * fsize;

        if (0 == size) {
            elog (INFO, "%s run time:  %d usec", text, t);
        } else {
            elog (INFO, "%s run time:  %d usec (%0.3f MB/sec)", text, t, ft);
        }
    }
}

float perf_calc (uint64_t elapsed, uint64_t size)
{
    int t;
    float fsize = (float)size / (1024 * 1024);
    float ft;

    t = (int)elapsed / 1000;

    if (t == 0) {
        return 0.0;
    }

    ft = (1000 / (float)t) * fsize;
    return ft;
}


void* alloc_mem (int align, size_t size)
{
    void* a;
    size_t size2 = size + align;

    if (posix_memalign ((void**)&a, 4096, size2) != 0) {
        //perror ("FAILED: posix_memalign()");
        return NULL;
    }

    return a;
}

void free_mem (void* a)
{
    if (a) {
        free (a);
    }
}

void* fill_one_packet (const char* in_pkt, int size, void* in_pkt_addr, int in_pkt_id)
{
    unsigned char* pkt_base_addr = (unsigned char*) in_pkt_addr;
    int pkt_id = in_pkt_id;
    uint32_t bytes_used = 0;
    uint16_t pkt_len = size;

    if (((uint64_t)pkt_base_addr & 0x3FULL) != 0) {
        elog (INFO, "WARNING: Address %p is not 64B aligned", pkt_base_addr);
    }

    // The frame header
    for (int i = 0; i < 4; i++) {
        pkt_base_addr[bytes_used] = 0x5A;
        bytes_used ++;
    }

    // The frame size
    pkt_base_addr[bytes_used] = (pkt_len & 0xFF);
    bytes_used ++;
    pkt_base_addr[bytes_used] = 0;
    pkt_base_addr[bytes_used] |= ((pkt_len >> 8) & 0xF);
    bytes_used ++;

    memset (pkt_base_addr + bytes_used, 0, 54);
    bytes_used += 54;

    for (int i = 0; i < 4 ; i++) {
        pkt_base_addr[bytes_used] = ((pkt_id >> (8 * i)) & 0xFF);
        bytes_used++;
    }

    memcpy (pkt_base_addr + bytes_used, in_pkt, pkt_len);
    bytes_used += pkt_len;

    // Padding to 64 bytes alignment
    bytes_used--;

    do {
        if ((((uint64_t) (pkt_base_addr + bytes_used)) & 0x3F) == 0x3F) { //the last address of the packet stream is 512bit/64byte aligned
            break;
        } else {
            bytes_used ++;
            pkt_base_addr[bytes_used] = 0x00; //padding 8'h00 until the 512bit/64byte alignment
        }

    } while (1);

    bytes_used++;

    return pkt_base_addr + bytes_used;
}

void* fill_one_pattern (const char* in_patt, void* in_patt_addr, int in_patt_id)
{
    unsigned char* patt_base_addr = (unsigned char*) in_patt_addr;
    int config_len = 0;
    unsigned char config_bytes[PATTERN_WIDTH_BYTES];
    int x;
    uint32_t pattern_id = in_patt_id;
    uint16_t patt_byte_cnt;
    uint32_t bytes_used = 0;

    for (x = 0; x < PATTERN_WIDTH_BYTES; x++) {
        config_bytes[x] = 0;
    }

    elog (DEBUG1, "PATT[%d] %s\n", pattern_id, in_patt);

    fregex_get_config (in_patt,
                       MAX_TOKEN_NUM,
                       MAX_STATE_NUM,
                       MAX_CHAR_NUM,
                       MAX_CHAR_PER_TOKEN,
                       config_bytes,
                       &config_len,
                       0);

    for (int i = 0; i < 4; i++) {
        patt_base_addr[bytes_used] = 0x5A;
        bytes_used++;
    }

    patt_byte_cnt = (PATTERN_WIDTH_BYTES - 4);
    patt_base_addr[bytes_used] = patt_byte_cnt & 0xFF;
    bytes_used ++;
    patt_base_addr[bytes_used] = (patt_byte_cnt >> 8) & 0x7;
    bytes_used ++;

    memset (patt_base_addr + bytes_used, 0, 54);
    bytes_used += 54;

    // Pattern ID;
    for (int i = 0; i < 4; i++) {
        patt_base_addr[bytes_used] = (pattern_id >> (i * 8)) & 0xFF;
        bytes_used ++;
    }

    memcpy (patt_base_addr + bytes_used, config_bytes, config_len);
    bytes_used += config_len;

    // Padding to 64 bytes alignment
    bytes_used --;

    do {
        if ((((uint64_t) (patt_base_addr + bytes_used)) & 0x3F) == 0x3F) { //the last address of the packet stream is 512bit/64byte aligned
            break;
        } else {
            bytes_used ++;
            patt_base_addr[bytes_used] = 0x00; //padding 8'h00 until the 512bit/64byte alignment
        }

    } while (1);

    bytes_used ++;

    return patt_base_addr + bytes_used;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
void action_write (struct snap_card* h, uint32_t addr, uint32_t data, int id)
{
    int rc;

    rc = snap_action_write32 (h, (uint64_t)REG (addr, id), data);

    if (0 != rc) {
        elog (DEBUG1, "Write MMIO 32 Err\n");
    }

    return;
}

uint32_t action_read (struct snap_card* h, uint32_t addr, int id)
{
    int rc;
    uint32_t data;

    rc = snap_action_read32 (h, (uint64_t)REG (addr, id), &data);

    if (0 != rc) {
        elog (DEBUG1, "Read MMIO 32 Err\n");
    }

    return data;
}

/*
 *  Start Action and wait for Idle.
 */
int action_wait_idle (struct snap_card* h, int timeout)
{
    int rc = ETIME;

    /* FIXME Use struct snap_action and not struct snap_card */
    snap_action_start ((struct snap_action*)h);

    /* Wait for Action to go back to Idle */
    rc = snap_action_completed ((struct snap_action*)h, NULL, timeout);

    if (rc) {
        rc = 0;    /* Good */
    } else {
        elog (DEBUG1, "Error. Timeout while Waiting for Idle\n");
    }

    return rc;
}

void print_control_status (struct snap_card* h, int id)
{
    if (verbose_level > 2) {
        uint32_t reg_data;
        elog (DEBUG3, " READ Control and Status Registers: \n");
        reg_data = action_read (h, ACTION_STATUS_L, id);
        elog (DEBUG3, "       STATUS_L = 0x%x\n", reg_data);
        reg_data = action_read (h, ACTION_STATUS_H, id);
        elog (DEBUG3, "       STATUS_H = 0x%x\n", reg_data);
        reg_data = action_read (h, ACTION_CONTROL_L, id);
        elog (DEBUG3, "       CONTROL_L = 0x%x\n", reg_data);
        reg_data = action_read (h, ACTION_CONTROL_H, id);
        elog (DEBUG3, "       CONTROL_H = 0x%x\n", reg_data);
    }
}

void soft_reset (struct snap_card* h, int id)
{
    // Status[4] to reset
    action_write (h, ACTION_CONTROL_L, 0x00000010, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);
    elog (DEBUG1, " Write ACTION_CONTROL for soft reset!");
    action_write (h, ACTION_CONTROL_L, 0x00000000, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);
}

int action_regex (struct snap_card* h,
                  void* patt_src_base,
                  void* pkt_src_base,
                  void* stat_dest_base,
                  size_t* num_matched_pkt,
                  size_t patt_size,
                  size_t pkt_size,
                  size_t stat_size,
                  int id)
{
    uint32_t reg_data;
    int64_t count = 0;

    print_control_status (h, id);

    elog (DEBUG1, "PKT  source: %p", pkt_src_base);
    elog (DEBUG1, "PATT source: %p", patt_src_base);
    elog (DEBUG1, "Stat source: %p", stat_dest_base);
    elog (DEBUG1, "PKT  size: %zu", pkt_size);
    elog (DEBUG1, "PATT size: %zu", patt_size);
    elog (DEBUG1, "Stat size: %zu", stat_size);

    action_write (h, ACTION_PATT_INIT_ADDR_L,
                  (uint32_t) (((uint64_t) patt_src_base) & 0xffffffff), id);
    action_write (h, ACTION_PATT_INIT_ADDR_H,
                  (uint32_t) ((((uint64_t) patt_src_base) >> 32) & 0xffffffff), id);

    action_write (h, ACTION_PKT_INIT_ADDR_L,
                  (uint32_t) (((uint64_t) pkt_src_base) & 0xffffffff), id);
    action_write (h, ACTION_PKT_INIT_ADDR_H,
                  (uint32_t) ((((uint64_t) pkt_src_base) >> 32) & 0xffffffff), id);

    action_write (h, ACTION_PATT_CARD_DDR_ADDR_L, 0, id);
    action_write (h, ACTION_PATT_CARD_DDR_ADDR_H, 0, id);

    action_write (h, ACTION_STAT_INIT_ADDR_L,
                  (uint32_t) (((uint64_t) stat_dest_base) & 0xffffffff), id);
    action_write (h, ACTION_STAT_INIT_ADDR_H,
                  (uint32_t) ((((uint64_t) stat_dest_base) >> 32) & 0xffffffff), id);

    action_write (h, ACTION_PATT_TOTAL_NUM_L,
                  (uint32_t) (((uint64_t) patt_size) & 0xffffffff), id);
    action_write (h, ACTION_PATT_TOTAL_NUM_H,
                  (uint32_t) ((((uint64_t) patt_size) >> 32) & 0xffffffff), id);

    action_write (h, ACTION_PKT_TOTAL_NUM_L,
                  (uint32_t) (((uint64_t) pkt_size) & 0xffffffff), id);
    action_write (h, ACTION_PKT_TOTAL_NUM_H,
                  (uint32_t) ((((uint64_t) pkt_size) >> 32) & 0xffffffff), id);

    action_write (h, ACTION_STAT_TOTAL_SIZE_L,
                  (uint32_t) (((uint64_t) stat_size) & 0xffffffff), id);
    action_write (h, ACTION_STAT_TOTAL_SIZE_H,
                  (uint32_t) ((((uint64_t) stat_size) >> 32) & 0xffffffff), id);

    // Start copying the pattern from host memory to card
    action_write (h, ACTION_CONTROL_L, 0x00000001, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);

    print_control_status (h, id);

    count = 0;

    do {
        reg_data = action_read (h, ACTION_STATUS_L, id);

        // Status[23:8]
        if ((reg_data & 0x00FFFF00) != 0) {
            elog (ERROR, "Error code got 0X%X\n", ((reg_data & 0x00FFFF00) >> 8));
            return -1;
        }

        // Status[0]
        if ((reg_data & 0x00000001) == 1) {
            elog (DEBUG1, "Pattern copy done!\n");
            break;
        }

        usleep (1000);

        count ++;

        if ((count % 1000) == 0) {
            elog (INFO, "Heart beat on hardware pattern polling");
        }
    } while (1);

    // Start working control[2:1] = 11
    action_write (h, ACTION_CONTROL_L, 0x00000006, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);

    count = 0;

    do {
        reg_data = action_read (h, ACTION_STATUS_L, id);

        // Status[23:8]
        if ((reg_data & 0x00FFFF00) != 0) {
            elog (ERROR, "Error code got 0X%X\n", ((reg_data & 0x00FFFF00) >> 8));
            return -1;
        }

        // Status[0]
        if ((reg_data & 0x00000010) != 0) {
            elog (ERROR, "Error status got 0X%X\n", (reg_data & 0x00000010));
            return -1;
        }

        if ((reg_data & 0x00000006) == 6) {
            break;
        }

        usleep (1000);

        count ++;

        if ((count % 1000) == 0) {
            elog (INFO, "Heart beat on hardware status polling");
        }
    } while (1);

    // Stop working
    action_write (h, ACTION_CONTROL_L, 0x00000000, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);

    // Flush rest data
    action_write (h, ACTION_CONTROL_L, 0x00000008, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);

    count = 0;

    do {
        reg_data = action_read (h, ACTION_STATUS_L, id);

        // Status[23:8]
        if ((reg_data & 0x00FFFF00) != 0) {
            elog (ERROR, "Error code got 0X%X\n", ((reg_data & 0x00FFFF00) >> 8));
            return -1;
        }

        // Status[3]
        if ((reg_data & 0x00000008) == 8) {
            reg_data = action_read (h, ACTION_STATUS_H, id);
            *num_matched_pkt = reg_data;
            break;
        }

        count ++;

        if ((count % 1000) == 0) {
            elog (INFO, "Heart beat on hardware draining polling");
        }
    } while (1);

    // Stop flushing
    action_write (h, ACTION_CONTROL_L, 0x00000000, id);
    action_write (h, ACTION_CONTROL_H, 0x00000000, id);

    return 0;
}

int capi_regex_scan_internal (struct snap_card* dnc,
                              int timeout,
                              void* patt_src_base,
                              void* pkt_src_base,
                              void* stat_dest_base,
                              size_t* num_matched_pkt,
                              size_t patt_size,
                              size_t pkt_size,
                              size_t stat_size,
                              int id)
{
    int rc = action_regex (dnc, patt_src_base, pkt_src_base, stat_dest_base, num_matched_pkt,
                           patt_size, pkt_size, stat_size, id);

    if (0 != rc) {
        return rc;
    }

    rc = action_wait_idle (dnc, timeout);

    return rc;
}

struct snap_action* get_action (struct snap_card* handle,
                                snap_action_flag_t flags, int timeout)
{
    struct snap_action* act;

    act = snap_attach_action (handle, ACTION_TYPE_DATABASE,
                              flags, timeout);

    if (NULL == act) {
        elog (DEBUG1, "Error: Can not attach Action: %x\n", ACTION_TYPE_DATABASE);
        elog (DEBUG1, "       Try to run snap_main tool\n");
    }

    return act;
}

void* capi_regex_compile_internal (const char* patt, size_t* size)
{
    // The max size that should be alloc
    // Assume we have at most 1024 lines in a pattern file
    size_t max_alloc_size = MAX_NUM_PATT * (64 +
                                            (PATTERN_WIDTH_BYTES - 4) +
                                            ((PATTERN_WIDTH_BYTES - 4) % 64) == 0 ? 0 :
                                            (64 - ((PATTERN_WIDTH_BYTES - 4) % 64)));

    void* patt_src_base = alloc_mem (64, max_alloc_size);
    //void* patt_src_base = palloc0 (max_alloc_size);
    void* patt_src = patt_src_base;

    elog (DEBUG1, "PATTERN Source Address Start at 0X%016lX\n", (uint64_t) patt_src);

    if (patt == NULL) {
        elog (ERROR, "PATTERN pointer is NULL!\n");
        return NULL;
    }

    //remove_newline (patt);
    // TODO: fill the same pattern for 8 times, workaround for 32x8.
    // TODO: for 64X1, only 1 pattern is needed.
    for (int i = 0; i < 1; i++) {
        elog (DEBUG3, "%s\n", patt);
        patt_src = fill_one_pattern (patt, patt_src, i);
        elog (DEBUG3, "Pattern Source Address 0X%016lX\n", (uint64_t) patt_src);
    }

    elog (DEBUG1, "Total size of pattern buffer used: %ld\n", (uint64_t) ((uint64_t) patt_src - (uint64_t) patt_src_base));

    elog (DEBUG1, "---------- Pattern Buffer: %p\n", patt_src_base);

    if (verbose_level > 2) {
        __hexdump (stdout, patt_src_base, ((uint64_t) patt_src - (uint64_t) patt_src_base));
    }

    (*size) = (uint64_t) patt_src - (uint64_t) patt_src_base;

    return patt_src_base;
}

// The new function based on PostgreSQL storage backend
char* get_attr (HeapTupleHeader tuphdr,
                TupleDesc tupdesc,
                uint16_t lp_len,
                int attr_id,
                int* out_len)
{
    int         nattrs;
    int         off = 0;
    int         i;
    uint16_t    t_infomask  = tuphdr->t_infomask;
    uint16_t    t_infomask2 = tuphdr->t_infomask2;
    int         tupdata_len = lp_len - tuphdr->t_hoff;
    char*       tupdata = (char*) tuphdr + tuphdr->t_hoff;
    bits8*      t_bits = tuphdr->t_bits;

    nattrs = tupdesc->natts;

    if (nattrs < (t_infomask2 & HEAP_NATTS_MASK))
        ereport (ERROR,
                 (errcode (ERRCODE_DATA_CORRUPTED),
                  errmsg ("number of attributes in tuple header is greater than number of attributes in tuple descriptor")));

    if (attr_id >= nattrs) {
        ereport (ERROR,
                 (errcode (ERRCODE_DATA_CORRUPTED),
                  errmsg ("Given index [%d] is out of range, number of attrs: %d", attr_id, nattrs)));
    }

    for (i = 0; i < nattrs; i++) {
        Form_pg_attribute attr;
        bool        is_null;

        attr = TupleDescAttr (tupdesc, i);

        if (i >= (t_infomask2 & HEAP_NATTS_MASK)) {
            is_null = true;
        } else {
            is_null = (t_infomask & HEAP_HASNULL) && att_isnull (i, t_bits);
        }

        if (!is_null) {
            int         len;

            if (attr->attlen == -1) {
                off = att_align_pointer (off, attr->attalign, -1,
                                         tupdata + off);

                if (VARATT_IS_EXTERNAL (tupdata + off) &&
                    !VARATT_IS_EXTERNAL_ONDISK (tupdata + off) &&
                    !VARATT_IS_EXTERNAL_INDIRECT (tupdata + off))
                    ereport (ERROR,
                             (errcode (ERRCODE_DATA_CORRUPTED),
                              errmsg ("first byte of varlena attribute is incorrect for attribute %d", i)));

                len = VARSIZE_ANY (tupdata + off);
            } else {
                off = att_align_nominal (off, attr->attalign);
                len = attr->attlen;
            }

            if (tupdata_len < off + len)
                ereport (ERROR,
                         (errcode (ERRCODE_DATA_CORRUPTED),
                          errmsg ("unexpected end of tuple data")));

            if (i == attr_id) {
                (*out_len) = len;
                break;
            }

            off = att_addlength_pointer (off, attr->attlen,
                                         tupdata + off);
        }
    }

    return (char*) (tupdata + off);
}

int capi_regex_context_init (CAPIContext* context)
{
    if (context == NULL) {
        return -1;
    }

    // Init the job descriptor
    context->card_no      = 0;
    context->timeout      = ACTION_WAIT_TIME;
    context->attach_flags = (snap_action_flag_t) 0;
    context->act          = NULL;

    // Prepare the card and action
    elog (DEBUG1, "Open Card: %d", context->card_no);

    if (context->card_no == 0) {
        snprintf (context->device, sizeof (context->device) - 1, "IBM,oc-snap");
    } else {
        snprintf (context->device, sizeof (context->device) - 1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", context->card_no);
    }

    context->dn = snap_card_alloc_dev (context->device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

    if (NULL == context->dn) {
        ereport (ERROR,
                 (errcode (ERRCODE_INVALID_PARAMETER_VALUE),
                  errmsg ("Cannot allocate CARD!")));
        return -1;
    }

    elog (DEBUG1, "Start to get action.");
    context->act = get_action (context->dn, context->attach_flags, 5 * context->timeout);
    elog (DEBUG1, "Finish get action.");

    return 0;
}

int capi_regex_job_init (CAPIRegexJobDescriptor* job_desc,
                         CAPIContext* context)
{
    if (NULL == job_desc) {
        return -1;
    }

    if (NULL == context) {
        return -1;
    }

    // Init the job descriptor
    job_desc->context               = context;
    job_desc->patt_src_base         = NULL;
    job_desc->pkt_src_base          = NULL;
    job_desc->stat_dest_base        = NULL;
    job_desc->num_pkt               = 0;
    job_desc->num_matched_pkt       = 0;
    job_desc->pkt_size              = 0;
    job_desc->max_alloc_pkt_size    = 0;
    job_desc->patt_size             = 0;
    job_desc->pkt_size_wo_hw_hdr    = 0;
    job_desc->stat_size             = 0;
    job_desc->pattern               = NULL;
    job_desc->results               = NULL;
    job_desc->curr_result_id        = 0;
    job_desc->start_blk_id          = 0;
    job_desc->num_blks              = 0;
    job_desc->thread_id             = 0;
    job_desc->t_init                = 0;
    job_desc->t_init                = 0;
    job_desc->t_regex_patt          = 0;
    job_desc->t_regex_pkt           = 0;
    job_desc->t_regex_scan          = 0;
    job_desc->t_regex_harvest       = 0;
    job_desc->t_cleanup             = 0;

    job_desc->next_desc             = NULL;

    return 0;
}

int capi_regex_compile (CAPIRegexJobDescriptor* job_desc, const char* pattern)
{
    if (job_desc == NULL) {
        return -1;
    }

    job_desc->patt_src_base = capi_regex_compile_internal (pattern, & (job_desc->patt_size));

    if (job_desc->patt_size == 0 || job_desc->patt_src_base == NULL) {
        return -1;
    }

    return 0;
}

int capi_regex_scan (CAPIRegexJobDescriptor* job_desc)
{
    if (job_desc == NULL) {
        return -1;
    }

    if (capi_regex_scan_internal (job_desc->context->dn,
                                  job_desc->context->timeout,
                                  job_desc->patt_src_base,
                                  job_desc->pkt_src_base,
                                  job_desc->stat_dest_base,
                                  & (job_desc->num_matched_pkt),
                                  job_desc->patt_size,
                                  job_desc->pkt_size,
                                  job_desc->stat_size,
                                  job_desc->thread_id)) {

        ereport (ERROR,
                 (errcode (ERRCODE_INVALID_PARAMETER_VALUE),
                  errmsg ("Hardware ERROR!")));
        return -1;
    }

    return 0;
}

int print_results (size_t num_results, void* stat_dest_base)
{
    int i = 0, j = 0;
    uint16_t offset = 0;
    uint32_t pkt_id = 0;
    uint32_t patt_id = 0;
    int rc = 0;

    elog (INFO, "---- Result buffer address: %p ----\n", stat_dest_base);
    elog (INFO, "---- Number of result items: %zu ----\n", num_results);
    elog (INFO, "---- Results (HW: hardware) ----\n");
    elog (INFO, "PKT(HW) PATT(HW) OFFSET(HW)\n");

    for (i = 0; i < (int)num_results; i++) {
        for (j = 0; j < 4; j++) {
            patt_id |= (((uint8_t*)stat_dest_base)[i * 10 + j] << j * 8);
        }

        for (j = 4; j < 8; j++) {
            pkt_id |= (((uint8_t*)stat_dest_base)[i * 10 + j] << (j % 4) * 8);
        }

        for (j = 8; j < 10; j++) {
            offset |= (((uint8_t*)stat_dest_base)[i * 10 + j] << (j % 2) * 8);
        }

        elog (INFO, "%7d\t%6d\t%7d\n", pkt_id, patt_id, offset);

        patt_id = 0;
        pkt_id = 0;
        offset = 0;
    }

    return rc;
}

int get_results (void* result, size_t num_matched_pkt, void* stat_dest_base)
{
    int i = 0, j = 0;
    uint32_t pkt_id = 0;

    if (result == NULL) {
        return -1;
    }

    for (i = 0; i < (int)num_matched_pkt; i++) {
        for (j = 4; j < 8; j++) {
            pkt_id |= (((uint8_t*)stat_dest_base)[i * 10 + j] << (j % 4) * 8);
        }

        ((uint32_t*)result)[i] = pkt_id;

        pkt_id = 0;
    }

    return 0;
}

int capi_regex_result_harvest (CAPIRegexJobDescriptor* job_desc)
{
    if (job_desc == NULL) {
        return -1;
    }

    int count = 0;

    // Wait for transaction to be done.
    do {
        action_read (job_desc->context->dn, ACTION_STATUS_L, job_desc->thread_id);
        count++;
    } while (count < 10);

    uint32_t reg_data = action_read (job_desc->context->dn, ACTION_STATUS_H, job_desc->thread_id);
    job_desc->num_matched_pkt = reg_data;
    job_desc->results = (uint32_t*) palloc (reg_data * sizeof (uint32_t));

    elog (INFO, "Thread %d finished with %d matched packets", job_desc->thread_id, reg_data);

    if (get_results (job_desc->results, reg_data, job_desc->stat_dest_base)) {
        errno = ENODEV;
        return -1;
    }

    return 0;
}

int capi_regex_job_cleanup (CAPIRegexJobDescriptor* job_desc)
{
    if (job_desc == NULL) {
        return -1;
    }

    // TODO: card will be freed in hardware manager
    //snap_detach_action (job_desc->context->act);
    //// Unmap AFU MMIO registers, if previously mapped
    //snap_card_free (job_desc->context->dn);
    //elog (DEBUG2, "Free Card Handle: %p\n", job_desc->context->dn);

    // TODO: patt buffer will be freed in worker
    //free_mem (job_desc->patt_src_base);
    // TODO: packet buffer will be freed in job
    //free_mem (job_desc->pkt_src_base);
    // TODO: dest buffer will be freed in job
    //free_mem (job_desc->stat_dest_base);

    if (job_desc->results) {
        pfree (job_desc->results);
    }

    return 0;
}

bool capi_regex_check_relation (Relation rel)
{
    bool retVal = true;

    /* Check that this relation has storage */
    if (rel->rd_rel->relkind == RELKIND_VIEW) {
        ereport (ERROR,
                 (errcode (ERRCODE_WRONG_OBJECT_TYPE),
                  errmsg ("cannot get raw page from view \"%s\"",
                          RelationGetRelationName (rel))));
        retVal = false;
    }

    if (rel->rd_rel->relkind == RELKIND_COMPOSITE_TYPE) {
        ereport (ERROR,
                 (errcode (ERRCODE_WRONG_OBJECT_TYPE),
                  errmsg ("cannot get raw page from composite type \"%s\"",
                          RelationGetRelationName (rel))));
        retVal = false;
    }

    if (rel->rd_rel->relkind == RELKIND_FOREIGN_TABLE) {
        ereport (ERROR,
                 (errcode (ERRCODE_WRONG_OBJECT_TYPE),
                  errmsg ("cannot get raw page from foreign table \"%s\"",
                          RelationGetRelationName (rel))));
        retVal = false;
    }

    return retVal;
}

void print_result (CAPIRegexJobDescriptor* job_desc, char* header_str, char* out_str)
{
    sprintf (header_str, "num_pkt,pkt_size,init,patt,pkt_cpy,pkt_other,hw_re_scan,harvest,cleanup,hw_perf(MB/s),num_matched_pkt\n");
    sprintf (out_str, "%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%f,%ld",
             job_desc->num_pkt,
             job_desc->pkt_size_wo_hw_hdr,
             job_desc->t_init,
             job_desc->t_regex_patt,
             job_desc->t_regex_pkt_copy,
             job_desc->t_regex_pkt - job_desc->t_regex_pkt_copy,
             job_desc->t_regex_scan,
             job_desc->t_regex_harvest,
             job_desc->t_cleanup,
             perf_calc (job_desc->t_regex_scan / 1000, job_desc->pkt_size_wo_hw_hdr),
             job_desc->num_matched_pkt);
    print_time_text ("|Regex hardware scan|", job_desc->t_regex_scan / 1000, job_desc->pkt_size_wo_hw_hdr);
}

