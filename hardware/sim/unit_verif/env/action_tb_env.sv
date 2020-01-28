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
`ifndef _ACTION_TB_ENV_SV_
`define _ACTION_TB_ENV_SV_

`include "../../../hdl/core/snap_global_vars.v"

//-------------------------------------------------------------------------------------
//
// CLASS: action_tb_env
//
// @description
//-------------------------------------------------------------------------------------


class action_tb_env extends uvm_env;

    string                    tID;
    tlx_afu_monitor           tlx_afu_mon;
    `ifndef ENABLE_ODMA_ST_MODE
        axi_mm_monitor            axi_mm_mon;
    `else
        axi_st_monitor            axi_st_mon;
    `endif
	axi_lite_monitor          axi_lite_mon; //added at 2019.08.14
    `ifndef ENABLE_ODMA
        bridge_check_scoreboard   bridge_check_sbd;
    `else
        odma_check_scoreboard     odma_check_sbd;
    `endif
    //tl_bfm_env                bfm_env;
    tl_agent                  bfm_agt;
    action_agent              action_agt;
    tb_vseqr                  vsqr; 
    brdg_cfg_obj              brdg_cfg;

    `uvm_component_utils_begin(action_tb_env)
    `uvm_component_utils_end

    extern function new(string name = "action_tb_env", uvm_component parent = null);

    //------------------------------------------------------------------------UVM Phases
    // Not all phases are needed, just enable specific phases for different component
    // @{

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase);
    extern task          reset_phase(uvm_phase phase);
    extern task          configure_phase(uvm_phase phase);
    extern task          main_phase(uvm_phase phase);
    extern task          shutdown_phase(uvm_phase phase);
    extern function void extract_phase(uvm_phase phase);
    extern function void check_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);
    extern function void final_phase(uvm_phase phase);

    // }@

endclass : action_tb_env

// Function: new
// Creates a new action_tb_env component
function action_tb_env::new(string name = "action_tb_env", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
endfunction : new

// Function: build_phase
// Used to construct testbench components, build top-level testbench topology
function void action_tb_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)
    brdg_cfg = brdg_cfg_obj::type_id::create("brdg_cfg", this);
    `ifndef ENABLE_ODMA_ST_MODE
        axi_mm_mon       = axi_mm_monitor::type_id::create("axi_mm_mon", this);
    `else
        axi_st_mon       = axi_st_monitor::type_id::create("axi_st_mon", this);
    `endif
    axi_lite_mon	 = axi_lite_monitor::type_id::create("axi_lite_mon", this); //added at 2019.08.14
    tlx_afu_mon          = tlx_afu_monitor::type_id::create("tlx_afu_mon", this);
    `ifndef ENABLE_ODMA    
        bridge_check_sbd = bridge_check_scoreboard::type_id::create("bridge_check_sbd", this);
    `else
        odma_check_sbd   = odma_check_scoreboard::type_id::create("odma_check_sbd", this);
    `endif
    vsqr             = tb_vseqr::type_id::create("vsqr", this);
//    bfm_env          = tl_bfm_env::type_id::create("bfm_env", this);
    bfm_agt          = tl_agent::type_id::create("bfm_agt", this);
    action_agt       = action_agent::type_id::create("action_agt", this);
    //host_mem         = host_mem_model::type_id::create("host_mem", this);
    uvm_config_db #(brdg_cfg_obj)::set(this, "bridge_check_sbd", "brdg_cfg", brdg_cfg);
    uvm_config_db #(brdg_cfg_obj)::set(this, "odma_check_sbd", "brdg_cfg", brdg_cfg);

endfunction : build_phase

// Function: connect_phase
// Used to connect components/tlm ports for environment topoloty
function void action_tb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
    //Connect components/tlm ports for scoreboard
    `ifndef ENABLE_ODMA
        tlx_afu_mon.tlx_afu_tran_port.connect(bridge_check_sbd.aimp_tlx_afu);
        tlx_afu_mon.afu_tlx_tran_port.connect(bridge_check_sbd.aimp_afu_tlx);    
        tlx_afu_mon.intrp_tran_port.connect(bridge_check_sbd.aimp_intrp);
        axi_mm_mon.axi_mm_tran_port.connect(bridge_check_sbd.aimp_axi_mm);
        axi_mm_mon.axi_mm_cmd_rd_port.connect(bridge_check_sbd.aimp_axi_mm_cmd_rd);
        axi_mm_mon.axi_mm_cmd_wr_port.connect(bridge_check_sbd.aimp_axi_mm_cmd_wr);
    `else
        tlx_afu_mon.tlx_afu_tran_port.connect(odma_check_sbd.aimp_tlx_afu_odma);
        tlx_afu_mon.afu_tlx_tran_port.connect(odma_check_sbd.aimp_afu_tlx_odma);
        tlx_afu_mon.afu_tlx_tran_port.connect(odma_check_sbd.aimp_afu_tlx_odma); 
        `ifndef ENABLE_ODMA_ST_MODE
            axi_mm_mon.axi_mm_tran_port.connect(odma_check_sbd.aimp_axi_mm_odma);
        `else
            axi_st_mon.axi_st_h2a_tran_port.connect(odma_check_sbd.aimp_axi_st_odma_h2a);
            axi_st_mon.axi_st_a2h_tran_port.connect(odma_check_sbd.aimp_axi_st_odma_a2h);
        `endif
    `endif
    //Connect sequencers to virtual sequencer
    //vsqr.tx_sqr = bfm_env.bfm_agt.tx_sqr;
    //vsqr.cfg_obj = bfm_env.bfm_agt.cfg_obj;
    //vsqr.tl_agt = bfm_env.bfm_agt;
    vsqr.brdg_cfg = brdg_cfg;
    vsqr.tx_sqr = bfm_agt.tx_sqr;
    vsqr.cfg_obj = bfm_agt.cfg_obj;
    vsqr.act_cfg = action_agt.act_cfg;
    vsqr.tl_agt = bfm_agt;
    vsqr.host_mem = bfm_agt.mgr.host_mem;
    vsqr.action_agt = action_agt;
    vsqr.act_sqr = action_agt.act_sqr;
    vsqr.act_sqr_st = action_agt.act_sqr_st;

endfunction : connect_phase

// Function: end_of_elaboration_phase
// Used to make any final adjustments to the env topology
function void action_tb_env::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(tID, $sformatf("end_of_elaboration_phase begin ..."), UVM_HIGH)

endfunction : end_of_elaboration_phase

// Function: start_of_simulation_phase
// Used to configure verification componets, printing
function void action_tb_env::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_HIGH)

endfunction : start_of_simulation_phase

// TASK: run_phase
// Used to execute run-time tasks of simulation
task action_tb_env::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_HIGH)

endtask : run_phase

// TASK: reset_phase
// The reset phase is reserved for DUT or interface specific reset behavior
task action_tb_env::reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    `uvm_info(tID, $sformatf("reset_phase begin ..."), UVM_HIGH)

