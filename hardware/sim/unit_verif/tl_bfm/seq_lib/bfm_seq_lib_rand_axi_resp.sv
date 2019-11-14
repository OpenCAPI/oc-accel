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
`ifndef _BFM_SEQ_LIB_RAND_AXI_RESP
`define _BFM_SEQ_LIB_RAND_AXI_RESP

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1_size5_len0_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1_size5_len0_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1_size5_len0_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1_size5_len0_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_0050;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_0050;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size5_len6_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size5_len6_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_size5_len6_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_size5_len6_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_0056;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_0056;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_strobe_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_strobe_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_strobe_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_strobe_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h20F0_00FF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_0FFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h20F0_0FFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_strobe_unaligned_randid_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_64_randsize_randlen_strobe_unaligned_randid_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 64;
        p_sequencer.brdg_cfg.total_write_num = 64;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0008_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0008_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0040;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0040;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1000000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0080_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0080_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_2048_randsize_randlen_strobe_unaligned_randid_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 2048;
        p_sequencer.brdg_cfg.total_write_num = 2048;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0800;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0800;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #20000000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_4096_randsize_randlen_strobe_unaligned_randid_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 4096;
        p_sequencer.brdg_cfg.total_write_num = 4096;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0200_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0200_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_1000;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_1000;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #40000000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_len31_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_len31_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_len31_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_size7_len31_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F07B;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F07B;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_randlen_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_randlen_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_randlen_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_10_size7_randlen_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F07F;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F07F;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #500000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_size7_len31_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_size7_len31_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_size7_len31_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_size7_len31_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F07B;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F07B;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #20000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_size7_randlen_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_size7_randlen_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_size7_randlen_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_size7_randlen_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F07F;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F07F;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #20000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_size6_randlen_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_size6_randlen_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_size6_randlen_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_size6_randlen_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F06F;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F06F;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #20000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_randsize_randlen_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_randsize_randlen_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_randsize_randlen_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_randsize_randlen_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_F0FF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_F0FF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #500000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_randsize_randlen_unaligned_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h2000_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] set_mmio_pattern [int unsigned];
    init_host_mem init_host_mem_item;    
    function new(string name= "bfm_seq_rd_wr_1024_randsize_randlen_strobe_unaligned_randid_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        void'(test_item.randomize());
        set_mmio_pattern[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        set_mmio_pattern[64'h0000_0008_8000_003c]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        set_mmio_pattern[64'h0000_0008_8000_004C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        set_mmio_pattern[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        set_mmio_pattern[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        set_mmio_pattern[64'h0000_0008_8000_005C]=32'h0000_0000;
        set_mmio_pattern[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number
        set_mmio_pattern[64'h0000_0008_8000_0064]=32'h2000_FFFF;                         //Read pattern
        set_mmio_pattern[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number
        set_mmio_pattern[64'h0000_0008_8000_006C]=32'h20F0_FFFF;                         //Write pattern
        set_mmio_pattern[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, set_mmio_pattern[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, set_mmio_pattern[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(set_mmio_pattern[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        p_sequencer.cfg_obj.wr_fail_percent = 1; //tl_resp_rand_item.wr_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        // p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        // p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        // p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)
        
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, set_mmio_pattern[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000000us;
    endtask: body
endclass

`endif
