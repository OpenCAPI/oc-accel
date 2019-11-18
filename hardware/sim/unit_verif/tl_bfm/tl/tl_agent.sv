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
`ifndef _TL_AGENT_SV
`define _TL_AGENT_SV

class tl_agent extends uvm_agent;

    //Component and Object declaration
    tl_tx_seqr       tx_sqr;
    tl_tx_driver     tx_drv;
    tl_tx_monitor    tx_mon;
    tl_rx_monitor    rx_mon;
    tl_scoreboard    sbd;
    tl_manager       mgr;
    tl_cfg_obj       cfg_obj;
    tl_mem_model     mem_model;
    //lane_width_agent lane_agt;

    int             agent_id;

    `uvm_component_utils_begin(tl_agent)
        `uvm_field_int   (agent_id,  UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name="tl_agent", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_sqr = tl_tx_seqr::type_id::create("tx_sqr", this);
        tx_drv = tl_tx_driver::type_id::create("tx_drv", this);
        tx_mon = tl_tx_monitor::type_id::create("tx_mon", this);
        rx_mon = tl_rx_monitor::type_id::create("rx_mon", this);
        sbd = tl_scoreboard::type_id::create("sbd", this);
        mgr = tl_manager::type_id::create("mgr", this);
        cfg_obj = tl_cfg_obj::type_id::create("cfg_obj", this);
        mem_model = tl_mem_model::type_id::create("mem_model", this);
        //lane_agt = lane_width_agent::type_id::create("lane_agt", this);
        uvm_config_db #(tl_cfg_obj)::set(this, "tx_drv", "cfg_obj", cfg_obj);
        uvm_config_db #(tl_cfg_obj)::set(this, "tx_mon", "cfg_obj", cfg_obj);
        uvm_config_db #(tl_cfg_obj)::set(this, "rx_mon", "cfg_obj", cfg_obj);
        uvm_config_db #(tl_cfg_obj)::set(this, "sbd", "cfg_obj", cfg_obj);
        uvm_config_db #(tl_cfg_obj)::set(this, "mgr", "cfg_obj", cfg_obj);
        uvm_config_db #(tl_mem_model)::set(this, "sbd", "mem_model", mem_model);
        uvm_config_db #(tl_mem_model)::set(this, "tx_drv", "mem_model", mem_model);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        tx_drv.seq_item_port.connect(tx_sqr.seq_item_export);
        mgr.mgr_output_trans_port.connect(tx_drv.tl_mgr_imp);
        mgr.mgr_output_credit_port.connect(tx_drv.tl_credit_imp);
        tx_mon.tl_tx_trans_ap.connect(mgr.mgr_input_tx_port);
        tx_mon.tl_tx_trans_ap.connect(sbd.scoreboard_input_tx_port);
        rx_mon.tl_rx_ap.connect(mgr.mgr_input_rx_port);
        rx_mon.tl_rx_ap.connect(sbd.scoreboard_input_rx_port);
        rx_mon.tl_rx2mgr_ap.connect(mgr.mgr_input_credit_port);
        tx_drv.mgr = this.mgr;
        sbd.tl_drv_resp_ap.connect(tx_drv.tl_sbd_resp_imp);
    endfunction: connect_phase

    task reset();
        `uvm_info(get_type_name(),$psprintf("TL BFM is starting to reset!!!"), UVM_MEDIUM)
        tx_drv.reset();
        tx_mon.reset();
        rx_mon.reset();
        sbd.reset();
        mem_model.reset();
        mgr.reset();
        `uvm_info(get_type_name(),$psprintf("TL BFM reset is finished!!!"), UVM_MEDIUM)
    endtask: reset

endclass: tl_agent

`endif

