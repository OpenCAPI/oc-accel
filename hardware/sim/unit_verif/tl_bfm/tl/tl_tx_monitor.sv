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
`ifndef _TL_TX_MONITOR_SV
`define _TL_TX_MONITOR_SV
`define MAX_MEM_ADDR            64'h0000_0001_0000_0000
`define MMIO_SENSOR_CACHE_ADDR1 64'h0000_0000_4008_4200
`define MMIO_SENSOR_CACHE_ADDR2 64'h0000_0000_4008_4220
`define MSCC_RAM_INDEX_1        12

class tl_tx_monitor extends uvm_monitor;
	

    //Virtual interface definition
    virtual interface tl_dl_if                   tl_dl_vif;
    //Configuration 
    tl_cfg_obj                                   cfg_obj;    

    //TLM port & transaction declaration
    //Analysis port
    uvm_analysis_port #(tl_tx_trans)             tl_tx_trans_ap;
    //Transaction declaration
    tl_tx_trans                                  tx_mon_trans;

    bit                                          coverage_on = 1;

    `uvm_component_utils_begin(tl_tx_monitor)
        `uvm_field_int(coverage_on, UVM_ALL_ON)
    `uvm_component_utils_end

    //Data Structure for collecting and parsing data
    class tl_tx_mon_data;
        bit  [511:0]                             data_q[$];                                //Collected data queue from tl-dl interface
        bit  [511:0]                             flit_q[$];                                //Flit data queue assembled from collected data
        bit                                      flit_err;                                 //Flit error signal form tl-dl interface
        bit  [2:0]                               data_err_q[$];                            //Data error queue, [2:1] is ECC bits, [0] is bad data bit
        bit  [1:0]                               ecc_err_q[$];                             //ECC error information data queue
        bit  [167:0]                             packet_q[$];                              //Packet data queue for templates, the max packet is a 7-slot data
        bit  [167:0]                             wait_packet_q[$];                         //Packet data
        
        bit  [6:0]                               mdf_q[$];                                 //mdf data queue parsed from the packet
        bit  [6:0]                               meta_q[$];                                //meta data queue parsed from the packet (only template 7)
        bit  [71:0]                              xmeta_q[$];                               //xmeta data queue parsed from packet (only template A)
        
        bit  [63:0]                              data_carrier_q[$];                        //8-byte unit data carrier queue
        bit  [511:0]                             prefetch_data_flit_q[$];                  //prefetch data from collected data queue, if no error flit----put prefetch data into data carrier queue
        bit                                      prefetch_bad_data_flit_q[$];              //                                         if error flit--- discard error flit data
        bit  [5:0]                               data_template_q[$];                       // indicate which template the data carrier in. in template 7, A or in data flit
        int                                      data_carrier_type_q[$];                   //indicate which type of data carrier. 64--in a data flit; 32--in a data field of a control flit
        
        int                                      flit_count;
        bit  [3:0]                               dRunLen;
        bit  [7:0]                               bad_data_flit;
        bit                                      is_ctrl_flit;

        real                                     coll_ctrl_time;
        real                                     cmd_time_q[$];

        function new(string name = "tl_tx_mon_data");
            flit_count    = 0;
            dRunLen       = 4'b0;
            bad_data_flit = 8'b0;
        endfunction
    endclass: tl_tx_mon_data

    class tl_tx_mon_cov_data;
        tl_tx_trans::packet_type_enum            packet_type;
        tl_tx_trans::packet_type_enum            prev_packet_type;
        bit  [5:0]                               template;
        bit  [13:0]                              template_packet;
        bit  [13:0]                              template_packet_q[$];

        bit                                      is_config;
        bit  [31:0]                              cfg_reg_addr;
        bit  [4:0]                               cfg_device_number;
        bit  [2:0]                               cfg_function_number;
        bit                                      cfg_type_bit;
        bit  [2:0]                               cfg_plength;
        bit  [1:0]                               cfg_pa_aligned;

        bit  [31:0]                              pr_physical_addr;
        bit                                      is_inside_msccrnge;
        bit                                      is_inside_mscc;
        bit                                      is_sensor_cache;
        bit  [2:0]                               pa;

        bit                                      meta_data_enable;
        bit  [6:0]                               meta_data_bit;

        bit  [1:0]                               slot_data_valid;
        bit  [1:0]                               ecc_err_0;
        bit  [1:0]                               ecc_err_1;

        function new(string name = "tl_tx_mon_cov_data");
        endfunction
    endclass: tl_tx_mon_cov_data

    //Define a data structure for tx_mon
    tl_tx_mon_data                               tx_mon_data;
    tl_tx_mon_cov_data                           tx_mon_cov_data;

    covergroup c_ocapi_tl_tx_packet;
        option.per_instance = 1;
        c_tl_transmit_packet_and_template    : coverpoint tx_mon_cov_data.template_packet{
            bins config_read_template00        = {14'h00e0};
            bins config_read_template01        = {14'h01e0};
            bins config_read_template04        = {14'h04e0};
            bins config_read_template07        = {14'h07e0};
            bins config_write_template00       = {14'h00e1};
            bins config_write_template01       = {14'h01e1};
            bins config_write_template04       = {14'h04e1};
            bins config_write_template07       = {14'h07e1};
            bins intrp_resp_template00         = {14'h000a};
            bins intrp_resp_template01         = {14'h010a};
            bins intrp_resp_template04         = {14'h040a};
            bins intrp_resp_template07         = {14'h070a};
            bins mem_cntl_template00           = {14'h00ef};
            bins mem_cntl_template01           = {14'h01ef};
            bins mem_cntl_template04           = {14'h04ef};
            bins mem_cntl_template07           = {14'h07ef};
            bins nop_template00                = {14'h0000};
            bins nop_template01                = {14'h0100};
            bins nop_template04                = {14'h0400};
            bins nop_template07                = {14'h0700};
            bins pr_rd_mem_tempalet00          = {14'h0028};
            bins pr_rd_mem_tempalet01          = {14'h0128};
            bins pr_rd_mem_tempalet04          = {14'h0428};
            bins pr_rd_mem_tempalet07          = {14'h0728};
            bins pr_wr_mem_tempalet00          = {14'h0086};
            bins pr_wr_mem_tempalet01          = {14'h0186};
            bins pr_wr_mem_tempalet04          = {14'h0486};
            bins pr_wr_mem_tempalet07          = {14'h0786};
            bins rd_mem_tempalet00             = {14'h0020};
            bins rd_mem_tempalet01             = {14'h0120};
            bins rd_mem_tempalet04             = {14'h0420};
            bins rd_mem_tempalet07             = {14'h0720};
            bins write_mem_tempalet00          = {14'h0081};
            bins write_mem_tempalet01          = {14'h0181};
            bins write_mem_tempalet04          = {14'h0481};
            bins write_mem_tempalet07          = {14'h0781};
            bins return_tlx_credits_template00 = {14'h0001}; 
            bins return_tlx_credits_template01 = {14'h0101}; 
            bins return_tlx_credits_template04 = {14'h0401}; 
            bins return_tlx_credits_template07 = {14'h0701}; 
            bins write_mem_be_template00       = {14'h0082}; 
        }
    endgroup : c_ocapi_tl_tx_packet

    covergroup c_ocapi_tl_tx_template;
        option.per_instance = 1;
        c_tl_transmit_template             : coverpoint tx_mon_cov_data.template {
            bins template_00       = {6'h00};
            bins template_01       = {6'h01};
            bins template_04       = {6'h04};
            bins template_07       = {6'h07};
        }

        c_meta_data_enbale:  coverpoint tx_mon_cov_data.meta_data_enable{
            bins meta_data_enable  = {1'b1};
            bins meta_data_disable = {1'b0};
        }
 
        c_meta_data_bit0:     coverpoint tx_mon_cov_data.meta_data_bit[0];
        c_meta_data_bit1:     coverpoint tx_mon_cov_data.meta_data_bit[1];
        c_meta_data_bit2:     coverpoint tx_mon_cov_data.meta_data_bit[2];
        c_meta_data_bit3:     coverpoint tx_mon_cov_data.meta_data_bit[3];
        c_meta_data_bit4:     coverpoint tx_mon_cov_data.meta_data_bit[4];
        c_meta_data_bit5:     coverpoint tx_mon_cov_data.meta_data_bit[5];
        c_meta_data_bit6:     coverpoint tx_mon_cov_data.meta_data_bit[6];
 
        c_transmit_slot_data_valid:    coverpoint tx_mon_cov_data.slot_data_valid{
            bins good_data      = {2'b10};
            bins bad_data       = {2'b11};
            bins invalid_data[] = {2'b00, 2'b01};
        }
 
    endgroup : c_ocapi_tl_tx_template

    covergroup c_ocapi_tl_tx_flit;
        option.per_instance = 1;
        c_transmit_data_run_length:    coverpoint tx_mon_data.dRunLen{
            bins data_run_len_0 = {4'd0};
            bins data_run_len_1 = {4'd1};
            bins data_run_len_2 = {4'd2};
        }
 
        c_transmit_bad_data_flit:    coverpoint tx_mon_data.bad_data_flit{
            bins good_data  = {8'h00};
            bins bad_data0  = {8'h01};
            bins bad_data1  = {8'h02};
            bins bad_data01 = {8'h03};
        }
 
        c_flit_ecc_error:        cross tx_mon_cov_data.ecc_err_0, tx_mon_cov_data.ecc_err_1{
            bins ecc_ce_error = binsof(tx_mon_cov_data.ecc_err_0) intersect{2'b01} && binsof(tx_mon_cov_data.ecc_err_1) intersect{2'b01};
            bins ecc_ue_error = binsof(tx_mon_cov_data.ecc_err_0) intersect{2'b11} && binsof(tx_mon_cov_data.ecc_err_1) intersect{2'b11};
            bins ignore = binsof(tx_mon_cov_data.ecc_err_0) && binsof(tx_mon_cov_data.ecc_err_1);
        }

    endgroup : c_ocapi_tl_tx_flit
 

    covergroup c_ocapi_tl_tx_trans;
        option.per_instance = 1;
        c_tl_transmit_packet_type          : coverpoint tx_mon_cov_data.packet_type {
            bins config_read        = {tl_tx_trans::CONFIG_READ};
            bins config_write       = {tl_tx_trans::CONFIG_WRITE};
            bins intrp_resp         = {tl_tx_trans::INTRP_RESP};
            bins mem_cntl           = {tl_tx_trans::MEM_CNTL};
            bins nop                = {tl_tx_trans::NOP};
            bins pr_rd_mem          = {tl_tx_trans::PR_RD_MEM};
            bins pr_wr_mem          = {tl_tx_trans::PR_WR_MEM};
            bins rd_mem             = {tl_tx_trans::RD_MEM};
            bins write_mem          = {tl_tx_trans::WRITE_MEM};
            bins write_mem_be       = {tl_tx_trans::WRITE_MEM_BE};
            bins return_tlx_credits = {tl_tx_trans::RETURN_TLX_CREDITS};
        }
 
        c_tl_transmit_prev_packet_type     : coverpoint tx_mon_cov_data.prev_packet_type {
            bins config_read        = {tl_tx_trans::CONFIG_READ};
            bins config_write       = {tl_tx_trans::CONFIG_WRITE};
            bins intrp_resp         = {tl_tx_trans::INTRP_RESP};
            bins mem_cntl           = {tl_tx_trans::MEM_CNTL};
            bins nop                = {tl_tx_trans::NOP};
            bins pr_rd_mem          = {tl_tx_trans::PR_RD_MEM};
            bins pr_wr_mem          = {tl_tx_trans::PR_WR_MEM};
            bins rd_mem             = {tl_tx_trans::RD_MEM};
            bins write_mem          = {tl_tx_trans::WRITE_MEM};
            bins write_mem_be       = {tl_tx_trans::WRITE_MEM_BE};
            bins return_tlx_credits = {tl_tx_trans::RETURN_TLX_CREDITS};
        }
 
        c_tl_transmit_two_packet_type      : cross c_tl_transmit_packet_type, c_tl_transmit_prev_packet_type;

        c_config_reg_addr_rd :        coverpoint tx_mon_cov_data.cfg_reg_addr iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ){
            wildcard bins rd_reg_addr_section1[] = {32'b0000_0000_0000_0000_0000_0000_00xx_xx00};
            wildcard bins rd_reg_addr_section2[] = {32'h00000100, 32'h00000104, 32'h00000108, 32'b0000_0000_0000_0000_0000_0010_0xxx_xx00, 32'b0000_0000_0000_0000_0000_0010_1000_xx00};
            wildcard bins rd_reg_addr_section3[] = {32'b0000_0000_0000_0000_0000_0011_0000_xx00, 32'b0000_0000_0000_0000_0000_0110_00xx_xx00};
            wildcard bins rd_reg_addr_section4[] = {32'b0000_0000_0000_0001_0000_0000_00xx_xx00, 32'h00010100, 32'h00010104, 32'b0000_0000_0000_0001_0000_0011_0000_xx00, 32'b0000_0000_0000_0001_0000_0100_0000_xx00, 32'h00010410};
            wildcard bins rd_reg_addr_section5[] = {32'b0000_0000_0000_0001_0000_0101_000x_xx00, 32'h00010600, 32'h00010604, 32'h00010608};
            ignore_bins   ignore                 = {32'h00000048, 32'h0000004c, 32'h00000638, 32'h0000063c};
        }
 
        c_config_reg_addr_wr :        coverpoint tx_mon_cov_data.cfg_reg_addr iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE){
            
            wildcard bins wr_reg_addr_section1[] = {32'b0000_0000_0000_0000_0000_0000_00xx_xx00};
            wildcard bins wr_reg_addr_section2[] = {32'h00000100, 32'h00000104, 32'h00000108, 32'b0000_0000_0000_0000_0000_0010_0xxx_xx00, 32'b0000_0000_0000_0000_0000_0010_1000_xx00};
            wildcard bins wr_reg_addr_section3[] = {32'b0000_0000_0000_0000_0000_0011_0000_xx00, 32'b0000_0000_0000_0000_0000_0110_00xx_xx00};
            wildcard bins wr_reg_addr_section4[] = {32'b0000_0000_0000_0001_0000_0000_00xx_xx00, 32'h00010100, 32'h00010104, 32'b0000_0000_0000_0001_0000_0011_0000_xx00, 32'b0000_0000_0000_0001_0000_0100_0000_xx00, 32'h00010410};
            wildcard bins wr_reg_addr_section5[] = {32'b0000_0000_0000_0001_0000_0101_000x_xx00, 32'h00010600, 32'h00010604, 32'h00010608};
            ignore_bins   ignore                 = {32'h00000048, 32'h0000004c, 32'h00000638, 32'h0000063c};
        }

        c_config_err_device_rd :  coverpoint tx_mon_cov_data.cfg_device_number iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ){
            bins rd_err_device_number = {[5'b00001:$]};
        }

        c_config_err_device_wr :  coverpoint tx_mon_cov_data.cfg_device_number iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE){
            bins wr_err_device_number = {[5'b00001:$]};
        }

        c_config_err_function_rd :  coverpoint tx_mon_cov_data.cfg_function_number iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ){
            bins rd_err_func_number = {[3'b010:$]};
        }
 
        c_config_err_function_wr :  coverpoint tx_mon_cov_data.cfg_function_number iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE){
            bins wr_err_func_number = {[3'b010:$]};
        }
 
        c_config_type_bit :       cross tx_mon_cov_data.cfg_type_bit, tx_mon_trans.packet_type{
            bins rd_config_typebit_0 = (binsof(tx_mon_cov_data.cfg_type_bit) intersect{0}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins rd_config_typebit_1 = (binsof(tx_mon_cov_data.cfg_type_bit) intersect{1}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins wr_config_typebit_0 = (binsof(tx_mon_cov_data.cfg_type_bit) intersect{0}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins wr_config_typebit_1 = (binsof(tx_mon_cov_data.cfg_type_bit) intersect{1}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins ignore = binsof(tx_mon_cov_data.cfg_type_bit) && binsof(tx_mon_trans.packet_type);
        }
 
        c_config_transfer_size :  cross tx_mon_cov_data.cfg_plength, tx_mon_trans.packet_type{
            bins cfg_transfer_size_1byte_rd = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b000}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins cfg_transfer_size_1byte_wr = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b000}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins cfg_transfer_size_4byte_rd = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b001}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins cfg_transfer_size_4byte_wr = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b001}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins cfg_transfer_size_8byte_rd = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins cfg_transfer_size_8byte_wr = (binsof(tx_mon_cov_data.cfg_plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins ignore = binsof(tx_mon_cov_data.cfg_plength) && binsof(tx_mon_trans.packet_type);
        }
 
        c_config_err_size_rd :  coverpoint tx_mon_cov_data.cfg_plength iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ){
            bins rd_cfg_transfer_error_size[] = {3'b011, 3'b100, 3'b101, 3'b110, 3'b111};
        }
 
        c_config_err_size_wr :  coverpoint tx_mon_cov_data.cfg_plength iff(tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE){
            bins wr_cfg_transfer_error_size[] = {3'b011, 3'b100, 3'b101, 3'b110, 3'b111};
        }
 
        c_config_unaligned_addr : cross tx_mon_cov_data.cfg_pa_aligned, tx_mon_cov_data.cfg_plength, tx_mon_trans.packet_type{
            bins rd_unaligned_addr_PA0and2byte_01  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b01}) iff(tx_mon_cov_data.cfg_plength==3'b001 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins rd_unaligned_addr_PA0and2byte_11  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b11}) iff(tx_mon_cov_data.cfg_plength==3'b001 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins wr_unaligned_addr_PA0and2byte_01  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b01}) iff(tx_mon_cov_data.cfg_plength==3'b001 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins wr_unaligned_addr_PA0and2byte_11  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b11}) iff(tx_mon_cov_data.cfg_plength==3'b001 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins rd_unaligned_addr_PA0and4byte_01  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b01}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins rd_unaligned_addr_PA0and4byte_10  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b10}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins rd_unaligned_addr_PA0and4byte_11  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b11}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_READ);
            bins wr_unaligned_addr_PA0and4byte_01  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b01}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins wr_unaligned_addr_PA0and4byte_10  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b10}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins wr_unaligned_addr_PA0and4byte_11  = (binsof(tx_mon_cov_data.cfg_pa_aligned) intersect{2'b11}) iff(tx_mon_cov_data.cfg_plength==3'b010 && tx_mon_trans.packet_type==tl_tx_trans::CONFIG_WRITE);
            bins ignore  = binsof(tx_mon_cov_data.cfg_pa_aligned) && binsof(tx_mon_cov_data.cfg_plength) && binsof(tx_mon_trans.packet_type);
        }
 
 
        c_mmio_reg_addr_rd :    coverpoint tx_mon_cov_data.pr_physical_addr iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc)){
            bins rd_mmio_addr_section[10]   = {[32'h08010800:32'h080108ff]};
            bins rd_mcbist_addr_section[10] = {[32'h08011800:32'h080118ff]};
            bins rd_rdf_addr_section[10]    = {[32'h08011c00:32'h08011c3f]};
            bins rd_srq_addr_section[10]    = {[32'h08011400:32'h0801144f]};
            bins rd_tlxt_addr_section[10]   = {[32'h08012400:32'h0801242f]};
            bins rd_tp_addr_section1[]      = {[32'h08010000:32'h0801000b]};
            bins rd_tp_addr_section2[]      = {[32'h08010400:32'h08010409]};
            bins rd_tp_addr_section3[]      = {[32'h08010440:32'h08010449]};
            bins rd_tp_addr_section4[]      = {[32'h080107c0:32'h080107cf]};
            bins rd_tp_addr_section5[10]    = {[32'h08040000:32'h0804001f]};
            bins rd_tp_addr_section6[]      = {[32'h080e0000:32'h080e0005]};
            bins rd_tp_addr_section7[]      = {[32'h080f0000:32'h080f0005]};
            bins rd_wdf_addr_section[]      = {[32'h08012000:32'h08012009]};
            bins rd_dlx_addr_section[10]    = {[32'h08012800:32'h0801281f]};
        }
 
        c_mmio_reg_addr_wr :    coverpoint tx_mon_cov_data.pr_physical_addr iff((tx_mon_trans.packet_type == tl_tx_trans::PR_WR_MEM) && (!tx_mon_cov_data.is_inside_mscc)){
            bins wr_mmio_addr_section[10]   = {[32'h08010800:32'h080108ff]};
            bins wr_mcbist_addr_section[10] = {[32'h08011800:32'h080118ff]};
            bins wr_rdf_addr_section[10]    = {[32'h08011c00:32'h08011c3f]};
            bins wr_srq_addr_section[10]    = {[32'h08011400:32'h0801144f]};
            bins wr_tlxt_addr_section[10]   = {[32'h08012400:32'h0801242f]};
            bins wr_tp_addr_section1[]      = {[32'h08010000:32'h0801000b]};
            bins wr_tp_addr_section2[]      = {[32'h08010400:32'h08010409]};
            bins wr_tp_addr_section3[]      = {[32'h08010440:32'h08010449]};
            bins wr_tp_addr_section4[]      = {[32'h080107c0:32'h080107cf]};
            bins wr_tp_addr_section5[10]    = {[32'h08040000:32'h0804001f]};
            bins wr_tp_addr_section6[]      = {[32'h080e0000:32'h080e0005]};
            bins wr_tp_addr_section7[]      = {[32'h080f0000:32'h080f0005]};
            bins wr_wdf_addr_section[]      = {[32'h08012000:32'h08012009]};
            bins wr_dlx_addr_section[10]    = {[32'h08012800:32'h0801281f]};
        }
 
        c_mmio_transfer_size_rd : coverpoint tx_mon_trans.plength iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (!tx_mon_cov_data.is_sensor_cache)){
            bins mmio_transfer_size_8byte_rd  = {3'b011};
        }

        c_mmio_sensor_size_rd : coverpoint tx_mon_trans.plength iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (tx_mon_cov_data.is_sensor_cache)){
            bins mmio_transfer_size_32byte_rd  = {3'b101};
        }
 
        c_mmio_transfer_size_wr : coverpoint tx_mon_trans.plength iff((tx_mon_trans.packet_type == tl_tx_trans::PR_WR_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (!tx_mon_cov_data.is_sensor_cache)){
            bins mmio_transfer_size_8byte_wr  = {3'b011};
        }
 
        c_mmio_error_size_rd : coverpoint tx_mon_trans.plength iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc)){
            bins mmio_plength_error_size_rd[]  = {3'b000, 3'b001, 3'b010, 3'b100, 3'b110, 3'b111};
        }
 
        c_mmio_error_size_wr : coverpoint tx_mon_trans.plength iff((tx_mon_trans.packet_type == tl_tx_trans::PR_WR_MEM) && (!tx_mon_cov_data.is_inside_mscc)){
            bins mmio_plength_error_size_wr[]  = {3'b000, 3'b001, 3'b010, 3'b100, 3'b101, 3'b110, 3'b111};
        }
 
        c_mmio_unaligned_addr_8byte_rd : coverpoint tx_mon_trans.physical_addr[2:0] iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (tx_mon_trans.plength==3'b011)){
            ignore_bins ignore = {3'b000};
        }
 
        c_mmio_unaligned_addr_32byte_rd : coverpoint tx_mon_trans.physical_addr[4:0] iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (tx_mon_trans.plength==3'b101)){
            ignore_bins ignore = {5'b00000};
        }
 
        c_mmio_unaligned_addr_wr : coverpoint tx_mon_trans.physical_addr[2:0] iff((tx_mon_trans.packet_type == tl_tx_trans::PR_WR_MEM) && (!tx_mon_cov_data.is_inside_mscc) && (tx_mon_trans.plength==3'b011)){
            ignore_bins ignore = {3'b000};
        }
 
       c_mscc_mmio_reg_addr_rd : coverpoint tx_mon_cov_data.pr_physical_addr[31:2] iff((tx_mon_trans.packet_type == tl_tx_trans::PR_RD_MEM) && (tx_mon_cov_data.is_inside_mscc)){
           bins  rd_gpbc_xcbi_peri_addr[10] = {[30'h0:30'h7ff]};
           bins  rd_gpbc_top_xcbi_addr[10]  = {[30'h800:30'hfff]};
           bins  rd_gpbc_sys_xcbi_addr[10]  = {[30'h1000:30'h13ff]};
           bins  rd_uart_addr[10]           = {[30'h1400:30'h14ff]};         // 1KB valid
           bins  rd_twi_addr[10]            = {[30'h2000:30'h23ff]};         // 4KB valid
           bins  rd_gpio_addr[10]           = {[30'h5000:30'h53ff]};
           bins  rd_wdt_addr[10]            = {[30'h5400:30'h57ff]};
           bins  rd_i2c_hs_addr[10]         = {[30'h10000:30'h103ff]};
           bins  rd_serdes_addr[10]         = {[30'h80000:30'h81fff]};       // 32KB valid
           bins  rd_dcsu_addr[10]           = {[30'h82000:30'h823ff]};
           bins  rd_pvt_cntl_addr[10]       = {[30'h82400:30'h82bff]};
           bins  rd_efuse_addr[10]          = {[30'h82c00:30'h833ff]};
           bins  rd_ram_addr[10]            = {[30'h400000:30'h41ffff]};     // 512KB valid
           bins  rd_rom_addr[10]            = {[30'h800000:30'h807fff]};     // 128KB valid
           bins  rd_opse_reg_addr[10]       = {[30'hc00000:30'hc03fff]};     // 64KB valid
           bins  rd_opse_gic_addr[10]       = {[30'hc08000:30'hc0ffff]};
           bins  rd_pcse_reg_addr[10]       = {[30'hc14000:30'hc17fff]};
           bins  rd_ddr4_phy_addr[10]       = {[30'h1000000:30'h1ffffff]};   
       }
 
       c_mscc_mmio_reg_addr_wr : coverpoint tx_mon_cov_data.pr_physical_addr[31:2] iff((tx_mon_trans.packet_type == tl_tx_trans::PR_WR_MEM) && (tx_mon_cov_data.is_inside_mscc)){
           bins  wr_gpbc_xcbi_peri_addr[10] = {[30'h0:30'h7ff]};
           bins  wr_gpbc_top_xcbi_addr[10]  = {[30'h800:30'hfff]};
           bins  wr_gpbc_sys_xcbi_addr[10]  = {[30'h1000:30'h13ff]};
           bins  wr_uart_addr[10]           = {[30'h1400:30'h14ff]};         // 1KB valid
           bins  wr_twi_addr[10]            = {[30'h2000:30'h23ff]};         // 4KB valid
           bins  wr_gpio_addr[10]           = {[30'h5000:30'h53ff]};
           bins  wr_wdt_addr[10]            = {[30'h5400:30'h57ff]};
           bins  wr_i2c_hs_addr[10]         = {[30'h10000:30'h103ff]};
           bins  wr_serdes_addr[10]         = {[30'h80000:30'h81fff]};       // 32KB valid
           bins  wr_dcsu_addr[10]           = {[30'h82000:30'h823ff]};
           bins  wr_pvt_cntl_addr[10]       = {[30'h82400:30'h82bff]};
           bins  wr_efuse_addr[10]          = {[30'h82c00:30'h833ff]};
           bins  wr_ram_addr[10]            = {[30'h400000:30'h41ffff]};     // 512KB valid
           bins  wr_rom_addr[10]            = {[30'h800000:30'h807fff]};     // 128KB valid
           bins  wr_opse_reg_addr[10]       = {[30'hc00000:30'hc03fff]};     // 64KB valid
           bins  wr_opse_gic_addr[10]       = {[30'hc08000:30'hc0ffff]};
           bins  wr_pcse_reg_addr[10]       = {[30'hc14000:30'hc17fff]};
           bins  wr_ddr4_phy_addr[10]       = {[30'h1000000:30'h1ffffff]};   
       }
 
        c_mscc_mmio_transfer_size : cross tx_mon_trans.plength, tx_mon_trans.packet_type, tx_mon_cov_data.is_inside_msccrnge, tx_mon_cov_data.is_inside_mscc{
            bins outsidemsccrnge_4byte_read  = (binsof(tx_mon_trans.plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins outsidemsccrnge_4byte_write = (binsof(tx_mon_trans.plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins insidemsccrnge_4byte_read   = (binsof(tx_mon_trans.plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins insidemsccrnge_4byte_write  = (binsof(tx_mon_trans.plength) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins insidemsccrnge_8byte_read   = (binsof(tx_mon_trans.plength) intersect{3'b011}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins insidemsccrnge_8byte_write  = (binsof(tx_mon_trans.plength) intersect{3'b011}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins ignore = binsof(tx_mon_trans.plength) && binsof(tx_mon_trans.packet_type) && binsof(tx_mon_cov_data.is_inside_msccrnge) && binsof(tx_mon_cov_data.is_inside_mscc);
        }
 
        c_mscc_mmio_err_size : cross tx_mon_trans.plength, tx_mon_trans.packet_type, tx_mon_cov_data.is_inside_msccrnge, tx_mon_cov_data.is_inside_mscc{
            bins err_size_outside_msccrnge_read  = (binsof(tx_mon_trans.plength) intersect{3'b000, 3'b001, 3'b011, 3'b100, 3'b101, 3'b110,3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins err_size_outside_msccrnge_write = (binsof(tx_mon_trans.plength) intersect{3'b000, 3'b001, 3'b011, 3'b100, 3'b101, 3'b110,3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins err_size_inside_msccrnge_read   = (binsof(tx_mon_trans.plength) intersect{3'b000, 3'b001, 3'b100, 3'b101, 3'b110,3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins err_size_inside_msccrnge_write  = (binsof(tx_mon_trans.plength) intersect{3'b000, 3'b001, 3'b100, 3'b101, 3'b110,3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc);
            bins ignore = binsof(tx_mon_trans.plength) && binsof(tx_mon_trans.packet_type) && binsof(tx_mon_cov_data.is_inside_msccrnge) && binsof(tx_mon_cov_data.is_inside_mscc);
        }
 

        c_mscc_mmio_unaligned_addr : cross tx_mon_cov_data.pa, tx_mon_trans.packet_type, tx_mon_cov_data.is_inside_msccrnge, tx_mon_cov_data.is_inside_mscc, tx_mon_trans.plength{
            bins rd_4byte_out_range_addr01 = (binsof(tx_mon_cov_data.pa) intersect{3'b001, 3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_4byte_out_range_addr10 = (binsof(tx_mon_cov_data.pa) intersect{3'b010, 3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_4byte_out_range_addr11 = (binsof(tx_mon_cov_data.pa) intersect{3'b011, 3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_out_range_addr01 = (binsof(tx_mon_cov_data.pa) intersect{3'b001, 3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_out_range_addr10 = (binsof(tx_mon_cov_data.pa) intersect{3'b010, 3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_out_range_addr11 = (binsof(tx_mon_cov_data.pa) intersect{3'b011, 3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && !tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_4byte_in_range_addr01 = (binsof(tx_mon_cov_data.pa) intersect{3'b001, 3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_4byte_in_range_addr10 = (binsof(tx_mon_cov_data.pa) intersect{3'b010, 3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_4byte_in_range_addr11 = (binsof(tx_mon_cov_data.pa) intersect{3'b011, 3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_in_range_addr01 = (binsof(tx_mon_cov_data.pa) intersect{3'b001, 3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_in_range_addr10 = (binsof(tx_mon_cov_data.pa) intersect{3'b010, 3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins wr_4byte_in_range_addr11 = (binsof(tx_mon_cov_data.pa) intersect{3'b011, 3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b010);
            bins rd_8byte_in_range_addr001 = (binsof(tx_mon_cov_data.pa) intersect{3'b001}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr010 = (binsof(tx_mon_cov_data.pa) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr011 = (binsof(tx_mon_cov_data.pa) intersect{3'b011}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr100 = (binsof(tx_mon_cov_data.pa) intersect{3'b100}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr101 = (binsof(tx_mon_cov_data.pa) intersect{3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr110 = (binsof(tx_mon_cov_data.pa) intersect{3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins rd_8byte_in_range_addr111 = (binsof(tx_mon_cov_data.pa) intersect{3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_RD_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr001 = (binsof(tx_mon_cov_data.pa) intersect{3'b001}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr010 = (binsof(tx_mon_cov_data.pa) intersect{3'b010}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr011 = (binsof(tx_mon_cov_data.pa) intersect{3'b011}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr100 = (binsof(tx_mon_cov_data.pa) intersect{3'b100}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr101 = (binsof(tx_mon_cov_data.pa) intersect{3'b101}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr110 = (binsof(tx_mon_cov_data.pa) intersect{3'b110}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins wr_8byte_in_range_addr111 = (binsof(tx_mon_cov_data.pa) intersect{3'b111}) iff(tx_mon_trans.packet_type==tl_tx_trans::PR_WR_MEM && tx_mon_cov_data.is_inside_msccrnge && tx_mon_cov_data.is_inside_mscc && tx_mon_trans.plength==3'b011);
            bins ignore = binsof(tx_mon_cov_data.pa) && binsof(tx_mon_trans.packet_type) && binsof(tx_mon_cov_data.is_inside_msccrnge) && binsof(tx_mon_cov_data.is_inside_mscc) && binsof(tx_mon_trans.plength);
        }
 
        c_memory_addr :    cross tx_mon_trans.physical_addr, tx_mon_trans.packet_type{
            bins valid_min_addr_rd = (binsof(tx_mon_trans.physical_addr) intersect{64'h0000_0000_0000_0000}) iff(tx_mon_trans.packet_type==tl_tx_trans::RD_MEM);
            bins valid_min_addr_wr = (binsof(tx_mon_trans.physical_addr) intersect{64'h0000_0000_0000_0000}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM);
            bins valid_min_addr_be = (binsof(tx_mon_trans.physical_addr) intersect{64'h0000_0000_0000_0000}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM_BE);
            bins valid_max_addr_rd = (binsof(tx_mon_trans.physical_addr) intersect{`MAX_MEM_ADDR}) iff(tx_mon_trans.packet_type==tl_tx_trans::RD_MEM);
            bins valid_max_addr_wr = (binsof(tx_mon_trans.physical_addr) intersect{`MAX_MEM_ADDR}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM);
            bins valid_max_addr_be = (binsof(tx_mon_trans.physical_addr) intersect{`MAX_MEM_ADDR}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM_BE);
            bins ignore = binsof(tx_mon_trans.physical_addr) && binsof(tx_mon_trans.packet_type);
 
        }
 
        c_memory_err_addr_rd :coverpoint tx_mon_trans.physical_addr iff(tx_mon_trans.packet_type == tl_tx_trans::RD_MEM){
            bins rd_above_max_addr = {[`MAX_MEM_ADDR+1 : $]};
        }
 
        c_memory_err_addr_wr :coverpoint tx_mon_trans.physical_addr iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM){
            bins wr_above_max_addr = {[`MAX_MEM_ADDR+1 : $]};
        }
 
        c_memory_err_addr_be :coverpoint tx_mon_trans.physical_addr iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE){
            bins be_above_max_addr = {[`MAX_MEM_ADDR+1 : $]};
        }
 
 
        c_memory_transfer_size:   cross tx_mon_trans.dlength, tx_mon_trans.packet_type{
            bins mem_transfer_size_64byte_rd   = (binsof(tx_mon_trans.dlength) intersect{2'b01}) iff(tx_mon_trans.packet_type==tl_tx_trans::RD_MEM);
            bins mem_transfer_size_64byte_wr   = (binsof(tx_mon_trans.dlength) intersect{2'b01}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM);
            bins mem_transfer_size_128byte_rd  = (binsof(tx_mon_trans.dlength) intersect{2'b10}) iff(tx_mon_trans.packet_type==tl_tx_trans::RD_MEM);
            bins mem_transfer_size_128byte_wr  = (binsof(tx_mon_trans.dlength) intersect{2'b10}) iff(tx_mon_trans.packet_type==tl_tx_trans::WRITE_MEM);
            bins ignore = binsof(tx_mon_trans.dlength) && binsof(tx_mon_trans.packet_type);
        }
 
        c_memory_err_size_rd:    coverpoint tx_mon_trans.dlength iff(tx_mon_trans.packet_type == tl_tx_trans::RD_MEM){
            bins rd_memory_err_size[] = {2'b00, 2'b11};
        }
 
        c_memory_err_size_wr:    coverpoint tx_mon_trans.dlength iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM){
            bins wr_memory_err_size[] = {2'b00, 2'b11};
        }
 
        c_memory_unaligned_64byte_addr_rd:    coverpoint tx_mon_trans.physical_addr[5:0] iff((tx_mon_trans.packet_type == tl_tx_trans::RD_MEM) && (tx_mon_trans.dlength==2'b01)){
            ignore_bins ignore = {6'b000000};
        }
 
        c_memory_unaligned_128byte_addr_rd:    coverpoint tx_mon_trans.physical_addr[6:0] iff((tx_mon_trans.packet_type == tl_tx_trans::RD_MEM) && (tx_mon_trans.dlength==2'b10)){
            ignore_bins ignore = {7'b0000000};
        }
 
        c_memory_unaligned_64byte_addr_wr:    coverpoint tx_mon_trans.physical_addr[5:0] iff((tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM) && (tx_mon_trans.dlength==2'b01)){
            ignore_bins ignore = {6'b000000};
        }
 
        c_memory_unaligned_128byte_addr_wr:    coverpoint tx_mon_trans.physical_addr[6:0] iff((tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM) && (tx_mon_trans.dlength==2'b10)){
            ignore_bins ignore = {7'b0000000};
        }
 
        c_wr_byte_enable_bit00:     coverpoint tx_mon_trans.byte_enable[0] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit01:     coverpoint tx_mon_trans.byte_enable[1] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit02:     coverpoint tx_mon_trans.byte_enable[2] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit03:     coverpoint tx_mon_trans.byte_enable[3] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit04:     coverpoint tx_mon_trans.byte_enable[4] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit05:     coverpoint tx_mon_trans.byte_enable[5] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit06:     coverpoint tx_mon_trans.byte_enable[6] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit07:     coverpoint tx_mon_trans.byte_enable[7] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit08:     coverpoint tx_mon_trans.byte_enable[8] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit09:     coverpoint tx_mon_trans.byte_enable[9] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit10:     coverpoint tx_mon_trans.byte_enable[10] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit11:     coverpoint tx_mon_trans.byte_enable[11] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit12:     coverpoint tx_mon_trans.byte_enable[12] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit13:     coverpoint tx_mon_trans.byte_enable[13] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit14:     coverpoint tx_mon_trans.byte_enable[14] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit15:     coverpoint tx_mon_trans.byte_enable[15] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit16:     coverpoint tx_mon_trans.byte_enable[16] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit17:     coverpoint tx_mon_trans.byte_enable[17] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit18:     coverpoint tx_mon_trans.byte_enable[18] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit19:     coverpoint tx_mon_trans.byte_enable[19] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit20:     coverpoint tx_mon_trans.byte_enable[20] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit21:     coverpoint tx_mon_trans.byte_enable[21] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit22:     coverpoint tx_mon_trans.byte_enable[22] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit23:     coverpoint tx_mon_trans.byte_enable[23] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit24:     coverpoint tx_mon_trans.byte_enable[24] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit25:     coverpoint tx_mon_trans.byte_enable[25] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit26:     coverpoint tx_mon_trans.byte_enable[26] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit27:     coverpoint tx_mon_trans.byte_enable[27] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit28:     coverpoint tx_mon_trans.byte_enable[28] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit29:     coverpoint tx_mon_trans.byte_enable[29] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit30:     coverpoint tx_mon_trans.byte_enable[30] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit31:     coverpoint tx_mon_trans.byte_enable[31] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit32:     coverpoint tx_mon_trans.byte_enable[32] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit33:     coverpoint tx_mon_trans.byte_enable[33] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit34:     coverpoint tx_mon_trans.byte_enable[34] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit35:     coverpoint tx_mon_trans.byte_enable[35] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit36:     coverpoint tx_mon_trans.byte_enable[36] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit37:     coverpoint tx_mon_trans.byte_enable[37] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit38:     coverpoint tx_mon_trans.byte_enable[38] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit39:     coverpoint tx_mon_trans.byte_enable[39] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit40:     coverpoint tx_mon_trans.byte_enable[40] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit41:     coverpoint tx_mon_trans.byte_enable[41] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit42:     coverpoint tx_mon_trans.byte_enable[42] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit43:     coverpoint tx_mon_trans.byte_enable[43] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit44:     coverpoint tx_mon_trans.byte_enable[44] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit45:     coverpoint tx_mon_trans.byte_enable[45] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit46:     coverpoint tx_mon_trans.byte_enable[46] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit47:     coverpoint tx_mon_trans.byte_enable[47] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit48:     coverpoint tx_mon_trans.byte_enable[48] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit49:     coverpoint tx_mon_trans.byte_enable[49] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit50:     coverpoint tx_mon_trans.byte_enable[50] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit51:     coverpoint tx_mon_trans.byte_enable[51] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit52:     coverpoint tx_mon_trans.byte_enable[52] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit53:     coverpoint tx_mon_trans.byte_enable[53] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit54:     coverpoint tx_mon_trans.byte_enable[54] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit55:     coverpoint tx_mon_trans.byte_enable[55] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit56:     coverpoint tx_mon_trans.byte_enable[56] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit57:     coverpoint tx_mon_trans.byte_enable[57] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit58:     coverpoint tx_mon_trans.byte_enable[58] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit59:     coverpoint tx_mon_trans.byte_enable[59] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit60:     coverpoint tx_mon_trans.byte_enable[60] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit61:     coverpoint tx_mon_trans.byte_enable[61] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit62:     coverpoint tx_mon_trans.byte_enable[62] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);
        c_wr_byte_enable_bit63:     coverpoint tx_mon_trans.byte_enable[63] iff(tx_mon_trans.packet_type == tl_tx_trans::WRITE_MEM_BE);

        c_mem_cntl_cmd_flag:  coverpoint tx_mon_trans.cmd_flag iff(tx_mon_trans.packet_type == tl_tx_trans::MEM_CNTL){
            bins cmd_flag_0000 = {4'b0000};
            bins cmd_flag_0001 = {4'b0001};
            bins cmd_flag_0010 = {4'b0010};
            bins cmd_flag_0011 = {4'b0011};
            bins cmd_flag_0100 = {4'b0100};
            bins cmd_flag_0101 = {4'b0101};
            bins cmd_flag_0110 = {4'b0110};
            bins cmd_flag_0111 = {4'b0111};
            bins cmd_flag_reserved[] = {[4'b1000 : 4'b1111]};
        }
 
        c_mem_cntl_obj_handle:  coverpoint tx_mon_trans.object_handle iff(tx_mon_trans.packet_type == tl_tx_trans::MEM_CNTL){
            bins object_handle_0 = {64'h0000_0000_0000_0000};
            bins object_handle_other_than_0 = {[64'h0000_0000_0000_0001:$]};
        }
 
        c_mem_intrp_resp:    coverpoint tx_mon_trans.resp_code iff(tx_mon_trans.packet_type == tl_tx_trans::INTRP_RESP){
            bins resp_code_0000 = {4'b0000};
            bins resp_code_0010 = {4'b0010};
            bins resp_code_0100 = {4'b0100};
            bins resp_code_1011 = {4'b1011};
            bins resp_code_1110 = {4'b1110};
        }
 
    endgroup: c_ocapi_tl_tx_trans
    

    function new (string name="tl_tx_monitor", uvm_component parent);
        super.new(name, parent);
        tl_tx_trans_ap = new("tl_tx_trans_ap", this);
        tx_mon_data = new("tx_mon_data");
        tx_mon_cov_data = new("tx_mon_cov_data");

        void'(uvm_config_db#(int)::get(this,"","coverage_on",coverage_on));
        if(coverage_on) begin
            c_ocapi_tl_tx_packet   = new();
            c_ocapi_tl_tx_template = new();
            c_ocapi_tl_tx_flit     = new();
            c_ocapi_tl_tx_trans    = new();
            c_ocapi_tl_tx_packet.set_inst_name({get_full_name(), ".c_ocapi_tl_tx_packet"});
            c_ocapi_tl_tx_template.set_inst_name({get_full_name(), ".c_ocapi_tl_tx_template"});
            c_ocapi_tl_tx_flit.set_inst_name({get_full_name(), ".c_ocapi_tl_tx_flit"});
            c_ocapi_tl_tx_trans.set_inst_name({get_full_name(), ".c_ocapi_tl_tx_trans"});
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
    endfunction: start_of_simulation_phase

    // Define global events
    event get_flit;
    event get_data;


    //Run phase and collection functions
    task main_phase(uvm_phase phase);
        fork
            collect_data();
            assemble_flit();
            parse_flit();
            assemble_trans();
        join
    endtask : main_phase

    function void reset();
        
        tx_mon_data.data_q.delete();
        tx_mon_data.flit_q.delete();
        tx_mon_data.data_err_q.delete();
        tx_mon_data.ecc_err_q.delete();
        tx_mon_data.packet_q.delete();
        tx_mon_data.wait_packet_q.delete();
        tx_mon_data.mdf_q.delete();
        tx_mon_data.meta_q.delete();
        tx_mon_data.xmeta_q.delete();
        tx_mon_data.data_carrier_q.delete();
        tx_mon_data.prefetch_data_flit_q.delete();
        tx_mon_data.prefetch_bad_data_flit_q.delete();
        tx_mon_data.data_carrier_type_q.delete();
        
        tx_mon_data.flit_err = 0;
        tx_mon_data.flit_count = 0;
        tx_mon_data.dRunLen = 4'b0;
        tx_mon_data.bad_data_flit = 8'b0;
        tx_mon_data.is_ctrl_flit = 0;
    endfunction


    // collect data from interface
    virtual task collect_data();
        forever begin
            @(posedge tl_dl_vif.clock);
            //UNIT_SIM MODE
            if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin

                tx_mon_data.flit_err = tl_dl_vif.dl_tl_flit_error;
                if(tx_mon_data.flit_err) begin
                    discard_data_flit();
                    if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1) begin
                        if((tx_mon_data.data_q.size != 0) && ((tx_mon_data.data_q.size)%4 == 1)) begin
                            bit [127:0] temp_data;
                            temp_data = tx_mon_data.data_q.pop_front;
                        end
                        if((tx_mon_data.data_q.size != 0) && ((tx_mon_data.data_q.size)%4 == 2)) begin
                            bit [127:0] temp_data;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                        end
                        if((tx_mon_data.data_q.size != 0) && ((tx_mon_data.data_q.size)%4 == 3)) begin
                            bit [127:0] temp_data;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                        end
                        if((tx_mon_data.data_q.size != 0) && ((tx_mon_data.data_q.size)%4 == 0)) begin
                            bit [127:0] temp_data;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                            temp_data = tx_mon_data.data_q.pop_front;
                        end
                    end else if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                        if (tx_mon_data.data_q.size != 0) begin
                            bit [511:0] temp_data;
                            temp_data = tx_mon_data.data_q.pop_front;
                        end
                    end
                end
                
                if(tl_dl_vif.dl_tl_flit_vld) begin
                
                    //OpenCapi link trained check
                    if(~tl_dl_vif.dl_tl_link_up) begin
                        `uvm_fatal(get_type_name(), "The OpenCapi link has not bee trained yet. UE error");
                    end

                    if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1) begin
                        //Parity check
                        parity_check(tl_dl_vif.dl_tl_flit_data, tl_dl_vif.dl_tl_flit_pty);
                        tx_mon_data.data_q.push_back(tl_dl_vif.dl_tl_flit_data[127:0]);
                    end else if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                        tx_mon_data.data_q.push_back(tl_dl_vif.dl_tl_flit_data[511:0]);
                    end
                    
                    tx_mon_data.ecc_err_q.push_back(2'b00);
                    ->get_data;
                end

            end // end for UNIT_SIM data collect
            //CHIP_SIM MODE
            else if(cfg_obj.sim_mode == tl_cfg_obj::CHIP_SIM) begin
                if(tl_dl_vif.tl_dl_flit_vld) begin
                    //ECC check
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
        
                    temp_data = tl_dl_vif.tl_dl_flit_data;
                    temp_ecc  = tl_dl_vif.tl_dl_flit_ecc;
                    ecc_check(temp_data, temp_ecc);
                    tx_mon_data.data_q.push_back(temp_data);
                    ->get_data;
                end
            end // end for UNIT_SIM data collect
            else begin
                `uvm_fatal(get_type_name(),"Unsupportted sim mode.");
            end
        end
    endtask : collect_data

    //Parity check function
    function void parity_check(bit [127:0] flit_data, bit [15:0] flit_pty);
        bit [15:0] flit_pty_check;
        for(int i=0; i<16; i++) begin
            flit_pty_check[i] = ^flit_data[(8*i + 7) -: 8];
            if(flit_pty_check[i] != flit_pty[i]) begin
                `uvm_fatal(get_type_name(), "Parity Check UE");
            end
        end
    endfunction

    //ECC check function
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
        for( bit_mask = 1<<31; bit_mask; ++bit_pos) begin
            if(qw0 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos]; 
            if(qw1 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos+32]; 

            if(qw2 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos]; 
            if(qw3 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos+32]; 
            bit_mask >>= 1;
        end

        //check ecc with input ecc
        ecc_syndrome_0 ^= ecc[15:8];
        ecc_syndrome_1 ^= ecc[7:0];

        if(ecc_syndrome_1 == 0) begin                                     //First 64bits
            bit [1:0] ecc_error = 2'b00;                                  //No error
            tx_mon_data.ecc_err_q.push_back(ecc_error);                   //For 8byte 
            tx_mon_cov_data.ecc_err_0 = 2'b00;
        end
        else begin
            bit bad_bit_found = 0;
            bad_bit = 0;
            while(!bad_bit_found && (bad_bit < 72)) begin
                if(ecc_syndrome_1 == ecc_pat[bad_bit]) bad_bit_found = 1;
                else bad_bit++;
            end

            if(!bad_bit_found) begin
                bit [1:0] ecc_error = 2'b11;                              //Uncorrectable Error
                tx_mon_data.ecc_err_q.push_back(ecc_error);               //For 8byte 
                tx_mon_cov_data.ecc_err_0 = 2'b11;
            end
            else begin
                bit [1:0] ecc_error = 2'b01;                              //Correctable Error
                tx_mon_data.ecc_err_q.push_back(ecc_error);               //For 8byte 
                tx_mon_cov_data.ecc_err_0 = 2'b01;
                if(bad_bit > 64) data[63:0] ^= 1'b1 << (63 - bad_bit);
                else ecc[7:0] ^= 1'b1 << (72 - bad_bit);
            end
        end

        if(ecc_syndrome_0 == 0) begin                                     //Second 64bits
            bit [1:0] ecc_error = 2'b00;                                  //No error
            tx_mon_data.ecc_err_q.push_back(ecc_error);                   //For 8byte 
            tx_mon_cov_data.ecc_err_1 = 2'b00;
        end
        else begin
            bit bad_bit_found = 0;
            bad_bit = 0;
            while(!bad_bit_found && (bad_bit < 72)) begin
                if(ecc_syndrome_0 == ecc_pat[bad_bit]) bad_bit_found = 1;
                else bad_bit++;
            end

            if(!bad_bit_found) begin
                bit [1:0] ecc_error = 2'b11;                              //Uncorrectable Error
                tx_mon_data.ecc_err_q.push_back(ecc_error);               //For 8byte 
                tx_mon_cov_data.ecc_err_1 = 2'b11;
            end
            else begin
                bit [1:0] ecc_error = 2'b01;                              //Correctable Error
                tx_mon_data.ecc_err_q.push_back(ecc_error);               //For 8byte 
                tx_mon_cov_data.ecc_err_1 = 2'b01;
                if(bad_bit > 64) data[127:64] ^= 1'b1 << (63 - bad_bit);
                else ecc[15:8] ^= 1'b1 << (72 - bad_bit);
            end
        end
    endfunction


    virtual task assemble_flit();
        forever begin
            @get_data;
            if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1) begin
                if((tx_mon_data.data_q.size != 0) && ((tx_mon_data.data_q.size)%4 == 0)) begin
                    bit [511:0] temp_flit;
                    for(int i = 0; i < 4; i++) begin
                        temp_flit[(127 + 128*i) -: 128] = tx_mon_data.data_q.pop_front;
                    end
                    tx_mon_data.flit_q.push_back(temp_flit);
                    ->get_flit;
                end
            end else if (cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                if(tx_mon_data.data_q.size != 0) begin
                    bit [511:0] temp_flit;
                    temp_flit[511:0] = tx_mon_data.data_q.pop_front;
                    tx_mon_data.flit_q.push_back(temp_flit);
                    ->get_flit;
                end
            end
        end
    endtask : assemble_flit
	
    virtual task parse_flit();
        forever begin

            bit          is_ctrl_flit;
            @get_flit;
    
            if(tx_mon_data.flit_q.size != 0) begin
                bit [511:0]    temp_flit;
                bit [447:0]    tl_content;
                bit [5:0]      tl_template;
    
                temp_flit = tx_mon_data.flit_q.pop_front;
    
                is_ctrl_flit = (tx_mon_data.flit_count == tx_mon_data.dRunLen);
                tx_mon_data.is_ctrl_flit = is_ctrl_flit;
                tx_mon_data.flit_count++;
    
                if(is_ctrl_flit) begin
                    bit [1:0]  temp_ecc_err;

                    //Check ECC error
                    for(int i=0; i<4; i++) begin
                        if(tx_mon_data.ecc_err_q[i] == 2'b11) begin
                            `uvm_fatal(get_type_name(), "ECC UE in Control Flit");
                        end
                    end

                    tx_mon_data.coll_ctrl_time = $realtime;
                    // wait 1 cycle for dl_tl_flit_error signal 
                    @(posedge tl_dl_vif.clock);
                    if(!tx_mon_data.flit_err) begin  // good control flit and issue the data prior to this control flit
                        tl_content = temp_flit[447:0];
                        tx_mon_data.dRunLen = temp_flit[451:448];
                        tx_mon_data.bad_data_flit = temp_flit[459:452];
                        tl_template = temp_flit[465:460];

                        if(coverage_on)
                            c_ocapi_tl_tx_flit.sample();

                        tx_mon_cov_data.template = tl_template;
    
                        issue_data_flit(tx_mon_data.bad_data_flit);
                        parse_tl_content(tl_content, tl_template);
                    end
                    else begin // bad control flit, discard the data & do not parse current control flit
                        discard_data_flit();
                    end
   
                    tx_mon_data.flit_count = 0;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                end
                // push data flit into data_carrier_q (push 8byte each)
                else begin
                    tx_mon_data.prefetch_data_flit_q.push_back(temp_flit);
                    //tx_mon_data.prefetch_bad_data_flit_q.push_back(tx_mon_data.bad_data_flit[tx_mon_data.flit_count - 1]);
                    
                    //if(tx_mon_data.bad_data_flit[tx_mon_data.flit_count - 1]) begin
                    //    `uvm_info("tl_tx_monitor",$sformatf("bad data flit is dectected"), UVM_MEDIUM);
                    //end
                end
            end
            else begin
                @(posedge tl_dl_vif.clock);
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

        while(tx_mon_data.prefetch_data_flit_q.size > 0) begin

                temp_flit = tx_mon_data.prefetch_data_flit_q.pop_front;
                temp_mdf = tx_mon_data.mdf_q.pop_front;
                tx_mon_cov_data.meta_data_bit = temp_mdf;
                temp_data_carrier_type = 64;
                //bad_data_flit = tx_mon_data.prefetch_bad_data_flit_q.pop_front;
                data_flit_err = bad_data_flit[data_flit_count];
                if(data_flit_err) begin
                    `uvm_info("tl_tx_monitor",$sformatf("bad data flit is dectected"), UVM_MEDIUM);
                end
                data_flit_count++;

                for(int i = 0; i < 8; i++) begin
                    tx_mon_data.data_carrier_q.push_back(temp_flit[(64*i+63) -:64]);
                        
                    data_err_type = {tx_mon_data.ecc_err_q.pop_front, data_flit_err};
                    tx_mon_data.xmeta_q.push_back({65'b0, temp_mdf});
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(temp_data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'hf);
                end
            end

            if(tx_mon_data.prefetch_data_flit_q.size == 0) begin
                `uvm_info("tl_tx_monitor", $sformatf("Prefetch Data Flit Queue is EMPTY."), UVM_HIGH);
            end
    endfunction

    function void discard_data_flit();
        bit [511:0] temp_flit;
        
        while(tx_mon_data.prefetch_data_flit_q.size > 0) begin
            temp_flit = tx_mon_data.prefetch_data_flit_q.pop_front;
        end

        if(tx_mon_data.prefetch_data_flit_q.size == 0) begin
            `uvm_info("tl_tx_monitor", $sformatf("Prefetch Data Flit Queue is EMPTY."), UVM_HIGH);
        end
    endfunction

	
    function void parse_tl_content(bit [447:0] tl_content, bit [5:0] tl_template);
        //Template Support Check
        if(~cfg_obj.tl_transmit_template[tl_template]) begin
            `uvm_error(get_type_name(), $sformatf("Unsupported Template Type, Template value is %h", tl_template));
        end

        tx_mon_cov_data.meta_data_enable = 0;
        //Parse template content
        case (tl_template)
            6'h0:
            begin
                //slot0 - slot1 : return_tlx_credits
                //slot4 - slot9 : 6-slot TL packet
                tx_mon_data.packet_q.push_back(tl_content[55:0]);
                tx_mon_data.packet_q.push_back(tl_content[279:112]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'h1:
            begin
                //slot0 -slot3 : 4-slot TL packet
                //slot4 -slot7 : 4-slot TL packet
                //slot8 -slot11 : 4-slot TL packet
                //slot12 -slot15 : 4-slot TL packet
                tx_mon_data.packet_q.push_back(tl_content[111:0]);
                tx_mon_data.packet_q.push_back(tl_content[223:112]);
                tx_mon_data.packet_q.push_back(tl_content[335:224]);
                tx_mon_data.packet_q.push_back(tl_content[447:336]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
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
                    tx_mon_data.packet_q.push_back(tl_content[((i+1)*56-1) -: 56]);
                    tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
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
                tx_mon_data.packet_q.push_back(tl_content[111 : 0]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                for (int i = 0; i < 2; i++) begin
                    tx_mon_data.packet_q.push_back(tl_content[((i+1)*168 + 112 - 1) -: 168]);
                    tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                end

                template_info_print(tl_template, tl_content);
                //for(int i=0; i<7; i++) begin
                //    bit [1:0]   temp_ecc_err;
                //    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                //end
            end

            6'h4:
            begin
                //slot0 - slot1 : 2-slot TL packet
                //slot2 : mdf(3) || mdf(2) || mdf(1) || mdf(0)
                //slot3 : mdf(7) || mdf(6) || mdf(5) || mdf(4)
                //slot4 -slot7 : 4-slot TL packet
                //slot8 -slot11 : 4-slot TL packet
                //slot12 -slot15 : 4-slot TL packet
                if(tx_mon_data.dRunLen != 0) begin
                    tx_mon_cov_data.meta_data_enable = 1;
                end
                else begin
                    tx_mon_cov_data.meta_data_enable = 0;
                end

                tx_mon_data.packet_q.push_back(tl_content[55:0]);
                for(int i = 0; i < tx_mon_data.dRunLen; i++) begin
                    tx_mon_data.mdf_q.push_back(tl_content[62+7*i -: 7]);
                end
                tx_mon_data.packet_q.push_back(tl_content[223:112]);
                tx_mon_data.packet_q.push_back(tl_content[335:224]);
                tx_mon_data.packet_q.push_back(tl_content[447:336]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                for(int i=0; i<7; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'h7:
            begin
                //slot0 - slot8 : Data(251:0)
                //slot9: mdf(1) || mdf(0) || R(0) || V(1:0) || meta(6:0) || Data(255:252)  32byte data carrier
                //slot10 - slot11 : 2-slot TL packet
                //slot12 -slot15 : 4-slot TL packet
                //V Check

                tx_mon_cov_data.slot_data_valid = tl_content[264:263];
                if(tl_content[264]) begin //data carrier valid V[1] == 1
                    bit [2:0]  data_err_type;
                    int        data_carrier_type;
                    bit [71:0] temp_xmeta;

                    data_err_type = {tx_mon_data.ecc_err_q.pop_front, tl_content[263]};
                    temp_xmeta = {65'b0, tl_content[262:256]};
                    data_carrier_type = 32;

                    tx_mon_data.data_carrier_q.push_back(tl_content[63:0]);
                    tx_mon_data.xmeta_q.push_back(temp_xmeta);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'h7);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[127:64]);
                    tx_mon_data.xmeta_q.push_back(temp_xmeta);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'h7);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[191:128]);
                    tx_mon_data.xmeta_q.push_back(temp_xmeta);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'h7);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[255:192]);
                    tx_mon_data.xmeta_q.push_back(temp_xmeta);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'h7);
                end
                //parse mdf & R & V
                for(int i = 0; i < tx_mon_data.dRunLen; i++) begin
                    tx_mon_data.mdf_q.push_back(tl_content[272+7*i -: 7]);
                end
                tx_mon_data.packet_q.push_back(tl_content[335:280]);
                tx_mon_data.packet_q.push_back(tl_content[447:336]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                
                if((tx_mon_data.dRunLen != 0) || tl_content[264]) begin
                    tx_mon_cov_data.meta_data_enable = 1;
                end
                else begin
                    tx_mon_cov_data.meta_data_enable = 0;
                end

                for(int i=0; i<3; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                end
            end

            6'ha:
            begin
                //slot0 - slot8 : Data(251:0)
                //slot9 : xmeta(23:0) || Data(255:252) 32byte data carrier [279:252]
                //slot10 : xmeta(51:24) [307:280]
                //slot11 : R(5:0) || V(1:0) || xmeta(71:52)
                //slot12 -slot15 : 4-slot TL packet
                //V Check

                if(tl_content[329]) begin //data carrier valid V[1] == 1
                    bit [2:0] data_err_type;
                    int       data_carrier_type;

                    data_err_type = {tx_mon_data.ecc_err_q.pop_front, tl_content[328]};
                    data_carrier_type = 32;

                    tx_mon_data.data_carrier_q.push_back(tl_content[63:0]);
                    tx_mon_data.xmeta_q.push_back(tl_content[327:256]);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'ha);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[127:64]);
                    tx_mon_data.xmeta_q.push_back(tl_content[327:256]);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'ha);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[191:128]);
                    tx_mon_data.xmeta_q.push_back(tl_content[327:256]);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'ha);
                    
                    tx_mon_data.data_carrier_q.push_back(tl_content[255:192]);
                    tx_mon_data.xmeta_q.push_back(tl_content[327:256]);
                    tx_mon_data.data_err_q.push_back(data_err_type);
                    tx_mon_data.data_carrier_type_q.push_back(data_carrier_type);
                    tx_mon_data.data_template_q.push_back(6'ha);
                end
                //parse R & V & xmeta
                
                tx_mon_data.packet_q.push_back(tl_content[447:336]);
                tx_mon_data.cmd_time_q.push_back(tx_mon_data.coll_ctrl_time);
                template_info_print(tl_template, tl_content);
                
                if(tl_content[329]) begin
                    tx_mon_cov_data.meta_data_enable = 1;
                end
                else begin
                    tx_mon_cov_data.meta_data_enable = 0;
                end

                for(int i=0; i<3; i++) begin
                    bit [1:0]   temp_ecc_err;
                    temp_ecc_err = tx_mon_data.ecc_err_q.pop_front;
                end
            end

            default:
            begin
                `uvm_fatal(get_type_name(), "UE:Unsupportted Template Type based on OCAPI profile.");
            end
        endcase
        if(coverage_on) begin
            c_ocapi_tl_tx_template.sample();
        end

    endfunction


    virtual task assemble_trans();
        forever begin
            @(posedge tl_dl_vif.clock);
            while(tx_mon_data.wait_packet_q.size != 0) begin
                bit [167:0] temp_packet;
                int break_flag;
                
                temp_packet   = tx_mon_data.wait_packet_q.pop_front;
                break_flag    = write_trans(temp_packet, 1'b1, 0);
                if(break_flag) break;
            end

            while(tx_mon_data.packet_q.size != 0) begin
                bit [167:0] temp_packet;
                int         is_data_cmd;
                real        temp_time;

                temp_packet   = tx_mon_data.packet_q.pop_front;
                temp_time     = tx_mon_data.cmd_time_q.pop_front;
                is_data_cmd   = identify_data_cmd(temp_packet[7:0]);


                if(is_data_cmd) begin
                    tx_mon_data.wait_packet_q.push_back(temp_packet);
                end
                else begin
                    void'(write_trans(temp_packet, 1'b0, temp_time));
                end
            end
        end
    endtask : assemble_trans

    function int identify_data_cmd( bit [7:0] packet_type );
        case(packet_type)
            tl_tx_trans::CONFIG_WRITE: return 1;
            tl_tx_trans::PR_WR_MEM:    return 1;
            tl_tx_trans::WRITE_MEM:    return 1;
            tl_tx_trans::WRITE_MEM_BE: return 1;
            default:                   return 0;
        endcase
    endfunction : identify_data_cmd
    
    function int write_trans( bit [167:0] packet, bit is_wait_q, real trans_time );
        tx_mon_trans = tl_tx_trans::type_id::create("tx_mon_trans", this); 
    
        tx_mon_cov_data.prev_packet_type = tx_mon_cov_data.packet_type;
        tx_mon_cov_data.packet_type      = tl_tx_trans::packet_type_enum'(packet[7:0]);
        tx_mon_cov_data.is_config        = 0;

        case(packet[7:0])
            tl_tx_trans::NOP:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::NOP;
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\t cmd=NOP"), UVM_MEDIUM);
            end
    
            tl_tx_trans::MEM_CNTL:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::MEM_CNTL;
                tx_mon_trans.cmd_flag      = packet[11:8];
                tx_mon_trans.object_handle = packet[91:28];
                tx_mon_trans.capp_tag      = packet[107:92];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=MEM_CNTL\tCappTag=%h", packet[107:92]), UVM_MEDIUM);
            end
    
            tl_tx_trans::CONFIG_READ:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::CONFIG_READ;
                tx_mon_trans.physical_addr = packet[91:28];
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.config_type   = packet[108];
                tx_mon_trans.plength       = packet[111:109];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=CONFIG_READ\tCappTag=%h \tphysical_addr=%h\tplength=%h", packet[107:92], packet[91:28], packet[111:109]), UVM_MEDIUM);

                tx_mon_cov_data.is_config  = 1;
                tx_mon_cov_data.cfg_reg_addr = packet[59:28];
                tx_mon_cov_data.cfg_device_number = packet[51:47];
                tx_mon_cov_data.cfg_function_number = packet[46:44];
                tx_mon_cov_data.cfg_type_bit = packet[108];
                tx_mon_cov_data.cfg_plength = packet[111:109];
                tx_mon_cov_data.cfg_pa_aligned = packet[29:28];
            end
    
            tl_tx_trans::CONFIG_WRITE:
            begin
                int        temp_data_carrier_type;
                real       tmp_time;
                
                tx_mon_cov_data.is_config  = 1;
                tx_mon_cov_data.cfg_reg_addr = packet[59:28];
                tx_mon_cov_data.cfg_device_number = packet[51:47];
                tx_mon_cov_data.cfg_function_number = packet[46:44];
                tx_mon_cov_data.cfg_type_bit = packet[108];
                tx_mon_cov_data.cfg_plength = packet[111:109];
                tx_mon_cov_data.cfg_pa_aligned = packet[29:28];

                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::CONFIG_WRITE;
                tx_mon_trans.physical_addr = packet[91:28];
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.config_type   = packet[108];
                tx_mon_trans.plength       = packet[111:109];

                if(tx_mon_data.data_carrier_type_q.size < 1) begin
                    if(is_wait_q) begin
                        tx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    tx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end

                temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;

                if(temp_data_carrier_type == 32) begin
                    if(tx_mon_data.data_carrier_q.size < 4) begin
                        if(is_wait_q) begin
                            tx_mon_data.wait_packet_q.push_front(packet);
                            tx_mon_data.data_carrier_type_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        tx_mon_data.wait_packet_q.push_back(packet);
                        return 0;
                    end

                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=CONFIG_WRITE \tCappTag=%h \tphysical_addr=%h \tplength=%h", packet[107:92], packet[91:28], packet[111:109]), UVM_MEDIUM);
                    for(int i = 0; i<4; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err; 
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = tx_mon_data.data_carrier_q.pop_front;
                        temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                        temp_err               = tx_mon_data.data_err_q.pop_front;
                        temp_template          = tx_mon_data.data_template_q.pop_front;

                        tx_mon_trans.data_carrier[i]   = temp_data;
                        tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                        tx_mon_trans.data_error[i]     = temp_err;
                        tx_mon_trans.data_carrier_type = 32;
                        tx_mon_trans.data_template     = temp_template;
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tCONFIG_WRITE data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                    end
                    
                    for(int i = 0; i<3; i++) begin
                        temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else if(temp_data_carrier_type == 64) begin
                    if(tx_mon_data.data_carrier_q.size < 8) begin
                        if(is_wait_q) begin
                            tx_mon_data.wait_packet_q.push_front(packet);
                            tx_mon_data.data_carrier_type_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        tx_mon_data.wait_packet_q.push_back(packet);
                        return 0;
                    end
                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=CONFIG_WRITE \tCappTag=%h \tphysical_addr=%h \tplength=%h", packet[107:92], packet[91:28], packet[111:109]), UVM_MEDIUM);

                    for(int i = 0; i < 8; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err; 
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = tx_mon_data.data_carrier_q.pop_front;
                        temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                        temp_err               = tx_mon_data.data_err_q.pop_front;
                        temp_template          = tx_mon_data.data_template_q.pop_front;

                        tx_mon_trans.data_carrier[i]   = temp_data;
                        tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                        tx_mon_trans.data_error[i]     = temp_err;
                        tx_mon_trans.data_carrier_type = 64;
                        tx_mon_trans.data_template     = temp_template;
                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tCONFIG_WRITE data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                    end
                    
                    for(int i = 0; i<7; i++) begin
                        temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else begin
                    `uvm_fatal("tl_tx_monitor", "UE: Unsupported Data Carrier Length Type Value.");
                end
                tmp_time                = $realtime;
                tx_mon_trans.time_stamp = tmp_time;
            end
                
            tl_tx_trans::READ_RESPONSE:
            begin
                real        tmp_time;
                if (tx_mon_data.data_carrier_q.size < (8*packet[27:26])) begin
                    if(is_wait_q) begin
                        tx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    tx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end
                else begin
                    tx_mon_trans.packet_type = tl_tx_trans::READ_RESPONSE;
                    tx_mon_trans.is_cmd      = 0;
                    tx_mon_trans.afu_tag     = packet[23:8];
                    tx_mon_trans.dpart       = packet[25:24];
                    tx_mon_trans.dlength     = packet[27:26];
                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\t cmd=READ_RESPONSE\tafu_tag=%h\tdL=%h", packet[23:8], packet[27:26]), UVM_MEDIUM);

                    for(int i=0; i<8*packet[27:26]; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err;
                        bit [71:0] temp_xmeta;
                        int        temp_data_carrier_type;
                        bit [5:0]  temp_template;

                        temp_data              = tx_mon_data.data_carrier_q.pop_front;
                        temp_err               = tx_mon_data.data_err_q.pop_front;
                        temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                        temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                        temp_template          = tx_mon_data.data_template_q.pop_front;

                        tx_mon_trans.data_carrier[i]   = temp_data;
                        tx_mon_trans.data_error[i]     = temp_err;

                        if(temp_template == 6'hb) begin
                            tx_mon_trans.xmeta[i]          = temp_xmeta;
                        end
                        else begin
                            tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                        end
                                
                        tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                        tx_mon_trans.data_template     = temp_template;
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tREAD_RESPONSE data \tAFUTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[23:8], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end
                end
                tmp_time                 = $realtime;
                tx_mon_trans.time_stamp = tmp_time;
            end
            
            tl_tx_trans::WRITE_RESPONSE:
            begin
                tx_mon_trans.time_stamp  = trans_time;
                tx_mon_trans.packet_type = tl_tx_trans::WRITE_RESPONSE;
                tx_mon_trans.is_cmd      = 0;
                tx_mon_trans.afu_tag     = packet[23:8];
                tx_mon_trans.dpart       = packet[25:24];
                tx_mon_trans.dlength     = packet[27:26];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\t cmd=WRITE_RESPONSE\tafu_tag=%h\tdL=%h", packet[23:8], packet[27:26]), UVM_MEDIUM);
            end

            tl_tx_trans::READ_FAILED:
            begin
                tx_mon_trans.time_stamp  = trans_time;
                tx_mon_trans.packet_type = tl_tx_trans::READ_FAILED;
                tx_mon_trans.is_cmd      = 0;
                tx_mon_trans.afu_tag     = packet[23:8];
                tx_mon_trans.dpart       = packet[25:24];
                tx_mon_trans.dlength     = packet[27:26];
                tx_mon_trans.resp_code   = packet[55:52];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\t cmd=READ_FAILED\tafu_tag=%h\tdL=%h\tresp_code=%h", packet[23:8], packet[27:26], packet[55:52]),
                    UVM_MEDIUM);
            end

            tl_tx_trans::WRITE_FAILED:
            begin
                tx_mon_trans.time_stamp  = trans_time;
                tx_mon_trans.packet_type = tl_tx_trans::WRITE_FAILED;
                tx_mon_trans.is_cmd      = 0;
                tx_mon_trans.afu_tag     = packet[23:8];
                tx_mon_trans.dpart       = packet[25:24];
                tx_mon_trans.dlength     = packet[27:26];
                tx_mon_trans.resp_code   = packet[55:52];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\t cmd=WRITE_FAILED\tafu_tag=%h\tdL=%h\tresp_code=%h", packet[23:8], packet[27:26], packet[55:52]),
                    UVM_MEDIUM);
            end

            tl_tx_trans::XLATE_DONE:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::XLATE_DONE;
                tx_mon_trans.afu_tag       = packet[23:8];
                tx_mon_trans.resp_code     = packet[55:52];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=XLATE_DONE\tAFUTag=%h \tresp_code=%h", packet[23:8], packet[55:52]), UVM_MEDIUM);
            end
 
            tl_tx_trans::INTRP_RDY:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;                     // Not sure for this cmd
                tx_mon_trans.packet_type   = tl_tx_trans::INTRP_RDY;
                tx_mon_trans.afu_tag       = packet[23:8];
                tx_mon_trans.resp_code     = packet[55:52];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=INTRP_RDY\tAFUTag=%h \tresp_code=%h", packet[23:8], packet[55:52]), UVM_MEDIUM);
            end
    
            tl_tx_trans::PAD_MEM:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::PAD_MEM;
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.physical_addr = {packet[91:33], 5'b00000};
                tx_mon_trans.dlength       = packet[111:110];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=PAD_MEM\tCappTag=%h \tdlength=%h", packet[107:92], packet[111:110]), UVM_MEDIUM);
            end
    
            tl_tx_trans::PR_RD_MEM:
            begin
                bit [63:0]    tmp_addr;

                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::PR_RD_MEM;
                tx_mon_trans.physical_addr = packet[91:28];
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.plength       = packet[111:109];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=PR_RD_MEM\tCappTag=%h \tphysical_addr=%h\tplength=%h", packet[107:92], packet[91:28], packet[111:109]), UVM_MEDIUM);

                tmp_addr                         = packet[91:28] - cfg_obj.mmio_space_base;
                if(is_in_mscc_space(tmp_addr))begin
                    tx_mon_cov_data.is_inside_mscc   = 1;
                    tx_mon_cov_data.pr_physical_addr = tmp_addr[31:0];
                    tx_mon_cov_data.pa               = tx_mon_trans.physical_addr[2:0];
                    if((tmp_addr >= cfg_obj.mscc_space_lower[`MSCC_RAM_INDEX_1]) && (tmp_addr <= cfg_obj.mscc_space_upper[`MSCC_RAM_INDEX_1]))begin
                        tx_mon_cov_data.is_inside_msccrnge = 1;
                    end
                    else begin
                        tx_mon_cov_data.is_inside_msccrnge = 0;
                    end
                end
                else begin
                    if((tmp_addr == `MMIO_SENSOR_CACHE_ADDR1) || (tmp_addr == `MMIO_SENSOR_CACHE_ADDR2))begin
                        tx_mon_cov_data.is_sensor_cache = 1;
                    end
                    else begin
                        tx_mon_cov_data.is_sensor_cache = 0;
                    end
                    tx_mon_cov_data.is_inside_mscc   = 0;
                    tmp_addr                         = tmp_addr>>3;
                    tx_mon_cov_data.pr_physical_addr = tmp_addr[31:0];
                    tx_mon_cov_data.pa               = tx_mon_trans.physical_addr[2:0];
                end
            end
    
            tl_tx_trans::PR_WR_MEM:
            begin
                int           temp_data_carrier_type;
                bit [63:0]    tmp_addr;
                real          tmp_time;
                
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::PR_WR_MEM;
                tx_mon_trans.physical_addr = packet[91:28];
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.plength       = packet[111:109];
    
                tmp_addr                         = packet[91:28] - cfg_obj.mmio_space_base;
                if(is_in_mscc_space(tmp_addr))begin
                    tx_mon_cov_data.is_inside_mscc   = 1;
                    tx_mon_cov_data.pr_physical_addr = tmp_addr[31:0];
                    tx_mon_cov_data.pa               = tx_mon_trans.physical_addr[2:0];
                    if((tmp_addr >= cfg_obj.mscc_space_lower[`MSCC_RAM_INDEX_1]) && (tmp_addr <= cfg_obj.mscc_space_upper[`MSCC_RAM_INDEX_1]))begin
                        tx_mon_cov_data.is_inside_msccrnge = 1;
                    end
                    else begin
                        tx_mon_cov_data.is_inside_msccrnge = 0;
                    end
                end
                else begin
                    if((tmp_addr == `MMIO_SENSOR_CACHE_ADDR1) || (tmp_addr == `MMIO_SENSOR_CACHE_ADDR2))begin
                        tx_mon_cov_data.is_sensor_cache = 1;
                    end
                    else begin
                        tx_mon_cov_data.is_sensor_cache = 0;
                    end
                    tx_mon_cov_data.is_inside_mscc   = 0;
                    tmp_addr                         = tmp_addr>>3;
                    tx_mon_cov_data.pr_physical_addr = tmp_addr[31:0];
                    tx_mon_cov_data.pa               = tx_mon_trans.physical_addr[2:0];
                end

                if(tx_mon_data.data_carrier_type_q.size < 1) begin
                    if(is_wait_q) begin
                        tx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    tx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end
                temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;

                if(temp_data_carrier_type == 32) begin
                    if(tx_mon_data.data_carrier_q.size < 4) begin
                        if(is_wait_q) begin
                            tx_mon_data.wait_packet_q.push_front(packet);
                            tx_mon_data.data_carrier_type_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        tx_mon_data.wait_packet_q.push_back(packet);
                        return 0;
                    end
                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=PR_WR_MEM \tCappTag=%h \tphysical_addr=%h \tplength=%h", packet[107:92], packet[91:28], packet[111:109]), UVM_MEDIUM);

                    for(int i = 0; i<4; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err; 
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = tx_mon_data.data_carrier_q.pop_front;
                        temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                        temp_err               = tx_mon_data.data_err_q.pop_front;
                        temp_template          = tx_mon_data.data_template_q.pop_front;

                        tx_mon_trans.data_carrier[i]   = temp_data;
                        if(temp_template == 6'hA) begin
                            tx_mon_trans.xmeta[i]      = temp_xmeta;
                        end
                        else begin
                            tx_mon_trans.meta[i]       = temp_xmeta[6:0];
                        end
                        tx_mon_trans.data_error[i]     = temp_err;
                        tx_mon_trans.data_carrier_type = 32;
                        tx_mon_trans.data_template     = temp_template;
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tPR_WR_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end
                    
                    for(int i = 0; i<3; i++) begin
                        temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else if(temp_data_carrier_type == 64) begin
                    if(tx_mon_data.data_carrier_q.size < 8) begin
                        if(is_wait_q) begin
                            tx_mon_data.wait_packet_q.push_front(packet);
                            tx_mon_data.data_carrier_type_q.push_front(temp_data_carrier_type);
                            return 1;
                        end
                        tx_mon_data.wait_packet_q.push_back(packet);
                        return 0;
                    end

                    for(int i = 0; i < 8; i++) begin
                        bit [63:0] temp_data;
                        bit [2:0]  temp_err; 
                        bit [71:0] temp_xmeta;
                        bit [5:0]  temp_template;

                        temp_data              = tx_mon_data.data_carrier_q.pop_front;
                        temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                        temp_err               = tx_mon_data.data_err_q.pop_front;
                        temp_template          = tx_mon_data.data_template_q.pop_front;

                        tx_mon_trans.data_carrier[i]   = temp_data;
                        if(temp_template == 6'hA) begin
                            tx_mon_trans.xmeta[i]      = temp_xmeta;
                        end
                        else begin
                            tx_mon_trans.meta[i]       = temp_xmeta[6:0];
                        end
                        tx_mon_trans.data_error[i]     = temp_err;
                        tx_mon_trans.data_carrier_type = 64;
                        tx_mon_trans.data_template     = temp_template;
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tPR_WR_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\txmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta, temp_template), UVM_MEDIUM);
                    end
                    
                    for(int i = 0; i<7; i++) begin
                        temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                    end
                end
                else begin
                    `uvm_fatal("tl_tx_monitor", "UE: Unsupported Data Carrier Length Type Value.");
                end
                tmp_time                = $realtime;
                tx_mon_trans.time_stamp = tmp_time;
            end
    
            tl_tx_trans::RD_MEM:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::RD_MEM;
                tx_mon_trans.mad           = {packet[31:28], packet[11:8]};
                tx_mon_trans.physical_addr = {packet[91:33], 5'b00000};
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.dlength       = packet[111:110];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=RD_MEM \tCappTag=%h \tphysical_addr=%h \tdlength=%h", packet[107:92], {packet[91:33], 5'b00000}, packet[111:110]), UVM_MEDIUM);
            end
    
            tl_tx_trans::WRITE_MEM:
            begin
                real         tmp_time;

                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::WRITE_MEM;
                tx_mon_trans.physical_addr = {packet[91:34], 6'b000000};
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.dlength       = packet[111:110];
                
                case(packet[111:110])
                    2'b01:
                    begin
                        if(tx_mon_data.data_carrier_q.size < 8) begin
                            if(is_wait_q) begin
                                tx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            tx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=WRITE_MEM \tCappTag=%h \tphysical_addr=%h \tdlength=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 8; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = tx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                            temp_err               = tx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = tx_mon_data.data_template_q.pop_front;

                            tx_mon_trans.data_carrier[i]   = temp_data;
                            tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                            tx_mon_trans.data_error[i]     = temp_err;
                            tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                            tx_mon_trans.data_template     = temp_template;
                            `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tWRITE_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b10:
                    begin
                        if(tx_mon_data.data_carrier_q.size < 16) begin
                            if(is_wait_q) begin
                                tx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            tx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=WRITE_MEM \tCappTag=%h \tphysical_addr=%h \tdlength=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 16; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = tx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                            temp_err               = tx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = tx_mon_data.data_template_q.pop_front;

                            tx_mon_trans.data_carrier[i]   = temp_data;
                            tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                            tx_mon_trans.data_error[i]     = temp_err;
                            tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                            tx_mon_trans.data_template     = temp_template;
                            `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tWRITE_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b11:
                    begin
                        if(tx_mon_data.data_carrier_q.size < 32) begin
                            if(is_wait_q) begin
                                tx_mon_data.wait_packet_q.push_front(packet);
                                return 1;
                            end
                            tx_mon_data.wait_packet_q.push_back(packet);
                            return 0;
                        end
                        `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=WRITE_MEM \tCappTag=%h \tphysical_addr=%h \tdlength=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                        for(int i = 0; i < 32; i++) begin
                            bit [63:0] temp_data;
                            bit [71:0] temp_xmeta;
                            bit [2:0]  temp_err; 
                            int        temp_data_carrier_type;
                            bit [5:0]  temp_template;
    
                            temp_data              = tx_mon_data.data_carrier_q.pop_front;
                            temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                            temp_err               = tx_mon_data.data_err_q.pop_front;
                            temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                            temp_template          = tx_mon_data.data_template_q.pop_front;

                            tx_mon_trans.data_carrier[i]   = temp_data;
                            tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                            tx_mon_trans.data_error[i]     = temp_err;
                            tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                            tx_mon_trans.data_template     = temp_template;
                            `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tWRITE_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                        end
                    end
    
                    2'b00:
                    begin
                        if( (cfg_obj.inject_err_enable == 1) /*&& (cfg_obj.inject_err_type == tl_cfg_obj::BAD_LENGTH_ADDR)*/ ) begin
                            if(tx_mon_data.data_carrier_q.size < 4) begin
                                if(is_wait_q) begin
                                    tx_mon_data.wait_packet_q.push_front(packet);
                                    return 1;
                                end
                                tx_mon_data.wait_packet_q.push_back(packet);
                                return 0;
                            end
                            `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=WRITE_MEM \tCappTag=%h \tphysical_addr=%h \tdlength=%h", packet[107:92], {packet[91:34], 6'b000000}, packet[111:110]), UVM_MEDIUM);

                            for(int i = 0; i < 4; i++) begin
                                bit [63:0] temp_data;
                                bit [71:0] temp_xmeta;
                                bit [2:0]  temp_err; 
                                int        temp_data_carrier_type;
                                bit [5:0]  temp_template;
    
                                temp_data              = tx_mon_data.data_carrier_q.pop_front;
                                temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                                temp_err               = tx_mon_data.data_err_q.pop_front;
                                temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                                temp_template          = tx_mon_data.data_template_q.pop_front;

                                tx_mon_trans.data_carrier[i]   = temp_data;
                                tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                                tx_mon_trans.data_error[i]     = temp_err;
                                tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                                tx_mon_trans.data_template     = temp_template;
                                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tWRITE_MEM data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                            end
                        end
                        else begin
                            `uvm_fatal("tl_tx_monitor", "UE:Unsupportted Data Length Field.");
                        end
                    end
                endcase
                tmp_time                = $realtime;
                tx_mon_trans.time_stamp = tmp_time;
            end
    
            tl_tx_trans::WRITE_MEM_BE:
            begin
                real         tmp_time;

                tx_mon_trans.is_cmd        = 1;
                tx_mon_trans.packet_type   = tl_tx_trans::WRITE_MEM_BE;
                tx_mon_trans.physical_addr = {packet[91:34], 6'b000000};
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.byte_enable   = {packet[167:108], packet[31:28]};
                
                if(tx_mon_data.data_carrier_q.size < 8) begin
                    if(is_wait_q) begin
                        tx_mon_data.wait_packet_q.push_front(packet);
                        return 1;
                    end
                    tx_mon_data.wait_packet_q.push_back(packet);
                    return 0;
                end

                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=WRITE_MEM_BE \tCappTag=%h \tphysical_addr=%h", packet[107:92], {packet[91:34], 6'b000000}), UVM_MEDIUM);

                for(int i = 0; i < 8; i++) begin
                    bit [63:0] temp_data;
                    bit [71:0] temp_xmeta;
                    bit [2:0]  temp_err; 
                    int        temp_data_carrier_type;
                    bit [5:0]  temp_template;
    
                    temp_data              = tx_mon_data.data_carrier_q.pop_front;
                    temp_xmeta             = tx_mon_data.xmeta_q.pop_front;
                    temp_err               = tx_mon_data.data_err_q.pop_front;
                    temp_data_carrier_type = tx_mon_data.data_carrier_type_q.pop_front;
                    temp_template          = tx_mon_data.data_template_q.pop_front;

                    tx_mon_trans.data_carrier[i]   = temp_data;
                    tx_mon_trans.meta[i]           = temp_xmeta[6:0];
                    tx_mon_trans.data_error[i]     = temp_err;
                    tx_mon_trans.data_carrier_type = temp_data_carrier_type;
                    tx_mon_trans.data_template     = temp_template;
                    `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tWRITE_MEM_BE data \tCappTag=%h \toffset=%3d\tdat(63:0)=%h\terror_bit=%b\tmeta=%h\tdata_template=%h", packet[107:92], i, temp_data, temp_err, temp_xmeta[6:0], temp_template), UVM_MEDIUM);
                end
                tmp_time                = $realtime;
                tx_mon_trans.time_stamp = tmp_time;
            end
    
            tl_tx_trans::INTRP_RESP:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 0;                    
                tx_mon_trans.packet_type   = tl_tx_trans::INTRP_RESP;
                tx_mon_trans.afu_tag       = packet[23:8];
                tx_mon_trans.resp_code     = packet[55:52];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=INTRP_RESP\tAFUTag=%h \tresp_code=%h", packet[23:8], packet[55:52]), UVM_MEDIUM);
            end
    
            tl_tx_trans::RETURN_TLX_CREDITS:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 0;                    
                tx_mon_trans.packet_type   = tl_tx_trans::RETURN_TLX_CREDITS;
                tx_mon_trans.tlx_vc_0      = packet[11:8];
                tx_mon_trans.tlx_vc_3      = packet[23:20];
                tx_mon_trans.tlx_dcp_0     = packet[37:32];
                tx_mon_trans.tlx_dcp_3     = packet[55:50];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=RETURN_TLX_CREDITS\ttlx_vc_0=%h\ttlx_vc_3=%h\ttlx_dcp_0=%h\ttlx_dcp_3=%h", packet[11:8], packet[23:20], packet[37:32], packet[55:50]), UVM_MEDIUM);
            end
    
            tl_tx_trans::RD_PF:
            begin
                tx_mon_trans.time_stamp    = trans_time;
                tx_mon_trans.is_cmd        = 1;                    
                tx_mon_trans.packet_type   = tl_tx_trans::RD_PF;
                tx_mon_trans.mad           = {packet[31:28], packet[11:8]};
                tx_mon_trans.physical_addr = {packet[91:33], 5'b00000};
                tx_mon_trans.capp_tag      = packet[107:92];
                tx_mon_trans.dlength       = packet[111:110];
                `uvm_info("tl_tx_monitor", $sformatf("TX Trans Info:\tcmd=RD_PF\tmad=%h\tphysical_addr=%h\tcapp_tag=%h\tdlength=%h", {packet[31:28],packet[11:8]}, {packet[91:33], 5'b00000}, packet[107:92], packet[111:110]), UVM_MEDIUM);
            end
    
            // TODO: add 3.0 commands, dma_wr and rd_wnitc
            
            default:
            begin
                `uvm_fatal("tl_tx_monitor", "Unsupported packet");
            end
        endcase
        //$timeformat(-9,3,"ns",15);
        //tx_mon_trans.time_stamp = $realtime;

        tx_mon_cov_data.template_packet = tx_mon_cov_data.template_packet_q.pop_front;
        if(coverage_on) begin
            c_ocapi_tl_tx_trans.sample();
            c_ocapi_tl_tx_packet.sample();
        end

        `uvm_info("tl_tx_monitor", $sformatf("%s", tx_mon_trans.sprint()), UVM_MEDIUM);
        tl_tx_trans_ap.write(tx_mon_trans);
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

                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 2 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);

                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_0[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_1[7:0]});
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

                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 4 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
                packet_info_print(packet_3);

                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_0[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_1[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_2[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_3[7:0]});
            end

            6'h2:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 8 command packets:", tl_template), UVM_MEDIUM);

                for (int i = 0; i < 8; i++) begin
                    bit [55:0] packet;
                    packet = tl_content[(i+1)*2 - 1 -: 56];

                    packet_info_print(packet);
                    tx_mon_cov_data.template_packet_q.push_back({tl_template, packet[7:0]});
                end
            end

            6'h3:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 3 command packets:", tl_template), UVM_MEDIUM);

                for (int i = 0; i < 1; i++) begin
                    bit [112 : 0] packet = tl_content[111 : 0];
                    packet_info_print(packet);
                    tx_mon_cov_data.template_packet_q.push_back({tl_template, packet[7:0]});
                end

                for (int i = 0; i < 2; i++) begin
                    bit [168 : 0] packet = tl_content[((i+1)*168 + 112 - 1) -: 168];
                    packet_info_print(packet);
                    tx_mon_cov_data.template_packet_q.push_back({tl_template, packet[7:0]});
                end

            end

            6'h4:
            begin
                bit [55:0]  packet_0;
                bit [111:0] packet_1;
                bit [111:0] packet_2;
                bit [111:0] packet_3;

                packet_0 = tl_content[55:0];
                packet_1 = tl_content[223:112];
                packet_2 = tl_content[335:224];
                packet_3 = tl_content[447:336];

                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 4 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);
                packet_info_print(packet_2);
                packet_info_print(packet_3);

                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_0[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_1[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_2[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_3[7:0]});
            end

            6'h7:
            begin
                bit [55:0]  packet_0;
                bit [111:0] packet_1;

                packet_0 = tl_content[335:280];
                packet_1 = tl_content[447:336];

                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 2 command packets:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);
                packet_info_print(packet_1);

                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_0[7:0]});
                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_1[7:0]});
            end

            6'ha:
            begin
                bit [111:0]  packet_0;

                packet_0 = tl_content[447:336];

                `uvm_info("tl_tx_monitor", $sformatf("Template Info: The template type value is %h. \tThis template has 1 command packet:", tl_template), UVM_MEDIUM);
                packet_info_print(packet_0);

                tx_mon_cov_data.template_packet_q.push_back({tl_template, packet_0[7:0]});
            end
        endcase

        //if(coverage_on)
        //    c_ocapi_tl_tx_packet.sample();

    endfunction

    function void packet_info_print( bit [167:0] packet );

        case(packet[7:0])
            tl_tx_trans::NOP:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : NOP"), UVM_MEDIUM);
            end

            tl_tx_trans::MEM_CNTL:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : MEM_CNTL\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::CONFIG_READ:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : CONFIG_READ\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::CONFIG_WRITE:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : CONFIG_WRITE\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::INTRP_RDY:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : INTRP_RDY\tAFUTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_tx_trans::PAD_MEM:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : PAD_MEM\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::PR_RD_MEM:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : PR_RD_MEM\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::PR_WR_MEM:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : PR_WR_MEM\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::RD_MEM:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : RD_MEM\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::WRITE_MEM:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : WRITE_MEM\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::WRITE_MEM_BE:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : WRITE_MEM_BE\tCappTag : %h", packet[107:92]), UVM_MEDIUM);
            end

            tl_tx_trans::INTRP_RESP:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : INTRP_RESPONSE\tAFUTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_tx_trans::RETURN_TLX_CREDITS:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : RETURN_TLX_CREDITS"), UVM_MEDIUM);
            end
            
            tl_tx_trans::READ_RESPONSE:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : READ_RESPONSE\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_tx_trans::READ_FAILED:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : READ_FAILED\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_tx_trans::WRITE_RESPONSE:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : WRITE_RESPONSE\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end

            tl_tx_trans::WRITE_FAILED:
            begin
                `uvm_info("tl_tx_monitor", $sformatf("Packet Command Type : WRITE_FAILED\tCappTag : %h", packet[23:8]), UVM_MEDIUM);
            end
            
        endcase
    endfunction

    function bit is_in_mscc_space(bit [63:0] addr);
        bit in_mscc_space=0;
        for(int i=0; i<18; i++) begin
            if((addr>=cfg_obj.mscc_space_lower[i])&&(addr<=cfg_obj.mscc_space_upper[i])) begin
                in_mscc_space=1;
                break;
            end
        end
        return in_mscc_space;
    endfunction

endclass: tl_tx_monitor

`endif
