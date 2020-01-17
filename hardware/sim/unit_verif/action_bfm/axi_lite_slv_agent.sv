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
`ifndef _AXI_LITE_SLV_AGENT_SV_
`define _AXI_LITE_SLV_AGENT_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_lite_slv_agent
//
// XXX
//-------------------------------------------------------------------------------------

class axi_lite_slv_agent extends uvm_agent;

    virtual interface               axi_vip_if `AXI_VIP_LITE_SLAVE_PARAMS lite_slv_vif;
    axi_vip_lite_slave_slv_mem_t    axi_vip_lite_slave_slv;
    uvm_active_passive_enum         is_active = UVM_PASSIVE;
    string                          tID;
    
    `uvm_component_utils_begin(axi_lite_slv_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_lite_slv_agent", uvm_component parent = null);

    // UVM Phases
    // Can just enable needed phase
    // @{
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    //extern function void end_of_elaboration_phase(uvm_phase phase);
    //extern function void start_of_simulation_phase(uvm_phase phase);
    //extern task          run_phase(uvm_phase phase);
    //extern task          reset_phase(uvm_phase phase);
    //extern task          configure_phase(uvm_phase phase);
    extern task          main_phase(uvm_phase phase);
    //extern task          shutdown_phase(uvm_phase phase);
    //extern function void extract_phase(uvm_phase phase);
    //extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);
    // }@

endclass : axi_lite_slv_agent

// Function: new
// Creates a new AXI lite slave agent
function axi_lite_slv_agent::new(string name = "axi_lite_slv_agent", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
endfunction : new

// Function: build_phase
// XXX
function void axi_lite_slv_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
    if(!uvm_config_db#(virtual axi_vip_if `AXI_VIP_LITE_SLAVE_PARAMS)::get(this, "", "axi_vip_lite_slave_vif", lite_slv_vif)) begin
        `uvm_fatal(tID, "No virtual interface axi_vip_lite_slave_vif specified for axi_lite_slv_agent.")
    end
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_lite_slv_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
endfunction : connect_phase

// Task: main_phase
// XXX
task axi_lite_slv_agent::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_HIGH)
    axi_vip_lite_slave_slv = new("axi_vip_lite_slave_slv", lite_slv_vif);
    axi_vip_lite_slave_slv.start_slave();
endtask : main_phase

`endif // _AXI_LITE_SLV_AGENT_SV_