endtask : reset_phase

// TASK: configure_phase
// Used to program the DUT or memoried in the testbench
task action_tb_env::configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    `uvm_info(tID, $sformatf("configure_phase begin ..."), UVM_HIGH)

endtask : configure_phase

// TASK: main_phase
// Used to execure mainly run-time tasks of simulation
task action_tb_env::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_HIGH)

endtask : main_phase

// TASK: shutdown_phase
// Data "drain" and other operations for graceful termination
task action_tb_env::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_HIGH)

endtask : shutdown_phase

// Function: extract_phase
// Used to retrieve final state of DUTG and details of scoreboard, etc.
function void action_tb_env::extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(tID, $sformatf("extract_phase begin ..."), UVM_HIGH)

endfunction : extract_phase

// Function: check_phase
// Used to process and check the simulation results
function void action_tb_env::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_HIGH)

endfunction : check_phase

// Function: report_phase
// Simulation results analysis and reports
function void action_tb_env::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(tID, $sformatf("report_phase begin ..."), UVM_HIGH)

endfunction : report_phase

// Function: final_phase
// Used to complete/end any outstanding actions of testbench
function void action_tb_env::final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info(tID, $sformatf("final_phase begin ..."), UVM_HIGH)

endfunction : final_phase



`endif // _ACTION_TB_ENV_SV_
