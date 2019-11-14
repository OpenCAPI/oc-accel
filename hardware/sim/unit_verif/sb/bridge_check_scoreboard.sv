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
`ifndef _BRIDGE_CHECK_SCOREBOARD_
`define _BRIDGE_CHECK_SCOREBOARD_

//------------------------------------------------------------------------------
//
// CLASS: bridge_check_sbd
//
//------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_tlx_afu)
`uvm_analysis_imp_decl(_afu_tlx)
`uvm_analysis_imp_decl(_axi_mm)
`uvm_analysis_imp_decl(_axi_mm_cmd_rd)
`uvm_analysis_imp_decl(_axi_mm_cmd_wr)
`uvm_analysis_imp_decl(_intrp)

class bridge_check_scoreboard extends uvm_component;

    typedef class brdg_packet;
    typedef class tlx_resp_packet;
    typedef class intrp_packet;
    //TLM port & transaction declaration
    uvm_analysis_imp_tlx_afu        #(tlx_afu_transaction, bridge_check_scoreboard) aimp_tlx_afu;
    uvm_analysis_imp_afu_tlx        #(afu_tlx_transaction, bridge_check_scoreboard) aimp_afu_tlx;
    uvm_analysis_imp_axi_mm         #(axi_mm_transaction, bridge_check_scoreboard) aimp_axi_mm;
    uvm_analysis_imp_axi_mm_cmd_rd  #(axi_mm_transaction, bridge_check_scoreboard) aimp_axi_mm_cmd_rd;
    uvm_analysis_imp_axi_mm_cmd_wr  #(axi_mm_transaction, bridge_check_scoreboard) aimp_axi_mm_cmd_wr;
    uvm_analysis_imp_intrp         #(intrp_transaction, bridge_check_scoreboard) aimp_intrp;
    brdg_cfg_obj                    brdg_cfg;

    //Internal signals declaration
    string tID;
    int read_num;
    int write_num;
    int intrp_num;
    bit [7:0] memory_model[longint unsigned];
    bit memory_tag[longint unsigned];
    bit [47:0] axi_rd_idx[bit[15:0]]; //Number of AXI read cmd beats, the index is comprised of {user[7:0],id[7:0]}
    bit [47:0] axi_wr_idx[bit[15:0]]; //Number of AXI write cmd beats, the index is comprised of {user[7:0],id[7:0]}
    bit [47:0] axi_rd_finish_idx[bit[15:0]]; //Number of AXI read beats finished, the index is comprised of {user[7:0],id[7:0]}
    bit [47:0] axi_wr_finish_idx[bit[15:0]]; //Number of AXI write beats finished, the index is comprised of {user[7:0],id[7:0]}
    axi_mm_transaction axi_rd_cmd[bit[63:0]]; //AXI read command for each beat, the index is comprised of {user[7:0],id[7:0],num[47:0]}
    axi_mm_transaction axi_wr_cmd[bit[63:0]]; //AXI write command for each beat, the index is comprised of {user[7:0],id[7:0].num[47:0]}
    brdg_packet brdg_packet_read[bit[63:0]]; //Bridge read commands and responses packet for each AXI beat
    brdg_packet brdg_packet_write[bit[63:0]]; //Bridge write commands and responses packet for each AXI beat
    axi_mm_transaction axi_trans_q[$];
    afu_tlx_transaction flight_afu_tlx_rd[bit[15:0]]; //Bridge read commands in flight, the index is afutag
    afu_tlx_transaction flight_afu_tlx_wr[bit[15:0]]; //Bridge write commands in flight, the index is afutag
    afu_tlx_transaction flight_afu_tlx_intrp[bit[15:0]]; //Bridge interrupt in flight, the index is afutag
    tlx_resp_packet tlx_read_resp[bit[15:0]]; //Tlx_afu read response, the index is afutag
    tlx_resp_packet tlx_write_resp[bit[15:0]]; //Tlx_afu write response, the index is afutag
    bit [7:0] brdg_read_memory[longint unsigned]; //Brdg read data from tlx
    bit [7:0] brdg_write_memory[longint unsigned]; //Brdg write data to tlx
    intrp_packet brdg_intrp; //Bridge interrupt

    //Bridge commands and responses packet structure
    class brdg_packet;
        int brdg_cmd_num; //The number of bridge commands for one AXI beat
        bit tlx_resp_success; //All of the tlx response and data are returned successfully
        bit axi_resp_success; //The beat response and data are returned successfully
        afu_tlx_transaction expect_brdg_cmd[shortint unsigned]; //Expected afu tlx commands for one AXI beat, index is the number of brdg transfer in one AXI beat  
        afu_tlx_transaction actual_brdg_cmd[shortint unsigned]; //Actual afu tlx commands and data for one AXI beat, index is the number of brdg transfer in one AXI beat
        bit[15:0] brdg_cmd_afutag[shortint unsigned]; //Afutags of expected afu tlx commands, index is the number of brdg transfer in one AXI beat
        bit brdg_cmd_pending[shortint unsigned]; //The expected afu tlx command should wait for xlate_done, index is the number of brdg transfer in one AXI beat
        bit brdg_resp_success[shortint unsigned]; //The expected tlx afu response are received successfully, index is the number of brdg transfer in one AXI beat
        bit brdg_resp_pending[shortint unsigned]; //The expected afu tlx command was send(retry will delete the related bit), index is the number of brdg transfer in one AXI beat
        function new(string name = "brdg_packet");
        endfunction            
    endclass: brdg_packet

    //TLX responses packet structure
    class tlx_resp_packet;
        int tlx_afu_reap_num; //The number of read/write response from tlx
        tlx_afu_transaction tlx_afu_reap[bit[1:0]]; //Read/write response from tlx, the index is the value of dp
        function new(string name = "tlx_resp_packet");
            tlx_afu_reap_num=0;
        endfunction            
    endclass: tlx_resp_packet

    //Interrupt packet structure
    class intrp_packet; //The number of read/write response from tlx
        bit [1:0] intrp_status; //2'b00:idle, 2'b01:intrp_valid. 2'b10:intrp_send, 2'b11:intrp_resp_success
        intrp_transaction intrp_trans;
        afu_tlx_transaction intrp_afu_tlx;
        bit intrp_cmd_pending; //The expected afu tlx interrupt should wait for intrp_rdy
        function new(string name = "intrp_packet");
            intrp_status=0;
        endfunction   
    endclass: intrp_packet

    `uvm_component_utils_begin(bridge_check_scoreboard)
    `uvm_component_utils_end

    extern function new(string name = "bridge_check_scoreboard", uvm_component parent = null);

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
    extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);

    extern function bit exist_data(longint unsigned addr, int byte_size, int burst_length);
    extern function bit check_data_err(bit[63:0] addr, bit[255:0][1023:0] data, int byte_size, int burst_length);
    extern function axi_mm_transaction get_mem_trans(bit[63:0] addr, int byte_size, int burst_length, axi_mm_transaction::uvm_axi_txn_e trans);
    extern function void print_mem();

    //extern function void write_bridge_check(bridge_check_transaction bridge_check_tran);
    extern function void write_tlx_afu(tlx_afu_transaction tlx_afu_tran);
    extern function void write_afu_tlx(afu_tlx_transaction afu_tlx_tran);    
    extern function void write_axi_mm(axi_mm_transaction axi_mm_tran);
    extern function void write_axi_mm_cmd_rd(axi_mm_transaction axi_mm_cmd_rd);    
    extern function void write_axi_mm_cmd_wr(axi_mm_transaction axi_mm_cmd_wr);    
    extern function void write_intrp(intrp_transaction intrp_tran);
    extern function void reset();
    extern function void result_check();
    extern task check_txn();
    extern function int dl2dl_num(bit[1:0] dl);
    extern function void parse_axi_cmd(axi_mm_transaction axi_trans, bit nrw, bit[63:0] axi_cmd_idx);
    extern function bit[47:0] get_axi_idx(bit[15:0]usr_id, bit nrw, bit finish);
    extern function void check_send_cmd_timer(bit[63:0] axi_cmd_idx, bit nrw);
    extern function bit afutag_in_flight(bit[15:0] afutag);
    extern function bit check_expected_brdg_cmd(bit nrw, afu_tlx_transaction afu_tlx_tran);
    extern function void check_tlx_resp(bit nrw, bit[15:0]afutag, tlx_afu_transaction tlx_afu_tran);
    extern function void set_brdg_resp_success(bit nrw, bit[15:0] afutag);
    extern function bit check_resp_data(axi_mm_transaction axi_mm_tran, bit[63:0]beat_index, bit nrw);
    extern function void write_brdg_memory(bit[63:0] brdg_addr, bit[63:0] brdg_addr_mask, bit[511:0] data, bit nrw);
    extern function bit[63:0] gen_pr_mask(bit[63:0] brdg_addr, bit[2:0] brdg_plength);
    extern function bit check_brdg_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);

endclass : bridge_check_scoreboard

function bridge_check_scoreboard::new(string name = "bridge_check_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    aimp_tlx_afu = new("aimp_tlx_afu", this);
    aimp_afu_tlx = new("aimp_afu_tlx", this);
    aimp_axi_mm  = new("aimp_axi_mm", this);
    aimp_axi_mm_cmd_rd  = new("aimp_axi_mm_cmd_rd", this);
    aimp_axi_mm_cmd_wr  = new("aimp_axi_mm_cmd_wr", this);
    aimp_intrp = new("aimp_intrp", this);
    read_num    = 0;
    write_num  = 0;
    intrp_num    = 0;
    brdg_intrp   = new("brdg_intrp");
endfunction : new

function void bridge_check_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
endfunction : build_phase

function void bridge_check_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
    if(!uvm_config_db#(brdg_cfg_obj)::get(this, "", "brdg_cfg", brdg_cfg))
        `uvm_error(get_type_name(), "Can't get brdg_cfg!")
