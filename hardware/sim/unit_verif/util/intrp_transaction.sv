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
// CLASS: intrp_transaction
//
//------------------------------------------------------------------------------
`ifndef INTRP_TRANSACTION_SV
`define INTRP_TRANSACTION_SV


class intrp_transaction extends uvm_sequence_item;

    typedef enum bit { INTRP_REQ, INTRP_ACK } uvm_intrp_txn;

    rand bit [63:0]           intrp_src;
    rand bit [8:0]            intrp_ctx;
    rand uvm_intrp_txn        intrp_item;

    `uvm_object_utils_begin(intrp_transaction)
        `uvm_field_int             (intrp_src,                  UVM_ALL_ON)
        `uvm_field_int             (intrp_ctx,                  UVM_ALL_ON)
        `uvm_field_enum            (uvm_intrp_txn, intrp_item,  UVM_ALL_ON)        
    `uvm_object_utils_end

    // new - constructor
    function new (string name = "intrp_transaction_inst");
        super.new(name);
    endfunction : new

endclass : intrp_transaction

`endif

