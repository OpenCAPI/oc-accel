// ****************************************************************
// (C) Copyright International Business Machines Corporation 2018
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
//------------------------------------------------------------------------------
//
// CLASS: intrp_interface
//
//------------------------------------------------------------------------------
`ifndef _INTRP_INTERFACE_SV
`define _INTRP_INTERFACE_SV

interface intrp_interface (input logic action_clock, input logic action_rst_n);

    logic             intrp_req;
    logic             intrp_ack;
    logic      [63:0] intrp_src;
    logic       [8:0] intrp_ctx;

endinterface: intrp_interface

`endif
