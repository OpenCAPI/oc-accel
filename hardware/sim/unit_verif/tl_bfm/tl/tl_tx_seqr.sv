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
`ifndef _TL_TX_SEQR_SV
`define _TL_TX_SEQR_SV

class tl_tx_seqr extends uvm_sequencer #(tl_tx_trans, tl_trans);

    `uvm_component_utils(tl_tx_seqr)

    function new (string name="tl_tx_seqr", uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: tl_tx_seqr

`endif
