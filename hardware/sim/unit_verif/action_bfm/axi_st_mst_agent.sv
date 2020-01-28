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
`ifndef _AXI_ST_MST_AGENT_SV_
`define _AXI_ST_MST_AGENT_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_st_mst_agent
//
// XXX
//-------------------------------------------------------------------------------------

class axi_st_mst_agent extends uvm_driver #(axi_st_transaction);

    virtual interface               axi4stream_vip_if `AXI_VIP_ST_MASTER_PARAMS st_mst_vif;
    axi_vip_st_master_mst_t         axi_vip_st_master_mst;
    uvm_active_passive_enum         is_active = UVM_PASSIVE;
    string                          tID;

    axi_st_transaction              axi_st_queue[$];
    axi4stream_transaction          vip_trans;

    `uvm_component_utils_begin(axi_st_mst_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_st_mst_agent", uvm_component parent = null);

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
    extern task          get_st_trans();
    extern task          send_st_write();

endclass : axi_st_mst_agent

// Function: new
// Creates a new AXI lite master agent
function axi_st_mst_agent::new(string name = "axi_st_mst_agent", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
endfunction : new

// Function: build_phase
// XXX
function void axi_st_mst_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
    if(!uvm_config_db#(virtual axi4stream_vip_if `AXI_VIP_ST_MASTER_PARAMS)::get(this, "", "axi_vip_st_master_vif", st_mst_vif)) begin
        `uvm_fatal(tID, "No virtual interface axi_vip_st_master_vif specified for axi_st_mst_agent.")
    end
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_st_mst_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
endfunction : connect_phase

// Task: main_phase
// XXX
task axi_st_mst_agent::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_HIGH)
    axi_vip_st_master_mst = new("axi_vip_st_master_mst", st_mst_vif);
    axi_vip_st_master_mst.start_master();
    axi_vip_st_master_mst.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
    fork
        get_st_trans();
        send_st_write();
    join
endtask : main_phase

//Get ST transactions from sequencer 
task axi_st_mst_agent::get_st_trans();
    forever begin
        seq_item_port.get_next_item(req);
        axi_st_queue.push_back(req);
        seq_item_port.item_done();        
    end
endtask : get_st_trans

//Send ST transactions 
task axi_st_mst_agent::send_st_write();
    forever begin
        if(axi_st_queue.size > 0)begin
            vip_trans = axi_vip_st_master_mst.driver.create_transaction("write transaction");
            vip_trans.set_delay_policy(XIL_AXI4STREAM_DELAY_INSERTION_FROM_IDLE);
            vip_trans.set_driver_return_item_policy(XIL_AXI4STREAM_NO_RETURN);
            vip_trans.set_delay(0);
            vip_trans.set_id(axi_st_queue[0].tid);
            vip_trans.set_user_beat(axi_st_queue[0].tuser);
            vip_trans.set_keep_beat(axi_st_queue[0].tkeep);
            vip_trans.set_data_beat(axi_st_queue[0].data);
            vip_trans.set_last(axi_st_queue[0].tlast);
            axi_vip_st_master_mst.driver.send(vip_trans);
            void'(axi_st_queue.pop_front());
        end
        else begin
            @(posedge st_mst_vif.ACLK);
        end
    end
endtask : send_st_write

`endif // _AXI_ST_MST_AGENT_SV_
