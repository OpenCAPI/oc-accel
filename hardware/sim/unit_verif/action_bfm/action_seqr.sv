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
`ifndef _ACTION_SEQR_SV
`define _ACTION_SEQR_SV

class action_seqr extends uvm_sequencer #(axi_mm_transaction);

    `uvm_component_utils(action_seqr)

    function new (string name="action_seqr", uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: action_seqr

`endif
