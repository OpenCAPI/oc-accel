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

#ifndef __SNAP_FW_EXA__
#define __SNAP_FW_EXA__

#include "unistd.h"
#include "libosnap.h"

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */
#include <osnap_hls_if.h>

#include "constants.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <getopt.h>
#include <ctype.h>

#include <libosnap.h>
#include <osnap_tools.h>
//#include <osnap_action_regs.h>
#include <osnap_global_regs.h>


/*  defaults */
#define STEP_DELAY      200
#define DEFAULT_MEMCPY_BLOCK    4096
#define DEFAULT_MEMCPY_ITER 1
#define ACTION_WAIT_TIME    10   /* Default in sec */
//#define MAX_NUM_PKT 502400
//#define MAX_NUM_PKT 4096
#define MIN_NUM_PKT 4096
#define MAX_NUM_PATT 1024

#define MEGAB       (1024*1024ull)
#define GIGAB       (1024 * MEGAB)


#define PERF_MEASURE(_func, out) \
    do { \
        struct timespec t_beg, t_end; \
        clock_gettime(CLOCK_REALTIME, &t_beg); \
        ERROR_CHECK((_func)); \
        clock_gettime(CLOCK_REALTIME, &t_end); \
        (out) = diff_time (&t_beg, &t_end); \
    } \
    while (0)

#define ERROR_LOG(_file, _func, _line, _rc) \
    do { \
        print_error((_file), (_func), (const char*) (_line), (_rc)); \
    } \
    while (0)

#define ERROR_CHECK(_err) \
    do { \
        int rc = (_err); \
        if (rc != 0) \
        { \
            ERROR_LOG (__FILE__, __FUNCTION__, __LINE__, rc); \
            goto fail; \
        } \
    } while (0)

void print_error (const char* file, const char* func, const char* line, int rc);
int64_t diff_time (struct timespec* t_beg, struct timespec* t_end);
uint64_t get_usec (void);
int get_file_line_count (FILE* fp);
void remove_newline (char* str);
float print_time (uint64_t elapsed, uint64_t size);
void* alloc_mem (int align, size_t size);
void free_mem (void* a);

void* fill_one_packet (const char* in_pkt, int size, void* in_pkt_addr);
void* fill_one_pattern (const char* in_patt, void* in_patt_addr);

void action_write (struct snap_card* h, uint32_t addr, uint32_t data);
uint32_t action_read (struct snap_card* h, uint32_t addr);
int action_wait_idle (struct snap_card* h, int timeout, uint64_t* elapsed);
void print_control_status (struct snap_card* h, int eng_id);
void soft_reset (struct snap_card* h, int eng_id);
void action_regex (struct snap_card* h,
                       void* patt_src_base,
                       void* pkt_src_base,
                       void* stat_dest_base,
                       size_t* num_matched_pkt,
                       size_t patt_size,
                       size_t pkt_size,
                       size_t stat_size,
                       int eng_id);
void config_single_regex  (struct snap_card* h,
                   void* patt_src_base,
                   void* pkt_src_base,
                   void* stat_dest_base,
                   size_t patt_size,
                   size_t pkt_size,
                   size_t stat_size,
                   int eng_id);
void pattern_copy_regex (struct snap_card* h,
                   void* patt_src_base,
                   void* pkt_src_base,
                   void* stat_dest_base,
                   size_t patt_size,
                   size_t pkt_size,
                   size_t stat_size,
                   int eng_num);
void engine_work_regex (struct snap_card* h,
                   void* patt_src_base,
                   void* pkt_src_base,
                   void* stat_dest_base,
                   size_t patt_size,
                   size_t pkt_size,
                   size_t stat_size,
                   int eng_num);
void stat_flush_regex (struct snap_card* h,
                   void* patt_src_base,
                   void* pkt_src_base,
                   void* stat_dest_base,
                   size_t patt_size,
                   size_t pkt_size,
                   size_t stat_size,
                   int eng_num);
int regex_scan_one_thread (struct snap_card* dnc,
                int timeout,
                void* patt_src_base,
                void* pkt_src_base,
                void* stat_dest_base,
                size_t patt_size,
                size_t pkt_size,
                size_t stat_size,
                int eng_num);
int regex_scan (struct snap_card* dnc,
                    int timeout,
                    void* patt_src_base,
                    void* pkt_src_base,
                    void* stat_dest_base,
                    size_t* num_matched_pkt,
                    size_t patt_size,
                    size_t pkt_size,
                    size_t stat_size,
                    int eng_id);
struct snap_action* get_action (struct snap_card* handle,
                                       snap_action_flag_t flags, int timeout);

void* sm_compile_file (const char* file_path, size_t* size);
void* regex_scan_file (const char* file_path, size_t* size, size_t* size_for_sw);
int print_results (size_t num_results, void* stat_dest_base);
int compare_results (size_t num_matched_pkt, void* stat_dest_base, int no_chk_offset);

#endif	/* __SNAP_FW_EXA__ */
