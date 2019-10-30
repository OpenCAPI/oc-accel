
// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
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

