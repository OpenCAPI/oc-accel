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
`timescale 1ns/1ps

//UVM ENV
import uvm_pkg::*;
`include "uvm_macros.svh"

//AXI VIP PKG
import axi_vip_pkg::*;
import axi_vip_master_pkg::*;

module snap_action_shim #(
    // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
    parameter C_M_AXI_CARD_MEM0_ID_WIDTH     = 2,
    parameter C_M_AXI_CARD_MEM0_ADDR_WIDTH   = 33,
    parameter C_M_AXI_CARD_MEM0_DATA_WIDTH   = 1024,
    parameter C_M_AXI_CARD_MEM0_AWUSER_WIDTH = 8,
    parameter C_M_AXI_CARD_MEM0_ARUSER_WIDTH = 8,
    parameter C_M_AXI_CARD_MEM0_WUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_RUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_BUSER_WIDTH  = 1,

    // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
    parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,

    // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    parameter C_M_AXI_HOST_MEM_ID_WIDTH      = 2,
    parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
    parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = 1024,
    parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1,
    parameter C_PATTERN_WIDTH = 1744,
    parameter SOURCE_BITS                    = 64,
    parameter CONTEXT_BITS                   = 9
)(
    input              clk                      ,
    input              rst_n                    ,


    //---- AXI bus interfaced with SNAP core ----
      // AXI write address channel
    output reg   [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_awid          ,
    output reg   [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_snap_awaddr        ,
    output reg   [0007:0] m_axi_snap_awlen         ,
    output reg   [0002:0] m_axi_snap_awsize        ,
    output reg   [0001:0] m_axi_snap_awburst       ,
    output reg   [0003:0] m_axi_snap_awcache       ,
    output reg   [0001:0] m_axi_snap_awlock        ,
    output reg   [0002:0] m_axi_snap_awprot        ,
    output reg   [0003:0] m_axi_snap_awqos         ,
    output reg   [0003:0] m_axi_snap_awregion      ,
    output reg   [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0] m_axi_snap_awuser        ,
    output reg            m_axi_snap_awvalid       ,
    input              m_axi_snap_awready       ,
      // AXI write data channel
    output reg   [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_wid           ,
    output reg   [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_snap_wdata         ,
    output reg   [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) - 1:0] m_axi_snap_wstrb         ,
    output reg            m_axi_snap_wlast         ,
    output reg            m_axi_snap_wvalid        ,
    input              m_axi_snap_wready        ,
      // AXI write response channel
    output reg            m_axi_snap_bready        ,
    input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_bid           ,
    input     [0001:0] m_axi_snap_bresp         ,
    input              m_axi_snap_bvalid        ,
      // AXI read address channel
    output reg  [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_arid          ,
    output reg  [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_snap_araddr        ,
    output reg  [0007:0] m_axi_snap_arlen         ,
    output reg  [0002:0] m_axi_snap_arsize        ,
    output reg  [0001:0] m_axi_snap_arburst       ,
    output reg  [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_snap_aruser        ,
    output reg  [0003:0] m_axi_snap_arcache       ,
    output reg  [0001:0] m_axi_snap_arlock        ,
    output reg  [0002:0] m_axi_snap_arprot        ,
    output reg  [0003:0] m_axi_snap_arqos         ,
    output reg  [0003:0] m_axi_snap_arregion      ,
    output reg           m_axi_snap_arvalid       ,
    input              m_axi_snap_arready       ,
      // AXI read data channel
    output reg           m_axi_snap_rready        ,
    input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_rid           ,
    input     [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_snap_rdata         ,
    input     [0001:0] m_axi_snap_rresp         ,
    input              m_axi_snap_rlast         ,
    input              m_axi_snap_rvalid        ,

    //---- AXI Lite bus interfaced with SNAP core ----
      // AXI write address channel
    output             s_axi_snap_awready       ,
    input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_snap_awaddr        ,
    input     [0002:0] s_axi_snap_awprot        ,
    input              s_axi_snap_awvalid       ,
      // axi write data channel
    output             s_axi_snap_wready        ,
    input     [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_snap_wdata         ,
    input     [(C_S_AXI_CTRL_REG_DATA_WIDTH/8) - 1:0] s_axi_snap_wstrb         ,
    input              s_axi_snap_wvalid        ,
      // AXI response channel
    output    [0001:0] s_axi_snap_bresp         ,
    output             s_axi_snap_bvalid        ,
    input              s_axi_snap_bready        ,
      // AXI read address channel
    output             s_axi_snap_arready       ,
    input              s_axi_snap_arvalid       ,
    input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_snap_araddr        ,
    input     [0002:0] s_axi_snap_arprot        ,
      // AXI read data channel
    output    [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_snap_rdata         ,
    output    [0001:0] s_axi_snap_rresp         ,
    input              s_axi_snap_rready        ,
    output             s_axi_snap_rvalid        ,

    // Other signals
    input              i_app_ready              ,
    input      [31:0]  i_action_type            ,
    input      [31:0]  i_action_version         ,
    output             interrupt                ,
    output [SOURCE_BITS-1  : 0] interrupt_src             ,
    output [CONTEXT_BITS-1 : 0] interrupt_ctx             ,
    input              interrupt_ack
                       );
//Internal signals
bit[31:0] source_addr_q[longint unsigned];
bit[31:0] target_addr_q[longint unsigned];
class axi_addr_rand;
    bit[31:0] rand_source_addr;
    bit[31:0] rand_target_addr;

    //constraint rand_addr_valid{
    //rand_source_addr inside {source_addr_q};
    //rand_target_addr inside {target_addr_q};    
    //}
endclass:axi_addr_rand
//For interrupt
bit rd_req_q[$];
bit wr_req_q[$];
bit intrp_req_q[$];

axi_addr_rand axi_addr_rand_item;

// AXI-Lite config signals
wire[000:0] memcpy_enable;
wire[063:0] source_address;
wire[063:0] target_address;
wire[063:0] source_size;
wire[063:0] target_size;
wire[031:0] read_number;
wire[031:0] read_rand_patt;
wire[031:0] write_number;
wire[031:0] write_rand_patt;
wire[031:0] input_seed;
wire[031:0] interrupt_patt;
reg [000:0] memcpy_done;

wire[031:0] snap_context;
reg interrupt;
reg [63:0]interrupt_src;
reg [8:0]interrupt_ctx;

//----------------------------------------------------------------------------------------------
//---- registers hub for AXI Lite interface ----
//----------------------------------------------------------------------------------------------

axi_lite_slave #(
           .DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   )
) maxi_lite_slave (
                                .clk                   (clk                   ),
                                .rst_n                 (rst_n                 ),
                                .s_axi_awready         (s_axi_snap_awready    ),
                                .s_axi_awaddr          (s_axi_snap_awaddr     ),//32b
                                .s_axi_awprot          (s_axi_snap_awprot     ),//3b
                                .s_axi_awvalid         (s_axi_snap_awvalid    ),
                                .s_axi_wready          (s_axi_snap_wready     ),
                                .s_axi_wdata           (s_axi_snap_wdata      ),//32b
                                .s_axi_wstrb           (s_axi_snap_wstrb      ),//4b
                                .s_axi_wvalid          (s_axi_snap_wvalid     ),
                                .s_axi_bresp           (s_axi_snap_bresp      ),//2b
                                .s_axi_bvalid          (s_axi_snap_bvalid     ),
                                .s_axi_bready          (s_axi_snap_bready     ),
                                .s_axi_arready         (s_axi_snap_arready    ),
                                .s_axi_arvalid         (s_axi_snap_arvalid    ),
                                .s_axi_araddr          (s_axi_snap_araddr     ),//32b
                                .s_axi_arprot          (s_axi_snap_arprot     ),//3b
                                .s_axi_rdata           (s_axi_snap_rdata      ),//32b
                                .s_axi_rresp           (s_axi_snap_rresp      ),//2b
                                .s_axi_rready          (s_axi_snap_rready     ),
                                .s_axi_rvalid          (s_axi_snap_rvalid     ),
                      //---- local control ----
                                .memcpy_enable         (memcpy_enable         ),
                                .source_address        (source_address        ),//64b
                                .target_address        (target_address        ),//64b
                                .source_size           (source_size           ),//64b
                                .target_size           (target_size           ),//64b
                                .read_number           (read_number           ),//32b
                                .read_rand_patt        (read_rand_patt        ),//32b
                                .write_number          (write_number          ),//32b
                                .write_rand_patt       (write_rand_patt       ),//32b
                                .seed                  (input_seed            ),//32b
                                .interrupt_patt        (interrupt_patt        ),//32b                                
                      //---- local status ----
                                .memcpy_done           (memcpy_done           ),
                      //---- snap status ----
                                .i_app_ready           (i_app_ready           ),
                                .i_action_type         (i_action_type         ),
                                .i_action_version      (i_action_version      ),
                                .o_snap_context        (snap_context          )
                               );

//----------------------------------------------------------------------------------------------
//---- AXI Master Signals ----
//----------------------------------------------------------------------------------------------

    wire    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]          m_axi_awid_host;
    wire    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]        m_axi_awaddr_host;
    wire    [7:0]                                      m_axi_awlen_host;
    wire    [2:0]                                      m_axi_awsize_host;
    wire    [1:0]                                      m_axi_awburst_host;
    wire    [1:0]                                      m_axi_awlock_host;
    wire    [3:0]                                      m_axi_awcache_host;
    wire    [2:0]                                      m_axi_awprot_host;
    wire    [3:0]                                      m_axi_awregion_host;
    wire    [3:0]                                      m_axi_awqos_host;
    wire    [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0]      m_axi_awuser_host;
    wire                                               m_axi_awvalid_host;
    wire                                               m_axi_awready_host;
    wire    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]        m_axi_wdata_host;
    wire    [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) - 1:0]    m_axi_wstrb_host;
    wire                                               m_axi_wlast_host;
    wire    [C_M_AXI_HOST_MEM_WUSER_WIDTH - 1:0]       m_axi_wuser_host;
    wire                                               m_axi_wvalid_host;
    wire                                               m_axi_wready_host;
    wire    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]          m_axi_bid_host;
    wire    [1:0]                                      m_axi_bresp_host;
    wire    [C_M_AXI_HOST_MEM_BUSER_WIDTH - 1:0]       m_axi_buser_host;
    wire                                               m_axi_bvalid_host;
    wire                                               m_axi_bready_host;
    wire    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]          m_axi_arid_host;
    wire    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]        m_axi_araddr_host;
    wire    [7:0]                                      m_axi_arlen_host;
    wire    [2:0]                                      m_axi_arsize_host;
    wire    [1:0]                                      m_axi_arburst_host;
    wire    [1:0]                                      m_axi_arlock_host;
    wire    [3:0]                                      m_axi_arcache_host;
    wire    [2:0]                                      m_axi_arprot_host;
    wire    [3:0]                                      m_axi_arregion_host;
    wire    [3:0]                                      m_axi_arqos_host;
    wire    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0]      m_axi_aruser_host;
    wire                                               m_axi_arvalid_host;
    wire                                               m_axi_arready_host;
    wire    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]          m_axi_rid_host;
    wire    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]        m_axi_rdata_host;
    wire    [1:0]                                      m_axi_rresp_host;
    wire                                               m_axi_rlast_host;
    wire    [C_M_AXI_HOST_MEM_RUSER_WIDTH - 1:0]       m_axi_ruser_host;
    wire                                               m_axi_rvalid_host;
    wire                                               m_axi_rready_host;

    always@*  m_axi_snap_awid= #1 m_axi_awid_host;
    always@*  m_axi_snap_awaddr= #1 m_axi_awaddr_host;
    always@*  m_axi_snap_awlen= #1 m_axi_awlen_host;
    always@*  m_axi_snap_awsize= #1 m_axi_awsize_host;
    always@*  m_axi_snap_awburst= #1 m_axi_awburst_host;
    always@*  m_axi_snap_awlock= #1 0;//m_axi_awlock_host;
    always@*  m_axi_snap_awcache= #1 m_axi_awcache_host;
    always@*  m_axi_snap_awprot= #1 m_axi_awprot_host;
    always@*  m_axi_snap_awregion= #1 m_axi_awregion_host;
    always@*  m_axi_snap_awqos= #1 m_axi_awqos_host;
    always@*  m_axi_snap_awuser= #1 m_axi_awuser_host;
    always@*  m_axi_snap_awvalid= #1 m_axi_awvalid_host;
    assign    m_axi_awready_host=m_axi_snap_awready;
    always@*  m_axi_snap_wdata= #1 m_axi_wdata_host;
    always@*  m_axi_snap_wstrb= #1 m_axi_wstrb_host;
    always@*  m_axi_snap_wlast= #1 m_axi_wlast_host;
    //always@*  m_axi_snap_wuser= #1 m_axi_wuser_host;
    always@*  m_axi_snap_wvalid= #1 m_axi_wvalid_host;
    assign    m_axi_wready_host=m_axi_snap_wready;
    assign    m_axi_bid_host=m_axi_snap_bid;
    assign    m_axi_bresp_host=m_axi_snap_bresp;
    assign    m_axi_buser_host=0;//=m_axi_snap_buser;
    assign    m_axi_bvalid_host=m_axi_snap_bvalid;
    always@*  m_axi_snap_bready= #1 m_axi_bready_host;
    always@*  m_axi_snap_arid= #1 m_axi_arid_host;
    always@*  m_axi_snap_araddr= #1 m_axi_araddr_host;
    always@*  m_axi_snap_arlen= #1 m_axi_arlen_host;
    always@*  m_axi_snap_arsize= #1 m_axi_arsize_host;
    always@*  m_axi_snap_arburst= #1 m_axi_arburst_host;
    always@*  m_axi_snap_arlock= #1 0;//m_axi_arlock_host;
    assign    m_axi_arcache_host=m_axi_snap_arcache;
    always@*  m_axi_snap_arprot= #1 m_axi_arprot_host;
    always@*  m_axi_snap_arregion= #1 m_axi_arregion_host;
    always@*  m_axi_snap_arqos= #1 m_axi_arqos_host;
    always@*  m_axi_snap_aruser= #1 m_axi_aruser_host;
    always@*  m_axi_snap_arvalid= #1 m_axi_arvalid_host;
    assign    m_axi_arready_host=m_axi_snap_arready;
    assign    m_axi_rid_host=m_axi_snap_rid;
    assign    m_axi_rdata_host=m_axi_snap_rdata;
    assign    m_axi_rresp_host=m_axi_snap_rresp;
    assign    m_axi_rlast_host=m_axi_snap_rlast;
    assign    m_axi_ruser_host=0;//=m_axi_snap_ruser;
    assign    m_axi_rvalid_host=m_axi_snap_rvalid;
    always@*  m_axi_snap_rready= #1 m_axi_rready_host;


