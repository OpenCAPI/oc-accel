`ifndef _AXI_MM_MONITOR_SV_
`define _AXI_MM_MONITOR_SV_

//-------------------------------------------------------------------------------------
//
// CLASS: axi_mm_monitor
//
// XXX
//-------------------------------------------------------------------------------------

class axi_mm_monitor extends uvm_monitor;

    virtual interface                          axi_vip_if `AXI_VIP_MM_CHECK_PARAMS mm_check_vif;
    axi_vip_mm_check_passthrough_t             axi_vip_mm_check_passthrough;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_tran_port;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_cmd_rd_port;
    uvm_analysis_port #(axi_mm_transaction)    axi_mm_cmd_wr_port;

    string                                     tID;
    int                                        rd_num;
    int                                        wr_num;
    int                                        cmd_wr_num;
    int                                        cmd_rd_num;
    int                                        void_num;
    bit [31:0]                                 data_size;
    axi_monitor_transaction                    axi_monitor_trans;
    xil_axi_cmd_beat                           axi_wr_trans;
    xil_axi_cmd_beat                           axi_rd_trans;
    axi_mm_transaction                         txn;
    axi_mm_transaction                         txn_rd;
    axi_mm_transaction                         txn_wr;

    //------------------------CONFIGURATION PARAMETERS--------------------------------
    // AXI_MONITOR Configuration Parameters. These parameters can be controlled through
    // the UVM configuration database
    // @{

    // Trace player has three work modes for different usages:
    // CMOD_ONLY:   only cmod is working
    // RTL_ONLY:    only DUT rtl is working
    // CROSS_CHECK: default verfication mode, cross check between RTL and CMOD
    string                      work_mode = "CROSS_CHECK";
    //event                       action_tb_finish;

    // }@

    `uvm_component_utils_begin(axi_mm_monitor)
        `uvm_field_string(work_mode, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name = "axi_mm_monitor", uvm_component parent = null);

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
    extern function void check_phase(uvm_phase phase);
    //extern function void report_phase(uvm_phase phase);
    //extern function void final_phase(uvm_phase phase);
    extern function void check_transactions_inflight();
    // }@
    extern task collect_transactions();
    extern task collect_cmd_rd();
    extern task collect_cmd_wr();

endclass : axi_mm_monitor

// Function: new
// Creates a new dbb check monitor
function axi_mm_monitor::new(string name = "axi_mm_monitor", uvm_component parent = null);
    super.new(name, parent);
    tID = get_type_name();
    axi_mm_tran_port = new("axi_mm_tran_port", this);
    axi_mm_cmd_rd_port = new("axi_mm_cmd_rd_port", this);
    axi_mm_cmd_wr_port = new("axi_mm_cmd_wr_port", this);
    wr_num = 0;
    rd_num = 0;
    void_num = 0;
endfunction : new

// Function: build_phase
// XXX
function void axi_mm_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(tID, $sformatf("build_phase begin ..."), UVM_MEDIUM)
endfunction : build_phase

// Function: connect_phase
// XXX
function void axi_mm_monitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(tID, $sformatf("connect_phase begin ..."), UVM_MEDIUM)
    if(!uvm_config_db#(virtual axi_vip_if `AXI_VIP_MM_CHECK_PARAMS)::get(this, "", "mm_check_vif", mm_check_vif)) begin
        `uvm_fatal(tID, "No virtual interface mm_check_vif specified fo axi_mm_monitor")
    end
    axi_vip_mm_check_passthrough = new("axi_vip_mm_check_passthrough", mm_check_vif);
    endfunction : connect_phase

function void axi_mm_monitor::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(tID, $sformatf("start_of_simulation_phase begin ..."), UVM_MEDIUM)

endfunction : start_of_simulation_phase
// Task: main_phase
// XXX
task axi_mm_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(tID, $sformatf("run_phase begin ..."), UVM_MEDIUM)

endtask : run_phase

// Task: main_phase
// XXX
task axi_mm_monitor::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info(tID, $sformatf("main_phase begin ..."), UVM_MEDIUM)
    //axi_vip_mm_check_passthrough.start_master();
    //axi_vip_mm_check_passthrough.start_slave();
    axi_vip_mm_check_passthrough.start_monitor();
    axi_vip_mm_check_passthrough.monitor.axi_rd_cmd_port.set_enabled();
    axi_vip_mm_check_passthrough.monitor.axi_wr_cmd_port.set_enabled();
    fork
        collect_transactions();
        collect_cmd_rd();
        collect_cmd_wr();
    join
endtask : main_phase

task axi_mm_monitor::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    `uvm_info(tID, $sformatf("shutdown_phase begin ..."), UVM_MEDIUM)
endtask : shutdown_phase

function void axi_mm_monitor::check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(tID, $sformatf("check_phase begin ..."), UVM_MEDIUM)
    `uvm_info(tID, $sformatf("DBB Monitor Detects %0d axi-read and %0d of that have finished.", cmd_rd_num, rd_num), UVM_MEDIUM)
    `uvm_info(tID, $sformatf("DBB Monitor Detects %0d axi-write and %0d of that have finished.", cmd_wr_num, wr_num), UVM_MEDIUM)
    check_transactions_inflight();
endfunction : check_phase

