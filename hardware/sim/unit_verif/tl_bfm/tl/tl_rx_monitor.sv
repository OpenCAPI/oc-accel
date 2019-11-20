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
`ifndef _TL_RX_MONITOR_SV
`define _TL_RX_MONITOR_SV

class tl_rx_monitor extends uvm_monitor;

    //Virtual interface definition
    virtual interface tl_dl_if             tl_dl_vif;
    //Configuration
    tl_cfg_obj                             cfg_obj;

    //TLM port & transaction declaration
    uvm_analysis_port #(tl_rx_trans)       tl_rx_ap;
    uvm_analysis_port #(dl_credit_trans)   tl_rx2mgr_ap;
    tl_rx_trans                            tl_rx_trans_1;
    dl_credit_trans                        dl_credit_trans_1;

    //Data structure for collecting and parsing data.
    class tl_rx_mon_data;
        bit [511:0]                        data_q[$];
        bit [1:0]                          ecc_err_q[$];
        bit [2:0]                          data_err_q[$];
        bit [511:0]                        flit_q[$];
        bit [511:0]                        prefetch_data_flit_q[$];
        bit                                prefetch_bad_data_flit_q[$];
        bit                                flit_err;
        
        bit [167:0]                        packet_q[$];
        bit [167:0]                        wait_packet_q[$];
        
        bit [6:0]                          mdf_q[$];
        bit [6:0]                          meta_q[$];
        bit [71:0]                         xmeta_q[$];
        
        bit [63:0]                         data_carrier_q[$];
        int                                data_carrier_type_q[$];
        bit [5:0]                          data_template_q[$];
        
        int                                data_flit_count = 0;
        bit [3:0]                          drl = 0;
        bit [7:0]                          bad_data_flit = 0;
        int                                credit_flag=0;
        bit                                is_ctrl_flit;

        int                                tl_vc0;
        int                                tl_vc1;
        int                                tl_dcp0;
        int                                tl_dcp1;
        int                                return_tl_credit_count = 0;
        bit                                return_tl_credit = 1;
        bit                                initial_return_credit_check = 1; // Enable initial RETURN_TL_CREDIT Check

        real                               coll_ctrl_time;
        real                               cmd_time_q[$];

        function new(string name = "tl_rx_mon_data");
        endfunction
    endclass: tl_rx_mon_data
    
    //Define a data structure for rx_mon
    tl_rx_mon_data                         rx_mon_data;

    //Define global events
    event                                  get_data;
    event                                  get_flit;

    //Coverage    
    bit coverage_on = 0;
    int                                    cov_template;
    tl_rx_trans::packet_type_enum          cov_first_packet;
    tl_rx_trans::packet_type_enum          cov_second_packet;
    int                                    cov_run_length;
    bit [7:0]                              cov_bad_data_flit;
    bit [1:0]                              cov_slot_data_valid;

    covergroup c_packets_and_template;
        option.per_instance = 1;
        tl_rx_packet_type:              coverpoint cov_first_packet{
                                            bins assign_actag = {tl_rx_trans::ASSIGN_ACTAG};
                                            bins intrp_req = {tl_rx_trans::INTRP_REQ};
                                            bins mem_cntl_done = {tl_rx_trans::MEM_CNTL_DONE};
                                            bins nop = {tl_rx_trans::NOP_R};
                                            bins return_tl_credits = {tl_rx_trans::RETURN_TL_CREDITS};
                                            bins mem_rd_fail = {tl_rx_trans::MEM_RD_FAIL};
                                            bins mem_rd_response = {tl_rx_trans::MEM_RD_RESPONSE};
                                            bins mem_rd_response_ow = {tl_rx_trans::MEM_RD_RESPONSE_OW};
                                            bins mem_wr_fail = {tl_rx_trans::MEM_WR_FAIL};
                                            bins mem_wr_response = {tl_rx_trans::MEM_WR_RESPONSE};
                                        }
        tl_rx_packet_type_2nd:          coverpoint cov_second_packet{
                                            bins assign_actag = {tl_rx_trans::ASSIGN_ACTAG};
                                            bins intrp_req = {tl_rx_trans::INTRP_REQ};
                                            bins mem_cntl_done = {tl_rx_trans::MEM_CNTL_DONE};
                                            bins nop = {tl_rx_trans::NOP_R};
                                            bins return_tl_credits = {tl_rx_trans::RETURN_TL_CREDITS};
                                            bins mem_rd_fail = {tl_rx_trans::MEM_RD_FAIL};
                                            bins mem_rd_response = {tl_rx_trans::MEM_RD_RESPONSE};
                                            bins mem_rd_response_ow = {tl_rx_trans::MEM_RD_RESPONSE_OW};
                                            bins mem_wr_fail = {tl_rx_trans::MEM_WR_FAIL};
                                            bins mem_wr_response = {tl_rx_trans::MEM_WR_RESPONSE};
                                        }
        tl_rx_two_continue_packet_type: cross tl_rx_packet_type,tl_rx_packet_type_2nd;

        tl_rx_template:                 coverpoint cov_template{
                                            bins template0 = {0};
                                            bins template1 = {1};
                                            bins template5 = {5};
                                            bins template9 = {9};
                                        }
        tl_rx_packet_type_in_template:  cross tl_rx_packet_type,tl_rx_template{
                                            ignore_bins impossible = binsof(tl_rx_packet_type.intrp_req) && binsof(tl_rx_template.template9);
                                        }
    endgroup: c_packets_and_template

    covergroup c_rx_tl_content;
        option.per_instance = 1;
        tl_rx_template:                 coverpoint cov_template{
                                            bins template0 = {0};
                                            bins template1 = {1};
                                            bins template5 = {5};
                                            bins template9 = {9};
                                        }
        tl_rx_data_run_length:          coverpoint cov_run_length{
                                            bins length0 = {0};
                                            bins length1 = {1};
                                            bins length2 = {2};
                                        }
        tl_rx_run_length_in_template:   cross tl_rx_data_run_length,tl_rx_template;

        tl_rx_bad_data_flit:            coverpoint cov_bad_data_flit{
                                            bins good_data  = {8'h00};
                                            bins bad_data0  = {8'h01};
                                            bins bad_data1  = {8'h02};
                                            bins bad_data01 = {8'h03};
                                        }
        tl_rx_bad_data_flit_in_template:cross tl_rx_bad_data_flit,tl_rx_template;

        tl_rx_slot_data_valid:          coverpoint cov_slot_data_valid{
                                            bins good_data    = {2'b10};
                                            bins bad_data     = {2'b11};
                                            bins invalid_data = {2'b00,2'b01};
                                        }
    endgroup: c_rx_tl_content

    covergroup c_ocapi_tl_rx_packet;
        option.per_instance = 1;
        packet_type:                    coverpoint tl_rx_trans_1.packet_type{
                                            bins assign_actag = {tl_rx_trans::ASSIGN_ACTAG};
                                            bins intrp_req = {tl_rx_trans::INTRP_REQ};
                                            bins mem_cntl_done = {tl_rx_trans::MEM_CNTL_DONE};
                                            bins nop = {tl_rx_trans::NOP_R};
                                            bins return_tl_credits = {tl_rx_trans::RETURN_TL_CREDITS};
                                            bins mem_rd_fail = {tl_rx_trans::MEM_RD_FAIL};
                                            bins mem_rd_response = {tl_rx_trans::MEM_RD_RESPONSE};
                                            bins mem_rd_response_ow = {tl_rx_trans::MEM_RD_RESPONSE_OW};
                                            bins mem_wr_fail = {tl_rx_trans::MEM_WR_FAIL};
                                            bins mem_wr_response = {tl_rx_trans::MEM_WR_RESPONSE};
                                        }
        data_length:                    coverpoint tl_rx_trans_1.dL{
                                            bins byte64  = {2'b01};
                                            bins byte128 = {2'b10};
                                        }
        data_part:                      coverpoint tl_rx_trans_1.dP{
                                            bins part0 = {3'b000};
                                            bins part1 = {3'b001};
                                            bins part2 = {3'b010};
                                            bins part3 = {3'b011};
                                        }
        resp_code:                      coverpoint tl_rx_trans_1.resp_code{
                                            bins code_0000 = {4'b0000};
                                            bins code_0010 = {4'b0010};
                                            bins code_1000 = {4'b1000};
                                            bins code_1001 = {4'b1001};
                                            bins code_1011 = {4'b1011};
                                            bins code_1110 = {4'b1110};
                                        }
        cmd_flag:                       coverpoint tl_rx_trans_1.cmd_flag{
                                            bins flag_0000 = {4'b0000};
                                            bins flag_0001 = {4'b0001};
                                            bins flag_0010 = {4'b0010};
                                            bins flag_0011 = {4'b0011};
                                        }
        packet_mem_rd_response:         cross packet_type,data_length,data_part{
                                            bins rd_byte64_dp0  = binsof(packet_type.mem_rd_response) && binsof(data_length.byte64) && binsof(data_part.part0);
                                            bins rd_byte64_dp1  = binsof(packet_type.mem_rd_response) && binsof(data_length.byte64) && binsof(data_part.part1);
                                            bins rd_byte128_dp0 = binsof(packet_type.mem_rd_response) && binsof(data_length.byte128) && binsof(data_part.part0);
                                            bins ignore = binsof(packet_type) && binsof(data_length) && binsof(data_part);
                                        }
        packet_mem_rd_response_ow:      cross packet_type,data_part{
                                            bins rd_ow_dp0 = binsof(packet_type.mem_rd_response_ow) && binsof(data_part.part0);
                                            bins rd_ow_dp1 = binsof(packet_type.mem_rd_response_ow) && binsof(data_part.part1);
                                            bins rd_ow_dp2 = binsof(packet_type.mem_rd_response_ow) && binsof(data_part.part2);
                                            bins rd_ow_dp3 = binsof(packet_type.mem_rd_response_ow) && binsof(data_part.part3);
                                            bins ignore = binsof(packet_type) && binsof(data_part);
                                        }
        packet_mem_rd_fail:             cross packet_type,resp_code{
                                            bins rd_fail_code0010 = binsof(packet_type.mem_rd_fail) && binsof(resp_code.code_0010);
                                            bins rd_fail_code1000 = binsof(packet_type.mem_rd_fail) && binsof(resp_code.code_1000);
                                            bins rd_fail_code1001 = binsof(packet_type.mem_rd_fail) && binsof(resp_code.code_1001);
                                            bins rd_fail_code1011 = binsof(packet_type.mem_rd_fail) && binsof(resp_code.code_1011);
                                            bins rd_fail_code1110 = binsof(packet_type.mem_rd_fail) && binsof(resp_code.code_1110);
                                            bins ignore = binsof(packet_type) && binsof(resp_code);
                                        }
        packet_mem_wr_response:         cross packet_type,data_length,data_part{
                                            bins wr_byte64_dp0  = binsof(packet_type.mem_wr_response) && binsof(data_length.byte64) && binsof(data_part.part0);
                                            bins wr_byte64_dp1  = binsof(packet_type.mem_wr_response) && binsof(data_length.byte64) && binsof(data_part.part1);
                                            bins wr_byte128_dp0 = binsof(packet_type.mem_wr_response) && binsof(data_length.byte128) && binsof(data_part.part0);
                                            bins ignore = binsof(packet_type) && binsof(data_length) && binsof(data_part);
                                        }
        packet_mem_wr_fail:             cross packet_type,resp_code{
                                            bins wr_fail_code0010 = binsof(packet_type.mem_wr_fail) && binsof(resp_code.code_0010);
                                            bins wr_fail_code1000 = binsof(packet_type.mem_wr_fail) && binsof(resp_code.code_1000);
                                            bins wr_fail_code1001 = binsof(packet_type.mem_wr_fail) && binsof(resp_code.code_1001);
                                            bins wr_fail_code1011 = binsof(packet_type.mem_wr_fail) && binsof(resp_code.code_1011);
                                            bins wr_fail_code1110 = binsof(packet_type.mem_wr_fail) && binsof(resp_code.code_1110);
                                            bins ignore = binsof(packet_type) && binsof(resp_code);
                                        }
        packet_mem_cntl_done:           cross packet_type,resp_code{
                                            bins mem_cntl_done_code0000 = binsof(packet_type.mem_cntl_done) && binsof(resp_code.code_0000);
                                            bins mem_cntl_done_code1110 = binsof(packet_type.mem_cntl_done) && binsof(resp_code.code_1110);
                                            bins ignore = binsof(packet_type) && binsof(resp_code);
                                        }
        packet_intrp_req:               cross packet_type,cmd_flag{
                                            bins intrp_req_flag0000 = binsof(packet_type.intrp_req) && binsof(cmd_flag.flag_0000);
                                            bins intrp_req_flag0001 = binsof(packet_type.intrp_req) && binsof(cmd_flag.flag_0001);
                                            bins intrp_req_flag0010 = binsof(packet_type.intrp_req) && binsof(cmd_flag.flag_0010);
                                            bins intrp_req_flag0011 = binsof(packet_type.intrp_req) && binsof(cmd_flag.flag_0011);
                                            bins ignore = binsof(packet_type) && binsof(cmd_flag);
                                        }
    endgroup: c_ocapi_tl_rx_packet

    `uvm_component_utils_begin(tl_rx_monitor)
        `uvm_field_int(coverage_on, UVM_ALL_ON)
    `uvm_component_utils_end

    function new (string name="tl_rx_monitor", uvm_component parent);
        super.new(name, parent);
        rx_mon_data        = new("rx_mon_data");
        tl_rx_trans_1      = new("tl_rx_trans_1");
        dl_credit_trans_1  = new("dl_credit_trans_1");
        tl_rx_ap           = new("tl_rx_ap", this);
        tl_rx2mgr_ap       = new("tl_rx2mgr_ap", this);

        void'(uvm_config_db#(int)::get(this,"","coverage_on",coverage_on));
        if(coverage_on) begin
            c_rx_tl_content=new();
            c_rx_tl_content.set_inst_name({get_full_name(),".c_rx_tl_content"});
            c_ocapi_tl_rx_packet=new();
            c_ocapi_tl_rx_packet.set_inst_name({get_full_name(),".c_ocapi_tl_rx_packet"});
            c_packets_and_template=new();
            c_packets_and_template.set_inst_name({get_full_name(),".c_packets_and_template"});
        end
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual tl_dl_if)::get(this, "","tl_dl_vif",tl_dl_vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".tl_dl_vif"})
    endfunction: build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        if(!uvm_config_db#(tl_cfg_obj)::get(this, "", "cfg_obj", cfg_obj))
            `uvm_error(get_type_name(), "Can't get cfg_obj!")

        // Get cfg_obj info for first two RETURN_TL_CREDIT check
        rx_mon_data.tl_vc0  = cfg_obj.tl_vc_credit_count[0];
        rx_mon_data.tl_vc1  = cfg_obj.tl_vc_credit_count[1];
        rx_mon_data.tl_dcp0 = cfg_obj.tl_data_credit_count[0];
        rx_mon_data.tl_dcp1 = cfg_obj.tl_data_credit_count[1];
    endfunction: start_of_simulation_phase

    //Run phase and collection functions
    task main_phase(uvm_phase phase);
        fork
            collect_data();
            assemble_flit();
            parse_flit();
            assemble_trans();
        join
    endtask

    function void reset();
        rx_mon_data.data_q.delete();
        rx_mon_data.flit_q.delete();
        rx_mon_data.data_err_q.delete();
        rx_mon_data.ecc_err_q.delete();
        rx_mon_data.packet_q.delete();
        rx_mon_data.wait_packet_q.delete();
        rx_mon_data.mdf_q.delete();
        rx_mon_data.meta_q.delete();
        rx_mon_data.xmeta_q.delete();
        rx_mon_data.data_carrier_q.delete();
        rx_mon_data.prefetch_data_flit_q.delete();
        rx_mon_data.prefetch_bad_data_flit_q.delete();
        rx_mon_data.data_carrier_type_q.delete();

        rx_mon_data.flit_err = 0;
        rx_mon_data.data_flit_count = 0;
        rx_mon_data.drl = 4'b0;
        rx_mon_data.bad_data_flit = 8'b0;
        rx_mon_data.is_ctrl_flit = 0;
        rx_mon_data.credit_flag = 0;
    endfunction


    task collect_data();
        //collect data from dl
        if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin
            forever begin
                @(posedge tl_dl_vif.clock);
                if(tl_dl_vif.tl_dl_flit_vld) begin
                    if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1) begin
                        bit [127:0] temp_data;
                        bit [15:0]  temp_ecc;

                        // LBIP data & ECC function disable now
                        //                    bit [127:0] temp_lbip_data;
                        //                    bit [15:0]  temp_lbip_ecc;
                        //                    if(tl_dl_vif.tl_dl_flit_lbip_vld) begin
                        //                        temp_lbip_data = {46'b0, tl_dl_vif.tl_dl_flit_lbip_data};
                        //                        temp_lbip_ecc  = tl_dl_vif.tl_dl_flit_lbip_ecc;
                        //                        ecc_check({46'b0, tl_dl_vif.tl_dl_flit_lbip_data}, tl_dl_vif.tl_dl_flit_lbip_ecc);
                        //                    end

                        temp_data = tl_dl_vif.tl_dl_flit_data[127:0];
                        temp_ecc  = tl_dl_vif.tl_dl_flit_ecc;
                        ecc_check(temp_data, temp_ecc);
                        rx_mon_data.data_q.push_back(temp_data);

                        //collect credit information
                        dl_credit_trans_1.return_credit = 1;
                        tl_rx2mgr_ap.write(dl_credit_trans_1);
                        dl_credit_trans_1 = dl_credit_trans::type_id::create("dl_credit_trans_1", this);
                    end else if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                        bit [511:0] temp_data;

                        // LBIP data & ECC function disable now
                        //                    bit [127:0] temp_lbip_data;
                        //                    bit [15:0]  temp_lbip_ecc;
                        //                    if(tl_dl_vif.tl_dl_flit_lbip_vld) begin
                        //                        temp_lbip_data = {46'b0, tl_dl_vif.tl_dl_flit_lbip_data};
                        //                        temp_lbip_ecc  = tl_dl_vif.tl_dl_flit_lbip_ecc;
                        //                        ecc_check({46'b0, tl_dl_vif.tl_dl_flit_lbip_data}, tl_dl_vif.tl_dl_flit_lbip_ecc);
                        //                    end

                        temp_data = tl_dl_vif.tl_dl_flit_data;
                        rx_mon_data.data_q.push_back(temp_data);

                        //collect credit information
                        dl_credit_trans_1.return_credit = 1;
                        tl_rx2mgr_ap.write(dl_credit_trans_1);
                        dl_credit_trans_1 = dl_credit_trans::type_id::create("dl_credit_trans_1", this);

                    end
                    ->get_data;
                end
            end
        end
        else begin
            forever begin
                //collect credit information
                @(negedge tl_dl_vif.clock);
                if(tl_dl_vif.dl_tl_flit_credit) begin
                    dl_credit_trans_1.return_credit = 1;
                    tl_rx2mgr_ap.write(dl_credit_trans_1);
                    dl_credit_trans_1 = dl_credit_trans::type_id::create("dl_credit_trans_1", this);
                end
            
                //monitor information
                @(posedge tl_dl_vif.clock);
                rx_mon_data.flit_err = tl_dl_vif.dl_tl_flit_error;
                if(rx_mon_data.flit_err)
                    discard_data_flit();

                if(rx_mon_data.flit_err || (!tl_dl_vif.dl_tl_link_up)) begin
                    if((rx_mon_data.data_q.size != 0) && ((rx_mon_data.data_q.size)%4 == 1)) begin
                        bit [127:0] temp_data;
                        temp_data = rx_mon_data.data_q.pop_front;
                    end
                    if((rx_mon_data.data_q.size != 0) && ((rx_mon_data.data_q.size)%4 == 2)) begin
                        bit [127:0] temp_data;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                    end
                    if((rx_mon_data.data_q.size != 0) && ((rx_mon_data.data_q.size)%4 == 3)) begin
                        bit [127:0] temp_data;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                    end
                    if((rx_mon_data.data_q.size != 0) && ((rx_mon_data.data_q.size)%4 == 0)) begin
                        bit [127:0] temp_data;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                        temp_data = rx_mon_data.data_q.pop_front;
                    end
                end
                
                if(tl_dl_vif.dl_tl_flit_vld) begin
                    bit [127:0] temp_data;
                    bit [15:0]  temp_pty;

                    //OpenCapi link trained check
                    if(~tl_dl_vif.dl_tl_link_up) begin
                        `uvm_info(get_type_name(), "Note: The flit valid is asserted when link up is down", UVM_MEDIUM);
                    end

                    temp_data = tl_dl_vif.dl_tl_flit_data;
                    temp_pty  = tl_dl_vif.dl_tl_flit_pty;
                    
                    //Parity check
                    parity_check(temp_data, temp_pty);

                    rx_mon_data.data_q.push_back(temp_data);
                    rx_mon_data.ecc_err_q.push_back(2'b00);
                    ->get_data;
                end
            end
        end
    endtask : collect_data

    function void ecc_check(ref bit [127:0] data, ref bit [15:0] ecc);
        //64-8 bit ecc table
        byte ecc_pat[72] = '{8'hc4, 8'h8c, 8'h94, 8'hd0, 8'hf4, 8'hb0, 8'ha8, 8'he0,
					  8'h62, 8'h46, 8'h4a, 8'h68, 8'h7a, 8'h58, 8'h54, 8'h70,
					  8'h31, 8'h23, 8'h25, 8'h34, 8'h3d, 8'h2c, 8'h2a, 8'h38,
					  8'h98, 8'h91, 8'h92, 8'h1a, 8'h9e, 8'h16, 8'h15, 8'h1c,
					  8'h4c, 8'hc8, 8'h49, 8'h0d, 8'h4f, 8'h0b, 8'h8a, 8'h0e,
					  8'h26, 8'h64, 8'ha4, 8'h86, 8'ha7, 8'h85, 8'h45, 8'h07,
					  8'h13, 8'h32, 8'h52, 8'h43, 8'hd3, 8'hc2, 8'ha2, 8'h83,
					  8'h89, 8'h19, 8'h29, 8'ha1, 8'he9, 8'h61, 8'h51, 8'hc1, 8'hc7,
					  8'h80, 8'h40, 8'h20, 8'h10, 8'h08, 8'h04, 8'h02};

        bit [7:0] ecc_syndrome_0, ecc_syndrome_1;
        bit [31:0] bit_pos, bit_mask, bad_bit, qw0, qw1, qw2, qw3;
        
        qw0 = data[127:96];
        qw1 = data[95:64];
        qw2 = data[63:32];
        qw3 = data[31:0];

        //generate ecc according to the data
        ecc_syndrome_0 = 8'h00;
        ecc_syndrome_1 = 8'h00;
        bit_pos = 0;

        for( bit_mask = (1<<31); bit_mask; ++bit_pos) begin
            if(qw0 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos];
            if(qw1 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos+32];

            if(qw2 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos];
            if(qw3 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos+32];
            bit_mask >>= 1;
        end

        //check ecc with input ecc
        ecc_syndrome_0 ^= ecc[15:8];
        ecc_syndrome_1 ^= ecc[7:0];

        if(ecc_syndrome_1 == 0) begin                   //First 64bits
            bit [1:0] ecc_error = 2'b00;                //No error
            rx_mon_data.ecc_err_q.push_back(ecc_error);    //For 8byte
        end
        else begin
            bit bad_bit_found = 0;
            bad_bit = 0;
            while(!bad_bit_found && (bad_bit < 72)) begin
                if(ecc_syndrome_1 == ecc_pat[bad_bit]) bad_bit_found = 1;
                else bad_bit++;
            end

            if(!bad_bit_found) begin
                bit [1:0] ecc_error = 2'b11;               //Uncorrectable Error
                rx_mon_data.ecc_err_q.push_back(ecc_error);   //For 8byte
            end
            else begin
                bit [1:0] ecc_error = 2'b01;               //Correctable Error
                rx_mon_data.ecc_err_q.push_back(ecc_error);   //For 8byte
                if(bad_bit > 64) data[63:0] ^= 1'b1 << (63 - bad_bit);
                else ecc[7:0] ^= 1'b1 << (72 - bad_bit);
            end
        end

        if(ecc_syndrome_0 == 0) begin                  //Second 64bits
            bit [1:0] ecc_error = 2'b00;               //No error
            rx_mon_data.ecc_err_q.push_back(ecc_error);   //For 8byte
        end
        else begin
            bit bad_bit_found = 0;
            bad_bit = 0;
            while(!bad_bit_found && (bad_bit < 72)) begin
                if(ecc_syndrome_0 == ecc_pat[bad_bit]) bad_bit_found = 1;
                else bad_bit++;
            end

            if(!bad_bit_found) begin
                bit [1:0] ecc_error = 2'b11;               //Uncorrectable Error
                rx_mon_data.ecc_err_q.push_back(ecc_error);   //For 8byte
            end
            else begin
                bit [1:0] ecc_error = 2'b01;               //Correctable Error
                rx_mon_data.ecc_err_q.push_back(ecc_error);   //For 8byte
                if(bad_bit > 64) data[127:64] ^= 1'b1 << (63 - bad_bit);
                else ecc[15:8] ^= 1'b1 << (72 - bad_bit);
            end
        end
    endfunction

    //Parity check function
    function void parity_check(bit [127:0] data, bit [15:0] pty);
        bit [15:0] flit_pty_check;
        for(int i=0; i<16; i++) begin
            flit_pty_check[i] = ^data[(8*i + 7) -: 8];
            if(flit_pty_check[i] != pty[i]) begin
                `uvm_fatal(get_type_name(), "Parity Check UE");
            end
        end
    endfunction
        
    task assemble_flit();
        forever begin
            @get_data;
            //assemble data to flit
            if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1) begin
                if((rx_mon_data.data_q.size % 4 == 0) && (rx_mon_data.data_q.size > 0))  begin
                    bit[511:0] temp_flit;
                    for(int i=0; i<4; i++) begin
                        temp_flit = {rx_mon_data.data_q.pop_front, temp_flit[511:128]};
                    end
                    rx_mon_data.flit_q.push_back(temp_flit);
                end
            end else if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                    bit[511:0] temp_flit;
                    temp_flit = rx_mon_data.data_q.pop_front;
                    rx_mon_data.flit_q.push_back(temp_flit);
            end
            ->get_flit;
        end
    endtask : assemble_flit

                
    task parse_flit();
        forever begin
            //parse control flit
            bit is_ctl_flit;
            @get_flit;

            while(rx_mon_data.flit_q.size != 0) begin
                bit [511:0] temp_flit;
                temp_flit = rx_mon_data.flit_q.pop_front;

                is_ctl_flit = (rx_mon_data.data_flit_count == rx_mon_data.drl);
                rx_mon_data.is_ctrl_flit = is_ctl_flit;

                if(is_ctl_flit) begin
                    bit [447:0] tlc;
                    bit [5:0]   tlt;
                    bit [1:0]   temp_ecc_err;

                    //Check ECC error
                    for(int i=0; i<4; i++) begin
                        if(rx_mon_data.ecc_err_q[i] == 2'b11) begin
                            `uvm_fatal(get_type_name(), "Ecc UE in control flit");
                        end
                    end

                    rx_mon_data.coll_ctrl_time = $realtime;
                    @(posedge tl_dl_vif.clock);

                    if(!rx_mon_data.flit_err) begin
                        tlc                       = temp_flit[447:0];    //TL Content
                        rx_mon_data.drl           = temp_flit[451:448];  //runlength
                        rx_mon_data.bad_data_flit = temp_flit[459:452];  //Bad flit
                        tlt                       = temp_flit[465:460];  //Template

                   // initial RETURN_TL_CREDIT Check 
                        if(rx_mon_data.initial_return_credit_check) begin
                            if(rx_mon_data.return_tl_credit) begin
                                if(tlt != 6'h0) begin
                                    `uvm_error(get_type_name(), $sformatf("RETURN_TL_CREDITS cmd in an unsupported template, template %h", tlt));
                                end
                                else begin
                                    `uvm_info(get_type_name(), $sformatf("RETURN_TL_CREDITS cmd in TEMPLATE 0."), UVM_MEDIUM);
                                end
                            end
                            else begin
                                if(~cfg_obj.tl_receive_template[tlt]) begin
                                    `uvm_fatal(get_type_name(), $sformatf("Unsupported template, template %h", tlt));
                                end
                            end
                        end
                        else begin
                            if(~cfg_obj.tl_receive_template[tlt]) begin
                                `uvm_fatal(get_type_name(), $sformatf("Unsupported template, template %h", tlt));
                            end
                        end

                        issue_data_flit(rx_mon_data.bad_data_flit);
                        cov_template = tlt;
                        parse_tlc(tlc, tlt);

                        cov_run_length = rx_mon_data.drl;
                        cov_bad_data_flit = rx_mon_data.bad_data_flit;
                        if(coverage_on)
                            c_rx_tl_content.sample();
                    end
                    else begin
                        discard_data_flit();
                    end

                    rx_mon_data.data_flit_count = 0;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
                else begin
                    rx_mon_data.prefetch_data_flit_q.push_back(temp_flit);
                    rx_mon_data.data_flit_count++;
                end
            end
        end
    endtask : parse_flit

    function void issue_data_flit(bit [7:0] bad_data_flit);
        bit [511:0] temp_flit;
        bit [2:0]   data_err_type;
        bit [6:0]   temp_mdf;
        bit         data_flit_err;
        int         temp_data_carrier_type;
        int         data_flit_count = 0;

        while(rx_mon_data.prefetch_data_flit_q.size > 0) begin

            temp_flit = rx_mon_data.prefetch_data_flit_q.pop_front;
            temp_mdf = rx_mon_data.mdf_q.pop_front;
            temp_data_carrier_type = 64;
            data_flit_err = bad_data_flit[data_flit_count];
            if(data_flit_err) begin
                `uvm_info("tl_rx_monitor", $sformatf("bad data flit is dectected"), UVM_MEDIUM);
            end
            data_flit_count++;

            for(int i = 0; i < 8; i++) begin
                rx_mon_data.data_carrier_q.push_back(temp_flit[(64*i+63) -:64]);
                    
                data_err_type = {rx_mon_data.ecc_err_q.pop_front, data_flit_err};
                rx_mon_data.xmeta_q.push_back({65'b0, temp_mdf});
                rx_mon_data.data_err_q.push_back(data_err_type);
                rx_mon_data.data_carrier_type_q.push_back(temp_data_carrier_type);
                rx_mon_data.data_template_q.push_back(6'hf);
            end
        end

        if(rx_mon_data.prefetch_data_flit_q.size == 0) begin
            `uvm_info("tl_rx_monitor", $sformatf("Prefetch Data Flit Queue is EMPTY."), UVM_HIGH);
        end
    endfunction

    function void discard_data_flit();
        bit [511:0] temp_flit;
        
        while(rx_mon_data.prefetch_data_flit_q.size > 0) begin
            temp_flit = rx_mon_data.prefetch_data_flit_q.pop_front;
        end
        rx_mon_data.data_flit_count = 0;

        if(rx_mon_data.prefetch_data_flit_q.size == 0) begin
            `uvm_info("tl_rx_monitor", $sformatf("Prefetch Data Flit Queue is EMPTY."), UVM_HIGH);
        end
    endfunction

   // function for tl_credit check
    function void return_tl_credit_check(bit [55:0] packet);
        if(packet[7:0] == 8'b0000_1000) begin
            rx_mon_data.return_tl_credit_count++;
            
            if(packet[11:8] <= rx_mon_data.tl_vc0) begin
                rx_mon_data.tl_vc0 = rx_mon_data.tl_vc0 - packet[11:8];
            end
            else begin
                `uvm_error(get_type_name(), "RETURN_TL_CREDITS tl_vc0 overflow");
            end

            if(packet[15:12] <= rx_mon_data.tl_vc1) begin
                rx_mon_data.tl_vc1 = rx_mon_data.tl_vc1 - packet[15:12];
            end
            else begin
                `uvm_error(get_type_name(), "RETURN_TL_CREDITS tl_vc1 overflow");
            end

            if(packet[37:32] <= rx_mon_data.tl_dcp0) begin
                rx_mon_data.tl_dcp0 = rx_mon_data.tl_dcp0 - packet[37:32];
            end
            else begin
                `uvm_error(get_type_name(), "RETURN_TL_CREDITS tl_dcp0 overflow");
            end

            if(packet[43:38] <= rx_mon_data.tl_dcp1) begin
                rx_mon_data.tl_dcp1 = rx_mon_data.tl_dcp1 - packet[43:38];
            end
            else begin
                `uvm_error(get_type_name(), "RETURN_TL_CREDITS tl_dcp1 overflow");
            end

        end

        if(rx_mon_data.return_tl_credit_count == 1) begin
            if((rx_mon_data.tl_vc0 == 0) && (rx_mon_data.tl_vc1 == 0) && (rx_mon_data.tl_dcp0 == 0) && (rx_mon_data.tl_dcp1 == 0)) begin
                rx_mon_data.return_tl_credit = 0;
            end
            else begin
                rx_mon_data.return_tl_credit = 1;
            end
        end
        else if(rx_mon_data.return_tl_credit_count == 2) begin
            rx_mon_data.return_tl_credit = 0;
        end

    endfunction


    function void parse_tlc(bit [447:0] tl_content, bit [5:0] tl_template);
        case(tl_template)
            6'h0:
            begin
                //slot0-slot1   : return_tlx_credits
                //slot4-slot9   : 6-slot TL packet
                rx_mon_data.packet_q.push_back(tl_content[55:0]);
                // only check first two RETURN_TL_CREDIT cmds
                if(rx_mon_data.return_tl_credit && (rx_mon_data.return_tl_credit_count < 2)) begin
                    return_tl_credit_check(tl_content[55:0]);
                end

                rx_mon_data.packet_q.push_back(tl_content[279:112]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'h1:
            begin
                //slot0-lot3    : 4-slot TL packet
                //slot4-slot7   : 4-slot TL packet
                //slot8-slot11  : 4-slot TL packet
                //slot12-slot15 : 4-slot TL packet
                rx_mon_data.packet_q.push_back(tl_content[111:0]);
                rx_mon_data.packet_q.push_back(tl_content[223:112]);
                rx_mon_data.packet_q.push_back(tl_content[335:224]);
                rx_mon_data.packet_q.push_back(tl_content[447:336]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'h2:
            begin
                // TODO: For 3.0 ONLY!
                //
                //slot0 -slot1   : 2-slot TL packet
                //slot2 -slot3   : 2-slot TL packet
                //slot4 -slot5   : 2-slot TL packet
                //slot6 -slot7   : 2-slot TL packet
                //slot8 -slot9   : 2-slot TL packet
                //slot10 -slot11 : 2-slot TL packet
                //slot12 -slot13 : 2-slot TL packet
                //slot14 -slot15 : 2-slot TL packet
                for (int i = 0; i < 8; i++) begin
                    rx_mon_data.packet_q.push_back(tl_content[((i+1)*56-1) -: 56]);
                    rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                end
                template_info_print(tl_template, tl_content);
                //for(int i=0; i<7; i++) begin
                //    bit [1:0]   temp_ecc_err;
                //    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                //end
            end

            6'h3:
            begin
                // TODO: For 3.0 ONLY!
                //
                //slot0 -slot3   : 4-slot TL packet
                //slot4 -slot9   : 6-slot TL packet
                //slot10 -slot15 : 6-slot TL packet
                rx_mon_data.packet_q.push_back(tl_content[111 : 0]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                for (int i = 0; i < 2; i++) begin
                    rx_mon_data.packet_q.push_back(tl_content[((i+1)*168 + 112 - 1) -: 168]);
                    rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                end

                template_info_print(tl_template, tl_content);
                //for(int i=0; i<7; i++) begin
                //    bit [1:0]   temp_ecc_err;
                //    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                //end
            end

            6'h5:
            begin
                //slot0-slot1   : 2-slot TL packet
                //slot2         : mdf(3) || mdf(2) || mdf(1) || mdf(0)
                //slot3         : mdf(7) || mdf(6) || mdf(5) || mdf(4)
                //slot4-slot11  : 1-slot TL packet * 8
                //slot12-slot15 : 4-slot TL packet
                rx_mon_data.packet_q.push_back(tl_content[55:0]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                for(int i=0; i<rx_mon_data.drl; i++) begin
                    rx_mon_data.mdf_q.push_back(tl_content[62+7*i -:7]);
                end

                for(int i=0; i<8; i++) begin
                    rx_mon_data.packet_q.push_back(tl_content[139+28*i -:28]);
                    rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                end
                rx_mon_data.packet_q.push_back(tl_content[447:336]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);

                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'h9:
            begin
                //slot0-slot8   : Data(251:0)
                //slot9         : mdf(1) || mdf(0) || R(0) || V(1:0) || meta(6:0) || Data(255:252)  32byte data carrier
                //slot10-slot11 : 2-slot TL packet
                //slot12-slot15 : 1-slot TL packet * 4
                cov_slot_data_valid = tl_content[264:263];
                if(tl_content[264]) begin   // data_carrier valid
                    for(int i=0; i<4; i++) begin
                        bit [2:0]  data_err_type;
                        bit [71:0] temp_xmeta;
                        int        data_carrier_type;
                        
                        data_err_type = {rx_mon_data.ecc_err_q.pop_front, tl_content[263]};
                        temp_xmeta = {65'b0, tl_content[262:256]};
                        data_carrier_type = 32;
                        
                        rx_mon_data.data_carrier_q.push_back(tl_content[63+64*i -:64]);
                        rx_mon_data.data_err_q.push_back(data_err_type);
                        rx_mon_data.xmeta_q.push_back(temp_xmeta);
                        rx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                        rx_mon_data.data_template_q.push_back(6'h9);
                    end
                end

                for(int i=0; i<rx_mon_data.drl; i++) begin
                    rx_mon_data.mdf_q.push_back(tl_content[272+7*i -:7]);
                end
                
                rx_mon_data.packet_q.push_back(tl_content[335:280]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                for(int i=0; i<4; i++) begin
                    rx_mon_data.packet_q.push_back(tl_content[363+28*i -:28]);
                    rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                end
                template_info_print(tl_template, tl_content);

                for(int i=0; i<3; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'hb:
            begin
                //slot0-slot8   : Data(251:0)
                //slot9         : xmeta(23:0) || Data(255:252) 32byte data carrier
                //slot10        : xmeta(51:24)
                //slot11        : R(5:0) || V(1:0) || xmeta(71:52)
                //slot12-slot15 : 2-slot TL packet
                //slot14-slot15 : 1-slot TL packet * 2
                if(tl_content[329]) begin   // data_carrier valid
                    for(int i=0; i<4; i++) begin
                        bit [2:0] data_err_type;
                        int       data_carrier_type;

                        data_err_type = {rx_mon_data.ecc_err_q.pop_front, tl_content[328]};
                        data_carrier_type = 32;

                        rx_mon_data.data_carrier_q.push_back(tl_content[63+64*i -:64]);
                        rx_mon_data.data_err_q.push_back(data_err_type);
                        rx_mon_data.xmeta_q.push_back(tl_content[327:256]);
                        rx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                        rx_mon_data.data_template_q.push_back(6'hb);
                    end
                end

                rx_mon_data.packet_q.push_back(tl_content[391:336]);
                rx_mon_data.packet_q.push_back(tl_content[419:392]);
                rx_mon_data.packet_q.push_back(tl_content[447:420]);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                rx_mon_data.cmd_time_q.push_back(rx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);

                for(int i=0; i<3; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = rx_mon_data.ecc_err_q.pop_front;
                end
            end

            default:
            begin
                 `uvm_fatal(get_type_name(), "UE:Unsupportted Template Type based on OCAPI profile.");
            end
        endcase
    endfunction

    task assemble_trans();
        forever begin
            @(posedge tl_dl_vif.clock);
            while(rx_mon_data.wait_packet_q.size != 0) begin
                bit [167:0] temp_packet;
                int break_flag;
                
                temp_packet   = rx_mon_data.wait_packet_q.pop_front;
                break_flag    = write_trans(temp_packet, 1'b1, 0);
                if(break_flag) break;
            end

            while(rx_mon_data.packet_q.size != 0) begin
                bit [167:0] temp_packet;
                int         is_data_cmd;
                real        temp_time;
                
                temp_packet   = rx_mon_data.packet_q.pop_front;
                temp_time     = rx_mon_data.cmd_time_q.pop_front;
                is_data_cmd   = identify_data_cmd(temp_packet[7:0]);

                if(is_data_cmd) begin
                    rx_mon_data.wait_packet_q.push_back(temp_packet);
                end
                else begin
                    void'(write_trans(temp_packet, 1'b0, temp_time));
                end
            end
        end
    endtask : assemble_trans

    function int identify_data_cmd( bit [7:0] packet_type);
        case(packet_type)
            tl_rx_trans::MEM_RD_RESPONSE_OW: return 1;
            tl_rx_trans::MEM_RD_RESPONSE_XW: return 1;
            tl_rx_trans::MEM_RD_RESPONSE   : return 1;
            tl_rx_trans::INTRP_REQ_D       : return 1;
            default:                         return 0;
        endcase
    endfunction: identify_data_cmd


    function int write_trans( bit [167:0] packet, bit is_wait_q, real trans_time );
        tl_rx_trans_1 = tl_rx_trans::type_id::create("tl_rx_trans_1", this);
        case(packet[7:0])
            8'b00000000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::NOP_R;
                tl_rx_trans_1.is_cmd      = 0;
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=NOP_R"), UVM_MEDIUM);
            end

            8'b00000001:
            begin
                real        tmp_time;
                if (rx_mon_data.data_carrier_q.size < (8*packet[27:26])) begin
                    if(is_wait_q) begin
                        rx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    rx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end
                else begin
                    tl_rx_trans_1.packet_type = tl_rx_trans::MEM_RD_RESPONSE;
                    tl_rx_trans_1.is_cmd      = 0;
                    tl_rx_trans_1.CAPPTag     = packet[23:8];
                    tl_rx_trans_1.dP          = packet[25:24];
                    tl_rx_trans_1.dL          = packet[27:26];
                    `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_RESPONSE\tCappTag=%h\tdlength=%h", packet[23:8], packet[27:26]), UVM_MEDIUM);

                    for(int i=0; i<8*packet[27:26]; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        int        temp_data_carrier_type;
                        bit [5:0]  temp_template;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                        temp_template          = rx_mon_data.data_template_q.pop_front;

                        tl_rx_trans_1.data_carrier[i]   = temp_data;
                        tl_rx_trans_1.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                        tl_rx_trans_1.data_template     = temp_template;
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tMEM_RD_RESPONSE data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end
                end
                tmp_time                 = $realtime;
                tl_rx_trans_1.time_stamp = tmp_time;
            end

            8'b00000010:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_RD_FAIL;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];
                tl_rx_trans_1.dP          = packet[25:24];
                tl_rx_trans_1.dL          = packet[27:26];
                tl_rx_trans_1.resp_code   = packet[55:52];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_FAIL\tCappTag=%h\tdlength=%h\tresp_code=%h", packet[23:8], packet[27:26], packet[55:52]), UVM_MEDIUM);
            end

            8'b00000011:
            begin
                int  temp_data_carrier_type;
                real tmp_time;

                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_RD_RESPONSE_OW;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];
                tl_rx_trans_1.dP          = packet[26:24];
                tl_rx_trans_1.R           = packet[27];

                if(rx_mon_data.data_carrier_type_q.size < 1) begin
                    if(is_wait_q) begin
                        rx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    rx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end

                temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;

                if(temp_data_carrier_type == 32) begin
                    if(rx_mon_data.data_carrier_q.size < 4) begin
                        if(is_wait_q) begin 
                            rx_mon_data.wait_packet_q.push_front(packet);
                            rx_mon_data.data_carrier_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        rx_mon_data.wait_packet_q.push_back(packet);
                        return 0;
                    end

                   `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_RESPONSE_OW\tCappTag=%h\tdP=%h", packet[23:8], packet[26:24]), UVM_MEDIUM);
                    for(int i=0; i<4; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                        temp_template          = rx_mon_data.data_template_q.pop_front;

                        tl_rx_trans_1.data_carrier[i]   = temp_data;
                        tl_rx_trans_1.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tl_rx_trans_1.data_carrier_type = 32;
                        tl_rx_trans_1.data_template     = temp_template;
                       `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tMEM_RD_RESPONSE_OW data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end

                    for(int i = 0; i < 3; i++) begin
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else if(temp_data_carrier_type == 64) begin
                    if(rx_mon_data.data_carrier_q.size < 8) begin
                        if(is_wait_q) begin 
                            rx_mon_data.wait_packet_q.push_front(packet);
                            rx_mon_data.data_carrier_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        rx_mon_data.wait_packet_q.push_back(packet); 
                        return 0;
                    end
                   `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_RESPONSE_OW\tCappTag=%h\tdP=%h", packet[23:8], packet[26:24]), UVM_MEDIUM);

                    for(int i=0; i<8; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                        temp_template          = rx_mon_data.data_template_q.pop_front;

                        tl_rx_trans_1.data_carrier[i]   = temp_data;
                        tl_rx_trans_1.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tl_rx_trans_1.data_carrier_type = 64;
                        tl_rx_trans_1.data_template     = temp_template;
                       `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tMEM_RD_RESPONSE_OW data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end

                    for(int i = 0; i < 7; i++) begin
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else begin
                    `uvm_fatal("tl_rx_monitor", "UE: Unsupported Data Carrier Length Type Value.");
                end
                tmp_time                 = $realtime;
                tl_rx_trans_1.time_stamp = tmp_time;
            end

            8'b00000100:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_WR_RESPONSE;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];
                tl_rx_trans_1.dP          = packet[25:24];
                tl_rx_trans_1.dL          = packet[27:26];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_WR_RESPONSE\tCappTag=%h\tdlenght=%h", packet[23:8], packet[27:26]), UVM_MEDIUM);
            end

            8'b00000101:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_WR_FAIL;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];
                tl_rx_trans_1.dP          = packet[25:24];
                tl_rx_trans_1.dL          = packet[27:26];
                tl_rx_trans_1.resp_code   = packet[55:52];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_WR_FAIL\tCappTag=%h\tdlenght=%h\tresp_code=%h", packet[23:8], packet[27:26], packet[55:52]), UVM_MEDIUM);
            end

            8'b00000111:
            begin
                int  temp_data_carrier_type;
                real tmp_time;

                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_RD_RESPONSE_XW;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];


                if(rx_mon_data.data_carrier_type_q.size < 1) begin
                    if(is_wait_q) begin
                        rx_mon_data.wait_packet_q.push_front(packet); 
                        return 1;
                    end
                    rx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end
                temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;

                if(temp_data_carrier_type == 32) begin
                    if(rx_mon_data.data_carrier_q.size < 4) begin
                        if(is_wait_q) begin
                            rx_mon_data.wait_packet_q.push_front(packet); 
                            rx_mon_data.data_carrier_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        rx_mon_data.wait_packet_q.push_back(packet); 
                        return 0;
                    end

                    `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_RESPONSE_XW\tCappTag=%h", packet[23:8]), UVM_MEDIUM);
                    for(int i=0; i<4; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;

                        tl_rx_trans_1.data_carrier[i]   = temp_data;
                        tl_rx_trans_1.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tl_rx_trans_1.data_carrier_type = 32;
                       `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tMEM_RD_RESPONSE_XW data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta), UVM_MEDIUM);
                    end

                    for(int i = 0; i < 3; i++) begin
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else if(temp_data_carrier_type == 64) begin
                    if(rx_mon_data.data_carrier_q.size < 8) begin
                        if(is_wait_q) begin 
                            rx_mon_data.wait_packet_q.push_front(packet);
                            rx_mon_data.data_carrier_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        rx_mon_data.wait_packet_q.push_back(packet); 
                        return 0;
                    end

                    `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_RD_RESPONSE_XW\tCappTag=%h", packet[23:8]), UVM_MEDIUM);
                    for(int i=0; i<8; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                        temp_template          = rx_mon_data.data_template_q.pop_front;

                        tl_rx_trans_1.data_carrier[i]   = temp_data;
                        tl_rx_trans_1.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tl_rx_trans_1.data_carrier_type = 64;
                        tl_rx_trans_1.data_template     = temp_template;
                       `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tMEM_RD_RESPONSE_XW data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end

                    for(int i = 0; i < 7; i++) begin
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else begin
                    `uvm_fatal("tl_rx_monitor", "UE: Unsupported Data Carrier Length Type Value.");
                end
                tmp_time                 = $realtime;
                tl_rx_trans_1.time_stamp = tmp_time;
            end

            8'b00001000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::RETURN_TL_CREDITS;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.TL_vc0      = packet[11:8];
                tl_rx_trans_1.TL_vc1      = packet[15:12];
                tl_rx_trans_1.TL_dcp0     = packet[37:32];
                tl_rx_trans_1.TL_dcp1     = packet[43:38];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=RETURN_TL_CREDITS\ttl_vc_0=%h\ttl_vc_1=%h\ttl_dcp_0=%h\ttl_dcp_1=%h", packet[11:8], packet[15:12], packet[37:32], packet[43:38]), UVM_MEDIUM);
            end

            8'b00001011:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::MEM_CNTL_DONE;
                tl_rx_trans_1.is_cmd      = 0;
                tl_rx_trans_1.CAPPTag     = packet[23:8];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=MEM_CNTL_DONE\tCappTag=%h", packet[23:8]), UVM_MEDIUM);
            end

            8'b00010000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::RD_WNITC;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.AFUTag      = packet[107:92];
                tl_rx_trans_1.dL          = packet[111:110];
                tl_rx_trans_1.Eaddr       = {packet[91:34], 6'b000000};
               `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=RD_WNITC\tacTag=%h\tafuTag=%h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end
			
			8'b00010010:	//added at 2019.07.31
			begin
				tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::PR_RD_WNITC;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.AFUTag      = packet[107:92];
                tl_rx_trans_1.pL          = packet[111:109];
                tl_rx_trans_1.Eaddr       = packet[91:28];
			   `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=PR_RD_WNITC\tacTag=%h\tafuTag=%h", packet[23:12], packet[107:92]), UVM_MEDIUM);
			end
			
            8'b00100000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::DMA_W;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.AFUTag      = packet[107:92];
                tl_rx_trans_1.dL          = packet[111:110];
                tl_rx_trans_1.Eaddr       = {packet[91:34], 6'b000000};
               `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=DMA_W\tacTag=%h\tafuTag=%h", packet[23:12], packet[107:92]), UVM_MEDIUM);

                case(packet[111:110])
                    2'b01:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b10:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 16) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 16; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b11:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 32) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_W \tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 32; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b00:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 4) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 4; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;

                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
                endcase
            end
			
			8'b00101000:	//added at 2019.08.1
			begin
				tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::DMA_W_BE;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.AFUTag      = packet[107:92];
				tl_rx_trans_1.Eaddr       = {packet[91:28], 6'b000000};
				tl_rx_trans_1.byte_enable = {packet[167:108], packet[31:28]};
			   `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=DMA_W_BE\tacTag=%h\tafuTag=%h", packet[23:12], packet[107:92]), UVM_MEDIUM);
			end
			
			8'b00110000:	//added at 2019.07.31
			begin
				tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::DMA_PR_W;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.AFUTag      = packet[107:92];
				tl_rx_trans_1.pL          = packet[111:109];
				tl_rx_trans_1.Eaddr       = packet[91:28];
			   `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=DMA_PR_W\tacTag=%h\tafuTag=%h", packet[23:12], packet[107:92]), UVM_MEDIUM);
			
				case(packet[111:109])
					3'b000:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					3'b001:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					3'b010:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					3'b011:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					3'b100:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					3'b101:
                    begin
                        if(rx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                rx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            rx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tcmd=DMA_PR_W\tAFUTag=%h \tEA=%h \tdL=%h", packet[107:92], packet[91:28], packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = rx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                            temp_err               = rx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = rx_mon_data.data_template_q.pop_front;

                            tl_rx_trans_1.data_carrier[i]   = temp_data;
                            tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            tl_rx_trans_1.data_error[i]     = temp_err;
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tDMA_PR_W data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
					
					
				endcase	
			end

            8'b01010000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::ASSIGN_ACTAG;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.acTag       = packet[19:8];
                tl_rx_trans_1.BDF         = packet[35:20];
                tl_rx_trans_1.PASID       = packet[55:36];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=ASSIGN_ACTAG\tacTag=%h\tBDF=%h\tPASId=%h", packet[19:8], packet[35:20], packet[55:36]), UVM_MEDIUM);
            end

            8'b01011000:
            begin
                tl_rx_trans_1.time_stamp  = trans_time;
                tl_rx_trans_1.packet_type = tl_rx_trans::INTRP_REQ;
                tl_rx_trans_1.is_cmd      = 1;
                tl_rx_trans_1.cmd_flag    = packet[11:8];
                tl_rx_trans_1.acTag       = packet[23:12];
                tl_rx_trans_1.stream_id   = packet[27:24];
                tl_rx_trans_1.obj_handle  = packet[91:28];
                tl_rx_trans_1.AFUTag      = packet[107:92];
                `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=INTRP_REQ\tacTag=%h\tstream_id=%h\tAFUTag=%h", packet[23:12], packet[27:24], packet[107:92]), UVM_MEDIUM);
            end

            8'b01011010:
            begin  
                real        tmp_time;

                if (rx_mon_data.data_carrier_q.size < 8) begin
                    if(is_wait_q) begin 
                        rx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    rx_mon_data.wait_packet_q.push_back(packet); 
                    return 0;
                end
                else begin
                    int valid_byte = 1;
                    tl_rx_trans_1.packet_type = tl_rx_trans::INTRP_REQ_D;
                    tl_rx_trans_1.is_cmd      = 1;
                    tl_rx_trans_1.cmd_flag    = packet[11:8];
                    tl_rx_trans_1.acTag       = packet[23:12];
                    tl_rx_trans_1.stream_id   = packet[27:24];
                    tl_rx_trans_1.obj_handle  = packet[91:28];
                    tl_rx_trans_1.AFUTag      = packet[107:92];
                    tl_rx_trans_1.R           = packet[108];
                    tl_rx_trans_1.pL          = packet[111:109];
  
                    `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\t cmd=INTRP_REQ_D\tacTag=%h\tstream_id=%h\tAFUTag=%h\tplength=%h", packet[23:12], packet[27:24], packet[107:92], packet[111:109]), UVM_MEDIUM);
                    for(int i=1; i<packet[111:109]; i++) begin
                        valid_byte *= 2;
                    end

                    for(int i=0; i<8; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        int        temp_data_carrier_type;
                        bit [5:0]  temp_template;
                        int j=0;

                        temp_data              = rx_mon_data.data_carrier_q.pop_front;
                        temp_err               = rx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = rx_mon_data.xmeta_q.pop_front;
                        temp_data_carrier_type = rx_mon_data.data_carrier_type_q.pop_front;
                        temp_template          = rx_mon_data.data_template_q.pop_front;

                        if(valid_byte > 8*i) begin
                            tl_rx_trans_1.data_carrier[j]   = temp_data;
                            tl_rx_trans_1.data_error[j]     = temp_err;
    
                            if(temp_template == 6'hb) begin
                                tl_rx_trans_1.xmeta[i]          = temp_xmeta;
                            end
                            else begin
                                tl_rx_trans_1.meta[i]           = temp_xmeta[6:0];
                            end
                                    
                            tl_rx_trans_1.data_carrier_type = temp_data_carrier_type;
                            tl_rx_trans_1.data_template     = temp_template;
                            j++;
                           `uvm_info("tl_rx_monitor", $sformatf("RX Trans Info:\tINTRP_REQ_D data \tacTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:12], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                        end
                    end
                end  
                tmp_time                 = $realtime;
                tl_rx_trans_1.time_stamp = tmp_time;
            end
            
            // TODO: add 3.0 commands, dma_wr and rd_wnitc

            default:
            begin
                `uvm_fatal(get_type_name(), "Unsupported packet");
            end
        endcase
        //$timeformat(-9,3,"ns",15);
        //tl_rx_trans_1.time_stamp = $realtime;
        if(coverage_on)
            c_ocapi_tl_rx_packet.sample();
        `uvm_info("tl_rx_monitor\n", $sformatf("%s", tl_rx_trans_1.sprint()), UVM_MEDIUM);
        tl_rx_ap.write(tl_rx_trans_1);
        return 0;
    endfunction : write_trans

    function void template_info_print(bit [5:0] tl_template, bit [447:0] tl_content);

        case (tl_template)
            6'h0:
            begin
                bit [55:0]  packet_0;
                bit [167:0] packet_1;

                packet_0 = tl_content[55:0];
                packet_1 = tl_content[279:112];

                `uvm_info("tl_rx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 2 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
            end

            6'h1:
            begin
                bit [111:0] packet_0;
                bit [111:0] packet_1;
                bit [111:0] packet_2;
                bit [111:0] packet_3;

                packet_0 = tl_content[111:0];
                packet_1 = tl_content[223:112];
                packet_2 = tl_content[335:224];
                packet_3 = tl_content[447:336];

                `uvm_info("tl_rx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 4 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
                packet_info_print(packet_3);
            end

            6'h2:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 4 command packets:", tl_template), UVM_MEDIUM);

                for (int i = 0; i < 8; i++) begin
                    bit [55:0] packet;
                    packet = tl_content[(i+1)*2 - 1 -: 56];

                    packet_info_print(packet);
                end
            end

            6'h3:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 4 command packets:", tl_template), UVM_MEDIUM);

                for (int i = 0; i < 1; i++) begin
                    bit [112 : 0] packet = tl_content[111 : 0];
                    packet_info_print(packet);
                end

                for (int i = 0; i < 2; i++) begin
                    bit [168 : 0] packet = tl_content[((i+1)*168 + 112 - 1) -: 168];
                    packet_info_print(packet);
                end

            end

            6'h5:
            begin
                bit [55:0]  packet_0;
                bit [27:0]  packet_1;
                bit [27:0]  packet_2;
                bit [27:0]  packet_3;
                bit [27:0]  packet_4;
                bit [27:0]  packet_5;
                bit [27:0]  packet_6;
                bit [27:0]  packet_7;
                bit [27:0]  packet_8;
                bit [111:0] packet_9;

                packet_0 = tl_content[55:0];
                packet_1 = tl_content[139:112];
                packet_2 = tl_content[167:140];
                packet_3 = tl_content[195:168];
                packet_4 = tl_content[223:196];
                packet_5 = tl_content[251:224];
                packet_6 = tl_content[279:252];
                packet_7 = tl_content[307:280];
                packet_8 = tl_content[335:308];
                packet_9 = tl_content[447:336];

                `uvm_info("tl_rx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 10 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
                packet_info_print(packet_3);
                packet_info_print(packet_4);
                packet_info_print(packet_5);
                packet_info_print(packet_6);
                packet_info_print(packet_7);
                packet_info_print(packet_8);
                packet_info_print(packet_9);
            end

            6'h9:
            begin
                bit [55:0]  packet_0;
                bit [27:0]  packet_1;
                bit [27:0]  packet_2;
                bit [27:0]  packet_3;
                bit [27:0]  packet_4;

                packet_0 = tl_content[335:280];
                packet_1 = tl_content[363:336];
                packet_2 = tl_content[391:364];
                packet_3 = tl_content[419:392];
                packet_4 = tl_content[447:420];

                `uvm_info("tl_rx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 5 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
                packet_info_print(packet_3);
                packet_info_print(packet_4);
            end

            6'hb:
            begin
                bit [55:0]  packet_0;
                bit [27:0]  packet_1;
                bit [27:0]  packet_2;

                packet_0 = tl_content[391:336];
                packet_1 = tl_content[419:392];
                packet_2 = tl_content[447:420];

                `uvm_info("tl_rx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 3 command packet:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
            end
        endcase
    endfunction

    function void packet_info_print( bit [167:0] packet );
        cov_second_packet = cov_first_packet;

        case(packet[7:0])
            tl_rx_trans::NOP_R:
            begin
                cov_first_packet = tl_rx_trans::NOP_R;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : NOP_R"), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_RD_RESPONSE:
            begin
                cov_first_packet = tl_rx_trans::MEM_RD_RESPONSE;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_RD_RESPONSE\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_RD_FAIL:
            begin
                cov_first_packet = tl_rx_trans::MEM_RD_FAIL;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_RD_FAIL\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_RD_RESPONSE_OW:
            begin
                cov_first_packet = tl_rx_trans::MEM_RD_RESPONSE_OW;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_RD_RESPONSE_OW\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_WR_RESPONSE:
            begin
                cov_first_packet = tl_rx_trans::MEM_WR_RESPONSE;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_WR_RESPONSE\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_WR_FAIL:
            begin
                cov_first_packet = tl_rx_trans::MEM_WR_FAIL;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_WR_FAIL\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_RD_RESPONSE_XW:
            begin
                cov_first_packet = tl_rx_trans::MEM_RD_RESPONSE_XW;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_RD_RESPONSE_XW\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::MEM_CNTL_DONE:
            begin
                cov_first_packet = tl_rx_trans::MEM_CNTL_DONE;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : MEM_CNTL_DONE\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_rx_trans::ASSIGN_ACTAG:
            begin
                cov_first_packet = tl_rx_trans::ASSIGN_ACTAG;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : ASSIGN_ACTAG\tacTag : %h", packet[19:8]), UVM_MEDIUM);
            end

            tl_rx_trans::INTRP_REQ:
            begin
                cov_first_packet = tl_rx_trans::INTRP_REQ;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : INTRP_REQ\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::INTRP_REQ_D:
            begin
                cov_first_packet = tl_rx_trans::INTRP_REQ_D;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : INTRP_REQ_D\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::RETURN_TL_CREDITS:
            begin
                cov_first_packet = tl_rx_trans::RETURN_TL_CREDITS;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : RETURN_TL_CREDITS"), UVM_MEDIUM);
            end

            tl_rx_trans::RD_WNITC:
            begin
                cov_first_packet = tl_rx_trans::RD_WNITC;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : RD_WNITC\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::PR_RD_WNITC:
            begin
                cov_first_packet = tl_rx_trans::PR_RD_WNITC;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : PR_RD_WNITC\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::DMA_W:
            begin
                cov_first_packet = tl_rx_trans::DMA_W;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : DMA_W\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::DMA_PR_W:
            begin
                cov_first_packet = tl_rx_trans::DMA_PR_W;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : DMA_PR_W\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

            tl_rx_trans::DMA_W_BE:
            begin
                cov_first_packet = tl_rx_trans::DMA_W_BE;
                `uvm_info("tl_rx_monitor", $sformatf("Packet Command Type : DMA_W_BE\tacTag : %h \tAFUTag : %h", packet[23:12], packet[107:92]), UVM_MEDIUM);
            end

        endcase
        
        if(coverage_on)
            c_packets_and_template.sample();
    endfunction
    
endclass: tl_rx_monitor

`endif
