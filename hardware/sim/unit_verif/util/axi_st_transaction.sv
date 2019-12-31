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
// CLASS: axi_st_transaction
//
//------------------------------------------------------------------------------
`ifndef AXI_ST_TRANSACTION_SV
`define AXI_ST_TRANSACTION_SV


class axi_st_transaction extends uvm_sequence_item;

    typedef enum bit { H2A, A2H } uvm_axi_txn_e;

    rand bit [1023:0]         data;
    rand bit [127:0]          tkeep;
    rand bit [4:0]            tid;
    rand bit [8:0]            tuser;
    rand bit                  tlast;
    rand uvm_axi_txn_e        trans;

    `uvm_object_utils_begin(axi_st_transaction)
        `uvm_field_int             (data,                 UVM_ALL_ON)
        `uvm_field_int             (tkeep,                UVM_ALL_ON)
        `uvm_field_int             (tid,                  UVM_ALL_ON)        
        `uvm_field_int             (tuser,                UVM_ALL_ON)
        `uvm_field_int             (tlast,                UVM_ALL_ON)
        `uvm_field_enum            (uvm_axi_txn_e, trans, UVM_ALL_ON)        
    `uvm_object_utils_end

    // new - constructor
    function new (string name = "axi_st_transaction_inst");
        super.new(name);
    endfunction : new

endclass : axi_st_transaction

`endif

