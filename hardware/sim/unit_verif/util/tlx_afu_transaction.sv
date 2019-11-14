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
// CLASS: tlx_afu_transaction
//
//------------------------------------------------------------------------------
`ifndef TLX_AFU_TRANSACTION_SV
`define TLX_AFU_TRANSACTION_SV


class tlx_afu_transaction extends uvm_sequence_item;

    typedef enum bit [7:0] {
        TOUCH_RESP             =8'b0000_0010,
        READ_RESPONSE          =8'b0000_0100,
        READ_FAILED            =8'b0000_0101,
        WRITE_RESPONSE         =8'b0000_1000,
        WRITE_FAILED           =8'b0000_1001,
        INTRP_RESP             =8'b0000_1100,
        WAKE_HOST_RESP         =8'b0001_0000,
        XLATE_DONE             =8'b0001_1000,
        INTRP_RDY              =8'b0001_1010,
        RD_MEM                 =8'b0010_0000,
        PR_RD_MEM              =8'b0010_1000,
        WRITE_MEM              =8'b1000_0001,
        PR_WR_MEM              =8'b1000_0110,
        WRITE_MEM_BE           =8'b1000_0010
        } tlx_afu_enum;

    // TLX to AFU Cmd/Resp operand
    bit           [7:0] tlx_afu_opcode;
    bit          [15:0] tlx_afu_afutag;
    bit          [15:0] tlx_afu_capptag;
    bit          [63:0] tlx_afu_addr;
    bit           [1:0] tlx_afu_dl;
    bit           [2:0] tlx_afu_pl;
    bit           [1:0] tlx_afu_dp;
    bit          [63:0] tlx_afu_be;
    bit           [3:0] tlx_afu_resp_code;
    bit          [11:0] tlx_afu_actag;
    bit           [3:0] tlx_afu_stream_id;
    bit          [15:0] tlx_afu_bdf;
    bit          [19:0] tlx_afu_pasid;
    bit           [5:0] tlx_afu_pg_size;
    bit          [23:0] tlx_afu_resp_host_tag;
    bit          [17:0] tlx_afu_resp_addr_tag;
    bit           [3:0] tlx_afu_resp_cache_state;

    // TLX to AFU Cmd/Resp Data
    bit         [511:0] tlx_afu_data_bus[4];
    bit                 tlx_afu_data_bdi[4];

    tlx_afu_enum tlx_afu_type;

    `uvm_object_utils_begin(tlx_afu_transaction)
        `uvm_field_enum             (tlx_afu_enum, tlx_afu_type,      UVM_ALL_ON)
        `uvm_field_int              (tlx_afu_opcode,                  UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_afutag,                  UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_capptag,                 UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_addr,                    UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_dl,                      UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_pl,                      UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_dp,                      UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_be,                      UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_resp_code,               UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_actag,                   UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_stream_id,               UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_bdf,                     UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_pasid,                   UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_pg_size,                 UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_resp_host_tag,           UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_resp_addr_tag,           UVM_DEFAULT)
        `uvm_field_int              (tlx_afu_resp_cache_state,        UVM_DEFAULT)
        `uvm_field_sarray_int       (tlx_afu_data_bus,                UVM_DEFAULT)
        `uvm_field_sarray_int       (tlx_afu_data_bdi,                UVM_DEFAULT)
    `uvm_object_utils_end

    // new - constructor
    function new (string name = "tlx_afu_transaction_inst");
        super.new(name);
    endfunction : new

endclass : tlx_afu_transaction

`endif
