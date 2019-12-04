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
`ifndef _TL_MANAGER_SV
`define _TL_MANAGER_SV

`define DL_CREDITS_MAX          32
`define TL_VC0_CREDITS_MAX      4
`define TL_VC1_CREDITS_MAX      31
`define TL_DCP1_CREDITS_MAX     64
`define TLX_VC0_CREDITS_MAX     64
`define TLX_VC3_CREDITS_MAX     64
`define TLX_DCP0_CREDITS_MAX    128
`define RETRY_NUM_MAX           2
`define CLOCK_CYCLE_IN_NS       2
`define CMD_LATENCY_MIN         30
`define CMD_LATENCY_MAX         160
`define FIR_REG_RD_NUM          11
`define FIR_REG_WR_NUM          8

class tl_manager extends uvm_component;
    //Virtual interface definition.
    virtual interface tl_dl_if tl_dl_vif;
    //TLM port declarations
    `uvm_analysis_imp_decl(_tx_mon)
    `uvm_analysis_imp_decl(_rx_mon)
    `uvm_analysis_imp_decl(_dl_credit)

    uvm_analysis_port #(tl_tx_trans)     mgr_output_trans_port;    //manager to driver cmd/rsp port
    uvm_analysis_port #(dl_credit_trans) mgr_output_credit_port;   //manager to driver dl credit port
    uvm_analysis_imp_tx_mon     #(tl_tx_trans, tl_manager) mgr_input_tx_port;         //tx monitor to manager port
    uvm_analysis_imp_rx_mon     #(tl_rx_trans, tl_manager) mgr_input_rx_port;         //rx monitor to manager cmd/rsp port
    uvm_analysis_imp_dl_credit  #(dl_credit_trans, tl_manager) mgr_input_credit_port; //rx monitor to manager dl credit port

    tl_cfg_obj       cfg_obj;
    host_mem_model   host_mem;

    class acTag_entry;
        bit valid;
        int bdf;
        int pasid;

        function new (string name = "acTag_entry");
            valid = 0;
            bdf = 0;
            pasid = 0;
        endfunction: new
    endclass: acTag_entry

    class tx_cmd_trans;
        tl_tx_trans tx_cmd_item;
        int         cur_dLength;
        bit         resp_fail_rty;
        int         resp_num;

        function new (string name = "tx_cmd_trans");
            tx_cmd_item = new("tx_cmd_item");
            cur_dLength = 0;
            resp_fail_rty = 0;
            resp_num = 0;
        endfunction: new
    endclass: tx_cmd_trans

    class rx_cmd_trans;
        tl_rx_trans rx_cmd_item;
        int         cur_dLength;

        function new (string name = "rx_cmd_trans");
            rx_cmd_item = new("rx_cmd_item");
            cur_dLength = 0;
        endfunction: new
    endclass: rx_cmd_trans

    class tx_timer_trans;
        tl_tx_trans tx_trans;
        int         timer;

        function new (string name = "tx_timer_trans");
            tx_trans = new("tx_trans");
            timer = 0;
        endfunction: new
    endclass: tx_timer_trans

    class tag_entry;
        real        start_time;
        real        finish_time;
        bit         reused;

        function new (string name = "tag_entry");
            start_time = 0;
            finish_time = 0;
            reused = 0;
        endfunction: new
    endclass: tag_entry

    class retry_entry;
        tl_tx_trans::packet_type_enum tx_packet;
        tl_rx_trans::packet_type_enum rx_packet;
        int                           retry_num;

        function new (string name = "retry_entry");
            tx_packet = tl_tx_trans::NOP;
            rx_packet = tl_rx_trans::NOP_R;
            retry_num = 0;
        endfunction: new
    endclass: retry_entry

    class resp_num_128B;
        rand int number;
        int w_num1, w_num2;
        constraint c_number {
            number dist{1:=w_num1, 2:=w_num2};
        }
    endclass: resp_num_128B 

    class resp_num_256B;
        rand int number;
        int w_num1, w_num2, w_num3, w_num4;
        constraint c_number {
            number dist{1:=w_num1, 2:=w_num2, 3:=w_num3, 4:=w_num4};
        }
    endclass: resp_num_256B 

    class fail_resp;
        rand bit fail_en;
        int w_good, w_fail;
        constraint c_fail_en {
            fail_en dist{0:=w_good, 1:=w_fail};
        }
    endclass: fail_resp 

    class fail_resp_code;
        typedef enum bit[3:0]{
            RESP_RTY_REQ       = 4'b0010,
            RESP_XLATE_PENDING = 4'b0100,
            RESP_DERROR        = 4'b1000,
            RESP_FAILED        = 4'b1110,
            RESP_RESERVED      = 4'b0000
        } code_e;
        rand code_e code;
        int w_rty, w_xlate, w_derror, w_failed, w_reserved;
        constraint c_code {
            code dist{
                    RESP_RTY_REQ:=w_rty,
                    RESP_XLATE_PENDING:=w_xlate,
                    RESP_DERROR:=w_derror,
                    RESP_FAILED:=w_failed,
                    RESP_RESERVED:=w_reserved
                    };
        }
    endclass: fail_resp_code 

    class xlate_resp_code;
        typedef enum bit[3:0]{
            RESP_CMP           = 4'b0000,
            RESP_RTY_REQ       = 4'b0010,
            RESP_ADDR_ERR      = 4'b1111,
            RESP_RESERVED      = 4'b0001
        } code_e;
        rand code_e code;
        int w_cmp, w_rty, w_aerror, w_reserved;
        constraint c_code {
            code dist{
                    RESP_CMP:=w_cmp,
                    RESP_RTY_REQ:=w_rty,
                    RESP_ADDR_ERR:=w_aerror,
                    RESP_RESERVED:=w_reserved
                    };
        }
    endclass: xlate_resp_code 

    int              tl_vc_credits[4];
    int              tl_data_credits[4];
    int              tlx_vc_credits[4];
    int              tlx_data_credits[4];
    int              dl_credits;
    tx_cmd_trans     tx_cmd_queue[bit[15:0]]; //CAPPTag index
    rx_cmd_trans     rx_cmd_queue[bit[15:0]]; //AFUTag index
    tx_timer_trans   tx_back_off_queue[$];    //long back off cmd queue
    acTag_entry      acTag_table[bit[11:0]];
    tag_entry        capp_tag_queue[bit[15:0]];
    tag_entry        afu_tag_queue[bit[15:0]];
    retry_entry      retry_tx_info_queue[bit[15:0]];
    retry_entry      retry_rx_info_queue[bit[15:0]];
    tl_tx_trans      intrp_handle_queue[bit[15:0]];
    tl_tx_trans      intrp_resp_queue[$];
    tx_timer_trans   rd_wr_resp_queue[$];
    tx_timer_trans   split_resp_queue[$];
    bit [31:0]       fir_rd_addr_list[`FIR_REG_RD_NUM] = '{ //Global FIR -> Local FIR
                        32'h08040000, //Global xstop FIR
                        32'h08040001, //Global recoverable FIR
                        32'h08040004, //Global special attention FIR
                        32'h08040018, //Global application interrupt FIR
                        32'h08012800, //DLx FIR
                        32'h08011800, //MCBIST FIR
                        32'h08010870, //MMIO FIR
                        32'h08011c00, //RDF FIR
                        32'h08011400, //SRQ FIR
                        32'h08012400, //TLx FIR
                        32'h0804000a  //TP FIR
                     };
    bit [31:0]       fir_wr_addr_list[`FIR_REG_WR_NUM] = '{ //Local FIR -> Global FIR
                        32'h08012800, //DLx FIR
                        32'h08011800, //MCBIST FIR
                        32'h08010870, //MMIO FIR
                        32'h08011c00, //RDF FIR
                        32'h08011400, //SRQ FIR
                        32'h08012400, //TLx FIR
                        32'h0804000a, //TP FIR
                        32'h08040000  //Global xstop FIR
                     };


    //Coverage    
    bit coverage_on = 0;
    tl_tx_trans::packet_type_enum cov_tx_packet_type;
    tl_rx_trans::packet_type_enum cov_rx_packet_type;
    bit                           cov_capp_tag_reuse_en;
    bit[15:0]                     cov_capp_tag_reuse;
    bit                           cov_afu_tag_reuse_en;
    bit[15:0]                     cov_afu_tag_reuse;
    int                           cov_rd_resp_num;
    int                           cov_wr_resp_num;
    tl_tx_trans::packet_type_enum cov_retry_tx_packet;
    tl_rx_trans::packet_type_enum cov_retry_rx_packet;
    int                           cov_retry_tx_num;
    int                           cov_retry_rx_num;
    tl_tx_trans::packet_type_enum cov_latency_packet;
    int                           cov_latency_in_cycle;
    tl_tx_trans::packet_type_enum cov_first_packet;
    tl_tx_trans::packet_type_enum cov_second_packet;
    bit[1:0]                      cov_first_dlength;
    bit[1:0]                      cov_second_dlength;
    bit[63:0]                     cov_first_addr;
    bit[63:0]                     cov_second_addr;

    covergroup c_dl_credits;
        option.per_instance = 1;
        dl_credits:             coverpoint dl_credits{
                                    bins value[] = {[0:`DL_CREDITS_MAX]};
                                }
    endgroup: c_dl_credits

    covergroup c_tl_credits;
        option.per_instance = 1;
        tl_vc0_credits:         coverpoint tl_vc_credits[0]{
                                    bins value[] = {[0:`TL_VC0_CREDITS_MAX]};
                                }
        tl_vc1_credits:         coverpoint tl_vc_credits[1]{
                                    bins value[] = {[0:`TL_VC1_CREDITS_MAX]};
                                }
        tl_dcp1_credits:        coverpoint tl_data_credits[1]{
                                    bins value[] = {[0:`TL_DCP1_CREDITS_MAX]};
                                }
    endgroup: c_tl_credits

    covergroup c_tlx_credits;
        option.per_instance = 1;
        tlx_vc0_credit:         coverpoint tlx_vc_credits[0]{
                                    bins value[] = {[0:`TLX_VC0_CREDITS_MAX]};
                                }
        tlx_vc3_credits:        coverpoint tlx_vc_credits[3]{
                                    bins value[] = {[0:`TLX_VC3_CREDITS_MAX]};
                                }
        tlx_dcp0_credits:       coverpoint tlx_data_credits[0]{
                                    bins value[] = {[0:`TLX_DCP0_CREDITS_MAX]};
                                }
    endgroup: c_tlx_credits

    covergroup c_tx_packet_credits;
        option.per_instance = 1;
        tl_vc0_credits_value:   coverpoint tl_vc_credits[0]{
                                    bins min = {1};
                                    bins max = {`TL_VC0_CREDITS_MAX};
                                }
        tl_vc1_credits_value:   coverpoint tl_vc_credits[1]{
                                    bins min = {1};
                                    bins max = {`TL_VC1_CREDITS_MAX};
                                }
        tl_dcp1_credits_value:  coverpoint tl_data_credits[1]{
                                    bins min = {1};
                                    bins max = {`TL_DCP1_CREDITS_MAX};
                                }
        tx_packet_type:         coverpoint cov_tx_packet_type{
                                    bins config_read = {tl_tx_trans::CONFIG_READ};
                                    bins config_write = {tl_tx_trans::CONFIG_WRITE};
                                    bins intrp_resp = {tl_tx_trans::INTRP_RESP};
                                    bins intrp_rdy = {tl_tx_trans::INTRP_RDY};
                                    bins mem_cntl = {tl_tx_trans::MEM_CNTL};
                                    bins pr_rd_mem = {tl_tx_trans::PR_RD_MEM};
                                    bins pr_wr_mem = {tl_tx_trans::PR_WR_MEM};
                                    bins rd_mem = {tl_tx_trans::RD_MEM};
                                    bins write_mem = {tl_tx_trans::WRITE_MEM};
                                    bins write_mem_be = {tl_tx_trans::WRITE_MEM_BE};
                                }
        tx_packet_tl_vc0:       cross tx_packet_type,tl_vc0_credits_value{
                                    bins mem_cntl_vc0_min = binsof(tx_packet_type.mem_cntl) && binsof(tl_vc0_credits_value) intersect{1};
                                    bins mem_cntl_vc0_max = binsof(tx_packet_type.mem_cntl) && binsof(tl_vc0_credits_value) intersect{`TL_VC0_CREDITS_MAX};
                                    bins intrp_resp_vc0_min = binsof(tx_packet_type.intrp_resp) && binsof(tl_vc0_credits_value) intersect{1};
                                    bins intrp_resp_vc0_max = binsof(tx_packet_type.intrp_resp) && binsof(tl_vc0_credits_value) intersect{`TL_VC0_CREDITS_MAX};
                                    bins intrp_rdy_vc0_min = binsof(tx_packet_type.intrp_rdy) && binsof(tl_vc0_credits_value) intersect{1};
                                    bins intrp_rdy_vc0_max = binsof(tx_packet_type.intrp_rdy) && binsof(tl_vc0_credits_value) intersect{`TL_VC0_CREDITS_MAX};
                                    bins ignore = binsof(tx_packet_type) && binsof(tl_vc0_credits_value);
                                }
        tx_packet_tl_vc1:       cross tx_packet_type,tl_vc1_credits_value{
                                    bins config_read_vc1_min = binsof(tx_packet_type.config_read) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins config_read_vc1_max = binsof(tx_packet_type.config_read) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins config_write_vc1_min = binsof(tx_packet_type.config_write) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins config_write_vc1_max = binsof(tx_packet_type.config_write) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins pr_rd_mem_vc1_min = binsof(tx_packet_type.pr_rd_mem) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins pr_rd_mem_vc1_max = binsof(tx_packet_type.pr_rd_mem) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins pr_wr_mem_vc1_min = binsof(tx_packet_type.pr_wr_mem) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins pr_wr_mem_vc1_max = binsof(tx_packet_type.pr_wr_mem) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins rd_mem_vc1_min = binsof(tx_packet_type.rd_mem) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins rd_mem_vc1_max = binsof(tx_packet_type.rd_mem) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins write_mem_vc1_min = binsof(tx_packet_type.write_mem) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins write_mem_vc1_max = binsof(tx_packet_type.write_mem) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins write_mem_be_vc1_min = binsof(tx_packet_type.write_mem_be) && binsof(tl_vc1_credits_value) intersect{1};
                                    bins write_mem_be_vc1_max = binsof(tx_packet_type.write_mem_be) && binsof(tl_vc1_credits_value) intersect{`TL_VC1_CREDITS_MAX};
                                    bins ignore = binsof(tx_packet_type) && binsof(tl_vc1_credits_value);
                                }
        tx_packet_tl_dcp1:      cross tx_packet_type,tl_dcp1_credits_value{
                                    bins config_write_dcp1_min = binsof(tx_packet_type.config_write) && binsof(tl_dcp1_credits_value) intersect{1};
                                    bins config_write_dcp1_max = binsof(tx_packet_type.config_write) && binsof(tl_dcp1_credits_value) intersect{`TL_DCP1_CREDITS_MAX};
                                    bins pr_wr_mem_dcp1_min = binsof(tx_packet_type.pr_wr_mem) && binsof(tl_dcp1_credits_value) intersect{1};
                                    bins pr_wr_mem_dcp1_max = binsof(tx_packet_type.pr_wr_mem) && binsof(tl_dcp1_credits_value) intersect{`TL_DCP1_CREDITS_MAX};
                                    bins write_mem_dcp1_min = binsof(tx_packet_type.write_mem) && binsof(tl_dcp1_credits_value) intersect{1};
                                    bins write_mem_dcp1_max = binsof(tx_packet_type.write_mem) && binsof(tl_dcp1_credits_value) intersect{`TL_DCP1_CREDITS_MAX};
                                    bins write_mem_be_dcp1_min = binsof(tx_packet_type.write_mem_be) && binsof(tl_dcp1_credits_value) intersect{1};
                                    bins write_mem_be_dcp1_max = binsof(tx_packet_type.write_mem_be) && binsof(tl_dcp1_credits_value) intersect{`TL_DCP1_CREDITS_MAX};
                                    bins ignore = binsof(tx_packet_type) && binsof(tl_dcp1_credits_value);
                                }
    endgroup: c_tx_packet_credits

    covergroup c_rx_packet_credits;
        option.per_instance = 1;
        tlx_vc0_credits_value:  coverpoint tlx_vc_credits[0]{
                                    bins min = {0};
                                    bins max = {`TLX_VC0_CREDITS_MAX-1};
                                }
        tlx_vc3_credits_value:  coverpoint tlx_vc_credits[3]{
                                    bins min = {0};
                                    bins max = {`TLX_VC3_CREDITS_MAX-1};
                                }
        tlx_dcp0_credits_value: coverpoint tlx_data_credits[0]{
                                    bins min = {0};
                                    bins max = {`TLX_DCP0_CREDITS_MAX-1};
                                }
        rx_packet_type:         coverpoint cov_rx_packet_type{
                                    bins assign_actag = {tl_rx_trans::ASSIGN_ACTAG};
                                    bins intrp_req = {tl_rx_trans::INTRP_REQ};
                                    bins mem_cntl_done = {tl_rx_trans::MEM_CNTL_DONE};
                                    bins mem_rd_fail = {tl_rx_trans::MEM_RD_FAIL};
                                    bins mem_rd_response = {tl_rx_trans::MEM_RD_RESPONSE};
                                    bins mem_rd_response_ow = {tl_rx_trans::MEM_RD_RESPONSE_OW};
                                    bins mem_wr_fail = {tl_rx_trans::MEM_WR_FAIL};
                                    bins mem_wr_response = {tl_rx_trans::MEM_WR_RESPONSE};
                                }
        rx_packet_tlx_vc0:      cross rx_packet_type,tlx_vc0_credits_value{
                                    bins mem_cntl_done_vc0_min = binsof(rx_packet_type.mem_cntl_done) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_cntl_done_vc0_max = binsof(rx_packet_type.mem_cntl_done) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins mem_rd_fail_vc0_min = binsof(rx_packet_type.mem_rd_fail) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_rd_fail_vc0_max = binsof(rx_packet_type.mem_rd_fail) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins mem_rd_response_vc0_min = binsof(rx_packet_type.mem_rd_response) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_rd_response_vc0_max = binsof(rx_packet_type.mem_rd_response) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins mem_rd_response_ow_vc0_min = binsof(rx_packet_type.mem_rd_response_ow) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_rd_response_ow_vc0_max = binsof(rx_packet_type.mem_rd_response_ow) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins mem_wr_fail_vc0_min = binsof(rx_packet_type.mem_wr_fail) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_wr_fail_vc0_max = binsof(rx_packet_type.mem_wr_fail) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins mem_wr_response_vc0_min = binsof(rx_packet_type.mem_wr_response) && binsof(tlx_vc0_credits_value) intersect{0};
                                    bins mem_wr_response_vc0_max = binsof(rx_packet_type.mem_wr_response) && binsof(tlx_vc0_credits_value) intersect{`TLX_VC0_CREDITS_MAX-1};
                                    bins ignore = binsof(rx_packet_type) && binsof(tlx_vc0_credits_value);
                                }
        rx_packet_tlx_vc3:      cross rx_packet_type,tlx_vc3_credits_value{
                                    bins assign_actag_vc3_min = binsof(rx_packet_type.assign_actag) && binsof(tlx_vc3_credits_value) intersect{0};
                                    bins assign_actag_vc3_max = binsof(rx_packet_type.assign_actag) && binsof(tlx_vc3_credits_value) intersect{`TLX_VC3_CREDITS_MAX-1};
                                    bins intrp_req_vc3_min = binsof(rx_packet_type.intrp_req) && binsof(tlx_vc3_credits_value) intersect{0};
                                    bins intrp_req_vc3_max = binsof(rx_packet_type.intrp_req) && binsof(tlx_vc3_credits_value) intersect{`TLX_VC3_CREDITS_MAX-1};
                                    bins ignore = binsof(rx_packet_type) && binsof(tlx_vc3_credits_value);
                                }
        rx_packet_tlx_dcp0:     cross rx_packet_type,tlx_dcp0_credits_value{
                                    bins mem_rd_response_dcp0_min = binsof(rx_packet_type.mem_rd_response) && binsof(tlx_dcp0_credits_value) intersect{0};
                                    bins mem_rd_response_dcp0_max = binsof(rx_packet_type.mem_rd_response) && binsof(tlx_dcp0_credits_value) intersect{`TLX_DCP0_CREDITS_MAX-1};
                                    bins mem_rd_response_ow_dcp0_min = binsof(rx_packet_type.mem_rd_response_ow) && binsof(tlx_dcp0_credits_value) intersect{0};
                                    bins mem_rd_response_ow_dcp0_max = binsof(rx_packet_type.mem_rd_response_ow) && binsof(tlx_dcp0_credits_value) intersect{`TLX_DCP0_CREDITS_MAX-1};
                                    bins ignore = binsof(rx_packet_type) && binsof(tlx_dcp0_credits_value);
                                }
    endgroup: c_rx_packet_credits

    covergroup c_tag_reuse;
        option.per_instance = 1;
        capp_tag_reuse:         coverpoint cov_capp_tag_reuse_en;
        afu_tag_reuse:          coverpoint cov_afu_tag_reuse_en;
    endgroup: c_tag_reuse

    covergroup c_resp_num;
        option.per_instance = 1;
        rd_resp_num:            coverpoint cov_rd_resp_num{
                                    bins num1 = {1};
                                    bins num2 = {2};
                                    bins num3 = {3};
                                    bins num4 = {4};
                                }
        wr_resp_num:            coverpoint cov_wr_resp_num{
                                    bins num1 = {1};
                                    bins num2 = {2};
                                }
    endgroup: c_resp_num

    covergroup c_tx_retry;
        option.per_instance = 1;
        tx_retry_packet:        coverpoint cov_retry_tx_packet{
                                    bins config_read = {tl_tx_trans::CONFIG_READ};
                                    bins config_write = {tl_tx_trans::CONFIG_WRITE};
                                    bins pr_rd_mem = {tl_tx_trans::PR_RD_MEM};
                                    bins pr_wr_mem = {tl_tx_trans::PR_WR_MEM};
                                    bins rd_mem = {tl_tx_trans::RD_MEM};
                                    bins write_mem = {tl_tx_trans::WRITE_MEM};
                                    bins write_mem_be = {tl_tx_trans::WRITE_MEM_BE};
                                }
        tx_retry_num:           coverpoint cov_retry_tx_num{
                                    bins value[] = {[1:`RETRY_NUM_MAX]};
                                }
        tx_packet_and_num:      cross tx_retry_packet,tx_retry_num;
    endgroup: c_tx_retry

    covergroup c_rx_retry;
        option.per_instance = 1;
        rx_retry_packet:        coverpoint cov_retry_rx_packet{
                                    bins intrp_req = {tl_rx_trans::INTRP_REQ};
                                }
        rx_retry_num:           coverpoint cov_retry_rx_num{
                                    bins value[] = {[1:`RETRY_NUM_MAX]};
                                }
        rx_packet_and_num:      cross rx_retry_packet,rx_retry_num;
    endgroup: c_rx_retry

    covergroup c_cmd_latency;
        option.per_instance = 1;
        cmd_packet:             coverpoint cov_latency_packet{
                                    bins config_read = {tl_tx_trans::CONFIG_READ};
                                    bins config_write = {tl_tx_trans::CONFIG_WRITE};
                                    bins mem_cntl = {tl_tx_trans::MEM_CNTL};
                                    bins pr_rd_mem = {tl_tx_trans::PR_RD_MEM};
                                    bins pr_wr_mem = {tl_tx_trans::PR_WR_MEM};
                                    bins rd_mem = {tl_tx_trans::RD_MEM};
                                    bins write_mem = {tl_tx_trans::WRITE_MEM};
                                    bins write_mem_be = {tl_tx_trans::WRITE_MEM_BE};
                                }
        cmd_latency:            coverpoint cov_latency_in_cycle{
                                    bins value[10] = {[`CMD_LATENCY_MIN:`CMD_LATENCY_MAX]};
                                }
        cmd_packet_and_latency: cross cmd_packet,cmd_latency;
    endgroup: c_cmd_latency

    covergroup c_mem_access_seq;
        option.per_instance = 1;
        first_mem_access:       coverpoint cov_first_packet{
                                    bins rd_mem = {tl_tx_trans::RD_MEM};
                                    bins write_mem = {tl_tx_trans::WRITE_MEM};
                                }
        first_dlength:          coverpoint cov_first_dlength{
                                    bins byte64  = {2'b01};
                                    bins byte128 = {2'b10};
                                }
        second_mem_access:      coverpoint cov_second_packet{
                                    bins rd_mem = {tl_tx_trans::RD_MEM};
                                    bins write_mem = {tl_tx_trans::WRITE_MEM};
                                }
        second_dlength:         coverpoint cov_second_dlength{
                                    bins byte64  = {2'b01};
                                    bins byte128 = {2'b10};
                                }
        two_mem_access:         cross first_mem_access,first_dlength,second_mem_access,second_dlength{
                                    bins raw_64byte  = binsof(first_mem_access.rd_mem) && binsof(first_dlength.byte64) && binsof(second_mem_access.write_mem) && binsof(second_dlength.byte64);
                                    bins raw_128byte = binsof(first_mem_access.rd_mem) && binsof(first_dlength.byte128) && binsof(second_mem_access.write_mem) && binsof(second_dlength.byte128);
                                    bins waw_64byte  = binsof(first_mem_access.write_mem) && binsof(first_dlength.byte64) && binsof(second_mem_access.write_mem) && binsof(second_dlength.byte64);
                                    bins waw_128byte = binsof(first_mem_access.write_mem) && binsof(first_dlength.byte128) && binsof(second_mem_access.write_mem) && binsof(second_dlength.byte128);
                                    bins war_64byte  = binsof(first_mem_access.write_mem) && binsof(first_dlength.byte64) && binsof(second_mem_access.rd_mem) && binsof(second_dlength.byte64);
                                    bins war_128byte = binsof(first_mem_access.write_mem) && binsof(first_dlength.byte128) && binsof(second_mem_access.rd_mem) && binsof(second_dlength.byte128);
                                    bins ignore = binsof(first_mem_access) && binsof(first_dlength) && binsof(second_mem_access) && binsof(second_dlength);
                                }
    endgroup: c_mem_access_seq

    `uvm_component_utils_begin(tl_manager)
        `uvm_field_int(coverage_on, UVM_ALL_ON)
    `uvm_component_utils_end

    function new (string name="tl_manager", uvm_component parent);
        super.new(name, parent);
        mgr_output_trans_port = new("mgr_ouput_trans_port", this);
        mgr_output_credit_port = new("mgr_ouput_credit_port", this);
        mgr_input_tx_port = new("mgr_input_tx_port", this);
        mgr_input_rx_port = new("mgr_input_rx_port", this);
        mgr_input_credit_port = new("mgr_input_credit_port", this);
        credits_reset();

        void'(uvm_config_db#(int)::get(this,"","coverage_on",coverage_on));
        if(coverage_on) begin
            c_dl_credits=new();
            c_dl_credits.set_inst_name({get_full_name(),".c_dl_credits"});
            c_tl_credits=new();
            c_tl_credits.set_inst_name({get_full_name(),".c_tl_credits"});
            c_tx_packet_credits=new();
            c_tx_packet_credits.set_inst_name({get_full_name(),".c_tx_packet_credits"});
            c_tlx_credits=new();
            c_tlx_credits.set_inst_name({get_full_name(),".c_tlx_credits"});
            c_rx_packet_credits=new();
            c_rx_packet_credits.set_inst_name({get_full_name(),".c_rx_packet_credits"});
            c_tag_reuse=new();
            c_tag_reuse.set_inst_name({get_full_name(),".c_tag_reuse"});
            c_resp_num=new();
            c_resp_num.set_inst_name({get_full_name(),".c_resp_num"});
            c_tx_retry=new();
            c_tx_retry.set_inst_name({get_full_name(),".c_tx_retry"});
            c_rx_retry=new();
            c_rx_retry.set_inst_name({get_full_name(),".c_rx_retry"});
            c_cmd_latency=new();
            c_cmd_latency.set_inst_name({get_full_name(),".c_cmd_latency"});
            c_mem_access_seq=new();
            c_mem_access_seq.set_inst_name({get_full_name(),".c_mem_access_seq"});
        end 
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        host_mem = host_mem_model::type_id::create("host_mem", this);
        if(!uvm_config_db#(virtual tl_dl_if)::get(this, "","tl_dl_vif",tl_dl_vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".tl_dl_vif"})
    endfunction: build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        if(!uvm_config_db#(tl_cfg_obj)::get(this, "", "cfg_obj", cfg_obj))
            `uvm_error(get_type_name(), "Can't get cfg_obj!")
        credits_init();
    endfunction: start_of_simulation_phase

    task main_phase(uvm_phase phase);
        fork
            try_to_send_backoff();
            try_to_send_intrp_resp();
            try_to_send_rd_wr_resp();
        join
    endtask: main_phase

    function void check_phase(uvm_phase phase);
        bit[15:0]    idx;
        //collect retry info
        if(retry_tx_info_queue.size() != 0) begin
            `uvm_info(get_type_name(),$psprintf("tx retry queue is not empty at end of test, there are %d cmds in it", retry_tx_info_queue.size()), UVM_MEDIUM)
            if(retry_tx_info_queue.first(idx)) begin
                do begin
                    `uvm_info(get_type_name(),$psprintf("the tag of the trans:%s in tx retry queue is:0x%x, retry num is %d", retry_tx_info_queue[idx].tx_packet.name(), idx, retry_tx_info_queue[idx].retry_num), UVM_MEDIUM);
                    cov_retry_tx_packet = retry_tx_info_queue[idx].tx_packet;
                    cov_retry_tx_num = retry_tx_info_queue[idx].retry_num;
                    if(coverage_on)
                        c_tx_retry.sample();
                end
                while(retry_tx_info_queue.next(idx));
            end
        end
        if(retry_rx_info_queue.size() != 0) begin
            `uvm_info(get_type_name(),$psprintf("rx retry queue is not empty at end of test, there are %d cmds in it", retry_rx_info_queue.size()), UVM_MEDIUM)
            if(retry_rx_info_queue.first(idx)) begin
                do begin
                    `uvm_info(get_type_name(),$psprintf("the tag of the trans:%s in rx retry queue is:0x%x, retry num is %d", retry_rx_info_queue[idx].rx_packet.name(), idx, retry_rx_info_queue[idx].retry_num), UVM_MEDIUM);
                    cov_retry_rx_packet = retry_rx_info_queue[idx].rx_packet;
                    cov_retry_rx_num = retry_rx_info_queue[idx].retry_num;
                    if(coverage_on)
                        c_rx_retry.sample();
                end
                while(retry_rx_info_queue.next(idx));
            end
        end
        //check the cmd queue empty
        if(tx_cmd_queue.size() != 0) begin
            `uvm_info(get_type_name(),$psprintf("tx command queue is not empty at end of test, there are %d cmds in it", tx_cmd_queue.size()), UVM_MEDIUM)
            if(tx_cmd_queue.first(idx)) begin
                do begin
                    `uvm_info(get_type_name(),$psprintf("the tag of the trans:%s in tx command queue is:0x%x", tx_cmd_queue[idx].tx_cmd_item.packet_type.name(), idx), UVM_MEDIUM);
                end
                while(tx_cmd_queue.next(idx));
            end
            `uvm_error(get_type_name(),$psprintf("tx command queue is not empty at end of test"))
        end
        if(rx_cmd_queue.size() != 0) begin
            `uvm_info(get_type_name(),$psprintf("rx command queue is not empty at end of test, there are %d cmds in it", rx_cmd_queue.size()), UVM_MEDIUM)
            if(rx_cmd_queue.first(idx)) begin
                do begin
                    `uvm_info(get_type_name(),$psprintf("the tag of the trans:%s in rx command queue is:0x%x", rx_cmd_queue[idx].rx_cmd_item.packet_type.name(), idx), UVM_MEDIUM);
                end
                while(rx_cmd_queue.next(idx));
            end
            if(!cfg_obj.intrp_resp_bad_afutag_enable)
                `uvm_error(get_type_name(),$psprintf("rx command queue is not empty at end of test"))
        end
        //check DL credits
        if(cfg_obj.credits_check_enable) begin
            if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin
                if(dl_credits != 0)
                    `uvm_error(get_type_name(),$psprintf("DL credits is not 0 at end of test"))
            end
            else begin
                if(dl_credits != cfg_obj.dl_credit_count)
                    `uvm_error(get_type_name(),$psprintf("DL credits is not %d at end of test", cfg_obj.dl_credit_count))
            end
            //check TL credits
            for(int i=0; i<4; i++) begin
                if(tlx_vc_credits[i] != 0)
                    `uvm_error(get_type_name(),$psprintf("TLx VC%d credits is not 0 at end of test", i))
                if(tlx_data_credits[i] != 0)
                    `uvm_error(get_type_name(),$psprintf("TLx DCP%d credits is not 0 at end of test", i))
            end
            if(tl_vc_credits[0] != cfg_obj.tl_vc_credit_count[0])
                `uvm_error(get_type_name(),$psprintf("TL VC0 credits is not %d at end of test", cfg_obj.tl_vc_credit_count[0]))
            if(tl_vc_credits[1] != cfg_obj.tl_vc_credit_count[1])
                `uvm_error(get_type_name(),$psprintf("TL VC1 credits is not %d at end of test", cfg_obj.tl_vc_credit_count[1]))
            if(tl_data_credits[0] != cfg_obj.tl_data_credit_count[0])
                `uvm_error(get_type_name(),$psprintf("TL DCP0 credits is not %d at end of test", cfg_obj.tl_data_credit_count[0]))
            if(tl_data_credits[1] != cfg_obj.tl_data_credit_count[1])
                `uvm_error(get_type_name(),$psprintf("TL DCP1 credits is not %d at end of test", cfg_obj.tl_data_credit_count[1]))
        end
    endfunction: check_phase

    task try_to_send_backoff();
        tx_timer_trans queue_item;
        tl_tx_trans    tx_item;

        forever begin
            @(posedge tl_dl_vif.clock);
            while(tx_back_off_queue.size != 0) begin
                if(tx_back_off_queue[0].timer >= cfg_obj.host_back_off_timer) begin
                    queue_item = tx_back_off_queue.pop_front();
                    tx_item = queue_item.tx_trans;
                    mgr_output_trans_port.write(tx_item);
                end
                else begin
                    for(int i=0; i<tx_back_off_queue.size; i++) begin
                        tx_back_off_queue[i].timer++;
                    end
                    break;
                end
            end
        end
    endtask: try_to_send_backoff

    task try_to_send_intrp_resp();
        tl_tx_trans    tx_item;

        forever begin
            @(posedge tl_dl_vif.clock);
            while(intrp_resp_queue.size != 0) begin
                //wait all FIR read/write finish
                if(cfg_obj.intrp_resp_wait_fir_clear) begin
                    //all FIR regs access resps received
                    if(intrp_handle_queue.size == 0) begin
                        tx_item = intrp_resp_queue.pop_front();
                        mgr_output_trans_port.write(tx_item);
                    end
                    else
                        @(posedge tl_dl_vif.clock);
                end
                //don't wait
                else begin
                    tx_item = intrp_resp_queue.pop_front();
                    mgr_output_trans_port.write(tx_item);
                end
            end
        end
    endtask: try_to_send_intrp_resp

    task try_to_send_rd_wr_resp();
        tx_timer_trans queue_item, tmp_item;
        tl_tx_trans    tx_item;
        int            reorder_timer = 0;
        int unsigned   idx1, idx2;

        forever begin
            @(posedge tl_dl_vif.clock);
            //wait window cycle and do reorder
            if(cfg_obj.resp_reorder_enable) begin
                if(reorder_timer == cfg_obj.resp_reorder_window_cycle) begin
                    reorder_timer = 0;
                    if(rd_wr_resp_queue.size() != 0) begin
                        //do resp reorder
                        for(int unsigned i=0; i<rd_wr_resp_queue.size()/2; i++) begin
                            idx1 = $urandom_range(0, rd_wr_resp_queue.size()-1);
                            do begin
                                idx2 = $urandom_range(0, rd_wr_resp_queue.size()-1);
                            end
                            while(idx1==idx2);
                            tmp_item = rd_wr_resp_queue[idx1];
                            rd_wr_resp_queue[idx1] = rd_wr_resp_queue[idx2];
                            rd_wr_resp_queue[idx2] = tmp_item;
                        end
                    end
                    while(rd_wr_resp_queue.size != 0) begin
                        queue_item = rd_wr_resp_queue.pop_front();
                        tx_item = queue_item.tx_trans;
                        mgr_output_trans_port.write(tx_item);
                    end
                end
                else
                    reorder_timer++;
            end
            //wait delay cycle and send
            else begin
                while(rd_wr_resp_queue.size != 0) begin
                    if(rd_wr_resp_queue[0].timer >= cfg_obj.resp_delay_cycle) begin
                        queue_item = rd_wr_resp_queue.pop_front();
                        tx_item = queue_item.tx_trans;
                        mgr_output_trans_port.write(tx_item);
                    end
                    else begin
                        for(int i=0; i<rd_wr_resp_queue.size; i++) begin
                            rd_wr_resp_queue[i].timer++;
                        end
                        break;
                    end
                end
            end
        end
    endtask: try_to_send_rd_wr_resp

// *********************************************************************
    //Get the trans from tx monitor
    function void write_tx_mon(tl_tx_trans tx_trans);
        tl_tx_trans     tx_item;
        tx_cmd_trans    tx_cmd_item;
        rx_cmd_trans    rx_cmd_item;
        tag_entry       capp_tag_item;
        retry_entry     retry_item;
        tx_timer_trans  back_off_item;
        xlate_resp_code xlate_code;
        cov_capp_tag_reuse_en = 1'b0;

        $cast(tx_item,tx_trans.clone());
        //if it is TL command
        if(tx_item.is_cmd) begin
            if((tx_item.packet_type != tl_tx_trans::NOP) && (tx_item.packet_type != tl_tx_trans::INTRP_RDY) && (tx_item.packet_type != tl_tx_trans::XLATE_DONE)) begin
                //collect RAW,WAW,WAR info
                cov_second_packet = cov_first_packet;
                cov_second_dlength = cov_first_dlength;
                cov_second_addr = cov_first_addr;
                cov_first_packet = tx_item.packet_type;
                cov_first_dlength = tx_item.dlength;
                cov_first_addr = tx_item.physical_addr;
                if(coverage_on && ((cov_first_packet==tl_tx_trans::WRITE_MEM) || (cov_first_packet==tl_tx_trans::RD_MEM)) &&
                   ((cov_second_packet==tl_tx_trans::WRITE_MEM) || (cov_second_packet==tl_tx_trans::RD_MEM)) &&
                   (cov_first_dlength==cov_second_dlength) && (cov_first_addr==cov_second_addr)) begin
                    c_mem_access_seq.sample();
                end
                //check CAPPTag and push into the queue
                if(tx_cmd_queue.exists(tx_item.capp_tag))
                    `uvm_error(get_type_name(),$psprintf("TX send TL command CAPPTag is still in use, the CAPPTag=0x%x", tx_item.capp_tag))
                else begin
                    if(tx_item.packet_type != tl_tx_trans::RD_PF) begin
                        tx_cmd_item = new("tx_cmd_item");
                        tx_cmd_item.tx_cmd_item = tx_item;
                        tx_cmd_item.cur_dLength = parse_dLength(tx_item.dlength);
                        tx_cmd_queue[tx_item.capp_tag] = tx_cmd_item;
                        `uvm_info(get_type_name(),$psprintf("TX cmd queue push item, the CAPPTag=0x%x, cmd:%s", tx_item.capp_tag, tx_item.packet_type.name()), UVM_MEDIUM)
                    end
                end
                //update retry info queue
                if(retry_tx_info_queue.exists(tx_item.capp_tag) && (tx_item.packet_type == retry_tx_info_queue[tx_item.capp_tag].tx_packet)) begin
                    retry_tx_info_queue[tx_item.capp_tag].retry_num++;
                end
                //check CAPPTag queue and update 
                if(capp_tag_queue.exists(tx_item.capp_tag)) begin
                    capp_tag_queue[tx_item.capp_tag].reused = 1'b1;
                    capp_tag_queue[tx_item.capp_tag].start_time = tx_item.time_stamp;
                    cov_capp_tag_reuse_en = 1'b1;
                    cov_capp_tag_reuse = tx_item.capp_tag;
                end
                else begin
                    capp_tag_item = new("capp_tag_item");
                    capp_tag_item.start_time = tx_item.time_stamp;
                    capp_tag_queue[tx_item.capp_tag] = capp_tag_item;
                end
                if(coverage_on)
                    c_tag_reuse.sample();
            end
        end
        //if it is TL response
        else begin
            int resp_dL = 0;
            rx_cmd_item = new("rx_cmd_item");
            case(tx_item.packet_type)
                tl_tx_trans::RETURN_TLX_CREDITS: begin
                    decrease_tlx_credits(0, 0, tx_item.tlx_vc_0);
                    decrease_tlx_credits(0, 3, tx_item.tlx_vc_3);
                    decrease_tlx_credits(1, 0, tx_item.tlx_dcp_0);
                    decrease_tlx_credits(1, 3, tx_item.tlx_dcp_3);
                    if(coverage_on)
                        c_tlx_credits.sample();
                end
                tl_tx_trans::INTRP_RESP: begin
                    if(rx_cmd_queue.exists(tx_item.afu_tag)) begin
                        rx_cmd_queue.delete(tx_item.afu_tag);
                        `uvm_info(get_type_name(),$psprintf("TX send an interrupt response, AFUTag=0x%x, resp_code=0x%x", tx_item.afu_tag, tx_item.resp_code), UVM_MEDIUM)
                    end
                    else begin
                        if(!cfg_obj.intrp_resp_bad_afutag_enable)
                            `uvm_error(get_type_name(),$psprintf("TX send an interrupt response without correlative command, AFUTag=0x%x", tx_item.afu_tag))
                    end
                    //update AFUTag queue
                    if(afu_tag_queue.exists(tx_item.afu_tag)) begin
                        afu_tag_queue[tx_item.afu_tag].finish_time = tx_item.time_stamp;
                    end
                    //update retry info queue
                    if(tx_item.resp_code == 4'b0010) begin
                        if(!retry_rx_info_queue.exists(tx_item.afu_tag)) begin
                            retry_item = new("retry_item");
                            retry_item.rx_packet = tl_rx_trans::INTRP_REQ;
                            retry_rx_info_queue[tx_item.afu_tag] = retry_item;
                        end
                    end
                end
                //TODO: coverage
                tl_tx_trans::WRITE_RESPONSE, tl_tx_trans::WRITE_FAILED: begin
                    if(rx_cmd_queue.exists(tx_item.afu_tag)) begin
                        `uvm_info(get_type_name(),$psprintf("TX send a mem write response, AFUTag=0x%x, dL=%b, dP=%b, resp_code=0x%x", tx_item.afu_tag, tx_item.dlength, tx_item.dpart, tx_item.resp_code), UVM_MEDIUM)
                        rx_cmd_item = rx_cmd_queue[tx_item.afu_tag];
                        //WRITE_FAILED for XLATE_PENDING, generate XLATE_DONE
                        if((tx_item.packet_type == tl_tx_trans::WRITE_FAILED) && (tx_item.resp_code == 4'b0100)) begin
                            xlate_code = new();
                            xlate_code.w_cmp = cfg_obj.xlate_done_cmp_weight;
                            xlate_code.w_rty = cfg_obj.xlate_done_rty_weight;
                            xlate_code.w_aerror = cfg_obj.xlate_done_aerror_weight;
                            xlate_code.w_reserved = cfg_obj.xlate_done_reserved_weight;
                            assert(xlate_code.randomize());
                            back_off_item = new("back_off_item");
                            back_off_item.tx_trans.packet_type = tl_tx_trans::XLATE_DONE;
                            back_off_item.tx_trans.afu_tag = tx_item.afu_tag;
                            back_off_item.tx_trans.resp_code = xlate_code.code;
                            tx_back_off_queue.push_back(back_off_item);
                        end
                        //DMA_W cmd can have multiple resp
                        if(rx_cmd_item.rx_cmd_item.packet_type == tl_rx_trans::DMA_W) begin
                            resp_dL = parse_dLength(tx_item.dlength);
                            //all resp is received
                            if(resp_dL == rx_cmd_item.cur_dLength) begin
                                rx_cmd_queue.delete(tx_item.afu_tag);
                            end
                            //one of the multiple resp
                            else if(resp_dL < rx_cmd_item.cur_dLength) begin
                                rx_cmd_item.cur_dLength -= resp_dL;
                                rx_cmd_queue[tx_item.afu_tag] = rx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"TX send resp dL overflow")
                            end
                        end
                        //DMA_PR_W
                        else if((rx_cmd_item.rx_cmd_item.packet_type == tl_rx_trans::DMA_PR_W) || (rx_cmd_item.rx_cmd_item.packet_type == tl_rx_trans::DMA_W_BE)) begin
                            if((tx_item.dlength != 2'b01) || (tx_item.dpart != 0)) begin
                                `uvm_error(get_type_name(),$psprintf("TX send resp:%s with illegal dL/dP, AFUTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0", 
                                                                    tx_item.packet_type.name(), tx_item.afu_tag, tx_item.dlength, tx_item.dpart))
                            end
                            rx_cmd_queue.delete(tx_item.afu_tag);
                        end
                        else
                            `uvm_error(get_type_name(),$psprintf("TX send a mem write response without write cmd received, AFUTag=0x%x", tx_item.afu_tag))
                    end
                    else
                        `uvm_error(get_type_name(),$psprintf("TX send a mem write response without correlative command, AFUTag=0x%x", tx_item.afu_tag))
                end
                //TODO: coverage
                tl_tx_trans::READ_RESPONSE, tl_tx_trans::READ_FAILED: begin
                    if(rx_cmd_queue.exists(tx_item.afu_tag)) begin
                        `uvm_info(get_type_name(),$psprintf("TX send a mem read response, AFUTag=0x%x, dL=%b, dP=%b, resp_code=0x%x", tx_item.afu_tag, tx_item.dlength, tx_item.dpart, tx_item.resp_code), UVM_MEDIUM)
                        rx_cmd_item = rx_cmd_queue[tx_item.afu_tag];
                        //WRITE_FAILED for XLATE_PENDING, generate XLATE_DONE
                        if((tx_item.packet_type == tl_tx_trans::READ_FAILED) && (tx_item.resp_code == 4'b0100)) begin
                            xlate_code = new();
                            xlate_code.w_cmp = cfg_obj.xlate_done_cmp_weight;
                            xlate_code.w_rty = cfg_obj.xlate_done_rty_weight;
                            xlate_code.w_aerror = cfg_obj.xlate_done_aerror_weight;
                            xlate_code.w_reserved = cfg_obj.xlate_done_reserved_weight;
                            assert(xlate_code.randomize());
                            back_off_item = new("back_off_item");
                            back_off_item.tx_trans.packet_type = tl_tx_trans::XLATE_DONE;
                            back_off_item.tx_trans.afu_tag = tx_item.afu_tag;
                            back_off_item.tx_trans.resp_code = xlate_code.code;
                            tx_back_off_queue.push_back(back_off_item);
                        end
                        //RD_WNITC cmd can have multiple resp
                        if(rx_cmd_item.rx_cmd_item.packet_type == tl_rx_trans::RD_WNITC) begin
                            resp_dL = parse_dLength(tx_item.dlength);
                            //all resp is received
                            if(resp_dL == rx_cmd_item.cur_dLength) begin
                                rx_cmd_queue.delete(tx_item.afu_tag);
                            end
                            //one of the multiple resp
                            else if(resp_dL < rx_cmd_item.cur_dLength) begin
                                rx_cmd_item.cur_dLength -= resp_dL;
                                rx_cmd_queue[tx_item.afu_tag] = rx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"TX send resp dL overflow")
                            end
                        end
                        //PR_RD_WNITC
                        else if(rx_cmd_item.rx_cmd_item.packet_type == tl_rx_trans::PR_RD_WNITC) begin
                            if((tx_item.dlength != 2'b01) || (tx_item.dpart != 0)) begin
                                `uvm_error(get_type_name(),$psprintf("TX send resp:%s with illegal dL/dP, AFUTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0", 
                                                                    tx_item.packet_type.name(), tx_item.afu_tag, tx_item.dlength, tx_item.dpart))
                            end
                            rx_cmd_queue.delete(tx_item.afu_tag);
                        end
                        else
                            `uvm_error(get_type_name(),$psprintf("TX send a mem read response without read cmd received, AFUTag=0x%x", tx_item.afu_tag))
                    end
                    else
                        `uvm_error(get_type_name(),$psprintf("TX send a mem read response without correlative command, AFUTag=0x%x", tx_item.afu_tag))
                end
                tl_tx_trans::NOP: begin
                    //do nothing
                end
                default: begin
                    `uvm_error(get_type_name(),$psprintf("TX send unsupported packet, the type =0x%x", tx_item.packet_type))
                end
            endcase
        end
    endfunction: write_tx_mon

    //Get the trans from rx monitor
    function void write_rx_mon(tl_rx_trans rx_trans);
        tl_rx_trans     rx_item;
        tl_tx_trans     tx_item;
        tx_timer_trans  back_off_item;
        tx_cmd_trans    tx_cmd_item;
        rx_cmd_trans    rx_cmd_item;
        tag_entry       afu_tag_item;
        retry_entry     retry_item;
        int             TLx_vc0 = 0;
        int             TLx_vc3 = 0;
        int             TLx_dcp0 = 0;
        int             TLx_dcp3 = 0;
        cov_afu_tag_reuse_en = 1'b0;

        tx_item = new("tx_item");
        $cast(rx_item,rx_trans.clone());
        //if it is TLx commands
        if(rx_item.is_cmd) begin
            rx_cmd_item = new("rx_cmd_item");
            case(rx_item.packet_type)
                tl_rx_trans::ASSIGN_ACTAG: begin
                    write_actag_table(rx_item.acTag, rx_item.BDF, rx_item.PASID);
                end
                tl_rx_trans::INTRP_REQ, tl_rx_trans::INTRP_REQ_D: begin
                    `uvm_info(get_type_name(),$psprintf("RX received an interrupt request, type=%s, AFUTag=0x%x, stream_id=%d, cmd_flag=%d, pL=%d, obj_handle=0x%x", 
                                                        rx_item.packet_type.name(), rx_item.AFUTag, rx_item.stream_id, rx_item.cmd_flag, rx_item.pL, rx_item.obj_handle), UVM_MEDIUM)
                    //update retry info queue
                    if(retry_rx_info_queue.exists(rx_item.AFUTag) && (rx_item.packet_type == retry_rx_info_queue[rx_item.AFUTag].rx_packet)) begin
                        retry_rx_info_queue[rx_item.AFUTag].retry_num++;
                    end
                    read_actag_table(rx_item.acTag);
                    //check AFUTag and push into the queue
                    if(rx_cmd_queue.exists(rx_item.AFUTag))
                        `uvm_error(get_type_name(),$psprintf("RX received TLx command AFUTag is still in use, the AFUTag=0x%x", rx_item.AFUTag))
                    else
                        rx_cmd_item.rx_cmd_item = rx_item;
                        rx_cmd_queue[rx_item.AFUTag] = rx_cmd_item;
                    //check AFUTag queue and update 
                    if(afu_tag_queue.exists(rx_item.AFUTag)) begin
                        afu_tag_queue[rx_item.AFUTag].reused = 1'b1;
                        afu_tag_queue[rx_item.AFUTag].start_time = rx_item.time_stamp;
                        cov_afu_tag_reuse_en = 1'b1;
                        cov_afu_tag_reuse = rx_item.AFUTag;
                    end
                    else begin
                        afu_tag_item = new("afu_tag_item");
                        afu_tag_item.start_time = rx_item.time_stamp;
                        afu_tag_queue[rx_item.AFUTag] = afu_tag_item;
                    end
                    if(coverage_on)
                        c_tag_reuse.sample();

                    void'(interrupt_handler(rx_item));
                end
                tl_rx_trans::DMA_W, tl_rx_trans::DMA_W_BE, tl_rx_trans::DMA_PR_W: begin
                    //TODO: coverage
                    if(cfg_obj.ocapi_version==tl_cfg_obj::OPENCAPI_3_1)
                        `uvm_error(get_type_name(),$psprintf("RX received unsupported packet for OpenCAPI3.1, the type =%s", rx_item.packet_type.name()))
                    else begin
                        `uvm_info(get_type_name(),$psprintf("RX received a memory write cmd, type=%s, AFUTag=0x%X, addr=0x%X, dL=%b, pL=%b, acTag=0x%X, byte_enable=0x%016X", 
                                                            rx_item.packet_type.name(), rx_item.AFUTag, rx_item.Eaddr, rx_item.dL, rx_item.pL, rx_item.acTag, rx_item.byte_enable), UVM_MEDIUM)
                        //check AFUTag and push into the queue
                        if(rx_cmd_queue.exists(rx_item.AFUTag))
                            `uvm_error(get_type_name(),$psprintf("RX received TLx command AFUTag is still in use, the AFUTag=0x%x", rx_item.AFUTag))
                        else begin
                            rx_cmd_item.rx_cmd_item = rx_item;
                            rx_cmd_item.cur_dLength = parse_dLength(rx_item.dL);
                            rx_cmd_queue[rx_item.AFUTag] = rx_cmd_item;
                        end

                        if(!check_cmd_length_addr_and_gen_fail_resp(rx_item)) begin
                            read_actag_table(rx_item.acTag);
                            generate_write_resp_and_write_mem(rx_item);
                        end
                    end
                end
                tl_rx_trans::RD_WNITC, tl_rx_trans::PR_RD_WNITC: begin
                    //TODO: coverage
                    if(cfg_obj.ocapi_version==tl_cfg_obj::OPENCAPI_3_1)
                        `uvm_error(get_type_name(),$psprintf("RX received unsupported packet for OpenCAPI3.1, the type =%s", rx_item.packet_type.name()))
                    else begin
                        `uvm_info(get_type_name(),$psprintf("RX received a memory read cmd, type=%s, AFUTag=0x%X, addr=0x%X, dL=%b, pL=%b, acTag=0x%X", 
                                                            rx_item.packet_type.name(), rx_item.AFUTag, rx_item.Eaddr, rx_item.dL, rx_item.pL, rx_item.acTag), UVM_MEDIUM)
                        //check AFUTag and push into the queue
                        if(rx_cmd_queue.exists(rx_item.AFUTag))
                            `uvm_error(get_type_name(),$psprintf("RX received TLx command AFUTag is still in use, the AFUTag=0x%x", rx_item.AFUTag))
                        else begin
                            rx_cmd_item.rx_cmd_item = rx_item;
                            rx_cmd_item.cur_dLength = parse_dLength(rx_item.dL);
                            rx_cmd_queue[rx_item.AFUTag] = rx_cmd_item;
                        end

                        if(!check_cmd_length_addr_and_gen_fail_resp(rx_item)) begin
                            read_actag_table(rx_item.acTag);
                            generate_read_resp_and_read_mem(rx_item);
                        end
                    end                     
                end
                tl_rx_trans::NOP_R: begin
                    //do nothing
                end
                default: begin
                    `uvm_error(get_type_name(),$psprintf("RX received unsupported packet, the type =%s", rx_item.packet_type.name()))
                end
            endcase
        end
        //if it is TLx response
        else begin
            int resp_dL = 0;
            tx_cmd_item = new("tx_cmd_item");
            case(rx_item.packet_type)
                tl_rx_trans::RETURN_TL_CREDITS: begin
                    return_tl_credits(0, 0, rx_item.TL_vc0);
                    return_tl_credits(0, 1, rx_item.TL_vc1);
                    return_tl_credits(1, 0, rx_item.TL_dcp0);
                    return_tl_credits(1, 1, rx_item.TL_dcp1);
                end
                tl_rx_trans::MEM_RD_RESPONSE: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_info(get_type_name(),$psprintf("RX received resp:%s, CAPPTag=0x%x, dL=%b, dP=%b", 
                                                            rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP), UVM_MEDIUM)
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        tx_cmd_item = tx_cmd_queue[rx_item.CAPPTag];
                        //rd_mem cmd can have multiple resp
                        if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::RD_MEM) begin
                            resp_dL = parse_dLength(rx_item.dL);
                            //all resp is received
                            if(resp_dL == tx_cmd_item.cur_dLength) begin
                                //rty_req
                                if(tx_cmd_item.resp_fail_rty) begin
                                    back_off_item = new("back_off_item");
                                    back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                    tx_back_off_queue.push_back(back_off_item);
                                end
                                cov_rd_resp_num = tx_cmd_item.resp_num;
                                if(coverage_on)
                                    c_resp_num.sample();
                                cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                tx_cmd_queue.delete(rx_item.CAPPTag);
                                //update CAPPTag queue
                                if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                    capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                    cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                                end
                                if(coverage_on)
                                    c_cmd_latency.sample();
                            end
                            //one of the multiple resp
                            else if(resp_dL < tx_cmd_item.cur_dLength) begin
                                tx_cmd_item.cur_dLength -= resp_dL;
                                tx_cmd_queue[rx_item.CAPPTag] = tx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"RX received resp dL overflow")
                            end
                        end
                        //pr_rd_mem and config_read
                        else begin
                            //dL and dP shall be 64 bytes and offset at 0
                            if((rx_item.dL != 2'b01) || (rx_item.dP != 0)) begin
                                `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0",
                                                                     rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                            end
                            cov_rd_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //delete intrp handle queue if needed
                            if(intrp_handle_queue.exists(rx_item.CAPPTag)) begin
                                intrp_handle_queue.delete(rx_item.CAPPTag);
                            end
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_RD_RESPONSE_OW: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_info(get_type_name(),$psprintf("RX received resp:%s, CAPPTag=0x%x, dP=%b", 
                                                            rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dP), UVM_MEDIUM)
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        tx_cmd_item = tx_cmd_queue[rx_item.CAPPTag];
                        //rd_mem cmd can have multiple resp
                        if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::RD_MEM) begin
                            resp_dL = 32;
                            //all resp is received
                            if(resp_dL == tx_cmd_item.cur_dLength) begin
                                //rty_req
                                if(tx_cmd_item.resp_fail_rty) begin
                                    back_off_item = new("back_off_item");
                                    back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                    tx_back_off_queue.push_back(back_off_item);
                                end
                                cov_rd_resp_num = tx_cmd_item.resp_num;
                                if(coverage_on)
                                    c_resp_num.sample();
                                cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                tx_cmd_queue.delete(rx_item.CAPPTag);
                                //update CAPPTag queue
                                if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                    capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                    cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                                end
                                if(coverage_on)
                                    c_cmd_latency.sample();
                            end
                            //one of the multiple resp
                            else if(resp_dL < tx_cmd_item.cur_dLength) begin
                                tx_cmd_item.cur_dLength -= resp_dL;
                                tx_cmd_queue[rx_item.CAPPTag] = tx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"RX received resp dL overflow")
                            end
                        end
                        //config_read
                        else if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::CONFIG_READ) begin
                            cov_rd_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                        //pr_rd_mem
                        else begin
                            //dP shall be offset at 0
                            if(rx_item.dP != 0) begin
                                `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dP, CAPPTag=0x%x, dP=%b, expected dP=0",
                                                                     rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dP))
                            end
                            cov_rd_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //delete intrp handle queue if needed
                            if(intrp_handle_queue.exists(rx_item.CAPPTag)) begin
                                intrp_handle_queue.delete(rx_item.CAPPTag);
                            end
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_RD_RESPONSE_XW: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_info(get_type_name(),$psprintf("RX received resp:%s, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag), UVM_MEDIUM)
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        cov_rd_resp_num = tx_cmd_queue[rx_item.CAPPTag].resp_num;
                        if(coverage_on)
                            c_resp_num.sample();
                        cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                        tx_cmd_queue.delete(rx_item.CAPPTag);
                        //delete intrp handle queue if needed
                        if(intrp_handle_queue.exists(rx_item.CAPPTag)) begin
                            intrp_handle_queue.delete(rx_item.CAPPTag);
                        end
                        //update CAPPTag queue
                        if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                            capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                            cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                        end
                        if(coverage_on)
                            c_cmd_latency.sample();
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_RD_FAIL: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_warning(get_type_name(),$psprintf("RX received fail resp:%s, CAPPTag=0x%x, dL=%b, dP=%b, resp_code=0x%x", 
                                                               rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP, rx_item.resp_code))
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        tx_cmd_item = tx_cmd_queue[rx_item.CAPPTag];
                        //mark as rty_req
                        if(rx_item.resp_code == 4'b0010) begin
                            tx_cmd_item.resp_fail_rty = 1;
                            //update retry info queue
                            if(!retry_tx_info_queue.exists(rx_item.CAPPTag)) begin
                                retry_item = new("retry_item");
                                retry_item.tx_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                retry_tx_info_queue[rx_item.CAPPTag] = retry_item;
                            end
                        end
                        //rd_mem cmd can have multiple resp
                        if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::RD_MEM) begin
                            resp_dL = parse_dLength(rx_item.dL);
                            //all resp is received
                            if(resp_dL == tx_cmd_item.cur_dLength) begin
                                //rty_req
                                if(tx_cmd_item.resp_fail_rty) begin
                                    back_off_item = new("back_off_item");
                                    back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                    tx_back_off_queue.push_back(back_off_item);
                                end
                                cov_rd_resp_num = tx_cmd_item.resp_num;
                                if(coverage_on)
                                    c_resp_num.sample();
                                cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                tx_cmd_queue.delete(rx_item.CAPPTag);
                                //update CAPPTag queue
                                if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                    capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                    cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                                end
                                if(coverage_on)
                                    c_cmd_latency.sample();
                            end
                            //one of the multiple resp
                            else if(resp_dL < tx_cmd_item.cur_dLength) begin
                                tx_cmd_item.cur_dLength -= resp_dL;
                                tx_cmd_queue[rx_item.CAPPTag] = tx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"RX received resp dL overflow")
                            end
                        end
                        //pr_rd_mem and config_read
                        else begin
                            //dL and dP shall be 64 bytes and offset at 0
                            if((rx_item.dL != 2'b01) || (rx_item.dP != 0)) begin
                                `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0",
                                                                     rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                            end
                            //rty_req
                            if(tx_cmd_item.resp_fail_rty) begin
                                back_off_item = new("back_off_item");
                                back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                tx_back_off_queue.push_back(back_off_item);
                            end
                            cov_rd_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_WR_RESPONSE: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_info(get_type_name(),$psprintf("RX received resp:%s, CAPPTag=0x%x, dL=%b, dP=%b", 
                                                            rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP), UVM_MEDIUM)
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        tx_cmd_item = tx_cmd_queue[rx_item.CAPPTag];
                        //wr_mem cmd can have multiple resp
                        if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::WRITE_MEM) begin
                            resp_dL = parse_dLength(rx_item.dL);
                            //all resp is received
                            if(resp_dL == tx_cmd_item.cur_dLength) begin
                                //rty_req
                                if(tx_cmd_item.resp_fail_rty) begin
                                    back_off_item = new("back_off_item");
                                    back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                    tx_back_off_queue.push_back(back_off_item);
                                end
                                cov_wr_resp_num = tx_cmd_item.resp_num;
                                if(coverage_on)
                                    c_resp_num.sample();
                                cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                tx_cmd_queue.delete(rx_item.CAPPTag);
                                //update CAPPTag queue
                                if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                    capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                    cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                                end
                                if(coverage_on)
                                    c_cmd_latency.sample();
                            end
                            //one of the multiple resp
                            else if(resp_dL < tx_cmd_item.cur_dLength) begin
                                tx_cmd_item.cur_dLength -= resp_dL;
                                tx_cmd_queue[rx_item.CAPPTag] = tx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"RX received resp dL overflow")
                            end
                        end
                        //pr_wr_mem, write_mem.be, config_write, pad_mem
                        else begin
                            //PAD_MEM: dL and dP shall be 32 bytes and offset at 0
                            if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::PAD_MEM) begin
                                if((rx_item.dL != 2'b00) || (rx_item.dP != 0))
                                    `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b00, dP=0",
                                                                         rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                                
                            end
                            //dL and dP shall be 64 bytes and offset at 0
                            else begin
                                if((rx_item.dL != 2'b01) || (rx_item.dP != 0))
                                    `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0",
                                                                         rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                            end
                            cov_wr_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //delete intrp handle queue if needed
                            if(intrp_handle_queue.exists(rx_item.CAPPTag)) begin
                                intrp_handle_queue.delete(rx_item.CAPPTag);
                            end
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_WR_FAIL: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_warning(get_type_name(),$psprintf("RX received fail resp:%s, CAPPTag=0x%x, dL=%b, dP=%b, resp_code=0x%x", 
                                                               rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP, rx_item.resp_code))
                        tx_cmd_queue[rx_item.CAPPTag].resp_num++;
                        tx_cmd_item = tx_cmd_queue[rx_item.CAPPTag];
                        //mark as rty_req
                        if(rx_item.resp_code == 4'b0010) begin
                            tx_cmd_item.resp_fail_rty = 1;
                            //update retry info queue
                            if(!retry_tx_info_queue.exists(rx_item.CAPPTag)) begin
                                retry_item = new("retry_item");
                                retry_item.tx_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                retry_tx_info_queue[rx_item.CAPPTag] = retry_item;
                            end
                        end
                        //wr_mem cmd can have multiple resp
                        if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::WRITE_MEM) begin
                            resp_dL = parse_dLength(rx_item.dL);
                            //all resp is received
                            if(resp_dL == tx_cmd_item.cur_dLength) begin
                                //rty_req
                                if(tx_cmd_item.resp_fail_rty) begin
                                    back_off_item = new("back_off_item");
                                    back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                    tx_back_off_queue.push_back(back_off_item);
                                end
                                cov_wr_resp_num = tx_cmd_item.resp_num;
                                if(coverage_on)
                                    c_resp_num.sample();
                                cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                                tx_cmd_queue.delete(rx_item.CAPPTag);
                                //update CAPPTag queue
                                if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                    capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                    cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                                end
                                if(coverage_on)
                                    c_cmd_latency.sample();
                            end
                            //one of the multiple resp
                            else if(resp_dL < tx_cmd_item.cur_dLength) begin
                                tx_cmd_item.cur_dLength -= resp_dL;
                                tx_cmd_queue[rx_item.CAPPTag] = tx_cmd_item;
                            end
                            //dLength overflow
                            else begin
                                `uvm_error(get_type_name(),"RX received resp dL overflow")
                            end
                        end
                        //pr_wr_mem, write_mem.be, config_write, pad_mem
                        else begin
                            //PAD_MEM: don't check dL and dP for fail response
                            if(tx_cmd_item.tx_cmd_item.packet_type == tl_tx_trans::PAD_MEM) begin
                                //if((rx_item.dL != 2'b00) || (rx_item.dP != 0))
                                //    `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b00, dP=0",
                                //                                         rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                                //
                            end
                            //dL and dP shall be 64 bytes and offset at 0
                            else begin
                                if((rx_item.dL != 2'b01) || (rx_item.dP != 0))
                                    `uvm_error(get_type_name(),$psprintf("RX received resp:%s with illegal dL/dP, CAPPTag=0x%x, dL=%b, dP=%b, expected dL=2'b01, dP=0",
                                                                         rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.dL, rx_item.dP))
                            end
                            //rty_req
                            if(tx_cmd_item.resp_fail_rty) begin
                                back_off_item = new("back_off_item");
                                back_off_item.tx_trans = tx_cmd_item.tx_cmd_item;
                                tx_back_off_queue.push_back(back_off_item);
                            end
                            cov_wr_resp_num = tx_cmd_item.resp_num;
                            if(coverage_on)
                                c_resp_num.sample();
                            cov_latency_packet = tx_cmd_item.tx_cmd_item.packet_type;
                            tx_cmd_queue.delete(rx_item.CAPPTag);
                            //update CAPPTag queue
                            if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                                capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                                cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                            end
                            if(coverage_on)
                                c_cmd_latency.sample();
                        end
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::MEM_CNTL_DONE: begin
                    if(tx_cmd_queue.exists(rx_item.CAPPTag)) begin
                        `uvm_info(get_type_name(),$psprintf("RX received resp:%s, CAPPTag=0x%x, resp_code=0x%x", 
                                                            rx_item.packet_type.name(), rx_item.CAPPTag, rx_item.resp_code), UVM_MEDIUM)
                        if(rx_item.resp_code == 4'b0000) begin
                            `uvm_info(get_type_name(),"MEM_CNTL_DONE Resp Complete", UVM_MEDIUM)
                        end
                        else if(rx_item.resp_code == 4'b1110) begin
                            `uvm_warning(get_type_name(),"MEM_CNTL_DONE Resp Failed")
                        end
                        else begin
                            `uvm_warning(get_type_name(),"MEM_CNTL_DONE Resp Reserved")
                        end
                        cov_latency_packet = tl_tx_trans::MEM_CNTL;
                        tx_cmd_queue.delete(rx_item.CAPPTag);
                        //update CAPPTag queue
                        if(capp_tag_queue.exists(rx_item.CAPPTag)) begin
                            capp_tag_queue[rx_item.CAPPTag].finish_time = rx_item.time_stamp;
                            cov_latency_in_cycle = calc_latency(capp_tag_queue[rx_item.CAPPTag].start_time, capp_tag_queue[rx_item.CAPPTag].finish_time);
                        end
                        if(coverage_on)
                            c_cmd_latency.sample();
                    end
                    else begin
                        `uvm_error(get_type_name(),$psprintf("RX received resp:%s without correlative command, CAPPTag=0x%x", rx_item.packet_type.name(), rx_item.CAPPTag))
                    end
                end
                tl_rx_trans::NOP_R: begin
                    //do nothing
                end
                default: begin
                    `uvm_error(get_type_name(),$psprintf("RX received unsupported packet, the type =0x%x", rx_item.packet_type))
                end
            endcase
        end
        //calc the TLx credits the trans consumed, generate return_tlx_credits to driver
        if((rx_item.packet_type==tl_rx_trans::MEM_RD_FAIL) || (rx_item.packet_type==tl_rx_trans::MEM_WR_FAIL)
         ||(rx_item.packet_type==tl_rx_trans::MEM_WR_RESPONSE) || (rx_item.packet_type==tl_rx_trans::MEM_CNTL_DONE)) begin
            TLx_vc0 = 1;
        end
        else if((rx_item.packet_type==tl_rx_trans::ASSIGN_ACTAG) || (rx_item.packet_type==tl_rx_trans::INTRP_REQ)
             || (rx_item.packet_type==tl_rx_trans::RD_WNITC) || (rx_item.packet_type==tl_rx_trans::PR_RD_WNITC)
             || (rx_item.packet_type==tl_rx_trans::WAKE_HOST_THREAD) || (rx_item.packet_type==tl_rx_trans::XLATE_TOUCH)) begin
            TLx_vc3 = 1;
        end
        else if((rx_item.packet_type==tl_rx_trans::INTRP_REQ_D) || (rx_item.packet_type==tl_rx_trans::DMA_W_BE)
             || (rx_item.packet_type==tl_rx_trans::DMA_PR_W)) begin
            TLx_vc3 = 1;
            TLx_dcp3 = 1;
        end
        else if(rx_item.packet_type==tl_rx_trans::DMA_W) begin
            TLx_vc3 = 1;
            if((rx_item.dL==2'b00) || (rx_item.dL==2'b01))
                TLx_dcp3 = 1;
            else if(rx_item.dL==2'b10)
                TLx_dcp3 = 2;
            else if(rx_item.dL==2'b11)
                TLx_dcp3 = 4;
        end
        else if(rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE) begin
            TLx_vc0 = 1;
            if((rx_item.dL==2'b00) || (rx_item.dL==2'b01))
                TLx_dcp0 = 1;
            else if(rx_item.dL==2'b10)
                TLx_dcp0 = 2;
            else if(rx_item.dL==2'b11)
                TLx_dcp0 = 4;
        end
        else if((rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_OW) || (rx_item.packet_type==tl_rx_trans::MEM_RD_RESPONSE_XW)) begin
            TLx_vc0 = 1;
            TLx_dcp0 = 1;
        end
        cov_rx_packet_type = rx_item.packet_type;
        if(coverage_on)
            c_rx_packet_credits.sample();
        //send return_tlx_credits to driver
        if((TLx_vc0!=0) || (TLx_vc3!=0) || (TLx_dcp0!=0) || (TLx_dcp3!=0)) begin
            tx_item.packet_type = tl_tx_trans::RETURN_TLX_CREDITS;
            tx_item.is_cmd = 0;
            tx_item.tlx_vc_0 = TLx_vc0;
            tx_item.tlx_vc_3 = TLx_vc3;
            tx_item.tlx_dcp_0 = TLx_dcp0;
            tx_item.tlx_dcp_3 = TLx_dcp3;
            //update TLx credits
            increase_tlx_credits(0, 0, TLx_vc0);
            increase_tlx_credits(0, 3, TLx_vc3);
            increase_tlx_credits(1, 0, TLx_dcp0);
            increase_tlx_credits(1, 3, TLx_dcp3);
            if(coverage_on)
                c_tlx_credits.sample();
            `uvm_info(get_type_name(),$psprintf("send return_tlx_credits vc0=%d, vc3=%d, dcp0=%d, dcp3=%d to driver", TLx_vc0, TLx_vc3, TLx_dcp0, TLx_dcp3), UVM_MEDIUM)
            mgr_output_trans_port.write(tx_item);
        end
    endfunction: write_rx_mon

    //Get dl credit trans from rx monitor
    function void write_dl_credit(dl_credit_trans credit_trans);
        dl_credit_trans credit_item;

        $cast(credit_item,credit_trans.clone());
        //unit sim, send the credit trans to driver directly
        if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin
            `uvm_info(get_type_name(),$psprintf("send return_dl_credits dl=%d to driver", credit_item.return_credit), UVM_MEDIUM)
            mgr_output_credit_port.write(credit_item);
        end
        //chip sim, add DL credits
        else begin
            return_dl_credits(credit_item.return_credit);
        end
    endfunction: write_dl_credit

// *********************************************************************
    //Reset the VC and data credits pools
    function void credits_reset();
        for(int i=0; i<4; i++) begin
            tl_vc_credits[i] = 0;
            tl_data_credits[i] = 0;
            tlx_vc_credits[i] = 0;
            tlx_data_credits[i] = 0;
        end
        dl_credits = 0;
    endfunction: credits_reset

    //Initial the VC and data credits pools
    function void credits_init();
        for(int i=0; i<4; i++) begin
            tlx_vc_credits[i] = cfg_obj.tlx_vc_credit_count[i];
            tlx_data_credits[i] = cfg_obj.tlx_data_credit_count[i];
        end
    endfunction: credits_init

// *********************************************************************
    //Write acTag table
    function void write_actag_table(input bit[11:0] acTag, input bit[15:0] bdf, input bit[19:0] pasid);
        acTag_entry acTag_item;

        //check acTag index, BDF and PASID are in the config range
        if((acTag < cfg_obj.actag_base) || (acTag >= (cfg_obj.actag_base + cfg_obj.actag_length)))
            `uvm_error(get_type_name(),$psprintf("acTag index is out of config range, index=%d, range is from %d to %d", 
                                                 acTag, cfg_obj.actag_base, (cfg_obj.actag_base + cfg_obj.actag_length - 1)))
        if(bdf != cfg_obj.bdf)
            `uvm_error(get_type_name(),$psprintf("bdf is not equal to config value, bdf=0x%x, config bdf=0x%x", bdf, cfg_obj.bdf))
        if((pasid < cfg_obj.pasid_base) || (pasid >= (cfg_obj.pasid_base + (20'h1 << cfg_obj.pasid_length))))
            `uvm_error(get_type_name(),$psprintf("pasid is out of config range, pasid=0x%x, range is from 0x%x to 0x%x",
                                                 pasid, cfg_obj.pasid_base, (cfg_obj.pasid_base + (20'h1 << cfg_obj.pasid_length) - 1)))

        acTag_item = new("acTag_item");
        acTag_item.valid = 1;
        acTag_item.bdf = bdf;
        acTag_item.pasid = pasid;
        acTag_table[acTag] = acTag_item;
        `uvm_info(get_type_name(),$psprintf("write acTag table entry index=%d, valid=1, bdf=0x%x, pasid=0x%x", acTag, bdf, pasid), UVM_MEDIUM)
    endfunction: write_actag_table

    //Read acTag table
    function void read_actag_table(input bit[11:0] acTag);
        acTag_entry acTag_item;

        //check acTag index is in the config range
        if((acTag < cfg_obj.actag_base) || (acTag >= (cfg_obj.actag_base + cfg_obj.actag_length)))
            `uvm_error(get_type_name(),$psprintf("acTag index is out of config range, index=%d, range is from %d to %d", 
                                                 acTag, cfg_obj.actag_base, (cfg_obj.actag_base + cfg_obj.actag_length - 1)))

        acTag_item = new("acTag_item");
        if(acTag_table.exists(acTag)) begin
            acTag_item = acTag_table[acTag];
            if(acTag_item.valid) begin
                `uvm_info(get_type_name(),$psprintf("read acTag table success, entry index=%d, valid=1, bdf=0x%x, pasid=0x%x", 
                                                    acTag, acTag_item.bdf, acTag_item.pasid), UVM_MEDIUM)
            end
            else begin
                `uvm_error(get_type_name(),$psprintf("read acTag table fail, entry index=%d, valid=0", acTag))
            end            
        end
    endfunction: read_actag_table

// *********************************************************************
    //Check TL credits number
    function bit has_tl_credits(input bit is_data, input int channel, input int number);
        if(coverage_on)
            c_tl_credits.sample();
        if(is_data)
            has_tl_credits = ((tl_data_credits[channel] - number) >= 0);
        else
            has_tl_credits = ((tl_vc_credits[channel] - number) >= 0);
    endfunction: has_tl_credits

    //Get TL credits
    function void get_tl_credits(input bit is_data, input int channel, input int number, input bit[7:0] packet_type);
        cov_tx_packet_type = tl_tx_trans::packet_type_enum'(packet_type);
        if(coverage_on)
            c_tx_packet_credits.sample();
        if(is_data)
            tl_data_credits[channel] -= number;
        else
            tl_vc_credits[channel] -= number;
    endfunction: get_tl_credits

    //Return TL credits
    function void return_tl_credits(input bit is_data, input int channel, input int number);
        if(is_data) begin
            if((tl_data_credits[channel] + number) > cfg_obj.tl_data_credit_count[channel])
                `uvm_error(get_type_name(), $psprintf("TL DCP credits %d overflow, max credits is %d, current credits is %d",
                                                      channel, cfg_obj.tl_data_credit_count[channel], tl_data_credits[channel] + number))
            else
                tl_data_credits[channel] += number;
        end
        else begin
            if((tl_vc_credits[channel] + number) > cfg_obj.tl_vc_credit_count[channel])
                `uvm_error(get_type_name(), $psprintf("TL VC credits %d overflow, max credits is %d, current credits is %d",
                                                      channel, cfg_obj.tl_vc_credit_count[channel], tl_vc_credits[channel] + number))
            else
                tl_vc_credits[channel] += number;
        end
    endfunction: return_tl_credits

// *********************************************************************
    //Decrease TLx credits
    function void decrease_tlx_credits(input bit is_data, input int channel, input int number);
        if(is_data) begin
            if((tlx_data_credits[channel] - number) >= 0)
                tlx_data_credits[channel] -= number;
            else
                `uvm_error(get_type_name(), $psprintf("TLx DCP credits %d underflow, current credits is %d",
                                                      channel, tlx_data_credits[channel] - number))
        end
        else begin
            if((tlx_vc_credits[channel] - number) >= 0)
                tlx_vc_credits[channel] -= number;
            else
                `uvm_error(get_type_name(), $psprintf("TLx VC credits %d underflow, current credits is %d",
                                                      channel, tlx_vc_credits[channel] - number))
        end
    endfunction: decrease_tlx_credits

    //Increase TLx credits
    function void increase_tlx_credits(input bit is_data, input int channel, input int number);
        if(is_data) begin
            if((tlx_data_credits[channel] + number) > cfg_obj.tlx_data_credit_count[channel])
                `uvm_error(get_type_name(), $psprintf("TLx DCP credits %d overflow, max credits is %d, current credits is %d",
                                                      channel, cfg_obj.tlx_data_credit_count[channel], tlx_data_credits[channel] + number))
            else
                tlx_data_credits[channel] += number;
        end
        else begin
            if((tlx_vc_credits[channel] + number) > cfg_obj.tlx_vc_credit_count[channel])
                `uvm_error(get_type_name(), $psprintf("TLx VC credits %d overflow, max credits is %d, current credits is %d",
                                                      channel, cfg_obj.tlx_vc_credit_count[channel], tlx_vc_credits[channel] + number))
            else
                tlx_vc_credits[channel] += number;
        end
    endfunction: increase_tlx_credits

// *********************************************************************
    //Check DL credits number
    function bit has_dl_credits(input int number);
        if(coverage_on)
            c_dl_credits.sample();
        has_dl_credits = ((dl_credits - number) >= 0);
    endfunction: has_dl_credits

    //Get DL credits
    function void get_dl_credits(input int number);
        dl_credits -= number;
    endfunction: get_dl_credits

    //Return DL credits
    function void return_dl_credits(input int number);
        if((dl_credits + number) > cfg_obj.dl_credit_count)
            `uvm_error(get_type_name(), $psprintf("DL credits overflow, max credits is %d, current credits is %d",
                                                  cfg_obj.dl_credit_count, dl_credits + number))
        else
            dl_credits += number;
    endfunction: return_dl_credits

// *********************************************************************
    function int parse_dLength(input bit[1:0] dLength);
        int dL_bytes;

        case(dLength)
            2'b00:dL_bytes = 32;
            2'b01:dL_bytes = 64;
            2'b10:dL_bytes = 128;
            2'b11:dL_bytes = 256;
        endcase
        return dL_bytes;
    endfunction: parse_dLength

// *********************************************************************
    //Generate resp code for intrp_resp and intrp_rdy, support error resp
    function bit[3:0] gen_resp_code(input bit is_rdy, input tl_rx_trans::packet_type_enum packet_type = tl_rx_trans::INTRP_REQ);
        bit[3:0] resp_code;
        //intrp_rdy
        if(is_rdy) begin
            //interrupt accepted
            if(!cfg_obj.inject_err_enable)
                resp_code = 4'b0;
            //generate error resp
            else begin
                case(cfg_obj.inject_err_type)
                    tl_cfg_obj::RESP_CODE_RTY_REQ:  resp_code = 4'b0010;
                    tl_cfg_obj::RESP_CODE_FAILED:   resp_code = 4'b1110;
                    tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING:void'(std::randomize(resp_code)with{resp_code inside{4'b0000, 4'b0010};});
                    tl_cfg_obj::RESP_CODE_VALID_RND:void'(std::randomize(resp_code)with{resp_code inside{4'b0010, 4'b1110};});
                    tl_cfg_obj::RESP_CODE_ALL_RND:  void'(std::randomize(resp_code)with{resp_code inside{[1:15]};});
                    default: resp_code = 4'b0;
                endcase
            end
        end
        //intrp_resp
        else begin
            //interrupt accepted
            if(!cfg_obj.inject_err_enable)
                resp_code = 4'b0;
            //generate error resp
            else begin
                if(packet_type == tl_rx_trans::INTRP_REQ) begin
                    case(cfg_obj.inject_err_type)
                        tl_cfg_obj::RESP_CODE_RTY_REQ:          resp_code = 4'b0010;
                        tl_cfg_obj::RESP_CODE_INTRP_PENDING:    resp_code = 4'b0100;
                        tl_cfg_obj::RESP_CODE_BAD_OBJECT_HANDLE:resp_code = 4'b1011;
                        tl_cfg_obj::RESP_CODE_FAILED:           resp_code = 4'b1110;
                        tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING:void'(std::randomize(resp_code)with{resp_code inside{4'b0000, 4'b0010, 4'b0100};});
                        tl_cfg_obj::RESP_CODE_VALID_RND:        void'(std::randomize(resp_code)with{resp_code inside{4'b0010, 4'b0100, 4'b1011,4'b1110};});
                        tl_cfg_obj::RESP_CODE_ALL_RND:          void'(std::randomize(resp_code)with{resp_code inside{[1:15]};});
                        default: resp_code = 4'b0;
                    endcase
                end
                else if(packet_type == tl_rx_trans::INTRP_REQ_D) begin
                    case(cfg_obj.inject_err_type)
                        tl_cfg_obj::RESP_CODE_RTY_REQ:          resp_code = 4'b0010;
                        tl_cfg_obj::RESP_CODE_INTRP_PENDING:    resp_code = 4'b0100;
                        tl_cfg_obj::RESP_CODE_DATA_ERR:         resp_code = 4'b1000;
                        tl_cfg_obj::RESP_CODE_UNSUPPORT_LENGTH: resp_code = 4'b1001;
                        tl_cfg_obj::RESP_CODE_BAD_OBJECT_HANDLE:resp_code = 4'b1011;
                        tl_cfg_obj::RESP_CODE_FAILED:           resp_code = 4'b1110;
                        tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING:void'(std::randomize(resp_code)with{resp_code inside{4'b0000, 4'b0010, 4'b0100};});
                        tl_cfg_obj::RESP_CODE_VALID_RND:        void'(std::randomize(resp_code)with{resp_code inside{4'b0010, 4'b0100, 4'b1000, 4'b1001, 4'b1011,4'b1110};});
                        tl_cfg_obj::RESP_CODE_ALL_RND:          void'(std::randomize(resp_code)with{resp_code inside{[1:15]};});
                        default: resp_code = 4'b0;
                    endcase
                end
                else
                    resp_code = 4'b0;
            end
        end
        return resp_code;
    endfunction: gen_resp_code


// *********************************************************************
    //Generate AFU tag for intrp_resp and intrp_rdy
    function bit[15:0] gen_afu_tag(input bit[15:0] tag);
        bit[15:0]   rnd_tag;

        if(cfg_obj.intrp_resp_bad_afutag_enable) begin
            if(cfg_obj.intrp_resp_bad_afutag_rnd) begin
                void'(std::randomize(rnd_tag));
                gen_afu_tag = rnd_tag;
            end
            else
                gen_afu_tag = cfg_obj.intrp_resp_bad_afutag;
        end
        else
            gen_afu_tag = tag;
    endfunction: gen_afu_tag

// *********************************************************************
    //reset the manager
    function void reset();
        tx_cmd_queue.delete();
        rx_cmd_queue.delete();
        tx_back_off_queue.delete();     
        acTag_table.delete();
        capp_tag_queue.delete();
        afu_tag_queue.delete();
        retry_tx_info_queue.delete();
        retry_rx_info_queue.delete();
        intrp_handle_queue.delete();
        intrp_resp_queue.delete();
        rd_wr_resp_queue.delete();
        credits_reset();
        credits_init();
    endfunction: reset

// *********************************************************************
    //calculate latency
    function int calc_latency(input real start_time_in_ns, input real end_time_in_ns);
        int latency_in_cycle;
        latency_in_cycle = (end_time_in_ns - start_time_in_ns)/`CLOCK_CYCLE_IN_NS;
        return latency_in_cycle;
    endfunction: calc_latency

// *********************************************************************
    //interrupt handling
    function interrupt_handler(input tl_rx_trans rx_item);
        bit[3:0]        resp_code;
        bit[15:0]       capp_tag;
        bit[63:0]       paddr;
        tl_tx_trans     tx_item;
        tx_timer_trans  back_off_item;

        if(cfg_obj.intrp_resp_num == 1) begin
            resp_code = gen_resp_code(0, rx_item.packet_type);
            //intrp_pending
            if(resp_code == 4'b0100) begin
                tx_item = new("tx_item");
                tx_item.is_cmd = 0;
                tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                tx_item.resp_code = resp_code;
                //send interrupt pending to driver
                mgr_output_trans_port.write(tx_item);
                //generate intp_rdy push into queue
                back_off_item = new("back_off_item");
                back_off_item.tx_trans.is_cmd = 1;
                back_off_item.tx_trans.packet_type = tl_tx_trans::INTRP_RDY;
                back_off_item.tx_trans.afu_tag = gen_afu_tag(rx_item.AFUTag);
                back_off_item.tx_trans.resp_code = gen_resp_code(1);
                tx_back_off_queue.push_back(back_off_item);
            end
            //intrp accepted
            else if(resp_code == 4'b0000) begin
                //send intrp_resp firstly
                if(cfg_obj.intrp_resp_immd) begin
                    //generate intrp accepted resp
                    tx_item = new("tx_item");
                    tx_item.is_cmd = 0;
                    tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                    tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                    tx_item.resp_code = resp_code;
                    if(cfg_obj.intrp_resp_ocmb_enable)
                        tx_item.intrp_handler_begin = 1;
                    mgr_output_trans_port.write(tx_item);
                    if(cfg_obj.intrp_resp_ocmb_enable)
                        fir_regs_access(1);
                end
                //send intrp_resp after FIR MMIO read/write
                else begin
                    if(cfg_obj.intrp_resp_ocmb_enable)
                        fir_regs_access(0);
                    //generate intrp accepted resp
                    tx_item = new("tx_item");
                    tx_item.is_cmd = 0;
                    tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                    tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                    tx_item.resp_code = resp_code;
                    if(cfg_obj.intrp_resp_ocmb_enable)
                        tx_item.intrp_handler_end = 1;
                    intrp_resp_queue.push_back(tx_item);
                end
            end
            //other resp code: retry, bad obj, failed
            else begin
                tx_item = new("tx_item");
                tx_item.is_cmd = 0;
                tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                tx_item.resp_code = resp_code;
                mgr_output_trans_port.write(tx_item);
            end
        end
        else if(cfg_obj.intrp_resp_num > 1) begin
            //send intrp_resp firstly
            if(cfg_obj.intrp_resp_immd) begin
                //all resps are good
                if(cfg_obj.intrp_resp_all_good) begin
                    for(int i=0; i<cfg_obj.intrp_resp_num; i++) begin
                        tx_item = new("tx_item");
                        tx_item.is_cmd = 0;
                        tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                        tx_item.afu_tag = rx_item.AFUTag;
                        tx_item.resp_code = 4'b0;
                        if(cfg_obj.intrp_resp_ocmb_enable)
                            tx_item.intrp_handler_begin = 1;
                        mgr_output_trans_port.write(tx_item);
                    end
                end
                else begin
                    //only last resp is good
                    if(cfg_obj.intrp_resp_last_good) begin
                        for(int i=0; i<(cfg_obj.intrp_resp_num -1); i++) begin
                            tx_item = new("tx_item");
                            tx_item.is_cmd = 0;
                            tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                            tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                            tx_item.resp_code = gen_resp_code(0, rx_item.packet_type);
                            if(cfg_obj.intrp_resp_ocmb_enable)
                                tx_item.intrp_handler_begin = 1;
                            mgr_output_trans_port.write(tx_item);
                        end
                        tx_item = new("tx_item");
                        tx_item.is_cmd = 0;
                        tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                        tx_item.afu_tag = rx_item.AFUTag;
                        tx_item.resp_code = 4'b0;
                        if(cfg_obj.intrp_resp_ocmb_enable)
                            tx_item.intrp_handler_begin = 1;
                        mgr_output_trans_port.write(tx_item);
                    end
                    //all resps are bad
                    else begin
                        for(int i=0; i<cfg_obj.intrp_resp_num; i++) begin
                            tx_item = new("tx_item");
                            tx_item.is_cmd = 0;
                            tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                            tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                            tx_item.resp_code = gen_resp_code(0, rx_item.packet_type);
                            if(cfg_obj.intrp_resp_ocmb_enable)
                                tx_item.intrp_handler_begin = 1;
                            mgr_output_trans_port.write(tx_item);
                        end
                    end
                end
                if(cfg_obj.intrp_resp_ocmb_enable)
                    fir_regs_access(1);
            end
            //send intrp_resp after FIR MMIO read/write
            else begin
                if(cfg_obj.intrp_resp_ocmb_enable)
                    fir_regs_access(0);
                //all resps are good
                if(cfg_obj.intrp_resp_all_good) begin
                    for(int i=0; i<cfg_obj.intrp_resp_num; i++) begin
                        tx_item = new("tx_item");
                        tx_item.is_cmd = 0;
                        tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                        tx_item.afu_tag = rx_item.AFUTag;
                        tx_item.resp_code = 4'b0;
                        if(cfg_obj.intrp_resp_ocmb_enable) begin
                            if(i == (cfg_obj.intrp_resp_num-1))
                                tx_item.intrp_handler_end = 1;
                            else
                                tx_item.intrp_handler_begin = 1;
                        end
                        intrp_resp_queue.push_back(tx_item);
                    end
                end
                else begin
                    //only last resp is good
                    if(cfg_obj.intrp_resp_last_good) begin
                        for(int i=0; i<(cfg_obj.intrp_resp_num -1); i++) begin
                            tx_item = new("tx_item");
                            tx_item.is_cmd = 0;
                            tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                            tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                            tx_item.resp_code = gen_resp_code(0, rx_item.packet_type);
                            if(cfg_obj.intrp_resp_ocmb_enable)
                                tx_item.intrp_handler_begin = 1;
                            intrp_resp_queue.push_back(tx_item);
                        end
                        tx_item = new("tx_item");
                        tx_item.is_cmd = 0;
                        tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                        tx_item.afu_tag = rx_item.AFUTag;
                        tx_item.resp_code = 4'b0;
                        if(cfg_obj.intrp_resp_ocmb_enable)
                            tx_item.intrp_handler_end = 1;
                        intrp_resp_queue.push_back(tx_item);
                    end
                    //all resps are bad
                    else begin
                        for(int i=0; i<cfg_obj.intrp_resp_num; i++) begin
                            tx_item = new("tx_item");
                            tx_item.is_cmd = 0;
                            tx_item.packet_type = tl_tx_trans::INTRP_RESP;
                            tx_item.afu_tag = gen_afu_tag(rx_item.AFUTag);
                            tx_item.resp_code = gen_resp_code(0, rx_item.packet_type);
                            if(cfg_obj.intrp_resp_ocmb_enable) begin
                                if(i == (cfg_obj.intrp_resp_num-1))
                                    tx_item.intrp_handler_end = 1;
                                else
                                    tx_item.intrp_handler_begin = 1;
                            end
                            intrp_resp_queue.push_back(tx_item);
                        end
                    end
                end
            end
        end
        else begin
            `uvm_error(get_type_name(), $psprintf("The config intrp_resp_num is illegal!!! Please correct it. Wrong intrp_resp_num=%d",cfg_obj.intrp_resp_num))
        end

    endfunction: interrupt_handler

// *********************************************************************
    //read and clear FIR registers
    function void fir_regs_access(input bit last_is_handler_end);
        tl_tx_trans     tx_item;
        bit[15:0]       capp_tag;

        //read FIR regs from global to local
        for(int i=0; i<`FIR_REG_RD_NUM; i++) begin
            tx_item = new("tx_item");
            tx_item.is_cmd = 1;
            tx_item.packet_type = tl_tx_trans::PR_RD_MEM;
            tx_item.plength = 3;
            void'(std::randomize(capp_tag));
            tx_item.capp_tag = capp_tag;
            tx_item.physical_addr = cfg_obj.mmio_space_base+(fir_rd_addr_list[i]<<3);
            tx_item.intrp_handler_begin = 1;
            intrp_handle_queue[capp_tag] = tx_item;
            mgr_output_trans_port.write(tx_item);
        end
        //clear FIR regs from local to global
        for(int i=0; i<`FIR_REG_WR_NUM; i++) begin
            tx_item = new("tx_item");
            tx_item.is_cmd = 1;
            tx_item.packet_type = tl_tx_trans::PR_WR_MEM;
            tx_item.plength = 3;
            void'(std::randomize(capp_tag));
            tx_item.capp_tag = capp_tag;
            tx_item.physical_addr = cfg_obj.mmio_space_base+(fir_wr_addr_list[i]<<3);
            tx_item.data_carrier[0] = 0;
            if((i==`FIR_REG_WR_NUM-1) && last_is_handler_end)
                tx_item.intrp_handler_end = 1;
            else
                tx_item.intrp_handler_begin = 1;
            intrp_handle_queue[capp_tag] = tx_item;
            mgr_output_trans_port.write(tx_item);
        end
        
    endfunction: fir_regs_access

// *********************************************************************
    function void generate_write_resp_and_write_mem(input tl_rx_trans rx_item);
        int             w_num1, w_num2, w_num3, w_num4;
        resp_num_128B   resp_num_128B;
        resp_num_256B   resp_num_256B;
        bit             split_reorder=0;

        w_num1 = cfg_obj.wr_resp_num_1_weight;
        w_num2 = cfg_obj.wr_resp_num_2_weight;
        w_num3 = cfg_obj.wr_resp_num_3_weight;
        w_num4 = cfg_obj.wr_resp_num_4_weight;

        case(rx_item.packet_type)
            tl_rx_trans::DMA_W: begin
                case(rx_item.dL)
                    2'b01: begin //64Byte
                        generate_one_write_resp_and_write_mem(rx_item, 2'b01, 2'b00);
                    end
                    2'b10: begin //128Byte
                        resp_num_128B = new();
                        resp_num_128B.w_num1 = w_num1;
                        resp_num_128B.w_num2 = w_num2;
                        assert(resp_num_128B.randomize());
                        //one resp
                        if(resp_num_128B.number==1) begin
                            generate_one_write_resp_and_write_mem(rx_item, 2'b10, 2'b00);
                        end
                        //two resp
                        else begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_write_resp_and_write_mem(rx_item, 2'b01, i, split_reorder);
                            end
                        end
                    end
                    2'b11: begin //256Byte
                        resp_num_256B = new();
                        resp_num_256B.w_num1 = w_num1;
                        resp_num_256B.w_num2 = w_num2;
                        resp_num_256B.w_num3 = w_num3;
                        resp_num_256B.w_num4 = w_num4;
                        assert(resp_num_256B.randomize());
                        //one resp
                        if(resp_num_256B.number==1) begin
                            generate_one_write_resp_and_write_mem(rx_item, 2'b11, 2'b00);
                        end
                        //two resp
                        else if(resp_num_256B.number==2) begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_write_resp_and_write_mem(rx_item, 2'b10, i*2, split_reorder);
                            end
                        end
                        //three resp
                        else if(resp_num_256B.number==3) begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_write_resp_and_write_mem(rx_item, 2'b01, i, split_reorder);
                            end
                            generate_one_write_resp_and_write_mem(rx_item, 2'b10, 2'b10, split_reorder);
                        end
                        //four resp
                        else begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<4; i++) begin
                                generate_one_write_resp_and_write_mem(rx_item, 2'b01, i, split_reorder);
                            end
                        end
                    end
                    default: `uvm_error(get_type_name(),"Reserved dlegnth for DMA_W command")
                endcase
            end
            tl_rx_trans::DMA_W_BE, tl_rx_trans::DMA_PR_W: begin
                generate_one_write_resp_and_write_mem(rx_item, 2'b01, 2'b00);
            end
            default: `uvm_error(get_type_name(),"Unsupported write cmd")
        endcase

        if(split_reorder)
            do_split_resp_reorder();

    endfunction: generate_write_resp_and_write_mem

    function void generate_one_write_resp_and_write_mem(input tl_rx_trans rx_item, input bit[1:0]dL, input bit[1:0]dP, input bit reorder=0);
        int             w_good, w_fail;
        int             w_rty, w_xlate, w_derror, w_failed, w_reserved;
        fail_resp       fail_resp_en;
        fail_resp_code  fail_resp_code;
        tx_timer_trans  write_resp;

        w_fail = cfg_obj.wr_fail_percent;
        w_good = 100 - w_fail;
        w_rty      = cfg_obj.resp_rty_weight;
        w_xlate    = cfg_obj.resp_xlate_weight;
        w_derror   = cfg_obj.resp_derror_weight;
        w_failed   = cfg_obj.resp_failed_weight;
        w_reserved = cfg_obj.resp_reserved_weight;
        fail_resp_en   = new();
        fail_resp_en.w_good = w_good;
        fail_resp_en.w_fail = w_fail;
        fail_resp_code = new();
        fail_resp_code.w_rty = w_rty;
        fail_resp_code.w_xlate = w_xlate;
        fail_resp_code.w_derror = w_derror;
        fail_resp_code.w_failed = w_failed;
        fail_resp_code.w_reserved = w_reserved;

        write_resp = new("write_resp");
        write_resp.tx_trans.dlength = dL;
        write_resp.tx_trans.dpart   = dP;
        write_resp.tx_trans.afu_tag = rx_item.AFUTag;
        write_resp.tx_trans.is_cmd = 0;
        write_resp.tx_trans.physical_addr = rx_item.Eaddr;

        assert(fail_resp_en.randomize());
        //fail resp
        if(fail_resp_en.fail_en) begin
            assert(fail_resp_code.randomize());
            write_resp.tx_trans.packet_type = tl_tx_trans::WRITE_FAILED;
            write_resp.tx_trans.resp_code = fail_resp_code.code;
        end
        //good resp and write host mem
        else begin
            write_resp.tx_trans.packet_type = tl_tx_trans::WRITE_RESPONSE;
            host_mem.write_memory_by_cmd(rx_item, dL, dP);
        end

        if(reorder)
            split_resp_queue.push_back(write_resp);
        else
            rd_wr_resp_queue.push_back(write_resp);

    endfunction: generate_one_write_resp_and_write_mem

// *********************************************************************
    function void generate_read_resp_and_read_mem(input tl_rx_trans rx_item);
        int             w_num1, w_num2, w_num3, w_num4;
        resp_num_128B   resp_num_128B;
        resp_num_256B   resp_num_256B;
        bit             split_reorder=0;

        w_num1 = cfg_obj.rd_resp_num_1_weight;
        w_num2 = cfg_obj.rd_resp_num_2_weight;
        w_num3 = cfg_obj.rd_resp_num_3_weight;
        w_num4 = cfg_obj.rd_resp_num_4_weight;

        case(rx_item.packet_type)
            tl_rx_trans::RD_WNITC: begin
                case(rx_item.dL)
                    2'b01: begin //64Byte
                        generate_one_read_resp_and_read_mem(rx_item, 2'b01, 2'b00);
                    end
                    2'b10: begin //128Byte
                        resp_num_128B = new();
                        resp_num_128B.w_num1 = w_num1;
                        resp_num_128B.w_num2 = w_num2;
                        assert(resp_num_128B.randomize());
                        //one resp
                        if(resp_num_128B.number==1) begin
                            generate_one_read_resp_and_read_mem(rx_item, 2'b10, 2'b00);
                        end
                        //two resp
                        else begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_read_resp_and_read_mem(rx_item, 2'b01, i, split_reorder);
                            end
                        end
                    end
                    2'b11: begin //256Byte
                        resp_num_256B = new();
                        resp_num_256B.w_num1 = w_num1;
                        resp_num_256B.w_num2 = w_num2;
                        resp_num_256B.w_num3 = w_num3;
                        resp_num_256B.w_num4 = w_num4;
                        assert(resp_num_256B.randomize());
                        //one resp
                        if(resp_num_256B.number==1) begin
                            generate_one_read_resp_and_read_mem(rx_item, 2'b11, 2'b00);
                        end
                        //two resp
                        else if(resp_num_256B.number==2) begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_read_resp_and_read_mem(rx_item, 2'b10, i*2, split_reorder);
                            end
                        end
                        //three resp
                        else if(resp_num_256B.number==3) begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<2; i++) begin
                                generate_one_read_resp_and_read_mem(rx_item, 2'b01, i, split_reorder);
                            end
                            generate_one_read_resp_and_read_mem(rx_item, 2'b10, 2'b10, split_reorder);
                        end
                        //four resp
                        else begin
                            split_reorder = cfg_obj.split_reorder_enable;
                            for(int i=0; i<4; i++) begin
                                generate_one_read_resp_and_read_mem(rx_item, 2'b01, i, split_reorder);
                            end
                        end
                    end
                    default: `uvm_error(get_type_name(),"Reserved dlegnth for DMA_W command")
                endcase
            end
            tl_rx_trans::PR_RD_WNITC: begin
                generate_one_read_resp_and_read_mem(rx_item, 2'b01, 2'b00);
            end
            default: `uvm_error(get_type_name(),"Unsupported write cmd")
        endcase

        if(split_reorder)
            do_split_resp_reorder();

    endfunction: generate_read_resp_and_read_mem

    function void generate_one_read_resp_and_read_mem(input tl_rx_trans rx_item, input bit[1:0]dL, input bit[1:0]dP, input bit reorder=0);
        int             w_good, w_fail;
        int             w_rty, w_xlate, w_derror, w_failed, w_reserved;
        fail_resp       fail_resp_en;
        fail_resp_code  fail_resp_code;
        tx_timer_trans  read_resp;
        bit[63:0]       data_array[32];

        w_fail = cfg_obj.rd_fail_percent;
        w_good = 100 - w_fail;
        w_rty      = cfg_obj.resp_rty_weight;
        w_xlate    = cfg_obj.resp_xlate_weight;
        w_derror   = cfg_obj.resp_derror_weight;
        w_failed   = cfg_obj.resp_failed_weight;
        w_reserved = cfg_obj.resp_reserved_weight;
        fail_resp_en   = new();
        fail_resp_en.w_good = w_good;
        fail_resp_en.w_fail = w_fail;
        fail_resp_code = new();
        fail_resp_code.w_rty = w_rty;
        fail_resp_code.w_xlate = w_xlate;
        fail_resp_code.w_derror = w_derror;
        fail_resp_code.w_failed = w_failed;
        fail_resp_code.w_reserved = w_reserved;

        read_resp = new("read_resp");
        if(rx_item.packet_type == tl_rx_trans::PR_RD_WNITC)
            read_resp.tx_trans.dlength = 2'b00;
        else
            read_resp.tx_trans.dlength = dL;
        read_resp.tx_trans.dpart   = dP;
        read_resp.tx_trans.plength = rx_item.pL;
        read_resp.tx_trans.afu_tag = rx_item.AFUTag;
        read_resp.tx_trans.is_cmd = 0;
        read_resp.tx_trans.physical_addr = rx_item.Eaddr;

        assert(fail_resp_en.randomize());
        //fail resp
        if(fail_resp_en.fail_en) begin
            assert(fail_resp_code.randomize());
            read_resp.tx_trans.packet_type = tl_tx_trans::READ_FAILED;
            read_resp.tx_trans.resp_code = fail_resp_code.code;
        end
        //good resp and write host mem
        else begin
            read_resp.tx_trans.packet_type = tl_tx_trans::READ_RESPONSE;
            host_mem.read_memory_by_cmd(rx_item, data_array, dL, dP);
            read_resp.tx_trans.data_carrier = data_array;
        end

        if(reorder)
            split_resp_queue.push_back(read_resp);
        else
            rd_wr_resp_queue.push_back(read_resp);

    endfunction: generate_one_read_resp_and_read_mem

    function bit check_cmd_length_addr_and_gen_fail_resp(input tl_rx_trans rx_item);
        bit             has_error=0;
        tx_timer_trans  resp_trans;
        //unsupported length resp is not used as per spec, only check bad addr
        case(rx_item.packet_type)
            tl_rx_trans::DMA_W, tl_rx_trans::RD_WNITC: begin
                case(rx_item.dL)
                    2'b01: begin
                        if(rx_item.Eaddr[5:0]!=6'b0)
                            has_error = 1;
                    end
                    2'b10: begin
                        if(rx_item.Eaddr[6:0]!=7'b0)
                            has_error = 1;
                    end
                    2'b11: begin
                        if(rx_item.Eaddr[7:0]!=8'b0)
                            has_error = 1;
                    end
                    default: `uvm_error(get_type_name(),$psprintf("Unsupported dL for cmd:%s", rx_item.packet_type.name()))
                endcase
            end
            tl_rx_trans::DMA_PR_W, tl_rx_trans::PR_RD_WNITC: begin
                case(rx_item.pL)
                    3'b000: begin
                    end
                    3'b001: begin
                        if(rx_item.Eaddr[0]!=1'b0)
                            has_error = 1;
                    end
                    3'b010: begin
                        if(rx_item.Eaddr[1:0]!=2'b0)
                            has_error = 1;
                    end
                    3'b011: begin
                        if(rx_item.Eaddr[2:0]!=3'b0)
                            has_error = 1;
                    end
                    3'b100: begin
                        if(rx_item.Eaddr[3:0]!=4'b0)
                            has_error = 1;
                    end
                    3'b101: begin
                        if(rx_item.Eaddr[4:0]!=5'b0)
                            has_error = 1;
                    end
                    default: `uvm_error(get_type_name(),$psprintf("Unsupported pL for cmd:%s", rx_item.packet_type.name()))
                endcase
            end
        endcase

        if(has_error) begin
            resp_trans = new("resp_trans");
            resp_trans.tx_trans.afu_tag = rx_item.AFUTag;
            resp_trans.tx_trans.resp_code = 4'b1011; //bad addr
            resp_trans.tx_trans.dpart = 2'b00;
            resp_trans.tx_trans.is_cmd = 0;
            case(rx_item.packet_type)
                tl_rx_trans::DMA_W: begin
                    resp_trans.tx_trans.packet_type = tl_tx_trans::WRITE_FAILED;
                    resp_trans.tx_trans.dlength = rx_item.dL;
                end
                tl_rx_trans::DMA_PR_W: begin
                    resp_trans.tx_trans.packet_type = tl_tx_trans::WRITE_FAILED;
                    resp_trans.tx_trans.dlength = 2'b01;
                end
                tl_rx_trans::RD_WNITC: begin
                    resp_trans.tx_trans.packet_type = tl_tx_trans::READ_FAILED;
                    resp_trans.tx_trans.dlength = rx_item.dL;
                end
                tl_rx_trans::PR_RD_WNITC: begin
                    resp_trans.tx_trans.packet_type = tl_tx_trans::READ_FAILED;
                    resp_trans.tx_trans.dlength = 2'b01;
                end
            endcase
            rd_wr_resp_queue.push_back(resp_trans);
        end
        return has_error;
    endfunction: check_cmd_length_addr_and_gen_fail_resp

    function void do_split_resp_reorder();
        tx_timer_trans  tmp_item;
        int unsigned    idx1, idx2;

        if(split_resp_queue.size()==2) begin
            tmp_item = split_resp_queue.pop_front();
            split_resp_queue.push_back(tmp_item);
        end
        else begin
            idx1 = $urandom_range(0, split_resp_queue.size()-1);
            do begin
                idx2 = $urandom_range(0, split_resp_queue.size()-1);
            end
            while(idx1==idx2);
            tmp_item = split_resp_queue[idx1];
            split_resp_queue[idx1] = split_resp_queue[idx2];
            split_resp_queue[idx2] = tmp_item;
        end

        while(split_resp_queue.size != 0) begin
            tmp_item = split_resp_queue.pop_front();
            rd_wr_resp_queue.push_back(tmp_item);
        end
    endfunction: do_split_resp_reorder

endclass: tl_manager

`endif

