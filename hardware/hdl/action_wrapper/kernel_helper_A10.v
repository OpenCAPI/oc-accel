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

// kernel helper will handel some special registers

module kernel_helper # (
              parameter  KERNEL_TYPE      = 32'h0000ABCD,
              parameter  RELEASE_LEVEL    = 32'h00000001,
              parameter  SPECIAL_REG_BASE = 32'h00020000,
              parameter  INT_BITS = 64,
              parameter  CTXW = 9,
              // Kernel function module's AXILITE width
              parameter  C_S_AXI_CONTROL_DATA_WIDTH = 32,
              parameter  C_S_AXI_CONTROL_ADDR_WIDTH = 32,
              // Kernel function module's AXIMM width
              parameter    C_M_AXI_GMEM_ID_WIDTH = 1     ,
              parameter    C_M_AXI_GMEM_ADDR_WIDTH = 64  ,
              parameter    C_M_AXI_GMEM_DATA_WIDTH = 1024,
              parameter    C_M_AXI_GMEM_AWUSER_WIDTH = 1 ,
              parameter    C_M_AXI_GMEM_ARUSER_WIDTH = 1 ,
              parameter    C_M_AXI_GMEM_WUSER_WIDTH = 1  ,
              parameter    C_M_AXI_GMEM_RUSER_WIDTH = 1  ,
              parameter    C_M_AXI_GMEM_BUSER_WIDTH = 1   

              )
