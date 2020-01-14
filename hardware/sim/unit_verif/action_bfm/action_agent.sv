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
`ifndef _ACTION_AGENT_SV
`define _ACTION_AGENT_SV

`include "../../../hdl/core/snap_global_vars.v"

class action_agent extends uvm_agent;

    //Component and Object declaration
    `ifndef ENABLE_ODMA
        axi_mm_mst_agent    mm_mst_agt;
    `else
        `ifndef ENABLE_ODMA_ST_MODE
            axi_mm_slv_agent    mm_slv_agt;
        `else
            axi_st_mst_agent    st_mst_agt;
            axi_st_slv_agent    st_slv_agt;
        `endif
    `endif
    axi_lite_slv_agent   lite_slv_agt;
    action_seqr          act_sqr;
    action_seqr_st       act_sqr_st;
    act_cfg_obj          act_cfg;

    int             agent_id;

    `uvm_component_utils_begin(action_agent)
        `uvm_field_int   (agent_id,  UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name="action_agent", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        lite_slv_agt = axi_lite_slv_agent::type_id::create("lite_slv_agt", this);
        act_sqr = action_seqr::type_id::create("act_sqr", this);
        act_sqr_st = action_seqr_st::type_id::create("act_sqr_st", this);
        act_cfg = act_cfg_obj::type_id::create("act_cfg", this);
        `ifndef ENABLE_ODMA
            mm_mst_agt = axi_mm_mst_agent::type_id::create("mm_mst_agt", this);
            uvm_config_db #(act_cfg_obj)::set(this, "mm_mst_agt", "act_cfg", act_cfg);
        `else
            `ifndef ENABLE_ODMA_ST_MODE
                mm_slv_agt = axi_mm_slv_agent::type_id::create("mm_slv_agt", this);
            `else
                st_slv_agt = axi_st_slv_agent::type_id::create("st_slv_agt", this);
                st_mst_agt = axi_st_mst_agent::type_id::create("st_mst_agt", this);
            `endif
        `endif
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `ifndef ENABLE_ODMA
            mm_mst_agt.seq_item_port.connect(act_sqr.seq_item_export);
        `else
            `ifndef ENABLE_ODMA_ST_MODE
            `else
                st_mst_agt.seq_item_port.connect(act_sqr_st.seq_item_export);
            `endif
        `endif
    endfunction: connect_phase

endclass: action_agent

`endif

