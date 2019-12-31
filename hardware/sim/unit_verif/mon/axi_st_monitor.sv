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

`ifndef _AXI_ST_MONITOR_SV_
`define _AXI_ST_MONITOR_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_st_monitor
//
// XXX
//-------------------------------------------------------------------------------------

class axi_st_monitor extends uvm_monitor;

    virtual interface                          axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_H2A_PARAMS st_h2a_vif;
    virtual interface                          axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_A2H_PARAMS st_a2h_vif;
    axi_vip_st_passthrough_h2a_passthrough_t       st_h2a_passthrough;
    axi_vip_st_passthrough_a2h_passthrough_t       st_a2h_passthrough;
    uvm_analysis_port #(axi_st_transaction)    axi_st_h2a_tran_port;
    uvm_analysis_port #(axi_st_transaction)    axi_st_a2h_tran_port;
    //uvm_analysis_port #(axi_st_transaction)    axi_st_cmd_rd_port;
    //uvm_analysis_port #(axi_st_transaction)    axi_st_cmd_wr_port;

    string                                     tID;
    axi4stream_monitor_transaction             axi_st_h2a_trans;
    axi4stream_monitor_transaction             axi_st_a2h_trans;
    axi_st_transaction                         st_txn_h2a;
    axi_st_transaction                         st_txn_a2h;

    //------------------------CONFIGURATION PARAMETERS--------------------------------
    // AXI_MONITOR Configuration Parameters. These parameters can be controlled through
    // the UVM configuration database
    // @{

    // Trace player has three work modes for different usages:
    // CMOD_ONLY:   only cmod is working
    // RTL_ONLY:    only DUT rtl is working
    // CROSS_CHECK: default verfication mode, cross check between RTL and CMOD
    string                      work_mode = "CROSS_CHECK";
    //event                       action_tb_finish;

    // }@

    `uvm_component_utils_begin(axi_st_monitor)
        `uvm_field_string(work_mode, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_st_monitor", uvm_component parent = null);

    // UVM Phases
    // Can just enable needed phase
    // @{
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    //extern function void end_of_elaboration_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase);
    //extern task          reset_phase(uvm_phase phase);
    //extern task          configure_phase(uvm_phase phase);
    extern task          main_phase(uvm_phase phase);
    extern task          shutdown_phase(uvm_phase phase);
    //extern function void extract_phase(uvm_phase phase);
    extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);
//    extern function void check_transactions_inflight();
    // }@
    extern task collect_h2a_trans();
    extern task collect_a2h_trans();

endclass : axi_st_monitor

// Function: new
// Creates a new dbb check monitor
function axi_st_monitor::new(string name = "axi_st_monitor", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    axi_st_h2a_tran_port = new("axi_st_h2a_tran_port", this);
    axi_st_a2h_tran_port = new("axi_st_a2h_tran_port", this);
endfunction : new

// Function: build_phase
// XXX
function void axi_st_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_st_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)
    if(!uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_H2A_PARAMS)::get(this, "", "axi_vip_st_passthrough_h2a_vif", st_h2a_vif)) begin
        `uvm_fatal(tID, "No virtual interface st_h2a_vif specified to axi_st_monitor")
    end
    if(!uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_PASSTHROUGH_A2H_PARAMS)::get(this, "", "axi_vip_st_passthrough_a2h_vif", st_a2h_vif)) begin
        `uvm_fatal(tID, "No virtual interface st_h2a_vif specified to axi_st_monitor")
    end
    st_h2a_passthrough = new("st_h2a_passthrough", st_h2a_vif);
    st_a2h_passthrough = new("st_a2h_passthrough", st_a2h_vif);
endfunction : connect_phase

function void axi_st_monitor::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)

endfunction : start_of_simulation_phase
// Task: main_phase
// XXX
task axi_st_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)

endtask : run_phase

// Task: main_phase
// XXX
task axi_st_monitor::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    st_h2a_passthrough.start_monitor();
    st_a2h_passthrough.start_monitor();
    fork
        collect_h2a_trans();
        collect_a2h_trans();
    join
endtask : main_phase

task axi_st_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase

function void axi_st_monitor::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_MEDIUM)
endfunction : check_phase

//Collect H2A transactions
task axi_st_monitor::collect_h2a_trans();
    `uvm_info(tID, $sformatf("dbb check collect_h2a_trans begin ..."), UVM_MEDIUM)
    //Turn off current monitor transaction depth check
    //st_h2a_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_st_h2a_trans=new("axi_st_h2a_trans");
        st_h2a_passthrough.monitor.item_collected_port.get(axi_st_h2a_trans);
        `uvm_info(tID, $sformatf("AXI ST VIP Detects a h2a transaction: \n%s.", axi_st_h2a_trans.convert2string()), UVM_HIGH)
        st_txn_h2a=new("st_txn_h2a");
        st_txn_h2a.trans=axi_st_transaction::H2A;
        st_txn_h2a.data[1023:0]=axi_st_h2a_trans.get_data_beat();
        st_txn_h2a.tkeep[127:0]=axi_st_h2a_trans.get_keep_beat();
        st_txn_h2a.tid=axi_st_h2a_trans.get_id();
        st_txn_h2a.tuser=axi_st_h2a_trans.get_user_beat();
        st_txn_h2a.tlast=axi_st_h2a_trans.get_last();
        `uvm_info(tID, $sformatf("AXI ST Monitor Detects a h2a transaction: \n%s.", st_txn_h2a.sprint()), UVM_MEDIUM)
        axi_st_h2a_tran_port.write(st_txn_h2a);
    end
endtask : collect_h2a_trans

//Collect A2H transactions
task axi_st_monitor::collect_a2h_trans();
    `uvm_info(tID, $sformatf("dbb check collect_a2h_trans begin ..."), UVM_MEDIUM)
    //Turn off current monitor transaction depth check
    //st_a2h_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_st_a2h_trans=new("axi_st_a2h_trans");
        st_a2h_passthrough.monitor.item_collected_port.get(axi_st_a2h_trans);
        `uvm_info(tID, $sformatf("AXI ST VIP Detects a a2h transaction: \n%s.", axi_st_a2h_trans.convert2string()), UVM_HIGH)
        st_txn_a2h=new("st_txn_a2h");
        st_txn_a2h.trans=axi_st_transaction::A2H;
        st_txn_a2h.data[1023:0]=axi_st_a2h_trans.get_data_beat();
        st_txn_a2h.tkeep[127:0]=axi_st_a2h_trans.get_keep_beat();
        st_txn_a2h.tid=axi_st_a2h_trans.get_id();
        st_txn_a2h.tuser=axi_st_a2h_trans.get_user_beat();
        st_txn_a2h.tlast=axi_st_a2h_trans.get_last();
        `uvm_info(tID, $sformatf("AXI ST Monitor Detects a a2h transaction: \n%s.", st_txn_a2h.sprint()), UVM_MEDIUM)
        axi_st_a2h_tran_port.write(st_txn_a2h);
    end
endtask : collect_a2h_trans

`endif // _AXI_MONITOR_SV_
