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
`ifndef _ODMA_CHECK_SCOREBOARD_
`define _ODMA_CHECK_SCOREBOARD_

`include "odma_reg_defines.sv"
`include "../../../hdl/core/snap_global_vars.v"

//------------------------------------------------------------------------------
//
// CLASS: odma_check_sbd
//
//------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_tlx_afu_odma)
`uvm_analysis_imp_decl(_afu_tlx_odma)
`uvm_analysis_imp_decl(_axi_mm_odma)
`uvm_analysis_imp_decl(_axi_st_odma_h2a)
`uvm_analysis_imp_decl(_axi_st_odma_a2h)
//`uvm_analysis_imp_decl(_axi_mm_cmd_rd)
//`uvm_analysis_imp_decl(_axi_mm_cmd_wr)

class odma_check_scoreboard extends uvm_component;

    typedef class brdg_packet;
    typedef class tlx_resp_packet;
    typedef class list_mm_format;
    typedef class stream_data_format;

    //TLM port & transaction declaration
    uvm_analysis_imp_tlx_afu_odma        #(tlx_afu_transaction, odma_check_scoreboard) aimp_tlx_afu_odma;
    uvm_analysis_imp_afu_tlx_odma        #(afu_tlx_transaction, odma_check_scoreboard) aimp_afu_tlx_odma;
    uvm_analysis_imp_axi_mm_odma         #(axi_mm_transaction, odma_check_scoreboard) aimp_axi_mm_odma;
    uvm_analysis_imp_axi_st_odma_h2a     #(axi_st_transaction, odma_check_scoreboard) aimp_axi_st_odma_h2a;
    uvm_analysis_imp_axi_st_odma_a2h     #(axi_st_transaction, odma_check_scoreboard) aimp_axi_st_odma_a2h;
    brdg_cfg_obj                         brdg_cfg;

    //Internal signals declaration
    string tID;
    int total_num;
    int compare_num;
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
    tlx_resp_packet tlx_read_resp[bit[15:0]]; //Tlx_afu read response, the index is afutag
    tlx_resp_packet tlx_write_resp[bit[15:0]]; //Tlx_afu write response, the index is afutag
    bit [7:0] brdg_read_memory[longint unsigned]; //Brdg read data from tlx
    bit [7:0] brdg_write_memory[longint unsigned]; //Brdg write data to tlx
    bit [7:0] axi_read_memory[longint unsigned]; //AXI read data from tlx
    bit [7:0] axi_write_memory[longint unsigned]; //AXI write data to tlx
    bit [7:0] odma_mmio_reg[longint unsigned]; //ODMA mmio registor value
    list_mm_format list_mm_format_ch0;
    list_mm_format list_mm_format_ch1;
    list_mm_format list_mm_format_ch2;
    list_mm_format list_mm_format_ch3;
    bit [1:0][3:0]odma_status_reg; //Set 1 for start and set 0 for stop, [1:0] for direction and [3:0] for channel
    int list_num_ch0; //Current list number for channel 0
    int list_num_ch1; //Current list number for channel 1
    int list_num_ch2; //Current list number for channel 2
    int list_num_ch3; //Current list number for channel 3
    stream_data_format st_h2a_data[3:0]; //Stream H2A data for channel 0, 1, 2, 3
    stream_data_format st_a2h_data[3:0]; //Stream A2H data for channel 0, 1. 2, 3
    stream_data_format stream_data_item;

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

    class tlx_resp_packet; //The number of read/write response from tlx
        int tlx_afu_reap_num;
        tlx_afu_transaction tlx_afu_reap[bit[1:0]]; //Read/write response from tlx, the index is the value of dp
        function new(string name = "tlx_resp_packet");
            tlx_afu_reap_num=0;
        endfunction
    endclass: tlx_resp_packet

    //ODMA MMIO reg format
    class mmio_reg_format;
        bit[63:0] desp_adr;
        bit[31:0] adj_desp_num;
        bit[63:0] wr_back_adr;
        bit[31:0] buf_size;
        function new(string name = "mmio_reg_format");
        endfunction
    endclass: mmio_reg_format

    //ODMA MM list format
    class list_mm_format;
        //int chnl_num; //Channel num 0-3
        bit h2a_a2h; //0: h2a, 1:a2h
        //int block_num; //Block number as an index for block length queue
        int block_desp_num; //Current block collected descriptor number
        int chk_desp_num; //Descriptor number of which the data checked 
        int total_desp_num; //Total descriptor number in the list
        bit list_ready; //All of the descriptors in the list are collected
        //bit list_check; //All of the descriptors in the list are checked        
        bit list_done; //The list is stop
        bit[63:0] wr_back_adr; //Write back address for descriptor number
        bit[63:0] desp_head_addr[$]; //Descriptor head address queue, index is block number
        int block_length[$]; //The length of block in the list
        bit[63:0] desp_addr[$]; //Each descriptor address in the list       
        odma_desp_transaction desp_mm_q[$]; //Descriptor queue for the list
        function new(string name = "list_mm_format");
            list_done=1;
        endfunction
    endclass: list_mm_format

    //Stream data format
    class stream_data_format;
        int st_byte_num;
        int st_byte_num_queue[$];
        bit[7:0] data_queue[$];
        int desp_byte_num;
        function new(string name = "stream_data_format");
        endfunction
    endclass: stream_data_format

    `uvm_component_utils_begin(odma_check_scoreboard)
    `uvm_component_utils_end

    extern function new(string name = "odma_check_scoreboard", uvm_component parent = null);

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

    //extern function void write_odma_check(odma_check_transaction odma_check_tran);
    extern function void write_tlx_afu_odma(tlx_afu_transaction tlx_afu_tran);
    extern function void write_afu_tlx_odma(afu_tlx_transaction afu_tlx_tran);
    extern function void write_axi_mm_odma(axi_mm_transaction axi_mm_tran);
    extern function void write_axi_st_odma_h2a(axi_st_transaction axi_st_tran);
    extern function void write_axi_st_odma_a2h(axi_st_transaction axi_st_tran);
    extern function int dl2dl_num(bit[1:0] dl);
    extern function bit afutag_in_flight(bit[15:0] afutag);
    extern function void check_tlx_resp(bit nrw, bit[15:0]afutag, tlx_afu_transaction tlx_afu_tran);
    extern function void set_brdg_resp_success(bit nrw, bit[15:0] afutag);
    extern function bit check_resp_data(axi_mm_transaction axi_mm_tran, bit[63:0]beat_index, bit nrw);
    extern function void write_brdg_memory(bit[63:0] brdg_addr, bit[63:0] brdg_addr_mask, bit[511:0] data, bit nrw);
    extern function bit[63:0] gen_pr_mask(bit[63:0] brdg_addr, bit[2:0] brdg_plength);
    extern function bit check_brdg_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);
    extern function void collect_mmio_write(tlx_afu_transaction tlx_afu_tran);
    extern function void check_start_stop_bit(tlx_afu_transaction tlx_afu_tran);
    extern function mmio_reg_format get_mmio_reg(bit direction, int channel);
    extern function bit[31:0] get_mmio_4byte(bit[63:0] address);
    extern function bit brdg_read_mem_exists(bit[63:0] address, int byte_num);
    extern function void brdg_read_mem_delete(bit[63:0] address, int byte_num);
    extern function odma_desp_transaction catch_desp_chnl(int channel, bit[63:0] address);
    extern function odma_desp_transaction gen_mm_desp(bit[63:0] address);
    extern function void parse_desp_chnl(int channel, odma_desp_transaction desp_item);
    extern function void check_write_back_data(bit[63:0]address, bit[1023:0]data);
    extern function void check_dma_data(int chnl_num, bit direction, odma_desp_transaction desp_item);
    extern function void write_axi_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);
    extern function void check_list_chnnl(int channel);
    extern function void reset_list_chnnl(int channel);
    extern function void push_st_data(int channel, bit direction, axi_st_transaction axi_st_tran);
    extern function int get_tkeek_num(axi_st_transaction axi_st_tran);
endclass : odma_check_scoreboard

function odma_check_scoreboard::new(string name = "odma_check_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    aimp_tlx_afu_odma = new("aimp_tlx_afu_odma", this);
    aimp_afu_tlx_odma = new("aimp_afu_tlx_odma", this);
    aimp_axi_mm_odma  = new("aimp_axi_mm_odma", this);
    aimp_axi_st_odma_h2a  = new("aimp_axi_st_odma_h2a", this);
    aimp_axi_st_odma_a2h  = new("aimp_axi_st_odma_a2h", this);
    total_num    = 0;
    compare_num  = 0;
    list_mm_format_ch0 = new("list_mm_format_ch0");
    list_mm_format_ch1 = new("list_mm_format_ch1");
    list_mm_format_ch2 = new("list_mm_format_ch2");
    list_mm_format_ch3 = new("list_mm_format_ch3");
    foreach(st_h2a_data[i])begin
        stream_data_item = new("stream_data_item");
        st_h2a_data[i]=stream_data_item;
    end
    foreach(st_a2h_data[i])begin
        stream_data_item = new("stream_data_item");
        st_a2h_data[i]=stream_data_item;
    end
endfunction : new

function void odma_check_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_HIGH)
endfunction : build_phase

