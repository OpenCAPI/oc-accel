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
`ifndef AXI_LITE_TRANSACTION_SV
`define AXI_LITE_TRANSACTION_SV

class axi_lite_transaction extends uvm_sequence_item;

	typedef enum bit { LITE_READ = 1'b0, LITE_WRITE = 1'b1} trans_type;
	
	rand bit [31:0] addr;
	rand bit [31:0] data;
	rand bit [3 :0] strobe;
	rand trans_type t_type;
	
	`uvm_object_utils_begin(axi_lite_transaction)
        `uvm_field_int     (addr,               UVM_ALL_ON)
        `uvm_field_int     (data,               UVM_ALL_ON)
        `uvm_field_int     (strobe,             UVM_ALL_ON)                    
        `uvm_field_enum    (trans_type, t_type, UVM_ALL_ON)        
    `uvm_object_utils_end

	function new (string name = "axi_lite_transaction_inst");
        super.new(name);
    endfunction : new

	function string convert2string(); 
		return $sformatf("addr = 0x%h\ndata = 0x%h\nstrb = 0x%h\n", addr, data, strobe);
   endfunction : convert2string
   
endclass : axi_lite_transaction
`endif
