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
#define ACTION_TYPE_HDL_MULTI_PROCESS     0x1014100E

#define REG_SNAP_CONTROL        0x00
#define REG_SNAP_INT_ENABLE     0x04
#define REG_SNAP_ACTION_TYPE    0x10
#define REG_SNAP_ACTION_VERSION 0x14
#define REG_SNAP_CONTEXT        0x20
#define REG_MP_CONTROL          0x24
#define REG_MP_INIT_ADDR_LO     0x28
#define REG_MP_INIT_ADDR_HI     0x2C
#define REG_MP_CMPL_ADDR_LO     0x30
#define REG_MP_CMPL_ADDR_HI     0x34

#endif  /* __HDL_MULTI_PROCESS__ */
