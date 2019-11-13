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
class axi_lite_monitor extends uvm_monitor;
	
	virtual interface 								axi_vip_if `AXI_LITE_PARAMS axi_lite_vif;
	axi_lite_passthrough_passthrough_t				axi_lite_check;
	
//	uvm_analysis_port #(axi_monitor_transaction)	trans_port;
//	uvm_analysis_port #(axi_lite_transaction)		lite_trans_port;
	
	string                      					work_mode = "CROSS_CHECK";
	string 											tID;
	
	axi_monitor_transaction 						axi_trans;
	axi_lite_transaction							lite_trans;
	
	 `uvm_component_utils_begin(axi_lite_monitor)
         `uvm_field_string(work_mode, UVM_ALL_ON)
     `uvm_component_utils_end
	
	extern function new(string name = "axi_lite_monitor", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase);
    extern task          main_phase(uvm_phase phase);
    extern task          shutdown_phase(uvm_phase phase);
    extern function void check_phase(uvm_phase phase);
    extern task			 collect_transactions();
	
endclass : axi_lite_monitor


function axi_lite_monitor::new(string name = "axi_lite_monitor", uvm_component parent = null);
	super.new(name, parent);
	tID = get_type_name();
//	trans_port = new("trans_port", this);
//	lite_trans_port = new("lite_trans_port", this);
endfunction : new


function void axi_lite_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)
endfunction : build_phase


function void axi_lite_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)
    if(!uvm_config_db#(virtual axi_vip_if `AXI_LITE_PARAMS)::get(this, "", "axi_lite_vif", axi_lite_vif)) begin
        `uvm_fatal(tID, "No virtual interface axi_lite_vif specified for axi_lite_monitor")
    end
    axi_lite_check = new("axi_lite_check", axi_lite_vif);
    endfunction : connect_phase


function void axi_lite_monitor::start_of_simulation_phase(uvm_phase phase);
	super.start_of_simulation_phase(phase);
	`uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)
endfunction : start_of_simulation_phase


task axi_lite_monitor::run_phase(uvm_phase phase);
	super.run_phase(phase);
	`uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)
endtask : run_phase


task axi_lite_monitor::main_phase(uvm_phase phase);
	axi_lite_check.start_monitor();
	axi_lite_check.monitor.axi_rd_cmd_port.set_enabled();
	axi_lite_check.monitor.axi_wr_cmd_port.set_enabled();
	fork
        collect_transactions();
    join
endtask : main_phase


task axi_lite_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase


function void axi_lite_monitor::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_MEDIUM)
endfunction : check_phase


task axi_lite_monitor::collect_transactions();
    `uvm_info(tID, $sformatf("dbb check collect_transactions begin ..."), UVM_MEDIUM)
    axi_lite_check.monitor.disable_transaction_depth_checks();
	
    forever begin
        axi_trans = new("axi_monitor_trans");
		lite_trans= new("axi_lite_transaction");
		
        axi_lite_check.monitor.item_collected_port.get(axi_trans);
		lite_trans.t_type = axi_trans.get_cmd_type();
		lite_trans.addr = axi_trans.get_addr();
		lite_trans.data = axi_trans.get_data_beat(0);
		lite_trans.strobe = axi_trans.get_strb_beat(0);
		
//		trans_port.write(axi_trans);
//		lite_trans_port.write(lite_trans);
		`uvm_info(tID, $sformatf("trans detected:\n%s", lite_trans.sprint()), UVM_MEDIUM);
    end
endtask : collect_transactions