endfunction : connect_phase

task bridge_check_scoreboard::main_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)
    //fork
    //    reset();
    //    check_txn();
    //join
endtask: main_phase

function void bridge_check_scoreboard::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_HIGH)
    result_check();
endfunction : check_phase

function bit bridge_check_scoreboard::check_data_err(bit[63:0] addr, bit [255:0][1023:0] data, int byte_size, int burst_length);
    for(int j=0; j<burst_length; j++)begin
        for(int i=0; i<byte_size; i++)begin
            if(data[j][8*i+7-:8] != memory_model[addr+j*byte_size+i])begin
                return 1;
            end
        end
    end
    return 0;
endfunction: check_data_err

function bit bridge_check_scoreboard::exist_data(longint unsigned addr, int byte_size, int burst_length);
    for(int j=0; j<burst_length; j++)begin
        for(int i=0; i<byte_size; i++)begin
            if(!memory_tag.exists(addr+j*byte_size+i))begin
                return 0;
            end
        end
    end
    return 1;
endfunction: exist_data

function void bridge_check_scoreboard::print_mem();
        foreach(memory_tag[i])begin
            $display("Memory addr:%h,data:%h.", i, memory_model[i]);
        end
endfunction: print_mem

function axi_mm_transaction bridge_check_scoreboard::get_mem_trans(bit[63:0] addr, int byte_size, int burst_length, axi_mm_transaction::uvm_axi_txn_e trans);
    get_mem_trans = new("get_mem_trans");
    get_mem_trans.trans=trans;
    get_mem_trans.addr=addr;
    get_mem_trans.byte_size=byte_size;
    get_mem_trans.burst_length=burst_length;
    for(int j=0; j<burst_length; j++)
        for(int i=0; i<byte_size; i++)
            get_mem_trans.data[j][i*8+7-:8]=memory_model[addr+j*byte_size+i];
endfunction: get_mem_trans

function void bridge_check_scoreboard::reset();
    foreach(memory_model[i])
        memory_model[i]=0;
    foreach(memory_tag[i])
        memory_tag[i]=0;
    read_num = 0;
    write_num = 0;
    intrp_num = 0;
endfunction : reset

