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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 0;

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
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
        end
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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 0;
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
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr; foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;act_trans.act_intrp==0;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            //Set address not cross a 4KB boundary
            read_addr[11:0] = 0;
            write_addr[11:0] = 0;
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, 4096, init_host_mem_item.init_data_queue(4096));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==8'h1f; act_trans.axi_size==3'h7; act_trans.axi_id==0;
                                                             act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;rd_len==8'h0;wr_len==8'h0;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int unsigned rd_block_byte;
    int unsigned wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h6;wr_size==3'h6;rd_len==8'h0;wr_len==8'h0;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h5;wr_size==3'h5;rd_len==8'h6;wr_len==8'h6;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1;
        p_sequencer.brdg_cfg.total_write_num = 1;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1; num++)begin
            void'(axi_item.randomize()with{rd_size==3'h5;wr_size==3'h5;rd_len==8'h0;wr_len==8'h0;});
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;rd_len==8'h6;wr_len==8'h6;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_size==3'h6;wr_size==3'h6;rd_len==8'h6;wr_len==8'h6;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==0; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;rd_len==8'h0;wr_len==8'h0;rd_id<4;wr_id<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_size==3'h7;wr_size==3'h7;rd_id<4;wr_id<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_id<4;wr_id<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==0; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==0; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_size==7;wr_size==7;rd_len==0;wr_len==0;rd_id==0;wr_id==0;rd_usr<4;wr_usr<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_size==7;wr_size==7;rd_len==0;wr_len==0;rd_id<4;wr_id<4;rd_usr<4;wr_usr<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 20;
        p_sequencer.brdg_cfg.total_write_num = 20;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<20; num++)begin
            void'(axi_item.randomize()with{rd_id<4;wr_id<4;rd_usr<4;wr_usr<4;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #800000ns;
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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 100;
        p_sequencer.brdg_cfg.total_write_num = 100;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<100; num++)begin
            void'(axi_item.randomize()with{rd_size==7;wr_size==7;rd_len==31;wr_len==31;rd_id<4;wr_id<4;rd_usr==0;wr_usr==0;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 100;
        p_sequencer.brdg_cfg.total_write_num = 100;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<100; num++)begin
            void'(axi_item.randomize()with{rd_id<4;wr_id<4;rd_usr<4;wr_usr<4;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #8000000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_rd_wr_100_randsize_randlen_strobe_unaligned_randid_harduser