//----------------------------------------------------------------------------------------------
//---- AXI Master VIP Instance ----
//----------------------------------------------------------------------------------------------

axi_vip_master_mst_t axi_vip_master_mst;

axi_vip_master host_mem_master(
  .aclk(clk),
  .aresetn(rst_n),
  // AXI write address channel
  .m_axi_awid(m_axi_awid_host),
  .m_axi_awaddr(m_axi_awaddr_host),
  .m_axi_awlen(m_axi_awlen_host),
  .m_axi_awsize(m_axi_awsize_host),
  .m_axi_awburst(m_axi_awburst_host),
  .m_axi_awlock(m_axi_awlock_host),
  .m_axi_awcache(m_axi_awcache_host),
  .m_axi_awprot(m_axi_awprot_host),
  .m_axi_awregion(m_axi_awregion_host),
  .m_axi_awqos(m_axi_awqos_host),
  .m_axi_awuser(m_axi_awuser_host),
  .m_axi_awvalid(m_axi_awvalid_host),
  .m_axi_awready(m_axi_awready_host),
  // AXI write data channel
  .m_axi_wdata(m_axi_wdata_host),
  .m_axi_wstrb(m_axi_wstrb_host),
  .m_axi_wlast(m_axi_wlast_host),
  .m_axi_wuser(m_axi_wuser_host),
  .m_axi_wvalid(m_axi_wvalid_host),
  .m_axi_wready(m_axi_wready_host),
  // AXI write response channel
  .m_axi_bid(m_axi_bid_host),
  .m_axi_bresp(m_axi_bresp_host),
  .m_axi_buser(m_axi_buser_host),
  .m_axi_bvalid(m_axi_bvalid_host),
  .m_axi_bready(m_axi_bready_host),
  // AXI read address channel
  .m_axi_arid(m_axi_arid_host),
  .m_axi_araddr(m_axi_araddr_host),
  .m_axi_arlen(m_axi_arlen_host),
  .m_axi_arsize(m_axi_arsize_host),
  .m_axi_arburst(m_axi_arburst_host),
  .m_axi_arlock(m_axi_arlock_host),
  .m_axi_arcache(m_axi_arcache_host),
  .m_axi_arprot(m_axi_arprot_host),
  .m_axi_arregion(m_axi_arregion_host),
  .m_axi_arqos(m_axi_arqos_host),
  .m_axi_aruser(m_axi_aruser_host),
  .m_axi_arvalid(m_axi_arvalid_host),
  .m_axi_arready(m_axi_arready_host),
  // AXI read data channel
  .m_axi_rid(m_axi_rid_host),
  .m_axi_rdata(m_axi_rdata_host),
  .m_axi_rresp(m_axi_rresp_host),
  .m_axi_rlast(m_axi_rlast_host),
  .m_axi_ruser(m_axi_ruser_host),
  .m_axi_rvalid(m_axi_rvalid_host),
  .m_axi_rready(m_axi_rready_host)
);

