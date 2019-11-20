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
// CLASS: afu_tlx_transaction
//
//------------------------------------------------------------------------------
`ifndef AFU_TLX_TRANSACTION_SV
`define AFU_TLX_TRANSACTION_SV


class afu_tlx_transaction extends uvm_sequence_item;

    typedef enum bit [7:0] {
        MEM_RD_RESPONSE        =8'b0000_0001,
        MEM_RD_FAIL            =8'b0000_0010,
        MEM_RD_RESPONSE_OW     =8'b0000_0011,
        MEM_WR_RESPONSE        =8'b0000_0100,
        MEM_WR_FAIL            =8'b0000_0101,
        MEM_RD_RESPONSE_XW     =8'b0000_0111,
        RD_WNITC               =8'b0001_0000,
        PR_RD_WNITC            =8'b0001_0010,
        RD_WNITC_N             =8'b0001_0100,
        PR_RD_WNITC_N          =8'b0001_0110,
        DMA_W                  =8'b0010_0000,
        DMA_W_N                =8'b0010_0100,
        DMA_W_BE               =8'b0010_1000,
        DMA_W_BE_N             =8'b0010_1100,
        DMA_PR_W               =8'b0011_0000,
        DMA_PR_W_N             =8'b0011_0100,
        ASSIGN_ACTAG           =8'b0101_0000,
        INTRP_REQ              =8'b0101_1000,
        INTRP_REQ_D            =8'b0101_1010,
        WAKE_HOST_THREAD       =8'b0101_1100,
        XLATE_TOUCH            =8'b0111_1000,
        XLATE_TOUCH_N          =8'b0111_1100
        } afu_tlx_enum;

    // AFU to TLX Cmd/Resp operand
    bit           [7:0] afu_tlx_opcode;
    bit          [15:0] afu_tlx_afutag;
    bit          [15:0] afu_tlx_capptag;
    bit          [63:0] afu_tlx_addr;
    bit           [1:0] afu_tlx_dl;
    bit           [2:0] afu_tlx_pl;
    bit           [1:0] afu_tlx_dp;
    bit          [63:0] afu_tlx_be;
    bit           [3:0] afu_tlx_resp_code;
    bit          [11:0] afu_tlx_actag;
    bit           [3:0] afu_tlx_stream_id;
    bit          [15:0] afu_tlx_bdf;
    bit          [19:0] afu_tlx_pasid;
    bit           [5:0] afu_tlx_pg_size;

    // AFU to TLX Cmd/Resp Data
    bit         [511:0] afu_tlx_data_bus[4];
    bit                 afu_tlx_data_bdi[4];

    afu_tlx_enum afu_tlx_type;

    `uvm_object_utils_begin(afu_tlx_transaction)
        `uvm_field_enum             (afu_tlx_enum, afu_tlx_type,      UVM_ALL_ON)
        `uvm_field_int              (afu_tlx_opcode,                  UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_afutag,                  UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_capptag,                 UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_addr,                    UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_dl,                      UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_pl,                      UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_dp,                      UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_be,                      UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_resp_code,               UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_actag,                   UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_stream_id,               UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_bdf,                     UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_pasid,                   UVM_DEFAULT)
        `uvm_field_int              (afu_tlx_pg_size,                 UVM_DEFAULT)
        `uvm_field_sarray_int       (afu_tlx_data_bus,                UVM_DEFAULT)
        `uvm_field_sarray_int       (afu_tlx_data_bdi,                UVM_DEFAULT)
    `uvm_object_utils_end

    // new - constructor
    function new (string name = "afu_tlx_transaction_inst");
        super.new(name);
    endfunction : new

endclass : afu_tlx_transaction

`endif
