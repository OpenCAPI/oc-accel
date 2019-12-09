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
//------------------------------------------------------------------------------
//
// CLASS: tlx_afu_monitor
//
//------------------------------------------------------------------------------
`ifndef _TLX_AFU_MONITOR_SV_
`define _TLX_AFU_MONITOR_SV_

class tlx_afu_monitor extends uvm_monitor;

    // Interface & Port
    string                                                tID;
    virtual interface tlx_afu_interface                   tlx_afu_vif;
    virtual interface intrp_interface                     intrp_vif;
    uvm_analysis_port #(tlx_afu_transaction)              tlx_afu_tran_port;
    uvm_analysis_port #(afu_tlx_transaction)              afu_tlx_tran_port;
    uvm_analysis_port #(intrp_transaction)                intrp_tran_port;

    // Local signals
    afu_tlx_transaction      afu_tlx_cmd_trans;
    afu_tlx_transaction      afu_tlx_resp_trans;
    tlx_afu_transaction      tlx_afu_cmd_trans;
    tlx_afu_transaction      tlx_afu_resp_trans;
    intrp_transaction        intrp_trans;

    int                      afu_tlx_cmd_num;
    int                      afu_tlx_resp_num;
    int                      tlx_afu_cmd_num;
    int                      tlx_afu_resp_num;

    bit[512:0]               afu_tlx_cmd_data_q[$];
    bit[512:0]               afu_tlx_resp_data_q[$];
    bit[512:0]               tlx_afu_cmd_data_q[$];
    bit[512:0]               tlx_afu_resp_data_q[$];

    afu_tlx_transaction      afu_tlx_cmd_trans_q[$];
    afu_tlx_transaction      afu_tlx_resp_trans_q[$];
    tlx_afu_transaction      tlx_afu_cmd_trans_q[$];
    tlx_afu_transaction      tlx_afu_resp_trans_q[$];

    //------------------------FUNCTIONAL COVERAGE--------------------------------
    //
    afu_tlx_transaction      pre_afu_tlx_cmd_trans;
    tlx_afu_transaction      pre_tlx_afu_resp_trans;

    covergroup c_tlx_afu_resp_packet;
        option.per_instance = 1;
        packet_type: coverpoint tlx_afu_resp_trans_q[0].tlx_afu_type {
            bins read_response        = {tlx_afu_transaction::READ_RESPONSE};
            bins read_failed          = {tlx_afu_transaction::READ_FAILED};
            bins write_response       = {tlx_afu_transaction::WRITE_RESPONSE};
            bins write_failed         = {tlx_afu_transaction::WRITE_FAILED};
            bins xlate_done           = {tlx_afu_transaction::XLATE_DONE};
            bins intrp_resp           = {tlx_afu_transaction::INTRP_RESP};
            bins intrp_rdy            = {tlx_afu_transaction::INTRP_RDY};
        }
        pre_packet_type: coverpoint pre_tlx_afu_resp_trans.tlx_afu_type {
            option.weight=0;
            bins read_response        = {tlx_afu_transaction::READ_RESPONSE};
            bins read_failed          = {tlx_afu_transaction::READ_FAILED};
            bins write_response       = {tlx_afu_transaction::WRITE_RESPONSE};
            bins write_failed         = {tlx_afu_transaction::WRITE_FAILED};
            bins xlate_done           = {tlx_afu_transaction::XLATE_DONE};
            bins intrp_resp           = {tlx_afu_transaction::INTRP_RESP};
            bins intrp_rdy            = {tlx_afu_transaction::INTRP_RDY};
        }
        resp_code: coverpoint tlx_afu_resp_trans_q[0].tlx_afu_resp_code {
            option.weight=0;
            bins resp_code_0          ={4'h0};
            bins resp_code_2          ={4'h2};
            bins resp_code_4          ={4'h4};
        }
        data_length: coverpoint tlx_afu_resp_trans_q[0].tlx_afu_dl {
            option.weight=0;
            bins data_length_64       ={2'h1};
            bins data_length_128      ={2'h2};
        }
        data_part: coverpoint tlx_afu_resp_trans_q[0].tlx_afu_dp {
            option.weight=0;
            bins data_part_0          ={2'h0};
            bins data_part_1          ={2'h1};
        }
        tlx_afu_two_packet_type: cross packet_type, pre_packet_type;
        read_resp_packet: cross packet_type, data_length, data_part {
            bins rd_resp_dlength64_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0);
            bins rd_resp_dlength64_dpart1=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1);
            bins rd_resp_dlength128_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0);
        }
        write_resp_packet: cross packet_type, data_length, data_part {
            bins wr_resp_dlength64_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0);
            bins wr_resp_dlength64_dpart1=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1);
            bins wr_resp_dlength128_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0);
        }
        read_failed_packet: cross packet_type, resp_code, data_length, data_part {
            bins rd_failed_code2_dlength64_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_2);
            bins rd_failed_code2_dlength64_dpart1=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1) && binsof(resp_code.resp_code_2);
            bins rd_failed_code2_dlength128_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_2);
            bins rd_failed_code4_dlength64_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_4);
            bins rd_failed_code4_dlength64_dpart1=binsof(packet_type.read_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1) && binsof(resp_code.resp_code_4);
            bins rd_failed_code4_dlength128_dpart0=binsof(packet_type.read_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_4);
        }
        write_failed_packet: cross packet_type, resp_code, data_length, data_part {
            bins wr_failed_code2_dlength64_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_2);
            bins wr_failed_code2_dlength64_dpart1=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1) && binsof(resp_code.resp_code_2);
            bins wr_failed_code2_dlength128_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_2);
            bins wr_failed_code4_dlength64_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_4);
            bins wr_failed_code4_dlength64_dpart1=binsof(packet_type.write_response) && binsof(data_length.data_length_64) && binsof(data_part.data_part_1) && binsof(resp_code.resp_code_4);
            bins wr_failed_code4_dlength128_dpart0=binsof(packet_type.write_response) && binsof(data_length.data_length_128) && binsof(data_part.data_part_0) && binsof(resp_code.resp_code_4);
        }
        xlate_done_packet: cross packet_type, resp_code, data_length, data_part {
            bins xlate_done_code0=binsof(packet_type.xlate_done) && binsof(resp_code.resp_code_0);
            bins xlate_done_code2=binsof(packet_type.xlate_done) && binsof(resp_code.resp_code_2);
        }
        intrp_resp_packet: cross packet_type, resp_code {
            bins intrp_resp_code0=binsof(packet_type.intrp_resp) && binsof(resp_code.resp_code_0);
            bins intrp_resp_code2=binsof(packet_type.intrp_resp) && binsof(resp_code.resp_code_2);
            bins intrp_resp_code4=binsof(packet_type.intrp_resp) && binsof(resp_code.resp_code_4);
            bins intrp_rdy_code0=binsof(packet_type.intrp_rdy) && binsof(resp_code.resp_code_0);
            bins intrp_rdy_code2=binsof(packet_type.intrp_rdy) && binsof(resp_code.resp_code_2);        
        }
        intrp_rdy_packet: cross packet_type, resp_code {
            bins intrp_rdy_code0=binsof(packet_type.intrp_rdy) && binsof(resp_code.resp_code_0);
            bins intrp_rdy_code2=binsof(packet_type.intrp_rdy) && binsof(resp_code.resp_code_2);
        }
    endgroup : c_tlx_afu_resp_packet

    covergroup c_afu_tlx_cmd_packet;
        option.per_instance = 1;
        packet_type: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_type {
            bins assign_actag         = {afu_tlx_transaction::ASSIGN_ACTAG};
            bins dma_pr_w             = {afu_tlx_transaction::DMA_PR_W};
            bins dma_w                = {afu_tlx_transaction::DMA_W};
            //bins dma_w_be             = {afu_tlx_transaction::DMA_W_BE};
            bins pr_rd_wnitc          = {afu_tlx_transaction::PR_RD_WNITC};
            bins rd_wnitc             = {afu_tlx_transaction::RD_WNITC};
            bins intrp_req            = {afu_tlx_transaction::INTRP_REQ};
        }
        pre_packet_type: coverpoint pre_afu_tlx_cmd_trans.afu_tlx_type {
            option.weight=0;
            bins assign_actag         = {afu_tlx_transaction::ASSIGN_ACTAG};
            bins dma_pr_w             = {afu_tlx_transaction::DMA_PR_W};
            bins dma_w                = {afu_tlx_transaction::DMA_W};
            //bins dma_w_be             = {afu_tlx_transaction::DMA_W_BE};
            bins pr_rd_wnitc          = {afu_tlx_transaction::PR_RD_WNITC};
            bins rd_wnitc             = {afu_tlx_transaction::RD_WNITC};
            bins intrp_req            = {afu_tlx_transaction::INTRP_REQ};
        }
        data_length: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_dl {
            option.weight=0;
            bins data_length_64       ={2'h1};
            bins data_length_128      ={2'h2};
        }
        partial_length: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_pl {
            option.weight=0;
            bins partial_length_1     ={3'h0};
            bins partial_length_2     ={3'h1};
            bins partial_length_4     ={3'h2};
            bins partial_length_8     ={3'h3};
            bins partial_length_16    ={3'h4};
            bins partial_length_32    ={3'h5};
        }
        afu_tlx_two_packet_type: cross packet_type, pre_packet_type;
        rd_wnitc_packet: cross packet_type, data_length {
            bins rd_wnitc_dlength64=binsof(packet_type.rd_wnitc) && binsof(data_length.data_length_64);
            bins rd_wnitc_dlength128=binsof(packet_type.rd_wnitc) && binsof(data_length.data_length_128);
        }
        dma_w_packet: cross packet_type, data_length {
            bins dma_w_dlength64=binsof(packet_type.dma_w) && binsof(data_length.data_length_64);
            bins dma_w_dlength128=binsof(packet_type.dma_w) && binsof(data_length.data_length_128);
        }
        pr_rd_wnitc_packet: cross packet_type, partial_length {
            bins pr_rd_wnitc_plength1=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_1);
            bins pr_rd_wnitc_plength2=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_2);
            bins pr_rd_wnitc_plength4=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_4);
            bins pr_rd_wnitc_plength8=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_8);
            bins pr_rd_wnitc_plength16=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_16);
            bins pr_rd_wnitc_plength32=binsof(packet_type.pr_rd_wnitc) && binsof(partial_length.partial_length_32);
        }
        dma_pr_w_packet: cross packet_type, partial_length {
            bins dma_pr_w_plength1=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_1);
            bins dma_pr_w_plength2=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_2);
            bins dma_pr_w_plength4=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_4);
            bins dma_pr_w_plength8=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_8);
            bins dma_pr_w_plength16=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_16);
            bins dma_pr_w_plength32=binsof(packet_type.dma_pr_w) && binsof(partial_length.partial_length_32);
        }
        rd_addr_bit00: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[0]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit01: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[1]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit02: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[2]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit03: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[3]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit04: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[4]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit05: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[5]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit06: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[6]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit07: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[7]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit08: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[8]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit09: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[9]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit10: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[10]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit11: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[11]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit12: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[12]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit13: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[13]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit14: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[14]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit15: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[15]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit16: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[16]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit17: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[17]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit18: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[18]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit19: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[19]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit20: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[20]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit21: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[21]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit22: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[22]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit23: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[23]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit24: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[24]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit25: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[25]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit26: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[26]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit27: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[27]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit28: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[28]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit29: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[29]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit30: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[30]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit31: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[31]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit32: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[32]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit33: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[33]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit34: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[34]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit35: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[35]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit36: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[36]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit37: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[37]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit38: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[38]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit39: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[39]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit40: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[40]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit41: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[41]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit42: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[42]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit43: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[43]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit44: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[44]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit45: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[45]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit46: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[46]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit47: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[47]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit48: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[48]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit49: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[49]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit50: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[50]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit51: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[51]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit52: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[52]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit53: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[53]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit54: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[54]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit55: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[55]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit56: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[56]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit57: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[57]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit58: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[58]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit59: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[59]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit60: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[60]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit61: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[61]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit62: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[62]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);
        rd_addr_bit63: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[63]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::RD_WNITC || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::PR_RD_WNITC);

        wr_addr_bit00: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[0]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit01: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[1]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit02: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[2]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit03: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[3]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit04: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[4]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit05: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[5]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit06: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[6]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit07: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[7]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit08: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[8]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit09: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[9]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit10: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[10]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit11: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[11]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit12: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[12]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit13: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[13]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit14: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[14]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit15: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[15]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit16: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[16]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit17: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[17]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit18: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[18]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit19: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[19]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit20: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[20]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit21: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[21]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit22: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[22]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit23: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[23]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit24: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[24]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit25: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[25]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit26: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[26]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit27: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[27]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit28: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[28]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit29: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[29]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit30: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[30]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit31: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[31]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit32: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[32]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit33: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[33]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit34: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[34]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit35: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[35]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit36: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[36]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit37: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[37]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit38: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[38]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit39: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[39]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit40: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[40]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit41: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[41]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit42: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[42]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit43: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[43]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit44: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[44]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit45: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[45]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit46: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[46]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit47: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[47]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit48: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[48]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit49: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[49]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit50: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[50]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit51: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[51]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit52: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[52]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit53: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[53]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit54: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[54]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit55: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[55]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit56: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[56]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit57: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[57]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit58: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[58]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit59: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[59]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit60: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[60]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit61: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[61]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit62: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[62]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);
        wr_addr_bit63: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[63]
            iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W);

        obj_ea_bit00: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[0] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit01: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[1] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit02: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[2] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit03: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[3] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit04: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[4] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit05: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[5] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit06: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[6] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit07: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[7] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit08: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[8] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit09: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[9] iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit10: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[10]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit11: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[11]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit12: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[12]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit13: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[13]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit14: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[14]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit15: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[15]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit16: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[16]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit17: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[17]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit18: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[18]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit19: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[19]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit20: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[20]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit21: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[21]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit22: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[22]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit23: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[23]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit24: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[24]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit25: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[25]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit26: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[26]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit27: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[27]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit28: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[28]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit29: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[29]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit30: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[30]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit31: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[31]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit32: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[32]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit33: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[33]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit34: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[34]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit35: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[35]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit36: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[36]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit37: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[37]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit38: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[38]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit39: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[39]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit40: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[40]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit41: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[41]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit42: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[42]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit43: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[43]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit44: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[44]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit45: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[45]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit46: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[46]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit47: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[47]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit48: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[48]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit49: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[49]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit50: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[50]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit51: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[51]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit52: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[52]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit53: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[53]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit54: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[54]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit55: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[55]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit56: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[56]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit57: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[57]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit58: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[58]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit59: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[59]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit60: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[60]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit61: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[61]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit62: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[62]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
        obj_ea_bit63: coverpoint afu_tlx_cmd_trans_q[0].afu_tlx_addr[63]iff(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::INTRP_REQ);
    endgroup : c_afu_tlx_cmd_packet

    //------------------------CONFIGURATION PARAMETERS--------------------------------
    // TLX_AFU_MONITOR Configuration Parameters. These parameters can be controlled through
    // the UVM configuration database
    // @{

    // Trace player has three work modes for different usages:
    // CMOD_ONLY:   only cmod is working
    // RTL_ONLY:    only DUT rtl is working
    // CROSS_CHECK: default verfication mode, cross check between RTL and CMOD
    string                      work_mode = "CROSS_CHECK";
    //event                       action_tb_finish;

    // }@

    `uvm_component_utils_begin(tlx_afu_monitor)
        `uvm_field_string(work_mode, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "tlx_afu_monitor", uvm_component parent = null);

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
    //extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);

    // }@
    extern task collect_afu_tlx_cmd();
    extern task collect_afu_tlx_resp();
    extern task collect_tlx_afu_cmd();
    extern task collect_tlx_afu_resp();
    extern function afu_tlx_transaction::afu_tlx_enum get_afu_tlx_type(bit[7:0] afu_tlx_opcode);
    extern function tlx_afu_transaction::tlx_afu_enum get_tlx_afu_type(bit[7:0] tlx_afu_opcode);
    extern function void pack_afu_tlx_cmd();
    extern function void pack_tlx_afu_cmd();
    extern function void pack_afu_tlx_resp();
    extern function void pack_tlx_afu_resp();
    extern function int dl2dl_num(bit[1:0] dl);
    extern task collect_interrupt();