function void bridge_check_scoreboard::write_axi_mm(axi_mm_transaction axi_mm_tran);
    bit[63:0] beat_index;
    bit[15:0] usr_id;
    bit[127:0] axi_mask;
    bit[127:0] axi_wr_mask;    
    bit[63:0] axi_addr_align;
    if(brdg_cfg.enable_brdg_scoreboard)begin
        if(!brdg_cfg.enable_brdg_ref_model)begin
            for(int i=0; i<axi_mm_tran.burst_length; i++)begin
                if(i == 0)begin
                    axi_addr_align=(axi_mm_tran.addr/axi_mm_tran.byte_size)*axi_mm_tran.byte_size+i*axi_mm_tran.byte_size;
                    for(int j=0; j<128; j++)begin
                        if(j>=(axi_mm_tran.addr-((axi_mm_tran.addr/128)*128)) && j<=(axi_addr_align+(axi_mm_tran.byte_size-1)-(axi_mm_tran.addr/128)*128))begin
                            axi_mask[j]=1;
                            if(axi_mm_tran.data_strobe[i][j])begin
                                axi_wr_mask[j]=1;                        
                            end
                            else begin
                                axi_wr_mask[j]=0;                                                        
                            end
                        end
                        else begin
                            axi_mask[j]=0;
                            axi_wr_mask[j]=0;                                                                                
                        end
                    end
                    if(axi_mm_tran.trans == axi_mm_transaction::READ)begin
                        //if(check_brdg_memory((axi_mm_tran.addr/128)*128, axi_mask, axi_mm_tran.data[i]<<(8*(axi_mm_tran.addr-((axi_mm_tran.addr/128)*128))), 0))begin
                        if(check_brdg_memory((axi_addr_align/128)*128, axi_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/128)*128))), 0))begin
                            `uvm_error(tID, $sformatf("Check axi read data failed, the number of transfor is %d.\nThe axi transaction is:\n%s", i, axi_mm_tran.sprint()))
                            break;
                        end
                        else begin
                            `uvm_info(tID, $sformatf("Compare axi read data successfully! Addr=0x%16h, Mask=0x%32h, Data=0x%256h", (axi_mm_tran.addr/128)*128, axi_mask, axi_mm_tran.data[i]), UVM_HIGH)                            
                        end
                    end
                    else begin
                        if(check_brdg_memory((axi_addr_align/128)*128, axi_wr_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/128)*128))), 1))begin
                            `uvm_error(tID, $sformatf("Check axi write data failed, the number of transfor is %d.\nThe axi transaction is:\n%s", i, axi_mm_tran.sprint()))
                            break;
                        end
                        else begin
                            `uvm_info(tID, $sformatf("Compare axi write data successfully! Addr=0x%16h, Mask=0x%32h, Data=0x%256h", (axi_mm_tran.addr/128)*128, axi_mask, axi_mm_tran.data[i]), UVM_HIGH)
                        end
                    end
                end
                else begin
                    axi_addr_align=(axi_mm_tran.addr/axi_mm_tran.byte_size)*axi_mm_tran.byte_size+i*axi_mm_tran.byte_size;
                    for(int j=0; j<128; j++)begin
                        if(j>=(axi_addr_align-((axi_addr_align/128)*128)) && j<((axi_addr_align-((axi_addr_align/128)*128))+axi_mm_tran.byte_size))begin
                            axi_mask[j]=1;
                            if(axi_mm_tran.data_strobe[i][j])begin
                                axi_wr_mask[j]=1;                        
                            end
                            else begin
                                axi_wr_mask[j]=0;                                                        
                            end
                        end
                        else begin
                            axi_mask[j]=0;
                            axi_wr_mask[j]=0;                                                                                                        
                        end
                    end
                    if(axi_mm_tran.trans == axi_mm_transaction::READ)begin
                        if(check_brdg_memory((axi_addr_align/128)*128, axi_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/128)*128))), 0))begin
                            `uvm_error(tID, $sformatf("Check axi read data failed, the number of transfor is %d.\nThe axi transaction is:\n%s", i, axi_mm_tran.sprint()))
                            break;
                        end
                        else begin
                            `uvm_info(tID, $sformatf("Compare axi read data successfully! Addr=0x%16h, Mask=0x%32h, Data=0x%256h", (axi_addr_align/128)*128, axi_mask, axi_mm_tran.data[i]), UVM_HIGH)                                                    
                        end
                    end
                    else begin
                        if(check_brdg_memory((axi_addr_align/128)*128, axi_wr_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/128)*128))), 1))begin
                            `uvm_error(tID, $sformatf("Check axi write data failed, the number of transfor is %d.\nThe axi transaction is:\n%s", i, axi_mm_tran.sprint()))
                            break;
                        end
                        else begin
                            `uvm_info(tID, $sformatf("Compare axi write data successfully! Addr=0x%16h, Mask=0x%32h, Data=0x%256h", (axi_addr_align/128)*128, axi_mask, axi_mm_tran.data[i]), UVM_HIGH)                                                                            
                        end
                    end
                end
            end
            `uvm_info(tID, $sformatf("Compare axi read/write data successfully! The axi transaction is:\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
            if(axi_mm_tran.trans == axi_mm_transaction::READ)begin
                read_num++;
            end
            else begin
                write_num++;
            end
        end
        else begin
            usr_id={axi_mm_tran.axi_usr, axi_mm_tran.axi_id};
            //Check response order, compare read/write data
            if(axi_mm_tran.trans == axi_mm_transaction::READ)begin
                beat_index={usr_id, get_axi_idx(usr_id, 1'b0, 1'b1)};
                //Check response order
                if(!brdg_packet_read.exists(beat_index))begin
                    `uvm_error(tID, $sformatf("Get an unexpected AXI read resonse of axi_usr=0x%h, axi_id=0x%h.\n%s", usr_id[15:8], usr_id[7:0], axi_mm_tran.sprint()))
                end
                if(brdg_packet_read[beat_index].axi_resp_success)begin
                    `uvm_error(tID, $sformatf("Get an illegal AXI beat number of 0x%16h.", beat_index))                
                end 
                if(!brdg_packet_read[beat_index].tlx_resp_success)begin
                    `uvm_error(tID, $sformatf("The received AXI read resonse of axi_usr=0x%h, axi_id=0x%h is not completed.", usr_id[15:8], usr_id[7:0]))
                    `uvm_info(tID, $sformatf("The received AXI read resonse is:\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
                    `uvm_info(tID, $sformatf("The received tlx-afu read resonses are:"), UVM_MEDIUM)
                    foreach(brdg_packet_read[beat_index].actual_brdg_cmd[i])begin
                        brdg_packet_read[beat_index].actual_brdg_cmd[i].print();
                    end
                end
              
                //Check read data
                if(axi_mm_tran.addr % axi_mm_tran.byte_size > 0)
                    `uvm_error(tID, $sformatf("TODO: Support for unaligned address data comparing."))
                else begin
                    if(check_resp_data(axi_mm_tran, beat_index, 1'b0))begin
                        `uvm_error(tID, $sformatf("AXI read data check failed!\n%s", axi_mm_tran.sprint()))
                    end
                    else begin
                        `uvm_info(tID, $sformatf("AXI read data check successfully!\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
                    end
                end
            end
            else begin
                beat_index={usr_id, get_axi_idx(usr_id, 1'b1, 1'b1)};
                //Check response order
                if(!brdg_packet_write.exists(beat_index))begin
                    `uvm_error(tID, $sformatf("Get an unexpected AXI write resonse of axi_usr=0x%h, axi_id=0x%h.\n%s", usr_id[15:8], usr_id[7:0], axi_mm_tran.sprint()))
                end
                if(brdg_packet_write[beat_index].axi_resp_success)begin
                    `uvm_error(tID, $sformatf("Get an illegal AXI beat number of 0x%16h.", beat_index))                
                end 
                if(!brdg_packet_write[beat_index].tlx_resp_success)begin
                    `uvm_error(tID, $sformatf("The received AXI write resonse of axi_usr=0x%h, axi_id=0x%h is not completed.", usr_id[15:8], usr_id[7:0]))
                    `uvm_info(tID, $sformatf("The received AXI write resonse is:"), UVM_MEDIUM)
                    axi_mm_tran.print();
                    `uvm_info(tID, $sformatf("The received tlx-afu write resonses are:"), UVM_MEDIUM)
                    foreach(brdg_packet_write[beat_index].actual_brdg_cmd[i])begin
                        brdg_packet_write[beat_index].actual_brdg_cmd[i].print();
                    end
                end
                //Check read data
                if(axi_mm_tran.addr % axi_mm_tran.byte_size > 0)
                    `uvm_error(tID, $sformatf("TODO: Support for unaligned address data comparing."))
                else begin
                    if(check_resp_data(axi_mm_tran, beat_index, 1'b1))begin
                        `uvm_error(tID, $sformatf("AXI write data check failed!\n%s", axi_mm_tran.sprint()))
                    end
                    else begin
                        `uvm_info(tID, $sformatf("AXI write data check successfully!\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
                    end
                end
            end
        end
    end
    else begin
        return;
    end
endfunction : write_axi_mm

//Check read/write response data
function bit bridge_check_scoreboard::check_resp_data(axi_mm_transaction axi_mm_tran, bit[63:0]beat_index, bit nrw);
    bit[7:0] mem_check_record[bit[63:0]]; //AXI beat write the related data in the specified address
    bit mem_check_tag[bit[63:0]]; //AXI beat tag all access address
    check_resp_data=0;
    //Check the tlx afu read response data
    if(nrw == 0)begin
        //Record the received AXI read response data
        for(int i=0; i<axi_mm_tran.burst_length; i++)begin
            for(int j=0; j<axi_mm_tran.byte_size; j++)begin
                mem_check_record[axi_mm_tran.addr+axi_mm_tran.byte_size*i+j]=axi_mm_tran.data[i][(axi_mm_tran.addr+axi_mm_tran.byte_size*i+j)%128*8+7-:8];
                mem_check_tag[axi_mm_tran.addr+axi_mm_tran.byte_size*i+j]=1;
            end
        end
        //Check tlx afu response data
        if(!brdg_packet_read.exists(beat_index) || !brdg_packet_read[beat_index].tlx_resp_success)begin
            `uvm_error(tID, $sformatf("Get an illegal AXI read resonse of axi_usr=0x%h, axi_id=0x%h.", beat_index[63:56], beat_index[55:48]))
            check_resp_data=1;
        end
        else begin
            for(int i=0; i<brdg_packet_read[beat_index].brdg_cmd_num; i++)begin
                if(brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_type == afu_tlx_transaction::RD_WNITC)begin
                    for(int j=0; j<dl2dl_num(brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_dl); j++)begin
                        for(int k=0; k<64; k++)begin
                            //Data match && mem_check_tag asserted
                            if((brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_data_bus[j][8*k+7-:8] == mem_check_record[brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k]) 
                            && (mem_check_tag[brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k] == 1))begin
                                mem_check_tag[brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k]=0;
                            end
                            else begin
                                `uvm_info(tID, $sformatf("Data miscompared:\nThe received AXI read resonse is:\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
                                `uvm_info(tID, $sformatf("The received afu-tlx read resonses are:"), UVM_MEDIUM)
                                foreach(brdg_packet_read[beat_index].actual_brdg_cmd[m])begin
                                    brdg_packet_read[beat_index].actual_brdg_cmd[m].print();
                                end
                                `uvm_error(tID, $sformatf("Data miscompared between received AXI read response and tlx-afu response."))
                                check_resp_data=1;                                
                            end
                        end
                    end
                end
                else if(brdg_packet_read[beat_index].actual_brdg_cmd[i].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC)begin
                    `uvm_error(tID, $sformatf("TODO: To support PR_RD_WNITC."))
                    check_resp_data=1;                                                    
                end
                else begin
                    `uvm_error(tID, $sformatf("Get an illegal AXI transaction."))
                    check_resp_data=1;                                
                end
            end
        end
    end
    else begin
        //Record the received AXI write response data
        for(int i=0; i<axi_mm_tran.burst_length; i++)begin
            for(int j=0; j<axi_mm_tran.byte_size; j++)begin
                mem_check_record[axi_mm_tran.addr+axi_mm_tran.byte_size*i+j]=axi_mm_tran.data[i][(axi_mm_tran.addr+axi_mm_tran.byte_size*i+j)%128*8+7-:8];
                mem_check_tag[axi_mm_tran.addr+axi_mm_tran.byte_size*i+j]=1;
            end
        end
        //Check tlx afu response data
        if(!brdg_packet_write.exists(beat_index) || !brdg_packet_write[beat_index].tlx_resp_success)begin
            `uvm_error(tID, $sformatf("Get an illegal AXI write resonse of axi_usr=0x%h, axi_id=0x%h.", beat_index[63:56], beat_index[55:48]))
            check_resp_data=1;                                
        end
        else begin
            for(int i=0; i<brdg_packet_write[beat_index].brdg_cmd_num; i++)begin
                if(brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_type == afu_tlx_transaction::DMA_W)begin
                    for(int j=0; j<dl2dl_num(brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_dl); j++)begin
                        for(int k=0; k<64; k++)begin
                            //Data match && mem_check_tag asserted
                            if((brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_data_bus[j][8*k+7-:8] == mem_check_record[brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k]) 
                            && (mem_check_tag[brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k] == 1))begin
                                mem_check_tag[brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_addr+64*j+k]=0;
                            end
                            else begin
                                `uvm_info(tID, $sformatf("Data miscompared:\nThe received AXI write resonse is:"), UVM_MEDIUM)
                                axi_mm_tran.print();
                                `uvm_info(tID, $sformatf("The received afu-tlx write resonses are:"), UVM_MEDIUM)
                                foreach(brdg_packet_write[beat_index].actual_brdg_cmd[m])begin
                                    brdg_packet_write[beat_index].actual_brdg_cmd[m].print();
                                end
                                `uvm_error(tID, $sformatf("Data miscompared between received AXI write response and tlx-afu response."))
                                check_resp_data=1;                                
                            end
                        end
                    end
                end
                else if(brdg_packet_write[beat_index].actual_brdg_cmd[i].afu_tlx_type == afu_tlx_transaction::DMA_PR_W)begin
                    `uvm_error(tID, $sformatf("TODO: To support DMA_PR_W.")) 
                    check_resp_data=1;                                                    
                end
                else begin
                    `uvm_error(tID, $sformatf("Get an illegal AXI transaction."))
                    check_resp_data=1;                                                    
                end
            end
        end
    end
    //Check mem_check_tag
    foreach(mem_check_tag[i])begin
        if(mem_check_tag[i] == 1)begin
            `uvm_error(tID, $sformatf("The address of 0x%16h in axi response that is not touched by tlx-afu response.\nThe received AXI resonse is:\n%s", axi_mm_tran.sprint()))
            check_resp_data=1;                                           
        end
    end
endfunction : check_resp_data