//
//------------------------------------------------------------------------------
class bfm_seq_rd_wr_100_randsize_randlen_strobe_unaligned_randid_harduser extends bfm_sequence_base; //Super
    `uvm_object_utils(bfm_seq_rd_wr_100_randsize_randlen_strobe_unaligned_randid_harduser)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
    bit[8:0] hard_user_q[$];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_rd_wr_100_randsize_randlen_strobe_unaligned_randid_harduser");
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
        p_sequencer.brdg_cfg.total_read_num = 100;
        p_sequencer.brdg_cfg.total_write_num = 100;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

	//Random AXI user in hard mode
        randomize(hard_user_q) with {hard_user_q.size inside {16,24,32};};
        foreach(hard_user_q[i])begin
            if(i%8==0)begin
                hard_user_q[i]=hard_user_q[i]%64;
            end else begin
                hard_user_q[i]=64*(i%8)+hard_user_q[i/8*8];
            end
        end

        for(int num=0; num<100; num++)begin
            void'(axi_item.randomize()with{rd_usr inside{hard_user_q}; wr_usr inside{hard_user_q};});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;})
        end

        #40000000ns;
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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1000; num++)begin
            void'(axi_item.randomize()with{rd_size==6;wr_size==6;rd_id==0;wr_id==0;rd_usr==0;wr_usr==0;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1000; num++)begin
            void'(axi_item.randomize()with{rd_size==6;wr_size==6;rd_usr==0;wr_usr==0;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1000; num++)begin
            void'(axi_item.randomize()with{rd_size==7;wr_size==7;rd_len==31;wr_len==31;rd_id<4;wr_id<4;rd_usr==0;wr_usr==0;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1000; num++)begin
            void'(axi_item.randomize());
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

        #40000000ns;
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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
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
            void'(axi_item.randomize()with{rd_id==0;wr_id==0;rd_usr==0;wr_usr==0;});
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
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Set max delays for AXI interface
        p_sequencer.act_cfg.mst_dly_mode = act_cfg_obj::MAX_DELAY;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize()with{rd_id==0;wr_id==0;rd_usr==0;wr_usr==0;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 10;
        p_sequencer.brdg_cfg.total_write_num = 10;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Set min delays for AXI interface
        p_sequencer.act_cfg.mst_dly_mode = act_cfg_obj::MIN_DELAY;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<10; num++)begin
            void'(axi_item.randomize()with{rd_id==0;wr_id==0;rd_usr==0;wr_usr==0;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;foreach(act_trans.data_strobe[i]) act_trans.data_strobe[i]==128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 0;
        p_sequencer.brdg_cfg.total_write_num = 64;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<64; num++)begin
            void'(axi_item.randomize()with{wr_id==0;wr_usr==0;});
            //read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            //rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            //read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            //p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            //`uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
            //                                                 act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;})
        end

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

    axi_mm_transaction act_trans;
    bridge_axi_item axi_item=new();
    bit [63:0] read_addr;
    bit [63:0] write_addr;
    int rd_block_byte;
    int wr_block_byte;
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

        //Set resd/write/interrupt number
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 1000;
        p_sequencer.brdg_cfg.total_write_num = 1000;

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Initial read/write address
        void'(axi_item.randomize());
        read_addr={axi_item.read_addr_high[31:0],axi_item.read_addr_low[31:0]};
        write_addr={axi_item.write_addr_high[31:0],axi_item.write_addr_low[31:0]};

        for(int num=0; num<1000; num++)begin
            void'(axi_item.randomize()with{rd_usr==0;wr_usr==0;});
            read_addr+=axi_item.rd_adr_var;
            write_addr+=axi_item.wr_adr_var;
            rd_block_byte=(1<<axi_item.rd_size)*(axi_item.rd_len+1);
            wr_block_byte=(1<<axi_item.wr_size)*(axi_item.wr_len+1);
            //Set address not cross a 4KB boundary
            read_addr[11:0] = (4096 - rd_block_byte) == 0 ? 0 : (read_addr[31:0] % (4096 - rd_block_byte));
            write_addr[11:0] = (4096 - wr_block_byte) == 0 ? 0 : (write_addr[31:0] % (4096 - wr_block_byte));
            //Set address aligned to axi size
            //read_addr[11:0] = read_addr[11:0]&(12'hFFF<<axi_item.rd_size);
            //write_addr[11:0] = write_addr[11:0]&(12'hFFF<<axi_item.wr_size);
            //Initial host memory data for read commands
            p_sequencer.host_mem.set_memory_by_length(read_addr, rd_block_byte, init_host_mem_item.init_data_queue(rd_block_byte));

            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::READ; act_trans.axi_len==axi_item.rd_len; act_trans.axi_size==axi_item.rd_size;
                                                             act_trans.axi_id==axi_item.rd_id; act_trans.axi_usr==axi_item.rd_usr; act_trans.addr==read_addr;act_trans.act_intrp==0;})
            `uvm_do_on_with(act_trans, p_sequencer.act_sqr, {act_trans.trans==axi_mm_transaction::WRITE; act_trans.axi_len==axi_item.wr_len; act_trans.axi_size==axi_item.wr_size;
                                                             act_trans.axi_id==axi_item.wr_id; act_trans.axi_usr==axi_item.wr_usr; act_trans.addr==write_addr;act_trans.act_intrp==0;})
        end

        #100000us;
    endtask: body
endclass

`endif

