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
`ifndef _TL_MEM_MODEL
`define _TL_MEM_MODEL

typedef class resp_packet;

class tl_mem_model extends uvm_object;

    `uvm_object_utils_begin(tl_mem_model)
    `uvm_object_utils_end

    typedef struct{bit [7:0] byte_data;
                   bit data_exist;
                   bit itag;
                   bit mdi;
                   bit [71:0] xmeta;
                   bit sue;
                   bit mdi_valid;
                   bit bad_data;
                  } byte_packet;


    typedef byte_packet byte_packet_array[256];
    
    bit readable_tag[longint unsigned];
    bit writable_tag[longint unsigned];
    bit [15:0] blocking_capptag_w[longint unsigned];
    bit [15:0] blocking_capptag_r[longint unsigned];
    byte_packet memory_model[longint unsigned];

    function new(string name="tl_mem_model");
        super.new(name);
    endfunction: new
    
    function byte_packet read_byte(longint unsigned addr);
        return memory_model[addr];
    endfunction: read_byte

    function bit exist_byte(longint unsigned addr);
        if(memory_model.exists(addr))
            return 1;
        else
            return 0;
    endfunction: exist_byte

    function void print_mem();
        foreach(memory_model[i])
            $display("Memory addr:%h,data:%h,data_exist:%h,itag:%h,mdi:%h,mdi_valid:%h,sue:%h,xmeta:%h", i, memory_model[i].byte_data,memory_model[i].data_exist,memory_model[i].itag,memory_model[i].mdi,memory_model[i].mdi_valid,memory_model[i].sue,memory_model[i].xmeta);
    endfunction: print_mem

    function void memory_update_by_write_cmd(tl_tx_trans write_cmd,tl_cfg_obj cfg_obj,resp_packet write_resp_packet=null);
        tl_tx_trans write_cmd_item;
        longint unsigned temp_addr;
        int unsigned byte_num;    
        byte_packet abstracted_byte_packet[256];
        $cast(write_cmd_item,write_cmd.clone());
   
        abstracted_byte_packet=abstract_from_write_cmd(write_cmd_item, cfg_obj.metadata_enable);
        temp_addr=write_cmd_item.physical_addr;

        case (write_cmd_item.packet_type)
            tl_tx_trans::WRITE_MEM : begin
                bit write_sue_with_diff_mdi=0;
                case (write_cmd_item.dlength)
                    2'b01: byte_num=64;
                    2'b10: byte_num=128;
                    2'b11: byte_num=256;
                    default:begin
                        byte_num=32;
                        `uvm_info(get_type_name(),"Reservered dlength of WRITE_MEM",UVM_MEDIUM)
                    end
                endcase
                for(int i=0; i<byte_num; i++) begin
                    if(write_resp_packet.write_success_record[i]==1)begin
                        memory_model[temp_addr].byte_data=abstracted_byte_packet[i].byte_data;
                        memory_model[temp_addr].data_exist=1;
                        memory_model[temp_addr].itag=abstracted_byte_packet[i].itag;
                        if((abstracted_byte_packet[i].bad_data==1)||(((i%64)<32)&&(abstracted_byte_packet[i+32].bad_data==1))||(((i%64)>31)&&(abstracted_byte_packet[i-32].bad_data==1))) begin
                            memory_model[temp_addr].sue=1;
                            memory_model[temp_addr].mdi_valid=0;
                        end
                        else if((((i%64)<32)&&(abstracted_byte_packet[i].mdi!=abstracted_byte_packet[i+32].mdi))||(((i%64)>31)&&(abstracted_byte_packet[i].mdi!=abstracted_byte_packet[i-32].mdi))) begin
                            memory_model[temp_addr].sue=1;
                            memory_model[temp_addr].mdi_valid=1;
                            write_sue_with_diff_mdi=1;
                        end
                        else begin
                            memory_model[temp_addr].sue=0;
                            memory_model[temp_addr].mdi_valid=1;
                        end
                        memory_model[temp_addr].mdi=abstracted_byte_packet[i].mdi;
                    end
                    temp_addr++;
                end
                if(write_sue_with_diff_mdi==1)
                    `uvm_warning(get_type_name(),$sformatf("Writting sue with mdi[0]!=mdi[1], original cmd is:\n%s",write_cmd_item.sprint()))
            end

            tl_tx_trans::CONFIG_WRITE :;

            tl_tx_trans::PR_WR_MEM : begin      //PR_WR_MEM classified into several types.
                case (write_cmd_item.plength)
                    3'b000: byte_num=1;
                    3'b001: byte_num=2;
                    3'b010: byte_num=4;
                    3'b011: byte_num=8;
                    3'b100: byte_num=16;
                    3'b101: byte_num=32;
                    3'b110: byte_num=4;
                    3'b111: byte_num=8;
                endcase
                if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)))begin
                    if(write_cmd_item.physical_addr[63:35]!=cfg_obj.mmio_space_base[63:35]) begin//in sysmem space
                        for(int i=0; i<byte_num; i++) begin     //update byte_data
                            memory_model[temp_addr+i].byte_data=abstracted_byte_packet[i].byte_data;
                            memory_model[temp_addr+i].data_exist=1;
                        end
                        if((abstracted_byte_packet[0].bad_data==1)||(memory_model[temp_addr].sue==1)) begin   // bad data indicated or already in memory.
                            temp_addr[5:0]=0;
                            for(int i=0; i<64; i++)begin           //set the meta data for the entire 64B block
                                memory_model[temp_addr+i].itag=0;
                                memory_model[temp_addr+i].sue=1;
                                memory_model[temp_addr+i].mdi_valid=1;
                                if(i<32)
                                    memory_model[temp_addr+i].mdi=0;
                                else
                                    memory_model[temp_addr+i].mdi=1;
                            end
                        end
                        else begin            // not bad data
                            temp_addr[5:0]=0;
                            for(int i=0; i<64; i++)begin           // clear the meta data for the entire 64 B block
                                memory_model[temp_addr+i].itag=0;
                                memory_model[temp_addr+i].mdi=0;
                                memory_model[temp_addr+i].sue=0;
                                memory_model[temp_addr+i].mdi_valid=1;
                            end
                        end
                    end
                end
                else begin     // in half_dimm_mode
                    if(write_cmd_item.physical_addr[63:35]!=cfg_obj.mmio_space_base[63:35]) begin//in sysmem space
                        if(write_cmd_item.physical_addr!=cfg_obj.mmio_space_base-32)  begin 
                            for(int i=0; i<byte_num; i++) begin     //update byte_data
                                memory_model[temp_addr+i].byte_data=abstracted_byte_packet[i].byte_data;
                                memory_model[temp_addr+i].data_exist=1;
                                memory_model[temp_addr+i].xmeta=abstracted_byte_packet[i].xmeta;
                            end
                        end
                    end
                end
            end
            tl_tx_trans::WRITE_MEM_BE :begin  
                byte_num=64;
                for(int i=0; i<byte_num; i++) begin
                    if(write_cmd_item.byte_enable[i]==1)begin
                        memory_model[temp_addr+i].byte_data=abstracted_byte_packet[i].byte_data;
                        memory_model[temp_addr+i].data_exist=1;
                    end
                    memory_model[temp_addr+i].itag=0;
                    memory_model[temp_addr+i].mdi=0;                    
                    if((abstracted_byte_packet[0].bad_data==1)||(memory_model[temp_addr].sue==1)) begin   // bad data indicated or already in memory
                        memory_model[temp_addr+i].sue=1;
                        memory_model[temp_addr+i].mdi_valid=0;
                    end
                end
            end
            tl_tx_trans::PAD_MEM : begin
                byte_num=32;
                for(int i=0; i<byte_num; i++) begin
                    memory_model[temp_addr+i].byte_data=cfg_obj.data_pattern[i];
                    memory_model[temp_addr+i].data_exist=1;
                    memory_model[temp_addr+i].xmeta=cfg_obj.data_pattern_xmeta;
                end
            end                    
            default: `uvm_error(get_type_name(),"Unkown cmd tends to update memory_model")
        endcase
    endfunction: memory_update_by_write_cmd

    function void memory_update_by_read_cmd(tl_tx_trans read_cmd, resp_packet read_resp_packet);
        longint unsigned temp_addr;
        temp_addr=read_cmd.physical_addr;
        case(read_cmd.packet_type)
            tl_tx_trans::RD_MEM : begin
                for(int i=0; i<read_resp_packet.byte_number_filled; i++) begin
                    if(read_resp_packet.read_success_record[i]==1)begin
                        memory_model[temp_addr+i].byte_data=read_resp_packet.data_bytewise[i].byte_data;
                        memory_model[temp_addr+i].data_exist=1;
                        memory_model[temp_addr+i].itag=read_resp_packet.data_bytewise[i].itag;
                        memory_model[temp_addr+i].mdi=read_resp_packet.data_bytewise[i].mdi;
                        memory_model[temp_addr+i].sue=read_resp_packet.data_bytewise[i].sue;
                        memory_model[temp_addr+i].mdi_valid=1;
                    end
                end
            end
            tl_tx_trans::PR_RD_MEM : begin
                for(int i=0; i<read_resp_packet.byte_number_filled; i++) begin
                    if(read_resp_packet.read_success_record[i]==1)begin
                        memory_model[temp_addr+i].byte_data=read_resp_packet.data_bytewise[i].byte_data;
                        memory_model[temp_addr+i].data_exist=1;
                        memory_model[temp_addr+i].itag=read_resp_packet.data_bytewise[i].itag;
                        memory_model[temp_addr+i].mdi=read_resp_packet.data_bytewise[i].mdi;
                        memory_model[temp_addr+i].xmeta=read_resp_packet.data_bytewise[i].xmeta;
                        memory_model[temp_addr+i].mdi_valid=1;
                    end
                end
                if(memory_model[temp_addr].sue==1)begin   //sue was alread in this 64B block
                    bit [63:0] temp_addr_other_half;
                    if(temp_addr[5]==1)
                        temp_addr_other_half={temp_addr[63:6],6'd0};
                    else
                        temp_addr_other_half=temp_addr+32;
                    for(int i=0; i<32; i++) begin
                        memory_model[temp_addr_other_half+i].mdi_valid=1;
                        memory_model[temp_addr_other_half+i].mdi=(!memory_model[temp_addr].mdi);
                    end
                end
            end                    
        endcase
    endfunction: memory_update_by_read_cmd

    function void rst_readable_tag(longint unsigned addr, int data_length, bit [15:0] capptag);
        for(int i=0; i<data_length; i++) begin
            readable_tag[addr+i]=1;
            blocking_capptag_w[addr+i]=capptag;
        end
    endfunction: rst_readable_tag


    function void rst_writable_tag(longint unsigned addr, int data_length, bit [15:0] capptag);
        for(int i=0; i<data_length; i++) begin
            writable_tag[addr+i]=1;
            blocking_capptag_r[addr+i]=capptag;
        end
    endfunction: rst_writable_tag



    function void set_readable_tag(tl_tx_trans write_cmd, bit half_dimm_mode=0);
        int unsigned byte_num;
        longint unsigned temp_addr;
        tl_tx_trans write_cmd_item;
        $cast(write_cmd_item,write_cmd.clone());
        temp_addr=write_cmd_item.physical_addr;
        case (write_cmd_item.packet_type)
            tl_tx_trans::CONFIG_WRITE:;
            tl_tx_trans::PR_WR_MEM : begin
                if(half_dimm_mode==1)begin
                    byte_num=32;
                    temp_addr[4:0]=0;
                end
                else begin
                    byte_num=64;
                    temp_addr[5:0]=0;
                end
            end
            tl_tx_trans::WRITE_MEM : begin
                case(write_cmd_item.dlength)
                    3'd0:begin
                        if(half_dimm_mode==1)
                            byte_num=32;
                        else
                            byte_num=64;
                    end
                    3'd1:begin
                        byte_num=64;
                    end
                    3'd2:begin
                        byte_num=128;
                        temp_addr[6:0]=0;
                    end
                    3'd3:begin
                        byte_num=256;
                        temp_addr[7:0]=0;
                    end
                endcase
            end
            tl_tx_trans::WRITE_MEM_BE : begin
                byte_num=64;
            end
            tl_tx_trans::PAD_MEM : begin
                case(write_cmd_item.dlength)
                    2'd0:begin
                        if(half_dimm_mode==1) begin
                            byte_num=32;
                        end
                        else
                            byte_num=64;
                    end
                    2'd1:begin
                        byte_num=64;
                        temp_addr[5:0]=0;
                    end
                    2'd2:begin
                        byte_num=128;
                        temp_addr[6:0]=0;
                    end
                    2'd3:begin
                        byte_num=256;
                        temp_addr[7:0]=0;
                    end
                endcase
            end
            default: `uvm_error(get_type_name(),"Unkown cmd tends to set_readable_tag")
        endcase
        for(int i=0;i<byte_num;i++) begin
            if(blocking_capptag_w.exists(temp_addr))begin
                if(write_cmd_item.capp_tag==blocking_capptag_w[temp_addr])begin
                    readable_tag.delete(temp_addr);
                    blocking_capptag_w.delete(temp_addr);
                end
            end
            temp_addr++;
        end        
    endfunction: set_readable_tag

    function void set_writable_tag(tl_tx_trans read_cmd, bit half_dimm_mode);
        int unsigned byte_num;
        longint unsigned temp_addr;
        tl_tx_trans read_cmd_item;
        $cast(read_cmd_item,read_cmd.clone());
        temp_addr=read_cmd_item.physical_addr;
        case (read_cmd_item.packet_type)
            tl_tx_trans::CONFIG_READ:;
            tl_tx_trans::PR_RD_MEM : begin
                if(half_dimm_mode==1)begin
                    byte_num=32;
                    temp_addr[4:0]=0;
                end
                else begin
                    byte_num=64;
                    temp_addr[4:0]=0;
                end
                for(int i=0;i<byte_num;i++) begin
                    if(blocking_capptag_r.exists(temp_addr))begin
                        if(read_cmd_item.capp_tag==blocking_capptag_r[temp_addr])begin
                            writable_tag.delete(temp_addr);
                            blocking_capptag_r.delete(temp_addr);
                        end
                    end
                    temp_addr++;
                end
            end
            tl_tx_trans::RD_MEM : begin
                case(read_cmd_item.dlength)
                    3'd0:begin
                        if(half_dimm_mode==1)
                            byte_num=32;
                        else
                            byte_num=64;
                    end
                    3'd1:begin
                        byte_num=64;
                        temp_addr[5:0]=0;
                    end
                    3'd2:begin
                        byte_num=128;
                        temp_addr[6:0]=0;
                    end
                    3'd3:begin
                        byte_num=256;
                        temp_addr[7:0]=0;
                    end
                endcase
                for(int i=0;i<byte_num;i++) begin
                    if(blocking_capptag_r.exists(temp_addr))begin
                        if(read_cmd_item.capp_tag==blocking_capptag_r[temp_addr])begin
                            writable_tag.delete(temp_addr);
                            blocking_capptag_r.delete(temp_addr);
                        end
                    end
                    temp_addr++;
                end
            end
            default: `uvm_error(get_type_name(),"Unkown cmd tends to set_writable_tag")
        endcase
    endfunction: set_writable_tag


    function bit check_readable_tag(longint unsigned addr, int data_length);
        bit readable=1;
        for(int i=0; i<data_length; i++) begin
            if(readable_tag.exists(addr+i)) begin
                readable=0;
                break;
            end
        end
        return readable;
    endfunction: check_readable_tag

    function bit check_writable_tag(longint unsigned addr, int data_length);
        bit writable=1;
        for(int i=0; i<data_length; i++) begin
            if(writable_tag.exists(addr+i)) begin
                writable=0;
                break;
            end
        end
        return writable;
    endfunction: check_writable_tag

    function byte_packet_array abstract_from_write_cmd(tl_tx_trans write_cmd_raw, bit metadata_enable);
        tl_tx_trans write_cmd;
        byte_packet abstracted_byte_packet[256];
        $cast(write_cmd,write_cmd_raw.clone());
        if(metadata_enable==0)begin         //metadata disabled, sue won't be written
            for(int i=0; i<32; i++ )begin
                write_cmd.meta[i]=0;
                write_cmd.data_error[i]=0;
            end
        end
        case (write_cmd.packet_type)
            tl_tx_trans::CONFIG_WRITE, tl_tx_trans::PR_WR_MEM, tl_tx_trans::WRITE_MEM_BE:begin
                for(int i=0;i<8;i++)begin
                    for(int j=0; j<8;j++)begin
                        abstracted_byte_packet[i*8+j].byte_data=write_cmd.data_carrier[i][(j*8+7) -:8];
                        abstracted_byte_packet[i*8+j].xmeta=write_cmd.xmeta[i];
                        abstracted_byte_packet[i*8+j].bad_data=write_cmd.data_error[i][0];
                        case(i)
                        0,1:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][0];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][2];
                        end
                        2,3:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][1];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][2];
                        end
                        4,5:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][3];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][5];
                        end
                        6,7:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][4];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][5];
                        end
                        endcase
                    end
                end
                case (write_cmd.data_carrier_type)
                    32:begin
                        bit [4:0] sr_byte_num=write_cmd.physical_addr[4:0];
                        for(int k=0; k<(256-sr_byte_num);k++)
                                abstracted_byte_packet[k]=abstracted_byte_packet[k+sr_byte_num];
                    end
                    64:begin
                        bit [5:0] sr_byte_num=write_cmd.physical_addr[5:0];
                        for(int k=0; k<(256-sr_byte_num);k++)
                                abstracted_byte_packet[k]=abstracted_byte_packet[k+sr_byte_num];
                    end
                    default: `uvm_error(get_type_name(),"Unsupported data_carrier_type")
                endcase
            end
            tl_tx_trans::WRITE_MEM :begin
                for(int i=0;i<32;i++)begin
                    for(int j=0; j<8;j++)begin
                        int k=(i % 8);
                        abstracted_byte_packet[i*8+j].byte_data=write_cmd.data_carrier[i][(j*8+7) -:8];
                        abstracted_byte_packet[i*8+j].bad_data=write_cmd.data_error[i][0];
                        case(k)
                        0,1:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][0];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][2];
                        end
                        2,3:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][1];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][2];
                        end
                        4,5:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][3];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][5];
                        end
                        6,7:begin
                            abstracted_byte_packet[i*8+j].itag=write_cmd.meta[i][4];
                            abstracted_byte_packet[i*8+j].mdi=write_cmd.meta[i][5];
                        end
                        endcase
                    end
                end
            end
            tl_tx_trans::PAD_MEM:begin    //no data need to be abstracted for pad_mem
            end
            default: `uvm_error(get_type_name(),"Unkown write cmd tends to abstract data")
        endcase
        return abstracted_byte_packet;
    endfunction :abstract_from_write_cmd

    function byte_packet_array abstract_from_read_resp(tl_tx_trans read_cmd, tl_rx_trans read_resp);
        byte_packet abstracted_byte_packet[256];
        if(read_resp.packet_type!=tl_rx_trans::MEM_RD_FAIL)begin
            case (read_cmd.packet_type)
                tl_tx_trans::CONFIG_READ, tl_tx_trans::PR_RD_MEM:begin
                    for(int i=0;i<8;i++)begin
                        for(int j=0; j<8;j++)begin
                            abstracted_byte_packet[i*8+j].byte_data=read_resp.data_carrier[i][(j*8+7) -:8];
                            abstracted_byte_packet[i*8+j].xmeta=read_resp.xmeta[i];
                            case(i)
                            0,1:begin
                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][0];
                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                            end
                            2,3:begin
                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][1];
                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                            end
                            4,5:begin
                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][3];
                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                            end
                            6,7:begin
                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][4];
                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                            end
                            endcase
                        end
                    end
                    case (read_resp.data_carrier_type)
                        32:begin
                            bit [4:0] sr_byte_num=read_cmd.physical_addr[4:0];
                            for(int k=0; k<(256-sr_byte_num);k++)
                                abstracted_byte_packet[k]=abstracted_byte_packet[k+sr_byte_num];
                        end
                        64:begin
                            bit [5:0] sr_byte_num=read_cmd.physical_addr[5:0];
                            for(int k=0; k<(256-sr_byte_num);k++)
                                abstracted_byte_packet[k]=abstracted_byte_packet[k+sr_byte_num];
                        end
                        default: `uvm_error(get_type_name(),"Unsupported data_carrier_type")
                    endcase
                end
                tl_tx_trans::RD_MEM :begin
                    if(read_resp.packet_type==tl_rx_trans::MEM_RD_RESPONSE_OW)begin
                        for(int i=0;i<4;i++)begin
                            for(int j=0; j<8;j++)begin
                                abstracted_byte_packet[i*8+j].byte_data=read_resp.data_carrier[i][(j*8+7) -:8];
                                case(read_resp.dP)
                                        3'd0,3'd2,3'd4,3'd6:begin
                                            case(i)
                                            0,1:begin
                                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][0];
                                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                                            end
                                            2,3:begin
                                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][1];
                                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                                            end
                                            endcase
                                        end
                                        3'd1,3'd3,3'd5,3'd7:begin
                                            case(i)
                                            0,1:begin
                                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][3];
                                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                                            end
                                            2,3:begin
                                                abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][4];
                                                abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                                            end
                                            endcase
                                        end
                                endcase
                            end
                        end
                    end
                    else begin
                        for(int i=0;i<32;i++)begin
                            for(int j=0; j<8;j++)begin
                                int k=(i % 8);
                                abstracted_byte_packet[i*8+j].byte_data=read_resp.data_carrier[i][(j*8+7) -:8];
                                case(k)
                                0,1:begin
                                    abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][0];
                                    abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                                end
                                2,3:begin
                                    abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][1];
                                    abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][2];
                                end
                                4,5:begin
                                    abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][3];
                                    abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                                end
                                6,7:begin
                                    abstracted_byte_packet[i*8+j].itag=read_resp.meta[i][4];
                                    abstracted_byte_packet[i*8+j].mdi=read_resp.meta[i][5];
                                end
                                endcase
                            end
                        end
                    end
                end
                default: `uvm_error(get_type_name(),"Unkown read cmd tends to abstract data")
            endcase
        end
        return abstracted_byte_packet;
    endfunction :abstract_from_read_resp

    function void reset();
        readable_tag.delete();
        writable_tag.delete();
        blocking_capptag_w.delete();
        blocking_capptag_r.delete();
        memory_model.delete();
    endfunction
endclass
`endif
