// ****************************************************************
// (C) Copyright International Business Machines Corporation 2018
//              All Rights Reserved -- Property of IBM
//                     *** IBM Confidential ***
// ****************************************************************
//------------------------------------------------------------------------------
//
// CLASS: tlx_afu_monitor
//
//------------------------------------------------------------------------------
`ifndef _TLX_AFU_MONITOR_SV_
`define _TLX_AFU_MONITOR_SV_

class tlx_afu_monitor extends uvm_monitor;

    // Interface & Port
    string                                                tID;
    virtual interface tlx_afu_interface                   tlx_afu_vif;
    virtual interface intrp_interface                     intrp_vif;
    uvm_analysis_port #(tlx_afu_transaction)              tlx_afu_tran_port;
    uvm_analysis_port #(afu_tlx_transaction)              afu_tlx_tran_port;
    uvm_analysis_port #(intrp_transaction)                intrp_tran_port;

    // Local signals
    afu_tlx_transaction      afu_tlx_cmd_trans;
    afu_tlx_transaction      afu_tlx_resp_trans;
    tlx_afu_transaction      tlx_afu_cmd_trans;
    tlx_afu_transaction      tlx_afu_resp_trans;
    intrp_transaction        intrp_trans;

    int                      afu_tlx_cmd_num;
    int                      afu_tlx_resp_num;
    int                      tlx_afu_cmd_num;
    int                      tlx_afu_resp_num;

    bit[512:0]               afu_tlx_cmd_data_q[$];
    bit[512:0]               afu_tlx_resp_data_q[$];
    bit[512:0]               tlx_afu_cmd_data_q[$];
    bit[512:0]               tlx_afu_resp_data_q[$];

    afu_tlx_transaction      afu_tlx_cmd_trans_q[$];
    afu_tlx_transaction      afu_tlx_resp_trans_q[$];
    tlx_afu_transaction      tlx_afu_cmd_trans_q[$];
    tlx_afu_transaction      tlx_afu_resp_trans_q[$];

    //------------------------CONFIGURATION PARAMETERS--------------------------------
    // TLX_AFU_MONITOR Configuration Parameters. These parameters can be controlled through
    // the UVM configuration database
    // @{

    // Trace player has three work modes for different usages:
    // CMOD_ONLY:   only cmod is working
    // RTL_ONLY:    only DUT rtl is working
    // CROSS_CHECK: default verfication mode, cross check between RTL and CMOD
    string                      work_mode = "CROSS_CHECK";
    //event                       action_tb_finish;

    // }@

    `uvm_component_utils_begin(tlx_afu_monitor)
        `uvm_field_string(work_mode, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "tlx_afu_monitor", uvm_component parent = null);

    // UVM Phases
    // Can just enable needed phase
    // @{

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    //extern function void end_of_elaboration_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase);
    //extern task          reset_phase(uvm_phase phase);
    //extern task          configure_phase(uvm_phase phase);
    extern task          main_phase(uvm_phase phase);
    extern task          shutdown_phase(uvm_phase phase);
    //extern function void extract_phase(uvm_phase phase);
    //extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);

    // }@
    extern task collect_afu_tlx_cmd();
    extern task collect_afu_tlx_resp();
    extern task collect_tlx_afu_cmd();
    extern task collect_tlx_afu_resp();
    extern function afu_tlx_transaction::afu_tlx_enum get_afu_tlx_type(bit[7:0] afu_tlx_opcode);
    extern function tlx_afu_transaction::tlx_afu_enum get_tlx_afu_type(bit[7:0] tlx_afu_opcode);
    extern function void pack_afu_tlx_cmd();
    extern function void pack_tlx_afu_cmd();
    extern function void pack_afu_tlx_resp();
    extern function void pack_tlx_afu_resp();
    extern function int dl2dl_num(bit[1:0] dl);
    extern task collect_interrupt();

endclass : tlx_afu_monitor

