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
`include "snap_global_vars.v"

module action_wrapper (
   input                                   ap_clk                   ,
   input                                   ap_rst_n                 ,
   output                                  interrupt                ,
   output [`INT_BITS-1:0]                  interrupt_src            ,
   output [`CTXW-1:0]                      interrupt_ctx            ,
   input                                   interrupt_ack            ,
    //
    // AXI Control Register inputterface
   input [ `AXI_LITE_AW-1 : 0]             s_axi_ctrl_reg_araddr    ,
   output                                  s_axi_ctrl_reg_arready   ,
   input                                   s_axi_ctrl_reg_arvalid   ,
   input [ `AXI_LITE_AW-1 : 0]             s_axi_ctrl_reg_awaddr    ,
   output                                  s_axi_ctrl_reg_awready   ,
   input                                   s_axi_ctrl_reg_awvalid   ,
   input                                   s_axi_ctrl_reg_bready    ,
   output [ 1 : 0]                         s_axi_ctrl_reg_bresp     ,
   output                                  s_axi_ctrl_reg_bvalid    ,
   output [ `AXI_LITE_DW-1 : 0]            s_axi_ctrl_reg_rdata     ,
   input                                   s_axi_ctrl_reg_rready    ,
   output [ 1 : 0]                         s_axi_ctrl_reg_rresp     ,
   output                                  s_axi_ctrl_reg_rvalid    ,
   input [ `AXI_LITE_DW-1 : 0]             s_axi_ctrl_reg_wdata     ,
   output                                  s_axi_ctrl_reg_wready    ,
   input [(`AXI_LITE_DW/8)-1 : 0]           s_axi_ctrl_reg_wstrb     ,
   input                                   s_axi_ctrl_reg_wvalid    ,
