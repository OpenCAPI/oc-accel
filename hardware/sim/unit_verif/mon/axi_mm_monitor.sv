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
`ifndef _AXI_MM_MONITOR_SV_
`define _AXI_MM_MONITOR_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_mm_monitor
//
// XXX
//-------------------------------------------------------------------------------------

class axi_mm_monitor extends uvm_monitor;

    virtual interface                          axi_vip_if `AXI_VIP_MM_CHECK_PARAMS mm_check_vif;
    axi_vip_mm_check_passthrough_t             axi_vip_mm_check_passthrough;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_tran_port;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_cmd_rd_port;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_cmd_wr_port;

    string                                     tID;
    int                                        rd_num;
    int                                        wr_num;
    int                                        cmd_wr_num;
    int                                        cmd_rd_num;
    int                                        void_num;
    bit [31:0]                                 data_size;
    axi_monitor_transaction                    axi_monitor_trans;
    xil_axi_cmd_beat                           axi_wr_trans;
    xil_axi_cmd_beat                           axi_rd_trans;
    axi_mm_transaction                         txn;
    axi_mm_transaction                         txn_rd;
    axi_mm_transaction                         txn_wr;

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

    //------------------------FUNCTIONAL COVERAGE--------------------------------
    //
    bit [63:0] c_axi_strobe;

    covergroup c_axi_mm_read_packet;
        option.per_instance = 1;
        byte_size: coverpoint txn.byte_size {
            bins byte_size_1          ={1};
            bins byte_size_2          ={2};
            bins byte_size_4          ={4};
            bins byte_size_8          ={8};
            bins byte_size_16         ={16};
            bins byte_size_32         ={32};
            bins byte_size_64         ={64};
            bins byte_size_128        ={128};
        }
        burst_length_short: coverpoint txn.burst_length {
            option.weight=0;
            bins burst_length_short[] ={[1:32]};
        }
        burst_length_full: coverpoint txn.burst_length {
            bins burst_length[]       ={[1:512]};
        }
        axi_id: coverpoint txn.axi_id {
            bins axi_id[]             ={[0:31]};
        }
        axi_usr: coverpoint txn.axi_usr {
            bins axi_usr[]            ={[0:511]};
        }
        axi_addr_bit0: coverpoint txn.addr[0];
        axi_addr_bit1: coverpoint txn.addr[1];
        axi_addr_bit2: coverpoint txn.addr[2];
        axi_addr_bit3: coverpoint txn.addr[3];
        axi_addr_bit4: coverpoint txn.addr[4];
        axi_addr_bit5: coverpoint txn.addr[5];
        axi_addr_bit6: coverpoint txn.addr[6];
        axi_addr_bit7: coverpoint txn.addr[7];
        axi_addr_bit8: coverpoint txn.addr[8];
        axi_addr_bit9: coverpoint txn.addr[9];
        axi_addr_bit10: coverpoint txn.addr[10];
        axi_addr_bit11: coverpoint txn.addr[11];
        axi_addr_bit12: coverpoint txn.addr[12];
        axi_addr_bit13: coverpoint txn.addr[13];
        axi_addr_bit14: coverpoint txn.addr[14];
        axi_addr_bit15: coverpoint txn.addr[15];
        axi_addr_bit16: coverpoint txn.addr[16];
        axi_addr_bit17: coverpoint txn.addr[17];
        axi_addr_bit18: coverpoint txn.addr[18];
        axi_addr_bit19: coverpoint txn.addr[19];
        axi_addr_bit20: coverpoint txn.addr[20];
        axi_addr_bit21: coverpoint txn.addr[21];
        axi_addr_bit22: coverpoint txn.addr[22];
        axi_addr_bit23: coverpoint txn.addr[23];
        axi_addr_bit24: coverpoint txn.addr[24];
        axi_addr_bit25: coverpoint txn.addr[25];
        axi_addr_bit26: coverpoint txn.addr[26];
        axi_addr_bit27: coverpoint txn.addr[27];
        axi_addr_bit28: coverpoint txn.addr[28];
        axi_addr_bit29: coverpoint txn.addr[29];
        axi_addr_bit30: coverpoint txn.addr[30];
        axi_addr_bit31: coverpoint txn.addr[31];
        axi_addr_bit32: coverpoint txn.addr[32];
        axi_addr_bit33: coverpoint txn.addr[33];
        axi_addr_bit34: coverpoint txn.addr[34];
        axi_addr_bit35: coverpoint txn.addr[35];
        axi_addr_bit36: coverpoint txn.addr[36];
        axi_addr_bit37: coverpoint txn.addr[37];
        axi_addr_bit38: coverpoint txn.addr[38];
        axi_addr_bit39: coverpoint txn.addr[39];
        axi_addr_bit40: coverpoint txn.addr[40];
        axi_addr_bit41: coverpoint txn.addr[41];
        axi_addr_bit42: coverpoint txn.addr[42];
        axi_addr_bit43: coverpoint txn.addr[43];
        axi_addr_bit44: coverpoint txn.addr[44];
        axi_addr_bit45: coverpoint txn.addr[45];
        axi_addr_bit46: coverpoint txn.addr[46];
        axi_addr_bit47: coverpoint txn.addr[47];
        axi_addr_bit48: coverpoint txn.addr[48];
        axi_addr_bit49: coverpoint txn.addr[49];
        axi_addr_bit50: coverpoint txn.addr[50];
        axi_addr_bit51: coverpoint txn.addr[51];
        axi_addr_bit52: coverpoint txn.addr[52];
        axi_addr_bit53: coverpoint txn.addr[53];
        axi_addr_bit54: coverpoint txn.addr[54];
        axi_addr_bit55: coverpoint txn.addr[55];
        axi_addr_bit56: coverpoint txn.addr[56];
        axi_addr_bit57: coverpoint txn.addr[57];
        axi_addr_bit58: coverpoint txn.addr[58];
        axi_addr_bit59: coverpoint txn.addr[59];
        axi_addr_bit60: coverpoint txn.addr[60];
        axi_addr_bit61: coverpoint txn.addr[61];
        axi_addr_bit62: coverpoint txn.addr[62];
        axi_addr_bit63: coverpoint txn.addr[63];
        cross_size_length: cross byte_size, burst_length_short;

    endgroup : c_axi_mm_read_packet

    covergroup c_axi_mm_write_packet;
        option.per_instance = 1;
        byte_size: coverpoint txn.byte_size {
            bins byte_size_1          ={1};
            bins byte_size_2          ={2};
            bins byte_size_4          ={4};
            bins byte_size_8          ={8};
            bins byte_size_16         ={16};
            bins byte_size_32         ={32};
            bins byte_size_64         ={64};
            bins byte_size_128        ={128};
        }
        burst_length_short: coverpoint txn.burst_length {
            option.weight=0;
            bins burst_length_short[] ={[1:32]};
        }
        burst_length_full: coverpoint txn.burst_length {
            bins burst_length[]       ={[1:512]};
        }
        axi_id: coverpoint txn.axi_id {
            bins axi_id[]             ={[0:31]};
        }
        axi_usr: coverpoint txn.axi_usr {
            bins axi_usr[]            ={[0:511]};
        }
        axi_addr_bit0: coverpoint txn.addr[0];
        axi_addr_bit1: coverpoint txn.addr[1];
        axi_addr_bit2: coverpoint txn.addr[2];
        axi_addr_bit3: coverpoint txn.addr[3];
        axi_addr_bit4: coverpoint txn.addr[4];
        axi_addr_bit5: coverpoint txn.addr[5];
        axi_addr_bit6: coverpoint txn.addr[6];
        axi_addr_bit7: coverpoint txn.addr[7];
        axi_addr_bit8: coverpoint txn.addr[8];
        axi_addr_bit9: coverpoint txn.addr[9];
        axi_addr_bit10: coverpoint txn.addr[10];
        axi_addr_bit11: coverpoint txn.addr[11];
        axi_addr_bit12: coverpoint txn.addr[12];
        axi_addr_bit13: coverpoint txn.addr[13];
        axi_addr_bit14: coverpoint txn.addr[14];
        axi_addr_bit15: coverpoint txn.addr[15];
        axi_addr_bit16: coverpoint txn.addr[16];
        axi_addr_bit17: coverpoint txn.addr[17];
        axi_addr_bit18: coverpoint txn.addr[18];
        axi_addr_bit19: coverpoint txn.addr[19];
        axi_addr_bit20: coverpoint txn.addr[20];
        axi_addr_bit21: coverpoint txn.addr[21];
        axi_addr_bit22: coverpoint txn.addr[22];
        axi_addr_bit23: coverpoint txn.addr[23];
        axi_addr_bit24: coverpoint txn.addr[24];
        axi_addr_bit25: coverpoint txn.addr[25];
        axi_addr_bit26: coverpoint txn.addr[26];
        axi_addr_bit27: coverpoint txn.addr[27];
        axi_addr_bit28: coverpoint txn.addr[28];
        axi_addr_bit29: coverpoint txn.addr[29];
        axi_addr_bit30: coverpoint txn.addr[30];
        axi_addr_bit31: coverpoint txn.addr[31];
        axi_addr_bit32: coverpoint txn.addr[32];
        axi_addr_bit33: coverpoint txn.addr[33];
        axi_addr_bit34: coverpoint txn.addr[34];
        axi_addr_bit35: coverpoint txn.addr[35];
        axi_addr_bit36: coverpoint txn.addr[36];
        axi_addr_bit37: coverpoint txn.addr[37];
        axi_addr_bit38: coverpoint txn.addr[38];
        axi_addr_bit39: coverpoint txn.addr[39];
        axi_addr_bit40: coverpoint txn.addr[40];
        axi_addr_bit41: coverpoint txn.addr[41];
        axi_addr_bit42: coverpoint txn.addr[42];
        axi_addr_bit43: coverpoint txn.addr[43];
        axi_addr_bit44: coverpoint txn.addr[44];
        axi_addr_bit45: coverpoint txn.addr[45];
        axi_addr_bit46: coverpoint txn.addr[46];
        axi_addr_bit47: coverpoint txn.addr[47];
        axi_addr_bit48: coverpoint txn.addr[48];
        axi_addr_bit49: coverpoint txn.addr[49];
        axi_addr_bit50: coverpoint txn.addr[50];
        axi_addr_bit51: coverpoint txn.addr[51];
        axi_addr_bit52: coverpoint txn.addr[52];
        axi_addr_bit53: coverpoint txn.addr[53];
        axi_addr_bit54: coverpoint txn.addr[54];
        axi_addr_bit55: coverpoint txn.addr[55];
        axi_addr_bit56: coverpoint txn.addr[56];
        axi_addr_bit57: coverpoint txn.addr[57];
        axi_addr_bit58: coverpoint txn.addr[58];
        axi_addr_bit59: coverpoint txn.addr[59];
        axi_addr_bit60: coverpoint txn.addr[60];
        axi_addr_bit61: coverpoint txn.addr[61];
        axi_addr_bit62: coverpoint txn.addr[62];
        axi_addr_bit63: coverpoint txn.addr[63];
        cross_size_length: cross byte_size, burst_length_short;
    endgroup : c_axi_mm_write_packet

    covergroup c_axi_mm_strobe;
        axi_strobe_bit0: coverpoint c_axi_strobe[0];
        axi_strobe_bit1: coverpoint c_axi_strobe[1];
        axi_strobe_bit2: coverpoint c_axi_strobe[2];
        axi_strobe_bit3: coverpoint c_axi_strobe[3];
        axi_strobe_bit4: coverpoint c_axi_strobe[4];
        axi_strobe_bit5: coverpoint c_axi_strobe[5];
        axi_strobe_bit6: coverpoint c_axi_strobe[6];
        axi_strobe_bit7: coverpoint c_axi_strobe[7];
        axi_strobe_bit8: coverpoint c_axi_strobe[8];
        axi_strobe_bit9: coverpoint c_axi_strobe[9];
        axi_strobe_bit10: coverpoint c_axi_strobe[10];
        axi_strobe_bit11: coverpoint c_axi_strobe[11];
        axi_strobe_bit12: coverpoint c_axi_strobe[12];
        axi_strobe_bit13: coverpoint c_axi_strobe[13];
        axi_strobe_bit14: coverpoint c_axi_strobe[14];
        axi_strobe_bit15: coverpoint c_axi_strobe[15];
        axi_strobe_bit16: coverpoint c_axi_strobe[16];
        axi_strobe_bit17: coverpoint c_axi_strobe[17];
        axi_strobe_bit18: coverpoint c_axi_strobe[18];
        axi_strobe_bit19: coverpoint c_axi_strobe[19];
        axi_strobe_bit20: coverpoint c_axi_strobe[20];
        axi_strobe_bit21: coverpoint c_axi_strobe[21];
        axi_strobe_bit22: coverpoint c_axi_strobe[22];
        axi_strobe_bit23: coverpoint c_axi_strobe[23];
        axi_strobe_bit24: coverpoint c_axi_strobe[24];
        axi_strobe_bit25: coverpoint c_axi_strobe[25];
        axi_strobe_bit26: coverpoint c_axi_strobe[26];
        axi_strobe_bit27: coverpoint c_axi_strobe[27];
        axi_strobe_bit28: coverpoint c_axi_strobe[28];
        axi_strobe_bit29: coverpoint c_axi_strobe[29];
        axi_strobe_bit30: coverpoint c_axi_strobe[30];
        axi_strobe_bit31: coverpoint c_axi_strobe[31];
        axi_strobe_bit32: coverpoint c_axi_strobe[32];
        axi_strobe_bit33: coverpoint c_axi_strobe[33];
        axi_strobe_bit34: coverpoint c_axi_strobe[34];
        axi_strobe_bit35: coverpoint c_axi_strobe[35];
        axi_strobe_bit36: coverpoint c_axi_strobe[36];
        axi_strobe_bit37: coverpoint c_axi_strobe[37];
        axi_strobe_bit38: coverpoint c_axi_strobe[38];
        axi_strobe_bit39: coverpoint c_axi_strobe[39];
        axi_strobe_bit40: coverpoint c_axi_strobe[40];
        axi_strobe_bit41: coverpoint c_axi_strobe[41];
        axi_strobe_bit42: coverpoint c_axi_strobe[42];
        axi_strobe_bit43: coverpoint c_axi_strobe[43];
        axi_strobe_bit44: coverpoint c_axi_strobe[44];
        axi_strobe_bit45: coverpoint c_axi_strobe[45];
        axi_strobe_bit46: coverpoint c_axi_strobe[46];
        axi_strobe_bit47: coverpoint c_axi_strobe[47];
        axi_strobe_bit48: coverpoint c_axi_strobe[48];
        axi_strobe_bit49: coverpoint c_axi_strobe[49];
        axi_strobe_bit50: coverpoint c_axi_strobe[50];
        axi_strobe_bit51: coverpoint c_axi_strobe[51];
        axi_strobe_bit52: coverpoint c_axi_strobe[52];
        axi_strobe_bit53: coverpoint c_axi_strobe[53];
        axi_strobe_bit54: coverpoint c_axi_strobe[54];
        axi_strobe_bit55: coverpoint c_axi_strobe[55];
        axi_strobe_bit56: coverpoint c_axi_strobe[56];
        axi_strobe_bit57: coverpoint c_axi_strobe[57];
        axi_strobe_bit58: coverpoint c_axi_strobe[58];
        axi_strobe_bit59: coverpoint c_axi_strobe[59];
        axi_strobe_bit60: coverpoint c_axi_strobe[60];
        axi_strobe_bit61: coverpoint c_axi_strobe[61];
        axi_strobe_bit62: coverpoint c_axi_strobe[62];
        axi_strobe_bit63: coverpoint c_axi_strobe[63];    
    endgroup : c_axi_mm_strobe

    `uvm_component_utils_begin(axi_mm_monitor)
        `uvm_field_string(work_mode, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_mm_monitor", uvm_component parent = null);

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
    extern function void check_transactions_inflight();
    // }@
    extern task collect_transactions();
    extern task collect_cmd_rd();
    extern task collect_cmd_wr();

endclass : axi_mm_monitor

// Function: new
// Creates a new dbb check monitor
function axi_mm_monitor::new(string name = "axi_mm_monitor", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    axi_mm_tran_port = new("axi_mm_tran_port", this);
    axi_mm_cmd_rd_port = new("axi_mm_cmd_rd_port", this);
    axi_mm_cmd_wr_port = new("axi_mm_cmd_wr_port", this);
    c_axi_mm_read_packet = new();
    c_axi_mm_read_packet.set_inst_name({get_full_name(),".c_axi_mm_read_packet"});
    c_axi_mm_write_packet = new();
    c_axi_mm_write_packet.set_inst_name({get_full_name(),".c_axi_mm_write_packet"});
    c_axi_mm_strobe = new();
    c_axi_mm_strobe.set_inst_name({get_full_name(),".c_axi_mm_strobe"});
    wr_num = 0;
    rd_num = 0;
    void_num = 0;
endfunction : new

// Function: build_phase
// XXX
function void axi_mm_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_mm_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)
    if(!uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_CHECK_PARAMS)::get(this, "", "mm_check_vif", mm_check_vif)) begin
        `uvm_fatal(tID, "No virtual interface mm_check_vif specified fo axi_mm_monitor")
    end
    axi_vip_mm_check_passthrough = new("axi_vip_mm_check_passthrough", mm_check_vif);
    endfunction : connect_phase

