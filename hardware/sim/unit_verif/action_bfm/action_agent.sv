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
            axi_st_slv_agent    st_slv_agt;
        `endif
    `endif
    axi_lite_slv_agent    lite_slv_agt;
    action_seqr           act_sqr;
    //tl_tx_driver     tx_drv;
    //tl_tx_monitor    tx_mon;
    //tl_rx_monitor    rx_mon;
    //tl_scoreboard    sbd;
    //tl_manager       mgr;
    //tl_cfg_obj       cfg_obj;
    //tl_mem_model     mem_model;
    ////lane_width_agent lane_agt;

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
        `ifndef ENABLE_ODMA
            act_sqr = action_seqr::type_id::create("act_sqr", this);
            mm_mst_agt = axi_mm_mst_agent::type_id::create("mm_mst_agt", this);
        `else
            `ifndef ENABLE_ODMA_ST_MODE
                mm_slv_agt = axi_mm_slv_agent::type_id::create("mm_slv_agt", this);
            `else
                st_slv_agt = axi_st_slv_agent::type_id::create("st_slv_agt", this);
            `endif
        `endif
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `ifndef ENABLE_ODMA
            mm_mst_agt.seq_item_port.connect(act_sqr.seq_item_export);
        `else
        `endif
        ////tx_drv.seq_item_port.connect(tx_sqr.seq_item_export);
        //mgr.mgr_output_trans_port.connect(tx_drv.tl_mgr_imp);
        //mgr.mgr_output_credit_port.connect(tx_drv.tl_credit_imp);
        //tx_mon.tl_tx_trans_ap.connect(mgr.mgr_input_tx_port);
        //tx_mon.tl_tx_trans_ap.connect(sbd.scoreboard_input_tx_port);
        //rx_mon.tl_rx_ap.connect(mgr.mgr_input_rx_port);
        //rx_mon.tl_rx_ap.connect(sbd.scoreboard_input_rx_port);
        //rx_mon.tl_rx2mgr_ap.connect(mgr.mgr_input_credit_port);
        //tx_drv.mgr = this.mgr;
        //sbd.tl_drv_resp_ap.connect(tx_drv.tl_sbd_resp_imp);
    endfunction: connect_phase

endclass: action_agent

`endif