//----------------------------------------------------------------------------------------------
//---- AXI Driver Local Signals ----
//----------------------------------------------------------------------------------------------

//Define AXI transaction
axi_transaction rd_transaction;
axi_transaction wr_transaction;
axi_transaction rd_transaction_q[$];
axi_transaction wr_transaction_q[$];

parameter ACTION_DONE_DRIVE_CYCLES      = 100;

int wr_resp_num=0;
int rd_resp_num=0;
reg memcpy_enable_reg;
int seed;
xil_axi_uint mst_agent_verbosity = 0;
//int addr_lock_model[longint unsigned];

//----------------------------------------------------------------------------------------------
//---- AXI Driver Random Parameter Controls ----
//----------------------------------------------------------------------------------------------

//Define AXI transaction

initial begin

    //========================================================
    //Example code to get simulator parameters
    //./run_sim -sparm "+STRING=Joery +NUMBER=100"
    //string       var1;
    //bit [31:0]   data;

    ////Handle Testcase runtime arguments
    //if ($value$plusargs ("STRING=%s", var1))
    //  $display ("STRING with FS has a value %s", var1);
    //if ($value$plusargs ("NUMBER=%0d", data))
    //  $display ("NUMBER with %%0d has a value %0d", data);
    //========================================================


    // New an AXI Master VIP
    // Note: some default Addr width, ID width, A?USER width are configured
    // in $ACTION_ROOT/ip/create_action_ip.tcl
    axi_vip_master_mst = new("axi_vip_master_mst", host_mem_master.inst.IF);
    // When bus is in idle, drive everything to 0
    axi_vip_master_mst.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
    // Set tag for agents for easy debug
    axi_vip_master_mst.set_agent_tag("Host-mem Master Axi4 VIP");
    // Set print out verbosity level.
    axi_vip_master_mst.set_verbosity(mst_agent_verbosity);
    // Set the capability to program the write/read transactions
    axi_vip_master_mst.wr_driver.seq_item_port.set_max_item_cnt(10000);
    axi_vip_master_mst.rd_driver.seq_item_port.set_max_item_cnt(10000);
    // Not to check 'X' value
    host_mem_master.inst.IF.set_enable_xchecks_to_warn();
    host_mem_master.inst.IF.set_xilinx_reset_check_to_warn();
    // Set waiting valid timeout value
    axi_vip_master_mst.wr_driver.set_waiting_valid_timeout_value(5000000);
    axi_vip_master_mst.rd_driver.set_waiting_valid_timeout_value(5000000);
    //Set AR or R handshakes timeout
    axi_vip_master_mst.wr_driver.set_forward_progress_timeout_value(500000);
    axi_vip_master_mst.rd_driver.set_forward_progress_timeout_value(500000);
    // Start AXI master
    axi_vip_master_mst.start_master();
    memcpy_done <= 1'b0;
    memcpy_enable_reg <= 0;


