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
`ifndef _BFM_SEQ_LIB
`define _BFM_SEQ_LIB

//------------------------------------------------------------------------------
//
// CLASS: transction variables
//
//------------------------------------------------------------------------------
class temp_capp_tag;
    randc bit[15:0] capp;
endclass

class init_data;
    rand bit [7:0] host_init_data;
endclass

class bridge_test_item;
    rand bit [63:0] source_addr;
    rand bit [63:0] source_size;
    rand bit [63:0] target_size;
    rand bit [63:0] target_addr;
    rand bit [32:0] seed;
    constraint rand_all_resp{
    source_addr[63:62] == 2'b00;
    target_addr[63:62] == 2'b10;    
    }
endclass

class tl_resp_rand;
    //Random retry/xlate_pending/reorder/delay
    rand int wr_fail_percent = 50;                         //Percentage of write fail response: 0-100                   
    rand int rd_fail_percent = 50;                         //Percentage of read fail response: 0-100
    rand int resp_rty_weight = 20;                         //Weight of write/read fail response for resp code rty_req
    rand int resp_xlate_weight = 20;                       //Weight of write/read fail response for resp code xlate_pending
    rand int resp_derror_weight = 0;                       //Weight of write/read fail response for resp code derror
    rand int resp_failed_weight = 0;                       //Weight of write/read fail response for resp code failed
    rand int resp_reserved_weight = 0;                     //Weight of write/read fail response for resp code reserved
    rand int resp_reorder_enable = 1;                      //Enable sending memory write/read response out-of-order
    rand int resp_reorder_window_cycle = 100;              //Clock cycles to delay sending memory write/read response(not precise) when reorder enable
    rand int resp_delay_cycle = 0;                         //Clock cycles of window to collect memory write/read resp when reorder enabled
    rand int xlate_done_cmp_weight = 20;                   //Weight of xlate done for resp code completed
    rand int xlate_done_rty_weight = 20;                   //Weight of xlate done for resp code rty_req
    rand int xlate_done_aerror_weight = 0;                 //Weight of xlate done for resp code addr error
    rand int xlate_done_reserved_weight = 0;               //Weight of xlate done for resp code reserved
    rand int host_back_off_timer = 0;                      //Timer in clock cycle for host back-off event
	rand int wr_resp_num_2_weight = 100;
	rand int rd_resp_num_2_weight = 100;

    constraint rand_all_resp{
        wr_fail_percent>0; wr_fail_percent<30;
        rd_fail_percent>0; rd_fail_percent<30;
        resp_rty_weight>0; resp_rty_weight<100;
        resp_xlate_weight>0; resp_xlate_weight<100; 
        resp_derror_weight==0;
        resp_failed_weight==0;
        resp_reserved_weight==0;
        resp_reorder_enable==1;
        resp_reorder_window_cycle>100; resp_reorder_window_cycle<200;
        resp_delay_cycle>10; resp_delay_cycle<20;
        xlate_done_cmp_weight>0; xlate_done_cmp_weight<100; 
        xlate_done_rty_weight>0; xlate_done_rty_weight<100; 
        xlate_done_aerror_weight==0;
        xlate_done_reserved_weight==0;
        host_back_off_timer>10; host_back_off_timer<20;
		wr_resp_num_2_weight >= 100; wr_resp_num_2_weight <= 200;
		rd_resp_num_2_weight >= 100; rd_resp_num_2_weight <= 200;
    }

endclass