function void odma_check_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_HIGH)
    if(!uvm_config_db#(brdg_cfg_obj)::get(this, "", "brdg_cfg", brdg_cfg))
        `uvm_error(get_type_name(), "Can't get brdg_cfg!")
endfunction : connect_phase

task odma_check_scoreboard::main_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)
endtask: main_phase

function void odma_check_scoreboard::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_HIGH)
    if(brdg_cfg.enable_odma_scoreboard)begin
        `uvm_info(tID, $sformatf("ODMA scoreboard check list number: CH0:%d, CH1:%d, CH2:%d, CH3:%d", list_num_ch0, list_num_ch1, list_num_ch2, list_num_ch3), UVM_LOW)
    end
endfunction : check_phase

function bit odma_check_scoreboard::check_data_err(bit[63:0] addr, bit [255:0][1023:0] data, int byte_size, int burst_length);
    for(int j=0; j<burst_length; j++)begin
        for(int i=0; i<byte_size; i++)begin
            if(data[j][8*i+7-:8] != memory_model[addr+j*byte_size+i])begin
                return 1;
            end
        end
    end
    return 0;
endfunction: check_data_err

function bit odma_check_scoreboard::exist_data(longint unsigned addr, int byte_size, int burst_length);
    for(int j=0; j<burst_length; j++)begin
        for(int i=0; i<byte_size; i++)begin
            if(!memory_tag.exists(addr+j*byte_size+i))begin
                return 0;
            end
        end
    end
    return 1;
endfunction: exist_data

function void odma_check_scoreboard::print_mem();
        foreach(memory_tag[i])begin
            $display("Memory addr:%h,data:%h.", i, memory_model[i]);
        end
endfunction: print_mem

function axi_mm_transaction odma_check_scoreboard::get_mem_trans(bit[63:0] addr, int byte_size, int burst_length, axi_mm_transaction::uvm_axi_txn_e trans);
    get_mem_trans = new("get_mem_trans");
    get_mem_trans.trans=trans;
    get_mem_trans.addr=addr;
    get_mem_trans.byte_size=byte_size;
    get_mem_trans.burst_length=burst_length;
    for(int j=0; j<burst_length; j++)
        for(int i=0; i<byte_size; i++)
            get_mem_trans.data[j][i*8+7-:8]=memory_model[addr+j*byte_size+i];
endfunction: get_mem_trans

function void odma_check_scoreboard::write_axi_mm_odma(axi_mm_transaction axi_mm_tran);
    //bit[63:0] beat_index;
    //bit[15:0] usr_id;
    bit[127:0] axi_mask;
    bit[127:0] axi_wr_mask;
    bit[63:0] axi_addr_align;
    if(brdg_cfg.enable_odma_scoreboard)begin
        for(int i=0; i<axi_mm_tran.burst_length; i++)begin
            if(i == 0)begin
                axi_addr_align=(axi_mm_tran.addr/axi_mm_tran.byte_size)*axi_mm_tran.byte_size+i*axi_mm_tran.byte_size;
                for(int j=0; j<(`AXI_MM_DW/8); j++)begin
                    if(j>=(axi_mm_tran.addr-((axi_mm_tran.addr/(`AXI_MM_DW/8))*(`AXI_MM_DW/8))) && j<=(axi_addr_align+(axi_mm_tran.byte_size-1)-(axi_mm_tran.addr/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))begin
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
                    write_axi_memory((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8), axi_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))), 0);
                end
                else begin
                    write_axi_memory((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8), axi_wr_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))), 1);
                end
            end
            else begin
                axi_addr_align=(axi_mm_tran.addr/axi_mm_tran.byte_size)*axi_mm_tran.byte_size+i*axi_mm_tran.byte_size;
                for(int j=0; j<(`AXI_MM_DW/8); j++)begin
                    if(j>=(axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8))) && j<((axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))+axi_mm_tran.byte_size))begin
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
                    write_axi_memory((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8), axi_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))), 0);
                end
                else begin
                    write_axi_memory((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8), axi_wr_mask, axi_mm_tran.data[i]<<(8*(axi_addr_align-((axi_addr_align/(`AXI_MM_DW/8))*(`AXI_MM_DW/8)))), 1);
                end
            end
        end
        `uvm_info(tID, $sformatf("Record axi side read/write successfully! The axi transaction is:\n%s", axi_mm_tran.sprint()), UVM_MEDIUM)
    end
    else begin
        return;
    end
endfunction : write_axi_mm_odma

//Get odma st h2a transactions
function void odma_check_scoreboard::write_axi_st_odma_h2a(axi_st_transaction axi_st_tran);
    //Check transaction tid
    if(axi_st_tran.tid > 3)begin
        `uvm_error(tID, $sformatf("Get an illegal AXI stream tid of %d.", axi_st_tran.tid))
    end
    //Collect H2A transactions
    if(axi_st_tran.tlast == 1)begin
        st_h2a_data[axi_st_tran.tid].st_byte_num+=get_tkeek_num(axi_st_tran);
        st_h2a_data[axi_st_tran.tid].st_byte_num_queue.push_back(st_h2a_data[axi_st_tran.tid].st_byte_num);
        st_h2a_data[axi_st_tran.tid].st_byte_num=0;
        push_st_data(axi_st_tran.tid, 1, axi_st_tran);
    end
    else begin
        st_h2a_data[axi_st_tran.tid].st_byte_num+=get_tkeek_num(axi_st_tran);
        push_st_data(axi_st_tran.tid, 1, axi_st_tran);
    end
endfunction : write_axi_st_odma_h2a

//Get odma st a2h transactions
function void odma_check_scoreboard::write_axi_st_odma_a2h(axi_st_transaction axi_st_tran);
    //Check transaction tid
    if(axi_st_tran.tid > 3)begin
        `uvm_error(tID, $sformatf("Get an illegal AXI stream tid of %d.", axi_st_tran.tid))
    end
    //Collect A2H transactions
    if(axi_st_tran.tlast == 1)begin
        st_a2h_data[axi_st_tran.tid].st_byte_num+=get_tkeek_num(axi_st_tran);
        st_a2h_data[axi_st_tran.tid].st_byte_num_queue.push_back(st_a2h_data[axi_st_tran.tid].st_byte_num);
        st_a2h_data[axi_st_tran.tid].st_byte_num=0;
        push_st_data(axi_st_tran.tid, 0, axi_st_tran);
    end
    else begin
        st_a2h_data[axi_st_tran.tid].st_byte_num+=get_tkeek_num(axi_st_tran);
        push_st_data(axi_st_tran.tid, 0, axi_st_tran);
    end
endfunction : write_axi_st_odma_a2h

//Check read/write response data
function bit odma_check_scoreboard::check_resp_data(axi_mm_transaction axi_mm_tran, bit[63:0]beat_index, bit nrw);
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

//Parse tlx-afu responses and assign to related afu-tlx commands
function void odma_check_scoreboard::write_afu_tlx_odma(afu_tlx_transaction afu_tlx_tran);
    tlx_resp_packet tlx_resp_packet_item;
    if(brdg_cfg.enable_odma_scoreboard)begin
        //Catch write back
        if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::DMA_W && afu_tlx_tran.afu_tlx_dl == 2)begin
            check_write_back_data(afu_tlx_tran.afu_tlx_addr, {afu_tlx_tran.afu_tlx_data_bus[1],afu_tlx_tran.afu_tlx_data_bus[0]});
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
        else begin
            if(afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::ASSIGN_ACTAG || afu_tlx_tran.afu_tlx_type == afu_tlx_transaction::INTRP_REQ
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
        return;
    end
endfunction : write_afu_tlx_odma

function void odma_check_scoreboard::write_tlx_afu_odma(tlx_afu_transaction tlx_afu_tran);
    odma_desp_transaction odma_desp_item;
    odma_desp_item=new("odma_desp_item");
    if(brdg_cfg.enable_odma_scoreboard)begin
        //Collect mmio configuration
        if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::PR_WR_MEM)begin
            collect_mmio_write(tlx_afu_tran);
            check_start_stop_bit(tlx_afu_tran);
        end
        //Detect tlx afu read response        
        else if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_RESPONSE || tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::READ_FAILED)begin
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
        //Detect tlx afu write response
        else if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_RESPONSE || tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::WRITE_FAILED)begin
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
        //Collect descriptors for channel 0
        while((list_mm_format_ch0.desp_addr.size > 0) && (brdg_read_mem_exists(list_mm_format_ch0.desp_addr[0], 32)))begin
            odma_desp_item=catch_desp_chnl(0, list_mm_format_ch0.desp_addr[0]);
            parse_desp_chnl(0, odma_desp_item);
            brdg_read_mem_delete(list_mm_format_ch0.desp_addr[0], 32);
            void'(list_mm_format_ch0.desp_addr.pop_front());
        end
        //Collect descriptors for channel 1
        while((list_mm_format_ch1.desp_addr.size > 0) && (brdg_read_mem_exists(list_mm_format_ch1.desp_addr[0], 32)))begin
            odma_desp_item=catch_desp_chnl(1, list_mm_format_ch1.desp_addr[0]);
            parse_desp_chnl(1, odma_desp_item);
            brdg_read_mem_delete(list_mm_format_ch1.desp_addr[0], 32);
            void'(list_mm_format_ch1.desp_addr.pop_front());
        end
        //Collect descriptors for channel 2
        while((list_mm_format_ch2.desp_addr.size > 0) && (brdg_read_mem_exists(list_mm_format_ch2.desp_addr[0], 32)))begin
            odma_desp_item=catch_desp_chnl(2, list_mm_format_ch2.desp_addr[0]);
            parse_desp_chnl(2, odma_desp_item);
            brdg_read_mem_delete(list_mm_format_ch2.desp_addr[0], 32);
            void'(list_mm_format_ch2.desp_addr.pop_front());
        end
        //Collect descriptors for channel 3
        while((list_mm_format_ch3.desp_addr.size > 0) && (brdg_read_mem_exists(list_mm_format_ch3.desp_addr[0], 32)))begin
            odma_desp_item=catch_desp_chnl(3, list_mm_format_ch3.desp_addr[0]);
            parse_desp_chnl(3, odma_desp_item);
            brdg_read_mem_delete(list_mm_format_ch3.desp_addr[0], 32);
            void'(list_mm_format_ch3.desp_addr.pop_front());
        end
    end
endfunction : write_tlx_afu_odma

//Parse tlx dl to number of 64byte
function int odma_check_scoreboard::dl2dl_num(bit[1:0] dl);
    case(dl)
        2'b01: dl2dl_num = 1;
        2'b10: dl2dl_num = 2;
        2'b11: dl2dl_num = 4;
        default: `uvm_error(get_type_name(), "Get an illegal data length!")
    endcase
endfunction : dl2dl_num

function bit odma_check_scoreboard::afutag_in_flight(bit[15:0] afutag);
    if(flight_afu_tlx_rd.exists(afutag) || flight_afu_tlx_wr.exists(afutag))
        afutag_in_flight=1;
    else
        afutag_in_flight=0;
endfunction : afutag_in_flight

function void odma_check_scoreboard::check_tlx_resp(bit nrw, bit[15:0]afutag, tlx_afu_transaction tlx_afu_tran);
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

function void odma_check_scoreboard::set_brdg_resp_success(bit nrw, bit[15:0] afutag);
    if(nrw == 0)begin: search_rd_afutag
        foreach(brdg_packet_read[i])begin
            for(int j=0; j<brdg_packet_read[i].brdg_cmd_num; j++)begin
                if(!brdg_packet_read[i].tlx_resp_success && !brdg_packet_read[i].axi_resp_success
                && brdg_packet_read[i].brdg_resp_pending[j]
                && !brdg_packet_read[i].brdg_cmd_pending[j]
                && !brdg_packet_read[i].brdg_resp_success[j]
                && brdg_packet_read[i].brdg_cmd_afutag[j] == afutag)begin
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

function void odma_check_scoreboard::write_brdg_memory(bit[63:0] brdg_addr, bit[63:0] brdg_addr_mask, bit[511:0] data, bit nrw);
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

//Record axi side data for read/write
function void odma_check_scoreboard::write_axi_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);
    for(int i=0; i<(`AXI_MM_DW/8); i++)begin
        if(axi_addr_mask[i])begin
            if(!nrw)begin
                axi_read_memory[axi_addr+i]=data[8*i+7-:8];
            end
            else begin
                axi_write_memory[axi_addr+i]=data[8*i+7-:8];
            end
        end
    end
endfunction : write_axi_memory

function bit odma_check_scoreboard::check_brdg_memory(bit[63:0] axi_addr, bit[127:0] axi_addr_mask, bit[1023:0] data, bit nrw);
    bit[1023:0] host_mem_1024;
    bit data_mismatch;
    bit data_invalid;
    check_brdg_memory=0;
    for(int i=0; i<128; i++)begin
        if(axi_addr_mask[i])begin
            if(!nrw)begin
                if(!brdg_read_memory.exists(axi_addr+i))begin
                    data_invalid = 1;
                end
                else if(data[8*i+7-:8] != brdg_read_memory[axi_addr+i])begin
                    data_mismatch = 1;
                end
                else begin
                    host_mem_1024[8*i+7-:8] = brdg_read_memory[axi_addr+i];                        
                end
            end
            else begin
                if(!brdg_write_memory.exists(axi_addr+i))begin
                     data_invalid = 1;
                end
                else if(data[8*i+7-:8] != brdg_write_memory[axi_addr+i])begin
                    data_mismatch = 1;
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

// Generate partial read/write address mask
function bit[63:0] odma_check_scoreboard::gen_pr_mask(bit[63:0] brdg_addr, bit[2:0] brdg_plength);
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

// Collect MMIO write commanda and write the value to the mmio reg model
function void  odma_check_scoreboard::collect_mmio_write(tlx_afu_transaction tlx_afu_tran);
    bit[63:0] addr_mask;
    bit[63:0] addr_align;
    addr_align = {tlx_afu_tran.tlx_afu_addr[63:6], 6'b0};
    if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::PR_WR_MEM && tlx_afu_tran.tlx_afu_addr >= `REG_ODMA_MIN_ADDR && tlx_afu_tran.tlx_afu_addr <= `REG_ODMA_MAX_ADDR)begin
        addr_mask=gen_pr_mask(tlx_afu_tran.tlx_afu_addr, tlx_afu_tran.tlx_afu_pl);
        for(int i=0; i<64; i++)begin
            if(addr_mask[i])begin
                odma_mmio_reg[addr_align+i]=tlx_afu_tran.tlx_afu_data_bus[0][8*i+7-:8];
            end
        end
    end
endfunction : collect_mmio_write

// Check start/stop set bit and initial list
function void  odma_check_scoreboard::check_start_stop_bit(tlx_afu_transaction tlx_afu_tran);
    mmio_reg_format mmio_reg_item;
    mmio_reg_item=new("mmio_reg_item");
    if(tlx_afu_tran.tlx_afu_type == tlx_afu_transaction::PR_WR_MEM && tlx_afu_tran.tlx_afu_pl == 2)begin
        // Set start bit
        // Channel 0, H2A
        if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH0_CTRL_W1S && odma_mmio_reg[`REG_H2A_CH0_CTRL_W1S] == 1 && odma_status_reg[0][0] == 0)begin
            odma_status_reg[0][0] = 1;
            mmio_reg_item=get_mmio_reg(0, 0);
            list_mm_format_ch0.list_done=0;
            list_mm_format_ch0.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch0.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch0.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch0.block_num++;
            list_mm_format_ch0.h2a_a2h=0;
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch0.desp_addr.push_back(list_mm_format_ch0.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 0 start: Direction: H2A, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 1, H2A
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH1_CTRL_W1S && odma_mmio_reg[`REG_H2A_CH1_CTRL_W1S] == 1 && odma_status_reg[0][1] == 0)begin
            odma_status_reg[0][1] = 1;
            mmio_reg_item=get_mmio_reg(0, 1);
            list_mm_format_ch1.list_done=0;
            list_mm_format_ch1.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch1.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch1.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch1.block_num++;
            list_mm_format_ch1.h2a_a2h=0;   
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch1.desp_addr.push_back(list_mm_format_ch1.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 1 start: Direction: H2A, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 2, H2A
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH2_CTRL_W1S && odma_mmio_reg[`REG_H2A_CH2_CTRL_W1S] == 1 && odma_status_reg[0][2] == 0)begin
            odma_status_reg[0][2] = 1;
            mmio_reg_item=get_mmio_reg(0, 2);
            list_mm_format_ch2.list_done=0;
            list_mm_format_ch2.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch2.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch2.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch2.block_num++;
            list_mm_format_ch2.h2a_a2h=0;
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch2.desp_addr.push_back(list_mm_format_ch2.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 2 start: Direction: H2A, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 3, H2A
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH3_CTRL_W1S && odma_mmio_reg[`REG_H2A_CH3_CTRL_W1S] == 1 && odma_status_reg[0][3] == 0)begin
            odma_status_reg[0][3] = 1;
            mmio_reg_item=get_mmio_reg(0, 3);
            list_mm_format_ch3.list_done=0;
            list_mm_format_ch3.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch3.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch3.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch3.block_num++;
            list_mm_format_ch3.h2a_a2h=0;  
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch3.desp_addr.push_back(list_mm_format_ch3.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 3 start: Direction: H2A, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 0, A2H
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH0_CTRL_W1S && odma_mmio_reg[`REG_A2H_CH0_CTRL_W1S] == 1 && odma_status_reg[1][0] == 0)begin
            odma_status_reg[1][0] = 1;
            mmio_reg_item=get_mmio_reg(1, 0);
            list_mm_format_ch0.list_done=0;
            list_mm_format_ch0.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch0.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch0.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch0.block_num++;
            list_mm_format_ch0.h2a_a2h=1;
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch0.desp_addr.push_back(list_mm_format_ch0.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 0 start: Direction: A2H, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 1, A2H
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH1_CTRL_W1S && odma_mmio_reg[`REG_A2H_CH1_CTRL_W1S] == 1 && odma_status_reg[1][1] == 0)begin
            odma_status_reg[1][1] = 1;
            mmio_reg_item=get_mmio_reg(1, 1);
            list_mm_format_ch1.list_done=0;
            list_mm_format_ch1.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch1.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch1.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch1.block_num++;
            list_mm_format_ch1.h2a_a2h=1;  
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch1.desp_addr.push_back(list_mm_format_ch1.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 1 start: Direction: A2H, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 2, A2H
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH2_CTRL_W1S && odma_mmio_reg[`REG_A2H_CH2_CTRL_W1S] == 1 && odma_status_reg[1][2] == 0)begin
            odma_status_reg[1][2] = 1;
            mmio_reg_item=get_mmio_reg(1, 2);
            list_mm_format_ch2.list_done=0;
            list_mm_format_ch2.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch2.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch2.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch2.block_num++;
            list_mm_format_ch2.h2a_a2h=1;     
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch2.desp_addr.push_back(list_mm_format_ch2.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 2 start: Direction: A2H, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Channel 3, A2H
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH3_CTRL_W1S && odma_mmio_reg[`REG_A2H_CH3_CTRL_W1S] == 1 && odma_status_reg[1][3] == 0)begin
            odma_status_reg[1][3] = 1;
            mmio_reg_item=get_mmio_reg(1, 3);
            list_mm_format_ch3.list_done=0;
            list_mm_format_ch3.desp_head_addr.push_back(mmio_reg_item.desp_adr);
            list_mm_format_ch3.wr_back_adr=mmio_reg_item.wr_back_adr;
            list_mm_format_ch3.block_length.push_back(mmio_reg_item.adj_desp_num+1);
            //list_mm_format_ch3.block_num++;
            list_mm_format_ch3.h2a_a2h=1; 
            for(int i=0; i<mmio_reg_item.adj_desp_num+1; i++)begin
                list_mm_format_ch3.desp_addr.push_back(list_mm_format_ch3.desp_head_addr[0]+32*i);                    
            end
            `uvm_info(tID, $sformatf("Channel 3 start: Direction: A2H, First descriptor addr: %16h, Adjacent descriptor num: %d, Write back addr: %16h.",mmio_reg_item.desp_adr, mmio_reg_item.adj_desp_num+1, mmio_reg_item.wr_back_adr), UVM_LOW)            
        end
        // Set stop bit
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH0_CTRL_W1C && odma_mmio_reg[`REG_H2A_CH0_CTRL_W1C] == 1 && odma_status_reg[0][0] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, H2A, List %d stop.", list_num_ch0), UVM_LOW)                        
            check_list_chnnl(0);
            odma_status_reg[0][0] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH1_CTRL_W1C && odma_mmio_reg[`REG_H2A_CH1_CTRL_W1C] == 1 && odma_status_reg[0][1] == 1)begin
            `uvm_info(tID, $sformatf("Channel 1, H2A, List %d stop.", list_num_ch1), UVM_LOW)                        
            check_list_chnnl(1);
            odma_status_reg[0][1] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH2_CTRL_W1C && odma_mmio_reg[`REG_H2A_CH2_CTRL_W1C] == 1 && odma_status_reg[0][2] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, H2A, List %d stop.", list_num_ch2), UVM_LOW)                        
            check_list_chnnl(2);
            odma_status_reg[0][2] = 0;                
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_H2A_CH3_CTRL_W1C && odma_mmio_reg[`REG_H2A_CH3_CTRL_W1C] == 1 && odma_status_reg[0][3] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, H2A, List %d stop.", list_num_ch3), UVM_LOW)                        
            check_list_chnnl(3);
            odma_status_reg[0][3] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH0_CTRL_W1C && odma_mmio_reg[`REG_A2H_CH0_CTRL_W1C] == 1 && odma_status_reg[1][0] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, A2H, List %d stop.", list_num_ch0), UVM_LOW)                        
            check_list_chnnl(0);
            odma_status_reg[1][0] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH1_CTRL_W1C && odma_mmio_reg[`REG_A2H_CH1_CTRL_W1C] == 1 && odma_status_reg[1][1] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, A2H, List %d stop.", list_num_ch1), UVM_LOW)                        
            check_list_chnnl(1);
            odma_status_reg[1][1] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH2_CTRL_W1C && odma_mmio_reg[`REG_A2H_CH2_CTRL_W1C] == 1 && odma_status_reg[1][2] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, A2H, List %d stop.", list_num_ch2), UVM_LOW)                        
            check_list_chnnl(2);
            odma_status_reg[1][2] = 0;
        end
        else if(tlx_afu_tran.tlx_afu_addr == `REG_A2H_CH3_CTRL_W1C && odma_mmio_reg[`REG_A2H_CH3_CTRL_W1C] == 1 && odma_status_reg[1][3] == 1)begin
            `uvm_info(tID, $sformatf("Channel 0, A2H, List %d stop.", list_num_ch3), UVM_LOW)                        
            check_list_chnnl(3);
            odma_status_reg[1][3] = 0;                
        end
    end
endfunction : check_start_stop_bit

//Generate the first descriptor head address
function mmio_reg_format odma_check_scoreboard::get_mmio_reg(bit direction, int channel);
    get_mmio_reg=new("get_mmio_reg");
    //From action to host
    if(direction)begin
        case(channel)
            0:begin
                if(list_mm_format_ch0.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_A2H_CH0_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_A2H_CH0_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_A2H_CH0_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_A2H_CH0_WB_ADDR_HI), get_mmio_4byte(`REG_A2H_CH0_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_A2H_CH0_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous A2H channel 0 list is not done.")                        
                end
            end
            1:begin
                if(list_mm_format_ch1.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_A2H_CH1_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_A2H_CH1_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_A2H_CH1_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_A2H_CH1_WB_ADDR_HI), get_mmio_4byte(`REG_A2H_CH1_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_A2H_CH1_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous A2H channel 1 list is not done.")                        
                end
            end
            2:begin 
                if(list_mm_format_ch2.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_A2H_CH2_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_A2H_CH2_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_A2H_CH2_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_A2H_CH2_WB_ADDR_HI), get_mmio_4byte(`REG_A2H_CH2_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_A2H_CH2_WB_SIZE);
                end 
                else begin
                    `uvm_error(get_type_name(), "The previous A2H channel 2 list is not done.")                        
                end
            end
            3:begin
                if(list_mm_format_ch3.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_A2H_CH3_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_A2H_CH3_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_A2H_CH3_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_A2H_CH3_WB_ADDR_HI), get_mmio_4byte(`REG_A2H_CH3_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_A2H_CH3_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous A2H channel 3 list is not done.")                        
                end
            end
            default:
                `uvm_error(get_type_name(), "Get an illegal channel number!")
        endcase
    end
    //From host to action  
    else begin
        case(channel)            
            0:begin
                if(list_mm_format_ch0.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_H2A_CH0_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_H2A_CH0_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_H2A_CH0_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_H2A_CH0_WB_ADDR_HI), get_mmio_4byte(`REG_H2A_CH0_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_H2A_CH0_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous H2A channel 0 list is not done.")                        
                end
            end
            1:begin
                if(list_mm_format_ch1.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_H2A_CH1_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_H2A_CH1_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_H2A_CH1_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_H2A_CH1_WB_ADDR_HI), get_mmio_4byte(`REG_H2A_CH1_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_H2A_CH1_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous H2A channel 1 list is not done.")                        
                end
            end
            2:begin 
                if(list_mm_format_ch2.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_H2A_CH2_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_H2A_CH2_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_H2A_CH2_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_H2A_CH2_WB_ADDR_HI), get_mmio_4byte(`REG_H2A_CH2_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_H2A_CH2_WB_SIZE);
                end 
                else begin
                    `uvm_error(get_type_name(), "The previous H2A channel 2 list is not done.")                        
                end
            end
            3:begin
                if(list_mm_format_ch3.list_done)begin
                    get_mmio_reg.desp_adr={get_mmio_4byte(`REG_H2A_CH3_DMA_DSC_ADDR_HI), get_mmio_4byte(`REG_H2A_CH3_DMA_DSC_ADDR_LO)};
                    get_mmio_reg.adj_desp_num=get_mmio_4byte(`REG_H2A_CH3_DMA_DSC_ADJ);
                    get_mmio_reg.wr_back_adr={get_mmio_4byte(`REG_H2A_CH3_WB_ADDR_HI), get_mmio_4byte(`REG_H2A_CH3_WB_ADDR_LO)};
                    get_mmio_reg.buf_size=get_mmio_4byte(`REG_H2A_CH3_WB_SIZE);
                end
                else begin
                    `uvm_error(get_type_name(), "The previous H2A channel 3 list is not done.")                        
                end
            end
            default:
                `uvm_error(get_type_name(), "Get an illegal channel number!")
        endcase
    end
endfunction : get_mmio_reg

//Get mmio 4 byte value
function bit[31:0] odma_check_scoreboard::get_mmio_4byte(bit[63:0] address);
    for(int i=0; i<4; i++)begin
        if(!odma_mmio_reg.exists(address+i))begin
            `uvm_error(get_type_name(), $psprintf("The address=0x%16h of mmio dose not exist!", (address+i)))
        end
    end
    get_mmio_4byte={odma_mmio_reg[address+3], odma_mmio_reg[address+2], odma_mmio_reg[address+1], odma_mmio_reg[address]};
endfunction : get_mmio_4byte

//Check if address is valid in bridge read memory model
function bit odma_check_scoreboard::brdg_read_mem_exists(bit[63:0] address, int byte_num);
    brdg_read_mem_exists = 1;
    for(int i=0; i<byte_num; i++)begin
        if(!brdg_read_memory.exists(address+i))begin
            return 0;
        end
    end
endfunction : brdg_read_mem_exists

//Delete data and address in the bridge read memory model
function void odma_check_scoreboard::brdg_read_mem_delete(bit[63:0] address, int byte_num);
    for(int i=0; i<byte_num; i++)begin
        if(brdg_read_memory.exists(address+i))begin
            brdg_read_memory.delete(address+i);
        end
    end
endfunction : brdg_read_mem_delete

//Catch the descriptor from bridge read memory model
function odma_desp_transaction odma_check_scoreboard::catch_desp_chnl(int channel, bit[63:0] address);
    case(channel)
        0:begin
            if({brdg_read_memory[address+3], brdg_read_memory[address+2]} == 16'had4b)begin
                catch_desp_chnl=gen_mm_desp(address);
                list_mm_format_ch0.desp_mm_q.push_back(catch_desp_chnl);
                `uvm_info(tID, $sformatf("Get a descriptor for channel 0:\n%s", catch_desp_chnl.sprint()), UVM_MEDIUM)
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("The descriptor magic content is not 0xad4b for channel 0. The descriptor head address is 0x%16h.", address))                       
            end
        end
        1:begin
            if({brdg_read_memory[address+3], brdg_read_memory[address+2]} == 16'had4b)begin
                catch_desp_chnl=gen_mm_desp(address);
                list_mm_format_ch1.desp_mm_q.push_back(catch_desp_chnl);
                `uvm_info(tID, $sformatf("Get a descriptor for channel 1:\n%s", catch_desp_chnl.sprint()), UVM_MEDIUM)
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("The descriptor magic content is not 0xad4b for channel 1. The descriptor head address is 0x%16h.", address))                       
            end
        end
        2:begin
            if({brdg_read_memory[address+3], brdg_read_memory[address+2]} == 16'had4b)begin
                catch_desp_chnl=gen_mm_desp(address);
                 list_mm_format_ch2.desp_mm_q.push_back(catch_desp_chnl);
                `uvm_info(tID, $sformatf("Get a descriptor for channel 2:\n%s", catch_desp_chnl.sprint()), UVM_MEDIUM)
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("The descriptor magic content is not 0xad4b for channel 2. The descriptor head address is 0x%16h.", address))                       
            end
        end
        3:begin
            if({brdg_read_memory[address+3], brdg_read_memory[address+2]} == 16'had4b)begin
                catch_desp_chnl=gen_mm_desp(address);
                list_mm_format_ch3.desp_mm_q.push_back(catch_desp_chnl);
                `uvm_info(tID, $sformatf("Get a descriptor for channel 3:\n%s", catch_desp_chnl.sprint()), UVM_MEDIUM)
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("The descriptor magic content is not 0xad4b for channel 3. The descriptor head address is 0x%16h.", address))                       
            end
        end
        default:
            `uvm_error(get_type_name(), $psprintf("Get an illegal channel number! The descriptor head address is 0x%16h.", address))
    endcase
endfunction : catch_desp_chnl

//Generate the descriptor from memory data
function odma_desp_transaction odma_check_scoreboard::gen_mm_desp(bit[63:0] address);
    gen_mm_desp=new("gen_mm_desp");
    gen_mm_desp.magic={brdg_read_memory[address+3], brdg_read_memory[address+2]};
    gen_mm_desp.nxt_adj=brdg_read_memory[address+1][5:0];
    gen_mm_desp.control=brdg_read_memory[address];
    gen_mm_desp.stop=gen_mm_desp.control[0];
    gen_mm_desp.st_eop=gen_mm_desp.control[4];
    gen_mm_desp.length={brdg_read_memory[address+7][3:0], brdg_read_memory[address+6], brdg_read_memory[address+5], brdg_read_memory[address+4]};
    gen_mm_desp.src_adr={brdg_read_memory[address+15], brdg_read_memory[address+14], brdg_read_memory[address+13], brdg_read_memory[address+12],
    brdg_read_memory[address+11], brdg_read_memory[address+10], brdg_read_memory[address+9], brdg_read_memory[address+8]};
    gen_mm_desp.dst_adr={brdg_read_memory[address+23], brdg_read_memory[address+22], brdg_read_memory[address+21], brdg_read_memory[address+20],
    brdg_read_memory[address+19], brdg_read_memory[address+18], brdg_read_memory[address+17], brdg_read_memory[address+16]};
    gen_mm_desp.nxt_adr={brdg_read_memory[address+31], brdg_read_memory[address+30], brdg_read_memory[address+29], brdg_read_memory[address+28],
    brdg_read_memory[address+27], brdg_read_memory[address+26], brdg_read_memory[address+25], brdg_read_memory[address+24]};
endfunction : gen_mm_desp

//Parse the descriptor for each channel
function void odma_check_scoreboard::parse_desp_chnl(int channel, odma_desp_transaction desp_item);
    case(channel)
        0:begin
            if(list_mm_format_ch0.block_desp_num < list_mm_format_ch0.block_length[list_mm_format_ch0.block_length.size-1]-1)begin
                //Check stop bit
                if(desp_item.stop == 1)begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal stop bit in the following descriptor for channel 0!\n%s", desp_item.sprint()))
                end
                //Check nxt_adj number
                if(desp_item.nxt_adj != (list_mm_format_ch0.block_length[list_mm_format_ch0.block_length.size-1]-list_mm_format_ch0.block_desp_num-2))begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal nxt_adj number in the following descriptor for channel 0!\n%s", desp_item.sprint()))
                end
                list_mm_format_ch0.block_desp_num++;
            end
            else if(list_mm_format_ch0.block_desp_num == list_mm_format_ch0.block_length[list_mm_format_ch0.block_length.size-1]-1)begin
                //Stop bit is 1
                if(desp_item.stop == 1)begin
                    list_mm_format_ch0.list_ready=1;
                    foreach(list_mm_format_ch0.block_length[i])begin
                        list_mm_format_ch0.total_desp_num+=list_mm_format_ch0.block_length[i];
                    end
                end
                //Stop bit is 0
                else begin
                    //Push descriptor length into queue for next block
                    list_mm_format_ch0.block_length.push_back(desp_item.nxt_adj+1);
                    //Push descriptor address into queue for next block
                    for(int i=0; i<(desp_item.nxt_adj+1); i++)begin
                        list_mm_format_ch0.desp_addr.push_back(desp_item.nxt_adr+32*i);
                    end
                end
                list_mm_format_ch0.block_desp_num=0;
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("Get too many descriptors for the current block in the channel 0."))                       
            end
        end
        1:begin
            if(list_mm_format_ch1.block_desp_num < list_mm_format_ch1.block_length[list_mm_format_ch1.block_length.size-1]-1)begin
                //Check stop bit
                if(desp_item.stop == 1)begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal stop bit in the following descriptor for channel 1!\n%s", desp_item.sprint()))
                end
                //Check nxt_adj number
                if(desp_item.nxt_adj != (list_mm_format_ch1.block_length[list_mm_format_ch1.block_length.size-1]-list_mm_format_ch1.block_desp_num-2))begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal nxt_adj number in the following descriptor for channel 1!\n%s", desp_item.sprint()))
                end
                list_mm_format_ch1.block_desp_num++;
            end
            else if(list_mm_format_ch1.block_desp_num == list_mm_format_ch1.block_length[list_mm_format_ch1.block_length.size-1]-1)begin
                //Stop bit is 1
                if(desp_item.stop == 1)begin
                    list_mm_format_ch1.list_ready=1;
                    foreach(list_mm_format_ch1.block_length[i])begin
                        list_mm_format_ch1.total_desp_num+=list_mm_format_ch1.block_length[i];
                    end
                end
                //Stop bit is 0
                else begin
                    //Push descriptor length into queue for next block
                    list_mm_format_ch1.block_length.push_back(desp_item.nxt_adj+1);
                    //Push descriptor address into queue for next block
                    for(int i=0; i<(desp_item.nxt_adj+1); i++)begin
                        list_mm_format_ch1.desp_addr.push_back(desp_item.nxt_adr+32*i);
                    end
                end
                list_mm_format_ch1.block_desp_num=0;
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("Get too many descriptors for the current block in the channel 1."))                       
            end
        end
        2:begin
            if(list_mm_format_ch2.block_desp_num < list_mm_format_ch2.block_length[list_mm_format_ch2.block_length.size-1]-1)begin
                //Check stop bit
                if(desp_item.stop == 1)begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal stop bit in the following descriptor for channel 2!\n%s", desp_item.sprint()))
                end
                //Check nxt_adj number
                if(desp_item.nxt_adj != (list_mm_format_ch2.block_length[list_mm_format_ch2.block_length.size-1]-list_mm_format_ch2.block_desp_num-2))begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal nxt_adj number in the following descriptor for channel 2!\n%s", desp_item.sprint()))
                end
                list_mm_format_ch2.block_desp_num++;
            end
            else if(list_mm_format_ch2.block_desp_num == list_mm_format_ch2.block_length[list_mm_format_ch2.block_length.size-1]-1)begin
                //Stop bit is 1
                if(desp_item.stop == 1)begin
                    list_mm_format_ch2.list_ready=1;
                    foreach(list_mm_format_ch2.block_length[i])begin
                        list_mm_format_ch2.total_desp_num+=list_mm_format_ch2.block_length[i];
                    end
                end
                //Stop bit is 0
                else begin
                    //Push descriptor length into queue for next block
                    list_mm_format_ch2.block_length.push_back(desp_item.nxt_adj+1);
                    //Push descriptor address into queue for next block
                    for(int i=0; i<(desp_item.nxt_adj+1); i++)begin
                        list_mm_format_ch2.desp_addr.push_back(desp_item.nxt_adr+32*i);
                    end
                end
                list_mm_format_ch2.block_desp_num=0;
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("Get too many descriptors for the current block in the channel 2."))                       
            end
        end
        3:begin
            if(list_mm_format_ch3.block_desp_num < list_mm_format_ch3.block_length[list_mm_format_ch3.block_length.size-1]-1)begin
                //Check stop bit
                if(desp_item.stop == 1)begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal stop bit in the following descriptor for channel 3!\n%s", desp_item.sprint()))
                end
                //Check nxt_adj number
                if(desp_item.nxt_adj != (list_mm_format_ch3.block_length[list_mm_format_ch3.block_length.size-1]-list_mm_format_ch3.block_desp_num-2))begin
                    `uvm_error(get_type_name(), $psprintf("Get an illegal nxt_adj number in the following descriptor for channel 3!\n%s", desp_item.sprint()))
                end
                list_mm_format_ch3.block_desp_num++;
            end
            else if(list_mm_format_ch3.block_desp_num == list_mm_format_ch3.block_length[list_mm_format_ch3.block_length.size-1]-1)begin
                //Stop bit is 1
                if(desp_item.stop == 1)begin
                    list_mm_format_ch3.list_ready=1;
                    foreach(list_mm_format_ch3.block_length[i])begin
                        list_mm_format_ch3.total_desp_num+=list_mm_format_ch3.block_length[i];
                    end
                end
                //Stop bit is 0
                else begin
                    //Push descriptor length into queue for next block
                    list_mm_format_ch3.block_length.push_back(desp_item.nxt_adj+1);
                    //Push descriptor address into queue for next block
                    for(int i=0; i<(desp_item.nxt_adj+1); i++)begin
                        list_mm_format_ch3.desp_addr.push_back(desp_item.nxt_adr+32*i);
                    end
                end
                list_mm_format_ch3.block_desp_num=0;
            end
            else begin
                `uvm_error(get_type_name(), $psprintf("Get too many descriptors for the current block in the channel 3."))                       
            end
        end
        default:
            `uvm_error(get_type_name(), $psprintf("Get an illegal channel number!"))
    endcase
endfunction : parse_desp_chnl

//Check write back number
function void odma_check_scoreboard::check_write_back_data(bit[63:0]address, bit[1023:0]data);
    //Check channel 0
    if((list_mm_format_ch0.list_done == 0) && (address == list_mm_format_ch0.wr_back_adr))begin
        `uvm_info(tID, $sformatf("Get write back data of 0x%4h for channel 0.", data[15:0]), UVM_LOW)
        //Check total descriptor number and descriptor queue
        if(list_mm_format_ch0.list_ready && (list_mm_format_ch0.desp_mm_q.size != list_mm_format_ch0.total_desp_num))begin
            `uvm_error(get_type_name(), $psprintf("Get a number of %d descriptors that not match the total descriptor number of %d for channel 0!", list_mm_format_ch0.desp_mm_q.size, list_mm_format_ch0.total_desp_num))
        end
        //Exist descriptors not checked in the list
        if(!(list_mm_format_ch0.list_ready && (list_mm_format_ch0.chk_desp_num == list_mm_format_ch0.total_desp_num)))begin
            //Check write back descriptor number
            if(data[15:0] > list_mm_format_ch0.desp_mm_q.size)begin
                `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor number is %d for channel 0!", data[15:0], list_mm_format_ch0.desp_mm_q.size))
            end
            //New write back descriptor check number
            if(data[15:0] > list_mm_format_ch0.chk_desp_num)begin
                //Check dma data
                for(int i=0; i<(data[15:0]-list_mm_format_ch0.chk_desp_num); i++)begin
                    if(list_mm_format_ch0.desp_mm_q.size < (list_mm_format_ch0.chk_desp_num+i+1))begin
                        `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor queue size is %d and the checked descriptor number is %d for channel 0!"
                        , data[15:0], list_mm_format_ch0.desp_mm_q.size, list_mm_format_ch0.chk_desp_num))
                    end
                    `uvm_info(tID, $sformatf("Check data for channel 0."), UVM_LOW)                    
                    check_dma_data(0, list_mm_format_ch0.h2a_a2h, list_mm_format_ch0.desp_mm_q[list_mm_format_ch0.chk_desp_num+i]);
                end
                //Set list done
                if(list_mm_format_ch0.list_ready && (data[15:0] == list_mm_format_ch0.total_desp_num))begin
                    list_mm_format_ch0.list_done=1;
                    list_num_ch0++;
                end
                list_mm_format_ch0.chk_desp_num=data[15:0];
            end
        end
    end
    //Check channel 1
    if((list_mm_format_ch1.list_done == 0) && (address == list_mm_format_ch1.wr_back_adr))begin
        `uvm_info(tID, $sformatf("Get write back data of 0x%4h for channel 1.", data[15:0]), UVM_LOW)
        //Check total descriptor number and descriptor queue
        if(list_mm_format_ch1.list_ready && (list_mm_format_ch1.desp_mm_q.size != list_mm_format_ch1.total_desp_num))begin
            `uvm_error(get_type_name(), $psprintf("Get a number of %d descriptors that not match the total descriptor number of %d for channel 1!", list_mm_format_ch1.desp_mm_q.size, list_mm_format_ch1.total_desp_num))
        end
        //Exist descriptors not checked in the list
        if(!(list_mm_format_ch1.list_ready && (list_mm_format_ch1.chk_desp_num == list_mm_format_ch1.total_desp_num)))begin
            //Check write back descriptor number
            if(data[15:0] > list_mm_format_ch1.desp_mm_q.size)begin
                `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor number is %d for channel 1!", data[15:0], list_mm_format_ch1.desp_mm_q.size))
            end
            //New write back descriptor check number
            if(data[15:0] > list_mm_format_ch1.chk_desp_num)begin
                //Check dma data
                for(int i=0; i<(data[15:0]-list_mm_format_ch1.chk_desp_num); i++)begin
                    if(list_mm_format_ch1.desp_mm_q.size < (list_mm_format_ch1.chk_desp_num+i+1))begin
                        `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor queue size is %d and the checked descriptor number is %d for channel 1!"
                        , data[15:0], list_mm_format_ch1.desp_mm_q.size, list_mm_format_ch1.chk_desp_num))
                    end
                    `uvm_info(tID, $sformatf("Check data for channel 1."), UVM_LOW)                    
                    check_dma_data(1, list_mm_format_ch1.h2a_a2h, list_mm_format_ch1.desp_mm_q[list_mm_format_ch1.chk_desp_num+i]);
                end
                //Set list done
                if(list_mm_format_ch1.list_ready && (data[15:0] == list_mm_format_ch1.total_desp_num))begin
                    list_mm_format_ch1.list_done=1;
                    list_num_ch1++;
                end
                list_mm_format_ch1.chk_desp_num=data[15:0];
            end
        end
    end
    //Check channel 2
    if((list_mm_format_ch2.list_done == 0) && (address == list_mm_format_ch2.wr_back_adr))begin
        `uvm_info(tID, $sformatf("Get write back data of 0x%4h for channel 2.", data[15:0]), UVM_LOW)
        //Check total descriptor number and descriptor queue
        if(list_mm_format_ch2.list_ready && (list_mm_format_ch2.desp_mm_q.size != list_mm_format_ch2.total_desp_num))begin
            `uvm_error(get_type_name(), $psprintf("Get a number of %d descriptors that not match the total descriptor number of %d for channel 2!", list_mm_format_ch2.desp_mm_q.size, list_mm_format_ch2.total_desp_num))
        end
        //Exist descriptors not checked in the list
        if(!(list_mm_format_ch2.list_ready && (list_mm_format_ch2.chk_desp_num == list_mm_format_ch2.total_desp_num)))begin
            //Check write back descriptor number
            if(data[15:0] > list_mm_format_ch2.desp_mm_q.size)begin
                `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor number is %d for channel 2!", data[15:0], list_mm_format_ch2.desp_mm_q.size))
            end
            //New write back descriptor check number
            if(data[15:0] > list_mm_format_ch2.chk_desp_num)begin
                //Check dma data
                for(int i=0; i<(data[15:0]-list_mm_format_ch2.chk_desp_num); i++)begin
                    if(list_mm_format_ch2.desp_mm_q.size < (list_mm_format_ch2.chk_desp_num+i+1))begin
                        `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor queue size is %d and the checked descriptor number is %d for channel 2!"
                        , data[15:0], list_mm_format_ch2.desp_mm_q.size, list_mm_format_ch2.chk_desp_num))
                    end
                    `uvm_info(tID, $sformatf("Check data for channel 2."), UVM_LOW)                    
                    check_dma_data(2, list_mm_format_ch2.h2a_a2h, list_mm_format_ch2.desp_mm_q[list_mm_format_ch2.chk_desp_num+i]);
                end
                //Set list done
                if(list_mm_format_ch2.list_ready && (data[15:0] == list_mm_format_ch2.total_desp_num))begin
                    list_mm_format_ch2.list_done=1;
                    list_num_ch2++;
                end
                list_mm_format_ch2.chk_desp_num=data[15:0];
            end
        end
    end
    //Check channel 3
    if((list_mm_format_ch3.list_done == 0) && (address == list_mm_format_ch3.wr_back_adr))begin
        `uvm_info(tID, $sformatf("Get write back data of 0x%4h for channel 3.", data[15:0]), UVM_LOW)
        //Check total descriptor number and descriptor queue
        if(list_mm_format_ch3.list_ready && (list_mm_format_ch3.desp_mm_q.size != list_mm_format_ch3.total_desp_num))begin
            `uvm_error(get_type_name(), $psprintf("Get a number of %d descriptors that not match the total descriptor number of %d for channel 3!", list_mm_format_ch3.desp_mm_q.size, list_mm_format_ch3.total_desp_num))
        end
        //Exist descriptors not checked in the list
        if(!(list_mm_format_ch3.list_ready && (list_mm_format_ch3.chk_desp_num == list_mm_format_ch3.total_desp_num)))begin
            //Check write back descriptor number
            if(data[15:0] > list_mm_format_ch3.desp_mm_q.size)begin
                `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor number is %d for channel 3!", data[15:0], list_mm_format_ch3.desp_mm_q.size))
            end
            //New write back descriptor check number
            if(data[15:0] > list_mm_format_ch3.chk_desp_num)begin
                //Check dma data
                for(int i=0; i<(data[15:0]-list_mm_format_ch3.chk_desp_num); i++)begin
                    if(list_mm_format_ch3.desp_mm_q.size < (list_mm_format_ch3.chk_desp_num+i+1))begin
                        `uvm_error(get_type_name(), $psprintf("Get an illegal write back number of %4h when the descriptor queue size is %d and the checked descriptor number is %d for channel 3!"
                        , data[15:0], list_mm_format_ch3.desp_mm_q.size, list_mm_format_ch3.chk_desp_num))
                    end
                    `uvm_info(tID, $sformatf("Check data for channel 3."), UVM_LOW)                    
                    check_dma_data(3, list_mm_format_ch3.h2a_a2h, list_mm_format_ch3.desp_mm_q[list_mm_format_ch3.chk_desp_num+i]);
                end
                //Set list done
                if(list_mm_format_ch3.list_ready && (data[15:0] == list_mm_format_ch3.total_desp_num))begin
                    list_mm_format_ch3.list_done=1;
                    list_num_ch3++;
                end
                list_mm_format_ch3.chk_desp_num=data[15:0];
            end
        end
    end
