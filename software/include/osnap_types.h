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
#ifndef __OSNAP_TYPES_H__
#define __OSNAP_TYPES_H__

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

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************
 * SNAP Job Definition
 *****************************************************************************/

/* Standardized, non-zero return codes to be expected from FPGA actions */
#define SNAP_RETC_SUCCESS                0x0102
#define SNAP_RETC_TIMEOUT                0x0103
#define SNAP_RETC_FAILURE                0x0104

/* FIXME Constants are too long, I like to type less */
#define SNAP_ADDRTYPE_UNUSED             0xffff
#define SNAP_ADDRTYPE_HOST_DRAM          0x0000 /* this is fine, always there */
#define SNAP_ADDRTYPE_CARD_DRAM          0x0001 /* card specific */
#define SNAP_ADDRTYPE_NVME               0x0002 /* card specific */
#define SNAP_ADDRTYPE_zzz                0x0003 /* ? */
#define SNAP_ADDRTYPE_LCL_MEM0           0x0010 /* card specific HBM or DDR Port 0 */
#define SNAP_ADDRTYPE_LCL_MEM1           0x0011 /* card specific HBM or DDR  Port 1 */
#define SNAP_ADDRTYPE_HBM_P0             0x0010 /* card specific HBM Port 0 */
#define SNAP_ADDRTYPE_HBM_P1             0x0011 /* card specific HBM Port 1 */
#define SNAP_ADDRTYPE_HBM_P2             0x0012 /* card specific HBM Port 2 */
#define SNAP_ADDRTYPE_HBM_P3             0x0013 /* card specific HBM Port 3 */
#define SNAP_ADDRTYPE_HBM_P4             0x0014 /* card specific HBM Port 4 */
#define SNAP_ADDRTYPE_HBM_P5             0x0015 /* card specific HBM Port 5 */
#define SNAP_ADDRTYPE_HBM_P6             0x0016 /* card specific HBM Port 6 */
#define SNAP_ADDRTYPE_HBM_P7             0x0017 /* card specific HBM Port 7 */
#define SNAP_ADDRTYPE_HBM_P8             0x0018 /* card specific HBM Port 8 */
#define SNAP_ADDRTYPE_HBM_P9             0x0019 /* card specific HBM Port 9 */
#define SNAP_ADDRTYPE_HBM_P10            0x001A /* card specific HBM Port 10 */
#define SNAP_ADDRTYPE_HBM_P11            0x001B /* card specific HBM Port 11 */
#define SNAP_ADDRTYPE_HBM_P12            0x001C /* card specific HBM Port 12 */
#define SNAP_ADDRTYPE_HBM_P13            0x001D /* card specific HBM Port 13 */
#define SNAP_ADDRTYPE_HBM_P14            0x001E /* card specific HBM Port 14 */
#define SNAP_ADDRTYPE_HBM_P15            0x001F /* card specific HBM Port 15 */
#define SNAP_ADDRTYPE_HBM_P16            0x0020 /* card specific HBM Port 16 */
#define SNAP_ADDRTYPE_HBM_P17            0x0021 /* card specific HBM Port 17 */
#define SNAP_ADDRTYPE_HBM_P18            0x0022 /* card specific HBM Port 18 */
#define SNAP_ADDRTYPE_HBM_P19            0x0023 /* card specific HBM Port 19 */
#define SNAP_ADDRTYPE_HBM_P20            0x0024 /* card specific HBM Port 20 */
#define SNAP_ADDRTYPE_HBM_P21            0x0025 /* card specific HBM Port 21 */
#define SNAP_ADDRTYPE_HBM_P22            0x0026 /* card specific HBM Port 22 */
#define SNAP_ADDRTYPE_HBM_P23            0x0027 /* card specific HBM Port 23 */
#define SNAP_ADDRTYPE_HBM_P24            0x0028 /* card specific HBM Port 24 */
#define SNAP_ADDRTYPE_HBM_P25            0x0029 /* card specific HBM Port 25 */
#define SNAP_ADDRTYPE_HBM_P26            0x002A /* card specific HBM Port 26 */
#define SNAP_ADDRTYPE_HBM_P27            0x002B /* card specific HBM Port 27 */
#define SNAP_ADDRTYPE_HBM_P28            0x002C /* card specific HBM Port 28 */
#define SNAP_ADDRTYPE_HBM_P29            0x002D /* card specific HBM Port 29 */
#define SNAP_ADDRTYPE_HBM_P30            0x002E /* card specific HBM Port 30 */
#define SNAP_ADDRTYPE_HBM_P31            0x002F /* card specific HBM Port 31 */

#define SNAP_ADDRFLAG_END                0x0001 /* last element in the list */
#define SNAP_ADDRFLAG_ADDR               0x0002 /* this one is an address */
#define SNAP_ADDRFLAG_DATA               0x0004 /* 64-bit address */
#define SNAP_ADDRFLAG_EXT                0x0008 /* reserved for extension */
#define SNAP_ADDRFLAG_SRC                0x0010 /* data source */
#define SNAP_ADDRFLAG_DST                0x0020 /* data destination */

typedef uint16_t snap_addrtype_t;
typedef uint16_t snap_addrflag_t;

typedef struct snap_addr {
    uint64_t addr;
    uint32_t size;
    snap_addrtype_t type;                /* DRAM, NVME, ... */
    snap_addrflag_t flags;                /* SRC, DST, EXT, ... */
} snap_addr_t;                                /* 16 bytes */

static inline void snap_addr_set (struct snap_addr* da,
                                  const void* addr,
                                  uint32_t size,
                                  snap_addrtype_t type,
                                  snap_addrflag_t flags)
{
    da->addr = (unsigned long)addr;
    da->size = size;
    da->type = type;
    da->flags = flags;
}

/*
 * Maximum size of an SNAP HLS job without addr extension, this size is required
 * such that the output MMIO registers will end up at the correct address offset.
 */
#define SNAP_JOBSIZE (16 * 6) /* 108 */

#ifdef __cplusplus
}
#endif

#endif /* __OSNAP_TYPES_H__ */
