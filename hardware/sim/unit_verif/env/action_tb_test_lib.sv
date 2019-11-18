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
`ifndef _BFM_TEST_LIB
`define _BFM_TEST_LIB

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k)

    function new(string name= "bfm_test_read_4k_write_4k", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1024
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1024 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1024)

    function new(string name= "bfm_test_read_4k_write_4k_n1024", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1024::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1024

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n2048
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n2048 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n2048)

    function new(string name= "bfm_test_read_4k_write_4k_n2048", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n2048::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 500000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n2048

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n4096
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n4096 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n4096)

    function new(string name= "bfm_test_read_4k_write_4k_n4096", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n4096::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n4096

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k
//
//----------------------------------------------------------------------

class bfm_test_read_4k extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k)

    function new(string name= "bfm_test_read_4k", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)        
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k

//----------------------------------------------------------------------
//
// TEST: bfm_test_write_4k
//
//----------------------------------------------------------------------

class bfm_test_write_4k extends action_tb_base_test;

    `uvm_component_utils(bfm_test_write_4k)

    function new(string name= "bfm_test_write_4k", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_write_4k::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_write_4k

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1_rand_resp)

    function new(string name= "bfm_test_read_4k_write_4k_n1_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50s);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n64_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n64_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n64_rand_resp)

    function new(string name= "bfm_test_read_4k_write_4k_n64_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n64_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50s);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n64_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1024_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1024_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1024_rand_resp)

    function new(string name= "bfm_test_read_4k_write_4k_n1024_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1024_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50s);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1024_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n2048_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n2048_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n2048_rand_resp)

    function new(string name= "bfm_test_read_4k_write_4k_n2048_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n2048_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50s);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n2048_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n4096_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n4096_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n4096_rand_resp)

    function new(string name= "bfm_test_read_4k_write_4k_n4096_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n4096_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50s);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n4096_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_10_size7_len31
//
//----------------------------------------------------------------------

class bfm_test_rd_10_size7_len31 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_10_size7_len31)

    function new(string name= "bfm_test_rd_10_size7_len31", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_10_size7_len31::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_10_size7_len31

//----------------------------------------------------------------------
//
// TEST: bfm_test_wr_10_size7_len31
//
//----------------------------------------------------------------------

class bfm_test_wr_10_size7_len31 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_wr_10_size7_len31)

    function new(string name= "bfm_test_wr_10_size7_len31", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_wr_10_size7_len31::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_wr_10_size7_len31

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1_size7_len31
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1_size7_len31 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1_size7_len31)

    function new(string name= "bfm_test_rd_wr_1_size7_len31", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1_size7_len31::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1_size7_len31

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_len31
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_len31 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_len31)

    function new(string name= "bfm_test_rd_wr_10_size7_len31", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_len31::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_len31

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_len0
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_len0 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_len0)

    function new(string name= "bfm_test_rd_wr_10_size7_len0", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_len0::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_len0

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_randlen
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_randlen extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_randlen)

    function new(string name= "bfm_test_rd_wr_10_size7_randlen", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_randlen::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_randlen

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_randlen_strobe
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_randlen_strobe extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_randlen_strobe)

    function new(string name= "bfm_test_rd_wr_10_size7_randlen_strobe", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_randlen_strobe::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_randlen_strobe

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size6_len0
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size6_len0 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size6_len0)

    function new(string name= "bfm_test_rd_wr_10_size6_len0", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size6_len0::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size6_len0

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size5_len6
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size5_len6 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size5_len6)

    function new(string name= "bfm_test_rd_wr_10_size5_len6", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size5_len6::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size5_len6

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_len6_unaligned
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_len6_unaligned extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_len6_unaligned)

    function new(string name= "bfm_test_rd_wr_10_size7_len6_unaligned", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_len6_unaligned::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_len6_unaligned

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size6_len6_unaligned
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size6_len6_unaligned extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size6_len6_unaligned)

    function new(string name= "bfm_test_rd_wr_10_size6_len6_unaligned", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size6_len6_unaligned::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size6_len6_unaligned

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_unaligned
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_unaligned extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_unaligned)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_unaligned", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_unaligned::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_unaligned

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_size7_len0_id0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_size7_len0_id0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_size7_len0_id0to3)

    function new(string name= "bfm_test_rd_wr_20_size7_len0_id0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_size7_len0_id0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_size7_len0_id0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_size7_randlen_id0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_size7_randlen_id0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_size7_randlen_id0to3)

    function new(string name= "bfm_test_rd_wr_20_size7_randlen_id0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_size7_randlen_id0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_size7_randlen_id0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_randsize_randlen_id0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_randsize_randlen_id0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_randsize_randlen_id0to3)

    function new(string name= "bfm_test_rd_wr_20_randsize_randlen_id0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_randsize_randlen_id0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_randsize_randlen_id0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_size7_len0_user0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_size7_len0_user0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_size7_len0_user0to3)

    function new(string name= "bfm_test_rd_wr_20_size7_len0_user0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_size7_len0_user0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_size7_len0_user0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_size7_len0_id0to3_user0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_size7_len0_id0to3_user0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_size7_len0_id0to3_user0to3)

    function new(string name= "bfm_test_rd_wr_20_size7_len0_id0to3_user0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_size7_len0_id0to3_user0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_size7_len0_id0to3_user0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_20_randsize_randlen_id0to3_user0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_20_randsize_randlen_id0to3_user0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_20_randsize_randlen_id0to3_user0to3)

    function new(string name= "bfm_test_rd_wr_20_randsize_randlen_id0to3_user0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_20_randsize_randlen_id0to3_user0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_20_randsize_randlen_id0to3_user0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_100_size7_len31_id0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_100_size7_len31_id0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_100_size7_len31_id0to3)

    function new(string name= "bfm_test_rd_wr_100_size7_len31_id0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_100_size7_len31_id0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_100_size7_len31_id0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3)

    function new(string name= "bfm_test_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid)

    function new(string name= "bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid_randuser
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid_randuser extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid_randuser)

    function new(string name= "bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid_randuser", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid_randuser::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1000_randsize_randlen_unaligned_randid_randuser

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1_size5_len0
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1_size5_len0 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1_size5_len0)

    function new(string name= "bfm_test_rd_wr_1_size5_len0", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1_size5_len0::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1_size5_len0

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_strobe
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_strobe extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_strobe)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_strobe", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_strobe::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_strobe

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_unaligned_dly
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_unaligned_dly extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_unaligned_dly)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_unaligned_dly", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_unaligned_dly

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_unaligned_dly0
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_unaligned_dly0 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_unaligned_dly0)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_unaligned_dly0", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly0::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_unaligned_dly0


//----------------------------------------------------------------------
//
// TEST: bfm_test_wr_64_randsize_randlen_strobe
//
//----------------------------------------------------------------------

class bfm_test_wr_64_randsize_randlen_strobe extends action_tb_base_test;

    `uvm_component_utils(bfm_test_wr_64_randsize_randlen_strobe)

    function new(string name= "bfm_test_wr_64_randsize_randlen_strobe", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_wr_64_randsize_randlen_strobe::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_wr_64_randsize_randlen_strobe

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1000_randsize_randlen_strobe_unaligned_randid
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1000_randsize_randlen_strobe_unaligned_randid extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1000_randsize_randlen_strobe_unaligned_randid)

    function new(string name= "bfm_test_rd_wr_1000_randsize_randlen_strobe_unaligned_randid", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1000_randsize_randlen_strobe_unaligned_randid::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1000_randsize_randlen_strobe_unaligned_randid

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1_split)

    function new(string name= "bfm_test_read_4k_write_4k_n1_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n64_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n64_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n64_split)

    function new(string name= "bfm_test_read_4k_write_4k_n64_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n64_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n64_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1024_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1024_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1024_split)

    function new(string name= "bfm_test_read_4k_write_4k_n1024_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1024_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1024_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n2048_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n2048_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n2048_rand_resp_split)

    function new(string name= "bfm_test_read_4k_write_4k_n2048_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n2048_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 500000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n2048_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n4096_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n4096_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n4096_rand_resp_split)

    function new(string name= "bfm_test_read_4k_write_4k_n4096_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n4096_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n4096_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1_size5_len0_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1_size5_len0_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1_size5_len0_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_1_size5_len0_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1_size5_len0_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1_size5_len0_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size5_len6_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size5_len6_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size5_len6_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_10_size5_len6_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size5_len6_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size5_len6_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_strobe_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_strobe_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_strobe_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_strobe_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_strobe_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_strobe_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split)

    function new(string name= "bfm_test_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_len31_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_len31_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_len31_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_10_size7_len31_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_len31_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_len31_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_size7_randlen_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_size7_randlen_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_size7_randlen_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_10_size7_randlen_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_size7_randlen_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_size7_randlen_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_size7_len31_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_size7_len31_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_size7_len31_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_size7_len31_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_size7_len31_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_size7_len31_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_size7_randlen_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_size7_randlen_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_size7_randlen_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_size7_randlen_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_size7_randlen_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_size7_randlen_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_randsize_randlen_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_randsize_randlen_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_randsize_randlen_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_randsize_randlen_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_randsize_randlen_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_randsize_randlen_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n1_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n1_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n1_rand_resp_split)

    function new(string name= "bfm_test_read_4k_write_4k_n1_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n1_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n1_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_n64_rand_resp_split
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_n64_rand_resp_split extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_n64_rand_resp_split)

    function new(string name= "bfm_test_read_4k_write_4k_n64_rand_resp_split", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_n64_rand_resp_split::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_n64_rand_resp_split

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1000_size6_randlen
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1000_size6_randlen extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1000_size6_randlen)

    function new(string name= "bfm_test_rd_wr_1000_size6_randlen", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1000_size6_randlen::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1000_size6_randlen

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1000_size6_randlen_randid
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1000_size6_randlen_randid extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1000_size6_randlen_randid)

    function new(string name= "bfm_test_rd_wr_1000_size6_randlen_randid", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1000_size6_randlen_randid::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1000_size6_randlen_randid

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_1024_size6_randlen_randid_rand_resp
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_1024_size6_randlen_randid_rand_resp extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_1024_size6_randlen_randid_rand_resp)

    function new(string name= "bfm_test_rd_wr_1024_size6_randlen_randid_rand_resp", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_1024_size6_randlen_randid_rand_resp::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_1024_size6_randlen_randid_rand_resp

//----------------------------------------------------------------------
//
// TEST: bfm_test_read_4k_write_4k_mmio
//
//----------------------------------------------------------------------

class bfm_test_read_4k_write_4k_mmio extends action_tb_base_test;

    `uvm_component_utils(bfm_test_read_4k_write_4k_mmio)

    function new(string name= "bfm_test_read_4k_write_4k_mmio", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_read_4k_write_4k_mmio::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_read_4k_write_4k_mmio

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_1
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_1 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_1)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_1", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_1::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_1

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_2
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_2 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_2)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_2", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_2::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_2

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_20
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_20 extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_20)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_20", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_20::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_20

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_1_rty
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_1_rty extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_1_rty)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_1_rty", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_1_rty::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_1_rty

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_2_rty
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_2_rty extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_2_rty)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_2_rty", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_2_rty

//----------------------------------------------------------------------
//
// TEST: bfm_test_rd_wr_10_randsize_randlen_intrp_20_rty
//
//----------------------------------------------------------------------

class bfm_test_rd_wr_10_randsize_randlen_intrp_20_rty extends action_tb_base_test;

    `uvm_component_utils(bfm_test_rd_wr_10_randsize_randlen_intrp_20_rty)

    function new(string name= "bfm_test_rd_wr_10_randsize_randlen_intrp_20_rty", uvm_component parent);
        super.new(name, parent);
    endfunction: new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_wrapper::set(this, "env.vsqr.main_phase", "default_sequence", bfm_seq_rd_wr_10_randsize_randlen_intrp_20_rty::type_id::get());
    endfunction : build_phase
    

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            timeout(phase, 50000us);
        join_none
    endtask: main_phase

endclass: bfm_test_rd_wr_10_randsize_randlen_intrp_20_rty

`endif
