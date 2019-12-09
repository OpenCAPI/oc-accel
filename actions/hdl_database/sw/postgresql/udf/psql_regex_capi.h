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

#ifndef __PSQL_REGEX_CAPI__
#define __PSQL_REGEX_CAPI__

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */
#include <osnap_hls_if.h>

#include "constants.h"

typedef struct CAPIRegexJobDescriptor_s {
    // CAPI device name
    char device[64];
    // CAPI-SNAP card handler
    struct snap_card* dn;
    // Card number
    int card_no;
    // Timeout value before waiting for a card to be valid
    int timeout;
    // Action flags
    snap_action_flag_t attach_flags;
    // Action handler
    struct snap_action* act;
    // Pointer to pattern buffer
    void* patt_src_base;
    // Pointer to packet buffer
    void* pkt_src_base;
    // Pointer to destination buffer (result buffer)
    void* stat_dest_base;
    // Number of total packets
    size_t num_pkt;
    // Number of matched packets
    size_t num_matched_pkt;
    // Size of the packet buffer
    size_t pkt_size;
    // Size of the pattern buffer
    size_t patt_size;
    // Size of the packet buffer - hardware headers
    size_t pkt_size_wo_hw_hdr;
    // Size of the output buffer
    size_t stat_size;
    // C string to the pattern
    // TODO: currently only 1 pattern for each job
    char* pattern;

    // The pointer to the results (id of matched packets)
    uint32_t* results;

    // Perf statistics (in nano seconds);
    int64_t t_init;
    int64_t t_regex_patt; // Pattern compile time
    int64_t t_regex_pkt; // The whole pkt preparation time
    int64_t t_regex_pkt_copy; // only the memcpy time
    int64_t t_regex_scan;
    int64_t t_regex_harvest;
    int64_t t_cleanup;
} CAPIRegexJobDescriptor;

void print_error(const char* file, const char* func, const char* line, int rc);
int64_t diff_time (struct timespec* t_beg, struct timespec* t_end);

void print_error(const char* file, const char* func, const char* line, int rc)
{
    printf("ERROR: %s %s failed in line %s with return code %d\n", file, func, line, rc);
}

int64_t diff_time (struct timespec* t_beg, struct timespec* t_end)
{
    if (t_end == NULL || t_beg == NULL) {
        return 0;
    }
    return ((t_end-> tv_sec - t_beg-> tv_sec) * 1000000000L + t_end-> tv_nsec - t_beg-> tv_nsec);
}

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
        print_error((_file), (_func), (_line), (_rc)); \
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

#endif  /* __PSQL_REGEX_CAPI__ */
