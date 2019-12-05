
// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
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
    rand bit [7:0]            tid;
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

