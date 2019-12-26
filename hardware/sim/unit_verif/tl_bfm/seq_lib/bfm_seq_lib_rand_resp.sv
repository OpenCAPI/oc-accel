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
`ifndef _BFM_SEQ_LIB_RAND_RESP
`define _BFM_SEQ_LIB_RAND_RESP

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1_rand_resp extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

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

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #1000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n64_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n64_rand_resp extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n64_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n64_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 64;
        p_sequencer.brdg_cfg.total_write_num = 64;

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

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<64; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1024_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1024_rand_resp extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1024_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1024_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

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

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1024; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #20000us;        
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n2048_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n2048_rand_resp extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n2048_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n2048_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 2048;
        p_sequencer.brdg_cfg.total_write_num = 2048;

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

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<2048; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #50000us;        
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n4096_rand_resp
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n4096_rand_resp extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n4096_rand_resp)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n4096_rand_resp");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 4096;
        p_sequencer.brdg_cfg.total_write_num = 4096;

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

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<4096; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #120000us;        
    endtask: body

endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        // p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        // p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        // p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        // p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        // p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        // p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        // p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        // p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        // p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        // p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        // p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        // p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        // p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1_rand_resp_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

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

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n64_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n64_rand_resp_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n64_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n64_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 64;
        p_sequencer.brdg_cfg.total_write_num = 64;

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

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<64; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #200000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n64_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n64_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n64_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n64_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 64;
        p_sequencer.brdg_cfg.total_write_num = 64;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        // p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        // p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        // p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        // p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        // p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        // p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        // p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        // p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        // p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        // p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        // p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        // p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        // p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<64; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1024_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1024_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1024_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1024_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1024;
        p_sequencer.brdg_cfg.total_write_num = 1024;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Enable retry/xlate_pending/reorder/delay
        void'(tl_resp_rand_item.randomize());        
        // p_sequencer.cfg_obj.wr_fail_percent = tl_resp_rand_item.wr_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.rd_fail_percent = tl_resp_rand_item.rd_fail_percent; //Range 0-100
        // p_sequencer.cfg_obj.resp_rty_weight = tl_resp_rand_item.resp_rty_weight;
        // p_sequencer.cfg_obj.resp_xlate_weight = tl_resp_rand_item.resp_xlate_weight;
        // p_sequencer.cfg_obj.resp_derror_weight = tl_resp_rand_item.resp_derror_weight;
        // p_sequencer.cfg_obj.resp_failed_weight = tl_resp_rand_item.resp_failed_weight;
        // p_sequencer.cfg_obj.resp_reserved_weight = tl_resp_rand_item.resp_reserved_weight;
        // p_sequencer.cfg_obj.resp_reorder_enable = tl_resp_rand_item.resp_reorder_enable;
        // p_sequencer.cfg_obj.resp_reorder_window_cycle = tl_resp_rand_item.resp_reorder_window_cycle;
        // p_sequencer.cfg_obj.resp_delay_cycle = tl_resp_rand_item.resp_delay_cycle;
        // p_sequencer.cfg_obj.xlate_done_cmp_weight = tl_resp_rand_item.xlate_done_cmp_weight;
        // p_sequencer.cfg_obj.xlate_done_rty_weight = tl_resp_rand_item.xlate_done_rty_weight;
        // p_sequencer.cfg_obj.xlate_done_aerror_weight = tl_resp_rand_item.xlate_done_aerror_weight;
        // p_sequencer.cfg_obj.xlate_done_reserved_weight = tl_resp_rand_item.xlate_done_reserved_weight;
        // p_sequencer.cfg_obj.host_back_off_timer = tl_resp_rand_item.host_back_off_timer;
        p_sequencer.cfg_obj.wr_resp_num_2_weight = tl_resp_rand_item.wr_resp_num_2_weight;
        p_sequencer.cfg_obj.rd_resp_num_2_weight = tl_resp_rand_item.rd_resp_num_2_weight;
        p_sequencer.cfg_obj.split_reorder_enable = 1;

        `uvm_info(get_type_name(), $psprintf("Randomize tl response config with wr_fail_percent:%d, rd_fail_percent:%d, resp_rty_weight:%d, resp_xlate_weight:%d, resp_derror_weight:%d,resp_failed_weight:%d, resp_reserved_weight:%d, resp_reorder_enable:%d, resp_reorder_window_cycle:%d, resp_delay_cycle:%d, xlate_done_cmp_weight:%d, xlate_done_rty_weight:%d, xlate_done_aerror_weight:%d, xlate_done_reserved_weight:%d, host_back_off_timer:%d.", p_sequencer.cfg_obj.wr_fail_percent, p_sequencer.cfg_obj.rd_fail_percent, p_sequencer.cfg_obj.resp_rty_weight, p_sequencer.cfg_obj.resp_xlate_weight, p_sequencer.cfg_obj.resp_derror_weight, p_sequencer.cfg_obj.resp_failed_weight, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_enable, p_sequencer.cfg_obj.resp_reorder_window_cycle, p_sequencer.cfg_obj.resp_delay_cycle, p_sequencer.cfg_obj.xlate_done_cmp_weight, p_sequencer.cfg_obj.xlate_done_rty_weight, p_sequencer.cfg_obj.xlate_done_aerror_weight, p_sequencer.cfg_obj.xlate_done_reserved_weight, p_sequencer.cfg_obj.host_back_off_timer), UVM_NONE)

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1024; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #600000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n2048_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n2048_rand_resp_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n2048_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n2048_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 2048;
        p_sequencer.brdg_cfg.total_write_num = 2048;

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

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<2048; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n4096_rand_resp_split
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n4096_rand_resp_split extends bfm_sequence_base;
    `uvm_object_utils(bfm_seq_read_4k_write_4k_n4096_rand_resp_split)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    tl_resp_rand tl_resp_rand_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n4096_rand_resp_split");
        super.new(name);
    endfunction: new

    task body();
        #50ns;
        `uvm_do(return_initial_credits)
        #100ns;
        `uvm_do(initial_config)
        #10000ns;

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 4096;
        p_sequencer.brdg_cfg.total_write_num = 4096;

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

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<4096; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            //wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            ////Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            //write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            ////Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #25000us;
    endtask: body
endclass
`endif