function void axi_mm_monitor::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)

endfunction : start_of_simulation_phase
// Task: main_phase
// XXX
task axi_mm_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)

endtask : run_phase

// Task: main_phase
// XXX
task axi_mm_monitor::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    //axi_vip_mm_check_passthrough.start_master();
    //axi_vip_mm_check_passthrough.start_slave();
    axi_vip_mm_check_passthrough.start_monitor();
    axi_vip_mm_check_passthrough.monitor.axi_rd_cmd_port.set_enabled();
    axi_vip_mm_check_passthrough.monitor.axi_wr_cmd_port.set_enabled();
    fork
        collect_transactions();
        collect_cmd_rd();
        collect_cmd_wr();
    join
endtask : main_phase

task axi_mm_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase

function void axi_mm_monitor::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_MEDIUM)
    `uvm_info(tID, $sformatf("DBB Monitor Detects %0d axi-read and %0d of that have finished.", cmd_rd_num, rd_num), UVM_MEDIUM)
    `uvm_info(tID, $sformatf("DBB Monitor Detects %0d axi-write and %0d of that have finished.", cmd_wr_num, wr_num), UVM_MEDIUM)
    check_transactions_inflight();
endfunction : check_phase

task axi_mm_monitor::collect_transactions();
    `uvm_info(tID, $sformatf("dbb check collect_transactions begin ..."), UVM_MEDIUM)
    axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_monitor_trans=new("axi_monitor_trans");
        txn=new();
        data_size = 32'b1;
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.item_collected_port.get(axi_monitor_trans);
        if(axi_monitor_trans.get_cmd_type()== XIL_AXI_READ) begin
            rd_num ++;
            txn.trans=axi_mm_transaction::READ;
            txn.addr=axi_monitor_trans.get_addr();
            txn.burst_length=axi_monitor_trans.get_len()+1;
            for(int i=0; i<txn.burst_length; i++) begin
                txn.data[i]=axi_monitor_trans.get_data_beat(i);
            end
            txn.byte_size=(data_size << axi_monitor_trans.get_size());
            txn.axi_id=axi_monitor_trans.get_id();
            //TODO: Get usr from axi_monitor_trans
            //txn.axi_usr=axi_monitor_trans.get_user();
            c_axi_mm_read_packet.sample();            
            `uvm_info(tID, $sformatf("DBB Monitor Detects a Read:\n%s", txn.sprint()), UVM_MEDIUM);
            axi_mm_tran_port.write(txn);
        end
        else if(axi_monitor_trans.get_cmd_type()==XIL_AXI_WRITE) begin
            wr_num ++;
            txn.trans=axi_mm_transaction::WRITE;
            txn.addr=axi_monitor_trans.get_addr();
            txn.burst_length=axi_monitor_trans.get_len()+1;
            for(int i=0; i<txn.burst_length; i++) begin
                txn.data[i]=axi_monitor_trans.get_data_beat(i);
                txn.data_strobe[i]=axi_monitor_trans.get_strb_beat(i);
                c_axi_strobe=txn.data_strobe[i];
                c_axi_mm_strobe.sample();            
            end
            txn.byte_size=(data_size << axi_monitor_trans.get_size());
            txn.axi_id=axi_monitor_trans.get_id();
            //TODO: Get usr from axi_monitor_trans
            //txn.axi_usr=axi_monitor_trans.get_user();
            c_axi_mm_write_packet.sample();            
            `uvm_info(tID, $sformatf("DBB Monitor Detects a Write:\n%s", txn.sprint()), UVM_MEDIUM);
            axi_mm_tran_port.write(txn);
        end
        else begin
            `uvm_info(tID, $sformatf("DBB monitor detects nothing"), UVM_MEDIUM)
            void_num ++;
        end
    end