(
   input                                   clk                      ,
   input                                   resetn                   ,

   input                                   interrupt_i              , //From kernel_ip
   output                                  interrupt_req            ,
   output [63:0]                           interrupt_src            ,
   output [CTXW-1:0]                       interrupt_ctx            ,
   input                                   interrupt_ack            ,

   // AXI Control Register interface Input, coming from infrastructure
   // Fixed port width
   // i2h = infrastructrure to helper
   input                                   s_axilite_i2h_awvalid   ,
   output                                  s_axilite_i2h_awready   ,
   input [ 31 : 0]                         s_axilite_i2h_awaddr    ,
   input                                   s_axilite_i2h_wvalid    ,
   output                                  s_axilite_i2h_wready    ,
   input [ 31 : 0]                         s_axilite_i2h_wdata     ,
   input [ 3 : 0]                          s_axilite_i2h_wstrb     ,
   input                                   s_axilite_i2h_arvalid   ,
   output                                  s_axilite_i2h_arready   ,
   input [ 31 : 0]                         s_axilite_i2h_araddr    ,
   output                                  s_axilite_i2h_rvalid    ,
   input                                   s_axilite_i2h_rready    ,
   output [ 31 : 0]                        s_axilite_i2h_rdata     ,
   output [ 1 : 0]                         s_axilite_i2h_rresp     ,
   output                                  s_axilite_i2h_bvalid    ,
   input                                   s_axilite_i2h_bready    ,
   output [ 1 : 0]                         s_axilite_i2h_bresp     ,

   // AXI Control Register interface Output, to kernel_ip
   // Port width adjustable
   // Usually DATA_WIDTH is fixed to 32
   // But ADDR_WIDTH may be less than 32 sometimes.
   // h2k = helper to kernel
   output                                       s_axilite_h2k_AWVALID ,
   input                                        s_axilite_h2k_AWREADY ,
   output[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]     s_axilite_h2k_AWADDR  ,
   output                                       s_axilite_h2k_WVALID  ,
   input                                        s_axilite_h2k_WREADY  ,
   output[C_S_AXI_CONTROL_DATA_WIDTH - 1:0]     s_axilite_h2k_WDATA   ,
   output[(C_S_AXI_CONTROL_DATA_WIDTH/8) - 1:0] s_axilite_h2k_WSTRB   ,
   output                                       s_axilite_h2k_ARVALID ,
   input                                        s_axilite_h2k_ARREADY ,
   output[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]     s_axilite_h2k_ARADDR  ,
   input                                        s_axilite_h2k_RVALID  ,
   output                                       s_axilite_h2k_RREADY  ,
   input  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0]    s_axilite_h2k_RDATA   ,
   input  [1:0]                                 s_axilite_h2k_RRESP   ,
   input                                        s_axilite_h2k_BVALID  ,
   output                                       s_axilite_h2k_BREADY  ,
   input  [1:0]                                 s_axilite_h2k_BRESP   ,

   // AXIMM gmem interface input, from kernel_ip
   // k2h = kernel to helper
    input                                     m_axi_k2h_AWVALID  ,
    output                                    m_axi_k2h_AWREADY  ,
    input   [C_M_AXI_GMEM_ADDR_WIDTH - 1:0]   m_axi_k2h_AWADDR   ,
    input   [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_k2h_AWID     ,
    input   [7:0]                             m_axi_k2h_AWLEN    ,
    input   [2:0]                             m_axi_k2h_AWSIZE   ,
    input   [1:0]                             m_axi_k2h_AWBURST  ,
    input   [1:0]                             m_axi_k2h_AWLOCK   ,
    input   [3:0]                             m_axi_k2h_AWCACHE  ,
    input   [2:0]                             m_axi_k2h_AWPROT   ,
    input   [3:0]                             m_axi_k2h_AWQOS    ,
    input   [3:0]                             m_axi_k2h_AWREGION ,
    input   [C_M_AXI_GMEM_AWUSER_WIDTH - 1:0] m_axi_k2h_AWUSER   ,
    input                                     m_axi_k2h_WVALID   ,
    output                                    m_axi_k2h_WREADY   ,
    input   [C_M_AXI_GMEM_DATA_WIDTH - 1:0]   m_axi_k2h_WDATA    ,
    input   [(C_M_AXI_GMEM_DATA_WIDTH/8) - 1:0]  m_axi_k2h_WSTRB    ,
    input                                     m_axi_k2h_WLAST    ,
    input   [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_k2h_WID      ,
    input   [C_M_AXI_GMEM_WUSER_WIDTH - 1:0]  m_axi_k2h_WUSER    ,
    input                                     m_axi_k2h_ARVALID  ,
    output                                    m_axi_k2h_ARREADY  ,
    input   [C_M_AXI_GMEM_ADDR_WIDTH - 1:0]   m_axi_k2h_ARADDR   ,
    input   [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_k2h_ARID     ,
    input   [7:0]                             m_axi_k2h_ARLEN    ,
    input   [2:0]                             m_axi_k2h_ARSIZE   ,
    input   [1:0]                             m_axi_k2h_ARBURST  ,
    input   [1:0]                             m_axi_k2h_ARLOCK   ,
    input   [3:0]                             m_axi_k2h_ARCACHE  ,
    input   [2:0]                             m_axi_k2h_ARPROT   ,
    input   [3:0]                             m_axi_k2h_ARQOS    ,
    input   [3:0]                             m_axi_k2h_ARREGION ,
    input   [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_k2h_ARUSER   ,
    output                                    m_axi_k2h_RVALID   ,
    input                                     m_axi_k2h_RREADY   ,
    output [C_M_AXI_GMEM_DATA_WIDTH - 1:0]    m_axi_k2h_RDATA    ,
    output                                    m_axi_k2h_RLAST    ,
    output [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_k2h_RID      ,
    output [C_M_AXI_GMEM_RUSER_WIDTH - 1:0]   m_axi_k2h_RUSER    ,
    output [1:0]                              m_axi_k2h_RRESP    ,
    output                                    m_axi_k2h_BVALID   ,
    input                                     m_axi_k2h_BREADY   ,
    output [1:0]                              m_axi_k2h_BRESP    ,
    output [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_k2h_BID      ,
    output [C_M_AXI_GMEM_BUSER_WIDTH - 1:0]   m_axi_k2h_BUSER    ,

    // h2i = helper to infrastructure
    
    output                                    m_axi_h2i_awvalid  ,
    input                                     m_axi_h2i_awready  ,
    output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0]   m_axi_h2i_awaddr   ,
    output  [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_h2i_awid     ,
    output  [7:0]                             m_axi_h2i_awlen    ,
    output  [2:0]                             m_axi_h2i_awsize   ,
    output  [1:0]                             m_axi_h2i_awburst  ,
    output  [1:0]                             m_axi_h2i_awlock   ,
    output  [3:0]                             m_axi_h2i_awcache  ,
    output  [2:0]                             m_axi_h2i_awprot   ,
    output  [3:0]                             m_axi_h2i_awqos    ,
    output  [3:0]                             m_axi_h2i_awregion ,
    output  [CTXW - 1:0]                      m_axi_h2i_awuser   , //Controlled by helper
    output                                    m_axi_h2i_wvalid   ,
    input                                     m_axi_h2i_wready   ,
    output  [C_M_AXI_GMEM_DATA_WIDTH - 1:0]   m_axi_h2i_wdata    ,
    output  [(C_M_AXI_GMEM_DATA_WIDTH/8) - 1:0]  m_axi_h2i_wstrb    ,
    output                                    m_axi_h2i_wlast    ,
    output  [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_h2i_wid      ,
    output  [0:0]                             m_axi_h2i_wuser    ,
    output                                    m_axi_h2i_arvalid  ,
    input                                     m_axi_h2i_arready  ,
    output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0]   m_axi_h2i_araddr   ,
    output  [C_M_AXI_GMEM_ID_WIDTH - 1:0]     m_axi_h2i_arid     ,
    output  [7:0]                             m_axi_h2i_arlen    ,
    output  [2:0]                             m_axi_h2i_arsize   ,
    output  [1:0]                             m_axi_h2i_arburst  ,
    output  [1:0]                             m_axi_h2i_arlock   ,
    output  [3:0]                             m_axi_h2i_arcache  ,
    output  [2:0]                             m_axi_h2i_arprot   ,
    output  [3:0]                             m_axi_h2i_arqos    ,
    output  [3:0]                             m_axi_h2i_arregion ,
    output  [CTXW - 1:0]                      m_axi_h2i_aruser   ,//Controlled by helper
    input                                     m_axi_h2i_rvalid   ,
    output                                    m_axi_h2i_rready   ,
    input  [C_M_AXI_GMEM_DATA_WIDTH - 1:0]    m_axi_h2i_rdata    ,
    input                                     m_axi_h2i_rlast    ,
    input  [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_h2i_rid      ,
    input  [0:0]                              m_axi_h2i_ruser    ,
    input  [1:0]                              m_axi_h2i_rresp    ,
    input                                     m_axi_h2i_bvalid   ,
    output                                    m_axi_h2i_bready   ,
    input  [1:0]                              m_axi_h2i_bresp    ,
    input  [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_h2i_bid      ,
    input  [0:0]                              m_axi_h2i_buser

    );
// Use some address @ 128KB base
// The whole configuration address space for one kernel is 256KB
localparam ADDR_KERNEL_TYPE                  = 32'h10 + SPECIAL_REG_BASE; //Read Only
localparam ADDR_RELEASE_LEVEL                = 32'h14 + SPECIAL_REG_BASE; //Read Only
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_LO = 32'h18 + SPECIAL_REG_BASE; //Write Only
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_HI = 32'h1C + SPECIAL_REG_BASE; //Write Only
localparam ADDR_CONTEXT                      = 32'h20 + SPECIAL_REG_BASE; //Read-Write



reg [31:0] reg_context;
reg [31:0] reg_interrupt_src_hi;
reg [31:0] reg_interrupt_src_lo;
reg interrupt_q;
reg interrupt_wait_ack_q;



//==========================================
always @ (posedge clk)
    if (~resetn)
        reg_context      <= 32'h0;
    else if (s_axilite_i2h_wvalid && (s_axilite_i2h_awaddr == ADDR_CONTEXT ))
        reg_context      <= s_axilite_i2h_wdata;


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
assign  interrupt_req     = interrupt_i & ~interrupt_q;
  // use fixed interrupt source id '0x4' for HLS interrupts
  // (the high order bit of the source id is assigned by SNAP)
always @ (posedge clk)
    if (~resetn) begin
        reg_interrupt_src_hi <= 32'b0;
        reg_interrupt_src_lo <= 32'b0;
    end
    else if (s_axilite_i2h_wvalid  && (s_axilite_i2h_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_HI))
        reg_interrupt_src_hi <= s_axilite_i2h_wdata;
    else if (s_axilite_i2h_wvalid  && (s_axilite_i2h_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_LO))
        reg_interrupt_src_lo <= s_axilite_i2h_wdata;

assign  interrupt_src = {reg_interrupt_src_hi, reg_interrupt_src_lo};
  // context ID
assign  interrupt_ctx = reg_context;


//==========================================
//When read KERNEL_TYPE and RELEASE_LEVEL, the return data is handled here. 
//hls_action will return RVALID (acknowledgement), RDATA=0
//and RDATA is ORed with this reg_rdata_hijack. 
reg  [31:0] reg_rdata_hijack; //This will be ORed with the return data of hls_action
always @ (posedge clk)
    if (~resetn) begin
        reg_rdata_hijack <= 32'h0;
    end
    else if (s_axilite_i2h_arvalid == 1'b1) begin
        if (s_axilite_i2h_araddr == ADDR_KERNEL_TYPE)
            reg_rdata_hijack <= KERNEL_TYPE;
        else if (s_axilite_i2h_araddr == ADDR_RELEASE_LEVEL)
            reg_rdata_hijack <= RELEASE_LEVEL;
        else if (s_axilite_i2h_araddr == ADDR_CONTEXT)
            reg_rdata_hijack <= reg_context;
        else
            reg_rdata_hijack <= 32'h0;
    end

// Bypass most of the connections

assign /*  output*/  s_axilite_h2k_AWVALID = s_axilite_i2h_awvalid ;
assign /*  input */  s_axilite_i2h_awready = s_axilite_h2k_AWREADY ;
assign /*  output*/  s_axilite_h2k_AWADDR  = s_axilite_i2h_awaddr[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] ; //Handle the mismatch of addr width
assign /*  output*/  s_axilite_h2k_WVALID  = s_axilite_i2h_wvalid ;
assign /*  input */  s_axilite_i2h_wready  = s_axilite_h2k_WREADY ;
assign /*  output*/  s_axilite_h2k_WDATA   = s_axilite_i2h_wdata ;
assign /*  output*/  s_axilite_h2k_WSTRB   = s_axilite_i2h_wstrb ;
assign /*  output*/  s_axilite_h2k_ARVALID = s_axilite_i2h_arvalid ;
assign /*  input */  s_axilite_i2h_arready = s_axilite_h2k_ARREADY ;
assign /*  output*/  s_axilite_h2k_ARADDR  = s_axilite_i2h_araddr [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] ; //Handle the mismatch of addr width
assign /*  input */  s_axilite_i2h_rvalid  = s_axilite_h2k_RVALID ;
assign /*  output*/  s_axilite_h2k_RREADY  = s_axilite_i2h_rready ;
assign /*  input */  s_axilite_i2h_rdata   = s_axilite_h2k_RDATA | reg_rdata_hijack ;
assign /*  input */  s_axilite_i2h_rresp   = s_axilite_h2k_RRESP ;
assign /*  input */  s_axilite_i2h_bvalid  = s_axilite_h2k_BVALID ;
assign /*  output*/  s_axilite_h2k_BREADY  = s_axilite_i2h_bready ;
assign /*  input */  s_axilite_i2h_bresp   = s_axilite_h2k_BRESP ;


assign    /*input */  m_axi_h2i_awvalid    = m_axi_k2h_AWVALID ;
assign    /*output*/  m_axi_k2h_AWREADY    = m_axi_h2i_awready ;
assign    /*input */  m_axi_h2i_awaddr     = m_axi_k2h_AWADDR ;
assign    /*input */  m_axi_h2i_awid       = m_axi_k2h_AWID ;
assign    /*input */  m_axi_h2i_awlen      = m_axi_k2h_AWLEN ;
assign    /*input */  m_axi_h2i_awsize     = m_axi_k2h_AWSIZE ;
assign    /*input */  m_axi_h2i_awburst    = m_axi_k2h_AWBURST ;
assign    /*input */  m_axi_h2i_awlock     = m_axi_k2h_AWLOCK ;
assign    /*input */  m_axi_h2i_awcache    = m_axi_k2h_AWCACHE ;
assign    /*input */  m_axi_h2i_awprot     = m_axi_k2h_AWPROT ;
assign    /*input */  m_axi_h2i_awqos      = m_axi_k2h_AWQOS ;
assign    /*input */  m_axi_h2i_awregion   = m_axi_k2h_AWREGION ;
assign    /*input */  m_axi_h2i_awuser     = reg_context ;//Context (PASID)
assign    /*input */  m_axi_h2i_wvalid     = m_axi_k2h_WVALID ;
assign    /*output*/  m_axi_k2h_WREADY     = m_axi_h2i_wready ;
assign    /*input */  m_axi_h2i_wdata      = m_axi_k2h_WDATA ;
assign    /*input */  m_axi_h2i_wstrb      = m_axi_k2h_WSTRB ;
assign    /*input */  m_axi_h2i_wlast      = m_axi_k2h_WLAST ;
assign    /*input */  m_axi_h2i_wid        = m_axi_k2h_WID ;
assign    /*input */  m_axi_h2i_wuser      = 0 ; //Not used
assign    /*input */  m_axi_h2i_arvalid    = m_axi_k2h_ARVALID ;
assign    /*output*/  m_axi_k2h_ARREADY    = m_axi_h2i_arready ;
assign    /*input */  m_axi_h2i_araddr     = m_axi_k2h_ARADDR ;
assign    /*input */  m_axi_h2i_arid       = m_axi_k2h_ARID ;
assign    /*input */  m_axi_h2i_arlen      = m_axi_k2h_ARLEN ;
assign    /*input */  m_axi_h2i_arsize     = m_axi_k2h_ARSIZE ;
assign    /*input */  m_axi_h2i_arburst    = m_axi_k2h_ARBURST ;
assign    /*input */  m_axi_h2i_arlock     = m_axi_k2h_ARLOCK ;
assign    /*input */  m_axi_h2i_arcache    = m_axi_k2h_ARCACHE ;
assign    /*input */  m_axi_h2i_arprot     = m_axi_k2h_ARPROT ;
assign    /*input */  m_axi_h2i_arqos      = m_axi_k2h_ARQOS ;
assign    /*input */  m_axi_h2i_arregion   = m_axi_k2h_ARREGION ;
assign    /*input */  m_axi_h2i_aruser     = reg_context ;//Context (PASID)
assign    /*output*/  m_axi_k2h_RVALID     = m_axi_h2i_rvalid ;
assign    /*input */  m_axi_h2i_rready     = m_axi_k2h_RREADY ;
assign    /*output*/  m_axi_k2h_RDATA      = m_axi_h2i_rdata ;
assign    /*output*/  m_axi_k2h_RLAST      = m_axi_h2i_rlast ;
assign    /*output*/  m_axi_k2h_RID        = m_axi_h2i_rid ;
assign    /*output*/  m_axi_k2h_RUSER      = 0 ;//Not used
assign    /*output*/  m_axi_k2h_RRESP      = m_axi_h2i_rresp ;
assign    /*output*/  m_axi_k2h_BVALID     = m_axi_h2i_bvalid ;
assign    /*input */  m_axi_h2i_bready     = m_axi_k2h_BREADY ;
assign    /*output*/  m_axi_k2h_BRESP      = m_axi_h2i_bresp ;
assign    /*output*/  m_axi_k2h_BID        = m_axi_h2i_bid ;
assign    /*output*/  m_axi_k2h_BUSER      = 0 ;//Not used



endmodule