endfunction : check_write_back_data

//Check DMA data
function void odma_check_scoreboard::check_dma_data(int chnl_num, bit direction, odma_desp_transaction desp_item);
    //H2A
    if(direction == 0)begin
    `ifndef ENABLE_ODMA_ST_MODE
        for(int i=0; i<desp_item.length; i++)begin
            if(!brdg_read_memory.exists(desp_item.src_adr+i))begin
                `uvm_error(get_type_name(), $psprintf("H2A: Not found a match afu-tlx read command of address 0x%16h for the descriptor:\n%s", desp_item.src_adr+i, desp_item.sprint()))
            end
            if(!axi_write_memory.exists(desp_item.dst_adr+i))begin
                `uvm_error(get_type_name(), $psprintf("H2A: Not found a match axi write command of address 0x%16h for the descriptor:\n%s", desp_item.dst_adr+i, desp_item.sprint()))
            end
            if(brdg_read_memory[desp_item.src_adr+i] != axi_write_memory[desp_item.dst_adr+i])begin
                `uvm_error(get_type_name(), $psprintf("H2A: Data mismatch in the src_adr=0x%16h with data=0x%2h, dst_adr=0x%16h with data=0x%2h, for the descriptor:\n%s", desp_item.src_adr+i, brdg_read_memory[desp_item.src_adr+i], desp_item.dst_adr+i, axi_write_memory[desp_item.dst_adr+i], desp_item.sprint()))                    
            end
        end
        `uvm_info(tID, $sformatf("H2A: Data check successfully for the descriptor:\n%s", desp_item.sprint()), UVM_MEDIUM)
    `else
        //Check collected data from AXI-Stream interface
        if(st_h2a_data[chnl_num].data_queue.size == 0)begin
             `uvm_error(tID, $sformatf("H2A channel %d dose not get any data from AXI-Stream interface for descriptor:\n%s.", chnl_num, desp_item.sprint()))
        end
        //For the EOP descriptor
        if(desp_item.st_eop == 1)begin
            //Check data length
            if((st_h2a_data[chnl_num].st_byte_num_queue.size > 0) && (st_h2a_data[chnl_num].st_byte_num_queue[0] == (st_h2a_data[chnl_num].desp_byte_num+desp_item.length)))begin
                for(int i=0; i<desp_item.length; i++)begin
                    if(!brdg_read_memory.exists(desp_item.src_adr+i))begin
                        `uvm_error(get_type_name(), $psprintf("H2A Channel %d: Not found a match afu-tlx read command of address 0x%16h for the descriptor:\n%s", chnl_num, desp_item.src_adr+i, desp_item.sprint()))
                    end
                    if(st_h2a_data[chnl_num].data_queue[0] != brdg_read_memory[desp_item.src_adr+i])begin
                        `uvm_error(get_type_name(), $psprintf("H2A Channel %d: Stream data mismatch in the src_adr=0x%16h with host data=0x%2h, AXI stream data=0x%2h. The descriptor:\n%s", chnl_num, desp_item.src_adr+i, brdg_read_memory[desp_item.src_adr+i], st_h2a_data[chnl_num].data_queue[0], desp_item.sprint()))
                    end
                    void'(st_h2a_data[chnl_num].data_queue.pop_front());
                end
                st_h2a_data[chnl_num].desp_byte_num=0;
                void'(st_h2a_data[chnl_num].st_byte_num_queue.pop_front());
                `uvm_info(tID, $sformatf("H2A Channel %d: Data check successfully for the EOP descriptor:\n%s", chnl_num, desp_item.sprint()), UVM_LOW)
            end
            else begin
                `uvm_error(tID, $sformatf("H2A channel %d: byte number not match! AXI stream has a number of %d bytes while the EOP despcriptor has a length of %d bytes.", chnl_num, st_h2a_data[chnl_num].st_byte_num_queue[0], st_h2a_data[chnl_num].desp_byte_num+desp_item.length))
            end
        end
        //Not the EOP descriptor
        else begin
            //Check data length
            if((st_h2a_data[chnl_num].data_queue.size > 0) && (st_h2a_data[chnl_num].data_queue.size >= desp_item.length))begin
                for(int i=0; i<desp_item.length; i++)begin
                    if(!brdg_read_memory.exists(desp_item.src_adr+i))begin
                        `uvm_error(get_type_name(), $psprintf("H2A Channel %d: Not found a match afu-tlx read command of address 0x%16h for the descriptor:\n%s", chnl_num, desp_item.src_adr+i, desp_item.sprint()))
                    end
                    if(st_h2a_data[chnl_num].data_queue[0] != brdg_read_memory[desp_item.src_adr+i])begin
                        `uvm_error(get_type_name(), $psprintf("H2A Channel %d: Stream data mismatch in the src_adr=0x%16h with host data=0x%2h, AXI stream data=0x%2h. The descriptor:\n%s", chnl_num, desp_item.src_adr+i, brdg_read_memory[desp_item.src_adr+i], st_h2a_data[chnl_num].data_queue[0], desp_item.sprint()))
                    end
                    void'(st_h2a_data[chnl_num].data_queue.pop_front());
                end
                st_h2a_data[chnl_num].desp_byte_num+=desp_item.length;
            end
            else begin
                `uvm_error(tID, $sformatf("H2A channel %d: byte number not match! AXI stream has a number of %d bytes while the despcriptor has a length of %d bytes.", chnl_num, st_h2a_data[chnl_num].data_queue.size, desp_item.length))
            end
        end
    `endif
    end
    //A2H
    else begin
    `ifndef ENABLE_ODMA_ST_MODE
        for(int i=0; i<desp_item.length; i++)begin
            if(!axi_read_memory.exists(desp_item.src_adr+i))begin
                `uvm_error(get_type_name(), $psprintf("A2H: Not found a match axi read command of address 0x%16h for the descriptor:\n%s", desp_item.src_adr+i, desp_item.sprint()))
            end
            if(!brdg_write_memory.exists(desp_item.dst_adr+i))begin
                `uvm_error(get_type_name(), $psprintf("A2H: Not found a match afu-tlx write command of address 0x%16h for the descriptor:\n%s", desp_item.dst_adr+i, desp_item.sprint()))
            end
            if(brdg_write_memory[desp_item.dst_adr+i] != axi_read_memory[desp_item.src_adr+i])begin
                `uvm_error(get_type_name(), $psprintf("A2H: Data mismatch in the src_adr=0x%16h with data=0x%2h, dst_adr=0x%16h with data=0x%2h, for the descriptor:\n%s", desp_item.src_adr+i, axi_read_memory[desp_item.src_adr+i], desp_item.dst_adr+i, brdg_write_memory[desp_item.dst_adr+i], desp_item.sprint()))                    
            end
        end
        `uvm_info(tID, $sformatf("A2H: Data check successfully for the descriptor:\n%s", desp_item.sprint()), UVM_MEDIUM)
    `else
        //Check collected data from AXI-Stream interface
        if(st_a2h_data[chnl_num].data_queue.size == 0)begin
             `uvm_error(tID, $sformatf("A2H channel %d: dose not get any data from AXI-Stream interface for descriptor:\n%s.", chnl_num, desp_item.sprint()))
        end
        //For the EOP descriptor
        if(desp_item.st_eop == 1)begin
            //Check data length
            if((st_a2h_data[chnl_num].st_byte_num_queue.size > 0) && (st_a2h_data[chnl_num].st_byte_num_queue[0] == (st_a2h_data[chnl_num].desp_byte_num+desp_item.length)))begin
                for(int i=0; i<desp_item.length; i++)begin
                    if(!brdg_write_memory.exists(desp_item.dst_adr+i))begin
                        `uvm_error(get_type_name(), $psprintf("A2H Channel %d: Not found a match afu-tlx write command of address 0x%16h for the descriptor:\n%s", chnl_num, desp_item.dst_adr+i, desp_item.sprint()))
                    end
                    if(st_a2h_data[chnl_num].data_queue[0] != st_a2h_data[chnl_num].data_queue[0])begin
                        `uvm_error(get_type_name(), $psprintf("A2H Channel %d: Stream data mismatch in the dst_adr=0x%16h with host data=0x%2h, AXI stream data=0x%2h. The descriptor:\n%s", chnl_num, desp_item.dst_adr+i, brdg_write_memory[desp_item.dst_adr+i], st_a2h_data[chnl_num].data_queue[0], desp_item.sprint()))
                    end
                    void'(st_a2h_data[chnl_num].data_queue.pop_front());
                end
                st_a2h_data[chnl_num].desp_byte_num=0;
                void'(st_a2h_data[chnl_num].st_byte_num_queue.pop_front());
                `uvm_info(tID, $sformatf("A2H Channel %d: Data check successfully for the EOP descriptor:\n%s", chnl_num, desp_item.sprint()), UVM_LOW)
            end
            else begin
                `uvm_error(tID, $sformatf("A2H channel %d: byte number not match! AXI stream has a number of %d while the EOP despcriptor has a length of %d.", chnl_num, st_a2h_data[chnl_num].st_byte_num_queue[0], st_a2h_data[chnl_num].desp_byte_num+desp_item.length))
            end
        end
        //Not the EOP descriptor
        else begin
            //Check data length
            if((st_a2h_data[chnl_num].data_queue.size > 0) && (st_a2h_data[chnl_num].data_queue.size >= desp_item.length))begin
                for(int i=0; i<desp_item.length; i++)begin
                    if(!brdg_write_memory.exists(desp_item.dst_adr+i))begin
                        `uvm_error(get_type_name(), $psprintf("A2H Channel %d: Not found a match afu-tlx write command of address 0x%16h for the descriptor:\n%s", chnl_num, desp_item.dst_adr+i, desp_item.sprint()))
                    end
                    if(st_a2h_data[chnl_num].data_queue[0] != brdg_write_memory[desp_item.dst_adr+i])begin
                        `uvm_error(get_type_name(), $psprintf("A2H Channel %d: Stream data mismatch in the dst_adr=0x%16h with host data=0x%2h, AXI stream data=0x%2h. The descriptor:\n%s", chnl_num, desp_item.dst_adr+i, brdg_write_memory[desp_item.dst_adr+i], st_a2h_data[chnl_num].data_queue[0], desp_item.sprint()))
                    end
                    void'(st_a2h_data[chnl_num].data_queue.pop_front());
                end
                st_a2h_data[chnl_num].desp_byte_num+=desp_item.length;
            end
            else begin
                `uvm_error(tID, $sformatf("A2H channel %d: byte number not match! AXI stream has a number of %d while the despcriptor has a length of %d.", chnl_num, st_a2h_data[chnl_num].data_queue.size, desp_item.length))
            end
        end
    `endif
    end
