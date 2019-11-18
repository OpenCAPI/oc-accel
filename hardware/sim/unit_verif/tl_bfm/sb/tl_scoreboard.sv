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
`ifndef _TL_SCOREBOARD_SV
`define _TL_SCOREBOARD_SV
`define MSCC_RAM_INDEX_1 12

typedef class resp_packet;

class tl_scoreboard extends uvm_component;

    `uvm_analysis_imp_decl(_tx_mon)
    `uvm_analysis_imp_decl(_rx_mon)
    uvm_analysis_imp_tx_mon  #(tl_tx_trans, tl_scoreboard) scoreboard_input_tx_port;  //tx monitor to scoreboard port
    uvm_analysis_imp_rx_mon  #(tl_rx_trans, tl_scoreboard) scoreboard_input_rx_port;  //rx monitor to scoreboard port
    uvm_analysis_port #(tl_trans)       tl_drv_resp_ap;

    tl_cfg_obj       cfg_obj;
    tl_mem_model     mem_model;
    tl_tx_trans tx_cmd_queue[shortint unsigned];
    tl_tx_trans tx_resp_queue[shortint unsigned];
    tl_rx_trans rx_cmd_queue[shortint unsigned];
    tl_rx_trans rx_resp_queue[shortint unsigned];
    resp_packet tx_cmd_packet_queue[shortint unsigned];
    resp_packet tx_resp_packet_queue[shortint unsigned];
    resp_packet rx_cmd_packet_queue[shortint unsigned];
    resp_packet rx_resp_packet_queue[shortint unsigned];
    tl_trans resp_to_drv;
    bit all_resp_received_flag[shortint unsigned];
    bit reset_tx_timeout_thread=0;
    bit reset_rx_timeout_thread=0;

////////
    `uvm_component_utils_begin(tl_scoreboard)
    `uvm_component_utils_end

    function new (string name="tl_scoreboard", uvm_component parent);
        super.new(name, parent);
        tl_drv_resp_ap = new("tl_drv_resp_ap", this);
        resp_to_drv = new("resp_to_drv");
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scoreboard_input_tx_port = new("scoreboard_input_tx_port", this);
        scoreboard_input_rx_port = new("scoreboard_input_rx_port", this);
    endfunction: build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        if(!uvm_config_db#(tl_cfg_obj)::get(this, "", "cfg_obj", cfg_obj))
            `uvm_error(get_type_name(), "Can't get cfg_obj!")
        if(!uvm_config_db#(tl_mem_model)::get(this, "", "mem_model", mem_model))
            `uvm_error(get_type_name(), "Can't get mem_model!")
    endfunction: start_of_simulation_phase

    virtual task main_phase(uvm_phase phase);
    endtask : main_phase
/////////
    function resp_packet tl_ref_model(tl_tx_trans input_trans);
        resp_packet output_packet;
        output_packet=new("output_packet");
        case (input_trans.packet_type)
            tl_tx_trans::WRITE_MEM, tl_tx_trans::RD_MEM : begin
                case (input_trans.dlength)
                    2'b01: output_packet.byte_number_filled=64;
                    2'b10: output_packet.byte_number_filled=128;
                    2'b11: output_packet.byte_number_filled=256;
                    default: begin
                            `uvm_info(get_type_name(),"Reservered dlength used for WRITE_MEM or RD_MEM",UVM_MEDIUM)
                            output_packet.byte_number_filled=32;
                    end
                endcase
            end
            default:;
        endcase
        return output_packet;
    endfunction : tl_ref_model
/////////
    function void write_tx_mon(tl_tx_trans tx_trans);
        tl_tx_trans tx_item;
        resp_packet expect_resp_packet;
        tx_item=new("tx_item");
        $cast(tx_item,tx_trans.clone());
        if((tx_item.packet_type==tl_tx_trans::RETURN_TLX_CREDITS)||(tx_item.packet_type==tl_tx_trans::NOP)||(tx_item.packet_type==tl_tx_trans::RD_PF)) begin    //no operation for return_tlx_credits, nop and rd_pr
        end
        else begin
            if(tx_item.is_cmd==1)begin
                case(tx_item.packet_type)
                    tl_tx_trans::WRITE_MEM, tl_tx_trans::RD_MEM : begin
                        expect_resp_packet=tl_ref_model(tx_item);
                        tx_cmd_packet_queue[tx_item.capp_tag]=expect_resp_packet;
                    end
                    tl_tx_trans::CONFIG_READ, tl_tx_trans::CONFIG_WRITE, tl_tx_trans::PR_RD_MEM, tl_tx_trans::WRITE_MEM_BE :;
                    tl_tx_trans::PR_WR_MEM : begin   // if write pad pattern, without error, update pad pattern in cfg_obj when pr_wr_mem issued.
                        if((tx_item.physical_addr==cfg_obj.mmio_space_base-32)&&(cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)&&(tx_item.data_error[0][0]!=1)&&(tx_item.plength==5)&&(tx_item.data_template==6'ha)) begin
                            tl_mem_model::byte_packet_array abstracted_byte_packet;
                            abstracted_byte_packet=mem_model.abstract_from_write_cmd(tx_item, cfg_obj.metadata_enable);
                            for(int i=0; i<32; i++) begin
                                cfg_obj.data_pattern[i]=abstracted_byte_packet[i].byte_data;
                            end 
                            cfg_obj.data_pattern_xmeta=abstracted_byte_packet[0].xmeta;
                        end
                    end
                    tl_tx_trans::PAD_MEM ,tl_tx_trans::MEM_CNTL :;
                    tl_tx_trans::INTRP_RDY:;
                    tl_tx_trans::XLATE_DONE:;                     
                    default:  `uvm_error(get_type_name(),"Unkown cmd or resp opcode found at tx")
                endcase
                template_check_tx(tx_item);
                if(tx_item.packet_type!=tl_tx_trans::INTRP_RDY && tx_item.packet_type!=tl_tx_trans::XLATE_DONE)begin
                    tx_cmd_queue[tx_item.capp_tag]=tx_item;
                    all_resp_received_flag[tx_item.capp_tag]=0;
                    `uvm_info(get_type_name(),$psprintf("adding new flag in all_resp_received_flag,capptag:%h", tx_item.capp_tag), UVM_MEDIUM)
                    foreach(all_resp_received_flag[i])
                        `uvm_info(get_type_name(), $sformatf("capptag:%h,value:%h",i,all_resp_received_flag[i]), UVM_MEDIUM)
                    fork  : timeout_block_tx
                        begin
                            fork
                                #(cfg_obj.host_receive_resp_timer * 1ns) `uvm_error(get_type_name(),$sformatf("Time_out for tx_cmd with no or not enough response. Cmd is:\n%s",tx_item.sprint()));
                            join_none
                            wait((all_resp_received_flag[tx_item.capp_tag]==1)||(reset_tx_timeout_thread==1));
                            if(reset_tx_timeout_thread==1)begin
                                reset_tx_timeout_thread=0;
                                disable fork;
                            end
                            else begin
                                void'(all_resp_received_flag.delete(tx_item.capp_tag));
                                `uvm_info(get_type_name(), $sformatf("deleting flag in all_resp_received_flag,capptag:%h",tx_item.capp_tag), UVM_MEDIUM)
                                foreach(all_resp_received_flag[i])
                                    `uvm_info(get_type_name(), $sformatf("capptag:%h,value:%h",i,all_resp_received_flag[i]), UVM_MEDIUM)
                                disable fork; 
                            end
                        end
                    join_none
                end
            end
            else begin      // tx_item.is_cmd==0
                if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0 && (tx_item.packet_type == tl_tx_trans::READ_RESPONSE || tx_item.packet_type == tl_tx_trans::WRITE_RESPONSE
                || tx_item.packet_type == tl_tx_trans::READ_FAILED || tx_item.packet_type == tl_tx_trans::WRITE_FAILED))begin
                end
                else if(rx_cmd_queue.exists(tx_item.capp_tag))begin
                    case(tx_item.packet_type)
                        tl_tx_trans::INTRP_RESP:begin
                            if((rx_cmd_queue[tx_item.capp_tag].packet_type==tl_rx_trans::INTRP_REQ)||(rx_cmd_queue[tx_item.capp_tag].packet_type==tl_rx_trans::INTRP_REQ_D))begin
                                rx_cmd_queue.delete(tx_item.capp_tag);             // clear the item in rx_cmd_queue 
                                all_resp_received_flag[tx_item.capp_tag]=1;        // inform the time-out watcher that all required responses are received.
                            end
                            else begin
                                `uvm_error(get_type_name(),"Illegal opcode found at tx")
                            end
                        end
                        default:  `uvm_error(get_type_name(),"Unkown cmd or resp opcode found at tx")
                    endcase
                        //tl_tx_trans::INTRP_RESP :;
                end
                else
                    `uvm_error(get_type_name(),"Response sent from tx, while no matching rx_cmd is found")
            end
        end
    endfunction: write_tx_mon
///////////////////////
    function void write_rx_mon(tl_rx_trans rx_trans);
        tl_rx_trans rx_item;
        resp_packet temp_packet;
        $cast(rx_item,rx_trans.clone());
        if((rx_item.packet_type==tl_rx_trans::RETURN_TL_CREDITS)||(rx_item.packet_type==tl_rx_trans::NOP_R)) begin    //no operation for return_tl_credits and nop
        end
        else if((rx_item.is_cmd==0)&&(tx_cmd_queue.exists(rx_item.CAPPTag))) begin
        template_check_rx(tx_cmd_queue[rx_item.CAPPTag], rx_item);
        error_checking(tx_cmd_queue[rx_item.CAPPTag], rx_item);
            case (rx_item.packet_type)
                tl_rx_trans::MEM_WR_RESPONSE, tl_rx_trans::MEM_WR_FAIL: begin
                    bit write_all_success=0;
                    case(tx_cmd_queue[rx_item.CAPPTag].packet_type)
                        tl_tx_trans::WRITE_MEM : begin
                            if(!rx_resp_queue.exists(rx_item.CAPPTag)) begin     //begin to creat new item for rx_resp_queue and rx_resp_packet_queue   
                                temp_packet=new("temp_packet");
                                rx_resp_queue[rx_item.CAPPTag]=rx_item;
                                rx_resp_packet_queue[rx_item.CAPPTag]=temp_packet;
                            end
                            update_resp_packet_with_wr_resp(rx_item, rx_resp_packet_queue[rx_item.CAPPTag]);
                            if(rx_item.packet_type==tl_rx_trans::MEM_WR_RESPONSE)
                                `uvm_info(get_type_name(),$psprintf("MEM_WR_RESPONSE received, capptag:%h, dL:%d, dP:%d", rx_item.CAPPTag,rx_item.dL,rx_item.dP), UVM_MEDIUM)
                            else begin
                                `uvm_info(get_type_name(),$psprintf("MEM_WR_FAIL received, capptag:%h, dL:%d, dP:%d, resp_code:%b", rx_item.CAPPTag,rx_item.dL,rx_item.dP,rx_item.resp_code), UVM_MEDIUM)
                                if(rx_item.resp_code==4'b0010)
                                    rx_resp_packet_queue[rx_item.CAPPTag].retry_flag=1;
                            end
                            //begin to decide whether all responses is received
                            if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled>tx_cmd_packet_queue[rx_item.CAPPTag].byte_number_filled)       //Too much bytes receiving response
                                `uvm_error(get_type_name(),"Too much bytes receiving write response")
                            else if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled==tx_cmd_packet_queue[rx_item.CAPPTag].byte_number_filled) begin //all response have been received
                                write_all_success=1;
                                for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++) begin
                                    if(rx_resp_packet_queue[rx_item.CAPPTag].write_success_record[i]==0) begin
                                        write_all_success=0;
                                        break;
                                    end
                                end                                        //decide whether write totally success

                                if(write_all_success==1)begin            
                                    `uvm_info(get_type_name(),"All write response received, all succeed",UVM_MEDIUM)
                                    mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode)); //handle the readable_tag array in mem_model
                                end
                                else if(rx_resp_packet_queue[rx_item.CAPPTag].retry_flag==1)
                                    `uvm_warning(get_type_name(),"All write response received, but not all succeed, retry is needed")
                                else begin
                                    `uvm_warning(get_type_name(),"All write response received, but not all succeed, retry is not needed")
                                    mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode)); //handle the readable_tag array in mem_model
                                end

                                fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                                resp_to_drv.rx_dL=tx_cmd_queue[rx_item.CAPPTag].dlength;
                                tl_drv_resp_ap.write(resp_to_drv);
                                `uvm_info(get_type_name(),$sformatf("Scoreboard send write response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)
                                
                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                mem_model.memory_update_by_write_cmd(tx_cmd_queue[rx_item.CAPPTag],cfg_obj,rx_resp_packet_queue[rx_item.CAPPTag]);//update memory_model
                                //mem_model.print_mem();
                                tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in both tx_cmd_queue, tx_cmd_packet_queue, rx_resp_queue, rx_resp_packet_queue 
                                tx_cmd_packet_queue.delete(rx_item.CAPPTag);
                                rx_resp_queue.delete(rx_item.CAPPTag);
                                rx_resp_packet_queue.delete(rx_item.CAPPTag);
                                all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                            end
                        end
                        tl_tx_trans::PR_WR_MEM, tl_tx_trans::CONFIG_WRITE, tl_tx_trans::WRITE_MEM_BE: begin
                            if(!((rx_item.dL==2'b01)&&(rx_item.dP==3'b000)))       //dL||dP should be 01000
                                `uvm_error(get_type_name(),"Illegal dL and dP pair for MEM_WR_RESPONSE or MEM_WR_FAIL")
                            else begin
                                if(rx_item.packet_type==tl_rx_trans::MEM_WR_RESPONSE) begin
                                    mem_model.memory_update_by_write_cmd(tx_cmd_queue[rx_item.CAPPTag],cfg_obj,);
                                    `uvm_info(get_type_name(),"MEM_WRITE succeed",UVM_MEDIUM)
                                    //mem_model.print_mem();
                                    mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode)); //handle the readable_tag array in mem_model
                                end
                                else begin          //WR_FAIL_RESPONSE RECEIVED
                                    if(rx_item.resp_code==4'b0010)begin
                                        `uvm_info(get_type_name(),"MEM_WRITE failed, retry is needed",UVM_MEDIUM)
                                    end
                                    else begin
                                        `uvm_info(get_type_name(),"MEM_WRITE failed, retry is not needed",UVM_MEDIUM)
                                        mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode)); //handle the readable_tag array in mem_model
                                    end
                                end
                                fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                                tl_drv_resp_ap.write(resp_to_drv);
                                `uvm_info(get_type_name(),$sformatf("Scoreboard send write response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)

                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in tx_cmd_queue 
                                all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                            end 
                        end
                        tl_tx_trans::PAD_MEM :begin
                            if(!((rx_item.dL==tx_cmd_queue[rx_item.CAPPTag].dlength)&&(rx_item.dP==3'b000)))    
                                `uvm_error(get_type_name(),"Illegal dL and dP pair for MEM_WR_RESPONSE or MEM_WR_FAIL")
                            else begin
                                if(rx_item.packet_type==tl_rx_trans::MEM_WR_RESPONSE) begin
                                    mem_model.memory_update_by_write_cmd(tx_cmd_queue[rx_item.CAPPTag],cfg_obj,);
                                    `uvm_info(get_type_name(),"PAD_MEM succeed",UVM_MEDIUM)
                                    //mem_model.print_mem();
                                    mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode));  //handle the readable_tag array in mem_model
                                end
                                else begin
                                    if(rx_item.resp_code==4'b0010)begin
                                        `uvm_info(get_type_name(),"PAD_MEM failed, retry is needed",UVM_MEDIUM)
                                    end
                                    else begin
                                        `uvm_info(get_type_name(),"PAD_MEM failed, retry is not needed",UVM_MEDIUM)
                                        mem_model.set_readable_tag(tx_cmd_queue[rx_item.CAPPTag],(cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode));  //handle the readable_tag array in mem_model
                                    end
                                end
                                fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                                tl_drv_resp_ap.write(resp_to_drv);
                                `uvm_info(get_type_name(),$sformatf("Scoreboard send write response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)                                
                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in tx_cmd_queue 
                                all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                            end
                        end
                        default: `uvm_error(get_type_name(),"Illegal opcode found at rx")
                    endcase  
                end 
                tl_rx_trans::MEM_RD_RESPONSE, tl_rx_trans::MEM_RD_RESPONSE_OW, tl_rx_trans::MEM_RD_RESPONSE_XW, tl_rx_trans::MEM_RD_FAIL : begin
                    bit read_all_success=0;
                    bit read_data_all_match=0;
                    bit meta_data_all_match=0;
                    bit xmeta_data_all_match=0;
                    int unsigned temp_byte_num;
                    int unsigned temp_index;
                    int unsigned temp_physical_addr;
                    tl_mem_model::byte_packet_array abstracted_byte_packet;

                    data_error_check(rx_item);      //check CE, UE and bad data
                    case(tx_cmd_queue[rx_item.CAPPTag].packet_type)
                        tl_tx_trans::RD_MEM: begin       //  Start to handle the read resps of RD_MEM
                            bit critical_ow_read;
                            critical_ow_read=((tx_cmd_queue[rx_item.CAPPTag].dlength==2)&&(tx_cmd_queue[rx_item.CAPPTag].physical_addr[6:5]!=2'b00))||(((tx_cmd_queue[rx_item.CAPPTag].dlength==1)&&(tx_cmd_queue[rx_item.CAPPTag].physical_addr[5]==1)));
                            if(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_XW)
                                `uvm_error(get_type_name(),"Illegal response opcode")
                            else begin
                                if(!rx_resp_queue.exists(rx_item.CAPPTag)) begin
                                    temp_packet=new("temp_packet");
                                    rx_resp_queue[rx_item.CAPPTag]=rx_item;
                                    rx_resp_packet_queue[rx_item.CAPPTag]=temp_packet;
                                end
                                abstracted_byte_packet=mem_model.abstract_from_read_resp(tx_cmd_queue[rx_item.CAPPTag],rx_item); //abstract_from_read_resp
                                if(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_OW) begin    // If the response is mem_rd_response.ow.
                                    `uvm_info(get_type_name(),$psprintf("MEM_RD_RESPONSE_OW received, capptag:%h, dP:%d", rx_item.CAPPTag,rx_item.dP), UVM_MEDIUM)
                                    if(cfg_obj.crit_ow_first_enable==1)begin     //Begin to adjust rx_item.dP, when critical_ow_first mode is on.
                                        if(tx_cmd_queue[rx_item.CAPPTag].dlength==2)
                                            rx_item.dP[1:0]=rx_item.dP[1:0]^tx_cmd_queue[rx_item.CAPPTag].physical_addr[6:5];
                                        if(tx_cmd_queue[rx_item.CAPPTag].dlength==1)
                                            rx_item.dP[0]=rx_item.dP[0]^tx_cmd_queue[rx_item.CAPPTag].physical_addr[5];
                                    end

                                    if(critical_ow_read==1)begin  //Critical_ow_read mode
                                        `uvm_info(get_type_name(),$psprintf("RD_MEM in critical_ow_read mode detected, capptag:%h", rx_item.CAPPTag), UVM_MEDIUM)
                                        if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled==0)begin   //first response.ow
                                            
                                            if(cfg_obj.crit_ow_first_enable==1)begin    //critical ow first enabled, check response order
                                                case({tx_cmd_queue[rx_item.CAPPTag].dlength,tx_cmd_queue[rx_item.CAPPTag].physical_addr[6:5]})
                                                4'b0111,4'b0101: begin
                                                    if(rx_item.dP!=3'b001)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response_ow is not correct")
                                                end
                                                4'b1001: begin
                                                    if(rx_item.dP!=3'b001)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response_ow is not correct")
                                                end
                                                4'b1010: begin
                                                    if(rx_item.dP!=3'b010)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response_ow is not correct")
                                                end
                                                4'b1011: begin
                                                    if(rx_item.dP!=3'b011)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response_ow is not correct")
                                                end
                                                endcase
                                            end
                                        end
                                    end
                                    update_resp_packet_with_rd_resp(rx_item, rx_resp_packet_queue[rx_item.CAPPTag], abstracted_byte_packet);
                                end
                                else begin   // If the response is mem_rd_response or mem_rd_fail

                                    if((cfg_obj.crit_ow_first_enable==1)&&(critical_ow_read==1))begin     //Begin to adjust rx_item.dP, when critical_ow_first mode is on.
                                        if(tx_cmd_queue[rx_item.CAPPTag].dlength==2)       //adjust dP
                                            rx_item.dP[0]=rx_item.dP[0]^tx_cmd_queue[rx_item.CAPPTag].physical_addr[6];
                                        if(tx_cmd_queue[rx_item.CAPPTag].physical_addr[5]==1)  begin     //do the rotate on data_carrier
                                            bit [63:0] temp_data_carrier[8];
                                            bit [2:0]  temp_data_error[8];
                                            bit [6:0] temp_meta[8];

                                            for(int i=0; i<4; i++) begin
                                                temp_data_carrier[i]=rx_item.data_carrier[i+4];
                                                temp_data_carrier[i+4]=rx_item.data_carrier[i];
                                                temp_data_error[i]=rx_item.data_error[i+4];
                                                temp_data_error[i+4]=rx_item.data_error[i];
                                            end
                                            for(int i=0; i<8; i++)  begin
                                                rx_item.data_carrier[i]=temp_data_carrier[i];
                                                rx_item.data_error[i]=temp_data_error[i];
                                                temp_meta[i][0]=rx_item.meta[i][3];
                                                temp_meta[i][3]=rx_item.meta[i][0];
                                                temp_meta[i][1]=rx_item.meta[i][4];
                                                temp_meta[i][4]=rx_item.meta[i][1];
                                                temp_meta[i][2]=rx_item.meta[i][5];
                                                temp_meta[i][5]=rx_item.meta[i][2];
                                                rx_item.meta[i]=temp_meta[i];
                                            end
                                            abstracted_byte_packet=mem_model.abstract_from_read_resp(tx_cmd_queue[rx_item.CAPPTag],rx_item); //abstract_from_read_resp after rotating of data_carrier
                                        end
                                    end

                                    if(critical_ow_read==1)begin  //Critical_ow_read mode
                                        `uvm_info(get_type_name(),$psprintf("RD_MEM in critical_ow_read mode detected, capptag:%h", rx_item.CAPPTag), UVM_MEDIUM)
                                        if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled==0)begin   //first response
                                            
                                            if(cfg_obj.crit_ow_first_enable==1)begin    //critical ow first enabled, check response order
                                                case({tx_cmd_queue[rx_item.CAPPTag].dlength,tx_cmd_queue[rx_item.CAPPTag].physical_addr[6:5]})
                                                4'b0111,4'b0101: begin   //dlength=1 
                                                    if(rx_item.dP!=3'b000)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response is not correct")
                                                end
                                                4'b1001: begin
                                                    if(rx_item.dP!=3'b000)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response is not correct")
                                                end
                                                4'b1010,4'b1011: begin
                                                    if(rx_item.dP!=3'b001)
                                                        `uvm_error(get_type_name(),"In critical_ow_read mode, the order of rd_response is not correct")
                                                end
                                                endcase
                                            end
                                        end
                                    end
                                    update_resp_packet_with_rd_resp(rx_item, rx_resp_packet_queue[rx_item.CAPPTag], abstracted_byte_packet);
                                    if(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE)
                                        `uvm_info(get_type_name(),$psprintf("MEM_RD_RESPONSE received, capptag:%h, dL:%d, dP:%d", rx_item.CAPPTag,rx_item.dL,rx_item.dP), UVM_MEDIUM)
                                    else begin
                                        `uvm_info(get_type_name(),$psprintf("MEM_RD_FAIL received, capptag:%h, dL:%d, dP:%d, resp_code:%b", rx_item.CAPPTag,rx_item.dL,rx_item.dP,rx_item.resp_code), UVM_MEDIUM)
                                        if(rx_item.resp_code==4'b0010)
                                            rx_resp_packet_queue[rx_item.CAPPTag].retry_flag=1;
                                    end
                                end   //finish handling rx_resp_queue and rx_resp_packet_queue    
                                // begin to decide whether all rd_response are received
                                if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled>tx_cmd_packet_queue[rx_item.CAPPTag].byte_number_filled)     //Too much bytes receiving response
                                    `uvm_error(get_type_name(),"Too much bytes receiving read response")
                                else if(rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled==tx_cmd_packet_queue[rx_item.CAPPTag].byte_number_filled)begin//all response have been received
                                    tl_tx_trans tx_trans_for_check;
                                    tx_trans_for_check=new("tx_trans_for_check");
                                    $cast(tx_trans_for_check,tx_cmd_queue[rx_item.CAPPTag].clone());
                                    if(critical_ow_read==1)begin
                                        if(tx_trans_for_check.dlength==1)
                                            tx_trans_for_check.physical_addr[5]=0;
                                        else
                                            tx_trans_for_check.physical_addr[6:5]=0;
                                    end

                                    sue_lable(rx_resp_packet_queue[rx_item.CAPPTag]);  //adding sue lable to resp_packet;

                                    for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++) begin   //  print the comparison process
                                        case ({rx_resp_packet_queue[rx_item.CAPPTag].read_success_record[i], mem_model.exist_byte(tx_trans_for_check.physical_addr+i),
                                                mem_model.read_byte(tx_trans_for_check.physical_addr+i).data_exist})
                                            3'b000 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: x, mdi: x, mdi_valid: x, sue: x, Actual data: x, itag: x, mdi: x, sue: x", tx_trans_for_check.physical_addr+i), UVM_MEDIUM)
                                            3'b010 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: x, itag: x, mdi: x, sue: x", tx_trans_for_check.physical_addr+i, mem_model.read_byte(tx_trans_for_check.physical_addr+i).itag, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi_valid, mem_model.read_byte(tx_trans_for_check.physical_addr+i).sue), UVM_MEDIUM)
                                            3'b011 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: %h, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: x, itag: x, mdi: x, sue: x", tx_trans_for_check.physical_addr+i, mem_model.read_byte(tx_trans_for_check.physical_addr+i).byte_data, mem_model.read_byte(tx_trans_for_check.physical_addr+i).itag, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi_valid, mem_model.read_byte(tx_trans_for_check.physical_addr+i).sue), UVM_MEDIUM)
                                            3'b100 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: x, mdi: x, mdi_valid: x, sue: x, Actual data: %h, itag: %h, mdi: %h, sue: %h", tx_trans_for_check.physical_addr+i, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].byte_data, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].sue), UVM_MEDIUM)
                                            3'b110 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: %h, itag: %h, mdi: %h, sue: %h", tx_trans_for_check.physical_addr+i, mem_model.read_byte(tx_trans_for_check.physical_addr+i).itag, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi_valid, mem_model.read_byte(tx_trans_for_check.physical_addr+i).sue, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].byte_data, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].sue), UVM_MEDIUM)
                                            3'b111 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: %h, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: %h, itag: %h, mdi: %h, sue: %h", tx_trans_for_check.physical_addr+i, mem_model.read_byte(tx_trans_for_check.physical_addr+i).byte_data, mem_model.read_byte(tx_trans_for_check.physical_addr+i).itag, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi, mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi_valid, mem_model.read_byte(tx_trans_for_check.physical_addr+i).sue, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].byte_data, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi, rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].sue), UVM_MEDIUM)
                                        endcase
                                    end      

                                    read_all_success=1;
                                    for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++) begin
                                        if(rx_resp_packet_queue[rx_item.CAPPTag].read_success_record[i]==0) begin
                                             read_all_success=0;
                                             break;
                                        end
                                    end                           //   till now, whether read totally success is known

                                    meta_data_all_match=1;
                                    for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++) begin
                                        if(rx_resp_packet_queue[rx_item.CAPPTag].read_success_record[i]==1) begin     //read succeed
                                            if(mem_model.exist_byte(tx_trans_for_check.physical_addr+i))begin  //exist in memory
                                                if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).sue!=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].sue) begin
                                                    `uvm_error(get_type_name(),$sformatf("SUE status mismatch, Cmd is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()))
                                                    break;
                                                end
                                                if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).itag!=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag) begin
                                                    meta_data_all_match=0;
                                                    break;
                                                end
                                                if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi_valid==1)begin
                                                    if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).mdi!=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi) begin
                                                        meta_data_all_match=0;
                                                        break;
                                                    end
                                                end
                                            end
                                        end
                                    end                      //till now, whether meta data all match is known

                                    read_data_all_match=1;
                                    for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++) begin
                                        if(rx_resp_packet_queue[rx_item.CAPPTag].read_success_record[i]==1) begin    //read succeed
                                            if(mem_model.exist_byte(tx_trans_for_check.physical_addr+i))begin  //exist in memory
                                                if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).data_exist==1)begin  //data_exist in the byte
                                                    if(mem_model.read_byte(tx_trans_for_check.physical_addr+i).byte_data!=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].byte_data) begin      //data don't match
                                                        read_data_all_match=0;
                                                        break;
                                                    end
                                                end
                                            end
                                        end
                                    end                  //   till now, whether read data all match is known

                                    case ({read_all_success,read_data_all_match,meta_data_all_match})
                                        3'b111 : begin
                                            `uvm_info(get_type_name(),"All read response received, all data received, all data matched, all meta data matched",UVM_MEDIUM)
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                        end
                                        3'b110 : begin
                                            `uvm_error(get_type_name(),"All read response received, all data received, all data matched, but meta data miscompared")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b101 : begin
                                            `uvm_error(get_type_name(),"All read response received, all data received, but data miscompared, all meta data matched")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b100 : begin
                                            `uvm_error(get_type_name(),"All read response received, all data received, but data miscompared, meta data miscompared")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b011 : begin
                                            `uvm_warning(get_type_name(),"All read response received, partial data received, all data matched, all meta data matched")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b010 : begin
                                            `uvm_error(get_type_name(),"All read response received, partial data received, all data matched, but meta miscpmpared")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b001 : begin
                                            `uvm_error(get_type_name(),"All read response received, partial data received, but data miscompared, all meta data matched")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                        3'b000 : begin
                                            `uvm_error(get_type_name(),"All read response received, partial data received, but data miscompared, meta data miscompared")
                                            `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                        end
                                    endcase
                                    if(rx_resp_packet_queue[rx_item.CAPPTag].retry_flag==1)
                                        `uvm_info(get_type_name(),$psprintf("Retry is need for capptag:%h", rx_item.CAPPTag), UVM_MEDIUM)
                                    else
                                        mem_model.set_writable_tag(tx_trans_for_check, (cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode));  //handle the writable_tag array in mem_model

                                    fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                                    resp_to_drv.rx_dL=tx_cmd_queue[rx_item.CAPPTag].dlength;
                                    resp_to_drv.rx_dP=0;
                                    resp_to_drv.rx_packet_type=(rx_item.packet_type==tl_rx_trans::MEM_RD_FAIL)?(tl_rx_trans::MEM_RD_FAIL):(tl_rx_trans::MEM_RD_RESPONSE);
                                    for(int i=0 ; i < rx_resp_packet_queue[rx_item.CAPPTag].byte_number_filled ; i++)begin
                                        int p=i/8; //data_carrier index
                                        int k=i%8; //byte index in a data_carrier
                                        int m=(i%64)/16; //itag index
                                        int n=(i%64)/32; //mdi index
                                        resp_to_drv.rx_data_carrier[p][(k*8+7)-: 8]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].byte_data;
                                        
                                        case(m)
                                            0: begin
                                                for(int j=0; j<8; j++)
                                                    resp_to_drv.rx_meta[(i/64)*8+j][0]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag;
                                            end
                                            1: begin
                                                for(int j=0; j<8; j++)
                                                    resp_to_drv.rx_meta[(i/64)*8+j][1]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag;
                                            end
                                            2: begin
                                                for(int j=0; j<8; j++)
                                                    resp_to_drv.rx_meta[(i/64)*8+j][3]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag;
                                            end
                                            3: begin
                                                for(int j=0; j<8; j++)
                                                    resp_to_drv.rx_meta[(i/64)*8+j][4]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].itag;
                                            end
                                        endcase
                                        case(n)
                                            0: begin
                                                for(int j=0; j<8; j++)begin
                                                    resp_to_drv.rx_meta[(i/64)*8+j][2]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi;
                                                end
                                            end
                                            1: begin
                                                for(int j=0; j<8; j++)begin
                                                    resp_to_drv.rx_meta[(i/64)*8+j][5]=rx_resp_packet_queue[rx_item.CAPPTag].data_bytewise[i].mdi;
                                                end
                                            end
                                        endcase
                                    end
                                    tl_drv_resp_ap.write(resp_to_drv);
                                    `uvm_info(get_type_name(),$sformatf("Scoreboard send read response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)


                                    mem_model.memory_update_by_read_cmd(tx_trans_for_check,rx_resp_packet_queue[rx_item.CAPPTag]);// update memory model based on data in rd_response
                                    //mem_model.print_mem();
                                    tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in both tx_cmd_queue, tx_cmd_packet_queue, rx_resp_queue, rx_resp_packet_queue 
                                    tx_cmd_packet_queue.delete(rx_item.CAPPTag);
                                    rx_resp_queue.delete(rx_item.CAPPTag);
                                    rx_resp_packet_queue.delete(rx_item.CAPPTag);
                                    all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                                end
                            end
                        end                             //    finish handling read resps for RD_MEM
                        tl_tx_trans::CONFIG_READ :begin

                            case(rx_item.packet_type)                        //checking dL, dP, plength 
                                tl_rx_trans::MEM_RD_RESPONSE, tl_rx_trans::MEM_RD_FAIL:begin
                                    if(!((rx_item.dL==2'b01)&&(rx_item.dP==3'b000)))
                                        `uvm_error(get_type_name(),"MEM_RD_RESPONSE or MEM_RD_FAIL with illegal pair of dL and dP")
                                end
                                tl_rx_trans::MEM_RD_RESPONSE_OW:begin
                                    if(rx_item.dP!=3'b000)
                                        `uvm_error(get_type_name(),"MEM_RD_RESPONSE_OW with illegal dP")
                                end
                                tl_rx_trans::MEM_RD_RESPONSE_XW:begin
                                    if(tx_cmd_queue[rx_item.CAPPTag].plength>3)
                                        `uvm_error(get_type_name(),"MEM_RD_RESPONSE_XW received, but the cmd requires more than 8 bytes")
                                end
                            endcase

                            if(rx_item.packet_type==tl_rx_trans::MEM_RD_FAIL)begin           // Read failed
                                `uvm_info(get_type_name(),"CONFIG_READ failed received",UVM_MEDIUM)
                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                            end
                            else begin 
                                `uvm_info(get_type_name(),"Read response received",UVM_MEDIUM)
                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                            end
                            abstracted_byte_packet=mem_model.abstract_from_read_resp(tx_cmd_queue[rx_item.CAPPTag],rx_item); //abstract_from_read_resp
                            fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                            for(int i=0; i<8; i++) begin
                                for(int j=0; j<8; j++)
                                    resp_to_drv.rx_data_carrier[i][(j*8+7) -:8]= abstracted_byte_packet[i*8+j].byte_data;
                            end
                            tl_drv_resp_ap.write(resp_to_drv);
                            `uvm_info(get_type_name(),$sformatf("Scoreboard send read response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)

                            tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in tx_cmd_queue 
                            all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                        end

                        tl_tx_trans::PR_RD_MEM : begin
                            case(rx_item.packet_type)                        //checking dL, dP, plength 
                                tl_rx_trans::MEM_RD_RESPONSE, tl_rx_trans::MEM_RD_FAIL:begin
                                    if(!((rx_item.dL==2'b01)&&(rx_item.dP==3'b000)))
                                        `uvm_error(get_type_name(),"MEM_RD_RESPONSE or MEM_RD_FAIL with illegal pair of dL and dP")
                                end
                                tl_rx_trans::MEM_RD_RESPONSE_OW:begin
                                    if(rx_item.dP!=3'b000)
                                        `uvm_error(get_type_name(),"MEM_RD_RESPONSE_OW with illegal dP")
                                end
                                tl_rx_trans::MEM_RD_RESPONSE_XW:begin
                                    `uvm_error(get_type_name(),"MEM_RD_RESPONSE_XW is not supported")
                                end
                            endcase

                            if(rx_item.packet_type==tl_rx_trans::MEM_RD_FAIL)begin           // Read failed
                                `uvm_info(get_type_name(),"PR_RD_MEM failed",UVM_MEDIUM)
                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                            end
                            else begin        // mem_rd_response or mem_rd_response_ow, read success, check data, creat a resp_packet and update memory model
                                `uvm_info(get_type_name(),"Read response received",UVM_MEDIUM)
                                if(tx_cmd_queue[rx_item.CAPPTag].physical_addr[63:35]!=cfg_obj.mmio_space_base[63:35]) begin//in sysmem space, check data, check meta, check xmeta update memory
                                    tl_tx_trans tx_trans_for_check;
                                    tx_trans_for_check=new("tx_trans_for_check");
                                    $cast(tx_trans_for_check,tx_cmd_queue[rx_item.CAPPTag].clone());
                                    tx_trans_for_check.physical_addr[4:0]=0;
                                    abstracted_byte_packet=mem_model.abstract_from_read_resp(tx_trans_for_check,rx_item); //abstract with 32B pr_rd_mem

                                    temp_byte_num=32;
                                    temp_packet=new("temp_packet");
                                    read_data_all_match=1;
                                    meta_data_all_match=1;
                                    xmeta_data_all_match=1;
                                    temp_physical_addr=tx_trans_for_check.physical_addr;
                                    temp_packet.byte_number_filled=temp_byte_num;


                                    for(int i=0 ; i<temp_byte_num ; i++) begin
                                        temp_packet.read_success_record[i]=1;
                                        temp_packet.data_bytewise[i]=abstracted_byte_packet[i];
                                    end

                                    if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))) begin    // print the compare process. 
                                        for(int i=0 ; i < temp_byte_num; i++) begin   //  Non half dimm mode
                                            case ({mem_model.exist_byte(temp_physical_addr+i), mem_model.read_byte(temp_physical_addr+i).data_exist})
                                                2'b00 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: x, mdi: x, mdi_valid: x, sue: x, Actual data: %h, itag: %h, mdi: %h", temp_physical_addr+i, temp_packet.data_bytewise[i].byte_data, temp_packet.data_bytewise[i].itag, temp_packet.data_bytewise[i].mdi),UVM_MEDIUM)
                                                2'b10 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: %h, itag: %h, mdi: %h", temp_physical_addr+i, mem_model.read_byte(temp_physical_addr+i).itag, mem_model.read_byte(temp_physical_addr+i).mdi, mem_model.read_byte(temp_physical_addr+i).mdi_valid, mem_model.read_byte(temp_physical_addr+i).sue, temp_packet.data_bytewise[i].byte_data, temp_packet.data_bytewise[i].itag, temp_packet.data_bytewise[i].mdi),UVM_MEDIUM)
                                                2'b11 : `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: %h, itag: %h, mdi: %h, mdi_valid: %h, sue: %h, Actual data: %h, itag: %h, mdi: %h", temp_physical_addr+i, mem_model.read_byte(temp_physical_addr+i).byte_data, mem_model.read_byte(temp_physical_addr+i).itag, mem_model.read_byte(temp_physical_addr+i).mdi, mem_model.read_byte(temp_physical_addr+i).mdi_valid, mem_model.read_byte(temp_physical_addr+i).sue, temp_packet.data_bytewise[i].byte_data, temp_packet.data_bytewise[i].itag, temp_packet.data_bytewise[i].mdi),UVM_MEDIUM)
                                            endcase
                                        end                                                
                                    end
                                    else begin 
                                        for(int i=0 ; i < temp_byte_num; i++) begin // half dimm mode
                                            if(!(mem_model.exist_byte(temp_physical_addr+i))) begin
                                                `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: x, xmeta: x, Actual data: %h, xmeta: %h", temp_physical_addr+i, temp_packet.data_bytewise[i].byte_data, temp_packet.data_bytewise[i].xmeta),UVM_MEDIUM)
                                            end
                                            else begin
                                                `uvm_info(get_type_name(), $sformatf("Memory addr: %h, Expected data: %h, xmeta: %h, Actual data: %h, xmeta: %h", temp_physical_addr+i, mem_model.read_byte(temp_physical_addr+i).byte_data, mem_model.read_byte(temp_physical_addr+i).xmeta, temp_packet.data_bytewise[i].byte_data, temp_packet.data_bytewise[i].xmeta),UVM_MEDIUM)
                                            end
                                        end
                                    end 

                                    for(int i=0 ; i<temp_byte_num ; i++) begin
                                        if(mem_model.exist_byte(temp_physical_addr+i))begin   //exist in memory
                                            if(mem_model.read_byte(temp_physical_addr+i).data_exist==1)begin
                                                if(mem_model.read_byte(temp_physical_addr+i).byte_data!=abstracted_byte_packet[i].byte_data)begin  //data  don't match
                                                    read_data_all_match=0;
                                                    break;
                                                end
                                            end
                                        end
                                    end // till now, whether data match is known

                                    if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))) begin   //only in non_half_dimm_mode, meta is checked.
                                        for(int i=0 ; i<temp_byte_num ; i++) begin
                                            if(mem_model.exist_byte(temp_physical_addr))begin  //   exist in memory
                                                if(mem_model.read_byte(temp_physical_addr+i).itag!=abstracted_byte_packet[i].itag) begin      //itag don't match
                                                    meta_data_all_match=0;
                                                    break;
                                                end
                                                if(mem_model.read_byte(temp_physical_addr+i).mdi_valid==1)  begin
                                                    if(mem_model.read_byte(temp_physical_addr+i).mdi!=abstracted_byte_packet[i].mdi) begin      //mdi don't match
                                                        meta_data_all_match=0;
                                                        break;
                                                    end
                                                end
                                            end
                                        end        //till now, whether meta data all match is known

                                        case({read_data_all_match,meta_data_all_match})
                                            2'b11:begin
                                                `uvm_info(get_type_name(),"Read response received, all data matched, all meta data matched",UVM_MEDIUM)
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                                mem_model.memory_update_by_read_cmd(tx_trans_for_check,temp_packet);    // update memory model based on data in rd_response
                                                //mem_model.print_mem();
                                            end
                                            2'b01:begin
                                                `uvm_error(get_type_name(),"Read response received, but data miscompared, all meta data matched")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                            2'b10:begin
                                                `uvm_error(get_type_name(),"Read response received, all data matched, but meta data miscompared")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                            2'b00:begin
                                                `uvm_error(get_type_name(),"Read response received, but data miscompared, meta data miscompared")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                        endcase
                                    end
                                    else begin   //only in half dimm mode, xmata is checked.
                                        for(int i=0 ; i<temp_byte_num ; i++) begin
                                            if(mem_model.exist_byte(temp_physical_addr))begin  //   exist in memory
                                                if(mem_model.read_byte(temp_physical_addr+i).xmeta[63:0]!=abstracted_byte_packet[i].xmeta[63:0]) begin      //xmeta don't match
                                                    xmeta_data_all_match=0;
                                                    break;
                                                end
                                            end
                                        end        //till now, whether xmeta data all match is known
                                        /*
                                        for(int i=0 ; i<temp_byte_num ; i++) begin   //only in half dimm mode. MISR code is checked.
                                            if(misr_cal(abstracted_byte_packet[i].xmeta[63:0])!=abstracted_byte_packet[i].xmeta[71:64])
                                                `uvm_error(get_type_name(),$sformatf("MISR code error detected, original cmd:\n%s", tx_cmd_queue[rx_item.CAPPTag].sprint()))
                                        end
                                        */
                                        case({read_data_all_match,xmeta_data_all_match})
                                            2'b11:begin
                                                `uvm_info(get_type_name(),"Read response received, all data matched, all xmeta matched",UVM_MEDIUM)
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_HIGH)
                                                mem_model.memory_update_by_read_cmd(tx_trans_for_check,temp_packet);    // update memory model based on data in rd_response
                                                //mem_model.print_mem();
                                            end
                                            2'b01:begin
                                                `uvm_error(get_type_name(),"Read response received, but data miscompared, all xmeta matched")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                            2'b10:begin
                                                `uvm_error(get_type_name(),"Read response received, all data matched, but xmeta miscompared")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                            2'b00:begin
                                                `uvm_error(get_type_name(),"Read response received, but data miscompared, xmeta miscompared")
                                                `uvm_info(get_type_name(),$sformatf("the corresponding command is:\n%s",tx_cmd_queue[rx_item.CAPPTag].sprint()),UVM_MEDIUM)
                                            end
                                        endcase
                                    end
                                end
                            end
                            abstracted_byte_packet=mem_model.abstract_from_read_resp(tx_cmd_queue[rx_item.CAPPTag],rx_item); //abstract_from_read_resp with original cmd
                            fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                            for(int i=0; i<8; i++) begin
                                for(int j=0; j<8; j++)
                                    resp_to_drv.rx_data_carrier[i][(j*8+7) -:8]= abstracted_byte_packet[i*8+j].byte_data;
                            end
                            tl_drv_resp_ap.write(resp_to_drv);
                            `uvm_info(get_type_name(),$sformatf("Scoreboard send read response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)

                            if(!((rx_item.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_item.resp_code==4'b0010)))
                                mem_model.set_writable_tag(tx_cmd_queue[rx_item.CAPPTag], (cfg_obj.half_dimm_mode&cfg_obj.cfg_enterprise_mode));  //handle the writable_tag array in mem_model
                            tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in tx_cmd_queue 
                            all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                        end
                        default: `uvm_error(get_type_name(),"Illegal response opcode")
                    endcase
                end        //finish handling read_response group
                tl_rx_trans::MEM_CNTL_DONE:begin
                    fill_resp_to_drv(tx_cmd_queue[rx_item.CAPPTag],rx_item,resp_to_drv);
                    tl_drv_resp_ap.write(resp_to_drv);
                    `uvm_info(get_type_name(),$sformatf("Scoreboard send mem_cntl_done response to driver:\n%s",resp_to_drv.sprint()),UVM_HIGH)

                    tx_cmd_queue.delete(rx_item.CAPPTag);             // clear the item in tx_cmd_queue 
                    all_resp_received_flag[rx_item.CAPPTag]=1;        // inform the time-out watcher that all required responses are received.
                end
                default: `uvm_error(get_type_name(),"Unkonw opcode in tl_rx_trans")
            endcase
        end
        else if((rx_item.is_cmd==0)&&(!tx_cmd_queue.exists(rx_item.CAPPTag))) 
            `uvm_error(get_type_name(),"Response received from DUT, while no matching tx_cmd is found")
        else if(rx_item.is_cmd==1)begin                  // handling cmd received by rx monitor
            case(rx_item.packet_type)
                tl_rx_trans::ASSIGN_ACTAG:;
                tl_rx_trans::INTRP_REQ_D:;
                tl_rx_trans::INTRP_REQ:begin
                    rx_cmd_queue[rx_item.CAPPTag]=rx_item;
                    all_resp_received_flag[rx_item.CAPPTag]=0;
                    fork  : timeout_block_rx
                        begin
                            fork
                                #(cfg_obj.host_receive_resp_timer * 1ns)
                                `uvm_error(get_type_name(),$sformatf("Time_out for rx_cmd with no or not enough response. Cmd is:\n%s",rx_item.sprint()));
                            join_none
                            wait((all_resp_received_flag[rx_item.CAPPTag]==1)||(reset_rx_timeout_thread==1));
                            if(reset_rx_timeout_thread==1)begin
                                reset_rx_timeout_thread=0;
                                disable fork;
                            end
                            else begin
                                void'(all_resp_received_flag.delete(rx_item.CAPPTag));
                                disable fork;  
                            end
                        end
                    join_none
                end
                tl_rx_trans::RD_WNITC:;
                tl_rx_trans::PR_RD_WNITC:;
                tl_rx_trans::DMA_W:;
                tl_rx_trans::DMA_W_BE:;
                tl_rx_trans::DMA_PR_W:;
                default: `uvm_error(get_type_name(),"Unkown cmd or resp opcode found at rx")
            endcase
        end
    endfunction: write_rx_mon

    function void reset();
        tx_cmd_queue.delete();
        tx_resp_queue.delete();
        rx_cmd_queue.delete();
        rx_resp_queue.delete();
        tx_cmd_packet_queue.delete();
        tx_resp_packet_queue.delete();
        rx_cmd_packet_queue.delete();
        rx_resp_packet_queue.delete();
        all_resp_received_flag.delete();
        reset_tx_timeout_thread=1;
        reset_rx_timeout_thread=1;
    endfunction

    function void error_checking(tl_tx_trans tx_cmd, tl_rx_trans rx_resp);
        `uvm_info(get_type_name(),$psprintf("Error checking begin"), UVM_MEDIUM)
        case(tx_cmd.packet_type)
            tl_tx_trans::CONFIG_READ : begin
                if((tx_cmd.physical_addr[23:19]!=0)||(tx_cmd.physical_addr[18:16]>1))begin  //The device and function number not recognized
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1110: Device and function number not recognized, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1110: Device and function number not recognized, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(tx_cmd.config_type!=0)begin    // Config_type invalid
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1110: Config_type not being 0, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1110: Config_type not being 0, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0))||((tx_cmd.plength==1)&&(tx_cmd.physical_addr[0]!=0)))begin  //Bad address, not aligned
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(tx_cmd.plength>2)begin  //Unsupported operand length
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end                
            end
            tl_tx_trans::PR_RD_MEM : begin
                if(tx_cmd.physical_addr[63:35]==cfg_obj.mmio_space_base[63:35])   begin//MMIO access
                    if((cfg_obj.ocapi_version==tl_cfg_obj::OPENCAPI_3_1)&&(tx_cmd.physical_addr>cfg_obj.mmio_space_base+32'h400841FF)&&(tx_cmd.physical_addr<cfg_obj.mmio_space_base+32'h40084240))begin  //sensor cache reg
                        if(tx_cmd.physical_addr[4:0]!=0)begin  //Bad address, not aligned
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end

                        end                             
                        if(tx_cmd.plength<5)begin  //Unsupported operand length
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end                       
                    end
                    else if((cfg_obj.ocapi_version==tl_cfg_obj::OPENCAPI_3_1)&&is_in_mscc_space(tx_cmd.physical_addr)) begin  //In MSCC space
                        if ((!is_in_mscc_valid(tx_cmd.physical_addr))||(is_in_mscc_hole(tx_cmd.physical_addr))) begin   // Not in MSCC valid range or in mscc hole, bad address
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: MSCC space read, but not in valid space, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: MSCC space read, but not in valid space, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end
                        else if(is_in_mscc_ram(tx_cmd.physical_addr))begin // In MSCC range, RAM
                            if(((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))||((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0)))  begin  //Bad address, not aligned
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                                
                            if(!((tx_cmd.plength==3)||(tx_cmd.plength==2)))begin  //Unsupported operand length
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                            
                        end
                        else  begin  // ROM or REG
                            if((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0))begin  //Bad address, not aligned
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                                
                            if(tx_cmd.plength!=2)begin  //Unsupported operand length
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                                    
                        end
                    end
                    else if(is_in_ibm_space(tx_cmd.physical_addr))begin    //  In ibm space
                        if((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))begin  //Bad address, not aligned
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end                            
                        if(tx_cmd.plength!=3 && cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1)begin  //Unsupported operand length
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end                        
                    end
                    else begin     // Invalid MMIO addr
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Invalid MMIO addr, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1011: Invalid MMIO addr, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                end
                else begin       //  memory access
                    if(tx_cmd.physical_addr>=(cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size))begin     //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                                             
                    if(((tx_cmd.plength==1)&&(tx_cmd.physical_addr[0]!=0))||((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0))||((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))||((tx_cmd.plength==4)&&(tx_cmd.physical_addr[3:0]!=0))||((tx_cmd.plength==5)&&(tx_cmd.physical_addr[4:0]!=0)))begin    //Bad address, not aligned
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1011)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, respode 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                        end
                    end
                    if((!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)))&&(cfg_obj.low_latency_mode==1))begin     //non-half dimm mode and low latency mode
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: PR_RD(memory) in non-half dimm mode and low latency mode, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: PR_RD(memory) in non-half dimm mode and low latency mode, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
            end
            tl_tx_trans::RD_MEM : begin
                if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))) begin    //non-half dimm mode
                    if(tx_cmd.physical_addr>=cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size)begin        //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                        
                    if((tx_cmd.dlength==0)||(tx_cmd.dlength==3))begin    //Unsupported operand length
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                end
                else begin      //half dimm mode
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)&&(rx_resp.resp_code==4'b1001)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_RD_FAIL with resp_code 4'b1001: RD_MEM invalid in half dimm mode, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_RD_FAIL received, resp_code 4'b1001:  RD_MEM invalid in half dimm mode, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
            end
            tl_tx_trans::CONFIG_WRITE : begin
                if((tx_cmd.physical_addr[23:19]!=0)||(tx_cmd.physical_addr[18:16]>1))begin  //The device and function number not recognized
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Device and function number not recognized, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Device and function number not recognized, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(tx_cmd.config_type!=0)begin    // Config_type invalid
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Config_type not being 0, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Config_type not being 0, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(((tx_cmd.plength==1)&&(tx_cmd.physical_addr[0]==1))||((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=2'b00)))begin     //   Bad address specification, not aligned address
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(tx_cmd.plength>2)begin  //Unsupported operand length
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                if(tx_cmd.data_error[0][0]==1)begin     //   Bad data indication
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1000)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1000: Bad data indication, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1000: Bad data indication, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end                
            end
            tl_tx_trans::PR_WR_MEM : begin
                if(tx_cmd.physical_addr[63:35]==cfg_obj.mmio_space_base[63:35])begin      //MMIO access
                    if((tx_cmd.physical_addr>cfg_obj.mmio_space_base+32'h400841FF)&&(tx_cmd.physical_addr<cfg_obj.mmio_space_base+32'h40084240))begin  //sensor cache reg
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Sensor cache write, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Sensor cache write, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    else if(is_in_mscc_space(tx_cmd.physical_addr)) begin  //In MSCC space
                        if ((!is_in_mscc_valid(tx_cmd.physical_addr))||(is_in_mscc_hole(tx_cmd.physical_addr))) begin   // Not in MSCC valid range or in mscc hole, bad address
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: MSCC space read, but not in valid space, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: MSCC space read, but not in valid space, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end                            
                        else if(is_in_mscc_ram(tx_cmd.physical_addr))begin // In MSCC range, RAM
                            if(((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))||((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0)))  begin  //Bad address, not aligned
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end
                            if(!((tx_cmd.plength==3)||(tx_cmd.plength==2)))begin  //Unsupported operand length
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                            
                        end
                        else begin // ROM or REG
                            if((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0))begin  //Bad address, not aligned
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end
                            if(tx_cmd.plength!=2)begin  //Unsupported operand length
                                if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                    `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                                else begin
                                    `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                    return;
                                end
                            end                            
                        end
                    end                    
                    else if(is_in_ibm_space(tx_cmd.physical_addr)) begin    // In ibm space
                        if((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))begin  //Bad address, not aligned
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end
                        if(tx_cmd.plength!=3 && cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1)begin  //Unsupported operand length
                            if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                                `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                            else begin
                                `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                                return;
                            end
                        end                        
                    end
                    else begin      //Invalid MMIO addr
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Invalid MMIO addr, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Invalid MMIO addr, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if(tx_cmd.data_error[0][0]==1)begin     //   Bad data indication
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1000)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1000: Bad data indication, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1000: Bad data indication, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
                else if((tx_cmd.physical_addr==cfg_obj.mmio_space_base-32)&&(cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))    begin    // write pad mem pattern
                    if(tx_cmd.data_template!=6'ha) begin   //Write data not in template A
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Write pad pattern data not in template A, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Write pad pattern data not in template A, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if(tx_cmd.plength!=5)begin  //Unsupported operand length
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                    if(tx_cmd.data_error[0][0]==1)begin     //   Bad data indication
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1000)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1000: Bad data indication, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1000: Bad data indication, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
                else begin     //sysmem access
                    if((tx_cmd.data_template!=6'ha)&&(cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)) begin   //Write data not in template A
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Write memory data not in template A , original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Write memory data not in template A, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end  
                    if(tx_cmd.physical_addr>=cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size)begin        //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if(((tx_cmd.plength==1)&&(tx_cmd.physical_addr[0]!=0))||((tx_cmd.plength==2)&&(tx_cmd.physical_addr[1:0]!=0))||((tx_cmd.plength==3)&&(tx_cmd.physical_addr[2:0]!=0))||((tx_cmd.plength==4)&&(tx_cmd.physical_addr[3:0]!=0))||((tx_cmd.plength==5)&&(tx_cmd.physical_addr[4:0]!=0)))  begin //Bad address, not aligned
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if((tx_cmd.plength!=5)&&(cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))begin  //Unsupported operand length
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
            end
            tl_tx_trans::WRITE_MEM : begin
                if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))) begin  //non half dimm mode
                    if(tx_cmd.physical_addr>=cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size)begin        //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if(((tx_cmd.dlength==1)&&(tx_cmd.physical_addr[5:0]!=0))||((tx_cmd.dlength==2)&&(tx_cmd.physical_addr[6:0]!=0)))begin     //   Bad address specification, not aligned address
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1011)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1011: Bad address specification, not aligned address, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1011: Bad address specification, not aligned address, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if((tx_cmd.dlength==0)||(tx_cmd.dlength==3))begin    //Unsupported operand length
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
                else begin   //half_dimm_mode
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: WRITE_MEM invalid in half dimm mode, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: WRITE_MEM invalid in half dimm mode, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
            end
            tl_tx_trans::WRITE_MEM_BE :begin
                if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)))  begin   //non half dimm mode
                    if(tx_cmd.physical_addr>=cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size)begin        //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                        
                end
                else begin      //half dimm mode
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: WRITE_MEM_BE invalid in half dimm mode, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: WRITE_MEM_BE invalid in half dimm mode, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
            end
            tl_tx_trans::MEM_CNTL :begin
                if(tx_cmd.cmd_flag>7) begin //invalid cmd_flag
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_CNTL_DONE)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_CNTL_DONE with resp_code 4'b1110: Invalid cmd_flag for mem_cntl, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_CNTL_DONE received, resp_code 4'b1110: Invalid cmd_flag for mem_cntl, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
            end
            tl_tx_trans::PAD_MEM :begin
                if(!((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1)))begin  //non half dimm mode
                    if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                        `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: PAD_MEM invalid in non half dimm mode, original cmd is:\n%s",tx_cmd.sprint()))
                    else begin
                        `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: PAD_MEM invalid in non half dimm mode, capp_tag:%h",rx_resp.CAPPTag))
                        return;
                    end
                end
                else begin   //half dimm mode
                    if(tx_cmd.physical_addr>=cfg_obj.sysmem_space_base+cfg_obj.sysmem_space_size)begin        //Addr (PA) above max memory size
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1110)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1110: Addr (PA) above max memory size, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1110: Addr (PA) above max memory size, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end
                    if(tx_cmd.dlength!=0)begin  //Unsupported operand length
                        if(!((rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)&&(rx_resp.resp_code==4'b1001)))
                            `uvm_error(get_type_name(),$sformatf("Expecting MEM_WR_FAIL with resp_code 4'b1001: Unsupported operand length, original cmd is:\n%s",tx_cmd.sprint()))
                        else begin
                            `uvm_warning(get_type_name(),$psprintf("MEM_WR_FAIL received, resp_code 4'b1001: Unsupported operand length, capp_tag:%h",rx_resp.CAPPTag))
                            return;
                        end
                    end                    
                end
            end
            default:;
        endcase
        if((rx_resp.packet_type==tl_rx_trans::MEM_RD_FAIL)||(rx_resp.packet_type==tl_rx_trans::MEM_WR_FAIL)||((rx_resp.packet_type==tl_rx_trans::MEM_CNTL_DONE)&&(rx_resp.resp_code==4'b1110)))
            `uvm_error(get_type_name(),$sformatf("Unexpected fail response received, original cmd is:\n%s",tx_cmd.sprint()))
    endfunction

    function void fill_resp_to_drv(tl_tx_trans cmd, tl_rx_trans resp, tl_trans resp_to_drv);
        resp_to_drv.tx_packet_type=cmd.packet_type;
        resp_to_drv.tx_config_type=cmd.config_type;
        resp_to_drv.tx_plength=cmd.plength;
        resp_to_drv.tx_dlength=cmd.dlength;
        resp_to_drv.tx_capp_tag=cmd.capp_tag;
        resp_to_drv.tx_byte_enable=cmd.byte_enable;
        resp_to_drv.tx_physical_addr=cmd.physical_addr;
        resp_to_drv.tx_cmd_flag=cmd.cmd_flag;
        resp_to_drv.tx_object_handle=cmd.object_handle;
        resp_to_drv.tx_mad=cmd.mad;
        resp_to_drv.tx_data_carrier=cmd.data_carrier;
        resp_to_drv.tx_data_error=cmd.data_error;           
        resp_to_drv.tx_meta=cmd.meta;   
        resp_to_drv.tx_xmeta=cmd.xmeta;
        resp_to_drv.tx_data_carrier_type=cmd.data_carrier_type;
       
        resp_to_drv.rx_packet_type=resp.packet_type;
        resp_to_drv.rx_CAPPTag=resp.CAPPTag;
        resp_to_drv.rx_dP=resp.dP;
        resp_to_drv.rx_dL=resp.dL;
        resp_to_drv.rx_resp_code=resp.resp_code;
        resp_to_drv.rx_R=resp.R;
        resp_to_drv.rx_data_carrier=resp.data_carrier;   
        resp_to_drv.rx_data_error=resp.data_error;
        resp_to_drv.tx_meta=cmd.meta;
        resp_to_drv.rx_xmeta=resp.xmeta;
        resp_to_drv.rx_data_carrier_type=resp.data_carrier_type;
    endfunction

    function void data_error_check(tl_rx_trans rx_item);
        for(int i=0; i<32; i++)begin
            if(rx_item.data_error[i][0]==1) begin
                `uvm_error(get_type_name(),$sformatf("Bad data detected. Response is:\n%s",rx_item.sprint()))
                break;
            end
            if(rx_item.data_error[i][2:1]==2'b11) begin
                `uvm_error(get_type_name(),$sformatf("Data UE detected. Response is:\n%s",rx_item.sprint()))
                break;
            end
            if(rx_item.data_error[i][2:1]==2'b01) begin
                `uvm_warning(get_type_name(),"Data CE detected, data is corrected by tl_rx_monitor")
                break;
            end
        end
    endfunction

    function bit is_in_mscc_space(bit [63:0] physical_addr);
        bit in_mscc_space=0;
        bit [63:0] addr_bias;
        addr_bias=physical_addr-cfg_obj.mmio_space_base;
        for(int i=0; i<18; i++) begin
            if((addr_bias>=cfg_obj.mscc_space_lower[i])&&(addr_bias<=cfg_obj.mscc_space_upper[i])) begin
                in_mscc_space=1;
                break;
            end
        end
        return in_mscc_space;
    endfunction

    function bit is_in_mscc_valid(bit [63:0] physical_addr);
        bit in_mscc_valid=0;
        bit [63:0] addr_bias;
        addr_bias=physical_addr-cfg_obj.mmio_space_base;
        for(int i=0; i<18; i++) begin
            if((addr_bias>=cfg_obj.mscc_space_lower[i])&&(addr_bias<=cfg_obj.mscc_space_valid[i])) begin
                in_mscc_valid=1;
                break;
            end
        end
        return in_mscc_valid;
    endfunction    

    function bit is_in_mscc_hole(bit [63:0] physical_addr);
        bit in_mscc_hole=0;
        bit [63:0] addr_bias;
        addr_bias=physical_addr-cfg_obj.mmio_space_base;
        for(int i=0; i<18; i++) begin
            if(cfg_obj.mscc_space_hole[i].size()>0) begin
                foreach(cfg_obj.mscc_space_hole[i][j]) begin
                    if(addr_bias==cfg_obj.mscc_space_hole[i][j]) begin
                        in_mscc_hole=1;
                        break;                        
                    end
                end
            end
        end
        return in_mscc_hole;
    endfunction   

    function bit is_in_mscc_ram(bit [63:0] physical_addr);
        bit in_mscc_ram=0;
        bit [63:0] addr_bias;
        addr_bias=physical_addr-cfg_obj.mmio_space_base;
        if((addr_bias>=cfg_obj.mscc_space_lower[`MSCC_RAM_INDEX_1])&&(addr_bias<=cfg_obj.mscc_space_upper[`MSCC_RAM_INDEX_1]))
            in_mscc_ram=1;
        return in_mscc_ram;
    endfunction

    function bit is_in_ibm_space(bit [63:0] physical_addr);
        bit in_ibm_space=0;
        bit [63:0] addr_bias;
        addr_bias=(physical_addr-cfg_obj.mmio_space_base)>>3;
        if((addr_bias>=cfg_obj.ibm_space_lower)&&(addr_bias<=cfg_obj.ibm_space_upper))
            in_ibm_space=1;
        return in_ibm_space;
    endfunction

    function void update_resp_packet_with_wr_resp(tl_rx_trans rx_item, resp_packet resp);
        int byte_num;
        int offset;
        case ({rx_item.dL,rx_item.dP})      
            5'b01000:begin
                byte_num=64;
                offset=0;
            end
            5'b01001:begin
                byte_num=64;
                offset=64;                                            
            end
            5'b01010:begin
                byte_num=64;
                offset=128;                                            
            end
            5'b01011:begin
                byte_num=64;
                offset=192;                                            
            end
            5'b10000:begin
                byte_num=128;
                offset=0;
            end
            5'b10010:begin
                byte_num=128;
                offset=128;
            end
            5'b11000:begin
                byte_num=256;
                offset=0;
            end
            default: begin
                if(cfg_obj.inject_err_enable == 1) begin
                    byte_num=32;
                    offset=0;
                end
                else
                    `uvm_error(get_type_name(),"Illegal dL and dP pair for MEM_WR_RESPONSE or MEM_WR_FAIL")
            end
        endcase        
        resp.byte_number_filled+=byte_num;
        for(int i=offset; i<offset+byte_num; i++)begin
            if(resp.write_resp_received[i]==0)begin
                if(rx_item.packet_type==tl_rx_trans::MEM_WR_RESPONSE)
                    resp.write_success_record[i]=1;
                else
                    resp.write_success_record[i]=0;
                resp.write_resp_received[i]=1;
            end
            else `uvm_error(get_type_name(),"Overlapped WRITE_RESPONSE is received")
        end
    endfunction

    function void update_resp_packet_with_rd_resp(tl_rx_trans rx_item, resp_packet resp, tl_mem_model::byte_packet_array abstracted_byte_packet);
        int byte_num;
        int offset;
        if(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_OW) begin  //MEM_RD_RESPONSE_OW
            byte_num=32;
            case(rx_item.dP)
                3'b000: offset=0;
                3'b001: offset=32;
                3'b010: offset=64;
                3'b011: offset=96;
                3'b100: offset=128;
                3'b101: offset=160;
                3'b110: offset=192;
                3'b111: offset=224;
            endcase
        end
        else begin     //MEM_RD_FAIL or MEM_RD_RESPONSE
            case ({rx_item.dL,rx_item.dP})
                5'b01000 :begin
                    byte_num=64;
                    offset=0;
                end
                5'b01001 :begin
                    byte_num=64;
                    offset=64;
                end
                5'b01010 :begin
                    byte_num=64;
                    offset=128;
                end
                5'b01011 :begin
                    byte_num=64;
                    offset=192;
                end
                5'b10000 :begin
                    byte_num=128;
                    offset=0;
                end
                5'b10010 :begin
                    byte_num=128;
                    offset=128;
                end
                5'b11000 :begin
                    byte_num=256;
                    offset=0;
                end
                default : begin
                    if(cfg_obj.inject_err_enable == 1) begin
                        byte_num=32;
                        offset=0;
                    end
                    else
                        `uvm_error(get_type_name(),"Illegal dL and dP pair for MEM_RD_RESPONSE or MEM_RD_FAIL")
                end
            endcase
        end
        resp.byte_number_filled+=byte_num;
        for(int i=offset; i<offset+byte_num; i++)begin
            if(resp.read_resp_received[i]==0)begin
                if((rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE)||(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_OW))
                    resp.read_success_record[i]=1;
                else
                    resp.read_success_record[i]=0;
                resp.read_resp_received[i]=1;
            end
            else `uvm_error(get_type_name(),"Overlapped READ_RESPONSE is received")
            resp.data_bytewise[i]=abstracted_byte_packet[i-offset];
        end
    endfunction

    function void sue_lable(resp_packet packet);
        int n=packet.byte_number_filled/64;
        while(n>0)begin
            if(packet.data_bytewise[n*64-32].mdi!=packet.data_bytewise[n*64-64].mdi) begin
                for(int i=0; i<64; i++) begin
                    packet.data_bytewise[(n-1)*64+i].sue=1;
                end
            end
            n--;
        end
    endfunction

    function void template_check_rx(tl_tx_trans cmd, tl_rx_trans resp);
        if((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))begin   //half dimm mode
            if((cmd.packet_type==tl_tx_trans::CONFIG_READ)||((cmd.packet_type==tl_tx_trans::PR_RD_MEM)&&(cmd.physical_addr[63:35]==cfg_obj.mmio_space_base[63:35])))begin
                if((resp.packet_type!=tl_rx_trans::MEM_RD_FAIL)&&(resp.data_template!=6'h9)&&(resp.data_template!=6'hf))
                    `uvm_error(get_type_name(),$sformatf("In half dimm mode, response data for config or mmio read not in data flit or template 9, capptag:%h",resp.CAPPTag))
            end
            if((cmd.packet_type==tl_tx_trans::PR_RD_MEM)&&(cmd.physical_addr[63:35]!=cfg_obj.mmio_space_base[63:35]))begin
                if((resp.packet_type!=tl_rx_trans::MEM_RD_FAIL)&&(resp.data_template!=6'hb))
                    `uvm_error(get_type_name(),$sformatf("In half dimm mode, memory read data not placed in template B, capptag:%h",resp.CAPPTag))
            end            
        end
        else begin                           //non half dimm mode
            if(resp.data_template==6'hb)
                `uvm_error(get_type_name(),$sformatf("Template B received in non half dimm mode, capptag:%h",resp.CAPPTag))
        end
    endfunction

    function bit [7:0] misr_cal(bit [63:0] in_data);
        return 8'd0;
    endfunction

    function void template_check_tx(tl_tx_trans cmd);
        if((cfg_obj.half_dimm_mode==1)&&(cfg_obj.cfg_enterprise_mode==1))begin   //half dimm mode
            if((cmd.packet_type==tl_tx_trans::CONFIG_WRITE)||((cmd.packet_type==tl_tx_trans::PR_WR_MEM)&&(cmd.physical_addr[63:35]==cfg_obj.mmio_space_base[63:35])))begin
                if((cmd.data_template!=6'h7)&&(cmd.data_template!=6'hf))
                    `uvm_error(get_type_name(),$sformatf("In half dimm mode, write data for config or mmio write not in data flit or template 7, capptag:%h",cmd.capp_tag))
            end
        end       
    endfunction

endclass: tl_scoreboard


class resp_packet extends uvm_object;
    tl_mem_model::byte_packet_array data_bytewise;  //used for both expect and actual read resp
    bit read_success_record[256]; //used for actual read resp, 0:read not succeed; 1:read succeed
    bit read_resp_received[256];  //used for actual read resp, 0:response not received; 1:response received
    bit write_success_record[256]; //used for write resp
    bit write_resp_received[256];  //used for write resp
    bit retry_flag;
    int unsigned byte_number_filled; //used for both read and write resp
    `uvm_object_utils_begin(resp_packet)
    `uvm_object_utils_end

    function new(string name="resp_packet");
        super.new(name);
        byte_number_filled=0;
        foreach(read_success_record[i])
            read_success_record[i]=0;
        foreach(read_resp_received[i])
            read_resp_received[i]=0;
        foreach(write_success_record[i])
            write_success_record[i]=0;
        foreach(write_resp_received[i])
            write_resp_received[i]=0;
        foreach(data_bytewise[i])begin
            data_bytewise[i].byte_data=0;
            data_bytewise[i].data_exist=0;
            data_bytewise[i].itag=0;
            data_bytewise[i].mdi=0;
        end
        retry_flag=0;
    endfunction
endclass: resp_packet

`endif