// Function: new
// Creates a new dbb check monitor
function tlx_afu_monitor::new(string name = "tlx_afu_monitor", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    tlx_afu_tran_port = new("tlx_afu_tran_port", this);
    afu_tlx_tran_port = new("afu_tlx_tran_port", this);    
    intrp_tran_port = new("intrp_tran_port", this);
    afu_tlx_cmd_num = 0;
    afu_tlx_resp_num = 0;
    tlx_afu_cmd_num = 0;
    tlx_afu_resp_num = 0;
endfunction : new

// Function: build_phase
// XXX
function void tlx_afu_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)

    //if($value$plusargs("WORK_MODE=%0s", work_mode)) begin
    //    `uvm_info(tID, $sformatf("Setting WORK_MODE:%0s", work_mode), UVM_MEDIUM)
    //end
endfunction : build_phase

// Function: connect_phase
// XXX
function void tlx_afu_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)

    if(!uvm_config_db#(virtual tlx_afu_interface)::get(this, "", "tlx_afu_vif", tlx_afu_vif)) begin
        `uvm_fatal(tID, "No virtual interface specified fo tlx_afu_monitor")
    end
    if(!uvm_config_db#(virtual intrp_interface)::get(this, "", "intrp_vif", intrp_vif)) begin
        `uvm_fatal(tID, "No virtual interface of interrupt specified fo tlx_afu_monitor")
    end
endfunction : connect_phase

function void tlx_afu_monitor::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)

endfunction : start_of_simulation_phase
// Task: run_phase
// XXX
task tlx_afu_monitor::run_phase(uvm_phase phase);

    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)

endtask : run_phase

// Task: main_phase
// XXX
task tlx_afu_monitor::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    fork
        collect_afu_tlx_cmd();
        collect_afu_tlx_resp();
        collect_tlx_afu_cmd();
        collect_tlx_afu_resp();
        collect_interrupt();
    join
endtask : main_phase

// Task: shutdown_phase
// XXX
task tlx_afu_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase

// Collect afu tlx command and data
task tlx_afu_monitor::collect_interrupt();
    typedef enum bit[1:0] { INTRP_IDLE, INTRP_WAIT_ACK, INTRP_FINISH } intrp_status;
    intrp_status intrp_status_item;
    `uvm_info(tID, $sformatf("Collect_interrupt begin ..."), UVM_MEDIUM)
    intrp_status_item = INTRP_IDLE;
    forever begin
        @(posedge intrp_vif.action_clock);
        if(intrp_vif.action_rst_n == 0)begin
            break;
        end
    end
    forever begin
        intrp_trans = new("intrp_trans");
        @(posedge intrp_vif.action_clock)
        if(intrp_status_item == INTRP_IDLE)begin
            if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 0))begin
                intrp_status_item = INTRP_WAIT_ACK;
                intrp_trans.intrp_item=intrp_transaction::INTRP_REQ;
                intrp_trans.intrp_src=intrp_vif.intrp_src;
                intrp_trans.intrp_ctx=intrp_vif.intrp_ctx;
                intrp_tran_port.write(intrp_trans);                
            end
            else if((intrp_vif.intrp_req == 0) && (intrp_vif.intrp_ack == 0))begin
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_IDLE statsu.")
            end
        end
        else if(intrp_status_item == INTRP_WAIT_ACK)begin
            if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 1))begin
                intrp_status_item = INTRP_FINISH;
                intrp_trans.intrp_item=intrp_transaction::INTRP_ACK;
                intrp_trans.intrp_src=intrp_vif.intrp_src;
                intrp_trans.intrp_ctx=intrp_vif.intrp_ctx;
                intrp_tran_port.write(intrp_trans);                
            end
            else if((intrp_vif.intrp_req == 1) && (intrp_vif.intrp_ack == 0))begin
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_WAIT_ACK statsu.")
            end
        end
        else begin
            if((intrp_vif.intrp_req == 0) && (intrp_vif.intrp_ack == 1))begin
                intrp_status_item = INTRP_IDLE;
            end
            else begin
                `uvm_error(get_type_name(), "Get illegal interrupt signals in INTRP_FINISH statsu.")
            end
        end
    end
endtask : collect_interrupt