//Parse AXI-read and push into axi_rd_cmd queue
function void bridge_check_scoreboard::write_axi_mm_cmd_rd(axi_mm_transaction axi_mm_cmd_rd);
    bit[63:0] axi_cmd_idx; //Index for axi read command
    if(brdg_cfg.enable_brdg_scoreboard)begin
        axi_cmd_idx[63:0] = {axi_mm_cmd_rd.axi_usr, axi_mm_cmd_rd.axi_id, get_axi_idx({axi_mm_cmd_rd.axi_usr, axi_mm_cmd_rd.axi_id}, 1'b0, 1'b0)}; //TODO check assign_actag axi user changed
        axi_rd_cmd[axi_cmd_idx] = axi_mm_cmd_rd;
        if(!brdg_cfg.enable_brdg_ref_model)begin
            return;
        end
        else begin
            parse_axi_cmd(axi_mm_cmd_rd, 1'b0, axi_cmd_idx);
            fork
                check_send_cmd_timer(axi_cmd_idx, 1'b0);
            join_none
        end
    end
    else begin
        return;
    end
endfunction : write_axi_mm_cmd_rd

//Parse AXI-write and push into axi_wr_cmd queue
function void bridge_check_scoreboard::write_axi_mm_cmd_wr(axi_mm_transaction axi_mm_cmd_wr);
    bit[63:0] axi_cmd_idx; //Index for axi write command
    if(brdg_cfg.enable_brdg_scoreboard)begin    
        axi_cmd_idx[63:0] = {axi_mm_cmd_wr.axi_usr, axi_mm_cmd_wr.axi_id, get_axi_idx({axi_mm_cmd_wr.axi_usr, axi_mm_cmd_wr.axi_id}, 1'b1, 1'b0)}; //TODO check assign_actag axi user changed
        axi_wr_cmd[axi_cmd_idx] = axi_mm_cmd_wr;
        if(!brdg_cfg.enable_brdg_ref_model)begin
            return;
        end
        else begin
            parse_axi_cmd(axi_mm_cmd_wr, 1'b1, axi_cmd_idx);
            fork
                check_send_cmd_timer(axi_cmd_idx, 1'b0);
            join_none
        end
    end
    else begin
        return;
    end
endfunction : write_axi_mm_cmd_wr

//Parse tlx-afu responses and assign to related afu-tlx commands
function void bridge_check_scoreboard::write_afu_tlx(afu_tlx_transaction afu_tlx_tran);
    tlx_resp_packet tlx_resp_packet_item;
    if(brdg_cfg.enable_brdg_scoreboard)begin    
        if(!brdg_cfg.enable_brdg_ref_model)begin
            //Check if afutag is in flight
            if(afutag_in_flight(afu_tlx_tran.afu_tlx_afutag))begin
                `uvm_error(tID, $sformatf("The afutag of %h is still in flight .", afu_tlx_tran.afu_tlx_afutag))
            end
            //Detect a bridge write command
            if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_BE || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_BE_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_PR_W || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_PR_W)begin
                //Clone an afu_tlx_tran to flight_afu_tlx_wr queue
                $cast(flight_afu_tlx_wr[afu_tlx_tran.afu_tlx_afutag], afu_tlx_tran.clone());
                `uvm_info(tID, $sformatf("The current afutag for write:"), UVM_MEDIUM)                    
                foreach(flight_afu_tlx_wr[k])begin
                    `uvm_info(tID, $sformatf("afutag=0x%4h", k), UVM_MEDIUM)                    
                end
                //Create a write response packet
                tlx_resp_packet_item=new("tlx_resp_packet_item");
                tlx_write_resp[afu_tlx_tran.afu_tlx_afutag]=tlx_resp_packet_item;
            end
            else if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::RD_WNITC_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC_N)begin
                //Clone an afu_tlx_tran to flight_afu_tlx_rd queue
                $cast(flight_afu_tlx_rd[afu_tlx_tran.afu_tlx_afutag], afu_tlx_tran.clone());                    
                `uvm_info(tID, $sformatf("The current afutag for read:"), UVM_MEDIUM)                    
                foreach(flight_afu_tlx_rd[k])begin
                    `uvm_info(tID, $sformatf("afutag=0x%4h", k), UVM_MEDIUM)                    
                end
                //Create a read response packet
                tlx_resp_packet_item=new("tlx_resp_packet_item");
                tlx_read_resp[afu_tlx_tran.afu_tlx_afutag]=tlx_resp_packet_item;
            end
            else if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::INTRP_REQ)begin
                if(brdg_intrp.intrp_status == 1)begin
                    brdg_intrp.intrp_status=2;
                    if(!(flight_afu_tlx_intrp.size == 0 && brdg_intrp.intrp_trans.intrp_src==afu_tlx_tran.afu_tlx_addr
                        && {3'b0,brdg_intrp.intrp_trans.intrp_ctx}==afu_tlx_tran.afu_tlx_actag))begin
                        `uvm_error(get_type_name(), $sformatf("Get a command of INTRP_REQ from afu_tlx not match the interrupt information!\nThe transactions are followed:\n%s\n%s", afu_tlx_tran.sprint(), brdg_intrp.intrp_trans.sprint()))
                    end
                    else if(brdg_intrp.intrp_cmd_pending == 1)begin
                        `uvm_error(get_type_name(), $sformatf("Get an unexpected INTRP_REQ from afu_tlx, when interrupt pending!\nThe transaction is followed:\n%s", afu_tlx_tran.sprint()))
                    end
                    else begin
                        //Clone an afu_tlx_tran to flight_afu_tlx_rd queue
                        $cast(flight_afu_tlx_intrp[afu_tlx_tran.afu_tlx_afutag], afu_tlx_tran.clone());                    
                        `uvm_info(tID, $sformatf("The current afutag for interrupt:"), UVM_MEDIUM)
                        //brdg_intrp.intrp_afu_tlx=afu_tlx_tran;
                    end
                end
                else begin
                    `uvm_error(get_type_name(), $sformatf("Illegal interrupt status of 0x%1h, when get an interrpt of \n%s!", brdg_intrp.intrp_status, afu_tlx_tran.sprint()))
                end
            end
            else begin
                if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::ASSIGN_ACTAG
                || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::MEM_RD_FAIL
                || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::MEM_WR_RESPONSE || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::MEM_WR_FAIL)begin
                    return;
                end
                else begin
                    `uvm_error(tID, $sformatf("Get an unexpected type of afu-tlx command.\n%s", afu_tlx_tran.sprint()))                    
                end
            end
        end
        else begin
            //Detect a bridge write command
            if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_BE || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W_BE_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_PR_W || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_PR_W)begin
                //Check if afutag is in flight
                if(afutag_in_flight(afu_tlx_tran.afu_tlx_afutag))begin
                    `uvm_error(tID, $sformatf("The afutag of %h found in an afu-tlx read is in flight .", afu_tlx_tran.afu_tlx_afutag))
                end
                else begin
                    //Check if have expected bridge command and update afutag in flight, brdg_resp_pending
                    if(check_expected_brdg_cmd(1'b1, afu_tlx_tran))begin
                        //Create a write response packet
                        tlx_resp_packet_item=new("tlx_resp_packet_item");
                        tlx_write_resp[afu_tlx_tran.afu_tlx_afutag]=tlx_resp_packet_item;
                    end
                    else begin
                       `uvm_error(tID, $sformatf("Get an unexpected command from afu_tlx.\n%s", afu_tlx_tran.sprint()))
                    end
                end
            end
            else if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::RD_WNITC_N
            || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC_N)begin
                //Check if afutag is in flight
                if(afutag_in_flight(afu_tlx_tran.afu_tlx_afutag))begin
                    `uvm_error(tID, $sformatf("The afutag of %h found in an afu-tlx write is in flight.", afu_tlx_tran.afu_tlx_afutag))
                end
                else begin
                    //Check if have expected bridge command and update afutag in flight, brdg_resp_pending
                    if(check_expected_brdg_cmd(1'b0, afu_tlx_tran))begin
                        //Create a read response packet
                        tlx_resp_packet_item=new("tlx_resp_packet_item");
                        tlx_read_resp[afu_tlx_tran.afu_tlx_afutag]=tlx_resp_packet_item;
                    end
                    else begin
                       `uvm_error(tID, $sformatf("Get an unexpected command from afu_tlx.\n%s", afu_tlx_tran.sprint()))
                    end
                end
            end
        end
    end
    else begin
        return;
    end
endfunction : write_afu_tlx

function void bridge_check_scoreboard::write_tlx_afu(tlx_afu_transaction tlx_afu_tran);
    if(brdg_cfg.enable_brdg_scoreboard)begin    
        //Detect tlx afu read response
        if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE || tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_FAILED)begin
            if(!brdg_cfg.enable_brdg_ref_model)begin
                //Check if have afu tlx matched afutag
                if(flight_afu_tlx_rd.exists(tlx_afu_tran.tlx_afu_afutag))begin
                    if(!tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap.exists(tlx_afu_tran.tlx_afu_dp))begin
                        tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                        tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap_num++;
                        check_tlx_resp(1'b0, tlx_afu_tran.tlx_afu_afutag, tlx_afu_tran);
                    end
                    else begin
                        `uvm_error(tID, $sformatf("Get a duplicate tlx afu response:\n%s", tlx_afu_tran.sprint()))
                    end
                end
                else begin
                    `uvm_error(tID, $sformatf("The afutag of %h not match any command from afu.", tlx_afu_tran.tlx_afu_afutag))                    
                end
            end
            else begin
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_FAILED)begin
                    //TODO: process of READ_FAILED
                    `uvm_error(tID, $sformatf("Get an unsupport response packet:\n%s", tlx_afu_tran.sprint()))
                end
                else begin
                    //Check if have afu tlx matched afutag
                    if(flight_afu_tlx_rd.exists(tlx_afu_tran.tlx_afu_afutag))begin
                        if(!tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap.exists(tlx_afu_tran.tlx_afu_dp))begin
                            tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                            tlx_read_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap_num++;
                            check_tlx_resp(1'b0, tlx_afu_tran.tlx_afu_afutag, tlx_afu_tran);
                        end
                        else begin
                            `uvm_error(tID, $sformatf("Get a duplicate tlx afu response:\n%s", tlx_afu_tran.sprint()))
                        end
                    end
                    else begin
                        `uvm_error(tID, $sformatf("The afutag of %h not match any command from afu.", tlx_afu_tran.tlx_afu_afutag))                    
                    end
                end
            end
        end
        //Detect tlx afu write response    
        else if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE || tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_FAILED)begin
            if(!brdg_cfg.enable_brdg_ref_model)begin
                //Check if have afu tlx matched afutag
                if(flight_afu_tlx_wr.exists(tlx_afu_tran.tlx_afu_afutag))begin
                    if(!tlx_write_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap.exists(tlx_afu_tran.tlx_afu_dp))begin
                        tlx_write_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                        tlx_write_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap_num++;
                        check_tlx_resp(1'b1, tlx_afu_tran.tlx_afu_afutag, tlx_afu_tran);
                    end
                    else begin
                        `uvm_error(tID, $sformatf("Get a duplicate tlx afu response:\n%s", tlx_afu_tran.sprint()))
                    end
                end
                else begin
                    `uvm_error(tID, $sformatf("The afutag of %h not match any command from afu.", tlx_afu_tran.tlx_afu_afutag))                    
                end
            end
            else begin
                //Check if have afu tlx matched afutag
                //TODO: process of WRITE_FAILED
                if(flight_afu_tlx_wr.exists(tlx_afu_tran.tlx_afu_afutag))begin
                    if(!tlx_write_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap.exists(tlx_afu_tran.tlx_afu_dp))begin
                        tlx_write_resp[tlx_afu_tran.tlx_afu_afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                        check_tlx_resp(1'b1, tlx_afu_tran.tlx_afu_afutag, tlx_afu_tran);
                    end
                    else begin
                        `uvm_error(tID, $sformatf("Get a duplicate tlx afu response:\n%s", tlx_afu_tran.sprint()))
                    end
                end
                else begin
                    `uvm_error(tID, $sformatf("The afutag of %h not match any command from afu.", tlx_afu_tran.tlx_afu_afutag))                    
                end
            end
        end
        //Detect tlx afu interrupt response    
        else if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::INTRP_RESP || tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::INTRP_RDY)begin
            //Check afutag
            if(!flight_afu_tlx_intrp.exists(tlx_afu_tran.tlx_afu_afutag))begin
                `uvm_error(tID, $sformatf("The afutag of %h not match the interrupt from afu.", tlx_afu_tran.tlx_afu_afutag))                    
            end
            if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::INTRP_RESP)begin
                //Check intrp_resp
                if(!(!brdg_intrp.intrp_cmd_pending && brdg_intrp.intrp_status==2))begin
                    `uvm_error(tID, $sformatf("Get an expected intrp_resp from tlx in interrupt status %1h.\n%s", brdg_intrp.intrp_status, tlx_afu_tran.sprint()))
                end
                if(tlx_afu_tran.tlx_afu_resp_code == 0)begin
                    brdg_intrp.intrp_status=3;
                    flight_afu_tlx_intrp.delete(tlx_afu_tran.tlx_afu_afutag);
                end
                else if(tlx_afu_tran.tlx_afu_resp_code == 4'h2)begin
                    brdg_intrp.intrp_status=1;
                    flight_afu_tlx_intrp.delete(tlx_afu_tran.tlx_afu_afutag);
                end
                else if(tlx_afu_tran.tlx_afu_resp_code == 4'h4)begin
                    brdg_intrp.intrp_cmd_pending=1;
                end
                else begin
                    `uvm_error(tID, $sformatf("Get an illegal resp_code of intrp_resp from tlx.\n%s", tlx_afu_tran.sprint()))                    
                end
            end
            else begin
                //Check intrp_rdy
                if(!(brdg_intrp.intrp_cmd_pending && brdg_intrp.intrp_status==2))begin
                    `uvm_error(tID, $sformatf("Get an expected intrp_rdy from tlx.\n%s", tlx_afu_tran.sprint()))                    
                end
                if(tlx_afu_tran.tlx_afu_resp_code == 0)begin
                    brdg_intrp.intrp_cmd_pending=0;
                    brdg_intrp.intrp_status=1;
                    flight_afu_tlx_intrp.delete(tlx_afu_tran.tlx_afu_afutag);
                end
                else if(tlx_afu_tran.tlx_afu_resp_code == 4'h2)begin
                    brdg_intrp.intrp_cmd_pending=0;
                    brdg_intrp.intrp_status=1;
                    flight_afu_tlx_intrp.delete(tlx_afu_tran.tlx_afu_afutag);
                end
                //else if(tlx_afu_tran.tlx_afu_resp_code == 4'he)begin
                //end
                else begin
                    `uvm_error(tID, $sformatf("Get an illegal resp_code of intrp_rdy from tlx.\n%s", tlx_afu_tran.sprint()))                    
                end
            end
        end
    end
    else begin
        return;
    end
