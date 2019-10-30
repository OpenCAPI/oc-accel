// *********************************************************************
// IBM CONFIDENTIAL BACKGROUND TECHNOLOGY: VERIFICATION ENVIRONMENT FILE
// *********************************************************************

`ifndef _TL_TX_SEQR_SV
`define _TL_TX_SEQR_SV

class tl_tx_seqr extends uvm_sequencer #(tl_tx_trans, tl_trans);

    `uvm_component_utils(tl_tx_seqr)

    function new (string name="tl_tx_seqr", uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: tl_tx_seqr

`endif
