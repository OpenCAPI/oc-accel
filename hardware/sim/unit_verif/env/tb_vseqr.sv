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
`ifndef _TB_VSEQR_SV
`define _TB_VSEQR_SV

class tb_vseqr extends uvm_sequencer;
    
    tl_tx_seqr      tx_sqr;
    tl_cfg_obj      cfg_obj;
    tl_agent        tl_agt;
    host_mem_model  host_mem;
    brdg_cfg_obj    brdg_cfg;
    act_cfg_obj     act_cfg;
    action_agent    action_agt;
    action_seqr     act_sqr;
    action_seqr_st  act_sqr_st;

    `uvm_component_utils_begin(tb_vseqr)
        `uvm_field_object (cfg_obj, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name="tb_vseqr", uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: tb_vseqr
    
`endif