endclass : tlx_afu_monitor

// Function: new
// Creates a new dbb check monitor
function tlx_afu_monitor::new(string name = "tlx_afu_monitor", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    tlx_afu_tran_port = new("tlx_afu_tran_port", this);
    afu_tlx_tran_port = new("afu_tlx_tran_port", this);    
    intrp_tran_port = new("intrp_tran_port", this);
    afu_tlx_cmd_num = 0;
    afu_tlx_resp_num = 0;
    tlx_afu_cmd_num = 0;
    tlx_afu_resp_num = 0;
    c_tlx_afu_resp_packet = new();
    c_tlx_afu_resp_packet.set_inst_name({get_full_name(),".c_tlx_afu_resp_packet"});
    c_afu_tlx_cmd_packet = new();
    c_afu_tlx_cmd_packet.set_inst_name({get_full_name(),".c_afu_tlx_cmd_packet"});
    pre_afu_tlx_cmd_trans = new();
    pre_tlx_afu_resp_trans = new();
endfunction : new

// Function: build_phase
// XXX
function void tlx_afu_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)

    //if($value$plusargs("WORK_MODE=%0s", work_mode)) begin
    //    `uvm_info(tID, $sformatf("Setting WORK_MODE:%0s", work_mode), UVM_MEDIUM)
    //end
