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

`ifndef ODMA_DESP_TRANSACTION_SV
`define ODMA_DESP_TRANSACTION_SV

class odma_desp_transaction extends uvm_sequence_item;

    bit[15:0] magic;
    bit[5:0] nxt_adj;
    bit[7:0] control;
    bit stop;
    bit st_eop;
    bit[27:0] length;
    bit[63:0] src_adr;
    bit[63:0] dst_adr;
    bit[63:0] nxt_adr;

	`uvm_object_utils_begin(odma_desp_transaction)
        `uvm_field_int     (magic,               UVM_ALL_ON)
        `uvm_field_int     (nxt_adj,             UVM_ALL_ON)
        `uvm_field_int     (control,             UVM_ALL_ON)
        `uvm_field_int     (stop,                UVM_ALL_ON)
        `uvm_field_int     (st_eop,              UVM_ALL_ON)
        `uvm_field_int     (length,              UVM_ALL_ON)
        `uvm_field_int     (src_adr,             UVM_ALL_ON)
        `uvm_field_int     (dst_adr,             UVM_ALL_ON)
        `uvm_field_int     (nxt_adr,             UVM_ALL_ON)         
    `uvm_object_utils_end

	function new (string name = "odma_desp_transaction_inst");
        super.new(name);
    endfunction : new
   
endclass : odma_desp_transaction
`endif