`ifdef ENABLE_AXI_CARD_MEM
   output [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0]  m_axi_card_mem0_araddr   ,
   output [ 1 : 0]                         m_axi_card_mem0_arburst  ,
   output [ 3 : 0]                         m_axi_card_mem0_arcache  ,
   output [ `AXI_CARD_MEM_ID_WIDTH-1 : 0]    m_axi_card_mem0_arid     ,
   output [ 7 : 0]                         m_axi_card_mem0_arlen    ,
   output [ 1 : 0]                         m_axi_card_mem0_arlock   ,
   output [ 2 : 0]                         m_axi_card_mem0_arprot   ,
   output [ 3 : 0]                         m_axi_card_mem0_arqos    ,
   input                                   m_axi_card_mem0_arready  ,
   output [ 3 : 0]                         m_axi_card_mem0_arregion ,
   output [ 2 : 0]                         m_axi_card_mem0_arsize   ,
   output [ `AXI_CARD_MEM_USER_WIDTH-1 : 0] m_axi_card_mem0_aruser  ,
   output                                  m_axi_card_mem0_arvalid  ,
   output [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0]  m_axi_card_mem0_awaddr   ,
   output [ 1 : 0]                         m_axi_card_mem0_awburst  ,
   output [ 3 : 0]                         m_axi_card_mem0_awcache  ,
   output [ `AXI_CARD_MEM_ID_WIDTH-1 : 0]    m_axi_card_mem0_awid     ,
   output [ 7 : 0]                         m_axi_card_mem0_awlen    ,
   output [ 1 : 0]                         m_axi_card_mem0_awlock   ,
   output [ 2 : 0]                         m_axi_card_mem0_awprot   ,
   output [ 3 : 0]                         m_axi_card_mem0_awqos    ,
   input                                   m_axi_card_mem0_awready  ,
   output [ 3 : 0]                         m_axi_card_mem0_awregion ,
   output [ 2 : 0]                         m_axi_card_mem0_awsize   ,
   output [ `AXI_CARD_MEM_USER_WIDTH-1 : 0] m_axi_card_mem0_awuser  ,
   output                                  m_axi_card_mem0_awvalid  ,
   input [`AXI_CARD_MEM_ID_WIDTH-1 : 0]     m_axi_card_mem0_bid      ,
   output                                  m_axi_card_mem0_bready   ,
   input [ 1 : 0]                          m_axi_card_mem0_bresp    ,
   input [`AXI_CARD_MEM_USER_WIDTH-1 : 0]  m_axi_card_mem0_buser    ,
   input                                   m_axi_card_mem0_bvalid   ,
   input [`AXI_CARD_MEM_DATA_WIDTH-1 : 0]   m_axi_card_mem0_rdata    ,
   input [`AXI_CARD_MEM_ID_WIDTH-1 : 0]     m_axi_card_mem0_rid      ,
   input                                   m_axi_card_mem0_rlast    ,
   output                                  m_axi_card_mem0_rready   ,
   input [ 1 : 0]                          m_axi_card_mem0_rresp    ,
   input [ `AXI_CARD_MEM_USER_WIDTH-1 : 0] m_axi_card_mem0_ruser    ,
   input                                   m_axi_card_mem0_rvalid   ,
   output [`AXI_CARD_MEM_DATA_WIDTH-1 : 0]  m_axi_card_mem0_wdata    ,
   output                                  m_axi_card_mem0_wlast    ,
   input                                   m_axi_card_mem0_wready   ,
   output [(`AXI_CARD_MEM_DATA_WIDTH/8)-1 : 0] m_axi_card_mem0_wstrb  ,
   output [`AXI_CARD_MEM_USER_WIDTH-1 : 0] m_axi_card_mem0_wuser    ,
   output                                  m_axi_card_mem0_wvalid   ,
`endif
    //
    // AXI Host Memory inputterface
   output [ `AXI_MM_AW-1 : 0]              m_axi_host_mem_araddr    ,
   output [ 1 : 0]                         m_axi_host_mem_arburst   ,
   output [ 3 : 0]                         m_axi_host_mem_arcache   ,
   output [ `IDW-1 : 0]                    m_axi_host_mem_arid      ,
   output [ 7 : 0]                         m_axi_host_mem_arlen     ,
   output [ 1 : 0]                         m_axi_host_mem_arlock    ,
   output [ 2 : 0]                         m_axi_host_mem_arprot    ,
   output [ 3 : 0]                         m_axi_host_mem_arqos     ,
   input                                   m_axi_host_mem_arready   ,
   output [ 3 : 0]                         m_axi_host_mem_arregion  ,
   output [ 2 : 0]                         m_axi_host_mem_arsize    ,
   output [ `AXI_ARUSER-1 : 0]             m_axi_host_mem_aruser    ,
   output                                  m_axi_host_mem_arvalid   ,
   output [ `AXI_MM_AW-1 : 0]              m_axi_host_mem_awaddr    ,
   output [ 1 : 0]                         m_axi_host_mem_awburst   ,
   output [ 3 : 0]                         m_axi_host_mem_awcache   ,
   output [ `IDW-1 : 0]                    m_axi_host_mem_awid      ,
   output [ 7 : 0]                         m_axi_host_mem_awlen     ,
   output [ 1 : 0]                         m_axi_host_mem_awlock    ,
   output [ 2 : 0]                         m_axi_host_mem_awprot    ,
   output [ 3 : 0]                         m_axi_host_mem_awqos     ,
   input                                   m_axi_host_mem_awready   ,
   output [ 3 : 0]                         m_axi_host_mem_awregion  ,
   output [ 2 : 0]                         m_axi_host_mem_awsize    ,
   output [`AXI_AWUSER-1 : 0]              m_axi_host_mem_awuser    ,
   output                                  m_axi_host_mem_awvalid   ,
   input [ `IDW-1 : 0]                     m_axi_host_mem_bid       ,
   output                                  m_axi_host_mem_bready    ,
   input [ 1 : 0]                          m_axi_host_mem_bresp     ,
   input [ `AXI_BUSER-1 : 0]               m_axi_host_mem_buser     ,
   input                                   m_axi_host_mem_bvalid    ,
   input [ `AXI_ACT_DW-1 : 0]              m_axi_host_mem_rdata     ,
   input [ `IDW-1 : 0]                     m_axi_host_mem_rid       ,
   input                                   m_axi_host_mem_rlast     ,
   output                                  m_axi_host_mem_rready    ,
   input [ 1 : 0]                          m_axi_host_mem_rresp     ,
   input [ `AXI_RUSER-1 : 0]               m_axi_host_mem_ruser     ,
   input                                   m_axi_host_mem_rvalid    ,
   output [ `AXI_ACT_DW-1 : 0]             m_axi_host_mem_wdata     ,
   output                                  m_axi_host_mem_wlast     ,
   input                                   m_axi_host_mem_wready    ,
   output [(`AXI_ACT_DW/8)-1 : 0]          m_axi_host_mem_wstrb     ,
   output [ `AXI_WUSER-1 : 0]              m_axi_host_mem_wuser     ,
   output                                  m_axi_host_mem_wvalid
    );


parameter ADDR_ACTION_TYPE = 32'h10;
parameter ADDR_RELEASE_LEVEL = 32'h14;
parameter ADDR_ACTION_INTERRUPT_SRC_ADDR_LO = 32'h18;
parameter ADDR_ACTION_INTERRUPT_SRC_ADDR_HI = 32'h1C;

reg context_q;
reg [31:0] interrupt_src_hi;
reg [31:0] interrupt_src_lo;
reg interrupt_q;
reg interrupt_wait_ack_q;
reg hls_rst_n_q;
wire interrupt_i;
wire [63:0] temp_card_mem0_araddr;
wire [63:0] temp_card_mem0_awaddr;


reg  [31:0] reg_rdata_hijack; //This will be ORed with the return data of hls_action
wire [31:0] temp_s_axi_ctrl_reg_rdata;

 hls_action hls_action_0 (
    .ap_clk                       ( ap_clk                  ) ,
    .ap_rst_n                     ( hls_rst_n_q             ) ,
`ifdef ENABLE_AXI_CARD_MEM
    .m_axi_card_mem0_araddr       (temp_card_mem0_araddr    ) ,
    .m_axi_card_mem0_arburst      (m_axi_card_mem0_arburst  ) ,
    .m_axi_card_mem0_arcache      (m_axi_card_mem0_arcache  ) ,
    .m_axi_card_mem0_arid         (m_axi_card_mem0_arid[0]  ) ,//SR# 10394170
    .m_axi_card_mem0_arlen        (m_axi_card_mem0_arlen    ) ,
    .m_axi_card_mem0_arlock       (m_axi_card_mem0_arlock   ) ,
    .m_axi_card_mem0_arprot       (m_axi_card_mem0_arprot   ) ,
    .m_axi_card_mem0_arqos        (m_axi_card_mem0_arqos    ) ,
    .m_axi_card_mem0_arready      (m_axi_card_mem0_arready  ) ,
    .m_axi_card_mem0_arregion     (m_axi_card_mem0_arregion ) ,
    .m_axi_card_mem0_arsize       (m_axi_card_mem0_arsize   ) ,
    .m_axi_card_mem0_aruser       (m_axi_card_mem0_aruser   ) ,
    .m_axi_card_mem0_arvalid      (m_axi_card_mem0_arvalid  ) ,
    .m_axi_card_mem0_awaddr       (temp_card_mem0_awaddr    ) ,
    .m_axi_card_mem0_awburst      (m_axi_card_mem0_awburst  ) ,
    .m_axi_card_mem0_awcache      (m_axi_card_mem0_awcache  ) ,
    .m_axi_card_mem0_awid         (m_axi_card_mem0_awid[0]  ) ,//SR# 10394170
    .m_axi_card_mem0_awlen        (m_axi_card_mem0_awlen    ) ,
    .m_axi_card_mem0_awlock       (m_axi_card_mem0_awlock   ) ,
    .m_axi_card_mem0_awprot       (m_axi_card_mem0_awprot   ) ,
    .m_axi_card_mem0_awqos        (m_axi_card_mem0_awqos    ) ,
    .m_axi_card_mem0_awready      (m_axi_card_mem0_awready  ) ,
    .m_axi_card_mem0_awregion     (m_axi_card_mem0_awregion ) ,
    .m_axi_card_mem0_awsize       (m_axi_card_mem0_awsize   ) ,
    .m_axi_card_mem0_awuser       (m_axi_card_mem0_awuser   ) ,
    .m_axi_card_mem0_awvalid      (m_axi_card_mem0_awvalid  ) ,
    .m_axi_card_mem0_bid          (m_axi_card_mem0_bid[0]   ) ,//SR# 10394170
    .m_axi_card_mem0_bready       (m_axi_card_mem0_bready   ) ,
    .m_axi_card_mem0_bresp        (m_axi_card_mem0_bresp    ) ,
    .m_axi_card_mem0_buser        (m_axi_card_mem0_buser    ) ,
    .m_axi_card_mem0_bvalid       (m_axi_card_mem0_bvalid   ) ,
    .m_axi_card_mem0_rdata        (m_axi_card_mem0_rdata    ) ,
    .m_axi_card_mem0_rid          (m_axi_card_mem0_rid[0]   ) ,//SR# 10394170
    .m_axi_card_mem0_rlast        (m_axi_card_mem0_rlast    ) ,
    .m_axi_card_mem0_rready       (m_axi_card_mem0_rready   ) ,
    .m_axi_card_mem0_rresp        (m_axi_card_mem0_rresp    ) ,
    .m_axi_card_mem0_ruser        (m_axi_card_mem0_ruser    ) ,
    .m_axi_card_mem0_rvalid       (m_axi_card_mem0_rvalid   ) ,
    .m_axi_card_mem0_wdata        (m_axi_card_mem0_wdata    ) ,
    .m_axi_card_mem0_wid          (                         ) ,
    .m_axi_card_mem0_wlast        (m_axi_card_mem0_wlast    ) ,
    .m_axi_card_mem0_wready       (m_axi_card_mem0_wready   ) ,
    .m_axi_card_mem0_wstrb        (m_axi_card_mem0_wstrb    ) ,
    .m_axi_card_mem0_wuser        (m_axi_card_mem0_wuser    ) ,
    .m_axi_card_mem0_wvalid       (m_axi_card_mem0_wvalid   ) ,
`endif
    .s_axi_ctrl_reg_araddr        (s_axi_ctrl_reg_araddr    ) ,
    .s_axi_ctrl_reg_arready       (s_axi_ctrl_reg_arready   ) ,
    .s_axi_ctrl_reg_arvalid       (s_axi_ctrl_reg_arvalid   ) ,
    .s_axi_ctrl_reg_awaddr        (s_axi_ctrl_reg_awaddr    ) ,
    .s_axi_ctrl_reg_awready       (s_axi_ctrl_reg_awready   ) ,
    .s_axi_ctrl_reg_awvalid       (s_axi_ctrl_reg_awvalid   ) ,
    .s_axi_ctrl_reg_bready        (s_axi_ctrl_reg_bready    ) ,
    .s_axi_ctrl_reg_bresp         (s_axi_ctrl_reg_bresp     ) ,
    .s_axi_ctrl_reg_bvalid        (s_axi_ctrl_reg_bvalid    ) ,
    .s_axi_ctrl_reg_rdata         (temp_s_axi_ctrl_reg_rdata     ) ,
    .s_axi_ctrl_reg_rready        (s_axi_ctrl_reg_rready    ) ,
    .s_axi_ctrl_reg_rresp         (s_axi_ctrl_reg_rresp     ) ,
    .s_axi_ctrl_reg_rvalid        (s_axi_ctrl_reg_rvalid    ) ,
    .s_axi_ctrl_reg_wdata         (s_axi_ctrl_reg_wdata     ) ,
    .s_axi_ctrl_reg_wready        (s_axi_ctrl_reg_wready    ) ,
    .s_axi_ctrl_reg_wstrb         (s_axi_ctrl_reg_wstrb     ) ,
    .s_axi_ctrl_reg_wvalid        (s_axi_ctrl_reg_wvalid    ) ,
    .m_axi_host_mem_araddr        (m_axi_host_mem_araddr    ) ,
    .m_axi_host_mem_arburst       (m_axi_host_mem_arburst   ) ,
    .m_axi_host_mem_arcache       (m_axi_host_mem_arcache   ) ,
    .m_axi_host_mem_arid          (m_axi_host_mem_arid [0]  ) ,//SR# 10394170
    .m_axi_host_mem_arlen         (m_axi_host_mem_arlen     ) ,
    .m_axi_host_mem_arlock        (m_axi_host_mem_arlock    ) ,
    .m_axi_host_mem_arprot        (m_axi_host_mem_arprot    ) ,
    .m_axi_host_mem_arqos         (m_axi_host_mem_arqos     ) ,
    .m_axi_host_mem_arready       (m_axi_host_mem_arready   ) ,
    .m_axi_host_mem_arregion      (m_axi_host_mem_arregion  ) ,
    .m_axi_host_mem_arsize        (m_axi_host_mem_arsize    ) ,
    .m_axi_host_mem_aruser        (                         ) ,
    .m_axi_host_mem_arvalid       (m_axi_host_mem_arvalid   ) ,
    .m_axi_host_mem_awaddr        (m_axi_host_mem_awaddr    ) ,
    .m_axi_host_mem_awburst       (m_axi_host_mem_awburst   ) ,
    .m_axi_host_mem_awcache       (m_axi_host_mem_awcache   ) ,
    .m_axi_host_mem_awid          (m_axi_host_mem_awid [0]  ) ,//SR# 10394170
    .m_axi_host_mem_awlen         (m_axi_host_mem_awlen     ) ,
    .m_axi_host_mem_awlock        (m_axi_host_mem_awlock    ) ,
    .m_axi_host_mem_awprot        (m_axi_host_mem_awprot    ) ,
    .m_axi_host_mem_awqos         (m_axi_host_mem_awqos     ) ,
    .m_axi_host_mem_awready       (m_axi_host_mem_awready   ) ,
    .m_axi_host_mem_awregion      (m_axi_host_mem_awregion  ) ,
    .m_axi_host_mem_awsize        (m_axi_host_mem_awsize    ) ,
    .m_axi_host_mem_awuser        (                         ) ,
    .m_axi_host_mem_awvalid       (m_axi_host_mem_awvalid   ) ,
    .m_axi_host_mem_bid           (m_axi_host_mem_bid [0]   ) ,//SR# 10394170
    .m_axi_host_mem_bready        (m_axi_host_mem_bready    ) ,
    .m_axi_host_mem_bresp         (m_axi_host_mem_bresp     ) ,
    .m_axi_host_mem_buser         (m_axi_host_mem_buser [0] ) ,//SR# 10394170
    .m_axi_host_mem_bvalid        (m_axi_host_mem_bvalid    ) ,
    .m_axi_host_mem_rdata         (m_axi_host_mem_rdata     ) ,
    .m_axi_host_mem_rid           (m_axi_host_mem_rid [0]   ) ,//SR# 10394170
    .m_axi_host_mem_rlast         (m_axi_host_mem_rlast     ) ,
    .m_axi_host_mem_rready        (m_axi_host_mem_rready    ) ,
    .m_axi_host_mem_rresp         (m_axi_host_mem_rresp     ) ,
    .m_axi_host_mem_ruser         (m_axi_host_mem_ruser [0] ) ,//SR# 10394170
    .m_axi_host_mem_rvalid        (m_axi_host_mem_rvalid    ) ,
    .m_axi_host_mem_wdata         (m_axi_host_mem_wdata     ) ,
    .m_axi_host_mem_wid           (                         ) ,
    .m_axi_host_mem_wlast         (m_axi_host_mem_wlast     ) ,
    .m_axi_host_mem_wready        (m_axi_host_mem_wready    ) ,
    .m_axi_host_mem_wstrb         (m_axi_host_mem_wstrb     ) ,
    .m_axi_host_mem_wuser         (m_axi_host_mem_wuser [0] ) ,//SR# 10394170
    .m_axi_host_mem_wvalid        (m_axi_host_mem_wvalid    ) ,
    .interrupt                    ( interrupt_i             )
  );
//==========================================
// Reset for hls_action
always @ (posedge ap_clk)
     hls_rst_n_q <= ap_rst_n;

//==========================================
// Context is not implemented
always @ (posedge ap_clk)
    if (~ap_rst_n)
        context_q <= 0;
//    else if (s_axi_ctrl_reg_wvalid && (s_axi_ctrl_reg_awaddr = ADDR_CTX_ID_REG )
//        context_q <= s_axi_ctrl_reg_wdata;


//==========================================
// Interrupt handshaking logic
always @ (posedge ap_clk)
     if (~ap_rst_n) begin
        interrupt_q          <= 1'b0;
        interrupt_wait_ack_q <= 1'b0;
     end
     else begin
         interrupt_wait_ack_q <= (interrupt_i & ~interrupt_q ) | (interrupt_wait_ack_q & ~interrupt_ack);
         interrupt_q          <= interrupt_i & (interrupt_q | ~interrupt_wait_ack_q);
     end

// Interrupt output signals
  // Generating interrupt pulse
assign  interrupt     = interrupt_i & ~interrupt_q;
  // use fixed interrupt source id '0x4' for HLS interrupts
  // (the high order bit of the source id is assigned by SNAP)
always @ (posedge ap_clk)
    if (~ap_rst_n) begin
        interrupt_src_hi <= 32'b0;
        interrupt_src_lo <= 32'b0;
    end
    else if (s_axi_ctrl_reg_wvalid  && (s_axi_ctrl_reg_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_HI))
        interrupt_src_hi <= s_axi_ctrl_reg_wdata;
    else if (s_axi_ctrl_reg_wvalid  && (s_axi_ctrl_reg_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_LO))
        interrupt_src_lo <= s_axi_ctrl_reg_wdata;

assign  interrupt_src = {interrupt_src_hi, interrupt_src_lo};
  // context ID
assign  interrupt_ctx = context_q;


//==========================================
//When read ACTION_TYPE and RELEASE_LEVEL, the return data is handled here. 
//hls_action will return RVALID (acknowledgement), RDATA=0
//and RDATA is ORed with this reg_rdata_hijack. 
always @ (posedge ap_clk)
    if (~ap_rst_n) begin
        reg_rdata_hijack <= 32'h0;
    end
    else if (s_axi_ctrl_reg_arvalid == 1'b1) begin
        if (s_axi_ctrl_reg_araddr == ADDR_ACTION_TYPE)
            reg_rdata_hijack <= `HLS_ACTION_TYPE;
        else if (s_axi_ctrl_reg_araddr == ADDR_RELEASE_LEVEL)
            reg_rdata_hijack <= `HLS_RELEASE_LEVEL;
        else
            reg_rdata_hijack <= 32'h0;
    end

assign s_axi_ctrl_reg_rdata = reg_rdata_hijack | temp_s_axi_ctrl_reg_rdata;

//==========================================
// Driving context ID to host memory interface
assign  m_axi_host_mem_aruser = context_q;
assign  m_axi_host_mem_awuser = context_q;

// Driving the higher ID fields to 0.
assign  m_axi_host_mem_arid  [ `IDW-1 : 1 ] = 'b0;
assign  m_axi_host_mem_awid  [ `IDW-1 : 1 ] = 'b0;
//assign  m_axi_host_mem_wuser [ `AXI_WUSER-1 : 1 ] = 'b0;


`ifdef ENABLE_AXI_CARD_MEM
assign m_axi_card_mem0_araddr = temp_card_mem0_araddr[`AXI_CARD_MEM_ADDR_WIDTH-1:0];
assign m_axi_card_mem0_awaddr = temp_card_mem0_awaddr[`AXI_CARD_MEM_ADDR_WIDTH-1:0];
assign m_axi_card_mem0_arid  [ `AXI_CARD_MEM_ID_WIDTH-1 : 1 ] = 'b0;
assign m_axi_card_mem0_awid  [ `AXI_CARD_MEM_ID_WIDTH-1 : 1 ] = 'b0;
`endif
endmodule
