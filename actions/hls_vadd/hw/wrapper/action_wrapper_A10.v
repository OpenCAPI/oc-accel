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
//`include "snap_global_vars.v"

module action_wrapper # (
                INT_BITS = 64,
                CTXW = 9,
                IDW = 1,
                AXI_DATAW = 1024, 
                AXI_ARUSER = 9,
                AXI_AWUSER = 9,
                AXI_RUSER = 1,
                AXI_BUSER = 1,
                AXI_WUSER = 1
                )
(
   input                                   clk                   ,
   input                                   resetn                 ,
   output                                  interrupt                ,
   output [63:0]                           interrupt_src            ,
   output [CTXW-1:0]                       interrupt_ctx            ,
   input                                   interrupt_ack            ,
    //
    // AXI Control Register interface
   input [ 31 : 0]                         s_axi_ctrl_reg_araddr    ,
   output                                  s_axi_ctrl_reg_arready   ,
   input                                   s_axi_ctrl_reg_arvalid   ,
   input [ 31 : 0]                         s_axi_ctrl_reg_awaddr    ,
   output                                  s_axi_ctrl_reg_awready   ,
   input                                   s_axi_ctrl_reg_awvalid   ,
   input                                   s_axi_ctrl_reg_bready    ,
   output [ 1 : 0]                         s_axi_ctrl_reg_bresp     ,
   output                                  s_axi_ctrl_reg_bvalid    ,
   output [ 31 : 0]                        s_axi_ctrl_reg_rdata     ,
   input                                   s_axi_ctrl_reg_rready    ,
   output [ 1 : 0]                         s_axi_ctrl_reg_rresp     ,
   output                                  s_axi_ctrl_reg_rvalid    ,
   input [ 31 : 0]                         s_axi_ctrl_reg_wdata     ,
   output                                  s_axi_ctrl_reg_wready    ,
   input [ 3 : 0]                          s_axi_ctrl_reg_wstrb     ,
   input                                   s_axi_ctrl_reg_wvalid    ,
    //
    // AXI Host Memory inputterface
   output [ 63 : 0]                        m_axi_host_mem_araddr    ,
   output [ 1 : 0]                         m_axi_host_mem_arburst   ,
   output [ 3 : 0]                         m_axi_host_mem_arcache   ,
   output [ IDW-1 : 0]                     m_axi_host_mem_arid      ,
   output [ 7 : 0]                         m_axi_host_mem_arlen     ,
   output [ 1 : 0]                         m_axi_host_mem_arlock    ,
   output [ 2 : 0]                         m_axi_host_mem_arprot    ,
   output [ 3 : 0]                         m_axi_host_mem_arqos     ,
   input                                   m_axi_host_mem_arready   ,
   output [ 3 : 0]                         m_axi_host_mem_arregion  ,
   output [ 2 : 0]                         m_axi_host_mem_arsize    ,
   output [ AXI_ARUSER-1 : 0]              m_axi_host_mem_aruser    ,
   output                                  m_axi_host_mem_arvalid   ,
   output [ 63 : 0]                        m_axi_host_mem_awaddr    ,
   output [ 1 : 0]                         m_axi_host_mem_awburst   ,
   output [ 3 : 0]                         m_axi_host_mem_awcache   ,
   output [ IDW-1 : 0]                     m_axi_host_mem_awid      ,
   output [ 7 : 0]                         m_axi_host_mem_awlen     ,
   output [ 1 : 0]                         m_axi_host_mem_awlock    ,
   output [ 2 : 0]                         m_axi_host_mem_awprot    ,
   output [ 3 : 0]                         m_axi_host_mem_awqos     ,
   input                                   m_axi_host_mem_awready   ,
   output [ 3 : 0]                         m_axi_host_mem_awregion  ,
   output [ 2 : 0]                         m_axi_host_mem_awsize    ,
   output [AXI_AWUSER-1 : 0]               m_axi_host_mem_awuser    ,
   output                                  m_axi_host_mem_awvalid   ,
   input [ IDW-1 : 0]                      m_axi_host_mem_bid       ,
   output                                  m_axi_host_mem_bready    ,
   input [ 1 : 0]                          m_axi_host_mem_bresp     ,
   input [ AXI_BUSER-1 : 0]                m_axi_host_mem_buser     ,
   input                                   m_axi_host_mem_bvalid    ,
   input [ AXI_DATAW-1 : 0]                m_axi_host_mem_rdata     ,
   input [ IDW-1 : 0]                      m_axi_host_mem_rid       ,
   input                                   m_axi_host_mem_rlast     ,
   output                                  m_axi_host_mem_rready    ,
   input [ 1 : 0]                          m_axi_host_mem_rresp     ,
   input [ AXI_RUSER-1 : 0]                m_axi_host_mem_ruser     ,
   input                                   m_axi_host_mem_rvalid    ,
   output [ AXI_DATAW-1 : 0]               m_axi_host_mem_wdata     ,
   output                                  m_axi_host_mem_wlast     ,
   input                                   m_axi_host_mem_wready    ,
   output [(AXI_DATAW/8)-1 : 0]            m_axi_host_mem_wstrb     ,
   output [ AXI_WUSER-1 : 0]               m_axi_host_mem_wuser     ,
   output                                  m_axi_host_mem_wvalid
    );

