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
`ifndef _BFM_SEQ_LIB_MMIO_INTRP
`define _BFM_SEQ_LIB_MMIO_INTRP

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_mmio
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_mmio extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k_write_4k_mmio)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k_write_4k_mmio [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_mmio");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #4000ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

        void'(test_item.randomize());
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number 1
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number 1
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0070]=test_item.seed;

        //MMIO write
        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k_write_4k_mmio[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        #4000ns;

        //MMIO read
        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_RD_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k_write_4k_mmio[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k_write_4k_mmio[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        //Action start bit read
        temp_addr={64'h0000_0008_8000_0038};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_RD_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_1
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_1 extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_1)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_1 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_1");
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
        p_sequencer.brdg_cfg.total_intrp_num = 1;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0080]=32'h0000_0001;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_1[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_1[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_1[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #800000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_2
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_2 extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_2)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_2 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_2");
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
        p_sequencer.brdg_cfg.total_intrp_num = 2;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0080]=32'h0000_0002;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_2[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_2[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_2[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_20
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_20 extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_20)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_20 [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_20");
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
        p_sequencer.brdg_cfg.total_intrp_num = 20;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0080]=32'h0000_000F;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_20[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_20[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_20[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #8000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_1_rty
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_1_rty extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_1_rty)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_1_rty [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_1_rty");
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
        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;       

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 1;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0080]=32'h0000_0001;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_1_rty[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_1_rty[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_1_rty[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #1000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_2_rty [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty");
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
        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;       

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 2;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0080]=32'h0000_0002;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_2_rty[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_2_rty[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_2_rty[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #2000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_20_rty
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_20_rty extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_20_rty)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] rd_wr_10_randsize_randlen_intrp_20_rty [int unsigned];
	init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_10_randsize_randlen_intrp_20_rty");
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
        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;       

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 20;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        void'(test_item.randomize());
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_003c]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_004C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_005C]=32'h0000_0000;
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0060]=32'h0000_000A;                         //Read number
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0064]=32'h2000_00FF;                         //Read pattern
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0068]=32'h0000_000A;                         //Write number
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_006C]=32'h2000_00FF;                         //Write pattern
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0070]=test_item.seed; 
        rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0080]=32'h0000_000F;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_20_rty[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

		//Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0048], 
													init_host_mem_item.init_data_queue(rd_wr_10_randsize_randlen_intrp_20_rty[64'h0000_0008_8000_0048]));
		
        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, rd_wr_10_randsize_randlen_intrp_20_rty[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000000ns;
    endtask: body
endclass

`endif