endfunction : write_tlx_afu

function void bridge_check_scoreboard::write_intrp(intrp_transaction intrp_tran);
    if((brdg_intrp.intrp_status == 0) && (intrp_tran.intrp_item == intrp_transaction::INTRP_REQ))begin
        brdg_intrp.intrp_status=1;
        brdg_intrp.intrp_trans=intrp_tran;
    end
    else if((brdg_intrp.intrp_status == 3) && (intrp_tran.intrp_item == intrp_transaction::INTRP_ACK))begin
        brdg_intrp.intrp_status=0.;
        intrp_num++;
    end
    else begin
        `uvm_error(get_type_name(), $sformatf("Illegal interrupt status of 0x%1h, when get an interrpt of \n%s!", brdg_intrp.intrp_status, intrp_tran.sprint()))
    end
endfunction : write_intrp
    
task bridge_check_scoreboard::check_txn();
endtask : check_txn

function void bridge_check_scoreboard::result_check();
    if(brdg_cfg.total_intrp_num == intrp_num && brdg_cfg.total_read_num == read_num && brdg_cfg.total_write_num == write_num)begin
        `uvm_info(tID, $sformatf("Compared total number of transaction successfully! READ_NUM: %d, WRITE_NUM: %d, INTRP_NUM: %d.", read_num, write_num, intrp_num), UVM_LOW);
    end
    else begin
        `uvm_error(tID, $sformatf("Compared total number of transaction failed! EXPECT_READ_NUM: %d, ACTUAL_READ_NUM: %d; EXPECT_WRITE_NUM: %d, ACTUAL_WRITE_NUM: %d; EXPECT_INTRP_NUM: %d, ACTUAL_INTRP_NUM: %d.", brdg_cfg.total_read_num, read_num, brdg_cfg.total_write_num, write_num, brdg_cfg.total_intrp_num, intrp_num))        
    end
endfunction : result_check

//Parse tlx dl to number of 64byte
function int bridge_check_scoreboard::dl2dl_num(bit[1:0] dl);
    case(dl)
        2'b01: dl2dl_num = 1;
        2'b10: dl2dl_num = 2;
        2'b11: dl2dl_num = 4;
        default: `uvm_error(get_type_name(), "Get an illegal data length!")
    endcase
endfunction : dl2dl_num

