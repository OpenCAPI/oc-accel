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
              parameter  ACTION_TYPE      = 32'h10143FFF,
              parameter  RELEASE_LEVEL    = 32'h00000001,
              parameter  SPECIAL_REG_BASE = 32'h00001000,
              parameter  INT_BITS = 64,
              parameter  CTXW = 9,
              parameter  C_S_AXI_CONTROL_DATA_WIDTH = 32,
              parameter  C_S_AXI_CONTROL_ADDR_WIDTH = 6
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
   input                                   s_axilite_awvalid   ,
   output                                  s_axilite_awready   ,
   input [ 31 : 0]                         s_axilite_awaddr    ,
   input                                   s_axilite_wvalid    ,
   output                                  s_axilite_wready    ,
   input [ 31 : 0]                         s_axilite_wdata     ,
   input [ 3 : 0]                          s_axilite_wstrb     ,
   input                                   s_axilite_arvalid   ,
   output                                  s_axilite_arready   ,
   input [ 31 : 0]                         s_axilite_araddr    ,
   output                                  s_axilite_rvalid    ,
   input                                   s_axilite_rready    ,
   output [ 31 : 0]                        s_axilite_rdata     ,
   output [ 1 : 0]                         s_axilite_rresp     ,
   output                                  s_axilite_bvalid    ,
   input                                   s_axilite_bready    ,
   output [ 1 : 0]                         s_axilite_bresp     ,

   // AXI Control Register interface Output, to kernel_ip
   // Port width adjustable
   // Usually DATA_WIDTH is fixed to 32
   // But ADDR_WIDTH may be less than 32 sometimes.
   output                                       s_axi_control_AWVALID ,
   input                                        s_axi_control_AWREADY ,
   output[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]     s_axi_control_AWADDR  ,
   output                                       s_axi_control_WVALID  ,
   input                                        s_axi_control_WREADY  ,
   output[C_S_AXI_CONTROL_DATA_WIDTH - 1:0]     s_axi_control_WDATA   ,
   output[(C_S_AXI_CONTROL_DATA_WIDTH/8) - 1:0] s_axi_control_WSTRB   ,
   output                                       s_axi_control_ARVALID ,
   input                                        s_axi_control_ARREADY ,
   output[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]     s_axi_control_ARADDR  ,
   input                                        s_axi_control_RVALID  ,
   output                                       s_axi_control_RREADY  ,
   input  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0]    s_axi_control_RDATA   ,
   input  [1:0]                                 s_axi_control_RRESP   ,
   input                                        s_axi_control_BVALID  ,
   output                                       s_axi_control_BREADY  ,
   input  [1:0]                                 s_axi_control_BRESP 

   //For now, this helper doesn't deal with AXI-MM interface
   //But if there is a need, it can also be added here.

    );

// Bypass most of the connections

assign /*  output*/  s_axi_control_AWVALID = s_axilite_awvalid ;
assign /*  input */  s_axilite_awready     = s_axi_control_AWREADY ;
assign /*  output*/  s_axi_control_AWADDR  = s_axilite_awaddr[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]  ;
assign /*  output*/  s_axi_control_WVALID  = s_axilite_wvalid  ;
assign /*  input */  s_axilite_wready      = s_axi_control_WREADY ;
assign /*  output*/  s_axi_control_WDATA   = s_axilite_wdata   ;
assign /*  output*/  s_axi_control_WSTRB   = s_axilite_wstrb   ;
assign /*  output*/  s_axi_control_ARVALID = s_axilite_arvalid ;
assign /*  input */  s_axilite_arready     = s_axi_control_ARREADY ;
assign /*  output*/  s_axi_control_ARADDR  = s_axilite_araddr [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0]  ;
assign /*  input */  s_axilite_rvalid      = s_axi_control_RVALID ;
assign /*  output*/  s_axi_control_RREADY  = s_axilite_rready  ;
assign /*  input */  s_axilite_rdata       = s_axi_control_RDATA | reg_rdata_hijack;
assign /*  input */  s_axilite_rresp       = s_axi_control_RRESP ;
assign /*  input */  s_axilite_bvalid      = s_axi_control_BVALID ;
assign /*  output*/  s_axi_control_BREADY  = s_axilite_bready  ;
assign /*  input */  s_axilite_bresp       = s_axi_control_BRESP ;



// Use some address far away
localparam ADDR_ACTION_TYPE                  = 32'h10 + SPECIAL_REG_BASE;
localparam ADDR_RELEASE_LEVEL                = 32'h14 + SPECIAL_REG_BASE;
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_LO = 32'h18 + SPECIAL_REG_BASE;
localparam ADDR_ACTION_INTERRUPT_SRC_ADDR_HI = 32'h1C + SPECIAL_REG_BASE;
localparam ADDR_RETURN_CODE                  = 32'h20 + SPECIAL_REG_BASE;



reg context_q;
reg [31:0] interrupt_src_hi;
reg [31:0] interrupt_src_lo;
reg interrupt_q;
reg interrupt_wait_ack_q;



//==========================================
// Context is not implemented
always @ (posedge clk)
    if (~resetn)
        context_q <= 0;
//    else if (s_axilite_wvalid && (s_axilite_awaddr = ADDR_CTX_ID_REG )
//        context_q <= s_axilite_wdata;


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
        interrupt_src_hi <= 32'b0;
        interrupt_src_lo <= 32'b0;
    end
    else if (s_axilite_wvalid  && (s_axilite_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_HI))
        interrupt_src_hi <= s_axilite_wdata;
    else if (s_axilite_wvalid  && (s_axilite_awaddr == ADDR_ACTION_INTERRUPT_SRC_ADDR_LO))
        interrupt_src_lo <= s_axilite_wdata;

assign  interrupt_src = {interrupt_src_hi, interrupt_src_lo};
  // context ID
assign  interrupt_ctx = context_q;


//==========================================
//When read ACTION_TYPE and RELEASE_LEVEL, the return data is handled here. 
//hls_action will return RVALID (acknowledgement), RDATA=0
//and RDATA is ORed with this reg_rdata_hijack. 
reg  [31:0] reg_rdata_hijack; //This will be ORed with the return data of hls_action
always @ (posedge clk)
    if (~resetn) begin
        reg_rdata_hijack <= 32'h0;
    end
    else if (s_axilite_arvalid == 1'b1) begin
        if (s_axilite_araddr == ADDR_ACTION_TYPE)
            reg_rdata_hijack <= ACTION_TYPE;
        else if (s_axilite_araddr == ADDR_RELEASE_LEVEL)
            reg_rdata_hijack <= RELEASE_LEVEL;
        else
            reg_rdata_hijack <= 32'h0;
    end

endmodule