endfunction : build_phase

// Function: connect_phase
// XXX
function void tlx_afu_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)

    if(!uvm_config_db#(virtual tlx_afu_interface)::get(this, "", "tlx_afu_vif", tlx_afu_vif)) begin
        `uvm_fatal(tID, "No virtual interface specified fo tlx_afu_monitor")
    end
    if(!uvm_config_db#(virtual intrp_interface)::get(this, "", "intrp_vif", intrp_vif)) begin
        `uvm_fatal(tID, "No virtual interface of interrupt specified fo tlx_afu_monitor")
    end
endfunction : connect_phase

function void tlx_afu_monitor::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)

endfunction : start_of_simulation_phase
// Task: run_phase
// XXX
task tlx_afu_monitor::run_phase(uvm_phase phase);

    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)

endtask : run_phase

// Task: main_phase
// XXX
task tlx_afu_monitor::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    fork
        collect_afu_tlx_cmd();
        collect_afu_tlx_resp();
        collect_tlx_afu_cmd();
        collect_tlx_afu_resp();
        collect_interrupt();
    join
endtask : main_phase

// Task: shutdown_phase
// XXX
task tlx_afu_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase

// Collect afu tlx command and data
task tlx_afu_monitor::collect_interrupt();
    typedef enum bit[1:0] { INTRP_IDLE, INTRP_WAIT_ACK, INTRP_FINISH } intrp_status;
    intrp_status intrp_status_item;
    `uvm_info(tID, $sformatf("Collect_interrupt begin ..."), UVM_MEDIUM)
    intrp_status_item = INTRP_IDLE;
    forever begin
        @(posedge intrp_vif.action_clock);
        if(intrp_vif.action_rst_n == 0)begin
            break;
        end
    end
    forever begin
        intrp_trans = new("intrp_trans");
        @(posedge intrp_vif.action_clock)
        if(intrp_status_item == INTRP_IDLE)begin
            if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 0))begin
                intrp_status_item = INTRP_WAIT_ACK;
                intrp_trans.intrp_item=intrp_transaction::INTRP_REQ;
                intrp_trans.intrp_src=intrp_vif.intrp_src;
                intrp_trans.intrp_ctx=intrp_vif.intrp_ctx;
                intrp_tran_port.write(intrp_trans);                
            end
            else if((intrp_vif.intrp_req == 0) && (intrp_vif.intrp_ack == 0))begin
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_IDLE statsu.")
            end
        end
        else if(intrp_status_item == INTRP_WAIT_ACK)begin
            if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 1))begin
                intrp_status_item = INTRP_FINISH;
                intrp_trans.intrp_item=intrp_transaction::INTRP_ACK;
                intrp_trans.intrp_src=intrp_vif.intrp_src;
                intrp_trans.intrp_ctx=intrp_vif.intrp_ctx;
                intrp_tran_port.write(intrp_trans);                
            end
            else if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 0))begin
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_WAIT_ACK statsu.")
            end
        end
        else begin
            if((intrp_vif.intrp_req == 0) && (intrp_vif.intrp_ack == 1))begin
                intrp_status_item = INTRP_IDLE;
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_FINISH statsu.")
            end
        end
    end
endtask : collect_interrupt

// Collect afu tlx command and data
task tlx_afu_monitor::collect_afu_tlx_cmd();
    `uvm_info(tID, $sformatf("Collect_afu_tlx_cmd begin ..."), UVM_MEDIUM)
    forever begin
        afu_tlx_cmd_trans = new("afu_tlx_cmd_trans");
        @(tlx_afu_vif.afu_clock)
        if(tlx_afu_vif.afu_tlx_cmd_valid_top == 1) begin
            afu_tlx_cmd_trans.afu_tlx_opcode = tlx_afu_vif.afu_tlx_cmd_opcode_top;
            afu_tlx_cmd_trans.afu_tlx_afutag = tlx_afu_vif.afu_tlx_cmd_afutag_top;
            afu_tlx_cmd_trans.afu_tlx_addr = tlx_afu_vif.afu_tlx_cmd_ea_or_obj_top;
            afu_tlx_cmd_trans.afu_tlx_dl = tlx_afu_vif.afu_tlx_cmd_dl_top;
            afu_tlx_cmd_trans.afu_tlx_pl = tlx_afu_vif.afu_tlx_cmd_pl_top;
            afu_tlx_cmd_trans.afu_tlx_be = tlx_afu_vif.afu_tlx_cmd_be_top;
            afu_tlx_cmd_trans.afu_tlx_actag = tlx_afu_vif.afu_tlx_cmd_actag_top;
            afu_tlx_cmd_trans.afu_tlx_stream_id = tlx_afu_vif.afu_tlx_cmd_stream_id_top;
            afu_tlx_cmd_trans.afu_tlx_bdf = tlx_afu_vif.afu_tlx_cmd_bdf_top;
            afu_tlx_cmd_trans.afu_tlx_pasid = tlx_afu_vif.afu_tlx_cmd_pasid_top;
            afu_tlx_cmd_trans.afu_tlx_pg_size = tlx_afu_vif.afu_tlx_cmd_pg_size_top;
            afu_tlx_cmd_trans.afu_tlx_type = get_afu_tlx_type(afu_tlx_cmd_trans.afu_tlx_opcode);
            afu_tlx_cmd_trans_q.push_back(afu_tlx_cmd_trans);
            afu_tlx_cmd_num++;
        end
        if(tlx_afu_vif.afu_tlx_cdata_valid_top == 1) begin
            afu_tlx_cmd_data_q.push_back({tlx_afu_vif.afu_tlx_cdata_bdi_top, tlx_afu_vif.afu_tlx_cdata_bus_top});
        end
        if(afu_tlx_cmd_trans_q.size > 0)
            pack_afu_tlx_cmd();
    end
