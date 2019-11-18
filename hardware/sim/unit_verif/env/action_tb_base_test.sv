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
`ifndef _ACTION_TB_BASE_TEST_SV_
`define _ACTION_TB_BASE_TEST_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: action_tb_base_test
//
// @description
//-------------------------------------------------------------------------------------
//
import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_vip_pkg::*;
//import axi_vip_mm_check_pkg::*;

class action_tb_base_test extends uvm_test;

    string                   tID;
    action_tb_env            env;

    `uvm_component_utils_begin(action_tb_base_test)
    `uvm_component_utils_end

    extern function new(string name = "action_tb_base_test", uvm_component parent = null);

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
    extern function void pre_abort();
    extern function void do_report();
    extern task          watch_dog_report();
    extern task          timeout(uvm_phase phase, time max_time);

    // }@

endclass : action_tb_base_test

// Function: new
// Creates a new action_tb_base_test component
function action_tb_base_test::new(string name = "action_tb_base_test", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
endfunction : new

// Function: build_phase
// Used to construct testbench components, build top-level testbench topology
function void action_tb_base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
    env             = action_tb_env::type_id::create("env", this);
    set_report_max_quit_count(1);
    //uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k::type_id::get());
endfunction : build_phase

// Function: connect_phase
// Used to connect components/tlm ports for environment topoloty
function void action_tb_base_test::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
endfunction : connect_phase

// Function: end_of_elaboration_phase
// Used to make any final adjustments to the env topology
function void action_tb_base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(tID, $sformatf("end_of_elaboration_phase begin ..."), UVM_HIGH)

    if (get_report_verbosity_level() >= UVM_HIGH) begin
        uvm_factory factory = uvm_factory::get();
        factory.print();
    end
    uvm_top.print_topology();
endfunction : end_of_elaboration_phase

// Function: start_of_simulation_phase
// Used to configure verification componets, printing
function void action_tb_base_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_HIGH)

    // Avoid excessive don't-care warnings in log file
    uvm_top.set_report_severity_id_action_hier(UVM_WARNING, "UVM/RSRC/NOREGEX", UVM_NO_ACTION);
    uvm_top.set_report_severity_id_action_hier(UVM_WARNING, "UVM/COMP/NAME", UVM_NO_ACTION);
endfunction : start_of_simulation_phase

// TASK: run_phase
// Used to execute run-time tasks of simulation
task action_tb_base_test::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_HIGH)
    phase.phase_done.set_drain_time(this, 50ps);
endtask : run_phase

// TASK: reset_phase
// The reset phase is reserved for DUT or interface specific reset behavior
task action_tb_base_test::reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    `uvm_info(tID, $sformatf("reset_phase begin ..."), UVM_HIGH)

endtask : reset_phase

// TASK: configure_phase
// Used to program the DUT or memoried in the testbench
task action_tb_base_test::configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    `uvm_info(tID, $sformatf("configure_phase begin ..."), UVM_HIGH)

endtask : configure_phase

// TASK: main_phase
// Used to execure mainly run-time tasks of simulation
task action_tb_base_test::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    fork
    //phase.raise_objection(this);
    //wait ($root.top.action_tb_finish.triggered);
    //`uvm_info(tID, $sformatf("main_phase end ..."), UVM_MEDIUM)
    //phase.drop_objection(this);
        //timeout(phase, 50000us);
        watch_dog_report();
    //phase.phase_done.set_drain_time(this, 50ps);
    join_none
endtask : main_phase

// TASK: shutdown_phase
// Data "drain" and other operations for graceful termination
task action_tb_base_test::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_HIGH)

endtask : shutdown_phase

// Function: extract_phase
// Used to retrieve final state of DUTG and details of scoreboard, etc.
function void action_tb_base_test::extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(tID, $sformatf("extract_phase begin ..."), UVM_HIGH)

endfunction : extract_phase

// Function: check_phase
// Used to process and check the simulation results
function void action_tb_base_test::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_HIGH)

endfunction : check_phase

// Function: report_phase
// Simulation results analysis and reports
function void action_tb_base_test::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(tID, $sformatf("report_phase begin ..."), UVM_HIGH)

    do_report();
endfunction : report_phase

// Function: final_phase
// Used to complete/end any outstanding actions of testbench
function void action_tb_base_test::final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info(tID, $sformatf("final_phase begin ..."), UVM_HIGH)

endfunction : final_phase

function void action_tb_base_test::pre_abort();
    super.pre_abort();
    do_report();
endfunction

function void action_tb_base_test::do_report();
    uvm_report_server rs = uvm_report_server::get_server();
    if (rs.get_severity_count(UVM_FATAL) + rs.get_severity_count(UVM_ERROR) == 0) begin
        $display("*******************************");
        $display("**        TEST PASS          **");
        $display("*******************************");
    end else begin
        $display("*******************************");
        $display("**        TEST FAILED        **");
        $display("*******************************");
    end
endfunction

task action_tb_base_test::watch_dog_report();
    forever begin
        #5000us;
        `uvm_info(get_type_name(),"Watch Dog Report!!",UVM_LOW)
    end
endtask : watch_dog_report

task action_tb_base_test::timeout(uvm_phase phase, time max_time);
    `uvm_delay(max_time);
    `uvm_error(get_type_name(), $psprintf( "Simulation Overtime, test case failed"))
    `uvm_info(this.get_type_name(), phase.phase_done.convert2string(), UVM_NONE)
    $finish;
endtask: timeout

`endif // _ACTION_TB_BASE_TEST_SV_