class reg_addr;
    bit [31:0]  config_write_addr [12:0] = '{
    32'h0000_030c, //Function 0, Extended Capabilities, DVSEC, Function(0xF001), [27:16]Function acTag Base; [11:0]Function acTag Length Enabled; Others Reserved
    32'h0000_0224, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), TLX Transmit Template Con-figuration (31:0)
    32'h0000_026c, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 7-0)
    32'h0001_0010, //Function 1, Configuration Space Header, MMIO BAR 0 Low
    32'h0001_0014, //Function 1, Configuration Space Header, MMIO BAR 0 High
    32'h0001_0004, //Function 1, Configuration Space Header, [20]Capabilities List; [1]Enable Response to BAR Memory Space Access; Others Reserved
    32'h0001_0408, //Function 1, Extended Capabilities, DVSEC, AFU Information(0xF003), [21:16]AFU Info Index; [15:0]DVSEC ID; Others Reserved
    32'h0001_0510, //Function 1, Extended Capabilities, DVSEC, AFU Control(0xF004), [12:8]PASID Length Enabled; [4:0]PASID Length Supported; Others Reserved
    32'h0001_0514, //Function 1, Extended Capabilities, DVSEC, AFU Control(0xF004), [28]MetaData is Supported; [27]MetaData is Enabled; [26:20]Default MetaData; Others Reserved
    32'h0001_0518, //Function 1, Extended Capabilities, DVSEC, AFU Control(0xF004), [27:16]AFU acTag Length Enabled; [11:0]AFU acTag Length Sup-ported; Others Reserved
    32'h0001_051c, //Function 1, Extended Capabilities, DVSEC, AFU Control(0xF004), [11:0]AFU acTag Base; Others Reserved
    32'h0001_050c, //Function 1, Extended Capabilities, DVSEC, AFU Control(0xF004), [25]Fence AFU; [24]Enable AFU; [20]Terminate Valid; [19:0]Terminate Valid; Others Reserved
    32'h0001_030c  //Function 1, Extended Capabilities, DVSEC, Function(0xF001), [27:16]Function acTag Base; [11:0]Function acTag Length Enabled; Others Reserved
    };

    bit [31:0]  config_read_addr [4:0] = '{
    32'h0000_0000, //Function 0, Configuration Space Header, Device ID[31:16], Vendor ID[15:0]
    //32'h0000_0218, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), TLX Receive Template Con-figuration (63:32)
    32'h0000_021c, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), TLX Receive Template Con-figuration (31:0) 
    //32'h0000_0220, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), TLX Transmit Template Con-figuration (63:32)
    32'h0000_0224, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), TLX Transmit Template Con-figuration (31:0) 
    //32'h0000_0230, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 63-56)
    //32'h0000_0234, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 55-48)
    //32'h0000_0238, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 47-40)
    //32'h0000_023c, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 39-32)
    //32'h0000_0240, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 31-24)
    //32'h0000_0244, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 23-16)
    //32'h0000_0248, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 15-8)
    32'h0000_024c, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Rcv Rate (Templates 7-0)
    //32'h0000_0250, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 63-56)
    //32'h0000_0254, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 55-48)
    //32'h0000_0258, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 47-40)
    //32'h0000_025c, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 39-32)
    //32'h0000_0260, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 31-24)
    //32'h0000_0264, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 23-16)
    //32'h0000_0268, //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 15-8)
    32'h0000_026c  //Function 0, Extended Capabilities, DVSEC, OpenCAPI Transport Layer(0xF000), Xmit Rate (Templates 7-0)
    };

    bit [63:0]  mmio_write_addr [15:0] = '{
    64'h0000_0008_8000_0038, //ADDR_CONTROL_L, [0]start, [32]rand_arlen, [48]rand_awlen, [49]rand_wstrobe
    64'h0000_0008_8000_003c, //ADDR_CONTROL_H          
    64'h0000_0008_8000_0040, //ADDR_PATTERN_SOURCE_ADDRESS_L 
    64'h0000_0008_8000_0044, //ADDR_PATTERN_SOURCE_ADDRESS_H
    64'h0000_0008_8000_0048, //ADDR_PATTERN_SOURCE_SIZE_L
    64'h0000_0008_8000_004C, //ADDR_PATTERN_SOURCE_SIZE_H
    64'h0000_0008_8000_0050, //ADDR_PATTERN_TARGET_ADDRESS_L
    64'h0000_0008_8000_0054, //ADDR_PATTERN_TARGET_ADDRESS_H  
    64'h0000_0008_8000_0058, //ADDR_PATTERN_TARGET_SIZE_L
    64'h0000_0008_8000_005C, //ADDR_PATTERN_TARGET_SIZE_H  
    64'h0000_0008_8000_0060, //ADDR_PATTERN_READ_NUMBER_L
    64'h0000_0008_8000_0064, //ADDR_PATTERN_READ_NUMBER_H
    64'h0000_0008_8000_0068, //ADDR_PATTERN_WRITE_NUMBER_L
    64'h0000_0008_8000_006C, //ADDR_PATTERN_WRITE_NUMBER_H
    64'h0000_0008_8000_0070, //ADDR_PATTERN_SEED
    64'h0000_0008_8000_0080  //ADDR_INTERRUPT_PATTERN    
    };

    function new(string name = "reg_addr");
    endfunction