// Collect afu tlx command and data
task tlx_afu_monitor::collect_afu_tlx_cmd();
    `uvm_info(tID, $sformatf("Collect_afu_tlx_cmd begin ..."), UVM_MEDIUM)
    forever begin
        afu_tlx_cmd_trans = new("afu_tlx_cmd_trans");
        @(tlx_afu_vif.afu_clock)
        if(tlx_afu_vif.afu_tlx_cmd_valid_top == 1) begin
            afu_tlx_cmd_trans.afu_tlx_opcode = tlx_afu_vif.afu_tlx_cmd_opcode_top;
            afu_tlx_cmd_trans.afu_tlx_afutag = tlx_afu_vif.afu_tlx_cmd_afutag_top;
            afu_tlx_cmd_trans.afu_tlx_addr = tlx_afu_vif.afu_tlx_cmd_ea_or_obj_top;
            afu_tlx_cmd_trans.afu_tlx_dl = tlx_afu_vif.afu_tlx_cmd_dl_top;
            afu_tlx_cmd_trans.afu_tlx_pl = tlx_afu_vif.afu_tlx_cmd_pl_top;
            afu_tlx_cmd_trans.afu_tlx_be = tlx_afu_vif.afu_tlx_cmd_be_top;
            afu_tlx_cmd_trans.afu_tlx_actag = tlx_afu_vif.afu_tlx_cmd_actag_top;
            afu_tlx_cmd_trans.afu_tlx_stream_id = tlx_afu_vif.afu_tlx_cmd_stream_id_top;
            afu_tlx_cmd_trans.afu_tlx_bdf = tlx_afu_vif.afu_tlx_cmd_bdf_top;
            afu_tlx_cmd_trans.afu_tlx_pasid = tlx_afu_vif.afu_tlx_cmd_pasid_top;
            afu_tlx_cmd_trans.afu_tlx_pg_size = tlx_afu_vif.afu_tlx_cmd_pg_size_top;
            afu_tlx_cmd_trans.afu_tlx_type = get_afu_tlx_type(afu_tlx_cmd_trans.afu_tlx_opcode);
            afu_tlx_cmd_trans_q.push_back(afu_tlx_cmd_trans);
            afu_tlx_cmd_num++;
        end
        if(tlx_afu_vif.afu_tlx_cdata_valid_top == 1) begin
            afu_tlx_cmd_data_q.push_back({tlx_afu_vif.afu_tlx_cdata_bdi_top, tlx_afu_vif.afu_tlx_cdata_bus_top});
        end
        if(afu_tlx_cmd_trans_q.size > 0)
            pack_afu_tlx_cmd();
    end
endtask : collect_afu_tlx_cmd

// Collect afu tlx response and data
task tlx_afu_monitor::collect_afu_tlx_resp();
    `uvm_info(tID, $sformatf("Collect_afu_tlx_resp begin ..."), UVM_MEDIUM)
    forever begin
        afu_tlx_resp_trans = new("afu_tlx_resp_trans");
        @(tlx_afu_vif.afu_clock)
        if(tlx_afu_vif.afu_tlx_resp_valid_top == 1) begin
            afu_tlx_resp_trans.afu_tlx_opcode = tlx_afu_vif.afu_tlx_resp_opcode_top;
            afu_tlx_resp_trans.afu_tlx_capptag = tlx_afu_vif.afu_tlx_resp_capptag_top;
            afu_tlx_resp_trans.afu_tlx_dl = tlx_afu_vif.afu_tlx_resp_dl_top;
            afu_tlx_resp_trans.afu_tlx_dp = tlx_afu_vif.afu_tlx_resp_dp_top;
            afu_tlx_resp_trans.afu_tlx_resp_code = tlx_afu_vif.afu_tlx_resp_code_top;
            afu_tlx_resp_trans.afu_tlx_type = get_afu_tlx_type(afu_tlx_resp_trans.afu_tlx_opcode);
            afu_tlx_resp_trans_q.push_back(afu_tlx_resp_trans);
            afu_tlx_resp_num++;
        end
        if(tlx_afu_vif.afu_tlx_rdata_valid_top == 1) begin
            afu_tlx_resp_data_q.push_back({tlx_afu_vif.afu_tlx_rdata_bdi_top, tlx_afu_vif.afu_tlx_rdata_bus_top});
        end
        if(afu_tlx_resp_trans_q.size > 0)
            pack_afu_tlx_resp();
    end
