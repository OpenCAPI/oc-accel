/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
`ifndef _BFM_SEQUENCE_BASE
`define _BFM_SEQUENCE_BASE

typedef class tb_vseqr;

class bfm_sequence_base extends uvm_sequence #(tl_tx_trans, tl_trans);


    `uvm_object_utils(bfm_sequence_base)
    `uvm_declare_p_sequencer(tb_vseqr)

    function new(string name="bfm_sequence_base");
        super.new(name);
    endfunction: new

    virtual task body();
        `uvm_info(get_type_name(), "Executing test base sequence", UVM_MEDIUM)
    endtask
    
    // Use a base sequence to raise/drop objections if this is a default sequence
    virtual task pre_body();
      use_response_handler(1);
      if (starting_phase != null)
        starting_phase.raise_objection(this, {"Running sequence '",
                                              get_full_name(), "'"});
    endtask

    virtual task post_body();
      if (starting_phase != null)
        starting_phase.drop_objection(this, {"Completed sequence '",
                                             get_full_name(), "'"});
    endtask

    virtual function void response_handler(uvm_sequence_item response);
    // do nothing right now
        `uvm_info(get_type_name(),$psprintf("Sequence receive response from driver, the sequence id is%d and the transaction id is%d",response.get_sequence_id(), response.get_transaction_id()), UVM_MEDIUM) 
/*
        tl_trans resp=new();
        if(!$cast(resp,response))
            `uvm_error(get_type_name(),"Can't cast")
        else
            `uvm_info(get_type_name(),$psprintf("Sequence receive response from driver, capptag:%h", resp.rx_CAPPTag), UVM_MEDIUM)
            `uvm_info(get_type_name(), $psprintf("This response has a sequence id of%d and a transaction id of%d",resp.get_sequence_id(), resp.get_transaction_id()), UVM_MEDIUM) 
*/ 
    endfunction
endclass: bfm_sequence_base

`endif