localparam ACTION_TYPE   = 32'h10143009;
localparam RELEASE_LEVEL = 32'h00000001;


// Use some address far away
localparam ADDR_ACTION_TYPE                  = 32'h10010;
localparam ADDR_RELEASE_LEVEL                = 32'h10014;
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_LO = 32'h10018;
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_HI = 32'h1001C;
localparam ADDR_RETURN_CODE                  = 32'h10020;



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


wire [ 63 : 0]                        hls_action_araddr    ;
wire [ 1 : 0]                         hls_action_arburst   ;
wire [ 3 : 0]                         hls_action_arcache   ;
wire [ 0 : 0]                         hls_action_arid      ;
wire [ 7 : 0]                         hls_action_arlen     ;
wire [ 1 : 0]                         hls_action_arlock    ;
wire [ 2 : 0]                         hls_action_arprot    ;
wire [ 3 : 0]                         hls_action_arqos     ;
wire                                  hls_action_arready   ;
wire [ 3 : 0]                         hls_action_arregion  ;
wire [ 2 : 0]                         hls_action_arsize    ;
wire [ 0 : 0]                         hls_action_aruser    ;
wire                                  hls_action_arvalid   ;
wire [ 63 : 0]                        hls_action_awaddr    ;
wire [ 1 : 0]                         hls_action_awburst   ;
wire [ 3 : 0]                         hls_action_awcache   ;
wire [ 0 : 0]                         hls_action_awid      ;
wire [ 7 : 0]                         hls_action_awlen     ;
wire [ 1 : 0]                         hls_action_awlock    ;
wire [ 2 : 0]                         hls_action_awprot    ;
wire [ 3 : 0]                         hls_action_awqos     ;
wire                                  hls_action_awready   ;
wire [ 3 : 0]                         hls_action_awregion  ;
wire [ 2 : 0]                         hls_action_awsize    ;
wire [ 0 : 0]                         hls_action_awuser    ;
wire                                  hls_action_awvalid   ;
wire[ 0 : 0]                          hls_action_bid       ;
wire                                  hls_action_bready    ;
wire[ 1 : 0]                          hls_action_bresp     ;
wire[ 0 : 0]                          hls_action_buser     ;
wire                                  hls_action_bvalid    ;
wire[ 31 : 0]                         hls_action_rdata     ;
wire[ 0 : 0]                          hls_action_rid       ;
wire                                  hls_action_rlast     ;
wire                                  hls_action_rready    ;
wire[ 1 : 0]                          hls_action_rresp     ;
wire[ 0 : 0]                          hls_action_ruser     ;
wire                                  hls_action_rvalid    ;
wire [ 31 : 0]                        hls_action_wdata     ;
wire                                  hls_action_wlast     ;
wire                                  hls_action_wready    ;
wire [(32/8)-1 : 0]                   hls_action_wstrb     ;
wire [ 0 : 0]                         hls_action_wuser     ;
wire                                  hls_action_wvalid    ;



 axi_dwidth_converter axi_dwidth_converter_act2snap (
      .s_axi_aclk        ( clk                   ) ,
      .s_axi_aresetn     ( resetn                ) ,
      .s_axi_awaddr      ( hls_action_awaddr    ) ,
      .s_axi_awid        ( hls_action_awid      ) ,
      .s_axi_awlen       ( hls_action_awlen     ) ,
      .s_axi_awsize      ( hls_action_awsize    ) ,
      .s_axi_awburst     ( hls_action_awburst   ) ,
      .s_axi_awlock      ( hls_action_awlock    ) ,
      .s_axi_awcache     ( hls_action_awcache   ) ,
      .s_axi_awprot      ( hls_action_awprot    ) ,
      .s_axi_awregion    ( hls_action_awregion  ) ,
      .s_axi_awqos       ( hls_action_awqos     ) ,
      .s_axi_awvalid     ( hls_action_awvalid   ) ,
      .s_axi_awready     ( hls_action_awready   ) ,
      .s_axi_wdata       ( hls_action_wdata     ) ,
      .s_axi_wstrb       ( hls_action_wstrb     ) ,
      .s_axi_wlast       ( hls_action_wlast     ) ,
      .s_axi_wvalid      ( hls_action_wvalid    ) ,
      .s_axi_wready      ( hls_action_wready    ) ,
      .s_axi_bresp       ( hls_action_bresp     ) ,
      .s_axi_bvalid      ( hls_action_bvalid    ) ,
      .s_axi_bid         ( hls_action_bid       ) ,
      .s_axi_bready      ( hls_action_bready    ) ,
      .s_axi_araddr      ( hls_action_araddr    ) ,
      .s_axi_arid        ( hls_action_arid      ) ,
      .s_axi_arlen       ( hls_action_arlen     ) ,
      .s_axi_arsize      ( hls_action_arsize    ) ,
      .s_axi_arburst     ( hls_action_arburst   ) ,
      .s_axi_arlock      ( hls_action_arlock    ) ,
      .s_axi_arcache     ( hls_action_arcache   ) ,
      .s_axi_arprot      ( hls_action_arprot    ) ,
      .s_axi_arregion    ( hls_action_arregion  ) ,
      .s_axi_arqos       ( hls_action_arqos     ) ,
      .s_axi_arvalid     ( hls_action_arvalid   ) ,
      .s_axi_arready     ( hls_action_arready   ) ,
      .s_axi_rdata       ( hls_action_rdata     ) ,
      .s_axi_rid         ( hls_action_rid       ) ,
      .s_axi_rresp       ( hls_action_rresp     ) ,
      .s_axi_rlast       ( hls_action_rlast     ) ,
      .s_axi_rvalid      ( hls_action_rvalid    ) ,
      .s_axi_rready      ( hls_action_rready    ) ,

      .m_axi_aclk        ( clk                 ) ,
      .m_axi_aresetn     ( ~resetn             ) ,
      .m_axi_awaddr      ( m_axi_host_mem_awaddr   ) ,
      .m_axi_awlen       ( m_axi_host_mem_awlen    ) ,
      .m_axi_awsize      ( m_axi_host_mem_awsize   ) ,
      .m_axi_awburst     ( m_axi_host_mem_awburst  ) ,
      .m_axi_awlock      ( m_axi_host_mem_awlock   ) ,
      .m_axi_awcache     ( m_axi_host_mem_awcache  ) ,
      .m_axi_awprot      ( m_axi_host_mem_awprot   ) ,
      .m_axi_awregion    ( m_axi_host_mem_awregion ) ,
      .m_axi_awqos       ( m_axi_host_mem_awqos    ) ,
      .m_axi_awvalid     ( m_axi_host_mem_awvalid  ) ,
      .m_axi_awready     ( m_axi_host_mem_awready  ) ,
      .m_axi_wdata       ( m_axi_host_mem_wdata    ) ,
      .m_axi_wstrb       ( m_axi_host_mem_wstrb    ) ,
      .m_axi_wlast       ( m_axi_host_mem_wlast    ) ,
      .m_axi_wvalid      ( m_axi_host_mem_wvalid   ) ,
      .m_axi_wready      ( m_axi_host_mem_wready   ) ,
      .m_axi_bresp       ( m_axi_host_mem_bresp    ) ,
      .m_axi_bvalid      ( m_axi_host_mem_bvalid   ) ,
      .m_axi_bready      ( m_axi_host_mem_bready   ) ,
      .m_axi_araddr      ( m_axi_host_mem_araddr   ) ,
      .m_axi_arlen       ( m_axi_host_mem_arlen    ) ,
      .m_axi_arsize      ( m_axi_host_mem_arsize   ) ,
      .m_axi_arburst     ( m_axi_host_mem_arburst  ) ,
      .m_axi_arlock      ( m_axi_host_mem_arlock   ) ,
      .m_axi_arcache     ( m_axi_host_mem_arcache  ) ,
      .m_axi_arprot      ( m_axi_host_mem_arprot   ) ,
      .m_axi_arregion    ( m_axi_host_mem_arregion ) ,
      .m_axi_arqos       ( m_axi_host_mem_arqos    ) ,
      .m_axi_arvalid     ( m_axi_host_mem_arvalid  ) ,
      .m_axi_arready     ( m_axi_host_mem_arready  ) ,
      .m_axi_rdata       ( m_axi_host_mem_rdata    ) ,
      .m_axi_rresp       ( m_axi_host_mem_rresp    ) ,
      .m_axi_rlast       ( m_axi_host_mem_rlast    ) ,
      .m_axi_rvalid      ( m_axi_host_mem_rvalid   ) ,
      .m_axi_rready      ( m_axi_host_mem_rready   )
) ; // axi_dwidth_converter
 
 //vadd hls_action_0 # (.C_S_AXI_CONTROL_ADDR_WIDTH (32) )
 vadd hls_action_0 
    (
    .ap_clk                       ( clk                   ) ,
    .ap_rst_n                     ( hls_rst_n_q             ) ,
    
    .s_axi_control_araddr        (s_axi_ctrl_reg_araddr    ) ,
    .s_axi_control_arready       (s_axi_ctrl_reg_arready   ) ,
    .s_axi_control_arvalid       (s_axi_ctrl_reg_arvalid   ) ,
    .s_axi_control_awaddr        (s_axi_ctrl_reg_awaddr    ) ,
    .s_axi_control_awready       (s_axi_ctrl_reg_awready   ) ,
    .s_axi_control_awvalid       (s_axi_ctrl_reg_awvalid   ) ,
    .s_axi_control_bready        (s_axi_ctrl_reg_bready    ) ,
    .s_axi_control_bresp         (s_axi_ctrl_reg_bresp     ) ,
    .s_axi_control_bvalid        (s_axi_ctrl_reg_bvalid    ) ,
    .s_axi_control_rdata         (temp_s_axi_ctrl_reg_rdata     ) ,
    .s_axi_control_rready        (s_axi_ctrl_reg_rready    ) ,
    .s_axi_control_rresp         (s_axi_ctrl_reg_rresp     ) ,
    .s_axi_control_rvalid        (s_axi_ctrl_reg_rvalid    ) ,
    .s_axi_control_wdata         (s_axi_ctrl_reg_wdata     ) ,
    .s_axi_control_wready        (s_axi_ctrl_reg_wready    ) ,
    .s_axi_control_wstrb         (s_axi_ctrl_reg_wstrb     ) ,
    .s_axi_control_wvalid        (s_axi_ctrl_reg_wvalid    ) ,
    .m_axi_gmem_araddr        (hls_action_araddr    ) ,
    .m_axi_gmem_arburst       (hls_action_arburst   ) ,
    .m_axi_gmem_arcache       (hls_action_arcache   ) ,
    .m_axi_gmem_arid          (hls_action_arid      ) ,//SR# 10394170
    .m_axi_gmem_arlen         (hls_action_arlen     ) ,
    .m_axi_gmem_arlock        (hls_action_arlock    ) ,
    .m_axi_gmem_arprot        (hls_action_arprot    ) ,
    .m_axi_gmem_arqos         (hls_action_arqos     ) ,
    .m_axi_gmem_arready       (hls_action_arready   ) ,
    .m_axi_gmem_arregion      (hls_action_arregion  ) ,
    .m_axi_gmem_arsize        (hls_action_arsize    ) ,
    .m_axi_gmem_aruser        (hls_action_aruser    ) ,
    .m_axi_gmem_arvalid       (hls_action_arvalid   ) ,
    .m_axi_gmem_awaddr        (hls_action_awaddr    ) ,
    .m_axi_gmem_awburst       (hls_action_awburst   ) ,
    .m_axi_gmem_awcache       (hls_action_awcache   ) ,
    .m_axi_gmem_awid          (hls_action_awid      ) ,//SR# 10394170
    .m_axi_gmem_awlen         (hls_action_awlen     ) ,
    .m_axi_gmem_awlock        (hls_action_awlock    ) ,
    .m_axi_gmem_awprot        (hls_action_awprot    ) ,
    .m_axi_gmem_awqos         (hls_action_awqos     ) ,
    .m_axi_gmem_awready       (hls_action_awready   ) ,
    .m_axi_gmem_awregion      (hls_action_awregion  ) ,
    .m_axi_gmem_awsize        (hls_action_awsize    ) ,
    .m_axi_gmem_awuser        (hls_action_awuser    ) ,
    .m_axi_gmem_awvalid       (hls_action_awvalid   ) ,
    .m_axi_gmem_bid           (hls_action_bid [0]   ) ,//SR# 10394170
    .m_axi_gmem_bready        (hls_action_bready    ) ,
    .m_axi_gmem_bresp         (hls_action_bresp     ) ,
    .m_axi_gmem_buser         (hls_action_buser [0] ) ,//SR# 10394170
    .m_axi_gmem_bvalid        (hls_action_bvalid    ) ,
    .m_axi_gmem_rdata         (hls_action_rdata     ) ,
    .m_axi_gmem_rid           (hls_action_rid [0]   ) ,//SR# 10394170
    .m_axi_gmem_rlast         (hls_action_rlast     ) ,
    .m_axi_gmem_rready        (hls_action_rready    ) ,
    .m_axi_gmem_rresp         (hls_action_rresp     ) ,
    .m_axi_gmem_ruser         (hls_action_ruser [0] ) ,//SR# 10394170
    .m_axi_gmem_rvalid        (hls_action_rvalid    ) ,
    .m_axi_gmem_wdata         (hls_action_wdata     ) ,
    .m_axi_gmem_wid           (hls_action_wid       ) ,
    .m_axi_gmem_wlast         (hls_action_wlast     ) ,
    .m_axi_gmem_wready        (hls_action_wready    ) ,
    .m_axi_gmem_wstrb         (hls_action_wstrb     ) ,
    .m_axi_gmem_wuser         (hls_action_wuser [0] ) ,//SR# 10394170
    .m_axi_gmem_wvalid        (hls_action_wvalid    ) ,
    .interrupt                    (interrupt_i          )
  );