endtask : collect_afu_tlx_cmd

// Collect afu tlx response and data
task tlx_afu_monitor::collect_afu_tlx_resp();
    `uvm_info(tID, $sformatf("Collect_afu_tlx_resp begin ..."), UVM_MEDIUM)
    forever begin
        afu_tlx_resp_trans = new("afu_tlx_resp_trans");
        @(tlx_afu_vif.afu_clock)
        if(tlx_afu_vif.afu_tlx_resp_valid_top == 1) begin
            afu_tlx_resp_trans.afu_tlx_opcode = tlx_afu_vif.afu_tlx_resp_opcode_top;
            afu_tlx_resp_trans.afu_tlx_capptag = tlx_afu_vif.afu_tlx_resp_capptag_top;
            afu_tlx_resp_trans.afu_tlx_dl = tlx_afu_vif.afu_tlx_resp_dl_top;
            afu_tlx_resp_trans.afu_tlx_dp = tlx_afu_vif.afu_tlx_resp_dp_top;
            afu_tlx_resp_trans.afu_tlx_resp_code = tlx_afu_vif.afu_tlx_resp_code_top;
            afu_tlx_resp_trans.afu_tlx_type = get_afu_tlx_type(afu_tlx_resp_trans.afu_tlx_opcode);
            afu_tlx_resp_trans_q.push_back(afu_tlx_resp_trans);
            afu_tlx_resp_num++;
        end
        if(tlx_afu_vif.afu_tlx_rdata_valid_top == 1) begin
            afu_tlx_resp_data_q.push_back({tlx_afu_vif.afu_tlx_rdata_bdi_top, tlx_afu_vif.afu_tlx_rdata_bus_top});
        end
        if(afu_tlx_resp_trans_q.size > 0)
            pack_afu_tlx_resp();
    end
endtask : collect_afu_tlx_resp

// Collect tlx afu command and data
task tlx_afu_monitor::collect_tlx_afu_cmd();
    `uvm_info(tID, $sformatf("Collect_tlx_afu_cmd begin ..."), UVM_MEDIUM)
    forever begin
        tlx_afu_cmd_trans = new("tlx_afu_cmd_trans");
        @(posedge tlx_afu_vif.tlx_clock)
        if(tlx_afu_vif.tlx_afu_cmd_valid_top == 1) begin
            tlx_afu_cmd_trans.tlx_afu_opcode = tlx_afu_vif.tlx_afu_cmd_opcode_top;
            tlx_afu_cmd_trans.tlx_afu_capptag = tlx_afu_vif.tlx_afu_cmd_capptag_top;
            tlx_afu_cmd_trans.tlx_afu_addr = tlx_afu_vif.tlx_afu_cmd_pa_top;
            tlx_afu_cmd_trans.tlx_afu_dl = tlx_afu_vif.tlx_afu_cmd_dl_top;
            tlx_afu_cmd_trans.tlx_afu_pl = tlx_afu_vif.tlx_afu_cmd_pl_top;
            tlx_afu_cmd_trans.tlx_afu_be = tlx_afu_vif.tlx_afu_cmd_be_top;
            tlx_afu_cmd_trans.tlx_afu_type = get_tlx_afu_type(tlx_afu_cmd_trans.tlx_afu_opcode);
            tlx_afu_cmd_trans_q.push_back(tlx_afu_cmd_trans);
            tlx_afu_cmd_num++;
        end
        if(tlx_afu_vif.tlx_afu_cmd_data_valid_top == 1) begin
            tlx_afu_cmd_data_q.push_back({tlx_afu_vif.tlx_afu_cmd_data_bdi_top, tlx_afu_vif.tlx_afu_cmd_data_bus_top});
        end
        if(tlx_afu_cmd_trans_q.size > 0)
            pack_tlx_afu_cmd();
    end