endfunction : check_dma_data

//Check list status for each channel when list stop
function void odma_check_scoreboard::check_list_chnnl(int channel);
    case(channel)
        0:begin
            if(!list_mm_format_ch0.list_ready)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_ready is 0 for channel 0!"))                    
            end
            if(!list_mm_format_ch0.list_done)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_done is 0 for channel 0!"))                    
            end
            if(list_mm_format_ch0.chk_desp_num != list_mm_format_ch0.total_desp_num)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when chk_desp_num=%d, total_desp_num=%d for channel 0!", list_mm_format_ch0.chk_desp_num, list_mm_format_ch0.total_desp_num))                    
            end
            reset_list_chnnl(0);
        end
        1:begin
            if(!list_mm_format_ch1.list_ready)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_ready is 0 for channel 1!"))                    
            end
            if(!list_mm_format_ch1.list_done)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_done is 0 for channel 1!"))                    
            end
            if(list_mm_format_ch1.chk_desp_num != list_mm_format_ch1.total_desp_num)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when chk_desp_num=%d, total_desp_num=%d for channel 1!", list_mm_format_ch1.chk_desp_num, list_mm_format_ch1.total_desp_num))                    
            end
            reset_list_chnnl(1);
        end
        2:begin
            if(!list_mm_format_ch2.list_ready)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_ready is 0 for channel 2!"))                    
            end
            if(!list_mm_format_ch2.list_done)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_done is 0 for channel 2!"))                    
            end
            if(list_mm_format_ch2.chk_desp_num != list_mm_format_ch2.total_desp_num)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when chk_desp_num=%d, total_desp_num=%d for channel 2!", list_mm_format_ch2.chk_desp_num, list_mm_format_ch2.total_desp_num))                    
            end
            reset_list_chnnl(2);
        end
        3:begin
            if(!list_mm_format_ch3.list_ready)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_ready is 0 for channel 3!"))                    
            end
            if(!list_mm_format_ch3.list_done)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when list_done is 0 for channel 3!"))                    
            end
            if(list_mm_format_ch3.chk_desp_num != list_mm_format_ch3.total_desp_num)begin
                `uvm_error(get_type_name(), $psprintf("Get an unexpected stop when chk_desp_num=%d, total_desp_num=%d for channel 3!", list_mm_format_ch3.chk_desp_num, list_mm_format_ch3.total_desp_num))                    
            end
            reset_list_chnnl(3);
        end
        default:
            `uvm_error(get_type_name(), $psprintf("Get an illegal channel number!"))
    endcase
