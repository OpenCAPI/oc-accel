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
`ifndef _ODMA_SEQ_LIB_UNALIGN
`define _ODMA_SEQ_LIB_UNALIGN

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc1_h2a_4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc1_h2a_4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc1_h2a_4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 1;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc1_h2a_4k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]=32'h0000_0000;                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Gen a descriptor
        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length == 28'h1000;});
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Print a descriptor
        odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
        //Write a descriptor to memory
        desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
        init_mem_desp_item.init_data_queue(desp_item);
        //Initial host memory data for descriptors
        p_sequencer.host_mem.set_memory_by_length({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}, 32, init_mem_desp_item.init_data_queue(desp_item));
        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
        #100000ns;
    endtask: body
endclass


//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc1_a2h_4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc1_a2h_4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc1_a2h_4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 1;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc1_a2h_4k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]=32'h0000_0000;                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Gen a descriptor
        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length == 28'h1000;});
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Print a descriptor
        odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
        //Write a descriptor to memory
        desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
        init_mem_desp_item.init_data_queue(desp_item);
        //Initial host memory data for descriptors
        p_sequencer.host_mem.set_memory_by_length({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}, 32, init_mem_desp_item.init_data_queue(desp_item));
        
        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
													
		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_h2a_4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_h2a_4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_h2a_4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_h2a_4k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length == 28'h1000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length == 28'h1000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
		
		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_a2h_4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_a2h_4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_a2h_4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_a2h_4k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length == 28'h1000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length == 28'h1000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_h2a_less128B_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_h2a_less128B_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_h2a_less128B_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_h2a_less128B_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length <= 28'h80;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h80;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_a2h_less128B_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_a2h_less128B_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_a2h_less128B_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_a2h_less128B_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length <= 28'h80;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h80;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_h2a_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length <= 28'h10000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag source address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.src_adr_q.push_back(odma_desp_templ_item.src_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1_dsc4_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1_dsc4_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1_dsc4_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();    
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item;
	
	int desp_count = 4;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1_dsc4_a2h_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={28'h0, 4'h3};                         //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr += odma_desp_templ_item.dst_adr_var;
		//Set source address
		odma_desp_templ_item.src_adr += odma_desp_templ_item.src_adr_var;
        //Gen 4 descriptors in one block
        for(int i=0; i<4; i++)begin
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: 0, Descriptor: %d.", i), UVM_LOW)
            if(i<3)begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == (2-i); control == 8'h00; length <= 28'h10000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
            else begin
                void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
				odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
				odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                //Tag target address
                for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                end
                //Print a descriptor
                odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                //Write a descriptor to memory
                desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                init_mem_desp_item.init_data_queue(desp_item);
                //Initial host memory data for descriptors
                p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));                
                //Initial host memory data for read commands
                p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block2to4_randdsc_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block2to4_randdsc_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block2to4_randdsc_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block2to4_randdsc_a2h_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m] % 64 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Tag target address
                    for(int j=0; j<odma_desp_templ_item.length; j++)begin
                        odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    end
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    //Tag target address
                    for(int j=0; j<odma_desp_templ_item.length; j++)begin
                        odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_5080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_5084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 10) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
        #500000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block2to4_dsc1to8_a2h_hardlen_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block2to4_dsc1to8_a2h_hardlen_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block2to4_dsc1to8_a2h_hardlen_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block2to4_dsc1to8_a2h_hardlen_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m] % 8 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);						
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_5080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_5084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 1000) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
        #2000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1to32_randdsc_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1to32_randdsc_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1to32_randdsc_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1to32_randdsc_a2h_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[1:32]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m]% 64 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)

        write_mmio_patt[64'h0000_0008_8000_5080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_5088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_a2h_addr[i])begin
            temp_addr=reg_addr_list.mmio_a2h_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Tag target address
                    for(int j=0; j<odma_desp_templ_item.length; j++)begin
                        odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    end
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);						
                    end
                    //Tag target address
                    for(int j=0; j<odma_desp_templ_item.length; j++)begin
                        odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;                    
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_5080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_5084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_1008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

		while(curr_desp_num < desp_count && to_break < 100) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
        #5000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block2to4_randdsc_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block2to4_randdsc_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block2to4_randdsc_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block2to4_randdsc_h2a_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m]% 64 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)     

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Tag target address
                    //for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    //    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    //end
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);						
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_4080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_4084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        
		while(curr_desp_num < desp_count && to_break < 100) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		#500000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block2to4_dsc1to8_h2a_hardlen_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block2to4_dsc1to8_h2a_hardlen_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block2to4_dsc1to8_h2a_hardlen_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block2to4_dsc1to8_h2a_hardlen_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m]% 8 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)     

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Tag target address
                    //for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    //    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    //end
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);						
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_4080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_4084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        while(curr_desp_num < desp_count && to_break < 1000) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
		#2000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_block1to32_randdsc_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_block1to32_randdsc_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_block1to32_randdsc_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int to_break = 0;
	int last_desp_num = 0;
	int curr_desp_num = 0;

    function new(string name= "odma_seq_block1to32_randdsc_h2a_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Randomize an array for block_num and desp_num
        randomize(block_desp_q) with {block_desp_q.size inside {[1:32]};};
        `uvm_info("odma_seq_lib", $sformatf("Generate a list of %d blocks.", block_desp_q.size), UVM_LOW)        
        foreach(block_desp_q[m])begin
            //TODO: Generate not a multiple of 4 integer when design support partial reaed+
            block_desp_q[m] = block_desp_q[m]% 64 + 1;
			desp_count += block_desp_q[m];
            `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Desp Num: %d", m, block_desp_q[m]), UVM_LOW)                    
        end
		`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)
		

        write_mmio_patt[64'h0000_0008_8000_4080]=32'h0000_0000;                         //host memory address low 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4084]=32'h0bee_0000;                         //host memory address high 32-bit for descriptor
        write_mmio_patt[64'h0000_0008_8000_4088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
        write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
        write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
        write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit

        foreach(reg_addr_list.mmio_h2a_addr[i])begin
            temp_addr=reg_addr_list.mmio_h2a_addr[i];
            temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
        //Set descriptor address
        odma_desp_templ_item.nxt_adr = {write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]};
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;

        //Generate descriptors in each block
        foreach(block_desp_q[n])begin
            for(int i=0; i<block_desp_q[n]; i++)begin
                `uvm_info("odma_seq_lib", $sformatf("List: 0, Block: %d, Descriptor: %d.", n, i), UVM_LOW)
                if(i<block_desp_q[n]-1)begin
                    void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
					odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
					odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    //Tag target address
                    //for(int j=0; j<odma_desp_templ_item.length; j++)begin
                    //    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
                    //end
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
                else begin
                    if(n == block_desp_q.size -1)begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
                    end
                    else begin
                        void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);						
                    end
                    //Generate descriptor address                    
                    odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
                    //Print a descriptor
                    odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
                    //Write a descriptor to memory
                    desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
                    init_mem_desp_item.init_data_queue(desp_item);
                    //Initial host memory data for descriptors
                    p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
                    //Set descriptor base address for next block
                    write_mmio_patt[64'h0000_0008_8000_4080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
                    write_mmio_patt[64'h0000_0008_8000_4084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
                    //Initial host memory data for read commands
                    p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
                end
            end
        end

        //Action start
        temp_addr={64'h0000_0008_8000_0008};
        temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        while(curr_desp_num < desp_count && to_break < 100) begin
			#1000ns;
			curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
			if(last_desp_num < curr_desp_num)begin
				last_desp_num = curr_desp_num;
				to_break = 0;
				`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
			end
			else begin
				to_break++;
			end
		end
			
		if(curr_desp_num != desp_count)begin
			`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count))
		end
		else begin
			`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list 0.\n", curr_desp_num, desp_count), UVM_LOW)
		end
		
		#5000us;
    endtask: body
endclass

//sequences of multi lists begin here
//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_list2to4_block2to4_randdsc_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_list2to4_block2to4_randdsc_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_list2to4_block2to4_randdsc_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int list_num = 1;
	int to_break = 0;
	bit[63:0] last_desp_num = 0;
	bit[63:0] curr_desp_num = 0;

    function new(string name= "odma_seq_list2to4_block2to4_randdsc_h2a_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard

        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = 64'h0bee_0000_0000_0000;
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;
		
		randomize(list_num) with {list_num >= 2; list_num <= 4;};
		`uvm_info("odma_seq_lib", $sformatf("There are totally %d list.", list_num), UVM_LOW) 
		
		for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
			`uvm_info("odma_seq_lib", $sformatf("Generate list %d of %d blocks.", k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 64 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("List: %d, Block: %d, Desp Num: %d", k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)     

			if(k > 0)begin
			write_mmio_patt[64'h0000_0008_8000_4080]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			end
			write_mmio_patt[64'h0000_0008_8000_4088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i];
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("List: %d, Block: %d, Descriptor: %d.", k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084], write_mmio_patt[64'h0000_0008_8000_4080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			last_desp_num = 0;
			curr_desp_num = 0;
			while(curr_desp_num < desp_count && to_break < 10) begin
				#1000ns;
				curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
				if(last_desp_num < curr_desp_num)begin
					last_desp_num = curr_desp_num;
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(curr_desp_num != desp_count)begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0 list number %d.\n", curr_desp_num, desp_count, k))
			end
			else begin
				`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0 list number %d.\n", curr_desp_num, desp_count, k), UVM_LOW)
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001, 8'h0);
		end

		#10000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_list2to4_block2to4_randdsc_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_list2to4_block2to4_randdsc_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_list2to4_block2to4_randdsc_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] write_mmio_patt [int unsigned];
    odma_desp_templ odma_desp_templ_item=new();
    //odma_list_block_desp odma_list_item=new();
    bit[31:0][7:0] desp_item;
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 
    rand int unsigned block_desp_q[$];
	int desp_count = 0;
	int list_num = 1;
	int to_break = 0;
	bit[63:0] last_desp_num = 0;
	bit[63:0] curr_desp_num = 0;

    function new(string name= "odma_seq_list2to4_block2to4_randdsc_a2h_less64k_unalign");
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
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = 64'h0bee_0000_0000_0000;
		//Set destination address
		odma_desp_templ_item.dst_adr = 64'h0bad_0000_0000_0000;
		//Set source address
		odma_desp_templ_item.src_adr = 64'hbeef_0000_0000_0000;
		
		randomize(list_num) with {list_num >= 2; list_num <= 4;};
		`uvm_info("odma_seq_lib", $sformatf("There are totally %d list.", list_num), UVM_LOW) 
		
		for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(block_desp_q) with {block_desp_q.size inside {[2:4]};};
			`uvm_info("odma_seq_lib", $sformatf("Generate list %d of %d blocks.", k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 64 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("List: %d, Block: %d, Desp Num: %d", k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Total number of descriptor is %d", desp_count), UVM_LOW)
			
			if(k > 0)begin
			write_mmio_patt[64'h0000_0008_8000_5080]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_5084]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			end
			write_mmio_patt[64'h0000_0008_8000_5088]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_1088]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_108c]=32'h0000_0bac;                         //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_1080]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_1008]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_100c]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_a2h_addr[i])begin
				temp_addr=reg_addr_list.mmio_a2h_addr[i];
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("List: %d, Block: %d, Descriptor: %d.", k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
							odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);                            
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
							odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084], write_mmio_patt[64'h0000_0008_8000_5080]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_5080]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_5084]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.dst_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_1008};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
		
			to_break = 0;
			last_desp_num = 0;
			curr_desp_num = 0;
			while(curr_desp_num < desp_count && to_break < 10) begin
				#1000ns;
				curr_desp_num = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0001), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000)}; 
				if(last_desp_num < curr_desp_num)begin
					last_desp_num = curr_desp_num;
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num, desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(curr_desp_num != desp_count)begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0 list number %d.\n", curr_desp_num, desp_count, k))
			end
			else begin
				`uvm_info ("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0 list number %d.\n", curr_desp_num, desp_count, k), UVM_LOW)
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001, 8'h0);
		end

		#10000ns;
    endtask: body
endclass

//sequences of multi channels begin here
//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_block2to4_dsc1to8_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_block2to4_dsc1to8_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_block2to4_dsc1to8_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	//rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_block2to4_dsc1to8_h2a_less64k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		//int list_num = 1;
		int k = 0;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		//randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		//list_num = temp_list_num;
		//for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 20) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 20)begin
				`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list %d.\n", curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list %d.\n", curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		//end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass


//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_block2to4_dsc1to8_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_block2to4_dsc1to8_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_block2to4_dsc1to8_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	//rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_block2to4_dsc1to8_a2h_less64k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int k = 0;
		//int list_num = 1;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		//randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		//list_num = temp_list_num;
		//for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %k of %d blocks.", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_5088 + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_1088 + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_108c + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_1080 + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_1008 + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_100c + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_a2h_addr[i])begin
				temp_addr=reg_addr_list.mmio_a2h_addr[i] + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_1008 + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 20) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 20)begin
				`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list %d.\n", curr_desp_num[x], desp_count), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel 0, list %d.\n", curr_desp_num[x], desp_count))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		//end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list2to4_block2to4_dsc1to8_h2a_less64k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int list_num = 1;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		list_num = temp_list_num;
		`uvm_info("odma_seq_lib", $sformatf("In Channel %d, there are totally %d list.",x ,list_num), UVM_LOW) 
		
		for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 20) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 20)begin
				`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel %h, list %d.\n", curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel %h, list %d.\n", curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list2to4_block2to4_dsc1to8_a2h_less64k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int list_num = 1;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		list_num = temp_list_num;
		`uvm_info("odma_seq_lib", $sformatf("In Channel %d, there are totally %d list.",x ,list_num), UVM_LOW)
		
		for(int k = 0; k < list_num; k++)begin
			desp_count = 0;
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_5088 + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_1088 + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_108c + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_1080 + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_1008 + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_100c + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_a2h_addr[i])begin
				temp_addr=reg_addr_list.mmio_a2h_addr[i] + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_5080 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_5084 + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_1008 + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 20) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 20)begin
				`uvm_info("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel %h, list %d.\n", curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Response number: %d, expected: %d for channel %h, list %d.\n", curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass

//sequences of mix directions begin here
//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	rand bit temp_direction;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_less64k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int list_num = 1;
		bit direction;
		string dir_claim;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		list_num = temp_list_num;
		for(int k = 0; k < list_num; k++)begin
			randomize(temp_direction);
			direction = temp_direction;
			//direction = 1;
			dir_claim = direction ? "Action to Host" : "Host to Action";
			desp_count = 0;
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of direction: %s\n", x, k, dir_claim), UVM_LOW) 
			
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.\n", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d\n", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d\n", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 16'h1000 * direction + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 16'h1000 * direction + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				//`uvm_info("odma_seq_lib", $sformatf("DEBUG_SEND: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end
			
			temp_addr = 64'h0000_0008_8000_100c - 16'h1000 * direction + 12'h100 * x;
			temp_data_carrier=64'h1;
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_CLEAR: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.\n", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h10000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h10000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_ACTION: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 100) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 100)begin
				`uvm_info("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns\n", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns\n", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns\n", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns\n", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	rand bit temp_direction;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list2to4_block2to4_dsc1to8_mixdrt_hardlen_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int list_num = 1;
		bit direction;
		string dir_claim;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		list_num = temp_list_num;
		for(int k = 0; k < list_num; k++)begin
			randomize(temp_direction);
			direction = temp_direction;
			dir_claim = direction ? "Action to Host" : "Host to Action";
			desp_count = 0;
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of direction: %s\n", x, k, dir_claim), UVM_LOW) 
			
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.\n", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d\n", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d\n", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 16'h1000 * direction + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 16'h1000 * direction + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end
			
			temp_addr = 64'h0000_0008_8000_100c - 16'h1000 * direction + 12'h100 * x;
			temp_data_carrier=64'h1;
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_CLEAR: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.\n", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h4000 || (length >= 28'h0100000 && length <= 28'h0104000);});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 1000) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 1000)begin
				`uvm_info("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns\n", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns\n", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns\n", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns\n", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#10000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	//rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	rand bit temp_direction;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list32_block2to4_dsc1to8_mixdrt_less4k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		//int list_num = 1;
		bit direction;
		string dir_claim;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		//randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		//list_num = temp_list_num;
		for(int k = 0; k < 32; k++)begin
			randomize(temp_direction);
			direction = temp_direction;
			//direction = 1;
			dir_claim = direction ? "Action to Host" : "Host to Action";
			desp_count = 0;
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of direction: %s\n", x, k, dir_claim), UVM_LOW) 
			
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.\n", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 8 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d\n", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d\n", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 16'h1000 * direction + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 16'h1000 * direction + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				//`uvm_info("odma_seq_lib", $sformatf("DEBUG_SEND: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end
			
			temp_addr = 64'h0000_0008_8000_100c - 16'h1000 * direction + 12'h100 * x;
			temp_data_carrier=64'h1;
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_CLEAR: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.\n", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h1000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h1000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h1000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_ACTION: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 100) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 100)begin
				`uvm_info("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns\n", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns\n", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns\n", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns\n", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list32_block2to4_dsc1to64_mixdrt_less128B_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list32_block2to4_dsc1to64_mixdrt_less128B_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list32_block2to4_dsc1to64_mixdrt_less128B_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	//rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	rand bit temp_direction;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list32_block2to4_dsc1to64_mixdrt_less128B_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		//int list_num = 1;
		bit direction;
		string dir_claim;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		//randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		//list_num = temp_list_num;
		for(int k = 0; k < 32; k++)begin
			randomize(temp_direction);
			direction = temp_direction;
			//direction = 1;
			dir_claim = direction ? "Action to Host" : "Host to Action";
			desp_count = 0;
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of direction: %s\n", x, k, dir_claim), UVM_LOW) 
			
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.\n", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 64 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d\n", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d\n", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 16'h1000 * direction + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 16'h1000 * direction + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				//`uvm_info("odma_seq_lib", $sformatf("DEBUG_SEND: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end
			
			temp_addr = 64'h0000_0008_8000_100c - 16'h1000 * direction + 12'h100 * x;
			temp_data_carrier=64'h1;
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_CLEAR: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.\n", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h0000080;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h1000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h80;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_ACTION: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 100) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 100)begin
				`uvm_info("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns\n", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns\n", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns\n", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns\n", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//
// SEQUENCE: odma_seq_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_unalign
//
//------------------------------------------------------------------------------
class odma_seq_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_unalign extends bfm_sequence_base;

    `uvm_object_utils(odma_seq_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_unalign)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    temp_capp_tag capp_tag=new();
    odma_reg_addr reg_addr_list=new();
	
	rand int unsigned temp_desp_q[$];
	rand int temp_list_num = 1;
	rand bit[31:0]start_time;
	rand bit temp_direction;
	
    bit [31:0] write_mmio_patt [int unsigned];
    init_mem_desp init_mem_desp_item=new();
    init_host_mem init_host_mem_item; 

    function new(string name= "odma_seq_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k_unalign");
        super.new(name);
    endfunction: new

	task delay(bit[7:0] delay_time);
		for(int i = 0; i < delay_time; i++)begin
		#10ns;
		end
	endtask
	
	task channel(bit[3:0] x);
	
		tl_tx_trans trans;
		
		bit [63:0] temp_data_carrier;
		odma_desp_templ odma_desp_templ_item=new();
		bit[31:0][7:0] desp_item;
		int unsigned block_desp_q[$];
		
		int desp_count = 0;
		int to_break = 0;
		bit[63:0] last_desp_num[3:0];
		bit[63:0] curr_desp_num[3:0];
		bit[63:0] temp_addr;
		bit[2:0]  temp_plength;
		int list_num = 1;
		bit direction;
		string dir_claim;
		
        //Turn off address 128B align constrain
        odma_desp_templ_item.addr_align.constraint_mode(0);
		//Set descriptor address
		odma_desp_templ_item.nxt_adr = {x, 60'hbee_0000_0000_0000};
		//Set destination address
		odma_desp_templ_item.dst_adr = {x, 60'hbad_0000_0000_0000};
		//Set source address
		odma_desp_templ_item.src_adr = {x, 60'heef_0000_0000_0000};
		
		randomize(temp_list_num) with {temp_list_num >= 2; temp_list_num <= 4;};
		list_num = temp_list_num;
		for(int k = 0; k < list_num; k++)begin
			randomize(temp_direction);
			direction = temp_direction;
			//direction = 1;
			dir_claim = direction ? "Action to Host" : "Host to Action";
			desp_count = 0;
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of direction: %s\n", x, k, dir_claim), UVM_LOW) 
			
			//Randomize an array for block_num and desp_num
			randomize(temp_desp_q) with {temp_desp_q.size inside {[2:4]};};
			block_desp_q = {temp_desp_q};
			`uvm_info("odma_seq_lib", $sformatf("Channel %d Generate list %d of %d blocks.\n", x, k, block_desp_q.size), UVM_LOW)        
			foreach(block_desp_q[m])begin
				//TODO: Generate not a multiple of 4 integer when design support partial reaed+
				block_desp_q[m] = block_desp_q[m] % 64 + 1;
				desp_count += block_desp_q[m];
				`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Desp Num: %d\n", x, k, m, block_desp_q[m]), UVM_LOW)                    
			end
			`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d Total number of descriptor is %d\n", x, k, desp_count), UVM_LOW)     

			write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];    //host memory address low 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];   //host memory address high 32-bit for descriptor
			write_mmio_patt[64'h0000_0008_8000_4088 + 16'h1000 * direction + 12'h100 * x]={26'h0, (block_desp_q[0]-1)};          //number of adjacent descriptors(in first block)
			write_mmio_patt[64'h0000_0008_8000_0088 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //host memory address low 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_008c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0bac + 16'h1000 * x;          //host memory address high 32-bit for write back status
			write_mmio_patt[64'h0000_0008_8000_0080 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0400;                         //write back status buffer size: 1KB
			write_mmio_patt[64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x]=32'h0000_0000;                         //Set run bit to 0
			write_mmio_patt[64'h0000_0008_8000_000c + 16'h1000 * direction + 12'h100 * x]=32'h0000_0001;                         //Set clear bit

			foreach(reg_addr_list.mmio_h2a_addr[i])begin
				temp_addr=reg_addr_list.mmio_h2a_addr[i] + 16'h1000 * direction + 12'h100 * x;
				temp_data_carrier={32'h0, write_mmio_patt[temp_addr]};
				temp_plength=2;
				void'(capp_tag.randomize());
				//`uvm_info("odma_seq_lib", $sformatf("DEBUG_SEND: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
				`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
															trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			end
			
			temp_addr = 64'h0000_0008_8000_100c - 16'h1000 * direction + 12'h100 * x;
			temp_data_carrier=64'h1;
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_CLEAR: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

			//Generate descriptors in each block
			foreach(block_desp_q[n])begin
				for(int i=0; i<block_desp_q[n]; i++)begin
					`uvm_info("odma_seq_lib", $sformatf("Channel %d List: %d, Block: %d, Descriptor: %d.\n", x, k, n, i), UVM_LOW)
					if(i<block_desp_q[n]-1)begin
						void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n]-2-i); control == 8'h00; length <= 28'h1000;});
						odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
						odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
					else begin
						if(n == block_desp_q.size -1)begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == 0; control == 8'h01; length <= 28'h1000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						else begin
							void'(odma_desp_templ_item.randomize()with{nxt_adj == (block_desp_q[n+1]-1); control == 8'h00; length <= 28'h1000;});
							odma_desp_templ_item.dst_adr += (odma_desp_templ_item.length + odma_desp_templ_item.dst_adr_var);
							odma_desp_templ_item.src_adr += (odma_desp_templ_item.length + odma_desp_templ_item.src_adr_var);
						end
						//Tag target address
						for(int j=0; j<odma_desp_templ_item.length; j++)begin
						    odma_desp_templ_item.dst_adr_q.push_back(odma_desp_templ_item.dst_adr+i);
						end
						//Generate descriptor address                    
						odma_desp_templ_item.nxt_adr += odma_desp_templ_item.nxt_adr_var;
						//Print a descriptor
						odma_desp_templ_item.desp_info_print(odma_desp_templ_item);
						//Write a descriptor to memory
						desp_item=init_mem_desp_item.desp2data_q(odma_desp_templ_item);
						init_mem_desp_item.init_data_queue(desp_item);
						//Initial host memory data for descriptors
						p_sequencer.host_mem.set_memory_by_length(({write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x], write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]}+32*i), 32, init_mem_desp_item.init_data_queue(desp_item));
						//Set descriptor base address for next block
						write_mmio_patt[64'h0000_0008_8000_4080 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[31:0];                         //host memory address low 32-bit for descriptor
						write_mmio_patt[64'h0000_0008_8000_4084 + 16'h1000 * direction + 12'h100 * x]=odma_desp_templ_item.nxt_adr[63:32];                        //host memory address high 32-bit for descriptor
						//Initial host memory data for read commands
						p_sequencer.host_mem.set_memory_by_length(odma_desp_templ_item.src_adr, odma_desp_templ_item.length, init_host_mem_item.init_data_queue(odma_desp_templ_item.length));
					end
				end
			end

			//Action start
			temp_addr={64'h0000_0008_8000_0008 + 16'h1000 * direction + 12'h100 * x};
			temp_data_carrier={32'h0, write_mmio_patt[temp_addr][31:1], 1'b1};
			temp_plength=2;
			void'(capp_tag.randomize());
			//`uvm_info("odma_seq_lib", $sformatf("DEBUG_ACTION: Channel %d, List: %d, Direction: %s, temp_addr = %16h, data = %16h\n", x, k, dir_claim, temp_addr, temp_data_carrier), UVM_LOW)
			`uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
														trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
			
			to_break = 0;
			for(int y = 0; y < 4; y++)begin
				last_desp_num[y] = 0;
			end
			curr_desp_num[x] = 0;
			while(curr_desp_num[x] < desp_count && to_break < 100) begin
				#1000ns;
				for(int y = 0; y < 4; y++)begin
					curr_desp_num[y] = {p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_000 + 48'h1000_0000_0000 * y), p_sequencer.host_mem.read_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * y)};
				end
				
				if((last_desp_num[0] < curr_desp_num[0]) || (last_desp_num[1] < curr_desp_num[1]) || (last_desp_num[2] < curr_desp_num[2]) || (last_desp_num[3] < curr_desp_num[3]))begin
					for(int y = 0; y < 4; y++)begin
						last_desp_num[y] = curr_desp_num[y];
					end
					to_break = 0;
					`uvm_info("odma_seq_lib", $sformatf("In Loop: %d / %d\n", curr_desp_num[x], desp_count), UVM_MEDIUM)
				end
				else begin
					to_break++;
				end
			end
			
			if(to_break < 100)begin
				`uvm_info("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k), UVM_LOW)
				
			end
			else begin
				`uvm_error("odma_seq_lib", $sformatf("Channel %d list %d Response number: %d, expected: %d for channel %h, list %d.\n", x, k, curr_desp_num[x], desp_count, x, k))
			end
			
			#1000ns;
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0000 + 48'h1000_0000_0000 * x, 8'h0);
			p_sequencer.host_mem.set_byte(64'h0000_0bac_0000_0001 + 48'h1000_0000_0000 * x, 8'h0);
		end
	endtask: channel
	
    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;
		
		p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,1,1,1,0,0,0,0,0,0,0,0}; //Use template 0,1,2,3.
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        p_sequencer.brdg_cfg.enable_brdg_scoreboard = 0; //Disable bridge scoreboard
		
        randomize(start_time) with {!((start_time[7:0] == start_time[15:8]) || (start_time[15:8] == start_time[23:16]) || (start_time[23:16] == start_time[31:24]));};
		`uvm_info("odma_seq_lib", $sformatf("Random delay time for channel 0-3 are separately %d, %d, %d, %dns\n", start_time[ 7: 0] * 10, start_time[15: 8] * 10, start_time[23:16] * 10, start_time[31:24] * 10), UVM_LOW)
		fork
			begin
				delay(start_time[ 7: 0]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 0 starts, delay time: %d ns\n", start_time[ 7: 0] * 10), UVM_LOW)
				channel(0);
			end
			begin
				delay(start_time[15: 8]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 1 starts, delay time: %d ns\n", start_time[15: 8] * 10), UVM_LOW)
				channel(1);
			end
			begin
				delay(start_time[23:16]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 2 starts, delay time: %d ns\n", start_time[23:16] * 10), UVM_LOW)
				channel(2);
			end
			begin
				delay(start_time[31:24]);
				`uvm_info("odma_seq_lib", $sformatf("Channel 3 starts, delay time: %d ns\n", start_time[31:24] * 10), UVM_LOW)
				channel(3);
			end
		join

		#100000ns;
    endtask: body
endclass
`endif