endtask : collect_tlx_afu_cmd

// Collect tlx afu response and data
task tlx_afu_monitor::collect_tlx_afu_resp();
    `uvm_info(tID, $sformatf("Collect_tlx_afu_resp begin ..."), UVM_MEDIUM)
    forever begin
        tlx_afu_resp_trans = new("tlx_afu_resp_trans");
        @(posedge tlx_afu_vif.tlx_clock)
        if(tlx_afu_vif.tlx_afu_resp_valid_top == 1) begin
            tlx_afu_resp_trans.tlx_afu_opcode = tlx_afu_vif.tlx_afu_resp_opcode_top;
            tlx_afu_resp_trans.tlx_afu_afutag = tlx_afu_vif.tlx_afu_resp_afutag_top;
            tlx_afu_resp_trans.tlx_afu_dl = tlx_afu_vif.tlx_afu_resp_dl_top;
            tlx_afu_resp_trans.tlx_afu_dp = tlx_afu_vif.tlx_afu_resp_dp_top;
            tlx_afu_resp_trans.tlx_afu_resp_code = tlx_afu_vif.tlx_afu_resp_code_top;
            tlx_afu_resp_trans.tlx_afu_pg_size = tlx_afu_vif.tlx_afu_resp_pg_size_top;
            tlx_afu_resp_trans.tlx_afu_resp_host_tag = tlx_afu_vif.tlx_afu_resp_host_tag_top;
            tlx_afu_resp_trans.tlx_afu_resp_addr_tag = tlx_afu_vif.tlx_afu_resp_addr_tag_top;
            tlx_afu_resp_trans.tlx_afu_resp_cache_state = tlx_afu_vif.tlx_afu_resp_cache_state_top;
            tlx_afu_resp_trans.tlx_afu_type = get_tlx_afu_type(tlx_afu_resp_trans.tlx_afu_opcode);
            tlx_afu_resp_trans_q.push_back(tlx_afu_resp_trans);
            tlx_afu_resp_num++;
        end
        if(tlx_afu_vif.tlx_afu_resp_data_valid_top == 1)
            tlx_afu_resp_data_q.push_back({tlx_afu_vif.tlx_afu_resp_data_bdi_top, tlx_afu_vif.tlx_afu_resp_data_bus_top});
        if(tlx_afu_resp_trans_q.size > 0)
            pack_tlx_afu_resp();
    end
endtask : collect_tlx_afu_resp

// Pack afu tlx command with data
function void tlx_afu_monitor::pack_afu_tlx_cmd();
    if(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_N) begin
        if(afu_tlx_cmd_data_q.size >= dl2dl_num(afu_tlx_cmd_trans_q[0].afu_tlx_dl)) begin
            for(int i=0; i<dl2dl_num(afu_tlx_cmd_trans_q[0].afu_tlx_dl); i++) begin
                afu_tlx_cmd_trans_q[0].afu_tlx_data_bus[i] = afu_tlx_cmd_data_q[0][511:0];
                afu_tlx_cmd_trans_q[0].afu_tlx_data_bdi[i] = afu_tlx_cmd_data_q[0][512];
                afu_tlx_cmd_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect an afu-tlx command and data.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            c_afu_tlx_cmd_packet.sample();
            $cast(pre_afu_tlx_cmd_trans, afu_tlx_cmd_trans_q[0].clone()); 
            afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
        end
    end
    else if(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_BE || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_BE_N ||
            afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W) begin
        if(afu_tlx_cmd_data_q.size > 0) begin
            afu_tlx_cmd_trans_q[0].afu_tlx_data_bus[0] = afu_tlx_cmd_data_q[0][511:0];
            afu_tlx_cmd_trans_q[0].afu_tlx_data_bdi[0] = afu_tlx_cmd_data_q[0][512];
            afu_tlx_cmd_data_q.pop_front();                        
            c_afu_tlx_cmd_packet.sample();
            $cast(pre_afu_tlx_cmd_trans, afu_tlx_cmd_trans_q[0].clone());
            `uvm_info(tID, $sformatf("Collect an afu-tlx command and data.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
        end
    end
    else begin
        c_afu_tlx_cmd_packet.sample();
        $cast(pre_afu_tlx_cmd_trans, afu_tlx_cmd_trans_q[0].clone()); 
        `uvm_info(tID, $sformatf("Collect an afu-tlx command.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
        afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
    end
endfunction : pack_afu_tlx_cmd

// Pack afu tlx response with data
function void tlx_afu_monitor::pack_afu_tlx_resp();
    if(afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE) begin
        if(afu_tlx_resp_data_q.size >= dl2dl_num(afu_tlx_resp_trans_q[0].afu_tlx_dl)) begin
            for(int i=0; i<dl2dl_num(afu_tlx_resp_trans_q[0].afu_tlx_dl); i++) begin
                afu_tlx_resp_trans_q[0].afu_tlx_data_bus[i] = afu_tlx_resp_data_q[0][511:0];
                afu_tlx_resp_trans_q[0].afu_tlx_data_bdi[i] = afu_tlx_resp_data_q[0][512];
                afu_tlx_resp_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect a afu-tlx response and data.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
        end
    end
    else if((afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE_OW) || (afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE_XW)) begin
        if(afu_tlx_resp_data_q.size > 0) begin
            afu_tlx_resp_trans_q[0].afu_tlx_data_bus[0] = afu_tlx_resp_data_q[0][511:0];
            afu_tlx_resp_trans_q[0].afu_tlx_data_bdi[0] = afu_tlx_resp_data_q[0][512];
            afu_tlx_resp_data_q.pop_front();
            `uvm_info(tID, $sformatf("Collect a afu-tlx response and data.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect a afu-tlx response.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
        afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
    end
endfunction : pack_afu_tlx_resp

// Pack tlx afu command with data
function void tlx_afu_monitor::pack_tlx_afu_cmd();
    if(tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::WRITE_MEM) begin
        if(tlx_afu_cmd_data_q.size >= dl2dl_num(tlx_afu_cmd_trans_q[0].tlx_afu_dl)) begin
            for(int i=0; i<dl2dl_num(tlx_afu_cmd_trans_q[0].tlx_afu_dl); i++) begin
                tlx_afu_cmd_trans_q[0].tlx_afu_data_bus[i] = tlx_afu_cmd_data_q[0][511:0];
                tlx_afu_cmd_trans_q[0].tlx_afu_data_bdi[i] = tlx_afu_cmd_data_q[0][512];
                tlx_afu_cmd_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect an tlx-afu command and data.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
        end
    end
    else if(tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::WRITE_MEM_BE || tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::PR_WR_MEM) begin
        if(tlx_afu_cmd_data_q.size > 0) begin
            tlx_afu_cmd_trans_q[0].tlx_afu_data_bus[0] = tlx_afu_cmd_data_q[0][511:0];
            tlx_afu_cmd_trans_q[0].tlx_afu_data_bdi[0] = tlx_afu_cmd_data_q[0][512];
            `uvm_info(tID, $sformatf("Collect an tlx-afu command and data.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect an tlx-afu command.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
        //tlx_afu_cmd_trans_q.pop_front();
        tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
    end
endfunction : pack_tlx_afu_cmd

// Pack tlx afu response with data
function void tlx_afu_monitor::pack_tlx_afu_resp();
    if(tlx_afu_resp_trans_q[0].tlx_afu_type == tlx_afu_transaction::READ_RESPONSE) begin
        if(tlx_afu_resp_data_q.size >= dl2dl_num(tlx_afu_resp_trans_q[0].tlx_afu_dl)) begin
            for(int i=0; i<dl2dl_num(tlx_afu_resp_trans_q[0].tlx_afu_dl); i++) begin
                tlx_afu_resp_trans_q[0].tlx_afu_data_bus[i] = tlx_afu_resp_data_q[0][511:0];
                tlx_afu_resp_trans_q[0].tlx_afu_data_bdi[i] = tlx_afu_resp_data_q[0][512];
                tlx_afu_resp_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect a tlx-afu response and data.\n%s", tlx_afu_resp_trans_q[0].sprint()), UVM_MEDIUM);
            c_tlx_afu_resp_packet.sample();
            $cast(pre_tlx_afu_resp_trans, tlx_afu_resp_trans_q[0].clone());            
            tlx_afu_tran_port.write(tlx_afu_resp_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect a tlx-afu response.\n%s", tlx_afu_resp_trans_q[0].sprint()), UVM_MEDIUM);
        c_tlx_afu_resp_packet.sample();            
        $cast(pre_tlx_afu_resp_trans, tlx_afu_resp_trans_q[0].clone());            
        tlx_afu_tran_port.write(tlx_afu_resp_trans_q.pop_front());
    end
endfunction : pack_tlx_afu_resp

// Get afu tlx command/response type
function afu_tlx_transaction::afu_tlx_enum tlx_afu_monitor::get_afu_tlx_type(bit[7:0] afu_tlx_opcode);
    case(afu_tlx_opcode)
        8'b0000_0001: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE;
        8'b0000_0010: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_FAIL;
        8'b0000_0011: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE_OW;
        8'b0000_0100: get_afu_tlx_type = afu_tlx_transaction::MEM_WR_RESPONSE;
        8'b0000_0101: get_afu_tlx_type = afu_tlx_transaction::MEM_WR_FAIL;
        8'b0000_0111: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE_XW;
        8'b0001_0000: get_afu_tlx_type = afu_tlx_transaction::RD_WNITC;
        8'b0001_0010: get_afu_tlx_type = afu_tlx_transaction::PR_RD_WNITC;
        8'b0001_0100: get_afu_tlx_type = afu_tlx_transaction::RD_WNITC_N;
        8'b0001_0110: get_afu_tlx_type = afu_tlx_transaction::PR_RD_WNITC_N;
        8'b0010_0000: get_afu_tlx_type = afu_tlx_transaction::DMA_W;
        8'b0010_0100: get_afu_tlx_type = afu_tlx_transaction::DMA_W_N;
        8'b0010_1000: get_afu_tlx_type = afu_tlx_transaction::DMA_W_BE;
        8'b0010_1100: get_afu_tlx_type = afu_tlx_transaction::DMA_W_BE_N;
        8'b0011_0000: get_afu_tlx_type = afu_tlx_transaction::DMA_PR_W;
        8'b0011_0100: get_afu_tlx_type = afu_tlx_transaction::DMA_PR_W_N;
        8'b0101_0000: get_afu_tlx_type = afu_tlx_transaction::ASSIGN_ACTAG;
        8'b0101_1000: get_afu_tlx_type = afu_tlx_transaction::INTRP_REQ;
        8'b0101_1010: get_afu_tlx_type = afu_tlx_transaction::INTRP_REQ_D;
        8'b0101_1100: get_afu_tlx_type = afu_tlx_transaction::WAKE_HOST_THREAD;
        8'b0111_1000: get_afu_tlx_type = afu_tlx_transaction::XLATE_TOUCH;
        8'b0111_1100: get_afu_tlx_type = afu_tlx_transaction:: XLATE_TOUCH_N;
        default: `uvm_error(get_type_name(), "Get an illegal afu tlx opcode!")
    endcase
endfunction : get_afu_tlx_type

// Get tlx afu command/response type
function tlx_afu_transaction::tlx_afu_enum tlx_afu_monitor::get_tlx_afu_type(bit[7:0] tlx_afu_opcode);
    case(tlx_afu_opcode)
        8'b0000_0010: get_tlx_afu_type = tlx_afu_transaction::TOUCH_RESP;
        8'b0000_0100: get_tlx_afu_type = tlx_afu_transaction::READ_RESPONSE;
        8'b0000_0101: get_tlx_afu_type = tlx_afu_transaction::READ_FAILED;
        8'b0000_1000: get_tlx_afu_type = tlx_afu_transaction::WRITE_RESPONSE;
        8'b0000_1001: get_tlx_afu_type = tlx_afu_transaction::WRITE_FAILED;
        8'b0000_1100: get_tlx_afu_type = tlx_afu_transaction::INTRP_RESP;
        8'b0001_0000: get_tlx_afu_type = tlx_afu_transaction::WAKE_HOST_RESP;
        8'b0001_1000: get_tlx_afu_type = tlx_afu_transaction::XLATE_DONE;
        8'b0001_1010: get_tlx_afu_type = tlx_afu_transaction::INTRP_RDY;
        8'b0010_0000: get_tlx_afu_type = tlx_afu_transaction::RD_MEM;
        8'b0010_1000: get_tlx_afu_type = tlx_afu_transaction::PR_RD_MEM;
        8'b1000_0001: get_tlx_afu_type = tlx_afu_transaction::WRITE_MEM;
        8'b1000_0110: get_tlx_afu_type = tlx_afu_transaction::PR_WR_MEM;
        8'b1000_0010: get_tlx_afu_type = tlx_afu_transaction::WRITE_MEM_BE;
        default: `uvm_error(get_type_name(), "Get an illegal tlx afu opcode!")
    endcase
endfunction : get_tlx_afu_type

function int tlx_afu_monitor::dl2dl_num(bit[1:0] dl);
    case(dl)
        2'b01: dl2dl_num = 1;
        2'b10: dl2dl_num = 2;
        2'b11: dl2dl_num = 4;
        default: `uvm_error(get_type_name(), "Get an illegal data length!")
    endcase
endfunction : dl2dl_num

`endif // _TLX_AFU_MONITOR_SV_
