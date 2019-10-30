// *********************************************************************
// IBM CONFIDENTIAL BACKGROUND TECHNOLOGY: VERIFICATION ENVIRONMENT FILE
// *********************************************************************

`ifndef _TB_VSEQR_SV
`define _TB_VSEQR_SV
    
class tb_vseqr extends uvm_sequencer;
    
    tl_tx_seqr      tx_sqr;
    tl_cfg_obj      cfg_obj;
    tl_agent        tl_agt;
    host_mem_model  host_mem;
    brdg_cfg_obj    brdg_cfg;

    `uvm_component_utils_begin(tb_vseqr)
        `uvm_field_object (cfg_obj, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name="tb_vseqr", uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: tb_vseqr
    
`endif
