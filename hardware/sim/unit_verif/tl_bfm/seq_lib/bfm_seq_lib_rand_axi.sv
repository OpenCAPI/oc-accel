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
`ifndef _BFM_SEQ_LIB_RAND_AXI
`define _BFM_SEQ_LIB_RAND_AXI

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_10_size7_len31
//
//------------------------------------------------------------------------------
class bfm_seq_rd_10_size7_len31 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_10_size7_len31)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_10_size7_len31 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_10_size7_len31");
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
        p_sequencer.brdg_cfg.total_write_num = 0;

        void'(test_item.randomize());
        rd_10_size7_len31[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_10_size7_len31[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_10_size7_len31[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_10_size7_len31[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_10_size7_len31[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_10_size7_len31[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_10_size7_len31[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_10_size7_len31[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_10_size7_len31[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_10_size7_len31[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_10_size7_len31[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number 1
        rd_10_size7_len31[64'h0000_0008_8000_0064]=32'h0000_007B;
        rd_10_size7_len31[64'h0000_0008_8000_0068]=32'h0000_0000;                         //Write number 0
        rd_10_size7_len31[64'h0000_0008_8000_006C]=32'h0000_0000;
        rd_10_size7_len31[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_10_size7_len31[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_10_size7_len31[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_10_size7_len31[64'h0000_0008_8000_0048]));
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_10_size7_len31[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_wr_10_size7_len31
//
//------------------------------------------------------------------------------
class bfm_seq_wr_10_size7_len31 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_wr_10_size7_len31)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] wr_10_size7_len31 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_wr_10_size7_len31");
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
        p_sequencer.brdg_cfg.total_read_num = 0;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        wr_10_size7_len31[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        wr_10_size7_len31[64'h0000_0008_8000_003c]=32'h0000_0000;
        wr_10_size7_len31[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        wr_10_size7_len31[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        wr_10_size7_len31[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        wr_10_size7_len31[64'h0000_0008_8000_004C]=32'h0000_0000;
        wr_10_size7_len31[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        wr_10_size7_len31[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        wr_10_size7_len31[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        wr_10_size7_len31[64'h0000_0008_8000_005C]=32'h0000_0000;
        wr_10_size7_len31[64'h0000_0008_8000_0060]=32'h0000_0000;                         //Read number 0
        wr_10_size7_len31[64'h0000_0008_8000_0064]=32'h0000_0000;
        wr_10_size7_len31[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number 1
        wr_10_size7_len31[64'h0000_0008_8000_006C]=32'h0000_007B;
        wr_10_size7_len31[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, wr_10_size7_len31[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, wr_10_size7_len31[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(wr_10_size7_len31[64'h0000_0008_8000_0048]));
													
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, wr_10_size7_len31[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1_size7_len31
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1_size7_len31 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1_size7_len31)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1_size7_len31 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1_size7_len31");
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
        rd_wr_1_size7_len31[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1_size7_len31[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1_size7_len31[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1_size7_len31[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1_size7_len31[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_1_size7_len31[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1_size7_len31[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1_size7_len31[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1_size7_len31[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_1_size7_len31[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1_size7_len31[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number 1
        rd_wr_1_size7_len31[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        rd_wr_1_size7_len31[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number 1
        rd_wr_1_size7_len31[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        rd_wr_1_size7_len31[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1_size7_len31[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
		
		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1_size7_len31[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1_size7_len31[64'h0000_0008_8000_0048]));
        
		//Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1_size7_len31[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_len31
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_len31 extends bfm_sequence_base; //Ten simple 4KB read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_len31)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size7_len31 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size7_len31");
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
        rd_wr_10_size7_len31[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size7_len31[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size7_len31[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len31[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size7_len31[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size7_len31[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size7_len31[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len31[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size7_len31[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size7_len31[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size7_len31[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size7_len31[64'h0000_0008_8000_0064]=32'h2000_007B;                         //Read pattern
        rd_wr_10_size7_len31[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size7_len31[64'h0000_0008_8000_006C]=32'h2000_007B;                         //Write pattern
        rd_wr_10_size7_len31[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size7_len31[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size7_len31[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size7_len31[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size7_len31[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_len0
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_len0 extends bfm_sequence_base; //Ten 128B read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_len0)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size7_len0 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size7_len0");
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
        rd_wr_10_size7_len0[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size7_len0[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size7_len0[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len0[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size7_len0[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size7_len0[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size7_len0[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len0[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size7_len0[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size7_len0[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size7_len0[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size7_len0[64'h0000_0008_8000_0064]=32'h2000_0070;                         //Read pattern
        rd_wr_10_size7_len0[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size7_len0[64'h0000_0008_8000_006C]=32'h2000_0070;                         //Write pattern
        rd_wr_10_size7_len0[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size7_len0[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size7_len0[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size7_len0[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size7_len0[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_randlen
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_randlen extends bfm_sequence_base; //Ten 128B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_randlen)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size7_randlen [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size7_randlen");
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
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size7_randlen[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size7_randlen[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size7_randlen[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0064]=32'h2000_007F;                         //Read pattern
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size7_randlen[64'h0000_0008_8000_006C]=32'h2000_007F;                         //Write pattern
        rd_wr_10_size7_randlen[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size7_randlen[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size7_randlen[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size7_randlen[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size7_randlen[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_randlen_strobe
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_randlen_strobe extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_randlen_strobe)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size7_randlen_strobe [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size7_randlen_strobe");
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
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0064]=32'h2000_007F;                         //Read pattern
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_006C]=32'h20F0_007F;                         //Write pattern
        rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size7_randlen_strobe[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size7_randlen_strobe[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size7_randlen_strobe[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size6_len0
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size6_len0 extends bfm_sequence_base; //Ten 64B read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_size6_len0)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size6_len0 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size6_len0");
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
        rd_wr_10_size6_len0[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size6_len0[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size6_len0[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size6_len0[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size6_len0[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size6_len0[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size6_len0[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size6_len0[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size6_len0[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size6_len0[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size6_len0[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size6_len0[64'h0000_0008_8000_0064]=32'h2000_0060;                         //Read pattern
        rd_wr_10_size6_len0[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size6_len0[64'h0000_0008_8000_006C]=32'h2000_0060;                         //Write pattern
        rd_wr_10_size6_len0[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size6_len0[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size6_len0[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size6_len0[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size6_len0[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size5_len6
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size5_len6 extends bfm_sequence_base; //Ten 32B*7 read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_size5_len6)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size5_len6 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size5_len6");
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
        rd_wr_10_size5_len6[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size5_len6[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size5_len6[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size5_len6[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size5_len6[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size5_len6[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size5_len6[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size5_len6[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size5_len6[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size5_len6[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size5_len6[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size5_len6[64'h0000_0008_8000_0064]=32'h2000_0056;                         //Read pattern
        rd_wr_10_size5_len6[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size5_len6[64'h0000_0008_8000_006C]=32'h2000_0056;                         //Write pattern
        rd_wr_10_size5_len6[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size5_len6[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size5_len6[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size5_len6[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size5_len6[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1_size5_len0
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1_size5_len0 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1_size5_len0)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1_size5_len0 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1_size5_len0");
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
        rd_wr_1_size5_len0[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1_size5_len0[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1_size5_len0[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1_size5_len0[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1_size5_len0[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_1_size5_len0[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1_size5_len0[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1_size5_len0[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1_size5_len0[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_1_size5_len0[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1_size5_len0[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number
        rd_wr_1_size5_len0[64'h0000_0008_8000_0064]=32'h2000_0050;                         //Read pattern
        rd_wr_1_size5_len0[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number
        rd_wr_1_size5_len0[64'h0000_0008_8000_006C]=32'h2000_0050;                         //Write pattern
        rd_wr_1_size5_len0[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1_size5_len0[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1_size5_len0[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1_size5_len0[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1_size5_len0[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen");
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
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #2000us;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size7_len6_unaligned
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size7_len6_unaligned extends bfm_sequence_base; //Ten 128B*7 read and write with unaligned address

    `uvm_object_utils(bfm_seq_rd_wr_10_size7_len6_unaligned)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size7_len6_unaligned [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size7_len6_unaligned");
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
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0064]=32'h2000_0F76;                         //Read pattern
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_006C]=32'h2000_0F76;                         //Write pattern
        rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size7_len6_unaligned[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size7_len6_unaligned[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size7_len6_unaligned[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #400000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_size6_len6_unaligned
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_size6_len6_unaligned extends bfm_sequence_base; //Ten 64B*7 read and write with unaligned address

    `uvm_object_utils(bfm_seq_rd_wr_10_size6_len6_unaligned)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_size6_len6_unaligned [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_size6_len6_unaligned");
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
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0064]=32'h2000_0F66;                         //Read pattern
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_006C]=32'h2000_0F66;                         //Write pattern
        rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_size6_len6_unaligned[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_size6_len6_unaligned[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_size6_len6_unaligned[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #200000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_unaligned
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_unaligned extends bfm_sequence_base; //Ten ?B*? read and write with unaligned address

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_unaligned)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_unaligned [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_unaligned");
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
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0064]=32'h2000_0FFF;                         //Read pattern
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_006C]=32'h2000_0FFF;                         //Write pattern
        rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_unaligned[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1500000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_size7_len0_id0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_size7_len0_id0to3 extends bfm_sequence_base; //Twenty ID:0-3 128B*1 read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_size7_len0_id0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_size7_len0_id0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_size7_len0_id0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0064]=32'h2000_4070;                         //Read pattern
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_006C]=32'h2000_4070;                         //Write pattern
        rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_size7_len0_id0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_size7_len0_id0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_size7_len0_id0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #250000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_size7_randlen_id0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_size7_randlen_id0to3 extends bfm_sequence_base; //Twenty ID:0-3 128B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_size7_randlen_id0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_size7_randlen_id0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_size7_randlen_id0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0064]=32'h2000_407F;                         //Read pattern
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_006C]=32'h2000_407F;                         //Write pattern
        rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_size7_randlen_id0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_size7_randlen_id0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_size7_randlen_id0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #250000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_randsize_randlen_id0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_randsize_randlen_id0to3 extends bfm_sequence_base; //Twenty ID:0-3 ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_randsize_randlen_id0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_randsize_randlen_id0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_randsize_randlen_id0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0064]=32'h2000_40FF;                         //Read pattern
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_006C]=32'h2000_40FF;                         //Write pattern
        rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_randsize_randlen_id0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_randsize_randlen_id0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_randsize_randlen_id0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #2500us;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_size7_len0_user0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_size7_len0_user0to3 extends bfm_sequence_base; //Twenty User:0-3 128B*1 read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_size7_len0_user0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_size7_len0_user0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_size7_len0_user0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0064]=32'h2004_0070;                         //Read pattern
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_006C]=32'h2004_0070;                         //Write pattern
        rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_size7_len0_user0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_size7_len0_user0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_size7_len0_user0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #250000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_size7_len0_id0to3_user0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_size7_len0_id0to3_user0to3 extends bfm_sequence_base; //Twenty User:0-3 ID:0-3 128B*1 read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_size7_len0_id0to3_user0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_size7_len0_id0to3_user0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_size7_len0_id0to3_user0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0064]=32'h2004_4070;                         //Read pattern
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_006C]=32'h2004_4070;                         //Write pattern
        rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_size7_len0_id0to3_user0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_size7_len0_id0to3_user0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_size7_len0_id0to3_user0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #250000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_20_randsize_randlen_id0to3_user0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_20_randsize_randlen_id0to3_user0to3 extends bfm_sequence_base; //Twenty User:0-3 ID:0-3 ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_20_randsize_randlen_id0to3_user0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_20_randsize_randlen_id0to3_user0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_20_randsize_randlen_id0to3_user0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        void'(test_item.randomize());
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0060]=32'h0000_0014;                         //Read number
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0064]=32'h2004_40FF;                         //Read pattern
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0068]=32'h0000_0014;                         //Write number
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_006C]=32'h2004_40FF;                         //Write pattern
        rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_20_randsize_randlen_id0to3_user0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_20_randsize_randlen_id0to3_user0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_20_randsize_randlen_id0to3_user0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #250000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_100_size7_len31_id0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_100_size7_len31_id0to3 extends bfm_sequence_base; //Observe Peformance with ID:0-3

    `uvm_object_utils(bfm_seq_rd_wr_100_size7_len31_id0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_100_size7_len31_id0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_100_size7_len31_id0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 100;
        p_sequencer.brdg_cfg.total_write_num = 100;

        void'(test_item.randomize());
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0048]=32'h0010_0000;                         //Source size 256*4k
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0058]=32'h0010_0000;                         //Target size 256*4k
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0060]=32'h0000_0064;                         //Read number
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0064]=32'h1000_407B;                         //Read pattern
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0068]=32'h0000_0064;                         //Write number
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_006C]=32'h1000_407B;                         //Write pattern
        rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_100_size7_len31_id0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_100_size7_len31_id0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_100_size7_len31_id0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #300000ns;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3 extends bfm_sequence_base; //One hundred User:0-3 ID:0-3 ?B*? unalgined read and write (with strb)

    `uvm_object_utils(bfm_seq_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3");
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
        p_sequencer.brdg_cfg.total_read_num = 100;
        p_sequencer.brdg_cfg.total_write_num = 100;

        void'(test_item.randomize());
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0058]=32'h0032_0000;                         //Target size 50*4k
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0060]=32'h0000_0064;                         //Read number
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0064]=32'h2004_4FFF;                         //Read pattern
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0068]=32'h0000_0064;                         //Write number
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_006C]=32'h2004_4FFF;                         //Write pattern
        rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_100_randsize_randlen_unaligned_id0to3_user0to3[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #300000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1000_size6_randlen
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1000_size6_randlen extends bfm_sequence_base; //Super

    `uvm_object_utils(bfm_seq_rd_wr_1000_size6_randlen)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1000_size6_randlen [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1000_size6_randlen");
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
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        void'(test_item.randomize());
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size 50*4k
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0060]=32'h0000_03E8;                         //Read number
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0064]=32'h2F00_006F;                         //Read pattern
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0068]=32'h0000_03E8;                         //Write number
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_006C]=32'h2F00_006F;                         //Write pattern
        rd_wr_1000_size6_randlen[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1000_size6_randlen[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1000_size6_randlen[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1000_size6_randlen[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1000_size6_randlen[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1000_size6_randlen_randid
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1000_size6_randlen_randid extends bfm_sequence_base; //Super

    `uvm_object_utils(bfm_seq_rd_wr_1000_size6_randlen_randid)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1000_size6_randlen_randid [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1000_size6_randlen_randid");
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
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        void'(test_item.randomize());
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size 50*4k
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0060]=32'h0000_03E8;                         //Read number
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0064]=32'h2F00_F06F;                         //Read pattern
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0068]=32'h0000_03E8;                         //Write number
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_006C]=32'h2F00_F06F;                         //Write pattern
        rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1000_size6_randlen_randid[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1000_size6_randlen_randid[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1000_size6_randlen_randid[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid extends bfm_sequence_base; //Super

    `uvm_object_utils(bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1000_randsize_randlen_unaligned_randid [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid");
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
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        void'(test_item.randomize());
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size 50*4k
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size 50*4k
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0060]=32'h0000_03E8;                         //Read number
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0068]=32'h0000_03E8;                         //Write number
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_006C]=32'h2F00_FFFF;                         //Write pattern
        rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_unaligned_randid[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1000_randsize_randlen_unaligned_randid[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_unaligned_randid[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #40000us;
    endtask: body
endclass
//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid_randuser
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid_randuser extends bfm_sequence_base; //Super

    `uvm_object_utils(bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid_randuser)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1000_randsize_randlen_unaligned_randid_randuser [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1000_randsize_randlen_unaligned_randid_randuser");
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
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        void'(test_item.randomize());
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size 50*4k
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0060]=32'h0000_03E8;                         //Read number
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0064]=32'h2F0F_FFFF;                         //Read pattern
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0068]=32'h0000_03E8;                         //Write number
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_006C]=32'h2F0F_FFFF;                         //Write pattern
        rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_unaligned_randid_randuser[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1000_randsize_randlen_unaligned_randid_randuser[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_unaligned_randid_randuser[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #3000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_strobe
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_strobe extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_strobe)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_strobe [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_strobe");
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
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_006C]=32'h20F0_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_strobe[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_strobe[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_strobe[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_unaligned_dly [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly");
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
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0064]=32'hF000_0FFF;                         //Read pattern
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_006C]=32'hF000_0FFF;                         //Write pattern
        rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned_dly[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_unaligned_dly[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned_dly[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #2000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly0
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly0 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly0)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_unaligned_dly0 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_unaligned_dly0");
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
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0064]=32'h1000_0FFF;                         //Read pattern
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_006C]=32'h1000_0FFF;                         //Write pattern
        rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned_dly0[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_unaligned_dly0[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_unaligned_dly0[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #500000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_wr_64_randsize_randlen_strobe
//
//------------------------------------------------------------------------------
class bfm_seq_wr_64_randsize_randlen_strobe extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_wr_64_randsize_randlen_strobe)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] wr_64_randsize_randlen_strobe [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_wr_64_randsize_randlen_strobe");
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
        p_sequencer.brdg_cfg.total_read_num = 0;
        p_sequencer.brdg_cfg.total_write_num = 64;

        void'(test_item.randomize());
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_003c]=32'h0000_0000;
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_004C]=32'h0000_0000;
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0058]=32'h0008_0000;                         //Target size
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_005C]=32'h0000_0000;
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0060]=32'h0000_0000;                         //Read number
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0068]=32'h0000_0040;                         //Write number
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_006C]=32'h20F0_00FF;                         //Write pattern
        wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, wr_64_randsize_randlen_strobe[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(wr_64_randsize_randlen_strobe[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, wr_64_randsize_randlen_strobe[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #4000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_1000_randsize_randlen_strobe_unaligned_randid
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_1000_randsize_randlen_strobe_unaligned_randid extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_rd_wr_1000_randsize_randlen_strobe_unaligned_randid)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_1000_randsize_randlen_strobe_unaligned_randid [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_1000_randsize_randlen_strobe_unaligned_randid");
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
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        void'(test_item.randomize());
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0048]=32'h0100_0000;                         //Source size
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0058]=32'h0100_0000;                         //Target size
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0060]=32'h0000_03E8;                         //Read number
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0064]=32'h2F00_FFFF;                         //Read pattern
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0068]=32'h0000_03E8;                         //Write number
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_006C]=32'h2FF0_FFFF;                         //Write pattern
        rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_strobe_unaligned_randid[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_1000_randsize_randlen_strobe_unaligned_randid[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_1000_randsize_randlen_strobe_unaligned_randid[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000us;
    endtask: body
endclass

`endif

