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
                AXI_DATAW = 32, 
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
   output [ 63 : 0]                        host_mem_axi_00_araddr    ,
   output [ 1 : 0]                         host_mem_axi_00_arburst   ,
   output [ 3 : 0]                         host_mem_axi_00_arcache   ,
   output [ IDW-1 : 0]                     host_mem_axi_00_arid      ,
   output [ 7 : 0]                         host_mem_axi_00_arlen     ,
   output [ 1 : 0]                         host_mem_axi_00_arlock    ,
   output [ 2 : 0]                         host_mem_axi_00_arprot    ,
   output [ 3 : 0]                         host_mem_axi_00_arqos     ,
   input                                   host_mem_axi_00_arready   ,
   output [ 3 : 0]                         host_mem_axi_00_arregion  ,
   output [ 2 : 0]                         host_mem_axi_00_arsize    ,
   output [ AXI_ARUSER-1 : 0]              host_mem_axi_00_aruser    ,
   output                                  host_mem_axi_00_arvalid   ,
   output [ 63 : 0]                        host_mem_axi_00_awaddr    ,
   output [ 1 : 0]                         host_mem_axi_00_awburst   ,
   output [ 3 : 0]                         host_mem_axi_00_awcache   ,
   output [ IDW-1 : 0]                     host_mem_axi_00_awid      ,
   output [ 7 : 0]                         host_mem_axi_00_awlen     ,
   output [ 1 : 0]                         host_mem_axi_00_awlock    ,
   output [ 2 : 0]                         host_mem_axi_00_awprot    ,
   output [ 3 : 0]                         host_mem_axi_00_awqos     ,
   input                                   host_mem_axi_00_awready   ,
   output [ 3 : 0]                         host_mem_axi_00_awregion  ,
   output [ 2 : 0]                         host_mem_axi_00_awsize    ,
   output [AXI_AWUSER-1 : 0]               host_mem_axi_00_awuser    ,
   output                                  host_mem_axi_00_awvalid   ,
   input [ IDW-1 : 0]                      host_mem_axi_00_bid       ,
   output                                  host_mem_axi_00_bready    ,
   input [ 1 : 0]                          host_mem_axi_00_bresp     ,
   input [ AXI_BUSER-1 : 0]                host_mem_axi_00_buser     ,
   input                                   host_mem_axi_00_bvalid    ,
   input [ AXI_DATAW-1 : 0]                host_mem_axi_00_rdata     ,
   input [ IDW-1 : 0]                      host_mem_axi_00_rid       ,
   input                                   host_mem_axi_00_rlast     ,
   output                                  host_mem_axi_00_rready    ,
   input [ 1 : 0]                          host_mem_axi_00_rresp     ,
   input [ AXI_RUSER-1 : 0]                host_mem_axi_00_ruser     ,
   input                                   host_mem_axi_00_rvalid    ,
   output [ AXI_DATAW-1 : 0]               host_mem_axi_00_wdata     ,
   output                                  host_mem_axi_00_wlast     ,
   input                                   host_mem_axi_00_wready    ,
   output [(AXI_DATAW/8)-1 : 0]            host_mem_axi_00_wstrb     ,
   output [ AXI_WUSER-1 : 0]               host_mem_axi_00_wuser     ,
   output                                  host_mem_axi_00_wvalid
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
    .m_axi_gmem_araddr        (host_mem_axi_00_araddr    ) ,
    .m_axi_gmem_arburst       (host_mem_axi_00_arburst   ) ,
    .m_axi_gmem_arcache       (host_mem_axi_00_arcache   ) ,
    .m_axi_gmem_arid          (host_mem_axi_00_arid      ) ,//SR# 10394170
    .m_axi_gmem_arlen         (host_mem_axi_00_arlen     ) ,
    .m_axi_gmem_arlock        (host_mem_axi_00_arlock    ) ,
    .m_axi_gmem_arprot        (host_mem_axi_00_arprot    ) ,
    .m_axi_gmem_arqos         (host_mem_axi_00_arqos     ) ,
    .m_axi_gmem_arready       (host_mem_axi_00_arready   ) ,
    .m_axi_gmem_arregion      (host_mem_axi_00_arregion  ) ,
    .m_axi_gmem_arsize        (host_mem_axi_00_arsize    ) ,
    .m_axi_gmem_aruser        (host_mem_axi_00_aruser    ) ,
    .m_axi_gmem_arvalid       (host_mem_axi_00_arvalid   ) ,
    .m_axi_gmem_awaddr        (host_mem_axi_00_awaddr    ) ,
    .m_axi_gmem_awburst       (host_mem_axi_00_awburst   ) ,
    .m_axi_gmem_awcache       (host_mem_axi_00_awcache   ) ,
    .m_axi_gmem_awid          (host_mem_axi_00_awid      ) ,//SR# 10394170
    .m_axi_gmem_awlen         (host_mem_axi_00_awlen     ) ,
    .m_axi_gmem_awlock        (host_mem_axi_00_awlock    ) ,
    .m_axi_gmem_awprot        (host_mem_axi_00_awprot    ) ,
    .m_axi_gmem_awqos         (host_mem_axi_00_awqos     ) ,
    .m_axi_gmem_awready       (host_mem_axi_00_awready   ) ,
    .m_axi_gmem_awregion      (host_mem_axi_00_awregion  ) ,
    .m_axi_gmem_awsize        (host_mem_axi_00_awsize    ) ,
    .m_axi_gmem_awuser        (host_mem_axi_00_awuser    ) ,
    .m_axi_gmem_awvalid       (host_mem_axi_00_awvalid   ) ,
    .m_axi_gmem_bid           (host_mem_axi_00_bid [0]   ) ,//SR# 10394170
    .m_axi_gmem_bready        (host_mem_axi_00_bready    ) ,
    .m_axi_gmem_bresp         (host_mem_axi_00_bresp     ) ,
    .m_axi_gmem_buser         (host_mem_axi_00_buser [0] ) ,//SR# 10394170
    .m_axi_gmem_bvalid        (host_mem_axi_00_bvalid    ) ,
    .m_axi_gmem_rdata         (host_mem_axi_00_rdata     ) ,
    .m_axi_gmem_rid           (host_mem_axi_00_rid [0]   ) ,//SR# 10394170
    .m_axi_gmem_rlast         (host_mem_axi_00_rlast     ) ,
    .m_axi_gmem_rready        (host_mem_axi_00_rready    ) ,
    .m_axi_gmem_rresp         (host_mem_axi_00_rresp     ) ,
    .m_axi_gmem_ruser         (host_mem_axi_00_ruser [0] ) ,//SR# 10394170
    .m_axi_gmem_rvalid        (host_mem_axi_00_rvalid    ) ,
    .m_axi_gmem_wdata         (host_mem_axi_00_wdata     ) ,
    .m_axi_gmem_wid           (host_mem_axi_00_wid       ) ,
    .m_axi_gmem_wlast         (host_mem_axi_00_wlast     ) ,
    .m_axi_gmem_wready        (host_mem_axi_00_wready    ) ,
    .m_axi_gmem_wstrb         (host_mem_axi_00_wstrb     ) ,
    .m_axi_gmem_wuser         (host_mem_axi_00_wuser [0] ) ,//SR# 10394170
    .m_axi_gmem_wvalid        (host_mem_axi_00_wvalid    ) ,
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