endtask : collect_afu_tlx_resp

// Collect tlx afu command and data
task tlx_afu_monitor::collect_tlx_afu_cmd();
    `uvm_info(tID, $sformatf("Collect_tlx_afu_cmd begin ..."), UVM_MEDIUM)
    forever begin
        tlx_afu_cmd_trans = new("tlx_afu_cmd_trans");
        @(posedge tlx_afu_vif.tlx_clock)
        if(tlx_afu_vif.tlx_afu_cmd_valid_top == 1) begin
            tlx_afu_cmd_trans.tlx_afu_opcode = tlx_afu_vif.tlx_afu_cmd_opcode_top;
            tlx_afu_cmd_trans.tlx_afu_capptag = tlx_afu_vif.tlx_afu_cmd_capptag_top;
            tlx_afu_cmd_trans.tlx_afu_addr = tlx_afu_vif.tlx_afu_cmd_pa_top;
            tlx_afu_cmd_trans.tlx_afu_dl = tlx_afu_vif.tlx_afu_cmd_dl_top;
            tlx_afu_cmd_trans.tlx_afu_pl = tlx_afu_vif.tlx_afu_cmd_pl_top;
            tlx_afu_cmd_trans.tlx_afu_be = tlx_afu_vif.tlx_afu_cmd_be_top;
            tlx_afu_cmd_trans.tlx_afu_type = get_tlx_afu_type(tlx_afu_cmd_trans.tlx_afu_opcode);
            tlx_afu_cmd_trans_q.push_back(tlx_afu_cmd_trans);
            tlx_afu_cmd_num++;
        end
        if(tlx_afu_vif.tlx_afu_cmd_data_valid_top == 1) begin
            tlx_afu_cmd_data_q.push_back({tlx_afu_vif.tlx_afu_cmd_data_bdi_top, tlx_afu_vif.tlx_afu_cmd_data_bus_top});
        end
        if(tlx_afu_cmd_trans_q.size > 0)
            pack_tlx_afu_cmd();
    end
endtask : collect_tlx_afu_cmd

// Collect tlx afu response and data
task tlx_afu_monitor::collect_tlx_afu_resp();
    `uvm_info(tID, $sformatf("Collect_tlx_afu_resp begin ..."), UVM_MEDIUM)
    forever begin
        tlx_afu_resp_trans = new("tlx_afu_resp_trans");
        @(posedge tlx_afu_vif.tlx_clock)
        if(tlx_afu_vif.tlx_afu_resp_valid_top == 1) begin
            tlx_afu_resp_trans.tlx_afu_opcode = tlx_afu_vif.tlx_afu_resp_opcode_top;
            tlx_afu_resp_trans.tlx_afu_afutag = tlx_afu_vif.tlx_afu_resp_afutag_top;
            tlx_afu_resp_trans.tlx_afu_dl = tlx_afu_vif.tlx_afu_resp_dl_top;
            tlx_afu_resp_trans.tlx_afu_dp = tlx_afu_vif.tlx_afu_resp_dp_top;
            tlx_afu_resp_trans.tlx_afu_resp_code = tlx_afu_vif.tlx_afu_resp_code_top;
            tlx_afu_resp_trans.tlx_afu_pg_size = tlx_afu_vif.tlx_afu_resp_pg_size_top;
            tlx_afu_resp_trans.tlx_afu_resp_host_tag = tlx_afu_vif.tlx_afu_resp_host_tag_top;
            tlx_afu_resp_trans.tlx_afu_resp_addr_tag = tlx_afu_vif.tlx_afu_resp_addr_tag_top;
            tlx_afu_resp_trans.tlx_afu_resp_cache_state = tlx_afu_vif.tlx_afu_resp_cache_state_top;
            tlx_afu_resp_trans.tlx_afu_type = get_tlx_afu_type(tlx_afu_resp_trans.tlx_afu_opcode);
            tlx_afu_resp_trans_q.push_back(tlx_afu_resp_trans);
            tlx_afu_resp_num++;
        end
        if(tlx_afu_vif.tlx_afu_resp_data_valid_top == 1)
            tlx_afu_resp_data_q.push_back({tlx_afu_vif.tlx_afu_resp_data_bdi_top, tlx_afu_vif.tlx_afu_resp_data_bus_top});
        if(tlx_afu_resp_trans_q.size > 0)
            pack_tlx_afu_resp();
    end