task axi_mm_monitor::collect_transactions();
    `uvm_info(tID, $sformatf("dbb check collect_transactions begin ..."), UVM_MEDIUM)
    axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_monitor_trans=new("axi_monitor_trans");
        txn=new();
        data_size = 32'b1;
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.item_collected_port.get(axi_monitor_trans);
        if(axi_monitor_trans.get_cmd_type()== XIL_AXI_READ) begin
            rd_num ++;
            txn.trans=axi_mm_transaction::READ;
            txn.addr=axi_monitor_trans.get_addr();
            txn.burst_length=axi_monitor_trans.get_len()+1;
            for(int i=0; i<txn.burst_length; i++) begin
                txn.data[i]=axi_monitor_trans.get_data_beat(i);
            end
            txn.byte_size=(data_size << axi_monitor_trans.get_size());
            txn.axi_id=axi_monitor_trans.get_id();
            //TODO: Get usr from axi_monitor_trans
            //txn.axi_usr=axi_monitor_trans.get_user();
            `uvm_info(tID, $sformatf("DBB Monitor Detects a Read:\n%s", txn.sprint()), UVM_MEDIUM);
            axi_mm_tran_port.write(txn);
        end
        else if(axi_monitor_trans.get_cmd_type()==XIL_AXI_WRITE) begin
            wr_num ++;
            txn.trans=axi_mm_transaction::WRITE;
            txn.addr=axi_monitor_trans.get_addr();
            txn.burst_length=axi_monitor_trans.get_len()+1;
            for(int i=0; i<txn.burst_length; i++) begin
                txn.data[i]=axi_monitor_trans.get_data_beat(i);
                txn.data_strobe[i]=axi_monitor_trans.get_strb_beat(i);
            end
            txn.byte_size=(data_size << axi_monitor_trans.get_size());
            txn.axi_id=axi_monitor_trans.get_id();
            //TODO: Get usr from axi_monitor_trans
            //txn.axi_usr=axi_monitor_trans.get_user();
            `uvm_info(tID, $sformatf("DBB Monitor Detects a Write:\n%s", txn.sprint()), UVM_MEDIUM);
            axi_mm_tran_port.write(txn);
        end
        else begin
            `uvm_info(tID, $sformatf("DBB monitor detects nothing"), UVM_MEDIUM)
            void_num ++;
        end
    end
endtask : collect_transactions

task axi_mm_monitor::collect_cmd_rd();
    `uvm_info(tID, $sformatf("dbb check collect_cmd_rd begin ..."), UVM_MEDIUM)
    axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
    forever begin
        axi_rd_trans=new("axi_rd_trans");
        txn_rd=new();
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.axi_rd_cmd_port.get(axi_rd_trans);
        `uvm_info(this.get_type_name(), axi_rd_trans.convert2string(), UVM_MEDIUM)        
        txn_rd.trans=axi_mm_transaction::READ;
        txn_rd.addr=axi_rd_trans.addr;
        txn_rd.burst_length=axi_rd_trans.len+1;
        txn_rd.byte_size=(32'b1 << axi_rd_trans.size);
        txn_rd.axi_id=axi_rd_trans.id;
        //txn_rd.axi_usr=axi_rd_trans.get_user();
        `uvm_info(tID, $sformatf("DBB Monitor Detects a AXI Read Cmd:"), UVM_MEDIUM);
        //`uvm_info(tID, axi_rd_trans.convert2string(), UVM_MEDIUM)
        axi_mm_cmd_rd_port.write(txn_rd);
        cmd_rd_num ++;
    end
endtask : collect_cmd_rd

task axi_mm_monitor::collect_cmd_wr();
    `uvm_info(tID, $sformatf("dbb check collect_cmd_wr begin ..."), UVM_MEDIUM)
    forever begin
        axi_wr_trans=new("axi_wr_trans");
        txn_wr=new();
        //Turn off current monitor transaction depth check
        axi_vip_mm_check_passthrough.monitor.disable_transaction_depth_checks();
        axi_vip_mm_check_passthrough.monitor.axi_wr_cmd_port.get(axi_wr_trans);
        `uvm_info(this.get_type_name(), axi_wr_trans.convert2string(), UVM_MEDIUM)        
        txn_wr.trans=axi_mm_transaction::WRITE;
        txn_wr.addr=axi_wr_trans.addr;
        txn_wr.burst_length=axi_wr_trans.len+1;
        txn_wr.byte_size=(32'b1 << axi_wr_trans.size);
        txn_wr.axi_id=axi_wr_trans.id;
        //txn_wr.axi_usr=axi_wr_trans.get_user();
        `uvm_info(tID, $sformatf("DBB Monitor Detects a AXI Write Cmd:"), UVM_MEDIUM);
        //`uvm_info(tID, axi_wr_trans.convert2string(), UVM_MEDIUM)
        axi_mm_cmd_wr_port.write(txn_wr);
        cmd_wr_num ++;
    end
endtask : collect_cmd_wr

function void axi_mm_monitor::check_transactions_inflight();
    int read_inflight_num;
    int write_inflight_num;
    read_inflight_num = axi_vip_mm_check_passthrough.monitor.get_num_rd_transactions_inflight();
    write_inflight_num = axi_vip_mm_check_passthrough.monitor.get_num_wr_transactions_inflight();
    if(read_inflight_num > 0) begin
         `uvm_error(tID, $sformatf("There are %d axi-read transctions in flight!", read_inflight_num))
    end
    if(write_inflight_num > 0) begin
         `uvm_error(tID, $sformatf("There are %d axi-write transctions in flight!", write_inflight_num))
    end

endfunction : check_transactions_inflight

`endif // _AXI_MONITOR_SV_
