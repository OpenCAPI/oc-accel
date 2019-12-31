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
`ifndef _AXI_MM_MST_AGENT_SV_
`define _AXI_MM_MST_AGENT_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_mm_mst_agent
//
// XXX
//-------------------------------------------------------------------------------------

class axi_mm_mst_agent extends uvm_driver #(axi_mm_transaction);

    virtual interface               axi_vip_if `AXI_VIP_MM_MASTER_PARAMS mm_mst_vif;
    virtual interface               intrp_interface intrp_vif;
    axi_vip_mm_master_mst_t         axi_vip_mm_master_mst;
    uvm_active_passive_enum         is_active = UVM_PASSIVE;
    string                          tID;

    axi_mm_transaction              axi_read_queue[$];     //AXI read transaction queue to drive
    axi_mm_transaction              axi_write_queue[$];    //AXI write transaction queue to drive
    axi_mm_transaction              axi_intrp_queue[$];    //Action interrupt transaction queue to drive
    axi_transaction                 vip_rd_trans;          //AXI VIP read transaction
    axi_transaction                 vip_wr_trans;          //AXI VIP write transaction
    axi_transaction                 rd_wait_q[$];          //AXI VIP read transaction wait queue for response
    axi_transaction                 wr_wait_q[$];          //AXI VIP write transaction wait queue for response

    `uvm_component_utils_begin(axi_mm_mst_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_mm_mst_agent", uvm_component parent = null);
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
    extern task          reset_intrp_signal();
    extern task          get_axi_trans();
    extern task          send_axi_read();
    extern task          send_axi_write();
    extern task          wait_read_resp();
    extern task          wait_write_resp();
    extern task          send_intrp();

endclass : axi_mm_mst_agent

// Function: new
// Creates a new AXI mm master agent
function axi_mm_mst_agent::new(string name = "axi_mm_mst_agent", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
endfunction : new

// Function: build_phase
// XXX
function void axi_mm_mst_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
    if(!uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_MASTER_PARAMS)::get(this, "", "axi_vip_mm_master_vif", mm_mst_vif)) begin
        `uvm_fatal(tID, "No virtual interface axi_vip_mm_master_vif specified for axi_mm_mst_agent.")
    end
    if(!uvm_config_db#(virtual intrp_interface)::get(this, "", "intrp_vif", intrp_vif)) begin
        `uvm_fatal(tID, "No virtual interface intrp_vif specified for axi_mm_mst_agent.")
    end
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_mm_mst_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
endfunction : connect_phase

// Task: main_phase
// XXX
task axi_mm_mst_agent::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_HIGH)
    axi_vip_mm_master_mst = new("axi_vip_mm_master_mst", mm_mst_vif);
    axi_vip_mm_master_mst.start_master(); 
    reset_intrp_signal();
    fork
        get_axi_trans();
        send_axi_read();
        send_axi_write();
        wait_read_resp();
        wait_write_resp();
        send_intrp();
    join
endtask : main_phase

//Reset interrupt signals 
task axi_mm_mst_agent::reset_intrp_signal();
    intrp_vif.intrp_req <= 1'b0;
    intrp_vif.intrp_src <= 64'b0;
    intrp_vif.intrp_ctx <= 9'b0;
endtask : reset_intrp_signal
    
//Get transactions from sequencer 
task axi_mm_mst_agent::get_axi_trans();
    forever begin
        seq_item_port.get_next_item(req);
        if(req.trans == axi_mm_transaction::READ)begin
            axi_read_queue.push_back(req);
        end
        else begin
            axi_write_queue.push_back(req);
        end
        seq_item_port.item_done();        
    end
endtask : get_axi_trans

//Drive axi read
task axi_mm_mst_agent::send_axi_read();
    forever begin
        if(axi_read_queue.size > 0)begin
            vip_rd_trans=axi_vip_mm_master_mst.rd_driver.create_transaction("read transaction");
            vip_rd_trans.set_aruser(axi_read_queue[0].axi_usr);
            vip_rd_trans.id=axi_read_queue[0].axi_id;
            vip_rd_trans.size=axi_read_queue[0].axi_size;
            vip_rd_trans.len=axi_read_queue[0].axi_len;
            vip_rd_trans.addr=axi_read_queue[0].addr;
            vip_rd_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
            ////Allow to generate consecutive read commands
            //{dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} = gen_xfer_delays(read_rand_patt, vip_rd_trans);
            //if ( {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} != 32'hFFFFFFFF ) begin
            //    vip_rd_trans.set_addr_delay (dly_addr);
            //    vip_rd_trans.set_data_insertion_delay(dly_d_ins);
            //    vip_rd_trans.set_response_delay(dly_rsp);
            //    vip_rd_trans.set_allow_data_before_cmd(dly_allow_dbc);
            //end
            axi_vip_mm_master_mst.rd_driver.send(vip_rd_trans);
            if(axi_read_queue[0].act_intrp==1)begin
                axi_intrp_queue.push_back(axi_read_queue.pop_front());
            end else begin
                void'(axi_read_queue.pop_front());
            end
            rd_wait_q.push_back(vip_rd_trans);
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : send_axi_read

