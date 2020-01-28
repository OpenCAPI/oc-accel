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
// SEQUENCE: bfm_seq_read_write_mmio
//
//------------------------------------------------------------------------------
class bfm_seq_read_write_mmio extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_write_mmio)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    function new(string name= "bfm_seq_read_write_mmio");
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
        p_sequencer.brdg_cfg.total_read_num = 0;
        p_sequencer.brdg_cfg.total_write_num = 0;

        //MMIO global register traveling read
        foreach(reg_addr_list.glb_mmio_addr[i])begin
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_RD_MEM; trans.plength==3; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==reg_addr_list.glb_mmio_addr[i];})
        end
        //MMIO action register 10 read/write
        //MMIO write
        for(int i=0; i<10; i++)begin
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==2; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr[63:28]==36'h0000_0008_8;trans.physical_addr[1:0]==2'b0;})
        end
        //MMIO read
        for(int i=0; i<10; i++)begin
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_RD_MEM; trans.plength==2; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr[63:28]==36'h0000_0008_8;trans.physical_addr[1:0]==2'b0;})
        end
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==3; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr[63:0]==64'h0000_0008_0000_0010;trans.data_carrier[0]==0;})

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 1;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[11:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[11:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            if(num==9)begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            end else begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            end
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 2;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            if(num==9 || num==0)begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            end else begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            end
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 20;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==1;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #3000000ns;
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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 1;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;    
        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            if(num==9)begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            end else begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            end
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #1000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_10_randsize_randlen_intrp_2_rty extends bfm_sequence_base; //Ten ?B*? read and write

    `uvm_object_utils(bfm_seq_rd_wr_10_randsize_randlen_intrp_2)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 2;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;      
        
        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            if(num==9 || num==0)begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            end else begin
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            end
                `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 20;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Config interrupt retry
        p_sequencer.cfg_obj.inject_err_enable = 1;       
        p_sequencer.cfg_obj.inject_err_type = tl_cfg_obj::RESP_CODE_VALID_RTY_PENDING;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==1;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                                 act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==1;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end
        
        #5000000ns;
    endtask: body
endclass

`endif
