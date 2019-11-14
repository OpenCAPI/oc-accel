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
#ifndef __OSNAP_INTERNAL_H__
#define __OSNAP_INTERNAL_H__


/**
 * Copyright 2016, 2017 International Business Machines
 * Copyright 2016 Rackspace Inc.
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

#include <stdint.h>
#include <libosnap.h>
#include <sys/time.h>
#include <unistd.h>
#include <sys/syscall.h>   /* For SYS_xxx definitions */

#include "osnap_queue.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __unused
#  define __unused __attribute__((unused))
#endif

#ifndef ARRAY_SIZE
#  define ARRAY_SIZE(a)  (sizeof((a)) / sizeof((a)[0]))
#endif

#ifndef ABS
#  define ABS(a)         (((a) < 0) ? -(a) : (a))
#endif

#ifndef MAX
#  define MAX(a,b)        ({ __typeof__ (a) _a = (a); \
        __typeof__ (b) _b = (b); \
        (_a) > (_b) ? (_a) : (_b); })
#endif

#ifndef MIN
#  define MIN(a,b)        ({ __typeof__ (a) _a = (a); \
        __typeof__ (b) _b = (b); \
        (_a) < (_b) ? (_a) : (_b); })
#endif

#define        CACHELINE_BYTES        128

//#define        ACTION_BASE 0x200000

struct snap_funcs {
    void* (* card_alloc_dev) (const char* path, uint16_t vendor_id,
                              uint16_t device_id);

    struct snap_action* (* attach_action) (struct snap_card* card,
                                           snap_action_type_t action_type,
                                           snap_action_flag_t action_flags,
                                           int timeout_sec);
    int (* detach_action) (struct snap_action* action);

    int (* mmio_per_pasid_write32) (struct snap_card* card, uint64_t offset, uint32_t data);
    int (* mmio_per_pasid_read32) (struct snap_card* card, uint64_t offset, uint32_t* data);
    int (* mmio_global_write64) (struct snap_card* card, uint64_t offset, uint64_t data);
    int (* mmio_global_read64) (struct snap_card* card, uint64_t offset, uint64_t* data);
    void (* card_free) (struct snap_card* card);
    int (* card_ioctl) (struct snap_card* card, unsigned int cmd, unsigned long arg);
};

static inline pid_t __gettid (void)
{
    return (pid_t)syscall (SYS_gettid);
}

static inline long long __get_usec (void)
{
    struct timeval t;
    gettimeofday (&t, NULL);
    return t.tv_sec * 1000000LL + t.tv_usec;
}

int action_trace_enabled (void);
int block_trace_enabled (void);
int cache_trace_enabled (void);
int stat_trace_enabled (void);
int pp_trace_enabled (void);

#define act_trace(fmt, ...) do {                                        \
        if (action_trace_enabled())                                \
            fprintf(stderr, "A " fmt, ## __VA_ARGS__);        \
    } while (0)

#define block_trace(fmt, ...) do {                                     \
        if (block_trace_enabled()) {                           \
            fprintf(stderr, "B %08x.%08x %-16lld " fmt,    \
                    getpid(), __gettid(), __get_usec(),    \
                    ## __VA_ARGS__);                               \
        }                                                      \
    } while (0)

#define cache_trace(fmt, ...) do {                                     \
        if (cache_trace_enabled()) {                           \
            fprintf(stderr, "C %08x.%08x %-16lld " fmt,    \
                    getpid(), __gettid(), __get_usec(),    \
                    ## __VA_ARGS__);                               \
        }                                                      \
    } while (0)

#define stat_trace(fmt, ...) do {                                      \
        if (stat_trace_enabled()) {                            \
            fprintf(stderr, "S %08x.%08x %-16lld " fmt,    \
                    getpid(), __gettid(), __get_usec(),    \
                    ## __VA_ARGS__);                               \
        }                                                      \
    } while (0)

#define pp_trace(fmt, ...) do {                                        \
        if (pp_trace_enabled()) {                              \
            fprintf(stderr, "P %08x.%08x %-16lld " fmt,    \
                    getpid(), __gettid(), __get_usec(),    \
                    ## __VA_ARGS__);                               \
        }                                                      \
    } while (0)


#ifdef __cplusplus
}
#endif

#endif        /* __OSNAP_INTERNAL_H__ */
