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
    act_cfg_obj                     act_cfg;
    axi_vip_mm_master_mst_t         axi_vip_mm_master_mst;
    uvm_active_passive_enum         is_active = UVM_PASSIVE;
    string                          tID;

    //Delay variables in master
    class master_delay_packet;
        rand int addr_delay;
        rand int data_ins_delay;
        rand int beat_delay;
        rand int dbc_delay;
    endclass : master_delay_packet

    axi_mm_transaction              axi_read_queue[$];     //AXI read transaction queue to drive
    axi_mm_transaction              axi_write_queue[$];    //AXI write transaction queue to drive
    axi_mm_transaction              axi_intrp_queue[$];    //Action interrupt transaction queue to drive
    axi_transaction                 vip_rd_trans;          //AXI VIP read transaction
    axi_transaction                 vip_wr_trans;          //AXI VIP write transaction
    axi_transaction                 rd_wait_q[$];          //AXI VIP read transaction wait queue for response
    axi_transaction                 wr_wait_q[$];          //AXI VIP write transaction wait queue for response
    int                             read_num;              //Finish read number
    int                             write_num;             //Finish write number

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
    extern function void get_trans_delay(input axi_transaction tr, output int addr_delay, output int data_ins_delay, output int beat_delay, output int dbc_delay);

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
    if(!uvm_config_db#(act_cfg_obj)::get(this, "", "act_cfg", act_cfg))
        `uvm_error(get_type_name(), "Can't get act_cfg_obj!")
endfunction : connect_phase
// Task: main_phase
// XXX
task axi_mm_mst_agent::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_HIGH)
    axi_vip_mm_master_mst = new("axi_vip_mm_master_mst", mm_mst_vif);
    // When bus is in idle, drive everything to 0
    axi_vip_mm_master_mst.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
    // Set tag for agents for easy debug
    axi_vip_mm_master_mst.set_agent_tag("MM Mode Master Axi4 VIP");
    // Set the capability to program the write/read transactions
    axi_vip_mm_master_mst.wr_driver.seq_item_port.set_max_item_cnt(10000);
    axi_vip_mm_master_mst.rd_driver.seq_item_port.set_max_item_cnt(10000);
    // Set waiting valid timeout value
    axi_vip_mm_master_mst.wr_driver.set_waiting_valid_timeout_value(10000000);
    axi_vip_mm_master_mst.rd_driver.set_waiting_valid_timeout_value(10000000);
    //Set AR or R handshakes timeout
    axi_vip_mm_master_mst.wr_driver.set_forward_progress_timeout_value(5000000);
    axi_vip_mm_master_mst.rd_driver.set_forward_progress_timeout_value(5000000);
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
    int addr_delay;
    int data_ins_delay;
    int beat_delay;
    int dbc_delay;
    forever begin
        if(axi_read_queue.size > 0)begin
            vip_rd_trans=axi_vip_mm_master_mst.rd_driver.create_transaction("read transaction");
            vip_rd_trans.set_aruser(axi_read_queue[0].axi_usr);
            vip_rd_trans.id=axi_read_queue[0].axi_id;
            vip_rd_trans.size=axi_read_queue[0].axi_size;
            vip_rd_trans.len=axi_read_queue[0].axi_len;
            vip_rd_trans.addr=axi_read_queue[0].addr;
            vip_rd_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
            //Get delays
            get_trans_delay(vip_rd_trans, addr_delay, data_ins_delay, beat_delay, dbc_delay);
            //Set the address delay
            if(act_cfg.mst_dly_adr_enable==1)begin
                vip_rd_trans.set_addr_delay(addr_delay);
            end
            //Set the data insertion delay
            if(act_cfg.mst_dly_data_ins_enable==1)begin
                vip_rd_trans.set_data_insertion_delay(data_ins_delay);
            end
            //Set the beat delay
            if(act_cfg.mst_dly_beat_enable==1)begin
                for(int beat=0; beat<vip_rd_trans.get_len()+1; beat++)begin
                    vip_rd_trans.set_beat_delay(beat, beat_delay);
                end
            end
            //Set the data before command delay
            if(act_cfg.mst_allow_dbc==1)begin
                vip_rd_trans.set_xfer_wrcmd_order(XIL_AXI_WRCMD_ORDER_DATA_BEFORE_CMD);
                vip_rd_trans.set_allow_data_before_cmd(dbc_delay);
            end
            //Send
            axi_vip_mm_master_mst.rd_driver.send(vip_rd_trans);
            //Issue interrupts
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
            read_num++;
            `uvm_info(tID, $sformatf("Finish read number:%d.", read_num), UVM_LOW)
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : wait_read_resp

//Drive axi write
task axi_mm_mst_agent::send_axi_write();
    int addr_delay;
    int data_ins_delay;
    int beat_delay;
    int dbc_delay;
    forever begin
        if(axi_write_queue.size > 0)begin
            vip_wr_trans = axi_vip_mm_master_mst.wr_driver.create_transaction("write transaction");
            vip_wr_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
            vip_wr_trans.size=axi_write_queue[0].axi_size;
            vip_wr_trans.len=axi_write_queue[0].axi_len;
            vip_wr_trans.addr=axi_write_queue[0].addr;
            vip_wr_trans.set_awuser(axi_write_queue[0].axi_usr);
            vip_wr_trans.id=axi_write_queue[0].axi_id;
            vip_wr_trans.size_wr_beats();
            //vip_wr_trans.set_data_block(wr_block);
            for (xil_axi_uint beat = 0; beat < vip_wr_trans.get_len()+1; beat++) begin
                vip_wr_trans.set_user_beat(beat, 0);
                vip_wr_trans.set_data_beat(beat, axi_write_queue[0].data[beat]);
                vip_wr_trans.set_strb_beat(beat, axi_write_queue[0].data_strobe[beat]);
            end
            //Get delays
            get_trans_delay(vip_wr_trans, addr_delay, data_ins_delay, beat_delay, dbc_delay);
            //Set the address delay
            if(act_cfg.mst_dly_adr_enable==1)begin
                vip_wr_trans.set_addr_delay(addr_delay);
            end
            //Set the data insertion delay
            if(act_cfg.mst_dly_data_ins_enable==1)begin
                vip_wr_trans.set_data_insertion_delay(data_ins_delay);
            end
            //Set the beat delay
            if(act_cfg.mst_dly_beat_enable==1)begin
                for(int beat=0; beat<vip_wr_trans.get_len()+1; beat++)begin
                    vip_wr_trans.set_beat_delay(beat, beat_delay);
                end
            end
            //Set the data before command delay
            if(act_cfg.mst_allow_dbc==1)begin
                vip_wr_trans.set_xfer_wrcmd_order(XIL_AXI_WRCMD_ORDER_DATA_BEFORE_CMD);
                vip_wr_trans.set_allow_data_before_cmd(dbc_delay);
            end
            // Send
            axi_vip_mm_master_mst.wr_driver.send(vip_wr_trans);
            //Issue interrupts
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
            write_num++;
            `uvm_info(tID, $sformatf("Finish write number:%d.", write_num), UVM_LOW)
        end
        else begin
            @(posedge mm_mst_vif.ACLK);
        end
    end
endtask : wait_write_resp

//Send action interrupt
task axi_mm_mst_agent::send_intrp();
    forever begin
        @(posedge mm_mst_vif.ACLK);
        if(!intrp_vif.action_rst_n)begin
            intrp_vif.intrp_req <= 1'b0;
            intrp_vif.intrp_src <= 64'b0;
            intrp_vif.intrp_ctx <= 9'b0;
        end
        else if(intrp_vif.intrp_ack == 1'b1 && intrp_vif.intrp_req == 1'b1)
            intrp_vif.intrp_req <= 1'b0;
        else if(intrp_vif.intrp_ack == 1'b0 && intrp_vif.intrp_req == 1'b0 && axi_intrp_queue.size > 0)begin
            intrp_vif.intrp_req <= 1'b1;
            void'(axi_intrp_queue.pop_front());
        end
    end
endtask : send_intrp

//Set delays for the transaction
function void axi_mm_mst_agent::get_trans_delay(input axi_transaction tr, output int addr_delay, output int data_ins_delay, output int beat_delay, output int dbc_delay);
    int min_addr_delay;
    int max_addr_delay;
    int min_data_insertion_delay;
    int max_data_insertion_delay;
    int min_beat_delay;
    int max_beat_delay;
    int min_dbc;
    int max_dbc;
    master_delay_packet mst_mm_dly=new(); 

    tr.get_addr_delay_range(min_addr_delay, max_addr_delay);
    tr.get_data_insertion_delay_range(min_data_insertion_delay, max_data_insertion_delay);
    tr.get_beat_delay_range(min_beat_delay, max_beat_delay);
    tr.get_allow_data_before_cmd_range(min_dbc, max_dbc);
    //if(max_dbc>tr.get_len()+1)
    max_dbc=tr.get_len()+1;

    //Set the range of delay
    case(act_cfg.mst_dly_mode)
        act_cfg_obj::MIN_DELAY:begin
            max_addr_delay=min_addr_delay;
            max_data_insertion_delay=min_data_insertion_delay;
            max_beat_delay=min_beat_delay;
            max_dbc=min_dbc;
        end
        act_cfg_obj::MAX_DELAY:begin
            min_addr_delay=max_addr_delay;
            min_data_insertion_delay=max_data_insertion_delay;
            min_beat_delay=max_beat_delay;
            min_dbc=max_dbc;
        end
        act_cfg_obj::RAND_DELAY:begin
        end
        act_cfg_obj::LITTLE_DELAY:begin
            if(max_addr_delay > 2)begin
                max_addr_delay=2;                
                max_data_insertion_delay=2;
                max_beat_delay=2;                
                max_dbc=2;                
            end
        end
    endcase

    void'(mst_mm_dly.randomize()with{addr_delay>=min_addr_delay;addr_delay<=max_addr_delay;
                                     data_ins_delay>=min_data_insertion_delay;data_ins_delay<=max_data_insertion_delay;
                                     beat_delay>=min_beat_delay;beat_delay<=max_beat_delay;
                                     dbc_delay>=min_dbc;dbc_delay<=max_dbc;});
    //`uvm_info(tID, $sformatf("Set master delays. addr_delay:%d, data_ins_delay:%d, beat_delay:%d, dbc:%d",mst_mm_dly.addr_delay, mst_mm_dly.data_ins_delay, mst_mm_dly.beat_delay, mst_mm_dly.dbc_delay), UVM_HIGH)

endfunction : get_trans_delay

`endif // _AXI_MM_MST_AGENT_SV_
