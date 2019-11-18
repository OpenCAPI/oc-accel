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
