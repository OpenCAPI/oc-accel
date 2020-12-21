#ifndef __ACTION_UDP_H__
#define __ACTION_UDP_H__

/*
 * Copyright 2020 International Business Machines
 * Copyright 2019 Paul Scherrer Institute
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

#include <osnap_types.h>

#define OCACCEL

#define FRAME_BUF_SIZE        16384L
#define FRAME_STATUS_BUF_SIZE 16384

#define NMODULES 4

#define MODULE_COLS 1024L
#define MODULE_LINES 512L

#define NPIXEL (NMODULES*MODULE_COLS*MODULE_LINES)

#define MODE_RESET          5

#ifdef __cplusplus
extern "C" {
#endif

/* This number is unique and is declared in ~snap/ActionTypes.md */
#define ACTION_TYPE   0x10143010
#define RELEASE_LEVEL 0x00000001
// Following number defines the number of AXI interfaces for the HBM. It is used to check compatibility
// with the number of AXI interfaces in the hardware and is set in the image "oc_maint" shows it).
#define HBM_AXI_IF_NB             12

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct rx100G_job {
    struct snap_addr out_frame_buffer;
    uint64_t packets_to_read;
    uint64_t read_size;
    uint64_t bad_packets;
    uint64_t ignored_packets;
    uint64_t good_packets;
    uint64_t fpga_mac_addr;
    uint32_t fpga_ipv4_addr;
    uint32_t user;
    uint32_t mode;  
    uint32_t dummy;    // to align with 8 bytes
} rx100G_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_UDP_H */