end

//Drive read transaction
task driver_rd_data();
    bit [8*4096-1:0]                        rd_block;
    bit [7:0] dly_addr;
    bit [7:0] dly_d_ins;
    bit [7:0] dly_rsp;
    bit [7:0] dly_allow_dbc;

    rd_transaction = axi_vip_master_mst.rd_driver.create_transaction("read transaction");
    rd_transaction.set_aruser(gen_user(read_rand_patt));
    rd_transaction.id = gen_id(read_rand_patt);
    rd_transaction.size = gen_size(read_rand_patt);
    {rd_transaction.len, rd_transaction.addr} = gen_len_and_addr(read_rand_patt, source_address, source_size, rd_transaction.size, 1'b0);
    rd_transaction.cache = 4'h0;
    rd_transaction.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
    //Allow to generate consecutive read commands

    {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} = gen_xfer_delays(read_rand_patt, rd_transaction);
    if ( {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} != 32'hFFFFFFFF ) begin
        rd_transaction.set_addr_delay (dly_addr);
        rd_transaction.set_data_insertion_delay(dly_d_ins);
        rd_transaction.set_response_delay(dly_rsp);
        rd_transaction.set_allow_data_before_cmd(dly_allow_dbc);
    end

    axi_vip_master_mst.rd_driver.send(rd_transaction);
    rd_transaction_q.push_back(rd_transaction);
endtask

//Drive write transaction
task driver_wr_data();
    bit [8*4096-1:0]                        wr_block;
    bit [7:0] dly_addr;
    bit [7:0] dly_d_ins;
    bit [7:0] dly_rsp;
    bit [7:0] dly_allow_dbc;
    bit [7:0] dly_beat;
    //static integer cnt=0;

    //do begin
        wr_transaction = axi_vip_master_mst.wr_driver.create_transaction("write transaction");
        wr_transaction.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        if (gen_wrcmd_order(write_rand_patt))
            wr_transaction.set_xfer_wrcmd_order(XIL_AXI_WRCMD_ORDER_DATA_BEFORE_CMD);

        wr_transaction.size = gen_size(write_rand_patt);
        {wr_transaction.len, wr_transaction.addr} = gen_len_and_addr(write_rand_patt, target_address, target_size, wr_transaction.size, 1'b1);
        
        //Allow to generate consecutive write commands
        {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} = gen_xfer_delays(write_rand_patt, wr_transaction);
        if ( {dly_addr, dly_d_ins, dly_rsp, dly_allow_dbc} != 32'hFFFFFFFF ) begin
            wr_transaction.set_addr_delay (dly_addr);
            wr_transaction.set_data_insertion_delay(dly_d_ins);
            wr_transaction.set_response_delay(dly_rsp);
            wr_transaction.set_allow_data_before_cmd(dly_allow_dbc);
        end

    //    cnt ++;
    //    
    //end
    //while(exists_addr_lock(wr_transaction.addr, wr_transaction.len, wr_transaction.size) && (cnt <=10000));

    //if (cnt >= 10000) begin
    //    $display("Couldn't solve a write transaction after trying 10000 times.");
    //    $display("target_address = 0x%016x, target_size = 0x%x", target_address, target_size);
    //    $display("write rand pattern = 0x%08x", write_rand_patt);
    //    $finish;
    //end

    //Set value for the transaction
    wr_transaction.set_awuser(gen_user(write_rand_patt));
    wr_transaction.id = gen_id(write_rand_patt);
    wr_transaction.cache = 4'h0;
    wr_transaction.size_wr_beats();
    wr_transaction.set_data_block(wr_block);
    for (xil_axi_uint beat = 0; beat < wr_transaction.get_len()+1; beat++) begin
        wr_transaction.set_user_beat(beat, 0);
        wr_transaction.set_data_beat(beat, gen_1024bit_data(write_rand_patt));
        wr_transaction.set_strb_beat(beat, gen_wstrb(write_rand_patt));
        dly_beat = get_beat_delay(write_rand_patt, wr_transaction);
        if (dly_beat != 8'hFF) begin
            wr_transaction.set_beat_delay(beat, dly_beat);
            //$display("%d-%d, ", beat, wr_transaction.get_beat_delay(beat));
        end
    end

    // Send
    axi_vip_master_mst.wr_driver.send(wr_transaction);
    wr_transaction_q.push_back(wr_transaction);
    // Lock this region
    //set_addr_lock(wr_transaction.addr, wr_transaction.len, wr_transaction.size);
endtask

// Drive action done
task driver_action_done();
    repeat(ACTION_DONE_DRIVE_CYCLES) begin @(posedge clk); end
    memcpy_done <= 1'b1;
    repeat(ACTION_DONE_DRIVE_CYCLES) begin @(posedge clk); end
    memcpy_done <= 1'b0;
endtask

//-----------------------------------------------------
//-----------------------------------------------------
// Decode rand_pattern and generate vaious things
//-----------------------------------------------------
//-----------------------------------------------------
function bit gen_wrcmd_order (bit[31:0] rand_patt);
    bit wrcmd_order;
    if ( rand_patt[27:24] == 4'hF)
        wrcmd_order = $urandom() %2;
    else if ( rand_patt[31:28] == 4'h1)
        wrcmd_order = 1; //Write DATA FIRST, then address (a strange situation but is allowed by AXI spec.)
    else
        wrcmd_order = 0; //Write ADDR FIRST
    return wrcmd_order;
endfunction

function bit[31:0] gen_xfer_delays (bit[31:0] rand_patt, axi_transaction tr);
    bit [7:0] min_addr_delay;
    bit [7:0] max_addr_delay;
    bit [7:0] addr_delay;

    bit [7:0] min_data_insertion_delay;
    bit [7:0] max_data_insertion_delay;
    bit [7:0] data_insertion_delay;

    bit [7:0] min_response_delay;
    bit [7:0] max_response_delay;
    bit [7:0] response_delay;

    bit [7:0] min_dbc;
    bit [7:0] max_dbc;
    bit [7:0] max_dbc_use;
    bit [7:0] allow_data_before_cmd;

    tr.get_addr_delay_range(min_addr_delay, max_addr_delay);
    tr.get_data_insertion_delay_range(min_data_insertion_delay, max_data_insertion_delay);
    tr.get_response_delay_range(min_response_delay, max_response_delay);
    tr.get_allow_data_before_cmd_range(min_dbc, max_dbc);

    //0-255, don't overflow.
    //NOTE: Please set len in advance (before calling this function) !!!
    max_dbc_use = (tr.get_len() <= max_dbc)? tr.get_len() : max_dbc;
    
    if ( rand_patt[31:28] == 4'hF) begin
        //the range is [min, max)
        //$display("min,max: %d,%d (a), %d,%d (d_ins), %d, %d (rsp), %d, %d (dbc)", min_addr_delay, max_addr_delay, min_data_insertion_delay, max_data_insertion_delay, min_response_delay, max_response_delay, min_dbc, max_dbc_use);
        addr_delay            = min_addr_delay + $urandom()%(max_addr_delay - min_addr_delay); 
        data_insertion_delay  = min_data_insertion_delay + $urandom()%(max_data_insertion_delay - min_data_insertion_delay); 
        response_delay        = min_response_delay + $urandom()%(max_response_delay - min_response_delay); 
        allow_data_before_cmd = min_dbc + $urandom()%( max_dbc_use - min_dbc); 
    end
    else if (rand_patt [31:28] == 4'h2) begin
        addr_delay            = $urandom()%2; 
        data_insertion_delay  = $urandom()%2; 
        response_delay        = $urandom()%2; 
        allow_data_before_cmd = $urandom()%2; 
    end
    else if (rand_patt [31:28] == 4'h1) begin
        //No delay (or shortest)
        addr_delay            = 0; 
        data_insertion_delay  = 0; 
        response_delay        = 0; 
        allow_data_before_cmd = 0; 
    end
    else begin
        addr_delay            = 8'hFF; 
        data_insertion_delay  = 8'hFF; 
        response_delay        = 8'hFF; 
        allow_data_before_cmd = 8'hFF; 
    end
    if ({addr_delay, data_insertion_delay, response_delay, allow_data_before_cmd} != 32'hFFFFFFFF)
        $display("Delay numbers %d(a), %d(d_ins), %d(rsp), %d(allow_dbc)\n", addr_delay, data_insertion_delay, response_delay, allow_data_before_cmd);

    return {addr_delay, data_insertion_delay, response_delay, allow_data_before_cmd};
endfunction

function bit[7:0] get_beat_delay (bit[31:0] rand_patt, axi_transaction tr);
    bit [7:0] beat_delay;
    if ( rand_patt[31:28] == 4'hF)
         beat_delay = $urandom()%5;
         //because xilinx VIP didn't provide get_min_beat_delay() and
         //get_max_beat_delay() method
         //beat_delay = tr.get_min_beat_delay() + $urandom()%(tr.get_max_beat_delay() - tr.get_min_beat_delay());
    else if (rand_patt [31:28] == 4'h2)
         beat_delay = $urandom()%2;
    else if (rand_patt [31:28] == 4'h1)
         beat_delay = 0;
    else
         beat_delay = 8'hFF; //Invalid
    return beat_delay;
endfunction


function bit[127:0] gen_wstrb (bit[31:0] rand_patt);
    bit [127:0] wstrb;
    if ( rand_patt[23:20] == 4'h0)
        wstrb = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;
    else
        wstrb = {$urandom(), $urandom(), $urandom(), $urandom()};
    return wstrb;
endfunction

//Note: here is a an assumption: AWUSER_WIDTH=ARUSER_WIDTH
function bit [C_M_AXI_HOST_MEM_AWUSER_WIDTH-1:0] gen_user (bit[31:0] rand_patt);
    bit [C_M_AXI_HOST_MEM_AWUSER_WIDTH-1:0] user;
    if ( rand_patt[19:16] == 4'hF)
        user = $urandom() & ((1<<C_M_AXI_HOST_MEM_AWUSER_WIDTH)-1);
    else if (rand_patt[19:16] == 4'h0)
        user = 0;
    else if (rand_patt[19:16] == 4'h2)
        user = $urandom() % 2;
    else if (rand_patt[19:16] == 4'h4)
        user = $urandom() % 4;
    else if (rand_patt[19:16] == 4'h8)
        user = $urandom() % 8;
    else if (rand_patt[19:16] == 4'hA)
        user = $urandom() % 16;
    return user;
endfunction
function bit [C_M_AXI_HOST_MEM_ID_WIDTH-1:0] gen_id (bit[31:0] rand_patt);
    bit [C_M_AXI_HOST_MEM_ID_WIDTH-1:0] id;
    if ( rand_patt[15:12] == 4'hF)
        id = $urandom() & ((1<<C_M_AXI_HOST_MEM_ID_WIDTH)-1);
    else if (rand_patt[15:12] == 4'h0)
        id = 0;
    else if (rand_patt[15:12] == 4'h2)
        id = $urandom() % 2;
    else if (rand_patt[15:12] == 4'h4)
        id = $urandom() % 4;
    else if (rand_patt[15:12] == 4'h8)
        id = $urandom() % 8;
    else if (rand_patt[15:12] == 4'hA)
        id = $urandom() % 16;
    else
        id = 0;
    return id;
endfunction


function bit [2:0] gen_size (bit[31:0] rand_patt);
    bit [2:0] size;
    if ( rand_patt[7:4] == 4'hF)
        size = $urandom() % 3'b111; //0 ~ 7
    else
        size = rand_patt[6:4];
    return size;
endfunction

function bit [71:0] gen_len_and_addr (bit[31:0] rand_patt, bit[63:0] base_addr, bit[63:0] range, bit[2:0] size, bit nst);
    bit [11:0] beat_bytes;
    bit [12:0] block_bytes;
    bit [63:0] addr;
    bit [11:0] addr_low_mask; 
    bit [7:0]  len;
    bit aligned;

    // New address random item
    axi_addr_rand_item = new();
    //Shift size to beat_bytes
    beat_bytes = (1 << size);

    if (rand_patt[11:8] == 4'hF)
        aligned = 0; //Address totally random
    else
        aligned = 1; //Address random but low bits are 0
    
    if (size == 7)
        addr_low_mask = 12'b111110000000;
    else if (size == 6)
        addr_low_mask = 12'b111111000000;
    else if (size == 5)
        addr_low_mask = 12'b111111100000;
    else if (size == 4)
        addr_low_mask = 12'b111111110000;
    else if (size == 3)
        addr_low_mask = 12'b111111111000;
    else if (size == 2)
        addr_low_mask = 12'b111111111100;
    else if (size == 1)
        addr_low_mask = 12'b111111111110;
    else
        addr_low_mask = 12'b111111111111;

    //the data block size should not be bigger than 4KB
    if (rand_patt[3:0] == 4'hF) begin
        if (size == 7)
            len = $urandom() & 8'h1F;
        else if (size == 6)
            len = $urandom() & 8'h3F;
        else if (size == 5)
            len = $urandom() & 8'h7F;
        else
            len = $urandom() & 8'hFF;
    end
    else if (rand_patt[3:0] == 4'hE)
        len = 255;
    else if (rand_patt[3:0] == 4'hD)
        len = 127;
    else if (rand_patt[3:0] == 4'hC)
        len = 63;
    else if (rand_patt[3:0] == 4'hB)
        len = 31;
    else if (rand_patt[3:0] == 4'hA)
        len = 15;
    else
        len = rand_patt[3:0];

    //High address bits are aligned to 4K
    //Suppose the range is less than 4GB and > 0
    //addr[63:12] = base_addr[63:12] + ($urandom() % range[31:12]);
    //void'(axi_addr_rand_item.randomize());
    //For target address
    if(nst) begin
    //std::randomize(axi_addr_rand_item.rand_target_addr) with {axi_addr_rand_item.rand_target_addr inside {target_addr_q};}
    void'(axi_addr_rand_item.randomize(rand_target_addr) with {axi_addr_rand_item.rand_target_addr inside {target_addr_q};});
        addr[63:0] = base_addr[63:0] + axi_addr_rand_item.rand_target_addr[31:0];
        target_addr_q.delete(axi_addr_rand_item.rand_target_addr);
    end
    //For source address
    else begin
    //std::randomize(axi_addr_rand_item.rand_source_addr) with {axi_addr_rand_item.rand_source_addr inside {source_addr_q};}
    void'(axi_addr_rand_item.randomize(rand_source_addr) with {axi_addr_rand_item.rand_source_addr inside {source_addr_q};});    
        addr[63:0] = base_addr[63:0] + axi_addr_rand_item.rand_source_addr[31:0];
        source_addr_q.delete(axi_addr_rand_item.rand_source_addr);
    end
    $display("randomize addr = 0x%x, beat_bytes=%d, range_low=%x", addr, beat_bytes, range[31:12]);
    //The memory in Host needs to have addtional one 4K 
    //Pick up the starting address inside 4K
    block_bytes = (len+1) * beat_bytes;
    if (block_bytes > 4096) begin
        $display("ERROR: Wrong rand_pattern: Size * (Len+1) should <= 4096. Run 'hdl_bridge_test -h' for more info.\n");
        $finish;
    end
    
    addr[11:0] = (4096 - block_bytes) == 0 ? 0 : ($urandom() % (4096 - block_bytes));

    if (aligned)
        addr[11:0] = addr[11:0] & addr_low_mask; 

    return {len, addr};
endfunction

// Generate 1024-bit random data
function bit[1023:0] gen_1024bit_data(bit[31:0] write_rand_patt);
    static bit[63:0] temp=0;
    for(int i=0; i<16; i++)begin
        gen_1024bit_data[1023:0] = {((write_rand_patt[23:21] == 3'b000)? temp: {$urandom(),$urandom()}), gen_1024bit_data[1023:64]};
        temp = temp + 1;
    end
 
  //  for(int i=0; i<32; i++)begin
  //      gen_1024bit_data[1023:0] = {gen_1024bit_data[991:0], $urandom()};
  //  end
endfunction


//-----------------------------------------------------
//-----------------------------------------------------
// Set / Check the address lock for write transaction
//-----------------------------------------------------
//-----------------------------------------------------

//function void set_addr_lock(bit[63:0] addr, bit[7:0] length, bit[2:0] size);
//    bit[63:0] bytes;
//
//    //The unaligned address lower bits should be considered:
//    //Example: 
//    // size = 5; (1<<size) = 32; (1<<size)-1 = 5'b11111 (mask)
//    // block_size = (127+1) * (1<<5) = 4096
//    // address = 6; 
//    // Impacted bytes are 6 ..... 4095 
//    // bytes = block_size - addr & mask
//    //
//    bytes = (length + 1) * (1 << size) - (addr & ((1<<size)-1));
//    //$display("Lock address range start=0x%016x, aw_len=%d, aw_size=%d, bytes=0x%x", addr,length, size, bytes); 
//    for(int i=0; i<bytes; i++)
//        addr_lock_model[addr+i] = 0;
//endfunction
//
//function bit exists_addr_lock(bit[63:0] addr, bit[7:0] length, bit[2:0] size);
//    bit[63:0] bytes;
//    bytes = (length + 1) * (1 << size) - (addr & ((1<<size)-1));
//    //$display("Check address range start=0x%016x, aw_len=%d, aw_size=%d, bytes=0x%x", addr,length, size, bytes); 
//    for(int i=0; i<bytes; i++) begin
//        if(addr_lock_model.exists(addr+i))
//            return 1;
//    end
//    return 0;
//endfunction

//-----------------------------------------------------
//-----------------------------------------------------

// Process read/write command
always@(posedge memcpy_enable) begin
    longint unsigned int_source_size;
    longint unsigned int_target_size;
    seed = input_seed;
    int_source_size = source_size;
    int_target_size = target_size;    
    $srandom(seed);
    $display("Random pattern for Read:  0X%08x, number=", read_rand_patt, read_number);
    $display("Random pattern for write: 0X%08x, number=", write_rand_patt, write_number);
    $display("seed=%d", seed);
    if(read_rand_patt[31:28] == 4'h1) begin
        $display("Set the fastest driving for READ. Send ARVALID as quickly as possible, RREADY is always asserted.");
        set_my_nobackpressure_rready(axi_vip_master_mst);
    end
    if(write_rand_patt[31:28] == 4'h1) begin
        $display("Set the fastest driving for WRITE. Send AWVALID and WVALID as quickly as possible, BREADY is always asserted.");
        set_my_nobackpressure_bready(axi_vip_master_mst);
    end
    //Get all valid source address
    for(int i=0; i<int_source_size/4096; i++) begin
        source_addr_q[4096*i]=4096*i;
    end
    //Get all valid target address
    for(int i=0; i<int_target_size/4096; i++) begin
        target_addr_q[4096*i]=4096*i;
    end
    if(source_addr_q.size<read_number || target_addr_q.size<write_number) begin
        $display("ERROR: Not enough memory space for read/write commands.\n");
        $finish;
    end
    fork
        for(int i=0; i<read_number; i++)begin
            driver_rd_data();
            rd_req_q.push_back(1'b1);
           $display("Finish to send a rd of number %d", i);
        end
        for(int i=0; i<write_number; i++)begin
            driver_wr_data();
            wr_req_q.push_back(1'b1);
            $display("Finish to send a wr of number %d", i);
        end
    join
end

// Lock address for write transactions
//always@(posedge clk)begin
//    foreach(addr_lock_model[i])begin
//        if(addr_lock_model[i] > 2000)
//            addr_lock_model.delete(i);
//        else
//            addr_lock_model[i]++;
//    end
//end

always@(posedge memcpy_enable) memcpy_enable_reg <= 1;

always@(posedge memcpy_done) memcpy_enable_reg <= 0;

// Wait for read/write response
always@(posedge clk)fork
    if(memcpy_enable_reg == 1 && rd_resp_num == read_number && wr_resp_num == write_number)
        driver_action_done();
    if(memcpy_enable_reg == 0) begin
        wr_resp_num = 0;
        rd_resp_num = 0;
    end

    if(rd_transaction_q.size > 0)begin
        axi_vip_master_mst.rd_driver.wait_rsp(rd_transaction_q[0]);
        void'(rd_transaction_q.pop_front());
        rd_resp_num++;
    end
    if(wr_transaction_q.size > 0)begin
        axi_vip_master_mst.wr_driver.wait_rsp(wr_transaction_q[0]);
        void'(wr_transaction_q.pop_front());
        wr_resp_num++;
    end
join

task set_my_nobackpressure_rready(axi_vip_master_mst_t axi_vip_master_mst);
    axi_ready_gen rready;
    rready = new("nobackpressure_rready");

    rready.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
    //rready.set_low_time_range(0,0);
    //rready.set_high_time_range(100,100);
    axi_vip_master_mst.rd_driver.set_rready_gen(rready);
endtask

task set_my_nobackpressure_bready(axi_vip_master_mst_t axi_vip_master_mst);
    axi_ready_gen bready;
    bready = new("nobackpressure_bready");

    bready.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
    //bready.set_low_time_range(0,0);
    //bready.set_high_time_range(100,100);
    axi_vip_master_mst.wr_driver.set_bready_gen(bready);
endtask

//Interrupt
always@(posedge clk)begin
    //Generate 1 interrupt
    if(interrupt_patt == 32'h1)begin
        if(((read_number > 0) && (rd_req_q.size == read_number)) && ((write_number > 0) && (wr_req_q.size == write_number)))begin
           rd_req_q.pop_front();
           wr_req_q.pop_front();
           intrp_req_q.push_back(1'b1);           
        end
    end
    //Generate 2 interrupts
    else if(interrupt_patt == 32'h2)begin
        if((read_number > 0) && (rd_req_q.size == read_number))begin
           rd_req_q.pop_front();
           intrp_req_q.push_back(1'b1);           
        end
        else if((write_number > 0) && (wr_req_q.size == write_number))begin
           wr_req_q.pop_front();
           intrp_req_q.push_back(1'b1);           
        end
    end
    //Generate some interrupts  
    else if(interrupt_patt == 32'hF)begin
        if(rd_req_q.size > 0)begin
           rd_req_q.pop_front();
           intrp_req_q.push_back(1'b1);
        end
        else if(wr_req_q.size > 0)begin
           wr_req_q.pop_front();
           intrp_req_q.push_back(1'b1);
        end
    end
    //Send interrupts
    if(~rst_n)begin
        interrupt     <= 1'b0;
        interrupt_src <= 64'b0;            
        interrupt_ctx <= 9'b0;                    
    end
    else begin
        if(interrupt_ack == 1'b1 && interrupt == 1'b1)
            interrupt <= 1'b0;
        if(interrupt_ack == 1'b0 && interrupt == 1'b0 && intrp_req_q.size > 0)begin
            interrupt <= 1'b1;
            intrp_req_q.pop_front();
        end
    end
end

endmodule
