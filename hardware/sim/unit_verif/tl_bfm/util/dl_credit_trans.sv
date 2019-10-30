// *********************************************************************
// IBM CONFIDENTIAL BACKGROUND TECHNOLOGY: VERIFICATION ENVIRONMENT FILE
// *********************************************************************

`ifndef _TL_CREDIT_TRANS_SV
`define _TL_CREDIT_TRANS_SV

class dl_credit_trans extends uvm_transaction;
    int return_credit = 0;

    `uvm_object_utils_begin(dl_credit_trans)
        `uvm_field_int(return_credit,   UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="dl_credit_trans");
        super.new(name);
    endfunction: new

endclass: dl_credit_trans

`endif