endtask : collect_tlx_afu_resp

// Pack afu tlx command with data
function void tlx_afu_monitor::pack_afu_tlx_cmd();
    if(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_N) begin
        if(afu_tlx_cmd_data_q.size >= dl2dl_num(afu_tlx_cmd_trans_q[0].afu_tlx_dl)) begin
            for(int i=0; i<dl2dl_num(afu_tlx_cmd_trans_q[0].afu_tlx_dl); i++) begin
                afu_tlx_cmd_trans_q[0].afu_tlx_data_bus[i] = afu_tlx_cmd_data_q[0][511:0];
                afu_tlx_cmd_trans_q[0].afu_tlx_data_bdi[i] = afu_tlx_cmd_data_q[0][512];
                afu_tlx_cmd_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect an afu-tlx command and data.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
        end
    end
    else if(afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_BE || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_W_BE_N ||
            afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W || afu_tlx_cmd_trans_q[0].afu_tlx_type == afu_tlx_transaction::DMA_PR_W) begin
        if(afu_tlx_cmd_data_q.size > 0) begin
            afu_tlx_cmd_trans_q[0].afu_tlx_data_bus[0] = afu_tlx_cmd_data_q[0][511:0];
            afu_tlx_cmd_trans_q[0].afu_tlx_data_bdi[0] = afu_tlx_cmd_data_q[0][512];
            afu_tlx_cmd_data_q.pop_front();                        
            `uvm_info(tID, $sformatf("Collect an afu-tlx command and data.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect an afu-tlx command.\n%s", afu_tlx_cmd_trans_q[0].sprint()), UVM_MEDIUM);
        afu_tlx_tran_port.write(afu_tlx_cmd_trans_q.pop_front());
    end
endfunction : pack_afu_tlx_cmd

// Pack afu tlx response with data
function void tlx_afu_monitor::pack_afu_tlx_resp();
    if(afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE) begin
        if(afu_tlx_resp_data_q.size >= dl2dl_num(afu_tlx_resp_trans_q[0].afu_tlx_dl)) begin
            for(int i=0; i<dl2dl_num(afu_tlx_resp_trans_q[0].afu_tlx_dl); i++) begin
                afu_tlx_resp_trans_q[0].afu_tlx_data_bus[i] = afu_tlx_resp_data_q[0][511:0];
                afu_tlx_resp_trans_q[0].afu_tlx_data_bdi[i] = afu_tlx_resp_data_q[0][512];
                afu_tlx_resp_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect a afu-tlx response and data.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
        end
    end
    else if((afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE_OW) || (afu_tlx_resp_trans_q[0].afu_tlx_type == afu_tlx_transaction::MEM_RD_RESPONSE_XW)) begin
        if(afu_tlx_resp_data_q.size > 0) begin
            afu_tlx_resp_trans_q[0].afu_tlx_data_bus[0] = afu_tlx_resp_data_q[0][511:0];
            afu_tlx_resp_trans_q[0].afu_tlx_data_bdi[0] = afu_tlx_resp_data_q[0][512];
            afu_tlx_resp_data_q.pop_front();
            `uvm_info(tID, $sformatf("Collect a afu-tlx response and data.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
            afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect a afu-tlx response.\n%s", afu_tlx_resp_trans_q[0].sprint()), UVM_MEDIUM);
        afu_tlx_tran_port.write(afu_tlx_resp_trans_q.pop_front());
    end
endfunction : pack_afu_tlx_resp

// Pack tlx afu command with data
function void tlx_afu_monitor::pack_tlx_afu_cmd();
    if(tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::WRITE_MEM) begin
        if(tlx_afu_cmd_data_q.size >= dl2dl_num(tlx_afu_cmd_trans_q[0].tlx_afu_dl)) begin
            for(int i=0; i<dl2dl_num(tlx_afu_cmd_trans_q[0].tlx_afu_dl); i++) begin
                tlx_afu_cmd_trans_q[0].tlx_afu_data_bus[i] = tlx_afu_cmd_data_q[0][511:0];
                tlx_afu_cmd_trans_q[0].tlx_afu_data_bdi[i] = tlx_afu_cmd_data_q[0][512];
                tlx_afu_cmd_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect an tlx-afu command and data.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
        end
    end
    else if(tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::WRITE_MEM_BE || tlx_afu_cmd_trans_q[0].tlx_afu_type == tlx_afu_transaction::PR_WR_MEM) begin
        if(tlx_afu_cmd_data_q.size > 0) begin
            tlx_afu_cmd_trans_q[0].tlx_afu_data_bus[0] = tlx_afu_cmd_data_q[0][511:0];
            tlx_afu_cmd_trans_q[0].tlx_afu_data_bdi[0] = tlx_afu_cmd_data_q[0][512];
            `uvm_info(tID, $sformatf("Collect an tlx-afu command and data.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
            tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect an tlx-afu command.\n%s", tlx_afu_cmd_trans_q[0].sprint()), UVM_MEDIUM);
        //tlx_afu_cmd_trans_q.pop_front();
        tlx_afu_tran_port.write(tlx_afu_cmd_trans_q.pop_front());
    end
endfunction : pack_tlx_afu_cmd

// Pack tlx afu response with data
function void tlx_afu_monitor::pack_tlx_afu_resp();
    if(tlx_afu_resp_trans_q[0].tlx_afu_type == tlx_afu_transaction::READ_RESPONSE) begin
        if(tlx_afu_resp_data_q.size >= dl2dl_num(tlx_afu_resp_trans_q[0].tlx_afu_dl)) begin
            for(int i=0; i<dl2dl_num(tlx_afu_resp_trans_q[0].tlx_afu_dl); i++) begin
                tlx_afu_resp_trans_q[0].tlx_afu_data_bus[i] = tlx_afu_resp_data_q[0][511:0];
                tlx_afu_resp_trans_q[0].tlx_afu_data_bdi[i] = tlx_afu_resp_data_q[0][512];
                tlx_afu_resp_data_q.pop_front();
            end
            `uvm_info(tID, $sformatf("Collect a tlx-afu response and data.\n%s", tlx_afu_resp_trans_q[0].sprint()), UVM_MEDIUM);
            tlx_afu_tran_port.write(tlx_afu_resp_trans_q.pop_front());
        end
    end
    else begin
        `uvm_info(tID, $sformatf("Collect a tlx-afu response.\n%s", tlx_afu_resp_trans_q[0].sprint()), UVM_MEDIUM);
        tlx_afu_tran_port.write(tlx_afu_resp_trans_q.pop_front());
    end
endfunction : pack_tlx_afu_resp

// Get afu tlx command/response type
function afu_tlx_transaction::afu_tlx_enum tlx_afu_monitor::get_afu_tlx_type(bit[7:0] afu_tlx_opcode);
    case(afu_tlx_opcode)
        8'b0000_0001: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE;
        8'b0000_0010: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_FAIL;
        8'b0000_0011: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE_OW;
        8'b0000_0100: get_afu_tlx_type = afu_tlx_transaction::MEM_WR_RESPONSE;
        8'b0000_0101: get_afu_tlx_type = afu_tlx_transaction::MEM_WR_FAIL;
        8'b0000_0111: get_afu_tlx_type = afu_tlx_transaction::MEM_RD_RESPONSE_XW;
        8'b0001_0000: get_afu_tlx_type = afu_tlx_transaction::RD_WNITC;
        8'b0001_0010: get_afu_tlx_type = afu_tlx_transaction::PR_RD_WNITC;
        8'b0001_0100: get_afu_tlx_type = afu_tlx_transaction::RD_WNITC_N;
        8'b0001_0110: get_afu_tlx_type = afu_tlx_transaction::PR_RD_WNITC_N;
        8'b0010_0000: get_afu_tlx_type = afu_tlx_transaction::DMA_W;
        8'b0010_0100: get_afu_tlx_type = afu_tlx_transaction::DMA_W_N;
        8'b0010_1000: get_afu_tlx_type = afu_tlx_transaction::DMA_W_BE;
        8'b0010_1100: get_afu_tlx_type = afu_tlx_transaction::DMA_W_BE_N;
        8'b0011_0000: get_afu_tlx_type = afu_tlx_transaction::DMA_PR_W;
        8'b0011_0100: get_afu_tlx_type = afu_tlx_transaction::DMA_PR_W_N;
        8'b0101_0000: get_afu_tlx_type = afu_tlx_transaction::ASSIGN_ACTAG;
        8'b0101_1000: get_afu_tlx_type = afu_tlx_transaction::INTRP_REQ;
        8'b0101_1010: get_afu_tlx_type = afu_tlx_transaction::INTRP_REQ_D;
        8'b0101_1100: get_afu_tlx_type = afu_tlx_transaction::WAKE_HOST_THREAD;
        8'b0111_1000: get_afu_tlx_type = afu_tlx_transaction::XLATE_TOUCH;
        8'b0111_1100: get_afu_tlx_type = afu_tlx_transaction:: XLATE_TOUCH_N;
        default: `uvm_error(get_type_name(), "Get an illegal afu tlx opcode!")
    endcase
endfunction : get_afu_tlx_type

// Get tlx afu command/response type
function tlx_afu_transaction::tlx_afu_enum tlx_afu_monitor::get_tlx_afu_type(bit[7:0] tlx_afu_opcode);
    case(tlx_afu_opcode)
        8'b0000_0010: get_tlx_afu_type = tlx_afu_transaction::TOUCH_RESP;
        8'b0000_0100: get_tlx_afu_type = tlx_afu_transaction::READ_RESPONSE;
        8'b0000_0101: get_tlx_afu_type = tlx_afu_transaction::READ_FAILED;
        8'b0000_1000: get_tlx_afu_type = tlx_afu_transaction::WRITE_RESPONSE;
        8'b0000_1001: get_tlx_afu_type = tlx_afu_transaction::WRITE_FAILED;
        8'b0000_1100: get_tlx_afu_type = tlx_afu_transaction::INTRP_RESP;
        8'b0001_0000: get_tlx_afu_type = tlx_afu_transaction::WAKE_HOST_RESP;
        8'b0001_1000: get_tlx_afu_type = tlx_afu_transaction::XLATE_DONE;
        8'b0001_1010: get_tlx_afu_type = tlx_afu_transaction::INTRP_RDY;
        8'b0010_0000: get_tlx_afu_type = tlx_afu_transaction::RD_MEM;
        8'b0010_1000: get_tlx_afu_type = tlx_afu_transaction::PR_RD_MEM;
        8'b1000_0001: get_tlx_afu_type = tlx_afu_transaction::WRITE_MEM;
        8'b1000_0110: get_tlx_afu_type = tlx_afu_transaction::PR_WR_MEM;
        8'b1000_0010: get_tlx_afu_type = tlx_afu_transaction::WRITE_MEM_BE;
        default: `uvm_error(get_type_name(), "Get an illegal tlx afu opcode!")
    endcase
endfunction : get_tlx_afu_type

function int tlx_afu_monitor::dl2dl_num(bit[1:0] dl);
    case(dl)
        2'b01: dl2dl_num = 1;
        2'b10: dl2dl_num = 2;
        2'b11: dl2dl_num = 4;
        default: `uvm_error(get_type_name(), "Get an illegal data length!")
    endcase
endfunction : dl2dl_num

`endif // _TLX_AFU_MONITOR_SV_
