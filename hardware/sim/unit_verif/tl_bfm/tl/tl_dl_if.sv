// *********************************************************************
// IBM CONFIDENTIAL BACKGROUND TECHNOLOGY: VERIFICATION ENVIRONMENT FILE
// *********************************************************************

`ifndef _TL_DL_IF_SV
`define _TL_DL_IF_SV

interface tl_dl_if (input logic clock);
    //Reset
    logic         chip_reset;
    //TL to DL Outputs
    logic         tl_dl_flit_early_vld;
    logic         tl_dl_flit_vld;
    logic [511:0] tl_dl_flit_data;
    logic [ 15:0] tl_dl_flit_ecc;
    logic         tl_dl_flit_lbip_vld;
    logic [ 81:0] tl_dl_flit_lbip_data;
    logic [ 15:0] tl_dl_flit_lbip_ecc;
    logic         tl_dl_tl_error;
    logic         tl_dl_tl_event;
    logic [  1:0] tl_dl_lane_width_desired;
    //DL to TL Inputs
    logic         dl_tl_flit_vld;
    logic         dl_tl_flit_error;
    logic [511:0] dl_tl_flit_data;
    logic [ 15:0] dl_tl_flit_pty;
    logic         dl_tl_flit_credit;
    logic         dl_tl_link_up;
    logic [  1:0] dl_tl_lane_width_status;
    logic [  2:0] dl_tl_init_flit_depth;

endinterface: tl_dl_if

`endif
