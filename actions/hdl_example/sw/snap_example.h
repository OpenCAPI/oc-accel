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

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */
#include <osnap_hls_if.h>

/* Header file for SNAP Framework example code */
#define ACTION_TYPE     0x10142000
#define RELEASE_LEVEL   0x00000000

#define ACTION_CONFIG           0x30
#define ACTION_CONFIG_COUNT     1       /* Count Mode */
#define ACTION_CONFIG_COPY_HH   2       /* Memcopy Host to Host */
#define ACTION_CONFIG_COPY_HD   3       /* Memcopy Host to DDR */
#define ACTION_CONFIG_COPY_DH   4       /* Memcopy DDR to Host */
#define ACTION_CONFIG_COPY_DD   5       /* Memcopy DDR to DDR */
#define ACTION_CONFIG_COPY_HDH  6       /* Memcopy Host to DDR to Host */
#define ACTION_CONFIG_MEMSET_H  8       /* Memset Host Memory */
#define ACTION_CONFIG_MEMSET_F  9       /* Memset FPGA Memory */
#define ACTION_CONFIG_COPY_DN   0x0a    /* Copy DDR to NVME drive 0 */
#define ACTION_CONFIG_COPY_ND   0x0b    /* Copy NVME drive 0 to DDR */
#define NVME_DRIVE1		0x10	/* Select Drive 1 for 0a and 0b */

#define ACTION_SRC_LOW          0x34	/* LBA for 0A, 1A, 0B and 1B */
#define ACTION_SRC_HIGH         0x38
#define ACTION_DEST_LOW         0x3c	/* LBA for 0A, 1A, 0B and 1B */
#define ACTION_DEST_HIGH        0x40
#define ACTION_CNT              0x44    /* Count Register or # of 512 Byte Blocks for NVME */
#define ACTION_IRQ_SRC_HIGH     0x48    /* Interrupt source high */
#define ACTION_IRQ_SRC_LOW      0x4C    /* Interrupt source low */

#endif	/* __SNAP_FW_EXA__ */