endclass: reg_addr

class reg_rst_value;
    bit [31:0] cfg_rst_value [int unsigned]='{
    32'h0000_030c:32'h0000_0000, 
    32'h0000_0224:32'h0000_000f,
    32'h0000_026c:32'h0000_2730,
    32'h0001_0010:32'h0000_0000, 
    32'h0001_0014:32'h0000_0008, 
    32'h0001_0004:32'h0000_0002, 
    32'h0001_0408:32'h0000_0000, 
    32'h0001_0510:32'h0000_0900,
    32'h0001_0514:32'h0000_0000, 
    32'h0001_0518:32'h0020_0000, 
    32'h0001_051c:32'h0000_0000, 
    32'h0001_050c:32'h0100_0000, 
    32'h0001_030c:32'h0000_0020
    };
    
    function new(string name = "reg_rst_value");
    endfunction
endclass: reg_rst_value

class init_host_mem;
    function host_mem_model::byte_packet_queue init_data_queue(int length);
        init_data init_data_item=new();                
        for(int i=0; i<length; i++)begin
            void'(init_data_item.randomize());
            init_data_queue.push_back(init_data_item.host_init_data);
        end
    endfunction: init_data_queue   
endclass: init_host_mem

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_return_initial_credits
//
//------------------------------------------------------------------------------
class bfm_seq_return_initial_credits extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_return_initial_credits)
    tl_tx_trans trans;

    int initial_tlx_vc_0;
    int initial_tlx_vc_3;
    int initial_tlx_dcp_0;
    int initial_tlx_dcp_3;
    int temp_tlx_vc_0;
    int temp_tlx_vc_3;
    int temp_tlx_dcp_0;
    int temp_tlx_dcp_3;

    function new(string name= "bfm_seq_return_initial_credits");
        super.new(name);
    endfunction: new

    task body();
        initial_tlx_vc_0= p_sequencer.cfg_obj.tlx_vc_credit_count[0];
        initial_tlx_vc_3= p_sequencer.cfg_obj.tlx_vc_credit_count[3];
        initial_tlx_dcp_0= p_sequencer.cfg_obj.tlx_data_credit_count[0];
        initial_tlx_dcp_3= p_sequencer.cfg_obj.tlx_data_credit_count[3];
        p_sequencer.cfg_obj.tl_transmit_template = {1,0,0,0,0,0,0,0,0,0,0,0}; //use template 0 to send return_tlx_credits
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template
        //return all the initial vc credits and dcp credits
        while ((initial_tlx_vc_0>0)||(initial_tlx_vc_3>0)||(initial_tlx_dcp_0>0)||(initial_tlx_dcp_3>0)) begin
            if(initial_tlx_vc_0>15)begin
                temp_tlx_vc_0=15;
                initial_tlx_vc_0-=15;
            end
            else begin
                temp_tlx_vc_0=initial_tlx_vc_0;
                initial_tlx_vc_0=0;
            end

            if(initial_tlx_vc_3>15)begin
                temp_tlx_vc_3=15;
                initial_tlx_vc_3-=15;
            end
            else begin
                temp_tlx_vc_3=initial_tlx_vc_3;
                initial_tlx_vc_3=0;
            end

            if(initial_tlx_dcp_0>63)begin
                temp_tlx_dcp_0=63;
                initial_tlx_dcp_0-=63;
            end
            else begin
                temp_tlx_dcp_0=initial_tlx_dcp_0;
                initial_tlx_dcp_0=0;
            end

            if(initial_tlx_dcp_3>63)begin
                temp_tlx_dcp_3=63;
                initial_tlx_dcp_3-=63;
            end
            else begin
                temp_tlx_dcp_3=initial_tlx_dcp_3;
                initial_tlx_dcp_3=0;
            end

            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::RETURN_TLX_CREDITS; trans.tlx_vc_0==temp_tlx_vc_0; 
                                                        trans.tlx_vc_3==temp_tlx_vc_3;trans.tlx_dcp_0==temp_tlx_dcp_0;trans.tlx_dcp_3==temp_tlx_dcp_3;})
        end
    endtask: body

endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_initial_config
//
//------------------------------------------------------------------------------
class bfm_seq_initial_config extends bfm_sequence_base;

    //bfm_seq_return_initial_credits return_initial_credits;
    `uvm_object_utils(bfm_seq_initial_config)

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    reg_rst_value reg_rst_value_temp=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;

    function new(string name= "bfm_seq_initial_config");
        super.new(name);
    endfunction: new

    task body();
        //`uvm_do(return_initial_credits)
        //#100ns;

        p_sequencer.cfg_obj.host_receive_resp_timer = 20000;
        p_sequencer.cfg_obj.tl_transmit_template = {1,0,0,0,0,0,0,0,0,0,0,0}; //Use template 0
        p_sequencer.cfg_obj.tl_transmit_rate  = {0,3,7,2,0,0,0,0,0,0,0,0}; //Rate for each available template

        foreach(reg_addr_list.config_read_addr[i])begin
            temp_addr={32'h0, reg_addr_list.config_read_addr[i]}; 
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::CONFIG_READ; trans.plength==temp_plength; trans.config_type==0;
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr;})
        end

        foreach(reg_addr_list.config_write_addr[i])begin
            temp_addr={32'h0, reg_addr_list.config_write_addr[i]}; 
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::CONFIG_WRITE; trans.plength==temp_plength; trans.config_type==0;
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr;
                                                        trans.data_carrier[0]=={32'h0, reg_rst_value_temp.cfg_rst_value[reg_addr_list.config_write_addr[i]]};})
        end
        //#25000ns;

    endtask: body

endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k [int unsigned];
    init_host_mem init_host_mem_item;

    function new(string name= "bfm_seq_read_4k");
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
        p_sequencer.brdg_cfg.total_write_num = 0;

        void'(test_item.randomize());
        seq_read_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        seq_read_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        seq_read_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number 1
        seq_read_4k[64'h0000_0008_8000_0064]=32'h0000_0000;
        seq_read_4k[64'h0000_0008_8000_0068]=32'h0000_0000;                         //Write number 0
        seq_read_4k[64'h0000_0008_8000_006C]=32'h0000_0000;
        seq_read_4k[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_write_4k
//
//------------------------------------------------------------------------------
class bfm_seq_write_4k extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_write_4k)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_write_4k [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_write_4k");
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
        p_sequencer.brdg_cfg.total_write_num = 1;

        void'(test_item.randomize());
        seq_write_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_write_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_write_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_write_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_write_4k[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        seq_write_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_write_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_write_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_write_4k[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        seq_write_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_write_4k[64'h0000_0008_8000_0060]=32'h0000_0000;                         //Read number 0
        seq_write_4k[64'h0000_0008_8000_0064]=32'h0000_0000;
        seq_write_4k[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number 1
        seq_write_4k[64'h0000_0008_8000_006C]=32'h0000_0000;
        seq_write_4k[64'h0000_0008_8000_0070]=test_item.seed; 

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_write_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_write_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_write_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_write_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k_write_4k)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k_write_4k [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k");
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
        seq_read_4k_write_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k_write_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0048]=32'h0003_2000;                         //Source size 50*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0058]=32'h0003_2000;                         //Target size 50*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0060]=32'h0000_0001;                         //Read number 1
        seq_read_4k_write_4k[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0068]=32'h0000_0001;                         //Write number 1
        seq_read_4k_write_4k[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k_write_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k_write_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #100000ns;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n1024
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n1024 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k_write_4k_n1024)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k_write_4k [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n1024");
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
        seq_read_4k_write_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k_write_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0048]=32'h0050_0000;                         //Source size 1280*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0058]=32'h0050_0000;                         //Target size 1280*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0060]=32'h0000_0400;                         //Read number 1024
        seq_read_4k_write_4k[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0068]=32'h0000_0400;                         //Write number 1024
        seq_read_4k_write_4k[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k_write_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k_write_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n2048
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n2048 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k_write_4k_n2048)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k_write_4k [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n2048");
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
        seq_read_4k_write_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k_write_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0048]=32'h00a0_0000;                         //Source size 2560*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0058]=32'h00a0_0000;                         //Target size 2560*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0060]=32'h0000_0800;                         //Read number 2048
        seq_read_4k_write_4k[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0068]=32'h0000_0800;                         //Write number 2048
        seq_read_4k_write_4k[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k_write_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k_write_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

//------------------------------------------------------------------------------
//
// SEQUENCE: bfm_seq_read_4k_write_4k_n4096
//
//------------------------------------------------------------------------------
class bfm_seq_read_4k_write_4k_n4096 extends bfm_sequence_base;

    `uvm_object_utils(bfm_seq_read_4k_write_4k_n4096)
    bfm_seq_return_initial_credits return_initial_credits;
    bfm_seq_initial_config initial_config;

    tl_tx_trans trans;
    temp_capp_tag capp_tag=new();
    reg_addr reg_addr_list=new();
    bridge_test_item test_item=new();
    rand bit [63:0] temp_addr;
    rand bit [2:0]  temp_plength;
    bit [63:0] temp_data_carrier;
    bit [31:0] seq_read_4k_write_4k [int unsigned];
    init_host_mem init_host_mem_item;
    function new(string name= "bfm_seq_read_4k_write_4k_n4096");
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

        void'(test_item.randomize());
        seq_read_4k_write_4k[64'h0000_0008_8000_0038]=32'h0000_0000;                         //Without random
        seq_read_4k_write_4k[64'h0000_0008_8000_003c]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0040]={test_item.source_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0044]=test_item.source_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0048]=32'h0200_0000;                         //Source size 8192*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_004C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0050]={test_item.target_addr[63:12], 12'h0}; //Align 4k
        seq_read_4k_write_4k[64'h0000_0008_8000_0054]=test_item.target_addr[63:32];
        seq_read_4k_write_4k[64'h0000_0008_8000_0058]=32'h0200_0000;                         //Target size 8192*4k
        seq_read_4k_write_4k[64'h0000_0008_8000_005C]=32'h0000_0000;
        seq_read_4k_write_4k[64'h0000_0008_8000_0060]=32'h0000_1000;                         //Read number 4096
        seq_read_4k_write_4k[64'h0000_0008_8000_0064]=32'h0000_007B;                         //Read pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0068]=32'h0000_1000;                         //Write number 4096
        seq_read_4k_write_4k[64'h0000_0008_8000_006C]=32'h0000_007B;                         //Write pattern
        seq_read_4k_write_4k[64'h0000_0008_8000_0070]=test_item.seed;

        foreach(reg_addr_list.mmio_write_addr[i])begin
            temp_addr=reg_addr_list.mmio_write_addr[i];
            temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr]};
            temp_plength=2;
            void'(capp_tag.randomize());
            `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                        trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})
        end

        //Initial host memory data for read commands
        p_sequencer.host_mem.set_memory_by_length(test_item.source_addr, seq_read_4k_write_4k[64'h0000_0008_8000_0048], init_host_mem_item.init_data_queue(seq_read_4k_write_4k[64'h0000_0008_8000_0048]));

        //Enable/Disable check read/write 256B in bridge check scorboard
        p_sequencer.brdg_cfg.cmd_rd_256_enable = 0;
        p_sequencer.brdg_cfg.cmd_wr_256_enable = 0;

        //Set total number of transactions
        p_sequencer.brdg_cfg.total_intrp_num = 0;
        p_sequencer.brdg_cfg.total_read_num = 4096;
        p_sequencer.brdg_cfg.total_write_num = 4096;

        //Action start
        temp_addr={64'h0000_0008_8000_0038};
        temp_data_carrier={32'h0, seq_read_4k_write_4k[temp_addr][31:1], 1'b1};
        temp_plength=2;
        void'(capp_tag.randomize());
        `uvm_do_on_with(trans, p_sequencer.tx_sqr, {trans.packet_type==tl_tx_trans::PR_WR_MEM; trans.plength==temp_plength; 
                                                    trans.capp_tag==capp_tag.capp; trans.physical_addr==temp_addr; trans.data_carrier[0]==temp_data_carrier;})

        #10000us;
    endtask: body
endclass

`endif
