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

`ifndef _ODMA_TEST_LIB_ST
`define _ODMA_TEST_LIB_ST

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc1_h2a_4k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc1_h2a_4k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc1_h2a_4k_st)

    function new(string name= "odma_test_block1_dsc1_h2a_4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc1_h2a_4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc1_h2a_4k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc1_a2h_4k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc1_a2h_4k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc1_a2h_4k_st)

    function new(string name= "odma_test_block1_dsc1_a2h_4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc1_a2h_4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc1_a2h_4k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc4_h2a_4k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc4_h2a_4k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc4_h2a_4k_st)

    function new(string name= "odma_test_block1_dsc4_h2a_4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc4_h2a_4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc4_h2a_4k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc4_a2h_4k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc4_a2h_4k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc4_a2h_4k_st)

    function new(string name= "odma_test_block1_dsc4_a2h_4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc4_a2h_4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc4_a2h_4k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc4_h2a_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc4_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc4_h2a_less64k_st)

    function new(string name= "odma_test_block1_dsc4_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc4_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc4_h2a_less64k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1_dsc4_a2h_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block1_dsc4_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1_dsc4_a2h_less64k_st)

    function new(string name= "odma_test_block1_dsc4_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1_dsc4_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1_dsc4_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block2to4_randdsc_a2h_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block2to4_randdsc_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block2to4_randdsc_a2h_less64k_st)

    function new(string name= "odma_test_block2to4_randdsc_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block2to4_randdsc_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block2to4_randdsc_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1to32_randdsc_a2h_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block1to32_randdsc_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1to32_randdsc_a2h_less64k_st)

    function new(string name= "odma_test_block1to32_randdsc_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1to32_randdsc_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1to32_randdsc_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block2to4_randdsc_h2a_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block2to4_randdsc_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block2to4_randdsc_h2a_less64k_st)

    function new(string name= "odma_test_block2to4_randdsc_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block2to4_randdsc_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block2to4_randdsc_h2a_less64k_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block1to32_randdsc_h2a_less64k_st
//
//----------------------------------------------------------------------

class odma_test_block1to32_randdsc_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block1to32_randdsc_h2a_less64k_st)

    function new(string name= "odma_test_block1to32_randdsc_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block1to32_randdsc_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block1to32_randdsc_h2a_less64k_st

//--------------------------------------------------------------------
//
// TEST: odma_test_block2to4_dsc1to8_a2h_hardlen_st
//
//----------------------------------------------------------------------

class odma_test_block2to4_dsc1to8_a2h_hardlen_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block2to4_dsc1to8_a2h_hardlen_st)

    function new(string name= "odma_test_block2to4_dsc1to8_a2h_hardlen_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block2to4_dsc1to8_a2h_hardlen_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block2to4_dsc1to8_a2h_hardlen_st

//----------------------------------------------------------------------
//
// TEST: odma_test_block2to4_dsc1to8_h2a_hardlen_st
//
//----------------------------------------------------------------------

class odma_test_block2to4_dsc1to8_h2a_hardlen_st extends action_tb_base_test;

    `uvm_component_utils(odma_test_block2to4_dsc1to8_h2a_hardlen_st)

    function new(string name= "odma_test_block2to4_dsc1to8_h2a_hardlen_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_block2to4_dsc1to8_h2a_hardlen_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: odma_test_block2to4_dsc1to8_h2a_hardlen_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_list2to4_block2to4_randdsc_a2h_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_list2to4_block2to4_randdsc_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_list2to4_block2to4_randdsc_a2h_less64k_st)

    function new(string name= " odma_test_list2to4_block2to4_randdsc_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_list2to4_block2to4_randdsc_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_list2to4_block2to4_randdsc_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_list2to4_block2to4_randdsc_h2a_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_list2to4_block2to4_randdsc_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_list2to4_block2to4_randdsc_h2a_less64k_st)

    function new(string name= " odma_test_list2to4_block2to4_randdsc_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_list2to4_block2to4_randdsc_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_list2to4_block2to4_randdsc_h2a_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_block2to4_dsc1to8_a2h_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_block2to4_dsc1to8_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_block2to4_dsc1to8_a2h_less64k_st)

    function new(string name= " odma_test_chnl4_block2to4_dsc1to8_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_block2to4_dsc1to8_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_block2to4_dsc1to8_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_block2to4_dsc1to8_h2a_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_block2to4_dsc1to8_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_block2to4_dsc1to8_h2a_less64k_st)

    function new(string name= " odma_test_chnl4_block2to4_dsc1to8_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_block2to4_dsc1to8_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_block2to4_dsc1to8_h2a_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st)

    function new(string name= " odma_test_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st)

    function new(string name= " odma_test_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st)

    function new(string name= " odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st)

    function new(string name= " odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st)

    function new(string name= " odma_test_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st)

    function new(string name= " odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_st

//----------------------------------------------------------------------
//
// TEST:  odma_test_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st
//
//----------------------------------------------------------------------

class  odma_test_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st extends action_tb_base_test;

    `uvm_component_utils( odma_test_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st)

    function new(string name= " odma_test_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", odma_seq_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st::type_id::get());
    endfunction : build_phase


    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass:  odma_test_chnl4_list32_block2to4_dsc1to64_mixdrt_128B_st

`endif
