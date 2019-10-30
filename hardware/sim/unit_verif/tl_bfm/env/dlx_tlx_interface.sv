// ****************************************************************
// (C) Copyright International Business Machines Corporation 2018
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
//------------------------------------------------------------------------------
//
// CLASS: dlx_tlx_interface
//
//------------------------------------------------------------------------------
`ifndef _DLX_TLX_INTERFACE_SV
`define _DLX_TLX_INTERFACE_SV

interface dlx_tlx_interface (input clock);

    logic [31:0]        dlx_config_info;
    logic [2:0]         dlx_tlx_init_flit_depth;
    logic [511:0]       dlx_tlx_flit;
    logic               dlx_tlx_flit_crc_err;
    logic               dlx_tlx_flit_credit;
    logic               dlx_tlx_flit_valid;
    logic               dlx_tlx_link_up;
    
    logic [3:0]         tlx_dlx_debug_encode;
    logic [31:0]        tlx_dlx_debug_info;
    logic [511:0]       tlx_dlx_flit;
    logic               tlx_dlx_flit_valid;

endinterface: dlx_tlx_interface

`endif
