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
`ifndef _ACTION_BFM_PKG_SVH_
`define _ACTION_BFM_PKG_SVH_

`include "../../../hdl/core/snap_global_vars.v"

//CONFIG
`include "act_cfg_obj.sv"

//SEQUENCE
`include "action_seqr.sv"
`include "action_seqr_st.sv"

//AGENTS
`ifndef ENABLE_ODMA
    `include "axi_mm_mst_agent.sv"
`else
    `ifndef ENABLE_ODMA_ST_MODE
        `include "axi_mm_slv_agent.sv"
    `else
        `include "axi_st_slv_agent.sv"
        `include "axi_st_mst_agent.sv"
    `endif
`endif
`include "axi_lite_slv_agent.sv"
`include "action_agent.sv"

`endif // _ACTION_BFM_PKG_SVH_