//TODO
//Parse AXI read/write and push into axi_rd_cmd/axi_wr_cmd queue
function void bridge_check_scoreboard::parse_axi_cmd(axi_mm_transaction axi_trans, bit nrw, bit[63:0] axi_cmd_idx);
    brdg_packet brdg_packet_item;
    afu_tlx_transaction afu_tlx_item;
    brdg_packet_item=new("brdg_packet_item");
    //AXI address align with 256byte && bridge commands support 256byte
    if(axi_trans.addr%256 == 0 && brdg_cfg.cmd_rd_256_enable == 1)begin
        //Narrow size process
        if(axi_trans.byte_size < 128)begin
            //TODO
            `uvm_error(tID, $sformatf("TODO: To support narrow size when bridge commands support 256byte."))        
        end
        //Non-narrow size process
        else begin
            for(int i=0; i<axi_trans.burst_length/2; i++)begin
                afu_tlx_item=new("afu_tlx_item");
                afu_tlx_item.afu_tlx_addr=axi_trans.addr+256*i;
                afu_tlx_item.afu_tlx_dl=3;
                //For an AXI read 
                if(nrw == 0)begin
                    afu_tlx_item.afu_tlx_opcode=8'h10;
                    afu_tlx_item.afu_tlx_type=afu_tlx_transaction::RD_WNITC;
                    brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                end
                //For an AXI write
                else begin
                    afu_tlx_item.afu_tlx_opcode=8'h20;
                    afu_tlx_item.afu_tlx_type=afu_tlx_transaction::DMA_W;
                    brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                end
            end
            //The last 128byte bridge command 
            if(axi_trans.burst_length/2 > 0)begin
                afu_tlx_item=new("afu_tlx_item");
                afu_tlx_item.afu_tlx_addr=axi_trans.addr+256*(axi_trans.burst_length/2);
                afu_tlx_item.afu_tlx_dl=2;
                //For an AXI read 
                if(nrw == 0)begin
                    afu_tlx_item.afu_tlx_opcode=8'h10;
                    afu_tlx_item.afu_tlx_type=afu_tlx_transaction::RD_WNITC;
                    brdg_packet_item.expect_brdg_cmd[axi_trans.burst_length/2+1]=afu_tlx_item;
                end
                //For an AXI write
                else begin
                    afu_tlx_item.afu_tlx_opcode=8'h20;
                    afu_tlx_item.afu_tlx_type=afu_tlx_transaction::DMA_W;
                    brdg_packet_item.expect_brdg_cmd[axi_trans.burst_length/2+1]=afu_tlx_item;
                end
            end
            brdg_packet_item.brdg_cmd_num=axi_trans.burst_length/2+axi_trans.burst_length%2;
        end
    end
    //AXI address not align with 256byte && bridge commands support 256byte
    else if(brdg_cfg.cmd_rd_256_enable == 1)begin
        //TODO
        `uvm_error(tID, $sformatf("TODO: To support AXI address align to 256byte when bridge cmd_rd_256_enable."))        
    end
    //Bridge commands not support 256byte
    else begin
        //AXI address not align with the size of each transfor && the size of each transfor is less than 64byte
        if(axi_trans.addr%axi_trans.byte_size != 0 || axi_trans.byte_size < 64)begin
            `uvm_error(tID, $sformatf("TODO: To support the AXI start address not-aligned to AXI size or AXI size less than 64byte in the future."))      
        end
        //Expexted bridge transfers may not involve partial commmands
        else begin
            //AXI size is 128byte
            if(axi_trans.byte_size == 128)begin
                for(int i=0; i<axi_trans.burst_length; i++)begin
                    afu_tlx_item=new("afu_tlx_item");
                    afu_tlx_item.afu_tlx_addr=axi_trans.addr+128*i;
                    afu_tlx_item.afu_tlx_dl=2;
                    //For an AXI read 
                    if(nrw == 0)begin
                        afu_tlx_item.afu_tlx_opcode=8'h10;
                        afu_tlx_item.afu_tlx_type=afu_tlx_transaction::RD_WNITC;
                        brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                    end
                    //For an AXI write
                    else begin
                        afu_tlx_item.afu_tlx_opcode=8'h20;
                        afu_tlx_item.afu_tlx_type=afu_tlx_transaction::DMA_W;
                        brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                    end
                end
            end
            //AXI size is 64byte
            else begin
                for(int i=0; i<axi_trans.burst_length; i++)begin
                    afu_tlx_item=new("afu_tlx_item");
                    afu_tlx_item.afu_tlx_addr=axi_trans.addr+64*i;
                    afu_tlx_item.afu_tlx_dl=1;
                    //For an AXI read 
                    if(nrw == 0)begin
                        afu_tlx_item.afu_tlx_opcode=8'h10;
                        afu_tlx_item.afu_tlx_type=afu_tlx_transaction::RD_WNITC;
                        brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                    end
                    //For an AXI write
                    else begin
                        afu_tlx_item.afu_tlx_opcode=8'h20;
                        afu_tlx_item.afu_tlx_type=afu_tlx_transaction::DMA_W;
                        brdg_packet_item.expect_brdg_cmd[i]=afu_tlx_item;
                    end
                end
            end
            brdg_packet_item.brdg_cmd_num=axi_trans.burst_length;
        end
    end
    //Push the expexted commands into 
    if(nrw == 0)begin
        brdg_packet_read[axi_cmd_idx]=brdg_packet_item;
    end
    else begin
        brdg_packet_write[axi_cmd_idx]=brdg_packet_item;
    end
endfunction : parse_axi_cmd

function bit[47:0] bridge_check_scoreboard::get_axi_idx(bit[15:0]usr_id, bit nrw, bit finish);
    if(finish == 0)begin
        if(nrw == 1'b0)begin
            if(!axi_rd_idx.exists(usr_id))
                axi_rd_idx[usr_id] = 0;
            if(axi_rd_idx[usr_id] == 48'hffffffffffff)begin
                `uvm_error(tID, $sformatf("The number of AXI read beats has overflow!"))
            end
            else begin
                axi_rd_idx[usr_id] = axi_rd_idx[usr_id] + 1;
                get_axi_idx = axi_rd_idx[usr_id];
            end
        end
        else begin
            if(!axi_wr_idx.exists(usr_id))
                axi_wr_idx[usr_id] = 0;
            if(axi_wr_idx[usr_id] == 48'hffffffffffff)begin
                `uvm_error(tID, $sformatf("The number of AXI write beats has overflow!"))
            end
            else begin
                axi_wr_idx[usr_id] = axi_wr_idx[usr_id] + 1;
                get_axi_idx = axi_wr_idx[usr_id];
            end
        end
    end
    else begin
        if(nrw == 1'b0)begin
            if(!axi_rd_finish_idx.exists(usr_id))
                axi_rd_finish_idx[usr_id] = 0;
            if(axi_rd_finish_idx[usr_id] == 48'hffffffffffff)begin
                `uvm_error(tID, $sformatf("The number of AXI read finish beats has overflow!"))
            end
            else begin
                axi_rd_finish_idx[usr_id] = axi_rd_finish_idx[usr_id] + 1;
                get_axi_idx = axi_rd_finish_idx[usr_id];
            end
        end
        else begin
            if(!axi_wr_finish_idx.exists(usr_id))
                axi_wr_finish_idx[usr_id] = 0;
            if(axi_wr_finish_idx[usr_id] == 48'hffffffffffff)begin
                `uvm_error(tID, $sformatf("The number of AXI write finish beats has overflow!"))
            end
            else begin
                axi_wr_finish_idx[usr_id] = axi_wr_finish_idx[usr_id] + 1;
                get_axi_idx = axi_wr_finish_idx[usr_id];
            end
        end
    end
endfunction : get_axi_idx

function void bridge_check_scoreboard::check_send_cmd_timer(bit[63:0] axi_cmd_idx, bit nrw);

endfunction : check_send_cmd_timer

function bit bridge_check_scoreboard::afutag_in_flight(bit[15:0] afutag);
    if(flight_afu_tlx_rd.exists(afutag) || flight_afu_tlx_wr.exists(afutag))
        afutag_in_flight=1;
    else
        afutag_in_flight=0;
endfunction : afutag_in_flight

function bit bridge_check_scoreboard::check_expected_brdg_cmd(bit nrw, afu_tlx_transaction afu_tlx_tran);
    check_expected_brdg_cmd = 0;
    //Check if exists an expected bridge read
    if(nrw == 0)begin: search_cmd_rd
        foreach(brdg_packet_read[i])begin
            //TODO: Only compare dl or pl for the specified command
            for(int j=0; j<brdg_packet_read[i].brdg_cmd_num; j++)begin
                if(!brdg_packet_read[i].tlx_resp_success && !brdg_packet_read[i].axi_resp_success
                && !brdg_packet_read[i].brdg_resp_success.exists(j)
                && !brdg_packet_read[i].brdg_cmd_pending.exists(j)
                && !brdg_packet_read[i].brdg_resp_pending.exists(j)
                && brdg_packet_read[i].expect_brdg_cmd[j].afu_tlx_opcode == afu_tlx_tran.afu_tlx_opcode 
                && brdg_packet_read[i].expect_brdg_cmd[j].afu_tlx_addr == afu_tlx_tran.afu_tlx_addr
                && brdg_packet_read[i].expect_brdg_cmd[j].afu_tlx_dl == afu_tlx_tran.afu_tlx_dl
                && brdg_packet_read[i].expect_brdg_cmd[j].afu_tlx_pl == afu_tlx_tran.afu_tlx_pl)begin
                    brdg_packet_read[i].brdg_resp_pending[j]=1;
                    //flight_afu_tlx_rd[afu_tlx_tran.afu_tlx_afutag]=afu_tlx_tran;
                    $cast(flight_afu_tlx_rd[afu_tlx_tran.afu_tlx_afutag], afu_tlx_tran.clone());                    
                    `uvm_info(tID, $sformatf("The current afutag for read:"), UVM_MEDIUM)                    
                    foreach(flight_afu_tlx_rd[k])begin
                        `uvm_info(tID, $sformatf("afutag=0x%4h", k), UVM_MEDIUM)                    
                    end
                    brdg_packet_read[i].brdg_cmd_afutag[j]=afu_tlx_tran.afu_tlx_afutag;
                    check_expected_brdg_cmd = 1;
                    `uvm_info(tID, $sformatf("Compare an expected bridge read successfully and the comprised-id=%h, the afu_tlx-num=%h", i, j), UVM_MEDIUM)
                    disable search_cmd_rd;
                end
            end
        end
    end
    //Check if exists an expected bridge write
    else begin: search_cmd_wr
        foreach(brdg_packet_write[i])begin
            //TODO: Only compare dl or pl for the specified command
            for(int j=0; j<brdg_packet_write[i].brdg_cmd_num; j++)begin
                if(!brdg_packet_write[i].tlx_resp_success && !brdg_packet_write[i].axi_resp_success
                && !brdg_packet_write[i].brdg_resp_success.exists(j)
                && !brdg_packet_write[i].brdg_cmd_pending.exists(j)
                && !brdg_packet_write[i].brdg_resp_pending.exists(j)
                && brdg_packet_write[i].expect_brdg_cmd[j].afu_tlx_opcode == afu_tlx_tran.afu_tlx_opcode 
                && brdg_packet_write[i].expect_brdg_cmd[j].afu_tlx_addr == afu_tlx_tran.afu_tlx_addr
                && brdg_packet_write[i].expect_brdg_cmd[j].afu_tlx_dl == afu_tlx_tran.afu_tlx_dl
                && brdg_packet_write[i].expect_brdg_cmd[j].afu_tlx_pl == afu_tlx_tran.afu_tlx_pl)begin
                    brdg_packet_write[i].brdg_resp_pending[j]=1;
                    //flight_afu_tlx_wr[afu_tlx_tran.afu_tlx_afutag]=afu_tlx_tran;
                    $cast(flight_afu_tlx_wr[afu_tlx_tran.afu_tlx_afutag], afu_tlx_tran.clone());
                    `uvm_info(tID, $sformatf("The current afutag for write:"), UVM_MEDIUM)                    
                    foreach(flight_afu_tlx_wr[k])begin
                        `uvm_info(tID, $sformatf("afutag=0x%4h", k), UVM_MEDIUM)                    
                    end
                    brdg_packet_write[i].brdg_cmd_afutag[j]=afu_tlx_tran.afu_tlx_afutag;
                    check_expected_brdg_cmd = 1;
                    `uvm_info(tID, $sformatf("Compare an expected bridge write successfully and the comprised-id=%h, the afu_tlx-num=%h", i, j), UVM_MEDIUM)
                    disable search_cmd_wr;
                end
            end
        end
    end
endfunction : check_expected_brdg_cmd

function void bridge_check_scoreboard::check_tlx_resp(bit nrw, bit[15:0]afutag, tlx_afu_transaction tlx_afu_tran);
    bit[63:0] addr_mask;
    //Detect a read response
    if(nrw == 0)begin
        if(flight_afu_tlx_rd[afutag].afu_tlx_type == afu_tlx_transaction::RD_WNITC || flight_afu_tlx_rd[afutag].afu_tlx_type == afu_tlx_transaction::RD_WNITC_N)begin
            //Read response without split
            if(flight_afu_tlx_rd[afutag].afu_tlx_dl == tlx_afu_tran.tlx_afu_dl)begin
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE)begin
                    for(int i=0; i<dl2dl_num(tlx_afu_tran.tlx_afu_dl); i++)begin
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[i] = tlx_afu_tran.tlx_afu_data_bus[i];
                        if(!brdg_cfg.enable_brdg_ref_model)begin
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr+64*i, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[i], 1'b0);
                        end
                    end
                end
                tlx_read_resp.delete(afutag);
                if(!brdg_cfg.enable_brdg_ref_model)begin
                    flight_afu_tlx_rd.delete(afutag);                    
                end
                else begin
                    set_brdg_resp_success(1'b0, afutag);
                end
            end
            //256byte read command with 2 read response without split
            else if(flight_afu_tlx_rd[afutag].afu_tlx_dl == 3 && tlx_afu_tran.tlx_afu_dl == 2)begin
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE)begin                
                    if(tlx_afu_tran.tlx_afu_dp == 0)begin
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0] = tlx_afu_tran.tlx_afu_data_bus[0];
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[1] = tlx_afu_tran.tlx_afu_data_bus[1];
                        if(!brdg_cfg.enable_brdg_ref_model)begin
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0], 1'b0);
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr+64, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[1], 1'b0);                        
                        end
                    end               
                    else if(tlx_afu_tran.tlx_afu_dp == 2)begin
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[2] = tlx_afu_tran.tlx_afu_data_bus[0];
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[3] = tlx_afu_tran.tlx_afu_data_bus[1];
                        if(!brdg_cfg.enable_brdg_ref_model)begin
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr+128, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[2], 1'b0);
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr+192, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[3], 1'b0);                        
                        end
                    end
                    else begin
                        `uvm_error(tID, $sformatf("Unsurpport dp=%h in tlx afu response.", tlx_afu_tran.tlx_afu_dp))
                    end
                end
                tlx_read_resp[afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                //tlx_read_resp[afutag].tlx_afu_reap_num++;
                if(tlx_read_resp[afutag].tlx_afu_reap_num == 2)begin
                    tlx_read_resp.delete(afutag);
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        flight_afu_tlx_rd.delete(afutag);                    
                    end
                    else begin
                        set_brdg_resp_success(1'b0, afutag);
                    end
                end
            end
            //128byte read command with 2 read response without split
            else if(flight_afu_tlx_rd[afutag].afu_tlx_dl == 2 && tlx_afu_tran.tlx_afu_dl == 1)begin
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE)begin                                
                    if(tlx_afu_tran.tlx_afu_dp == 0)begin
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0] = tlx_afu_tran.tlx_afu_data_bus[0];
                        if(!brdg_cfg.enable_brdg_ref_model)begin
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0], 1'b0);
                        end
                    end               
                    else if(tlx_afu_tran.tlx_afu_dp == 1)begin
                        flight_afu_tlx_rd[afutag].afu_tlx_data_bus[1] = tlx_afu_tran.tlx_afu_data_bus[0];
                        if(!brdg_cfg.enable_brdg_ref_model)begin
                            write_brdg_memory(flight_afu_tlx_rd[afutag].afu_tlx_addr+64, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[1], 1'b0);                        
                        end
                    end
                    else begin
                        `uvm_error(tID, $sformatf("Unsurpport dp=%h in tlx afu response.", tlx_afu_tran.tlx_afu_dp))
                    end
                end
                tlx_read_resp[afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                //tlx_read_resp[afutag].tlx_afu_reap_num++;
                if(tlx_read_resp[afutag].tlx_afu_reap_num == 2)begin
                    tlx_read_resp.delete(afutag);
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        flight_afu_tlx_rd.delete(afutag);                    
                    end
                    else begin
                        set_brdg_resp_success(1'b0, afutag);
                    end
                end
            end
            else begin
                `uvm_error(tID, $sformatf("Unsurpport split read response:\n%s", tlx_afu_tran.sprint()))
            end
        end
        else if(flight_afu_tlx_rd[afutag].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC || flight_afu_tlx_rd[afutag].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC_N)begin
            if(tlx_afu_tran.tlx_afu_dl == 1 && tlx_afu_tran.tlx_afu_dp == 0)begin
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE)begin                                                
                    flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0] = tlx_afu_tran.tlx_afu_data_bus[0];
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        addr_mask=gen_pr_mask(flight_afu_tlx_rd[afutag].afu_tlx_addr, flight_afu_tlx_rd[afutag].afu_tlx_pl);
                        write_brdg_memory({flight_afu_tlx_rd[afutag].afu_tlx_addr[63:6], 6'h0}, addr_mask, flight_afu_tlx_rd[afutag].afu_tlx_data_bus[0], 1'b0);                        
                    end
                end
                if(!brdg_cfg.enable_brdg_ref_model)begin
                    flight_afu_tlx_rd.delete(afutag);                    
                end
                else begin
                    set_brdg_resp_success(1'b0, afutag);
                end
            end
            else begin
                `uvm_error(tID, $sformatf("Unsurpport read response from tlx.\n%s", tlx_afu_tran.sprint()))
            end
        end
        else begin
            `uvm_error(tID, $sformatf("Unsurpport read command from afu."))
        end
    end
    //Detect a write response
    else begin
        if(flight_afu_tlx_wr[afutag].afu_tlx_type == afu_tlx_transaction::DMA_W || flight_afu_tlx_wr[afutag].afu_tlx_type == afu_tlx_transaction::DMA_W_N)begin
            //Write response without split
            if(flight_afu_tlx_wr[afutag].afu_tlx_dl == tlx_afu_tran.tlx_afu_dl)begin
                tlx_write_resp.delete(afutag);
                if(!brdg_cfg.enable_brdg_ref_model)begin
                    if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE)begin
                        for(int i=0; i<dl2dl_num(tlx_afu_tran.tlx_afu_dl); i++)begin
                            write_brdg_memory(flight_afu_tlx_wr[afutag].afu_tlx_addr+64*i, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_wr[afutag].afu_tlx_data_bus[i], 1'b1);
                        end
                    end
                    flight_afu_tlx_wr.delete(afutag);                    
                end
                else begin
                    set_brdg_resp_success(1'b1, afutag);
                end
            end
            //256byte write command with 2 write response without split
            else if(flight_afu_tlx_wr[afutag].afu_tlx_dl == 3 && tlx_afu_tran.tlx_afu_dl == 2)begin
                if(tlx_afu_tran.tlx_afu_dp != 0 && tlx_afu_tran.tlx_afu_dp != 2)begin
                    `uvm_error(tID, $sformatf("Unsurpport dp=%h in tlx afu response.", tlx_afu_tran.tlx_afu_dp))
                end
                tlx_write_resp[afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                //tlx_write_resp[afutag].tlx_afu_reap_num++;
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE)begin                
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        write_brdg_memory(flight_afu_tlx_wr[afutag].afu_tlx_addr+64*tlx_afu_tran.tlx_afu_dp, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_wr[afutag].afu_tlx_data_bus[tlx_afu_tran.tlx_afu_dp], 1'b1);
                        write_brdg_memory(flight_afu_tlx_wr[afutag].afu_tlx_addr+64*(tlx_afu_tran.tlx_afu_dp+1), 64'hffff_ffff_ffff_ffff, flight_afu_tlx_wr[afutag].afu_tlx_data_bus[tlx_afu_tran.tlx_afu_dp+1], 1'b1);
                    end
                end
                if(tlx_write_resp[afutag].tlx_afu_reap_num == 2)begin
                    tlx_write_resp.delete(afutag);
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        flight_afu_tlx_wr.delete(afutag);                    
                    end
                    else begin
                        set_brdg_resp_success(1'b1, afutag);
                    end
                end
            end
            //128byte write command with 2 write response without split
            else if(flight_afu_tlx_wr[afutag].afu_tlx_dl == 2 && tlx_afu_tran.tlx_afu_dl == 1)begin
                if(tlx_afu_tran.tlx_afu_dp != 0 && tlx_afu_tran.tlx_afu_dp != 1)begin
                    `uvm_error(tID, $sformatf("Unsurpport dp=%h in tlx afu response.", tlx_afu_tran.tlx_afu_dp))
                end
                tlx_write_resp[afutag].tlx_afu_reap[tlx_afu_tran.tlx_afu_dp]=tlx_afu_tran;
                //tlx_write_resp[afutag].tlx_afu_reap_num++;
                if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE)begin                                
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        write_brdg_memory(flight_afu_tlx_wr[afutag].afu_tlx_addr+64*tlx_afu_tran.tlx_afu_dp, 64'hffff_ffff_ffff_ffff, flight_afu_tlx_wr[afutag].afu_tlx_data_bus[tlx_afu_tran.tlx_afu_dp], 1'b1);
                    end
                end
                if(tlx_write_resp[afutag].tlx_afu_reap_num == 2)begin
                    tlx_write_resp.delete(afutag);
                    if(!brdg_cfg.enable_brdg_ref_model)begin
                        flight_afu_tlx_wr.delete(afutag);                    
                    end
                    else begin
                        set_brdg_resp_success(1'b1, afutag);
                    end
                end
            end
            else begin
                `uvm_error(tID, $sformatf("Unsurpport split write response:\n%s", tlx_afu_tran.sprint()))
            end
        end
        else if(flight_afu_tlx_wr[afutag].afu_tlx_type == afu_tlx_transaction::DMA_PR_W || flight_afu_tlx_wr[afutag].afu_tlx_type == afu_tlx_transaction::DMA_W_BE)begin
            if(tlx_afu_tran.tlx_afu_dl == 1 && tlx_afu_tran.tlx_afu_dp == 0)begin
                //flight_afu_tlx_wr[afutag].afu_tlx_data_bus[0] = tlx_afu_tran.tlx_afu_data_bus[0];
                if(!brdg_cfg.enable_brdg_ref_model)begin
                    if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE)begin                                                    
                        if(flight_afu_tlx_wr[afutag].afu_tlx_type == afu_tlx_transaction::DMA_W_BE)begin
                            addr_mask=flight_afu_tlx_wr[afutag].afu_tlx_be;
                        end
                        else begin
                            addr_mask=gen_pr_mask(flight_afu_tlx_wr[afutag].afu_tlx_addr, flight_afu_tlx_wr[afutag].afu_tlx_pl);
                        end
                        write_brdg_memory({flight_afu_tlx_wr[afutag].afu_tlx_addr[63:6], 6'h0}, addr_mask, flight_afu_tlx_wr[afutag].afu_tlx_data_bus[0], 1'b1);
                    end
                    flight_afu_tlx_wr.delete(afutag);                    
                end
                else begin
                    set_brdg_resp_success(1'b1, afutag);
                end
            end
            else begin
                `uvm_error(tID, $sformatf("Unsurpport write response from tlx.\n%s", tlx_afu_tran.sprint()))
            end
        end
        else begin
            `uvm_error(tID, $sformatf("Unsurpport write command from afu."))
        end
    end
endfunction : check_tlx_resp

function void bridge_check_scoreboard::set_brdg_resp_success(bit nrw, bit[15:0] afutag);
    //afu_tlx_transaction afu_tlx_item;
    //afu_tlx_item=new("afu_tlx_item");
    if(nrw == 0)begin: search_rd_afutag
        foreach(brdg_packet_read[i])begin
            for(int j=0; j<brdg_packet_read[i].brdg_cmd_num; j++)begin
                if(!brdg_packet_read[i].tlx_resp_success && !brdg_packet_read[i].axi_resp_success
                && brdg_packet_read[i].brdg_resp_pending[j]
                && !brdg_packet_read[i].brdg_cmd_pending[j]
                && !brdg_packet_read[i].brdg_resp_success[j]                
                && brdg_packet_read[i].brdg_cmd_afutag[j] == afutag)begin
                    //brdg_packet_read[i].actual_brdg_cmd[j]=afu_tlx_item;
                    //brdg_packet_read[i].actual_brdg_cmd[j]=flight_afu_tlx_rd[afutag];
                    if(!flight_afu_tlx_rd.exists(afutag))
                        `uvm_error(tID, $sformatf("Get an afutag of 0x%4h that not match any afu-tlx read in flight.", afutag))
                    $cast(brdg_packet_read[i].actual_brdg_cmd[j], flight_afu_tlx_rd[afutag].clone());
                    flight_afu_tlx_rd.delete(afutag);                    
                    brdg_packet_read[i].brdg_resp_pending.delete(j);
                    brdg_packet_read[i].brdg_resp_success[j]=1;
                    //Check if all response are returned
                    if(brdg_packet_read[i].brdg_resp_success.size == brdg_packet_read[i].brdg_cmd_num)begin
                        brdg_packet_read[i].tlx_resp_success=1;
                        `uvm_info(tID, $sformatf("All tlx afu responses returned for an axi read beat, the comprised id=%h", i), UVM_MEDIUM)                        
                    end
                    disable search_rd_afutag;
                end
            end
        end
    end
    else begin: search_wr_afutag
        foreach(brdg_packet_write[i])begin
            for(int j=0; j<brdg_packet_write[i].brdg_cmd_num; j++)begin
                if(!brdg_packet_write[i].tlx_resp_success && !brdg_packet_write[i].axi_resp_success
                && brdg_packet_write[i].brdg_resp_pending[j]
                && !brdg_packet_write[i].brdg_cmd_pending[j]
                && !brdg_packet_write[i].brdg_resp_success[j]
                && brdg_packet_write[i].brdg_cmd_afutag[j] == afutag)begin
                    //brdg_packet_write[i].actual_brdg_cmd[j]=afu_tlx_item;
                    if(!flight_afu_tlx_wr.exists(afutag))
                        `uvm_error(tID, $sformatf("Get an afutag of 0x%4h that not match any afu-tlx write in flight.", afutag))                            
                    $cast(brdg_packet_write[i].actual_brdg_cmd[j], flight_afu_tlx_wr[afutag].clone());
                    //brdg_packet_write[i].actual_brdg_cmd[j]=flight_afu_tlx_wr[afutag];
                    flight_afu_tlx_wr.delete(afutag);
                    brdg_packet_write[i].brdg_resp_pending.delete(j);
                    brdg_packet_write[i].brdg_resp_success[j]=1;
                    //Check if all response are returned
                    if(brdg_packet_write[i].brdg_resp_success.size == brdg_packet_write[i].brdg_cmd_num)begin
                        brdg_packet_write[i].tlx_resp_success=1;
                        `uvm_info(tID, $sformatf("All tlx afu responses returned for an axi write beat, the comprised id=%h", i), UVM_MEDIUM)                        
                    end
                    disable search_wr_afutag;
                end
            end
        end
    end
endfunction : set_brdg_resp_success

function void bridge_check_scoreboard::write_brdg_memory(bit[63:0] brdg_addr, bit[63:0] brdg_addr_mask, bit[511:0] data, bit nrw);
    if(brdg_addr[5:0] != 6'h0)
        `uvm_error(tID, $sformatf("The address of %h is not aligned to 64 bytes.", brdg_addr))
    else begin
        //For a brdg read
        if(!nrw)begin
            for(int i=0; i<64; i++)begin
                if(brdg_addr_mask[i])begin
                    brdg_read_memory[brdg_addr+i]=data[8*i+7-:8];
                end
            end
        end
        //For a brdg write    
        else begin
            for(int i=0; i<64; i++)begin
                if(brdg_addr_mask[i])begin
                    brdg_write_memory[brdg_addr+i]=data[8*i+7-:8];
                end
            end
        end
    end
endfunction : write_brdg_memory

function bit bridge_check_scoreboard::check_brdg_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);
    bit[1023:0] host_mem_1024;
    bit data_mismatch;
    bit data_invalid;
    check_brdg_memory=0;    
    for(int i=0; i<128; i++)begin
        if(axi_addr_mask[i])begin
            if(!nrw)begin
                if(!brdg_read_memory.exists(axi_addr+i))begin
                    data_invalid = 1;
                    `uvm_info(tID, $sformatf("Not read host memory with an address of 0x%16h", axi_addr+i), UVM_LOW)
                end
                else if(data[8*i+7-:8] != brdg_read_memory[axi_addr+i])begin
                    data_mismatch = 1;
                    host_mem_1024[8*i+7-:8] = brdg_read_memory[axi_addr+i];                        
                    `uvm_info(tID, $sformatf("Date mismatch with a read address of 0x%16h", axi_addr+i), UVM_LOW)                    
                end
                else begin
                    host_mem_1024[8*i+7-:8] = brdg_read_memory[axi_addr+i];                        
                end
            end
            else begin
                if(!brdg_write_memory.exists(axi_addr+i))begin
                     data_invalid = 1;
                     `uvm_info(tID, $sformatf("Not write host memory with an address of 0x%16h", axi_addr+i), UVM_LOW)
                end
                else if(data[8*i+7-:8] != brdg_write_memory[axi_addr+i])begin
                    data_mismatch = 1;
                    host_mem_1024[8*i+7-:8] = brdg_read_memory[axi_addr+i];                        
                    `uvm_info(tID, $sformatf("Date mismatch with a write address of 0x%16h", axi_addr+i), UVM_LOW)                    
                end
                else begin
                    host_mem_1024[8*i+7-:8] = brdg_write_memory[axi_addr+i];                        
                end
            end
        end
    end
    //Print host memory data for data miscompare
    if(data_mismatch ==1)begin
        if(!nrw)
            `uvm_info(tID, $sformatf("Detect data mismatch in a read command, host side: 128byte_align_address=0x%16h, compare_byte_mask=0x%32h, data=0x%h", axi_addr, axi_addr_mask, host_mem_1024), UVM_LOW)
        else
            `uvm_info(tID, $sformatf("Detect data mismatch in a write command, host side: 128byte_align_address=0x%16h, compare_byte_mask=0x%32h, data=0x%h", axi_addr, axi_addr_mask, host_mem_1024), UVM_LOW)
    end
    if(data_invalid ==1)begin
        if(!nrw)
            `uvm_info(tID, $sformatf("Detect invalid data in a read command, host side: 128byte_align_address=0x%16h, compare_byte_mask=0x%32h, data=0x%h", axi_addr, axi_addr_mask, host_mem_1024), UVM_LOW)
        else
            `uvm_info(tID, $sformatf("Detect invalid data in a write command, host side: 128byte_align_address=0x%16h, compare_byte_mask=0x%32h, data=0x%h", axi_addr, axi_addr_mask, host_mem_1024), UVM_LOW)
    end
    check_brdg_memory = data_invalid | data_mismatch;
    return check_brdg_memory;
endfunction : check_brdg_memory

function bit[63:0] bridge_check_scoreboard::gen_pr_mask(bit[63:0] brdg_addr, bit[2:0] brdg_plength);
    if(brdg_addr%(1 << brdg_plength) != 0)
        `uvm_error(tID, $sformatf("The address of %h is not aligned to the plength of %h.", brdg_addr, brdg_plength))
    else begin
        for(int i=0; i<64; i++)begin
            if(i>=brdg_addr[5:0] && i<(brdg_addr[5:0]+(1 << brdg_plength)))begin
                gen_pr_mask[i]=1;
            end
            else begin
                gen_pr_mask[i]=0;                
            end
        end
    end
endfunction : gen_pr_mask

`endif

