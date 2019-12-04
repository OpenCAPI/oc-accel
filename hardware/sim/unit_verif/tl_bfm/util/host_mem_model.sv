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
`ifndef _HOST_MEM_MODEL_SV
`define _HOST_MEM_MODEL_SV

class host_mem_model extends uvm_object;

    `uvm_object_utils_begin(host_mem_model)
    `uvm_object_utils_end

    typedef bit[7:0] byte_packet_array[256];
    typedef bit[7:0] byte_packet_queue[$];

    bit [7:0] memory_model[longint unsigned];

    function new(string name="host_mem_model");
        super.new(name);
    endfunction: new
    
    function bit[7:0] read_byte(longint unsigned addr);
        return memory_model[addr];
    endfunction: read_byte

    function void set_byte(longint unsigned addr, bit[7:0] data);
        memory_model[addr]=data;
    endfunction: set_byte

    function void set_memory_by_length(longint unsigned addr, int unsigned length, byte_packet_queue data_queue);
        for(int i=0; i<length; i++) begin
            if(data_queue.size != 0) begin
                memory_model[addr+i]=data_queue[0];
                void'(data_queue.pop_front());
            end
            else
                `uvm_error(get_type_name(),"data_queue size not match length")
        end
    endfunction: set_memory_by_length

    function bit exist_byte(longint unsigned addr);
        if(memory_model.exists(addr))
            return 1;
        else
            return 0;
    endfunction: exist_byte

    function void print_mem();
        foreach(memory_model[i])
            `uvm_info(get_type_name(),$psprintf("Memory addr:%h,data:%h", i, memory_model[i]), UVM_MEDIUM);
    endfunction: print_mem

    function void reset();
        memory_model.delete();
    endfunction

    function void write_memory_by_cmd(tl_rx_trans write_cmd, bit[1:0] resp_dlength=0, bit[1:0] resp_dpart=0);
        tl_rx_trans write_cmd_item;
        longint unsigned addr;
        int unsigned byte_num;    
        bit[7:0] byte_packet[256];
        $cast(write_cmd_item,write_cmd.clone());
   
        byte_packet=get_data_from_write_cmd(write_cmd_item);
        addr=write_cmd_item.Eaddr;

        case (write_cmd_item.packet_type)
            tl_rx_trans::DMA_W: begin
                case (resp_dlength)
                    2'b01: byte_num=64;
                    2'b10: byte_num=128;
                    2'b11: byte_num=256;
                    default: `uvm_error(get_type_name(),"Reserved resp dlegnth for DMA_W command")
                endcase
                for(int i=resp_dpart*64; i<byte_num; i++) begin
                    memory_model[addr+i]=byte_packet[i];
                end
            end
            tl_rx_trans::DMA_PR_W: begin 
                case (write_cmd_item.pL)
                    3'b000: byte_num=1;
                    3'b001: byte_num=2;
                    3'b010: byte_num=4;
                    3'b011: byte_num=8;
                    3'b100: byte_num=16;
                    3'b101: byte_num=32;
                    default: `uvm_error(get_type_name(),"Reserved plegnth for DMA_PR_W command")
                endcase
                for(int i=0; i<byte_num; i++) begin
                    memory_model[addr+i]=byte_packet[i];
                end
            end
            tl_rx_trans::DMA_W_BE: begin  
                byte_num=64;
                for(int i=0; i<byte_num; i++) begin
                    if(write_cmd_item.byte_enable[i]==1)begin
                        memory_model[addr+i]=byte_packet[i];
                    end
                end
            end
            default: `uvm_error(get_type_name(),"Unsupported cmd tends to update memory_model")
        endcase
    endfunction: write_memory_by_cmd

    function byte_packet_array get_data_from_write_cmd(tl_rx_trans write_cmd_raw);
        tl_rx_trans write_cmd;
        bit[7:0] byte_packet[256];
        $cast(write_cmd,write_cmd_raw.clone());

        case (write_cmd.packet_type)
            tl_rx_trans::DMA_PR_W, tl_rx_trans::DMA_W_BE: begin
                for(int i=0;i<8;i++)begin
                    for(int j=0; j<8;j++)begin
                        byte_packet[i*8+j]=write_cmd.data_carrier[i][(j*8+7) -:8];
                    end
                end
                case (write_cmd.data_carrier_type)
                    32:begin
                        bit [4:0] byte_num=write_cmd.Eaddr[4:0];
                        for(int k=0; k<(256-byte_num);k++)
                                byte_packet[k]=byte_packet[k+byte_num];
                    end
                    64:begin
                        bit [5:0] byte_num=write_cmd.Eaddr[5:0];
                        for(int k=0; k<(256-byte_num);k++)
                                byte_packet[k]=byte_packet[k+byte_num];
                    end
                    default: `uvm_error(get_type_name(),"Unsupported data_carrier_type")
                endcase
            end
            tl_rx_trans::DMA_W: begin
                for(int i=0;i<32;i++)begin
                    for(int j=0; j<8;j++)begin
                        byte_packet[i*8+j]=write_cmd.data_carrier[i][(j*8+7) -:8];
                    end
                end
            end
            default: `uvm_error(get_type_name(),"Unsupported write cmd tends to abstract data")
        endcase
        return byte_packet;
    endfunction :get_data_from_write_cmd

    function void read_memory_by_cmd(input tl_rx_trans read_cmd_raw, ref bit[63:0] data_carrier[32], input bit[1:0] resp_dlength=0, input bit[1:0] resp_dpart=0);
        tl_rx_trans read_cmd;
        longint unsigned addr;
        int unsigned byte_num;

        $cast(read_cmd,read_cmd_raw.clone());
        addr=read_cmd.Eaddr;

        case(read_cmd.packet_type)
            tl_rx_trans::RD_WNITC : begin
                case (resp_dlength)
                    2'b01: byte_num=64;
                    2'b10: byte_num=128;
                    2'b11: byte_num=256;
                    default: `uvm_error(get_type_name(),"Reserved resp dlegnth for RD_WNITC command")
                endcase
                for(int i=0; i<byte_num/8; i++) begin
                    for(int j=0; j<8; j++) begin
                        if(!memory_model.exists(addr+resp_dpart*64+i*8+j)) begin
                            memory_model[addr+resp_dpart*64+i*8+j]=0;
                            `uvm_info(get_type_name(),$psprintf("Memory addr:%h is not initialized or written, set as 0 for read resp", addr+resp_dpart*64+i*8+j), UVM_MEDIUM);
                        end
                        data_carrier[i][(j*8+7) -:8] = memory_model[addr+resp_dpart*64+i*8+j];
                    end
                end
            end
            tl_rx_trans::PR_RD_WNITC : begin
                case (read_cmd.pL)
                    3'b000: byte_num=1;
                    3'b001: byte_num=2;
                    3'b010: byte_num=4;
                    3'b011: byte_num=8;
                    3'b100: byte_num=16;
                    3'b101: byte_num=32;
                    default: `uvm_error(get_type_name(),"Reserved plegnth for PR_RD_WNITC command")
                endcase
                if(byte_num<8) begin
                    for(int i=0; i<byte_num; i++) begin
                        if(!memory_model.exists(addr+i)) begin
                            memory_model[addr+i]=0;
                            `uvm_info(get_type_name(),$psprintf("Memory addr:%h is not initialized or written, set as 0 for read resp", addr+i), UVM_MEDIUM);
                        end
                        data_carrier[0][(i*8+7) -:8] = memory_model[addr+i];
                    end
                end
                else begin
                    for(int i=0; i<byte_num/8; i++) begin
                        for(int j=0; j<8; j++) begin
                            if(!memory_model.exists(addr+i*8+j)) begin
                                memory_model[addr+i*8+j]=0;
                                `uvm_info(get_type_name(),$psprintf("Memory addr:%h is not initialized or written, set as 0 for read resp", addr+i*8+j), UVM_MEDIUM);
                            end
                            data_carrier[i][(j*8+7) -:8] = memory_model[addr+i*8+j];
                        end
                    end
                end
            end                    
            default: `uvm_error(get_type_name(),"Unsupported cmd tends to read memory_model")
        endcase
    endfunction: read_memory_by_cmd

endclass

`endif
