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
#ifndef __OCACCEL_GLOBAL_REGS_H__
#define __OCACCEL_GLOBAL_REGS_H__

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
//***************************************************************************
//***************************************************************************
//
//This file defines the registers in Global MMIO space, or ocaccel registers.
//
//***************************************************************************
//***************************************************************************
#define OPENCAPI30
    //FIXME!

#define INFRA_BASE_ADDR 0x0
#define DEBUG_BASE_ADDR 0x1A000
#define   FIR_BASE_ADDR 0x1C000

#define OCACCEL_M_FIR_NUM  5


//-----------------------------------
#define OCACCEL_REG_IMP_VERSION        ( INFRA_BASE_ADDR + 0x0  )
#define OCACCEL_REG_BUILD_DATE         ( INFRA_BASE_ADDR + 0x8  )
#define OCACCEL_REG_COMMAND            ( INFRA_BASE_ADDR + 0x10 )
#define OCACCEL_REG_STATUS             ( INFRA_BASE_ADDR + 0x18 )
#define OCACCEL_REG_CAPABILITY         ( INFRA_BASE_ADDR + 0x30 )

#define OCACCEL_REG_ACTION_NAME_STR1   ( INFRA_BASE_ADDR + 0x40 )
#define OCACCEL_REG_ACTION_NAME_STR2   ( INFRA_BASE_ADDR + 0x48 )
#define OCACCEL_REG_ACTION_NAME_STR3   ( INFRA_BASE_ADDR + 0x50 )
#define OCACCEL_REG_ACTION_NAME_STR4   ( INFRA_BASE_ADDR + 0x58 )

//-----------------------------------
#define OCACCEL_REG_DBG_CLEAR          ( DEBUG_BASE_ADDR + 0x00 )
#ifdef OPENCAPI30
#define OCACCEL_REG_CNT_TLX_CMD        ( DEBUG_BASE_ADDR + 0x08 )
#define OCACCEL_REG_CNT_TLX_RSP        ( DEBUG_BASE_ADDR + 0x10 )
#define OCACCEL_REG_CNT_TLX_RTY        ( DEBUG_BASE_ADDR + 0x18 )
#define OCACCEL_REG_CNT_TLX_FAIL       ( DEBUG_BASE_ADDR + 0x20 )
#define OCACCEL_REG_CNT_TLX_XLP        ( DEBUG_BASE_ADDR + 0x28 )
#define OCACCEL_REG_CNT_TLX_XLD        ( DEBUG_BASE_ADDR + 0x30 )
#define OCACCEL_REG_CNT_TLX_XLR        ( DEBUG_BASE_ADDR + 0x38 )
#endif
#define OCACCEL_REG_CNT_AXI_CMD        ( DEBUG_BASE_ADDR + 0x40 )
#define OCACCEL_REG_CNT_AXI_RSP        ( DEBUG_BASE_ADDR + 0x48 )
#define OCACCEL_REG_BUF_CNT            ( DEBUG_BASE_ADDR + 0x50 )

//-----------------------------------
#define OCACCEL_REG_DATA_BRIDGE        (   FIR_BASE_ADDR + 0x00 )
#ifdef OPENCAPI30
#define OCACCEL_REG_TRANS_PROTOCOL     (   FIR_BASE_ADDR + 0x08 )
#endif


#define OCACCEL_NVME_ENA   0x100
#define AD9V3_OC_CARD   0x031     /* OpenCAPI 3.0*/
#define AD9H3_OC_CARD   0x032     /* OpenCAPI 3.0*/
#define AD9H7_OC_CARD   0x033     /* OpenCAPI 3.0*/


#ifdef __cplusplus
}
#endif

#endif        /* __OCACCEL_GLOBAL_REGS_H__ */