//==========================================
// Reset for hls_action
always @ (posedge clk)
     hls_rst_n_q <= resetn;

//==========================================
// Context is not implemented
always @ (posedge clk)
    if (~resetn)
        context_q <= 0;
//    else if (s_axi_ctrl_reg_wvalid && (s_axi_ctrl_reg_awaddr = ADDR_CTX_ID_REG )
//        context_q <= s_axi_ctrl_reg_wdata;


//==========================================
// Interrupt handshaking logic
always @ (posedge clk)
     if (~resetn) begin
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
always @ (posedge clk)
    if (~resetn) begin
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
always @ (posedge clk)
    if (~resetn) begin
        reg_rdata_hijack <= 32'h0;
    end
    else if (s_axi_ctrl_reg_arvalid == 1'b1) begin
        if (s_axi_ctrl_reg_araddr == ADDR_ACTION_TYPE)
            reg_rdata_hijack <= ACTION_TYPE;
        else if (s_axi_ctrl_reg_araddr == ADDR_RELEASE_LEVEL)
            reg_rdata_hijack <= RELEASE_LEVEL;
        else
            reg_rdata_hijack <= 32'h0;
    end

assign s_axi_ctrl_reg_rdata = reg_rdata_hijack | temp_s_axi_ctrl_reg_rdata;

//==========================================
// Driving context ID to host memory interface
assign  m_axi_host_mem_aruser = context_q;
assign  m_axi_host_mem_awuser = context_q;

// Driving the higher ID fields to 0.
generate if(IDW > 1)
begin:high_hid_fields_driver
    assign  m_axi_host_mem_arid  [ IDW-1 : 1 ] = 'b0;
    assign  m_axi_host_mem_awid  [ IDW-1 : 1 ] = 'b0;
end
endgenerate
//assign  m_axi_host_mem_wuser [ `AXI_WUSER-1 : 1 ] = 'b0;


endmodule
