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

#ifndef __HDL_MULTI_PROCESS__
#define __HDL_MULTI_PROCESS__

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */
#define ACTION_TYPE_HDL_MULTI_PROCESS     0x1014200E	/* Action Type */
#define ACTION_REG_BASE                0x200
#define ACTION_REG_ENG_RANGE           0x100
#define reg(_reg,_id) ((ACTION_REG_BASE + (_id * ACTION_REG_ENG_RANGE)) + _reg)

#define REG_SNAP_CONTROL        0x00
#define REG_SNAP_INT_ENABLE     0x04
#define REG_SNAP_ACTION_TYPE    0x10
#define REG_SNAP_ACTION_VERSION 0x14
#define REG_SNAP_CONTEXT        0x20
// User defined below
#define REG_USER_STATUS         0x30
#define REG_USER_CONTROL        0x34
#define REG_USER_MODE           0x38
#define REG_INIT_RDATA          0x3C //Non-zero init Read Data 
#define REG_INIT_WDATA          0x40 //Non-zero init Write Data

//Following four Time Trace RAMs when read the MMIO port, the RAM
//address is increased by 1 automatically
#define REG_TT_RD_CMD           0x44 //Time Trace RAM, when ARVALID is sent
#define REG_TT_RD_RSP           0x48 //Time Trace RAM, when RLAST is received
#define REG_TT_WR_CMD           0x4C //Time Trace RAM, when AWVALID is sent
#define REG_TT_WR_RSP           0x50 //Time Trace RAM, when BVALID is received

#define REG_TT_ARID             0x54 //ID Trace RAM, 
#define REG_TT_AWID             0x58 //ID Trace RAM, 
#define REG_TT_RID              0x5C //ID Trace RAM, 
#define REG_TT_BID              0x60 //ID Trace RAM, 

#define REG_RD_PATTERN          0x64 //AXI Read pattern
#define REG_RD_NUMBER           0x68 //how many AXI Read transactions
#define REG_WR_PATTERN          0x6C //AXI Write Pattern
#define REG_WR_NUMBER           0x70 //how many AXI Write trasactions

#define REG_SOURCE_ADDRESS_L    0x74
#define REG_SOURCE_ADDRESS_H    0x78
#define REG_TARGET_ADDRESS_L    0x7C
#define REG_TARGET_ADDRESS_H    0x80

#define REG_ERROR_INFO_L        0x84
#define REG_ERROR_INFO_H        0x88
#define REG_SOFT_RESET          0x8C


#endif	/* __HDL_MULTI_PROCESS__ */
