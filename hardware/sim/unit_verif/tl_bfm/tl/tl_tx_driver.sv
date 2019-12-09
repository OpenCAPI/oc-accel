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
`ifndef _TL_TX_DRIVER_SV
`define _TL_TX_DRIVER_SV

class tl_tx_driver extends uvm_driver #(tl_tx_trans, tl_trans);
    //Virtual interface definition.
    virtual interface tl_dl_if tl_dl_vif;
    tl_manager                 mgr;
    tl_cfg_obj                 cfg_obj;
    tl_mem_model               mem_model;

    //TLM port & transaction declaration.
    `uvm_analysis_imp_decl(_mgr)
    `uvm_analysis_imp_decl(_credit)
    `uvm_analysis_imp_decl(_sbd)
    uvm_analysis_imp_mgr    #(tl_tx_trans, tl_tx_driver)     tl_mgr_imp;
    uvm_analysis_imp_credit #(dl_credit_trans, tl_tx_driver) tl_credit_imp;
    uvm_analysis_imp_sbd    #(tl_trans, tl_tx_driver)     tl_sbd_resp_imp;

    //Data and command/response structure for packing each transaction.
    class driver_packet;
        int                 cmd_resp_length;         //slot number of command
        int                 data_length;             //byte number of data 
        int                 chk_length;              //byte number of readable/writable data in memory
        bit [27:0]          cmd_resp_packet[6];      //TL cmd and resp  
        bit [7:0]           data_packet[256];        //data in byte
        bit                 read_chk_cmd;            //is a read command
        bit                 write_chk_cmd;           //is a write command
        bit [15:0]          afu_tag;                 //AFU Tag        
        bit [15:0]          capp_tag;                //CAPP Tag
        int                 tl_dcp0;                 //data credits for channel 0
        int                 tl_dcp1;                 //data credits for channel 1
        int                 tl_vc0;                  //command and response redits for channel 0
        int                 tl_vc1;                  //command and response redits for channel 1
        bit [63:0]          physical_addr;           //physical address
        bit [63:0]          chk_addr;                //physical address for readable/writable check
        bit [63:0]          byte_enable;             //byte enable for write_byte_enable
        bit                 data_to_memory;          //the data will be written into memory
        bit [6:0]           meta[4];                 //meta data
        bit [71:0]          xmeta[4];                //extended meta data
        function new(string name = "driver_packet");
        endfunction
    endclass: driver_packet

    //Data struture between packet to flit
    class data_on_carrier;
        bit [511:0]         data_carrier;             //64-byte data carriers
        bit                 is_32byte_length;         //data is 32 bytes or shorter than 32 bytes length
        bit                 addr_high;                //a 32-byte data block placed in the high address of a 64-byte data block
        bit                 only_32byte_carrier;      //the data block can be only placed into 32-byte data carrier
        bit                 only_64byte_carrier;      //the data block can be only placed into 64-byte data carrier
        bit                 data_to_memory;           //the data will be written into memory
        bit [6:0]           meta; 
        bit [71:0]          xmeta; 
        function new(string name = "data_on_carrier");
        endfunction
    endclass: data_on_carrier
    
    //Flit structure to be drived
    class driver_flit;
        bit [511:0]         flit;
        bit                 is_data_flit = 0;
        bit                 is_cntl_flit = 0;
        bit                 is_null_cntl_flit = 0;
        bit                 is_last_data_flit = 0;
        bit                 is_last_cntl_flit = 0;
        function new(string name = "driver_flit");
        endfunction
    endclass: driver_flit

    //delay signals
    class signals_dly;
        bit [127:0]         tl_dl_flit_data = 0;
        bit                 tl_dl_flit_vld = 0;
        bit [15:0]          tl_dl_flit_ecc = 0;
        bit [127:0]         tl_dl_flit_lbip_data = 0;
        bit                 tl_dl_flit_lbip_vld = 0;
        bit [15:0]          tl_dl_flit_lbip_ecc = 0;
        bit                 is_last_data_flit = 0;
        function new(string name = "signals_dly");
        endfunction
    endclass: signals_dly

    //Counter for command and response
    class num_cmd_resp;
        int                 num_seq = 0;
        int                 num_mgr = 0;
        int                 num_config_read = 0;
        int                 num_config_write = 0;
        int                 num_rd_mem = 0;
        int                 num_pr_rd_mem = 0;
        int                 num_write_mem = 0;
        int                 num_write_mem_be = 0;
        int                 num_pr_wr_mem = 0;
        int                 num_pad_mem = 0;
        int                 num_nop = 0;
        int                 num_mem_cntl = 0;  
        int                 num_intrp_rdy = 0;
        int                 num_intrp_resp = 0;
        int                 num_read_resp = 0;
        int                 num_write_resp = 0;
        int                 num_read_failed = 0;
        int                 num_write_failed = 0;
        int                 num_xlate_done = 0;
        int                 num_return_tlx_credits = 0;
        int                 num_tl_vc0 = 0;
        int                 num_tl_vc1 = 0;
        int                 num_tl_dcp0 = 0;
        int                 num_tl_dcp1 = 0;
        int                 num_rd_pf = 0;
        function new(string name = "num_cmd_resp");
        endfunction

        function void clear();
            num_seq = 0;
            num_mgr = 0;
            num_config_read = 0;
            num_config_write = 0;
            num_rd_mem = 0;
            num_pr_rd_mem = 0;
            num_write_mem = 0;
            num_write_mem_be = 0;
            num_pr_wr_mem = 0;
            num_pad_mem = 0;
            num_nop = 0;
            num_mem_cntl = 0;  
            num_intrp_rdy = 0;
            num_intrp_resp = 0;
            num_read_resp = 0;
            num_write_resp = 0;
            num_read_failed = 0;
            num_write_failed = 0;
            num_xlate_done = 0;
            num_return_tlx_credits = 0;
            num_tl_vc0 = 0;
            num_tl_vc1 = 0;
            num_tl_dcp0 = 0;
            num_tl_dcp1 = 0;
            num_rd_pf = 0;

        endfunction
    endclass: num_cmd_resp

    //Internal variables
    driver_packet       vc0_packet_pre_queue[$];    //packets queue for virtual channel 0 without credits  
    driver_packet       vc1_packet_pre_queue[$];    //packets queue for virtual channel 1 without credits
    driver_packet       vc0_packet_queue[$];        //packets queue for virtual channel 0 with credits
    driver_packet       vc1_packet_queue[$];        //packets queue for virtual channel 1 with credits
    driver_packet       return_credits_queue[$];    //packets queue for return tlx credits
    driver_packet       intrp_handle_queue[$];      //packets queue for return tlx credits
    driver_packet       retry_cmd_queue[$];         //packets queue for retry command 
    dl_credit_trans     dl_trans_queue[$];          //DL credit trans queue
    data_on_carrier     present_data_queue[$];      //data queue for present data 
    driver_flit         flit_queue[$];              //flit queue to be drived 
    num_cmd_resp        total_number;               //total number of command and response

    bit [5:0]           template;                   //template 
    bit [15:0][27:0]    tl_content;                 //TL content 
    bit [63:0]          dl_content;                 //DL content
    bit [3:0]           last_run_length = 4'b0;     //run length of last time
    rand int            template_rand;              //random template
    rand bit            err_cntl_flit;              //bad data in control flit
    rand bit [7:0]      err_data_flit = 8'b0;       //bad data in data flit
    rand bit            err_pin_flit;               //insert error for dl_tl_flit_error signal
    bit                 reset_signal;               //event for reset signals
    tl_tx_trans         req_list[bit[15:0]];        //queue for request that has not gotten a response
    bit[2:0]            intrp_handle_cntl;          //bit 0:start to handle interrpt, bit 1:stop to handle interrpt, bit 1:block cmd/resp from sequence and retry 

    `uvm_component_utils_begin(tl_tx_driver)
    `uvm_component_utils_end

    function new (string name="tl_tx_driver", uvm_component parent);
        super.new(name, parent);
        tl_mgr_imp    = new("tl_mgr_imp", this);
        tl_credit_imp = new("tl_credit_imp", this);
        total_number  = new("total_number");
        tl_sbd_resp_imp = new("tl_sbd_resp_imp", this);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual tl_dl_if)::get(this, "","tl_dl_vif",tl_dl_vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".tl_dl_vif"})
    endfunction: build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        if(!uvm_config_db#(tl_cfg_obj)::get(this, "", "cfg_obj", cfg_obj))
            `uvm_error(get_type_name(), "Can't get cfg_obj!")
        if(!uvm_config_db#(tl_mem_model)::get(this, "", "mem_model", mem_model))
            `uvm_error(get_type_name(), "Can't get mem_model!")
    endfunction: start_of_simulation_phase

    virtual task main_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("debug main_phase begin ...1"), UVM_MEDIUM)
        start_drive();
        #100ns;
        fork
            trans_to_packet();
            channel_check();
            packet_to_flit();
            drive_to_tlx();
            if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin   
                drive_dl_credit();
            end
        join
    endtask: main_phase

    function void check_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $psprintf("Driver got a number of%d commands and responses from sequence and a number of%d commands and responses from manager. The number of all supported commands and responses are followed. CONFIG_READ:%d, CONFIG_WRITE:%d, RD_MEM:%d, PR_RD_MEM:%d, WRITE_MEM:%d, WRITE_MEM_BE:%d, PR_WR_MEM:%d, PAD_MEM:%d, NOP:%d, MEM_CNTL:%d, INTRP_RDY:%d, INTRP_RESP:%d, READ_RESP:%d, WRITE_RESP:%d, READ_FAILED:%d, WRITE_FAILED:%d, XLATE_DONE:%d, RETURN_TLX_CREDITS:%d, RD_PF:%d.",
        total_number.num_seq, total_number.num_mgr, total_number.num_config_read, total_number.num_config_write, total_number.num_rd_mem, total_number.num_pr_rd_mem, total_number.num_write_mem, total_number.num_write_mem_be, total_number.num_pr_wr_mem, total_number.num_pad_mem, total_number.num_nop, total_number.num_mem_cntl, total_number.num_intrp_rdy, total_number.num_intrp_resp, total_number.num_read_resp, total_number.num_write_resp, total_number.num_read_failed, total_number.num_write_failed, total_number.num_xlate_done, total_number.num_return_tlx_credits, total_number.num_rd_pf), UVM_LOW)
        `uvm_info(get_type_name(), $psprintf("The total consumed TL credits are followed. TL.VC.0:%d, TL.VC.1:%d, TL.DCP.0:%d, TL.DCP.1:%d.", total_number.num_tl_vc0, total_number.num_tl_vc1, total_number.num_tl_dcp0, total_number.num_tl_dcp1), UVM_MEDIUM)                
        if(vc0_packet_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("virtual channel 0 packet queue is not empty at end of test, there are %d packets in it", vc0_packet_queue.size()))
        if(vc1_packet_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("virtual channel 1 packet queue is not empty at end of test, there are %d packets in it", vc1_packet_queue.size()))
        if(vc0_packet_pre_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("pre-virtual channel 0 packet queue is not empty at end of test, there are %d packets in it", vc0_packet_pre_queue.size()))
        if(vc1_packet_pre_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("pre-virtual channel 1 packet queue is not empty at end of test, there are %d packets in it", vc1_packet_pre_queue.size()))
        if(return_credits_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("return credits queue is not empty at end of test, there are %d packets in it", return_credits_queue.size()))
        if(intrp_handle_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("interrpt handle queue is not empty at end of test, there are %d packets in it", intrp_handle_queue.size()))
        if(dl_trans_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("DL credit trans queue is not empty at end of test, there are %d trans in it", dl_trans_queue.size()))
        if(present_data_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("data queue is not empty at end of test, there are %d 32/64-byte data in it", present_data_queue.size()))
        if(flit_queue.size() != 0)
            `uvm_error(get_type_name(),$psprintf("flit queue is not empty at end of test, there are %d flits in it", flit_queue.size()))
    endfunction: check_phase

    task reset();
        vc0_packet_queue.delete();        //packets queue for virtual channel 0 with credits
        vc1_packet_queue.delete();        //packets queue for virtual channel 1 with credits
        vc0_packet_pre_queue.delete();    //packets queue for virtual channel 0 without credits  
        vc1_packet_pre_queue.delete();    //packets queue for virtual channel 1 without credits
        return_credits_queue.delete();    //packets queue for return tlx credits
        intrp_handle_queue.delete();      //packets queue for interrpt handling 
        retry_cmd_queue.delete();         //packets queue for retry command 
        dl_trans_queue.delete();          //DL credit trans queue
        present_data_queue.delete();      //data queue for present data 
        flit_queue.delete();              //flit queue to be drived
        req_list.delete();                //queue for request that has not gotten a response
        template = 0;                     //template 
        tl_content = 0;                   //TL content 
        dl_content = 0;                   //DL content                 
        template_rand = 0;                //random template
        err_cntl_flit = 0;                //bad data in control flit
        err_data_flit = 0;                //bad data in data flit
        err_pin_flit = 0;                 //insert error for dl_tl_flit_error signal
        intrp_handle_cntl = 0;
        total_number.clear();
        reset_signal = 1;
        repeat(4) @(posedge tl_dl_vif.clock);    //delay 4 clock to throw out signals 
    endtask

    //start to drive for different mode
    virtual task start_drive();
        //unit mode
        if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM) begin 
            `uvm_info(get_type_name(), $psprintf("Initializing signals under UNIT_SIM mode!"), UVM_MEDIUM)
            tl_dl_vif.dl_tl_link_up <= 1'b0;
            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
            tl_dl_vif.dl_tl_flit_error <= 1'b0;
            tl_dl_vif.dl_tl_flit_data <= 512'h0;
            tl_dl_vif.dl_tl_flit_pty <= 16'b0;
            tl_dl_vif.dl_tl_flit_credit <= 1'b0;
            #10ns;
            @(posedge tl_dl_vif.clock);
            tl_dl_vif.dl_tl_link_up <= 1'b1;
            //return dl credits
            if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0)begin
                tl_dl_vif.dl_tl_init_flit_depth <= 3'b100;
            end
            else begin
                @(posedge tl_dl_vif.clock);
                tl_dl_vif.dl_tl_flit_credit <= 1'b1;
                repeat(cfg_obj.dl_credit_count) @(posedge tl_dl_vif.clock);
                tl_dl_vif.dl_tl_flit_credit <= 1'b0;
            end
            //ready for transmit
            @(posedge tl_dl_vif.clock);
            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
	        tl_dl_vif.dl_tl_flit_data <= 128'h0;
            tl_dl_vif.dl_tl_flit_pty <= gen_parity_bits (128'h0);
        end
        //chip mode
        else begin
            `uvm_info(get_type_name(), $psprintf("Initializing signals under CHIP_SIM mode!"), UVM_MEDIUM)
            @(posedge tl_dl_vif.clock);
            tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
            tl_dl_vif.tl_dl_flit_vld <= 1'b0;
            tl_dl_vif.tl_dl_flit_data <= 128'h0;
            tl_dl_vif.tl_dl_flit_ecc <= 16'h0;
            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
            tl_dl_vif.tl_dl_tl_error <= 1'b0;
            tl_dl_vif.tl_dl_tl_event <= 1'b0;
            while(tl_dl_vif.dl_tl_link_up != 1'b1)
                @(posedge tl_dl_vif.clock);
            `uvm_info(get_type_name(), $psprintf("The dl_tl_link is up now!"), UVM_MEDIUM)
        end
    endtask: start_drive

    //get cmd/resp trans from manager
    function void write_mgr(tl_tx_trans mgr_tr);
        driver_packet packet_temp;
        packet_temp = gen_packet(mgr_tr);
        //handle RETURN_TLX_CREDITS
        if(mgr_tr.packet_type == tl_tx_trans::RETURN_TLX_CREDITS)begin
            return_credits_queue.push_back(packet_temp);
            `uvm_info(get_type_name(), $psprintf("Get a RETURN_TLX_CREDITS command from manager."), UVM_MEDIUM)
        end
        //handle READ_RESPONSE, READ_FAILED, WRITE_RESPONSE, WRITE_FAILED XLATE_DONE
        else if(mgr_tr.packet_type == tl_tx_trans::READ_RESPONSE || mgr_tr.packet_type == tl_tx_trans::READ_FAILED
        || mgr_tr.packet_type == tl_tx_trans::WRITE_RESPONSE || mgr_tr.packet_type == tl_tx_trans::WRITE_FAILED || mgr_tr.packet_type == tl_tx_trans::XLATE_DONE)begin
            vc0_packet_pre_queue.push_back(packet_temp);
            `uvm_info(get_type_name(), $psprintf("Get a read/write response/failed from manager for virtual channel 0.\n%s", mgr_tr.sprint()), UVM_MEDIUM)
        end
        //handle interrpt
        else if(mgr_tr.intrp_handler_begin == 1 || mgr_tr.intrp_handler_end == 1)begin
            if(mgr_tr.intrp_handler_begin == 1 && intrp_handle_cntl[2] == 1'b0)begin
                intrp_handle_cntl = 3'b101;
                `uvm_info(get_type_name(), $psprintf("The current interrupt handle state is %b",intrp_handle_cntl), UVM_MEDIUM)
            end
            if(mgr_tr.intrp_handler_end == 1)begin
                intrp_handle_cntl[1] = 1'b1;
                `uvm_info(get_type_name(), $psprintf("The current interrupt handle state is %b",intrp_handle_cntl), UVM_MEDIUM)   
            end
            intrp_handle_queue.push_back(packet_temp);
            `uvm_info(get_type_name(), $psprintf("Get an interrupt handle command/response from manager.\n%s", mgr_tr.sprint()), UVM_MEDIUM)
        end
        else if((mgr_tr.packet_type == tl_tx_trans::MEM_CNTL) || (mgr_tr.packet_type == tl_tx_trans::INTRP_RESP) || (mgr_tr.packet_type == tl_tx_trans::INTRP_RDY))begin
            vc0_packet_pre_queue.push_back(packet_temp);
            `uvm_info(get_type_name(), $psprintf("Get a response from manager for virtual channel 0.\n%s", mgr_tr.sprint()), UVM_MEDIUM)
        end
        else begin
            retry_cmd_queue.push_back(packet_temp);
            `uvm_info(get_type_name(), $psprintf("Get a retry command from manager for virtual channel 1.\n%s", mgr_tr.sprint()), UVM_MEDIUM)
        end
        total_number.num_mgr++;
    endfunction: write_mgr
    
    //get dl credits from manager
    function void write_credit(dl_credit_trans credit_tr);
        dl_trans_queue.push_back(credit_tr);
    endfunction: write_credit
    
    //get command from sequence and generate packets for each virtual channel
    virtual task trans_to_packet;
        tl_tx_trans trans_item;
        forever begin
            while(intrp_handle_cntl[2] == 1'b1) 
                @(posedge tl_dl_vif.clock);            
            seq_item_port.get_next_item(req);
            if(req.packet_type == tl_tx_trans::RETURN_TLX_CREDITS)begin
                return_credits_queue.push_back(gen_packet(req));
                `uvm_info(get_type_name(), $psprintf("Get a RETURN_TLX_CREDITS command from sequence."), UVM_MEDIUM)
            end
            else if((req.packet_type == tl_tx_trans::MEM_CNTL) || (req.packet_type == tl_tx_trans::INTRP_RESP) || (req.packet_type == tl_tx_trans::INTRP_RDY))begin
                while((vc0_packet_pre_queue.size + vc0_packet_queue.size) >= cfg_obj.driver_cmd_buffer_size)
                    @(posedge tl_dl_vif.clock);
                vc0_packet_pre_queue.push_back(gen_packet(req));
                `uvm_info(get_type_name(), $psprintf("Get a command/response from sequence for virtual channel 0."), UVM_MEDIUM)
            end
            else begin
                while((vc1_packet_pre_queue.size + vc1_packet_queue.size) >= cfg_obj.driver_cmd_buffer_size)
                    @(posedge tl_dl_vif.clock);
                vc1_packet_pre_queue.push_back(gen_packet(req));
                `uvm_info(get_type_name(), $psprintf("Get a command/response from sequence for virtual channel 1."), UVM_MEDIUM)
            end
            if(req.packet_type != tl_tx_trans::RETURN_TLX_CREDITS && req.packet_type != tl_tx_trans::NOP && cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_1)begin
                trans_item = new("trans_item");
                $cast(trans_item,req.clone());
                req_list[trans_item.capp_tag] = trans_item;
                req_list[trans_item.capp_tag].set_id_info(req);
                `uvm_info(get_type_name(), $psprintf("This sequence request has a sequence id of%d and a transaction id of%d",req.get_sequence_id(), req.get_transaction_id()), UVM_MEDIUM)
            end  
            total_number.num_seq++;
            seq_item_port.item_done();
        end
    endtask: trans_to_packet

    //get response from scorebord
    function void write_sbd(tl_trans rx_trans);
        if(req_list.exists(rx_trans.rx_CAPPTag))begin
            $cast(rsp,rx_trans.clone());
            rsp.set_id_info(req_list[rx_trans.rx_CAPPTag]);
            req_list.delete(rx_trans.rx_CAPPTag);
            seq_item_port.put_response(rsp);
        end
    endfunction: write_sbd

    //drive dl credit to return credits
    virtual task drive_dl_credit();
        dl_credit_trans credit_item;
        forever begin
            while(dl_trans_queue.size != 0) begin
                credit_item = dl_trans_queue.pop_front;                
                repeat(credit_item.return_credit)begin
                   @(posedge tl_dl_vif.clock);
                   tl_dl_vif.dl_tl_flit_credit <= 1'b1;
                end
            end
            @(posedge tl_dl_vif.clock);
            tl_dl_vif.dl_tl_flit_credit <= 1'b0;
        end
    endtask: drive_dl_credit

    //packet the cmd/resp trans from manager and sequence
    function driver_packet gen_packet(tl_tx_trans trans_item);
        gen_packet = new("gen_packet");
        case (trans_item.packet_type)
            tl_tx_trans::NOP: 
            begin
                gen_packet.cmd_resp_length = 1;   
                gen_packet.data_length = 0;  
                gen_packet.cmd_resp_packet[0] = 28'h0;	 
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_nop++;
            end
            tl_tx_trans::MEM_CNTL:	
            begin
                gen_packet.cmd_resp_length = 4;  
                gen_packet.data_length = 0; 
                gen_packet.cmd_resp_packet[0] = {16'b0, trans_item.cmd_flag, 8'hef};
                gen_packet.cmd_resp_packet[1] = trans_item.object_handle[27:0];
                gen_packet.cmd_resp_packet[2] = trans_item.object_handle[55:28];
                gen_packet.cmd_resp_packet[3] = {4'b0, trans_item.capp_tag[15:0], trans_item.object_handle[63:56]};
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_mem_cntl++;
            end 
            tl_tx_trans::CONFIG_READ:
            begin
                gen_packet.cmd_resp_length = 4;   
                gen_packet.data_length = 0;
                //check if plength is valid
                if((trans_item.plength > 2) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal partial data length of%d, in a CONFIG_READ command.", trans_item.plength), UVM_MEDIUM)                    
                gen_packet.cmd_resp_packet[0] = {20'b0, 8'he0};
                gen_packet.cmd_resp_packet[1] = trans_item.physical_addr[27:0];
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.plength[2:0], trans_item.config_type, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]}; 
                gen_packet.physical_addr = trans_item.physical_addr;
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_config_read++;
            end
            tl_tx_trans::CONFIG_WRITE: 
            begin
                gen_packet.cmd_resp_length = 4; 
                //check if plength is valid
                if((trans_item.plength > 2) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal partial data length of%d, in a CONFIG_WRITE command.", trans_item.plength), UVM_MEDIUM)                    
                gen_packet.data_length = gen_data_length_p(trans_item.plength);
                gen_packet.cmd_resp_packet[0] = {20'b0, 8'he1};
                gen_packet.cmd_resp_packet[1] = trans_item.physical_addr[27:0];
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.plength[2:0], trans_item.config_type, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]};
                if(gen_packet.data_length < 8)begin
                    for(int j=0; j<gen_packet.data_length; j++)begin
                        gen_packet.data_packet[j] = trans_item.data_carrier[0][8*j+7-:8];
                    end
                end
                else begin
                    for(int i=0; i<(gen_packet.data_length/8); i++)
                        for(int j=0; j<8; j++)
                            gen_packet.data_packet[8*i+j] = trans_item.data_carrier[i][8*j+7-:8];
                end
                if(cfg_obj.inject_err_enable != 1'b1)
                    if((trans_item.physical_addr[63:0] % gen_packet.data_length) > 0)
                        `uvm_error(get_type_name(), "This data is addressed not aligned with a data block!")
                gen_packet.physical_addr = trans_item.physical_addr;
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 1;
                total_number.num_config_write++;
	        end
            tl_tx_trans::RD_MEM: 
	        begin
                gen_packet.cmd_resp_length = 4;   
                gen_packet.data_length = 0;
                //check if dlength is valid
                if((trans_item.dlength == 0) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal data length of%d, in a RD_MEM command.", trans_item.dlength), UVM_MEDIUM)
                 gen_packet.cmd_resp_packet[0] = {15'b0, 1'b0, trans_item.mad[3:0], 8'h20};
                gen_packet.cmd_resp_packet[1] = {trans_item.physical_addr[27:5], 1'b0, trans_item.mad[7:4]};
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.dlength[1:0], 2'b00, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]};   
                gen_packet.physical_addr = {trans_item.physical_addr[63:5], 5'b0};
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.read_chk_cmd = 1;
                gen_packet.chk_length =  gen_data_length_d(trans_item.dlength);
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_rd_mem++;
            end
            tl_tx_trans::PR_RD_MEM: 
            begin
                gen_packet.cmd_resp_length = 4;  
                gen_packet.data_length = 0;
                //check if plength is valid
                if((trans_item.plength > 5) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal partial data length of%d, in a PR_RD_MEM command.", trans_item.plength), UVM_MEDIUM)                    
                //check if the physical address belongs to system memory range
                if(trans_item.physical_addr[63:35] == cfg_obj.mmio_space_base[63:35])
                    gen_packet.read_chk_cmd = 0;
                else begin
                    gen_packet.read_chk_cmd = 1;
                end
                gen_packet.cmd_resp_packet[0] = {20'b0, 8'h28};
                gen_packet.cmd_resp_packet[1] = trans_item.physical_addr[27:0];
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.plength[2:0], 1'b0, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]};
                gen_packet.physical_addr =  trans_item.physical_addr;
                gen_packet.capp_tag =  trans_item.capp_tag;
                if(cfg_obj.half_dimm_mode == 1'b0)
                    gen_packet.chk_length = 64;
                else
                    gen_packet.chk_length = 32;
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_pr_rd_mem++;
            end
            tl_tx_trans::WRITE_MEM: 
            begin
                gen_packet.cmd_resp_length = 4;
                //check if dlength is valid
                gen_packet.data_length = gen_data_length_d(trans_item.dlength);
                if((trans_item.dlength == 0) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal data length of%d, in a WRITE_MEM command.", trans_item.dlength), UVM_MEDIUM)
                gen_packet.data_to_memory = 1;
                gen_packet.cmd_resp_packet[0] = {20'b0, 8'h81};
                gen_packet.cmd_resp_packet[1] = {trans_item.physical_addr[27:6], 6'b0};
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.dlength[1:0], 2'b0, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]}; 
                for(int i=0; i<(gen_packet.data_length/8); i++)begin
                    for(int j=0; j<8; j++)
                        gen_packet.data_packet[8*i+j] = trans_item.data_carrier[i][8*j+7-:8];
                end
                if((cfg_obj.inject_err_enable == 1'b0) && (({trans_item.physical_addr[63:6], 6'b0} % gen_packet.data_length) > 0))
                    `uvm_error(get_type_name(), "This data is addressed not aligned with a data block!")
                gen_packet.physical_addr = {trans_item.physical_addr[63:6], 6'b0};
                gen_packet.capp_tag =  trans_item.capp_tag;
                for(int i=0; i<(gen_packet.data_length/64 + ((gen_packet.data_length)%64)/32); i++)begin
                    gen_packet.meta[i] = trans_item.meta[i*8];
                    gen_packet.xmeta[i] = trans_item.xmeta[i*8];
                end
                gen_packet.write_chk_cmd = 1;
                gen_packet.chk_length =  gen_data_length_d(trans_item.dlength);
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = ((gen_packet.data_length)/64 + ((gen_packet.data_length)%64)/32);
                total_number.num_write_mem++;
            end
            tl_tx_trans::PR_WR_MEM: 
            begin
                gen_packet.cmd_resp_length = 4;
                gen_packet.data_length = gen_data_length_p(trans_item.plength);  
                //check if plength is valid
                if((trans_item.plength > 5) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal partial data length of%d, in a PR_WR_MEM command.", trans_item.plength), UVM_MEDIUM)                    
                gen_packet.cmd_resp_packet[0] = ({20'b0, 8'h86});
                gen_packet.cmd_resp_packet[1] = (trans_item.physical_addr[27:0]);
                gen_packet.cmd_resp_packet[2] = (trans_item.physical_addr[55:28]);
                gen_packet.cmd_resp_packet[3] = ({trans_item.plength[2:0], 1'b0, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]});
                if(gen_packet.data_length < 8)begin
                    for(int j=0; j<gen_packet.data_length; j++)
                        gen_packet.data_packet[j] = trans_item.data_carrier[0][8*j+7-:8];
                end
                else begin
                    for(int i=0; i<(gen_packet.data_length/8); i++)
                        for(int j=0; j<8; j++)
                            gen_packet.data_packet[8*i+j] = trans_item.data_carrier[i][8*j+7-:8];
                end
                if(cfg_obj.inject_err_enable != 1'b1)
                    if((trans_item.physical_addr[63:0] % gen_packet.data_length) > 0)
                        `uvm_error(get_type_name(), "This data is addressed not aligned with a data block!")
                //check if the physical address belongs to system memory range
                if(trans_item.physical_addr[63:35] == cfg_obj.mmio_space_base[63:35])
                    gen_packet.write_chk_cmd = 0;
                else begin
                    gen_packet.write_chk_cmd = 1;
                    gen_packet.data_to_memory = 1;
                    gen_packet.meta[0] = trans_item.meta[0];                    
                end
                if(cfg_obj.half_dimm_mode == 1'b0)
                    gen_packet.chk_length = 64;
                else
                    gen_packet.chk_length = 32;
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.physical_addr = trans_item.physical_addr;
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.xmeta[0] = trans_item.xmeta[0];
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 1;
                total_number.num_pr_wr_mem++;
            end
            tl_tx_trans::PAD_MEM: 
            begin
                gen_packet.cmd_resp_length = 4;  
                gen_packet.data_length = 0;
                //check if dlength is valid
                if((trans_item.dlength != 0) && (cfg_obj.inject_err_enable == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Get an illegal data length of%d, in a PAD_MEM command.", trans_item.dlength), UVM_MEDIUM)
                gen_packet.data_to_memory = 0;
                gen_packet.cmd_resp_packet[0] = ({20'b0, 8'h80});
                gen_packet.cmd_resp_packet[1] = ({trans_item.physical_addr[27:5], 5'b0});
                gen_packet.cmd_resp_packet[2] = (trans_item.physical_addr[55:28]);
                gen_packet.cmd_resp_packet[3] = ({trans_item.dlength[1:0], 2'b0, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]});
                gen_packet.physical_addr = {trans_item.physical_addr[63:5], 5'b0};
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.write_chk_cmd = 1;
                gen_packet.chk_length =  gen_data_length_d(trans_item.dlength);
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_pad_mem++;
            end
            tl_tx_trans::WRITE_MEM_BE: 
            begin
                gen_packet.cmd_resp_length = 6;  
                gen_packet.data_length = 64; 
                gen_packet.data_to_memory = 1;
                gen_packet.cmd_resp_packet[0] = ({20'b0, 8'h82});
                gen_packet.cmd_resp_packet[1] = ({trans_item.physical_addr[27:6], 2'b0, trans_item.byte_enable[3:0]});
                gen_packet.cmd_resp_packet[2] = (trans_item.physical_addr[55:28]);
                gen_packet.cmd_resp_packet[3] = ({trans_item.byte_enable[7:4], trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]});
                gen_packet.cmd_resp_packet[4] = ({trans_item.byte_enable[35:8]});
                gen_packet.cmd_resp_packet[5] = ({trans_item.byte_enable[63:36]}); 
                for(int i=0; i<(gen_packet.data_length/8); i++)begin
                    for(int j=0; j<8; j++)
                        gen_packet.data_packet[8*i+j] = trans_item.data_carrier[i][8*j+7-:8];
                end
                if(cfg_obj.inject_err_enable != 1'b1)
                    if((trans_item.physical_addr[63:0] % gen_packet.data_length) > 0)
                        `uvm_error(get_type_name(), "This data is addressed not aligned with a data block!")
                gen_packet.physical_addr = {trans_item.physical_addr[63:6], 6'b0};
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.byte_enable = trans_item.byte_enable;
                gen_packet.meta[0] = trans_item.meta[0];
                gen_packet.xmeta[0] = trans_item.xmeta[0];
                gen_packet.write_chk_cmd = 1;
                gen_packet.chk_length =  64;
                gen_packet.chk_addr =  gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 1;
                total_number.num_write_mem_be++;
            end
            tl_tx_trans::INTRP_RDY:	
            begin
                gen_packet.cmd_resp_length = 2;  
                gen_packet.data_length = 0; 
                gen_packet.cmd_resp_packet[0] = ({4'b0000, trans_item.afu_tag[15:0], 8'h1a});
                gen_packet.cmd_resp_packet[1] = ({trans_item.resp_code, 24'b0});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_intrp_rdy++;
            end 
            tl_tx_trans::INTRP_RESP:	
            begin
                gen_packet.cmd_resp_length = 2;  
                gen_packet.data_length = 0; 
                gen_packet.cmd_resp_packet[0] = ({4'b0000, trans_item.afu_tag[15:0], 8'h0c});
                gen_packet.cmd_resp_packet[1] = ({trans_item.resp_code, 24'b0});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_intrp_resp++;
            end 
            tl_tx_trans::RETURN_TLX_CREDITS:	
            begin
                gen_packet.cmd_resp_length = 2;  
                gen_packet.data_length = 0; 
                gen_packet.cmd_resp_packet[0] = ({4'b0000, trans_item.tlx_vc_3, 8'b0, trans_item.tlx_vc_0, 8'h01});
                gen_packet.cmd_resp_packet[1] = ({trans_item.tlx_dcp_3, 12'b0, trans_item.tlx_dcp_0, 4'b0});
                total_number.num_return_tlx_credits++;
            end
            tl_tx_trans::RD_PF: 
	        begin
                gen_packet.cmd_resp_length = 4;   
                gen_packet.data_length = 0;
                //check if dlength is valid
                //if((trans_item.dlength == 0) && (cfg_obj.inject_err_enable == 1'b0))
                //    `uvm_info(get_type_name(), $psprintf("Get an illegal data length of%d, in a RD_MEM command.", trans_item.dlength), UVM_MEDIUM)
                gen_packet.cmd_resp_packet[0] = {15'b0, 1'b0, trans_item.mad[3:0], 8'h22};
                gen_packet.cmd_resp_packet[1] = {trans_item.physical_addr[27:5], 1'b0, trans_item.mad[7:4]};
                gen_packet.cmd_resp_packet[2] = trans_item.physical_addr[55:28];
                gen_packet.cmd_resp_packet[3] = {trans_item.dlength[1:0], 2'b00, trans_item.capp_tag[15:0], trans_item.physical_addr[63:56]};   
                gen_packet.physical_addr = {trans_item.physical_addr[63:5], 5'b0};
                gen_packet.capp_tag =  trans_item.capp_tag;
                gen_packet.read_chk_cmd = 0;
                gen_packet.chk_length =  0;//gen_data_length_d(trans_item.dlength);
                gen_packet.chk_addr =  0;//gen_chk_addr(gen_packet.chk_length, trans_item.physical_addr);
                gen_packet.tl_vc0 = 0;
                gen_packet.tl_vc1 = 1;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_rd_pf++;
            end
            tl_tx_trans::READ_RESPONSE:	
            begin
                gen_packet.cmd_resp_length = 1;
                if(trans_item.dlength == 0)begin
                    gen_packet.data_length = gen_data_length_p(trans_item.plength);
                    trans_item.dlength = 2'b1;
                    gen_packet.tl_dcp0 = 1'b1;
                end
                else begin
                    gen_packet.data_length = gen_data_length_d(trans_item.dlength);
                    gen_packet.tl_dcp0 = (gen_packet.data_length)/64;
                end
                if(gen_packet.data_length < 8)begin
                    for(int j=0; j<gen_packet.data_length; j++)
                        gen_packet.data_packet[j] = trans_item.data_carrier[0][8*j+7-:8];
                end
                else begin
                    for(int i=0; i<(gen_packet.data_length/8); i++)
                        for(int j=0; j<8; j++)
                            gen_packet.data_packet[8*i+j] = trans_item.data_carrier[i][8*j+7-:8];
                end
                gen_packet.cmd_resp_packet[0] = ({trans_item.dlength, trans_item.dpart, trans_item.afu_tag[15:0], 8'h04});
                gen_packet.physical_addr = trans_item.physical_addr;
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_read_resp++;
            end
            tl_tx_trans::WRITE_RESPONSE:	
            begin
                gen_packet.cmd_resp_length = 1;
                if(trans_item.dlength == 0)begin
                    trans_item.dlength = 2'b1;
                end
                gen_packet.data_length = 0;
                gen_packet.cmd_resp_packet[0] = ({trans_item.dlength, trans_item.dpart, trans_item.afu_tag[15:0], 8'h08});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_write_resp++;
            end 
            tl_tx_trans::READ_FAILED:	
            begin
                gen_packet.cmd_resp_length = 2;
                if(trans_item.dlength == 0)begin
                    trans_item.dlength = 2'b1;
                end
                gen_packet.data_length = 0;
                gen_packet.cmd_resp_packet[0] = ({trans_item.dlength, trans_item.dpart, trans_item.afu_tag[15:0], 8'h05});
                gen_packet.cmd_resp_packet[1] = ({trans_item.resp_code, 24'b0});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_read_failed++;
            end
            tl_tx_trans::WRITE_FAILED:	
            begin
                gen_packet.cmd_resp_length = 2;
                if(trans_item.dlength == 0)begin
                    trans_item.dlength = 2'b1;
                end
                gen_packet.data_length = 0;
                gen_packet.cmd_resp_packet[0] = ({trans_item.dlength, trans_item.dpart, trans_item.afu_tag[15:0], 8'h09});
                gen_packet.cmd_resp_packet[1] = ({trans_item.resp_code, 24'b0});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_write_failed++;
            end
            tl_tx_trans::XLATE_DONE:	
            begin
                gen_packet.cmd_resp_length = 2;
                gen_packet.cmd_resp_packet[0] = ({4'h0, trans_item.afu_tag[15:0], 8'h18});
                gen_packet.cmd_resp_packet[1] = ({trans_item.resp_code, 24'b0});
                gen_packet.tl_vc0 = 1;
                gen_packet.tl_vc1 = 0;
                gen_packet.tl_dcp0 = 0;
                gen_packet.tl_dcp1 = 0;
                total_number.num_xlate_done++;
            end
            default:
                `uvm_error(get_type_name(), "Get an illegal cmd or resp transaction item!")
        endcase
        return gen_packet; 
    endfunction: gen_packet

    //get data byte number from dL
    function int gen_data_length_d(bit[1:0] dlength); 
        int data_length_d;
        case (dlength)
            2'b00: data_length_d = 32;
            2'b01: data_length_d = 64;
            2'b10: data_length_d = 128;
            2'b11: data_length_d = 256;
            default: `uvm_error(get_type_name(), "Get an illegal data length!")
        endcase
        return data_length_d;
    endfunction: gen_data_length_d

    //get data byte number from pL
    function int gen_data_length_p(bit[2:0] plength);
        int data_length_p;
        case (plength)
            3'b000: data_length_p = 1;
            3'b001: data_length_p = 2;
            3'b010: data_length_p = 4;
            3'b011: data_length_p = 8;
            3'b100: data_length_p = 16;
            3'b101: data_length_p = 32; 
            3'b110: data_length_p = 4;
            3'b111: data_length_p = 8;
            default: `uvm_error(get_type_name(), "Get an illegal partial data length!")
        endcase 
        return data_length_p;
    endfunction: gen_data_length_p

    function bit[63:0] gen_chk_addr(int chk_length, bit[63:0] physical_addr);
        if(cfg_obj.half_dimm_mode == 1'b0)
            case (chk_length)
                32: gen_chk_addr = {physical_addr[63:6],6'b0};
                64: gen_chk_addr = {physical_addr[63:6],6'b0};
                128: gen_chk_addr = {physical_addr[63:7],7'b0};
                256: gen_chk_addr = {physical_addr[63:8],8'b0};
                default: `uvm_error(get_type_name(), "Get an illegal readable/writable check length!")
            endcase
        else
            case (chk_length)
                32: gen_chk_addr = {physical_addr[63:5],5'b0};
                64: gen_chk_addr = {physical_addr[63:6],6'b0};
                128: gen_chk_addr = {physical_addr[63:7],7'b0};
                256: gen_chk_addr = {physical_addr[63:8],8'b0};
                default: `uvm_error(get_type_name(), "Get an illegal readable/writable check length!")
            endcase 
        return gen_chk_addr;
    endfunction: gen_chk_addr

    //check credits for virtual channel 0 and  virtual channel 1
    //check readable/writable tag for virtual channel 1
    virtual task channel_check;
        forever begin
            //handle interrupt
            if(intrp_handle_cntl[0]== 1'b1 && vc1_packet_queue.size == 0 && vc0_packet_queue.size == 0)begin
                intrp_handle_cntl[0]=1'b0;
                `uvm_info(get_type_name(), $psprintf("The current interrupt handle state is %b",intrp_handle_cntl), UVM_MEDIUM)   
            end
            if(intrp_handle_cntl[1]== 1'b1 && intrp_handle_queue.size == 0 && vc1_packet_queue.size == 0)begin
                intrp_handle_cntl=3'b0; 
                `uvm_info(get_type_name(), $psprintf("The current interrupt handle state is %b",intrp_handle_cntl), UVM_MEDIUM)   
            end
            while((intrp_handle_cntl[2]== 1'b1) && (intrp_handle_cntl[0]== 1'b0) && (intrp_handle_queue.size != 0) && 
            (has_credit(intrp_handle_queue[0].tl_vc0, intrp_handle_queue[0].tl_dcp0, 1'b0) == 1'b1) && (has_credit(intrp_handle_queue[0].tl_vc1, intrp_handle_queue[0].tl_dcp1, 1'b1) == 1'b1) &&(
            ((intrp_handle_queue[0].read_chk_cmd != 1'b1) && (intrp_handle_queue[0].write_chk_cmd != 1'b1)) ||
            //check readable tag for read commands including critical memory read
            ((intrp_handle_queue[0].read_chk_cmd == 1'b1) &&  (mem_model.check_readable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length) == 1'b1)) ||
            //check writable tag for write commands
            ((intrp_handle_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length) == 1'b1)))
                               )begin
                if(intrp_handle_queue[0].write_chk_cmd == 1'b1)begin
                    mem_model.rst_readable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length, intrp_handle_queue[0].capp_tag);
                end
                if(intrp_handle_queue[0].read_chk_cmd == 1'b1)begin
                    mem_model.rst_writable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length, intrp_handle_queue[0].capp_tag);         
                end
                consume_credit(intrp_handle_queue[0].tl_vc0, intrp_handle_queue[0].tl_dcp0, 1'b0, intrp_handle_queue[0].cmd_resp_packet[0][7:0]);
                consume_credit(intrp_handle_queue[0].tl_vc1, intrp_handle_queue[0].tl_dcp1, 1'b1, intrp_handle_queue[0].cmd_resp_packet[0][7:0]);
                vc1_packet_queue.push_back(intrp_handle_queue.pop_front);
            end 

            //handle pre virtual channel 0
            while((intrp_handle_cntl[2]== 1'b0) && (vc0_packet_pre_queue.size != 0) && (has_credit(vc0_packet_pre_queue[0].tl_vc0, vc0_packet_pre_queue[0].tl_dcp0, 1'b0) == 1'b1))begin
                consume_credit(vc0_packet_pre_queue[0].tl_vc0, vc0_packet_pre_queue[0].tl_dcp0, 1'b0, vc0_packet_pre_queue[0].cmd_resp_packet[0][7:0]);
                vc0_packet_queue.push_back(vc0_packet_pre_queue.pop_front);
            end

            //handle retry queue
            while((intrp_handle_cntl[2]== 1'b0) && (retry_cmd_queue.size != 0) && (has_credit(retry_cmd_queue[0].tl_vc1, retry_cmd_queue[0].tl_dcp1, 1'b1) == 1'b1) &&(
            ((retry_cmd_queue[0].read_chk_cmd != 1'b1) && (retry_cmd_queue[0].write_chk_cmd != 1'b1)) ||
            //check readable tag for read commands including critical memory read
            ((retry_cmd_queue[0].read_chk_cmd == 1'b1) &&  (mem_model.check_readable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length) == 1'b1)) ||
            //check writable tag for write commands
            ((retry_cmd_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length) == 1'b1)))
                               )begin
                if(retry_cmd_queue[0].write_chk_cmd == 1'b1)begin
                    mem_model.rst_readable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length, retry_cmd_queue[0].capp_tag);
                end
                if(retry_cmd_queue[0].read_chk_cmd == 1'b1)begin
                    mem_model.rst_writable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length, retry_cmd_queue[0].capp_tag);         
                end
                consume_credit(retry_cmd_queue[0].tl_vc1, retry_cmd_queue[0].tl_dcp1, 1'b1, retry_cmd_queue[0].cmd_resp_packet[0][7:0]);
                vc1_packet_queue.push_back(retry_cmd_queue.pop_front);
            end 

            //handle pre virtual channel 1
            while((intrp_handle_cntl[2]== 1'b0) && (vc1_packet_pre_queue.size != 0) && (has_credit(vc1_packet_pre_queue[0].tl_vc1, vc1_packet_pre_queue[0].tl_dcp1, 1'b1) == 1'b1) && (
            ((vc1_packet_pre_queue[0].read_chk_cmd != 1'b1) && (vc1_packet_pre_queue[0].write_chk_cmd != 1'b1)) ||
            //check readable tag for read commands including critical memory read
            ((vc1_packet_pre_queue[0].read_chk_cmd == 1'b1) &&  (mem_model.check_readable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length) == 1'b1)) ||
            //check writable tag for write commands
            ((vc1_packet_pre_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length) == 1'b1))))begin
                if(vc1_packet_pre_queue[0].write_chk_cmd == 1'b1)begin
                    mem_model.rst_readable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length, vc1_packet_pre_queue[0].capp_tag);
                end
                if(vc1_packet_pre_queue[0].read_chk_cmd == 1'b1)begin
                    mem_model.rst_writable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length, vc1_packet_pre_queue[0].capp_tag);         
                end
                consume_credit(vc1_packet_pre_queue[0].tl_vc1, vc1_packet_pre_queue[0].tl_dcp1, 1'b1, vc1_packet_pre_queue[0].cmd_resp_packet[0][7:0]);
                vc1_packet_queue.push_back(vc1_packet_pre_queue.pop_front);
            end

            @(posedge tl_dl_vif.clock);

            if((intrp_handle_cntl[2]== 1'b0) && (vc1_packet_pre_queue.size != 0))begin
                if((vc1_packet_pre_queue[0].read_chk_cmd == 1'b1) && (mem_model.check_readable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length) == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory readable tags."), UVM_HIGH)
                else if((vc1_packet_pre_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(vc1_packet_pre_queue[0].chk_addr, vc1_packet_pre_queue[0].chk_length) == 1'b0))begin
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory writable tags."), UVM_HIGH)
                end
            end
            if((intrp_handle_cntl[2]== 1'b0) && (retry_cmd_queue.size != 0))begin
                if((retry_cmd_queue[0].read_chk_cmd == 1'b1) && (mem_model.check_readable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length) == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory readable tags for retry command."), UVM_HIGH)
                else if((retry_cmd_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(retry_cmd_queue[0].chk_addr, retry_cmd_queue[0].chk_length) == 1'b0))begin
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory writable tags for retry command."), UVM_HIGH)
                end
            end
            if((intrp_handle_cntl[2]== 1'b1) && (intrp_handle_queue.size != 0))begin
                if((intrp_handle_queue[0].read_chk_cmd == 1'b1) && (mem_model.check_readable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length) == 1'b0))
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory readable tags."), UVM_HIGH)
                else if((intrp_handle_queue[0].write_chk_cmd == 1'b1) && (mem_model.check_writable_tag(intrp_handle_queue[0].chk_addr, intrp_handle_queue[0].chk_length) == 1'b0))begin
                    `uvm_info(get_type_name(), $psprintf("Waiting for checking memory writable tags."), UVM_HIGH)
                end
            end
        end
    endtask: channel_check

    //assign packets to flit
    virtual task packet_to_flit;
        int pending_flit_num;
        if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0)
            pending_flit_num = 1;
        else
            pending_flit_num = 4;
        forever begin
            //assign packets from vc0 and vc1 to flit
            while((flit_queue.size < pending_flit_num) && ((return_credits_queue.size != 0) || (vc0_packet_queue.size != 0) || (vc1_packet_queue.size != 0) || (present_data_queue.size != 0)))begin
            select_new_template();
            `uvm_info(get_type_name(), $psprintf("New template of%d is selected normally.", template), UVM_MEDIUM)
            gen_tl_content();
            gen_dl_content();
            gen_flit();
            end

            if((intrp_handle_cntl[2]== 1'b0) && (vc0_packet_pre_queue.size != 0) && (vc0_packet_queue.size == 0) && (has_credit(vc0_packet_pre_queue[0].tl_vc0, 0, 0) != 1'b1))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for vc0, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            if((intrp_handle_cntl[2]== 1'b0) && (vc0_packet_pre_queue.size != 0) && (vc0_packet_queue.size == 0) && (has_credit(0, vc0_packet_pre_queue[0].tl_dcp0, 0) != 1'b1))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for dcp0, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            if((intrp_handle_cntl[2]== 1'b0) && (vc1_packet_pre_queue.size != 0) && (vc1_packet_queue.size == 0) && (has_credit(vc1_packet_pre_queue[0].tl_vc1, 0, 1'b1) != 1'b1))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for vc1, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            if((intrp_handle_cntl[2]== 1'b0) && (vc1_packet_pre_queue.size != 0) && (vc1_packet_queue.size == 0) && (has_credit(0, vc1_packet_pre_queue[0].tl_dcp1, 1'b1) != 1'b1))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for dcp1, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            if((intrp_handle_cntl[2]== 1'b1) && (intrp_handle_queue.size != 0) && (vc1_packet_queue.size == 0) && ( 
            (has_credit(intrp_handle_queue[0].tl_vc0, intrp_handle_queue[0].tl_dcp0, 1'b0) != 1'b1) || (has_credit(intrp_handle_queue[0].tl_vc1, intrp_handle_queue[0].tl_dcp1, 1'b1) != 1'b1)))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for interrupt handling, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            if((intrp_handle_cntl[2]== 1'b0) && (retry_cmd_queue.size != 0) && ((vc0_packet_queue.size == 0 && has_credit(intrp_handle_queue[0].tl_vc0, intrp_handle_queue[0].tl_dcp0, 1'b0) != 1'b1)
                    || (vc1_packet_queue.size == 0 && has_credit(intrp_handle_queue[0].tl_vc1, intrp_handle_queue[0].tl_dcp1, 1'b1) != 1'b1)))
                `uvm_info(get_type_name(), $psprintf("Waiting tl credits for retry command, the total consumed tl credits: vc0=%d, dcp0=%d, vc1=%d, dcp1=%d.", total_number.num_tl_vc0, total_number.num_tl_dcp0, total_number.num_tl_vc1, total_number.num_tl_dcp1), UVM_HIGH)
            @(posedge tl_dl_vif.clock);
        end
    endtask: packet_to_flit

    //check credits for packet 
    function bit has_credit(int vc, int dcp, bit channel);
        if((cfg_obj.consume_tl_credits_disable == 1'b1) || (mgr.has_tl_credits(1'b0, channel, vc) == 1'b1 && mgr.has_tl_credits(1'b1, channel, dcp) == 1'b1))
            has_credit = 1'b1;
        else 
            has_credit = 1'b0;
        return has_credit;
    endfunction: has_credit

    //consume credits for packet 
    function void consume_credit(int vc, int dcp, bit channel, bit[7:0] packet_type);
        if(cfg_obj.consume_tl_credits_disable == 1'b0)begin
            mgr.get_tl_credits(1'b0, channel, vc, packet_type);
            mgr.get_tl_credits(1'b1, channel, dcp, packet_type);
        end
        if(channel == 0)begin
            total_number.num_tl_vc0 = total_number.num_tl_vc0 + vc;
            total_number.num_tl_dcp0 = total_number.num_tl_dcp0 + dcp;
        end
        else begin
            total_number.num_tl_vc1 = total_number.num_tl_vc1 + vc;
            total_number.num_tl_dcp1 = total_number.num_tl_dcp1 + dcp;
        end
    endfunction: consume_credit

    //select a new template
    virtual task select_new_template();
        bit template_sel[12] = '{1,1,1,1,1,1,0,1,0,1,1,0};
        int template_queue[$]; 
        `uvm_info(get_type_name(), $psprintf("The number of 32-byte/64-byte data to be drive is%d.", present_data_queue.size), UVM_MEDIUM)
        //select template in half-dimm-mode
        if(cfg_obj.half_dimm_mode == 1'b1) begin
            if(present_data_queue.size != 0 && present_data_queue[0].data_to_memory == 1)begin
                template_sel = '{0,0,0,0,0,0,0,0,0,0,1,0};                        
            end
            else
                template_sel = '{1,1,0,0,1,1,0,1,0,1,1,0};
        end
        //select template in non-half-dimm-mode
        else begin
            //select template in metadata enable
            if(cfg_obj.metadata_enable == 1'b1)begin
                if(present_data_queue.size != 0 && present_data_queue[0].data_to_memory == 1)begin
                    if(present_data_queue[0].only_32byte_carrier == 1'b1)begin
                        template_sel = '{0,0,0,0,0,0,0,1,0,1,1,0};                        
                    end
                    else begin
                        template_sel = '{0,0,0,0,1,1,0,1,0,1,1,0};                     
                    end
                end
                else begin
                    if(return_credits_queue.size != 0)begin
                        template_sel = '{1,1,0,0,1,1,0,0,0,0,0,0};
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length == 6))begin
                        template_sel = '{1,0,0,0,0,0,0,0,0,0,0,0};
                    end
                    else begin
                        template_sel = '{1,1,0,0,1,1,0,1,0,1,1,0};
                    end
                end
            end
            else begin
                //template should include 32-byte data carrier for allgnment
                if((present_data_queue.size != 0) && (present_data_queue[0].only_32byte_carrier == 1'b1))begin
                    template_sel = '{0,0,0,0,0,0,0,1,0,1,1,0};
                end
                else if(return_credits_queue.size != 0)begin
                    template_sel = '{1,1,1,1,1,1,0,0,0,0,0,0};
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length == 6))
                    template_sel = '{1,0,0,1,0,0,0,0,0,0,0,0};
                else begin
                    template_sel = '{1,1,1,1,1,1,0,1,0,1,1,0};
                end
            end
        end
        for(int i=0; i<12; i++)begin
            //select priority template
            if(cfg_obj.tx_tmpl_priority_enable)begin
                if((cfg_obj.tl_transmit_template[i] == 1'b1) && (template_sel[i] == 1'b1) && (cfg_obj.tx_tmpl_priority[i] == 1'b1))
                    template_queue.push_back(i);
            end
            else begin
                if((cfg_obj.tl_transmit_template[i] == 1'b1) && (template_sel[i] == 1'b1))
                    template_queue.push_back(i);
            end
        end
        if(template_queue.size == 0)
            template_queue.push_back(0);
        void'(std::randomize(template_rand) with {template_rand inside {template_queue};});
        template = template_rand;
    endtask: select_new_template

    //generate tl_content for supported template
    virtual task gen_tl_content();
        driver_packet packet_temp;
        driver_packet tlx_credits_temp;
        data_on_carrier data_carrier_temp;
        packet_temp = new("packet_temp");
        data_carrier_temp = new("data_carrier_temp");
        `uvm_info(get_type_name(), $psprintf("Generating tl_content for template%d.", template), UVM_MEDIUM)
        for(int i=0; i<16; i++)
            tl_content[i] = 28'b0; 
        case(template)
            6'h0:begin
                //slot 0-1
                while(return_credits_queue.size != 0)begin
                    if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                    && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                        packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                        packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                        packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                        tlx_credits_temp = return_credits_queue.pop_front;
                    end
                    else 
                        break;
                end
                for(int m=0; m<2; m++)
                    tl_content[m] = packet_temp.cmd_resp_packet[m];
                //slot 4-9
                if(vc0_packet_queue.size != 0)begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<6; m++)
                        tl_content[m+4] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)begin
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
                else if(vc1_packet_queue.size != 0)begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<6; m++)
                        tl_content[m+4] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)begin
                        //the data associated with write_byte_enable command will be put 64-byte carrier only
                        if(packet_temp.cmd_resp_length == 6)
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 1, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        else
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
            end
            6'h1:begin
                //slot 0-3
                if(return_credits_queue.size != 0)begin
                    while(return_credits_queue.size != 0)begin
                        if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                        && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                            packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                            packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                            packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                            tlx_credits_temp = return_credits_queue.pop_front;
                        end
                        else 
                            break;
                    end
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if(vc0_packet_queue.size != 0)begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<4; m++)begin
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                    end
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)begin
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
                else if(vc1_packet_queue.size != 0)begin
                    packet_temp = vc1_packet_queue.pop_front;
                    if(packet_temp.cmd_resp_length < 6)begin
                        for(int m=0; m<4; m++)
                            tl_content[m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end   
                end
                //slot 4-7, 8-11, 12-15
                for(int i=1; i<4; i++)begin
                    if(vc0_packet_queue.size != 0)begin
                        packet_temp = vc0_packet_queue.pop_front;
                        for(int m=0; m<4; m++)
                            tl_content[i*4+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 6))begin
                        packet_temp = vc1_packet_queue.pop_front;
                        for(int m=0; m<4; m++)
                            tl_content[i*4+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
            end

            6'h2:begin
                //slot 0-1
                if(return_credits_queue.size != 0)begin
                    while(return_credits_queue.size != 0)begin
                        if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                        && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                            packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                            packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                            packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                            tlx_credits_temp = return_credits_queue.pop_front;
                        end
                        else 
                            break;
                    end
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<2; m++)begin
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                    end
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)begin
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                //slot 2-3, 4-5, 6-7, 8-9, 10-11, 12-13, 14-15
                for(int i=0; i<7; i++)begin
                    if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                        packet_temp = vc0_packet_queue.pop_front;
                        for(int m=0; m<2; m++)
                            tl_content[2+i*2+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                        packet_temp = vc1_packet_queue.pop_front;
                        for(int m=0; m<2; m++)
                            tl_content[2+i*2+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end
                end
            end

            6'h3:begin
                //slot 0-3
                if(return_credits_queue.size != 0)begin
                    while(return_credits_queue.size != 0)begin
                        if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                        && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                            packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                            packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                            packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                            tlx_credits_temp = return_credits_queue.pop_front;
                        end
                        else 
                            break;
                    end
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if(vc0_packet_queue.size != 0)begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)begin
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
                else if(vc1_packet_queue.size != 0)begin
                    packet_temp = vc1_packet_queue.pop_front;
                    if(packet_temp.cmd_resp_length < 6)begin
                        for(int m=0; m<4; m++)
                            tl_content[m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end   
                end
                //slot 4-9, 10-15
                for(int i=0; i<2; i++)begin
                    if(vc0_packet_queue.size != 0)begin
                        packet_temp = vc0_packet_queue.pop_front;
                        for(int m=0; m<6; m++)
                            tl_content[4+6*i+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end
                    else if(vc1_packet_queue.size != 0)begin
                        packet_temp = vc1_packet_queue.pop_front;
                        for(int m=0; m<6; m++)
                            tl_content[4+6*i+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)begin
                            //the data associated with write_byte_enable command will be put 64-byte carrier only
                            if(packet_temp.cmd_resp_length == 6)
                                gen_present_data(packet_temp.data_length, packet_temp.data_packet, 1, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                            else
                                gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                        end
                    end
                end
            end

            6'h4:begin
                //slot 0-1
                if(return_credits_queue.size != 0)begin
                    while(return_credits_queue.size != 0)begin
                        if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                        && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                            packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                            packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                            packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                            tlx_credits_temp = return_credits_queue.pop_front;
                        end
                        else 
                            break;
                    end
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                //mdf will be inserted in task gen_dl_content
                //slot 2 : mdf(3) || mdf(2) || mdf(1) || mdf(0)
                //slot 3 : mdf(7) || mdf(6) || mdf(5) || mdf(4)
                //slot 4-7, 8-11, 12-15
                for(int i=1; i<4; i++)begin
                    if(vc0_packet_queue.size != 0)begin
                        packet_temp = vc0_packet_queue.pop_front;
                        for(int m=0; m<4; m++)
                            tl_content[i*4+m] = packet_temp.cmd_resp_packet[m];
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 6))begin
                        packet_temp = vc1_packet_queue.pop_front;
                        for(int m=0; m<4; m++)
                            tl_content[i*4+m] = packet_temp.cmd_resp_packet[m];
                        //the associated data will be put into present_data_queue
                        if(packet_temp.data_length > 0)
                            gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                    end
                end
            end
            6'h5:begin
                //slot 0-1
                if(return_credits_queue.size != 0)begin
                    while(return_credits_queue.size != 0)begin
                        if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                        && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                            packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                            packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                            packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                            tlx_credits_temp = return_credits_queue.pop_front;
                        end
                        else 
                            break;
                    end
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m] = packet_temp.cmd_resp_packet[m];
                end
                //mdf will be inserted in task gen_dl_content 
                //slot 2 : mdf(3) || mdf(2) || mdf(1) || mdf(0)
                //slot 3 : mdf(7) || mdf(6) || mdf(5) || mdf(4)
                //slot 4, 5, 6, 7, 8, 9, 10, 11
                for(int i=0; i<8; i++)begin
                    if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length == 1))begin
                        packet_temp = new("packet_temp");
                        packet_temp = vc0_packet_queue.pop_front;
                        tl_content[i+4] = packet_temp.cmd_resp_packet[0];
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length == 1))begin
                        packet_temp = new("packet_temp");
                        packet_temp = vc1_packet_queue.pop_front;
                        tl_content[i+4] = packet_temp.cmd_resp_packet[0];
                    end
                end
                //slot 12-15
                if((vc1_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 6))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 6))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                end

            end
            6'h7:begin
                //meta will be inserted in task gen_dl_content 
                //slot 9: mdf(1) || mdf(0) || R(0) || V(1:0) || meta(6:0) || Data(255:252)  32byte data carrier
                //slot 10-11
                if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m+10] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m+10] = packet_temp.cmd_resp_packet[m];
                end
                //slot 12-15
                if(vc0_packet_queue.size != 0)begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 6))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                end
                //slot 0-9
                if(cfg_obj.invalid_data_enable == 1'b0 && present_data_queue.size != 0 && (cfg_obj.half_dimm_mode == 1'b0 || (cfg_obj.half_dimm_mode == 1'b1 && present_data_queue[0].data_to_memory == 1'b0)))begin
                    //the present data has a length of 32-byte
                    if(present_data_queue[0].is_32byte_length == 1)begin
                        data_carrier_temp = present_data_queue.pop_front;
                        for(int m=0; m<9; m++)begin
                            if(data_carrier_temp.addr_high == 1'b0)
                                tl_content[m] = data_carrier_temp.data_carrier[(28*m+27)-:28];
                            else
                                tl_content[m] = data_carrier_temp.data_carrier[(256+28*m+27)-:28];
                        end
                        if(data_carrier_temp.addr_high == 1'b0)
                            tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0, data_carrier_temp.data_carrier[255:252]};
                        else
                            tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0, data_carrier_temp.data_carrier[511:508]};
                    end
                    //part of the present data will be put into 32-byte data carrier
                    else if(present_data_queue[0].only_64byte_carrier != 1'b1)begin
                        data_carrier_temp = present_data_queue[0];
                        for(int m=0; m<9; m++)
                            tl_content[m] = present_data_queue[0].data_carrier[(28*m+27)-:28];
                        tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0,  present_data_queue[0].data_carrier[255:252]};                
                        present_data_queue[0].only_32byte_carrier = 1;
                        present_data_queue[0].is_32byte_length = 1;
//                        present_data_queue[0].data_to_memory = 1;
                        present_data_queue[0].data_carrier[255:0] = present_data_queue[0].data_carrier[511:256];
                        present_data_queue[0].data_carrier[511:256] = 256'b0;
                        present_data_queue[0].addr_high = 1'b0;
                    end
                    if(tl_content[9][12] == 1'b1 && data_carrier_temp.data_to_memory == 1)
                        tl_content[9][10:4] = data_carrier_temp.meta[6:0];
                    //inject error bits if BAD_DATA_IN_CNTL_FLIT is enable
                    if(tl_content[9][12] == 1'b1 && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_CNTL_FLIT))begin    
                        void'(std::randomize(err_cntl_flit));
                        tl_content[9][11] = err_cntl_flit;
                        `uvm_info(get_type_name(), $psprintf("Data error bit in control flit of template x'07' is %d.", err_cntl_flit), UVM_MEDIUM)
                    end
                end                    
            end
            6'h9:begin
                //meta will be inserted in task gen_dl_content 
                //slot 9: mdf(1) || mdf(0) || R(0) || V(1:0) || meta(6:0) || Data(255:252)  32byte data carrier
                //slot 10-11
                if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m+10] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 4))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<2; m++)
                        tl_content[m+10] = packet_temp.cmd_resp_packet[m];
                end
                //slot 12, 13, 14, 15
                for(int i=0; i<4; i++)begin
                    if((vc0_packet_queue.size != 0) && (vc0_packet_queue[0].cmd_resp_length == 1))begin
                        packet_temp = new("packet_temp");
                        packet_temp = vc0_packet_queue.pop_front;
                        tl_content[i+8] = packet_temp.cmd_resp_packet[0];
                    end
                    else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length == 1))begin
                        packet_temp = new("packet_temp");
                        packet_temp = vc1_packet_queue.pop_front;
                        tl_content[i+8] = packet_temp.cmd_resp_packet[0];
                    end
                end
                //slot 0-9
                if(cfg_obj.invalid_data_enable == 1'b0 && present_data_queue.size != 0 && (cfg_obj.half_dimm_mode == 1'b0 || (cfg_obj.half_dimm_mode == 1'b1 && present_data_queue[0].data_to_memory == 1'b0)))begin
                    //the present data has a length of 32-byte
                    if(present_data_queue[0].is_32byte_length == 1)begin
                        data_carrier_temp = present_data_queue.pop_front;
                        for(int m=0; m<9; m++)begin
                            if(data_carrier_temp.addr_high == 1'b0)
                                tl_content[m] = data_carrier_temp.data_carrier[(28*m+27)-:28];
                            else
                                tl_content[m] = data_carrier_temp.data_carrier[(256+28*m+27)-:28];
                        end
                        if(data_carrier_temp.addr_high == 1'b0)
                            tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0, data_carrier_temp.data_carrier[255:252]};
                        else
                            tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0, data_carrier_temp.data_carrier[511:508]};
                    end
                    //part of the present data will be put into 32-byte data carrier
                    else if(present_data_queue[0].only_64byte_carrier != 1'b1)begin
                        data_carrier_temp = present_data_queue[0];
                        for(int m=0; m<9; m++)
                            tl_content[m] = present_data_queue[0].data_carrier[(28*m+27)-:28];
                        tl_content[9][27:0] = {14'b0, 1'b0, 2'b10, 7'b0,  present_data_queue[0].data_carrier[255:252]};                
                        present_data_queue[0].only_32byte_carrier = 1;
                        present_data_queue[0].is_32byte_length = 1;                        
                        present_data_queue[0].data_carrier[255:0] = present_data_queue[0].data_carrier[511:256];
                        present_data_queue[0].data_carrier[511:256] = 256'b0;
                        present_data_queue[0].addr_high = 1'b0;
                    end
                    if(tl_content[9][12] == 1'b1 && data_carrier_temp.data_to_memory == 1)
                        tl_content[9][10:4] = data_carrier_temp.meta[6:0];
                    //inject error bits if BAD_DATA_IN_CNTL_FLIT is enable
                    if(tl_content[9][11] == 1'b1 && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_CNTL_FLIT))begin    
                        void'(std::randomize(err_cntl_flit));
                        tl_content[9][11] = err_cntl_flit;
                        `uvm_info(get_type_name(), $psprintf("Data error bit in control flit of template x'09' is %d.", err_cntl_flit), UVM_MEDIUM)
                    end
                end
            end
            6'ha:begin
                //slot 9 : xmeta(23:0) || Data(255:252) 32byte data carrier
                //slot 10 : xmeta(51:24)
                //slot 11 : R(5:0) || V(1:0) || xmeta(71:52)
                //slot 12-15
                if(vc0_packet_queue.size != 0)begin
                    packet_temp = vc0_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                end
                else if((vc1_packet_queue.size != 0) && (vc1_packet_queue[0].cmd_resp_length < 6))begin
                    packet_temp = vc1_packet_queue.pop_front;
                    for(int m=0; m<4; m++)
                        tl_content[12+m] = packet_temp.cmd_resp_packet[m];
                    //the associated data will be put into present_data_queue
                    if(packet_temp.data_length > 0)
                        gen_present_data(packet_temp.data_length, packet_temp.data_packet, 0, packet_temp.physical_addr[5:0], packet_temp.write_chk_cmd, packet_temp.meta, packet_temp.xmeta);
                end
                //slot 0-9
                if(cfg_obj.invalid_data_enable == 1'b0 && present_data_queue.size != 0 && (cfg_obj.half_dimm_mode == 1'b0 || (cfg_obj.half_dimm_mode == 1'b1 && present_data_queue[0].data_to_memory == 1'b1)))begin
                    //the present data has a length of 32-byte
                    if(present_data_queue[0].is_32byte_length == 1)begin
                        data_carrier_temp = present_data_queue.pop_front;
                        for(int m=0; m<9; m++)begin
                            if(data_carrier_temp.addr_high == 1'b0)
                                tl_content[m] = data_carrier_temp.data_carrier[(28*m+27)-:28];
                            else
                                tl_content[m] = data_carrier_temp.data_carrier[(256+28*m+27)-:28];
                        end
                        if(data_carrier_temp.addr_high == 1'b0)
                            tl_content[9][27:0] = {24'b0, data_carrier_temp.data_carrier[255:252]};
                        else
                            tl_content[9][27:0] = {24'b0, data_carrier_temp.data_carrier[511:508]};
                        tl_content[11][21] = 1;
                    end
                    //part of the present data will be put into 32-byte data carrier
                    else if(present_data_queue[0].only_64byte_carrier != 1'b1)begin
                        data_carrier_temp = present_data_queue[0];
                        for(int m=0; m<9; m++)
                            tl_content[m] = present_data_queue[0].data_carrier[(28*m+27)-:28];
                        tl_content[9][27:0] = {24'b0, present_data_queue[0].data_carrier[255:252]};
                        present_data_queue[0].only_32byte_carrier = 1;
                        present_data_queue[0].is_32byte_length = 1;                        
                        present_data_queue[0].data_carrier[255:0] = present_data_queue[0].data_carrier[511:256];
                        present_data_queue[0].data_carrier[511:256] = 256'b0;
                        present_data_queue[0].addr_high = 1'b0;
                        tl_content[11][21] = 1;
                    end
                    if(cfg_obj.half_dimm_mode == 1'b1 && tl_content[11][21] == 1'b1)begin                            
                        tl_content[11][19:0] = data_carrier_temp.xmeta[71:52];
                        tl_content[10][27:0] = data_carrier_temp.xmeta[51:24];
                        tl_content[9][27:4]  = data_carrier_temp.xmeta[23:0];
                    end
                    if(tl_content[11][21] == 1'b1 && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_CNTL_FLIT))begin    
                        void'(std::randomize(err_cntl_flit));
                        tl_content[11][20] = err_cntl_flit;
                        `uvm_info(get_type_name(), $psprintf("Data error bit in control flit of template x'0a' is %d.", err_cntl_flit), UVM_MEDIUM)
                    end
                end
            end
            default:
                `uvm_error(get_type_name(), "Get an illegal TLX receive/TL transmit template!")
        endcase
    endtask: gen_tl_content 

    //generate the present data
    function void gen_present_data(int data_length, bit[7:0] data_packet[256], bit only_64byte_carrier, bit[5:0] physical_addr, bit data_to_memory, bit[6:0] meta[4], bit[71:0] xmeta[4]);
        data_on_carrier data_carrier_temp;
        if(data_length <= 32)begin
            data_carrier_temp = new("data_carrier_temp");
            data_carrier_temp.is_32byte_length = 1;
            data_carrier_temp.data_carrier = ({data_packet[31], data_packet[30], data_packet[29], data_packet[28], data_packet[27], data_packet[26], data_packet[25], data_packet[24],
                                               data_packet[23], data_packet[22], data_packet[21], data_packet[20], data_packet[19], data_packet[18], data_packet[17], data_packet[16],
                                               data_packet[15], data_packet[14], data_packet[13], data_packet[12], data_packet[11], data_packet[10], data_packet[9], data_packet[8],
                                               data_packet[7], data_packet[6], data_packet[5], data_packet[4], data_packet[3], data_packet[2], data_packet[1], data_packet[0]} << (8*physical_addr[4:0]));
            data_carrier_temp.only_64byte_carrier = only_64byte_carrier;
            data_carrier_temp.only_32byte_carrier = 1'b0;
            data_carrier_temp.addr_high = physical_addr[5];
            data_carrier_temp.data_to_memory = data_to_memory;
            data_carrier_temp.meta = meta[0];
            data_carrier_temp.xmeta = xmeta[0];
            present_data_queue.push_back(data_carrier_temp);
        end
        else
            for(int m=0; m<data_length/64; m++)begin
                data_carrier_temp = new("data_carrier_temp");
                data_carrier_temp.is_32byte_length = 0;
                for(int i=0; i<64; i++)
                    data_carrier_temp.data_carrier[8*i+7-:8] = data_packet[64*m+i];
                data_carrier_temp.only_64byte_carrier = only_64byte_carrier;
                data_carrier_temp.only_32byte_carrier = 1'b0;
                data_carrier_temp.addr_high = 1'b0;
                data_carrier_temp.data_to_memory = data_to_memory;
                data_carrier_temp.meta = meta[m];
                data_carrier_temp.xmeta = xmeta[m];
                present_data_queue.push_back(data_carrier_temp);
            end               
    endfunction: gen_present_data 

    //generate the dl_content for each template
    virtual task gen_dl_content();
        //counter for data that will not be written into memory
        int non_mem_data_cnt = 0;
        dl_content = 64'b0;
        //assign template to dl_content
        dl_content[17:12] = template;
        `uvm_info(get_type_name(), $psprintf("Generating dl_content for template%d.", template), UVM_MEDIUM)
        if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
            if(present_data_queue.size > 8)begin
                dl_content[3:0] = 8;
            end
            else begin
                dl_content[3:0] = present_data_queue.size;                
            end
        end
        else begin
            //count for data that will be written into memory on the front of data queue
            while(non_mem_data_cnt < present_data_queue.size)begin
                if(present_data_queue[non_mem_data_cnt].data_to_memory == 0)
                    non_mem_data_cnt++;
                else
                    break;
            end
            //assign run_length to dl_content
            //assign mdf, metadata to tl_content when memory data in carrier
            if(cfg_obj.half_dimm_mode == 1'b1)begin
                if(non_mem_data_cnt > 0)
                    if(non_mem_data_cnt > cfg_obj.tl_transmit_rate[template])
                        dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                    else
                        dl_content[3:0] = non_mem_data_cnt; 
                else
                    dl_content[3:0] = 0; 
            end
            else begin
                //run_length is 0 when there is a partial data of 32byte                        
                if((present_data_queue.size > 0) && (present_data_queue[0].only_32byte_carrier == 1'b1))begin
                        dl_content[3:0] = 4'h0;                        
                end
                else begin
                    if(cfg_obj.metadata_enable == 1'b1)begin
                        if((template == 6'h0) || (template == 6'h1) || (template == 6'ha))
                            if(non_mem_data_cnt > cfg_obj.tl_transmit_rate[template])
                                dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            else
                                dl_content[3:0] = non_mem_data_cnt; 
                        else if((template == 6'h4) || (template == 6'h5))begin
                            if(present_data_queue.size > cfg_obj.tl_transmit_rate[template])
                                dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            else
                                dl_content[3:0] = present_data_queue.size; 
                            for(int i=0; i<dl_content[3:0]; i++)begin
                                if(i<4)begin
                                    tl_content[2][7*i+6-:7] = present_data_queue[i].meta[6:0];
                                end
                                else
                                    tl_content[3][7*(i-4)+6-:7] = present_data_queue[i].meta[6:0];
                            end
                        end
                        else if((template == 6'h7) || (template == 6'h9))begin
                            if(present_data_queue.size > cfg_obj.tl_transmit_rate[template])begin
                                if(cfg_obj.tl_transmit_rate[template] > 2)
                                    dl_content[3:0] = 4'h2;                        
                                else
                                    dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            end
                            else begin
                                if(present_data_queue.size > 2)
                                    dl_content[3:0] = 4'h2;                        
                                else
                                    dl_content[3:0] = present_data_queue.size; 
                            end
                            for(int i=0; i<dl_content[3:0]; i++)begin
                                tl_content[9][20+7*i-:7] = present_data_queue[i].meta[6:0];
                            end
                        end
                        else
                            `uvm_error(get_type_name(), "Get an illegal TLX receive/TL transmit template for metadata enable!")
                    end
                    else begin
                        if((template == 6'h7) || (template == 6'h9))begin
                            if(present_data_queue.size > cfg_obj.tl_transmit_rate[template])begin
                                if(cfg_obj.tl_transmit_rate[template] > 2)
                                    dl_content[3:0] = 4'h2;                        
                                else
                                    dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            end
                            else begin
                                if(present_data_queue.size > 2)
                                    dl_content[3:0] = 4'h2;                        
                                else
                                    dl_content[3:0] = present_data_queue.size; 
                            end
                            for(int i=0; i<dl_content[3:0]; i++)begin
                                tl_content[9][20+7*i-:7] = present_data_queue[i].meta[6:0];
                            end
                        end
                        else if((template == 6'h4) || (template == 6'h5))begin
                            if(present_data_queue.size > cfg_obj.tl_transmit_rate[template])
                                dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            else
                                dl_content[3:0] = present_data_queue.size; 
                            for(int i=0; i<dl_content[3:0]; i++)begin
                                if(i<4)begin
                                    tl_content[2][7*i+6-:7] = present_data_queue[i].meta[6:0];
                                end
                                else
                                    tl_content[3][7*(i-4)+6-:7] = present_data_queue[i].meta[6:0];
                            end
                        end
                        else begin
                            if(present_data_queue.size > cfg_obj.tl_transmit_rate[template])begin
                                dl_content[3:0] = cfg_obj.tl_transmit_rate[template];
                            end
                            else begin
                                dl_content[3:0] = present_data_queue.size;                
                            end
                        end
                    end
                end
            end
        end
        if((cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_DATA_FLIT))begin
            void'(std::randomize(err_data_flit));
            for(int i=0; i<8; i++)begin
                if(i>=last_run_length)
                    err_data_flit[i] = 1'b0;
            end
            dl_content[11:4] = err_data_flit[7:0];
            `uvm_info(get_type_name(), $psprintf("Data error bits for data flit are%b.", err_data_flit[7:0]), UVM_MEDIUM)
            last_run_length = dl_content[3:0];
        end
        else begin
            err_data_flit = 0;
            last_run_length = 0;
        end
        `uvm_info(get_type_name(), $psprintf("Run length of%d is generated for template of%d.", dl_content[3:0], template), UVM_MEDIUM)
    endtask: gen_dl_content

    //generate flits to drive
    virtual task gen_flit();
        driver_flit flit_temp;
        data_on_carrier present_data_queue_temp;
        bit[511:0] null_cntl_temp;
        `uvm_info(get_type_name(), $psprintf("Generating flits for drving."), UVM_MEDIUM)
        //generate control flit
        if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
            flit_temp = new("flit_temp");
            flit_temp.flit = {dl_content, tl_content[15], tl_content[14], tl_content[13], tl_content[12], tl_content[11], tl_content[10], 
            tl_content[9], tl_content[8], tl_content[7], tl_content[6], tl_content[5], tl_content[4], tl_content[3], tl_content[2], tl_content[1], tl_content[0]};
            flit_temp.is_cntl_flit = 1'b1;
            flit_queue.push_back(flit_temp);
        end
        else begin
            flit_temp = new("flit_temp");
            flit_temp.flit = {tl_content[4][15:0], tl_content[3], tl_content[2], tl_content[1], tl_content[0]};
            flit_temp.is_cntl_flit = 1'b1;
            flit_queue.push_back(flit_temp);
            flit_temp = new("flit_temp");
            flit_temp.flit = {tl_content[9][3:0], tl_content[8], tl_content[7], tl_content[6], tl_content[5], tl_content[4][27:16]};
            flit_temp.is_cntl_flit = 1'b1;
            flit_queue.push_back(flit_temp);
            flit_temp = new("flit_temp");
            flit_temp.flit = {tl_content[13][19:0], tl_content[12], tl_content[11], tl_content[10], tl_content[9][27:4]};
            flit_temp.is_cntl_flit = 1'b1;
            flit_queue.push_back(flit_temp);
            flit_temp = new("flit_temp");
            flit_temp.flit = {dl_content, tl_content[15], tl_content[14], tl_content[13][27:20]};
            flit_temp.is_cntl_flit = 1'b1;
            flit_temp.is_last_cntl_flit = 1'b1;
            flit_queue.push_back(flit_temp);
        end

        //generate data flit
        for(int i=0; i<dl_content[3:0]; i++)begin
            present_data_queue_temp = present_data_queue.pop_front;
            if(present_data_queue_temp.addr_high == 1'b1)
                present_data_queue_temp.data_carrier = present_data_queue_temp.data_carrier << 256;
            if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                flit_temp = new("flit_temp");
                flit_temp.flit = present_data_queue_temp.data_carrier[511:0];
                flit_temp.is_data_flit = 1'b1;                
                flit_queue.push_back(flit_temp);
            end
            else begin
                flit_temp = new("flit_temp");
                flit_temp.flit = present_data_queue_temp.data_carrier[127:0];
                flit_temp.is_data_flit = 1'b1;
                flit_queue.push_back(flit_temp);
                flit_temp = new("flit_temp");
                flit_temp.flit = present_data_queue_temp.data_carrier[255:128];
                flit_temp.is_data_flit = 1'b1;
                flit_queue.push_back(flit_temp);
                flit_temp = new("flit_temp");
                flit_temp.flit = present_data_queue_temp.data_carrier[383:256];
                flit_temp.is_data_flit = 1'b1;
                flit_queue.push_back(flit_temp);
                flit_temp = new("flit_temp");
                flit_temp.flit = present_data_queue_temp.data_carrier[511:384];
                flit_temp.is_data_flit = 1'b1;
                flit_temp.is_last_data_flit = 1'b1;
                flit_queue.push_back(flit_temp);
            end
        end

        //generate null control flit
        if((cfg_obj.null_flit_enable == 1'b1) && (cfg_obj.tl_transmit_rate[template] > dl_content[3:0]))begin
            //insert null control flit and the slot 0-1 may be used to return tlx credits
            for(int i=0; i<(cfg_obj.tl_transmit_rate[template] - dl_content[3:0]); i++)begin
                null_cntl_temp = gen_null_flit();
                if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0) begin
                    flit_temp = new("flit_temp");
                    flit_temp.flit = null_cntl_temp[511:0];
                    flit_temp.is_cntl_flit = 1'b1;                    
                    flit_queue.push_back(flit_temp);
                end
                else begin
                    flit_temp = new("flit_temp");
                    flit_temp.flit = null_cntl_temp[127:0];
                    flit_temp.is_cntl_flit = 1'b1;
                    flit_queue.push_back(flit_temp);
                    flit_temp = new("flit_temp");
                    flit_temp.flit = null_cntl_temp[255:128];
                    flit_temp.is_cntl_flit = 1'b1;
                    flit_queue.push_back(flit_temp);
                    flit_temp = new("flit_temp");
                    flit_temp.flit = null_cntl_temp[383:256];
                    flit_temp.is_cntl_flit = 1'b1;
                    flit_queue.push_back(flit_temp);
                    flit_temp = new("flit_temp");
                    flit_temp.flit = null_cntl_temp[511:384];
                    flit_temp.is_cntl_flit = 1'b1;
                    flit_temp.is_last_cntl_flit = 1'b1;
                    flit_queue.push_back(flit_temp);
                end
            end
        `uvm_info(get_type_name(), $psprintf("%d null control flits will be inserted during rate.", (cfg_obj.tl_transmit_rate[template] - dl_content[3:0])), UVM_MEDIUM)
        end
    endtask: gen_flit

    //generate null control flits
    function bit[511:0] gen_null_flit();
        driver_packet tlx_credits_temp;
        driver_packet packet_temp;
        packet_temp = new("packet_temp");
            while(return_credits_queue.size != 0)begin
                if(((packet_temp.cmd_resp_packet[0][11:8] + return_credits_queue[0].cmd_resp_packet[0][11:8]) <= 15) && ((packet_temp.cmd_resp_packet[0][23:20] + return_credits_queue[0].cmd_resp_packet[0][23:20]) <= 15) 
                && ((packet_temp.cmd_resp_packet[1][9:4] + return_credits_queue[0].cmd_resp_packet[1][9:4]) <= 63) && ((packet_temp.cmd_resp_packet[1][27:22] + return_credits_queue[0].cmd_resp_packet[1][27:22]) <= 63))begin
                    packet_temp.cmd_resp_packet[0][27:8] = packet_temp.cmd_resp_packet[0][27:8] + return_credits_queue[0].cmd_resp_packet[0][27:8];
                    packet_temp.cmd_resp_packet[0][7:0] = return_credits_queue[0].cmd_resp_packet[0][7:0];
                    packet_temp.cmd_resp_packet[1] = packet_temp.cmd_resp_packet[1] + return_credits_queue[0].cmd_resp_packet[1];
                    tlx_credits_temp = return_credits_queue.pop_front;
                end
                else 
                    break;
            end
        gen_null_flit = {64'b0, 392'b0, packet_temp.cmd_resp_packet[1], packet_temp.cmd_resp_packet[0]};                        
        return gen_null_flit;
    endfunction: gen_null_flit

    virtual task drive_to_tlx();
        bit get_crc_err = 0;
        bit flit_err_insert_enable = 0;
        int last_data_cnt = 0;
        driver_flit flit_queue_temp;
        signals_dly signals_temp;
        signals_temp = new("signals_temp");
        forever begin
            //UNIT MODE
            if(cfg_obj.sim_mode == tl_cfg_obj::UNIT_SIM)begin
                if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0)begin
                    while(flit_queue.size != 0)begin
                        flit_queue_temp = flit_queue.pop_front;
                        //drive valid signal
                        if(get_crc_err == 1'b1)
                            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                        else
                            tl_dl_vif.dl_tl_flit_vld <= 1'b1;
                        //drive flit error signal
                        if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                        //drive flit data signals
                        tl_dl_vif.dl_tl_flit_data <= flit_queue_temp.flit;
                        if(flit_queue_temp.is_cntl_flit == 1'b1)begin
                            `uvm_info(get_type_name(), $psprintf("The drived control flit is%h.", flit_queue_temp.flit), UVM_MEDIUM)
                            last_data_cnt = 0;                        
                        end
                        else begin
                            `uvm_info(get_type_name(), $psprintf("The drived data flit is%h.", flit_queue_temp.flit), UVM_MEDIUM)
                            last_data_cnt = 1;
                        end
                        //randomize error flit bit for next flit
                        void'(std::randomize(err_pin_flit));
                        if(flit_queue_temp.is_last_cntl_flit == 1'b1)begin
                            if((err_pin_flit == 1'b1) && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::PIN_FLIT_ERR))begin
                                get_crc_err = 1'b1; 
                            end
                            flit_err_insert_enable = 1'b0;
                        end
                        else
                            flit_err_insert_enable = 1'b1;
                        @(posedge tl_dl_vif.clock);
                    end
                    //drive nops when the last flit is a data flit 
                    if(last_data_cnt > cfg_obj.driver_last_nop_timer)begin //get last nop time from config
                        if(cfg_obj.ocapi_version == tl_cfg_obj::OPENCAPI_3_0)
                            template=0;
                        else
                            select_new_template();
                        `uvm_info(get_type_name(), $psprintf("New template of%d is generated for drive the last nop.", template), UVM_MEDIUM)  
                        last_data_cnt = 0; 
                        //send last nops
                        //drive valid signal
                        if(get_crc_err == 1'b1)
                            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                        else
                            tl_dl_vif.dl_tl_flit_vld <= 1'b1;
                        //drive flit error signal
                        if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                        //random bad data flit bits in last drived control flit if bad data in data flit is enable
                        if((cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_DATA_FLIT))begin
                            void'(std::randomize(err_data_flit));
                            for(int i=0; i<8; i++)begin
                                if(i>=last_run_length)
                                    err_data_flit[i] = 1'b0;
                            end
                            `uvm_info(get_type_name(), $psprintf("Data error bits for data flit are%b.", err_data_flit[7:0]), UVM_MEDIUM)
                            last_run_length = 0;
                        end
                        else begin
                            err_data_flit = 0;
                            last_run_length = 0;
                        end
                        //drive flit data signals
                        tl_dl_vif.dl_tl_flit_data <= {46'b0, template, err_data_flit, 4'b0, 64'b0, 384'b0};
                        `uvm_info(get_type_name(), $psprintf("The drived last nops control flit is%h.", {46'b0, template, err_data_flit, 4'b0, 64'b0, 384'b0}), UVM_MEDIUM)
                        void'(std::randomize(err_pin_flit));
                        if((err_pin_flit == 1'b1) && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::PIN_FLIT_ERR))begin
                            get_crc_err = 1'b1; 
                        end
                        flit_err_insert_enable = 1'b0; 
                        @(posedge tl_dl_vif.clock);
                        if(reset_signal == 1)begin
                            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                            tl_dl_vif.dl_tl_flit_data <= 128'b0;
                            reset_signal = 0;
                            break;
                        end
                    end
                    else begin
                        if(last_data_cnt > 0)
                            last_data_cnt++;
                        else
                            last_data_cnt=0;
                        //drive valid signal
                        tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                        //drive flit error signal
                        if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                        //drive flit data signals
                        tl_dl_vif.dl_tl_flit_data <= 128'b0;
                        //drive flit parity signals
                        tl_dl_vif.dl_tl_flit_pty <= 16'b0;
                        void'(std::randomize(err_pin_flit));
                        flit_err_insert_enable = 1'b1;
                        @(posedge tl_dl_vif.clock);
                    end
                end
                else begin
                    while(flit_queue.size != 0)begin
                        flit_queue_temp = flit_queue.pop_front;
                        //drive valid signal
                        if(get_crc_err == 1'b1)
                            tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                        else
                            tl_dl_vif.dl_tl_flit_vld <= 1'b1;
                        //drive flit error signal
                        if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                        //drive flit data signals
                        tl_dl_vif.dl_tl_flit_data <= flit_queue_temp.flit;
                        if(flit_queue_temp.is_cntl_flit == 1'b1)begin
                            `uvm_info(get_type_name(), $psprintf("The drived control flit is%h.", flit_queue_temp.flit), UVM_MEDIUM)
                            last_data_cnt = 0;                        
                        end
                        else begin
                            `uvm_info(get_type_name(), $psprintf("The drived data flit is%h.", flit_queue_temp.flit), UVM_MEDIUM)
                            last_data_cnt = 1;
                        end
                        //drive flit parity signals
                        tl_dl_vif.dl_tl_flit_pty <= gen_parity_bits (flit_queue_temp.flit);
                        //randomize error flit bit for next flit
                        void'(std::randomize(err_pin_flit));
                        if(flit_queue_temp.is_last_cntl_flit == 1'b1)begin
                            if((err_pin_flit == 1'b1) && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::PIN_FLIT_ERR))begin
                                get_crc_err = 1'b1; 
                            end
                            flit_err_insert_enable = 1'b0;
                        end
                        else
                            flit_err_insert_enable = 1'b1;
                        @(posedge tl_dl_vif.clock);
                    end
                    //drive nops when the last flit is a data flit 
                    if(last_data_cnt > cfg_obj.driver_last_nop_timer)begin //get last nop time from config
                        select_new_template();
                        `uvm_info(get_type_name(), $psprintf("New template of%d is generated for drive the last nop.", template), UVM_MEDIUM)  
                        last_data_cnt = 0; 
                        //send last nops
                        for(int i=0; i<4; i++)begin
                            if(i<3)begin
                                //drive valid signal
                                if(get_crc_err == 1'b1)
                                    tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                                else
                                    tl_dl_vif.dl_tl_flit_vld <= 1'b1;
                                //drive flit error signal
                                if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                                    tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                                else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                                    tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                                else
                                    tl_dl_vif.dl_tl_flit_error <= 1'b0;
                                //drive flit data signals
                                tl_dl_vif.dl_tl_flit_data <= 128'b0;
                                `uvm_info(get_type_name(), $psprintf("The drived last nops control flit is%h.", 128'b0), UVM_MEDIUM)
                                //drive flit parity signals
                                tl_dl_vif.dl_tl_flit_pty <= 16'b0;
                                void'(std::randomize(err_pin_flit));
                                flit_err_insert_enable = 1'b1;
                                @(posedge tl_dl_vif.clock);
                            end
                            else begin
                                //drive valid signal
                                if(get_crc_err == 1'b1)
                                    tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                                else
                                    tl_dl_vif.dl_tl_flit_vld <= 1'b1;
                                //drive flit error signal
                                if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                                    tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                                else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                                    tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                                else
                                    tl_dl_vif.dl_tl_flit_error <= 1'b0;
                                //random bad data flit bits in last drived control flit if bad data in data flit is enable
                                if((cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_DATA_FLIT))begin
                                    void'(std::randomize(err_data_flit));
                                    for(int i=0; i<8; i++)begin
                                        if(i>=last_run_length)
                                            err_data_flit[i] = 1'b0;
                                    end
                                    `uvm_info(get_type_name(), $psprintf("Data error bits for data flit are%b.", err_data_flit[7:0]), UVM_MEDIUM)
                                    last_run_length = 0;
                                end
                                else begin
                                    err_data_flit = 0;
                                    last_run_length = 0;
                                end
                                //drive flit data signals
                                tl_dl_vif.dl_tl_flit_data <= {46'b0, template, err_data_flit, 4'b0, 64'b0};
                                `uvm_info(get_type_name(), $psprintf("The drived last nops control flit is%h.", {46'b0, template, err_data_flit, 4'b0, 64'b0}), UVM_MEDIUM)
                                //drive flit parity signals
                                tl_dl_vif.dl_tl_flit_pty <= gen_parity_bits({46'b0, template, err_data_flit, 4'b0, 64'b0});
                                void'(std::randomize(err_pin_flit));
                                if((err_pin_flit == 1'b1) && (cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::PIN_FLIT_ERR))begin
                                    get_crc_err = 1'b1; 
                                end
                                flit_err_insert_enable = 1'b0; 
                                @(posedge tl_dl_vif.clock);
                            end
                            if(reset_signal == 1)begin
                                tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                                tl_dl_vif.dl_tl_flit_error <= 1'b0;
                                tl_dl_vif.dl_tl_flit_data <= 128'b0;
                                tl_dl_vif.dl_tl_flit_pty <= 16'b0;
                                reset_signal = 0;
                                break;
                            end
                        end
                    end
                    else begin
                        if(last_data_cnt > 0)
                            last_data_cnt++;
                        else
                            last_data_cnt=0;
                        //drive valid signal
                        tl_dl_vif.dl_tl_flit_vld <= 1'b0;
                        //drive flit error signal
                        if((get_crc_err == 1'b1) && (flit_err_insert_enable == 1'b0))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else if((cfg_obj.pin_flit_err_rand_enable == 1'b1) && (flit_err_insert_enable == 1'b1))
                            tl_dl_vif.dl_tl_flit_error <= err_pin_flit;
                        else
                            tl_dl_vif.dl_tl_flit_error <= 1'b0;
                        //drive flit data signals
                        tl_dl_vif.dl_tl_flit_data <= 128'b0;
                        //drive flit parity signals
                        tl_dl_vif.dl_tl_flit_pty <= 16'b0;
                        void'(std::randomize(err_pin_flit));
                        flit_err_insert_enable = 1'b1;
                        @(posedge tl_dl_vif.clock);
                    end
                end
            end
            //CHIP MODE
            else begin
                while(flit_queue.size != 0)begin
                    if(mgr.has_dl_credits(1) != 1'b1)begin
                        if(reset_signal == 1)begin
                            signals_temp.tl_dl_flit_vld = 1'b0;
                            signals_temp.tl_dl_flit_data = 128'b0;
                            signals_temp.tl_dl_flit_ecc = 16'b0;
                            signals_temp.is_last_data_flit = 1'b0;
                            tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                            last_data_cnt = 0;
                            reset_signal = 0;
                            break;
                        end
                        tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                        tl_dl_vif.tl_dl_flit_vld <= signals_temp.tl_dl_flit_vld;
                        tl_dl_vif.tl_dl_flit_data <= signals_temp.tl_dl_flit_data;
                        tl_dl_vif.tl_dl_flit_ecc <= signals_temp.tl_dl_flit_ecc;                        
                        tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                        tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                        tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                        if(signals_temp.tl_dl_flit_vld == 1'b1)
                            `uvm_info(get_type_name(), $psprintf("The drived flit is%h.", signals_temp.tl_dl_flit_data), UVM_MEDIUM)
                        signals_temp.tl_dl_flit_vld = 1'b0;
                        signals_temp.tl_dl_flit_data = 128'b0;
                        signals_temp.tl_dl_flit_ecc = 16'b0;
                        signals_temp.is_last_data_flit = 1'b0;
                        `uvm_info(get_type_name(), $psprintf("Waiting for dl credits!"), UVM_HIGH)
                        @(posedge tl_dl_vif.clock);	
                    end
                    else begin
                        if(reset_signal == 1)begin
                            signals_temp.tl_dl_flit_vld = 1'b0;
                            signals_temp.tl_dl_flit_data = 128'b0;
                            signals_temp.tl_dl_flit_ecc = 16'b0;
                            signals_temp.is_last_data_flit = 1'b0;
                            tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                            reset_signal = 0;
                            last_data_cnt = 0;
                            break;
                        end
                        flit_queue_temp = flit_queue.pop_front;
                        tl_dl_vif.tl_dl_flit_early_vld <= 1'b1;
                        tl_dl_vif.tl_dl_flit_vld <= signals_temp.tl_dl_flit_vld;
                        tl_dl_vif.tl_dl_flit_data <= signals_temp.tl_dl_flit_data;
                        tl_dl_vif.tl_dl_flit_ecc <= signals_temp.tl_dl_flit_ecc;
                        if(signals_temp.tl_dl_flit_vld == 1'b1)
                            `uvm_info(get_type_name(), $psprintf("The drived flit is%h.", signals_temp.tl_dl_flit_data), UVM_MEDIUM)
                        signals_temp.tl_dl_flit_vld = 1'b1;
                        signals_temp.tl_dl_flit_data = flit_queue_temp.flit;
                        signals_temp.tl_dl_flit_ecc = gen_ecc_bits (flit_queue_temp.flit);
                        signals_temp.is_last_data_flit = flit_queue_temp.is_last_data_flit;
                        if(flit_queue_temp.is_last_cntl_flit)begin
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b1;
                            tl_dl_vif.tl_dl_flit_lbip_data <= flit_queue_temp.flit;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= gen_ecc_bits (flit_queue_temp.flit);
                        end
                        else begin
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0; 
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                        end
                        mgr.get_dl_credits(1);
                        @(posedge tl_dl_vif.clock);	
                    end
                end

                //drive nops when the last flit is a data flit 
                if((last_data_cnt >= cfg_obj.driver_last_nop_timer) && (signals_temp.is_last_data_flit == 1'b1))begin //get last nop time from config
                    select_new_template();
                    `uvm_info(get_type_name(), $psprintf("New template of%d is generated for drive the last nop", template), UVM_MEDIUM)
                    signals_temp.is_last_data_flit = 1'b0;
                    last_data_cnt = 0;
                    for(int i=0; i<4; i++)begin
                        while(mgr.has_dl_credits(1) != 1'b1)begin
                            if(reset_signal == 1)begin
                                signals_temp.tl_dl_flit_vld = 1'b0;
                                signals_temp.tl_dl_flit_data = 128'b0;
                                signals_temp.tl_dl_flit_ecc = 16'b0;
                                signals_temp.is_last_data_flit = 1'b0; 
                                tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                                tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                                tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                                tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                                last_data_cnt = 0;
                                break;
                            end
                            tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_vld <= signals_temp.tl_dl_flit_vld;
                            tl_dl_vif.tl_dl_flit_data <= signals_temp.tl_dl_flit_data;
                            tl_dl_vif.tl_dl_flit_ecc <= signals_temp.tl_dl_flit_ecc;                        
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                            if(signals_temp.tl_dl_flit_vld == 1'b1)
                                `uvm_info(get_type_name(), $psprintf("The drived flit is%h.", signals_temp.tl_dl_flit_data), UVM_MEDIUM)
                            signals_temp.tl_dl_flit_vld = 1'b0;
                            signals_temp.tl_dl_flit_data = 128'b0;
                            signals_temp.tl_dl_flit_ecc = 16'b0;
                            signals_temp.is_last_data_flit = 1'b0;
                            `uvm_info(get_type_name(), $psprintf("Waiting for dl credits!"), UVM_HIGH)
                            @(posedge tl_dl_vif.clock);	
                        end
                        if(reset_signal == 1)begin
                            signals_temp.tl_dl_flit_vld = 1'b0;
                            signals_temp.tl_dl_flit_data = 128'b0;
                            signals_temp.tl_dl_flit_ecc = 16'b0;
                            signals_temp.is_last_data_flit = 1'b0;
                            tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                            last_data_cnt = 0;
                            reset_signal = 0;
                            break;
                        end
                        tl_dl_vif.tl_dl_flit_early_vld <= 1'b1;
                        tl_dl_vif.tl_dl_flit_vld <= signals_temp.tl_dl_flit_vld;
                        tl_dl_vif.tl_dl_flit_data <= signals_temp.tl_dl_flit_data;
                        tl_dl_vif.tl_dl_flit_ecc <= signals_temp.tl_dl_flit_ecc;
                        if(signals_temp.tl_dl_flit_vld == 1'b1)
                            `uvm_info(get_type_name(), $psprintf("The drived flit is%h.", signals_temp.tl_dl_flit_data), UVM_MEDIUM)
                        if(i == 3)begin
                            //random bad data flit bits in last drived control flit if bad data in data flit is enable
                            if((cfg_obj.inject_err_enable == 1'b1) && (cfg_obj.inject_err_type == tl_cfg_obj::BAD_DATA_IN_DATA_FLIT))begin
                                void'(std::randomize(err_data_flit));
                                for(int i=0; i<8; i++)begin
                                    if(i>=last_run_length)
                                        err_data_flit[i] = 1'b0;
                                end
                                `uvm_info(get_type_name(), $psprintf("Data error bits for data flit are%b.", err_data_flit[7:0]), UVM_MEDIUM)
                                last_run_length = 0;
                            end
                            else begin
                                err_data_flit = 0;
                                last_run_length = 0;
                            end
                            //drive flit data signals
                            `uvm_info(get_type_name(), $psprintf("The drived last nops control flit is%h.", {46'b0, template, err_data_flit, 4'b0, 64'b0}), UVM_MEDIUM)
                            signals_temp.tl_dl_flit_vld = 1'b1;
                            signals_temp.tl_dl_flit_data = {46'b0, template, err_data_flit, 4'b0, 64'b0};
                            signals_temp.tl_dl_flit_ecc =  gen_ecc_bits({46'b0, template, err_data_flit, 4'b0, 64'b0});
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b1;
                            tl_dl_vif.tl_dl_flit_lbip_data <= {template, err_data_flit, 4'b0, 64'b0};
                            tl_dl_vif.tl_dl_flit_lbip_ecc <=  gen_ecc_bits({46'b0, template, err_data_flit, 4'b0, 64'b0});
                        end
                        else begin
                            signals_temp.tl_dl_flit_vld = 1'b1;
                            signals_temp.tl_dl_flit_data = 128'b0;
                            signals_temp.tl_dl_flit_ecc = 16'b0;
                            tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                            tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                            tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                        end
                        mgr.get_dl_credits(1);
                        @(posedge tl_dl_vif.clock);	
                    end
                end
                else begin
                    if(reset_signal == 1)begin
                        signals_temp.tl_dl_flit_vld = 1'b0;
                        signals_temp.tl_dl_flit_data = 128'b0;
                        signals_temp.tl_dl_flit_ecc = 16'b0;
                        signals_temp.is_last_data_flit = 1'b0;
                        tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                        tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                        tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                        tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                        last_data_cnt = 0;
                        reset_signal = 0;
                    end
                    if(signals_temp.is_last_data_flit == 1'b1)begin
                        last_data_cnt++;
                        signals_temp.is_last_data_flit = 1'b1;
                    end
                    else begin
                        last_data_cnt=0;
                        signals_temp.is_last_data_flit = 1'b0;
                    end
                    tl_dl_vif.tl_dl_flit_early_vld <= 1'b0;
                    tl_dl_vif.tl_dl_flit_vld <= signals_temp.tl_dl_flit_vld;
                    tl_dl_vif.tl_dl_flit_data <= signals_temp.tl_dl_flit_data;
                    tl_dl_vif.tl_dl_flit_ecc <= signals_temp.tl_dl_flit_ecc;
                    if(signals_temp.tl_dl_flit_vld == 1'b1)
                        `uvm_info(get_type_name(), $psprintf("The drived flit is%h.", signals_temp.tl_dl_flit_data), UVM_MEDIUM)
                    signals_temp.tl_dl_flit_vld = 1'b0;
                    signals_temp.tl_dl_flit_data = 128'b0;
                    signals_temp.tl_dl_flit_ecc = 16'b0;
                    tl_dl_vif.tl_dl_flit_lbip_vld <= 1'b0;
                    tl_dl_vif.tl_dl_flit_lbip_data <= 82'h0;
                    tl_dl_vif.tl_dl_flit_lbip_ecc <= 16'h0;
                    @(posedge tl_dl_vif.clock);	
                end

            end
        end
    endtask: drive_to_tlx

    //generate 16 parity bits for 128 bits flit
    function bit[15:0] gen_parity_bits (bit[127:0] flit_data);  //generate odd parity 16 bits for 128 bits
        bit[15:0] parity_bits; 
        for(int p=0; p<16; p++)
            parity_bits[p] = ^flit_data[8*p+7-:8];
        return parity_bits;
    endfunction: gen_parity_bits

    //generate 16 ECC check bits for 128 bits flit
    function bit[15:0] gen_ecc_bits(bit[127:0] data);
        //64-8 bit ecc table
        byte ecc_pat[72] = '{8'hc4, 8'h8c, 8'h94, 8'hd0, 8'hf4, 8'hb0, 8'ha8, 8'he0,
					  8'h62, 8'h46, 8'h4a, 8'h68, 8'h7a, 8'h58, 8'h54, 8'h70,
					  8'h31, 8'h23, 8'h25, 8'h34, 8'h3d, 8'h2c, 8'h2a, 8'h38,
					  8'h98, 8'h91, 8'h92, 8'h1a, 8'h9e, 8'h16, 8'h15, 8'h1c,
					  8'h4c, 8'hc8, 8'h49, 8'h0d, 8'h4f, 8'h0b, 8'h8a, 8'h0e,
					  8'h26, 8'h64, 8'ha4, 8'h86, 8'ha7, 8'h85, 8'h45, 8'h07,
					  8'h13, 8'h32, 8'h52, 8'h43, 8'hd3, 8'hc2, 8'ha2, 8'h83,
					  8'h89, 8'h19, 8'h29, 8'ha1, 8'he9, 8'h61, 8'h51, 8'hc1, 8'hc7,
					  8'h80, 8'h40, 8'h20, 8'h10, 8'h08, 8'h04, 8'h02};
        bit [7:0] ecc_syndrome_0, ecc_syndrome_1;
        bit [31:0] bit_pos, bit_mask, bad_bit, qw0, qw1, qw2, qw3; 
        ecc_syndrome_0 = 8'h00;
        ecc_syndrome_1 = 8'h00;
        bit_pos = 0;

        //generate ecc according to the data
        qw0 = data[127:96];
        qw1 = data[95:64];
        qw2 = data[63:32];
        qw3 = data[31:0];
        for( bit_mask = (1<<31); bit_mask; ++bit_pos) begin
            if(qw0 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos];
            if(qw1 & bit_mask) ecc_syndrome_0 ^= ecc_pat[bit_pos+32];
            if(qw2 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos];
            if(qw3 & bit_mask) ecc_syndrome_1 ^= ecc_pat[bit_pos+32];
            bit_mask >>= 1;
        end
        gen_ecc_bits = {ecc_syndrome_0, ecc_syndrome_1};
        return gen_ecc_bits;
    endfunction: gen_ecc_bits

endclass: tl_tx_driver

`endif