endfunction : check_list_chnnl

//Reset list status for each channel
function void odma_check_scoreboard::reset_list_chnnl(int channel);
    case(channel)
        0:begin
            list_mm_format_ch0.list_ready=0;
            list_mm_format_ch0.block_desp_num=0;
            list_mm_format_ch0.chk_desp_num=0;
            list_mm_format_ch0.total_desp_num=0;
            list_mm_format_ch0.wr_back_adr=0;
            list_mm_format_ch0.desp_head_addr.delete();
            list_mm_format_ch0.block_length.delete();
            list_mm_format_ch0.desp_mm_q.delete();
        end
        1:begin
            list_mm_format_ch1.list_ready=0;
            list_mm_format_ch1.block_desp_num=0;
            list_mm_format_ch1.chk_desp_num=0;
            list_mm_format_ch1.total_desp_num=0;
            list_mm_format_ch1.wr_back_adr=0;
            list_mm_format_ch1.desp_head_addr.delete();
            list_mm_format_ch1.block_length.delete();
            list_mm_format_ch1.desp_mm_q.delete();
        end
        2:begin
            list_mm_format_ch2.list_ready=0;
            list_mm_format_ch2.block_desp_num=0;
            list_mm_format_ch2.chk_desp_num=0;
            list_mm_format_ch2.total_desp_num=0;
            list_mm_format_ch2.wr_back_adr=0;
            list_mm_format_ch2.desp_head_addr.delete();
            list_mm_format_ch2.block_length.delete();
            list_mm_format_ch2.desp_mm_q.delete();
        end
        3:begin
            list_mm_format_ch3.list_ready=0;
            list_mm_format_ch3.block_desp_num=0;
            list_mm_format_ch3.chk_desp_num=0;
            list_mm_format_ch3.total_desp_num=0;
            list_mm_format_ch3.wr_back_adr=0;
            list_mm_format_ch3.desp_head_addr.delete();
            list_mm_format_ch3.block_length.delete();
            list_mm_format_ch3.desp_mm_q.delete();
        end
        default:
            `uvm_error(get_type_name(), $psprintf("Get an illegal channel number!"))
    endcase
endfunction : reset_list_chnnl

//Push data into stream data queue
function void odma_check_scoreboard::push_st_data(int channel, bit direction, axi_st_transaction axi_st_tran);
    //H2A
    if(direction)begin
        for(int i=0; i<`AXI_ST_DW/8; i++)begin
            if(axi_st_tran.tkeep[i])
                st_h2a_data[channel].data_queue.push_back(axi_st_tran.data[8*i+7-:8]);
        end
    end
    //A2H
    else begin
        for(int i=0; i<`AXI_ST_DW/8; i++)begin
            if(axi_st_tran.tkeep[i])
                st_a2h_data[channel].data_queue.push_back(axi_st_tran.data[8*i+7-:8]);
        end
    end
endfunction : push_st_data

//Get the number of tkeep
function int odma_check_scoreboard::get_tkeek_num(axi_st_transaction axi_st_tran);
    for(int i=0; i<`AXI_ST_DW/8; i++)begin
        if(axi_st_tran.tkeep[i])
            get_tkeek_num++;
    end
endfunction : get_tkeek_num

`endif