//Wait for AXI read response
task axi_mm_mst_agent::wait_read_resp();
    forever begin
        if(rd_wait_q.size > 0)begin
            axi_vip_mm_master_mst.rd_driver.wait_rsp(rd_wait_q[0]);
            void'(rd_wait_q.pop_front());
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : wait_read_resp

//Drive axi write
task axi_mm_mst_agent::send_axi_write();
    forever begin
        if(axi_write_queue.size > 0)begin
            vip_wr_trans = axi_vip_mm_master_mst.wr_driver.create_transaction("write transaction");
            vip_wr_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
            //if (gen_wrcmd_order(write_rand_patt))
            //    vip_wr_trans.set_xfer_wrcmd_order(XIL_AXI_WRCMD_ORDER_DATA_BEFORE_CMD);
            vip_wr_trans.size=axi_write_queue[0].axi_size;
            vip_wr_trans.len=axi_write_queue[0].axi_len;
            vip_wr_trans.addr=axi_write_queue[0].addr;
            ////Allow to generate consecutive write commands
            //{dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} = gen_xfer_delays(write_rand_patt, vip_wr_trans);
            //if ( {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} != 32'hFFFFFFFF ) begin
            //    vip_wr_trans.set_addr_delay (dly_addr);
            //    vip_wr_trans.set_data_insertion_delay(dly_d_ins);
            //    vip_wr_trans.set_response_delay(dly_rsp);
            //    vip_wr_trans.set_allow_data_before_cmd(dly_allow_dbc);
            //end
            vip_wr_trans.set_awuser(axi_write_queue[0].axi_usr);
            vip_wr_trans.id=axi_write_queue[0].axi_id;
            vip_wr_trans.size_wr_beats();
            //vip_wr_trans.set_data_block(wr_block);
            for (xil_axi_uint beat = 0; beat < vip_wr_trans.get_len()+1; beat++) begin
                vip_wr_trans.set_user_beat(beat, 0);
                vip_wr_trans.set_data_beat(beat, axi_write_queue[0].data[beat]);
                vip_wr_trans.set_strb_beat(beat, axi_write_queue[0].data_strobe[beat]);
                //vip_wr_trans.set_strb_beat(beat, axi_write_queue[0].data_strobe[beat]);
                //dly_beat = get_beat_delay(write_rand_patt, vip_wr_trans);
                //if (dly_beat != 8'hFF) begin
                //    vip_wr_trans.set_beat_delay(beat, dly_beat);
                //end
            end
            // Send
            axi_vip_mm_master_mst.wr_driver.send(vip_wr_trans);
            if(axi_write_queue[0].act_intrp==1)begin
                axi_intrp_queue.push_back(axi_write_queue.pop_front());
            end else begin
                void'(axi_write_queue.pop_front());
            end
            wr_wait_q.push_back(vip_wr_trans);
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : send_axi_write

//Wait for AXI write response
task axi_mm_mst_agent::wait_write_resp();
    forever begin
        if(wr_wait_q.size > 0)begin
            axi_vip_mm_master_mst.wr_driver.wait_rsp(wr_wait_q[0]);
            void'(wr_wait_q.pop_front());
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : wait_write_resp

//Send action interrupt
task axi_mm_mst_agent::send_intrp();
    forever begin
        if(intrp_vif.action_rst_n==0)begin
            @(posedge mm_mst_vif.ACLK);
        end
        else if(intrp_vif.intrp_ack == 1'b1 && intrp_vif.intrp_req == 1'b1)
            intrp_vif.intrp_req <= 1'b0;
        else if(intrp_vif.intrp_ack == 1'b0 && intrp_vif.intrp_req == 1'b0 && axi_intrp_queue.size > 0)begin
            intrp_vif.intrp_req <= 1'b1;
            void'(axi_intrp_queue.pop_front());
        end        
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : send_intrp

`endif // _AXI_MM_MST_AGENT_SV_
