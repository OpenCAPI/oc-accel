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