endtask : collect_transactions

task axi_mm_monitor::collect_cmd_rd();
    `uvm_info(tID, $sformatf("dbb check collect_cmd_rd begin ..."), UVM_MEDIUM)
    axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_rd_trans=new("axi_rd_trans");
        txn_rd=new();
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.axi_rd_cmd_port.get(axi_rd_trans);
        `uvm_info(this.get_type_name(), axi_rd_trans.convert2string(), UVM_MEDIUM)        
        txn_rd.trans=axi_mm_transaction::READ;
        txn_rd.addr=axi_rd_trans.addr;
        txn_rd.burst_length=axi_rd_trans.len+1;
        txn_rd.byte_size=(32'b1 << axi_rd_trans.size);
        txn_rd.axi_id=axi_rd_trans.id;
        //txn_rd.axi_usr=axi_rd_trans.get_user();
        `uvm_info(tID, $sformatf("DBB Monitor Detects a AXI Read Cmd:"), UVM_MEDIUM);
        //`uvm_info(tID, axi_rd_trans.convert2string(), UVM_MEDIUM)
        axi_mm_cmd_rd_port.write(txn_rd);
        cmd_rd_num ++;
    end
endtask : collect_cmd_rd

task axi_mm_monitor::collect_cmd_wr();
    `uvm_info(tID, $sformatf("dbb check collect_cmd_wr begin ..."), UVM_MEDIUM)
    forever begin
        axi_wr_trans=new("axi_wr_trans");
        txn_wr=new();
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
        axi_vip_mm_check_passthrough.monitor.axi_wr_cmd_port.get(axi_wr_trans);
        `uvm_info(this.get_type_name(), axi_wr_trans.convert2string(), UVM_MEDIUM)        
        txn_wr.trans=axi_mm_transaction::WRITE;
        txn_wr.addr=axi_wr_trans.addr;
        txn_wr.burst_length=axi_wr_trans.len+1;
        txn_wr.byte_size=(32'b1 << axi_wr_trans.size);
        txn_wr.axi_id=axi_wr_trans.id;
        //txn_wr.axi_usr=axi_wr_trans.get_user();
        `uvm_info(tID, $sformatf("DBB Monitor Detects a AXI Write Cmd:"), UVM_MEDIUM);
        //`uvm_info(tID, axi_wr_trans.convert2string(), UVM_MEDIUM)
        axi_mm_cmd_wr_port.write(txn_wr);
        cmd_wr_num ++;
    end
endtask : collect_cmd_wr

function void axi_mm_monitor::check_transactions_inflight();
    int read_inflight_num;
    int write_inflight_num;
    read_inflight_num = axi_vip_mm_check_passthrough.monitor.get_num_rd_transactions_inflight();
    write_inflight_num = axi_vip_mm_check_passthrough.monitor.get_num_wr_transactions_inflight();
    if(read_inflight_num > 0) begin
         `uvm_error(tID, $sformatf("There are %d axi-read transctions in flight!", read_inflight_num))
    end
    if(write_inflight_num > 0) begin
         `uvm_error(tID, $sformatf("There are %d axi-write transctions in flight!", write_inflight_num))
    end

endfunction : check_transactions_inflight

`endif // _AXI_MONITOR_SV_
