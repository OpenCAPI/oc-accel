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
#ifndef __OSNAP_HLS_IF_H__
#define __OSNAP_HLS_IF_H__

/**
 * Copyright 2017 International Business Machines
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

#ifdef __cplusplus
extern "C" {
#endif

#include <malloc.h>

/* Action Address map defined by Vivado HLS     */
/* Search the contents in Xilinx document ug902 */            	
#define ACTION_CONTROL             0x00              /* Control signals */
#define ACTION_CONTROL_START       0x00000001        /* ap_start (Clear on Handshake) */
#define ACTION_CONTROL_DONE        0x00000002        /* ap_done (Clear on Read) */
#define ACTION_CONTROL_IDLE        0x00000004        /* ap_idle (Read Only) */
#define ACTION_CONTROL_RUN         0x00000008        /* ap_ready (Read Only) */

#define ACTION_IRQ_CONTROL         0x04              /* Global Interrupt Enable Register */
#define ACTION_IRQ_CONTROL_ON      0x00000001        /* Global Interrupt Enable (Read/Write) */
#define ACTION_IRQ_CONTROL_OFF     0x00000000        /* Global Interrupt Disable (Read/Write) */

#define ACTION_IRQ_APP             0x08              /* IP Interrupt Enable Register (Read/Write) */
#define ACTION_IRQ_APP_DONE        0x00000001        /* Channel 0 (ap_done)*/
#define ACTION_IRQ_APP_READY       0x00000002        /* Channel 1 (ap_ready) FIXME: not implemented yet */

#define ACTION_IRQ_STATUS          0x0c              /* IP Interrupt Status Register (Read/TOW) */
#define ACTION_IRQ_STATUS_DONE     0x00000001        /* Channel 0 (ap_done)*/
#define ACTION_IRQ_STATUS_READY    0x00000002        /* Channel 1 (ap_ready) FIXME: not implemented yet*/


#define ACTION_TYPE_REG            0x10              /* SNAP Action Type Register */
#define ACTION_RELEASE_REG         0x14              /* SNAP Action Release version Register */


#define ACTION_IRQ_SRC_LO          0x18              /* SNAP Action interrupt src (low 32bits) (obj_handler) */
#define ACTION_IRQ_SRC_HI          0x1C              /* SNAP Action interrupt src (high 32bits) (obj_handler) */

#define ACTION_HBM_AXI_NUM         0x20              /* SNAP Action number of HBM AXI interfaces */

/* ACTION Specific register setup: Input */
#define ACTION_PARAMS_IN           0x100
#define ACTION_RETC_IN             (ACTION_PARAMS_IN + 4)

/* ACTION Specific register setup: Output */
#define ACTION_PARAMS_OUT          (ACTION_PARAMS_IN + 0x80)
#define ACTION_RETC_OUT            (ACTION_PARAMS_OUT + 4)


#define SNAP_MEMBUS_WIDTH          128                /* bytes */
#define SNAP_ROUND_UP(x, width) (((x) + (width) - 1) & ~((width) - 1))

static inline void* snap_malloc (size_t size)
{
    unsigned int page_size = sysconf (_SC_PAGESIZE);
    return memalign (page_size, SNAP_ROUND_UP (size, SNAP_MEMBUS_WIDTH));
}

#ifdef __cplusplus
}
#endif

#endif /*__OSNAP_HLS_IF_H__ */
