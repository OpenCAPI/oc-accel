
// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
//------------------------------------------------------------------------------
//
// CLASS: axi_mm_transaction
//
//------------------------------------------------------------------------------
`ifndef AXI_MM_TRANSACTION_SV
`define AXI_MM_TRANSACTION_SV


class axi_mm_transaction extends uvm_sequence_item;

    typedef enum bit { READ, WRITE } uvm_axi_txn_e;

    rand bit [63:0]           addr;
    rand bit [255:0][1023:0]  data;
    rand bit [255:0][127:0]   data_strobe;
    rand bit [7:0]            axi_id;
    rand bit [7:0]            axi_usr;
    rand int                  byte_size;           // value of 2^arsize/awsize
    rand int                  burst_length;        // arlen/awlen+1
    rand uvm_axi_txn_e        trans;

    `uvm_object_utils_begin(axi_mm_transaction)
        `uvm_field_int             (addr,                       UVM_ALL_ON)
        `uvm_field_sarray_int      (data,                       UVM_ALL_ON)
        `uvm_field_sarray_int      (data_strobe,                UVM_ALL_ON)
        `uvm_field_int             (axi_id,                     UVM_ALL_ON)        
        `uvm_field_int             (byte_size,                  UVM_ALL_ON)
        `uvm_field_int             (burst_length,               UVM_ALL_ON)                
        `uvm_field_enum            (uvm_axi_txn_e, trans, UVM_ALL_ON)        
    `uvm_object_utils_end

    // new - constructor
    function new (string name = "axi_mm_transaction_inst");
        super.new(name);
    endfunction : new

    function string convert2string(); 
      return $sformatf("Addr=0x%64h, AXI_id=0x%8h", addr, axi_id);
   endfunction : convert2string

endclass : axi_mm_transaction

`endif

