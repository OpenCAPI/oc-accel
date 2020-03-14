/*
 * Copyright 2020 International Business Machines
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

//-----------------------------------------------------------------//
// kernel helper 
// Define some special registers and handle AXI *USER wires
//-----------------------------------------------------------------//

//  Each kernel has allocated 256KB register space （0 to 'h40000-1）
//  Here REG_RANGE_BIT=17
//  [REG_RANGE_BIT:0] is the valid address

//  In this area, lower half is for the kernel core
//                higher half is for the special registers in kernel_helper
// 
//  DON'T modify REG_RANGE_BIT unless your kernel core needs larger configuration space (> 128KB)
//  Because it needs corresponding modifications to software and Address Editor in create_top.tcl


module kernel_helper # (
    parameter  KERNEL_TYPE      = 32'h0000ABCD  ,
    parameter  RELEASE_LEVEL    = 32'h00000001  ,
    parameter  REG_RANGE_BIT    = 17            ,
    parameter  KERNEL_NAME_STR1 = 32'h7473_6574 ,
    parameter  KERNEL_NAME_STR2 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR3 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR4 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR5 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR6 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR7 = 32'h2020_2020 ,
    parameter  KERNEL_NAME_STR8 = 32'h2020_2020 ,
    parameter  CTXW             = 9             ,
    // Kernel function module's AXILITE width
    parameter  C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
    parameter  C_S_AXI_CONTROL_ADDR_WIDTH = 32 ,
    // Kernel function module's AXIMM width
    parameter  C_M_AXI_GMEM_ID_WIDTH     = 1    ,
    parameter  C_M_AXI_GMEM_ADDR_WIDTH   = 64   ,
    parameter  C_M_AXI_GMEM_DATA_WIDTH   = 1024 ,
    parameter  C_M_AXI_GMEM_AWUSER_WIDTH = 1    ,
    parameter  C_M_AXI_GMEM_ARUSER_WIDTH = 1    ,
    parameter  C_M_AXI_GMEM_WUSER_WIDTH  = 1    ,
    parameter  C_M_AXI_GMEM_RUSER_WIDTH  = 1    ,
    parameter  C_M_AXI_GMEM_BUSER_WIDTH  = 1

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

    wire                            wire_axilite_ACLK          ;
    wire                            wire_axilite_ARESET        ;
    wire                            wire_axilite_ACLK_EN       ;
    wire [REG_RANGE_BIT-1:0]        wire_axilite_AWADDR        ;
    wire                            wire_axilite_AWVALID       ;
    wire                            wire_axilite_AWREADY       ;
    wire [31:0]                     wire_axilite_WDATA         ;
    wire [3:0]                      wire_axilite_WSTRB         ;
    wire                            wire_axilite_WVALID        ;
    wire                            wire_axilite_WREADY        ;
    wire [1:0]                      wire_axilite_BRESP         ;
    wire                            wire_axilite_BVALID        ;
    wire                            wire_axilite_BREADY        ;
    wire [REG_RANGE_BIT-1:0]        wire_axilite_ARADDR        ;
    wire                            wire_axilite_ARVALID       ;
    wire                            wire_axilite_ARREADY       ;
    wire [31:0]                     wire_axilite_RDATA         ;
    wire [1:0]                      wire_axilite_RRESP         ;
    wire                            wire_axilite_RVALID        ;
    wire                            wire_axilite_RREADY        ;
    wire [CTXW-1:0]                 o_context                  ;


    wire access_helper_w;
    assign access_helper_w = (s_axilite_i2h_awaddr[REG_RANGE_BIT] == 1'b1);
    wire access_helper_r;
    assign access_helper_r = (s_axilite_i2h_araddr[REG_RANGE_BIT] == 1'b1);

    reg access_helper_w_reg;
    always @ (posedge clk)
        if (s_axilite_i2h_awvalid)
            access_helper_w_reg <= access_helper_w;

    // helper's AXI slave
    verilog_helper_s_axi # (
        .C_S_AXI_ADDR_WIDTH (REG_RANGE_BIT      ) ,
        .KERNEL_TYPE        (KERNEL_TYPE        ) ,
        .RELEASE_LEVEL      (RELEASE_LEVEL      ) ,
        .KERNEL_NAME_STR1   (KERNEL_NAME_STR1   ) ,
        .KERNEL_NAME_STR2   (KERNEL_NAME_STR2   ) ,
        .KERNEL_NAME_STR3   (KERNEL_NAME_STR3   ) ,
        .KERNEL_NAME_STR4   (KERNEL_NAME_STR4   ) ,
        .KERNEL_NAME_STR5   (KERNEL_NAME_STR5   ) ,
        .KERNEL_NAME_STR6   (KERNEL_NAME_STR6   ) ,
        .KERNEL_NAME_STR7   (KERNEL_NAME_STR7   ) ,
        .KERNEL_NAME_STR8   (KERNEL_NAME_STR8   ) ,
        .CTXW               (CTXW               )
    ) helper_axi_s (
        .ACLK          (wire_axilite_ACLK               ) ,
        .ARESET        (wire_axilite_ARESET             ) ,
        .ACLK_EN       (wire_axilite_ACLK_EN            ) ,
        .AWADDR        (wire_axilite_AWADDR             ) ,
        .AWVALID       (wire_axilite_AWVALID            ) ,
        .AWREADY       (wire_axilite_AWREADY            ) ,
        .WDATA         (wire_axilite_WDATA              ) ,
        .WSTRB         (wire_axilite_WSTRB              ) ,
        .WVALID        (wire_axilite_WVALID             ) ,
        .WREADY        (wire_axilite_WREADY             ) ,
        .BRESP         (wire_axilite_BRESP              ) ,
        .BVALID        (wire_axilite_BVALID             ) ,
        .BREADY        (wire_axilite_BREADY             ) ,
        .ARADDR        (wire_axilite_ARADDR             ) ,
        .ARVALID       (wire_axilite_ARVALID            ) ,
        .ARREADY       (wire_axilite_ARREADY            ) ,
        .RDATA         (wire_axilite_RDATA              ) ,
        .RRESP         (wire_axilite_RRESP              ) ,
        .RVALID        (wire_axilite_RVALID             ) ,
        .RREADY        (wire_axilite_RREADY             ) ,
        .interrupt_i   (interrupt_i             ) ,
        .interrupt_req (interrupt_req           ) ,
        .interrupt_src (interrupt_src           ) ,
        .interrupt_ctx (interrupt_ctx           ) ,
        .interrupt_ack (interrupt_ack           ) ,
        .o_context     (o_context               )
    ) ;

    // Bypass most of the connections
    assign /*  output*/  s_axilite_h2k_AWVALID = access_helper_w ? 0 : s_axilite_i2h_awvalid;
    assign /*  output*/  s_axilite_h2k_AWADDR  = s_axilite_i2h_awaddr[C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] ; //Handle the mismatch of addr width
    assign /*  output*/  s_axilite_h2k_WVALID  = s_axilite_i2h_wvalid ;
    assign /*  output*/  s_axilite_h2k_WDATA   = s_axilite_i2h_wdata ;
    assign /*  output*/  s_axilite_h2k_WSTRB   = s_axilite_i2h_wstrb ;
    assign /*  output*/  s_axilite_h2k_ARVALID = access_helper_r ? 0 : s_axilite_i2h_arvalid;
    assign /*  output*/  s_axilite_h2k_ARADDR  = s_axilite_i2h_araddr [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] ; //Handle the mismatch of addr width
    assign /*  output*/  s_axilite_h2k_RREADY  = s_axilite_i2h_rready ;
    assign /*  output*/  s_axilite_h2k_BREADY  = s_axilite_i2h_bready ;

    assign /*  input */  s_axilite_i2h_awready = access_helper_w ? wire_axilite_AWREADY : s_axilite_h2k_AWREADY;
    assign /*  input */  s_axilite_i2h_wready  = (access_helper_w | access_helper_w_reg) ? wire_axilite_WREADY  : s_axilite_h2k_WREADY;
    assign /*  input */  s_axilite_i2h_arready = access_helper_r ? wire_axilite_ARREADY : s_axilite_h2k_ARREADY ;
    assign /*  input */  s_axilite_i2h_rvalid  = wire_axilite_RVALID  | s_axilite_h2k_RVALID ;
    assign /*  input */  s_axilite_i2h_rdata   = wire_axilite_RVALID  ? wire_axilite_RDATA : s_axilite_h2k_RDATA;
    assign /*  input */  s_axilite_i2h_rresp   = wire_axilite_RRESP   | s_axilite_h2k_RRESP ;
    assign /*  input */  s_axilite_i2h_bvalid  = wire_axilite_BVALID  | s_axilite_h2k_BVALID ;
    assign /*  input */  s_axilite_i2h_bresp   = wire_axilite_BRESP   | s_axilite_h2k_BRESP ;

    assign /*  input */  wire_axilite_ACLK          = clk;
    assign /*  input */  wire_axilite_ARESET        = ~resetn;
    assign /*  input */  wire_axilite_ACLK_EN       = 1'b1;

    assign /*  input */  wire_axilite_AWADDR        = s_axilite_i2h_awaddr;
    assign /*  input */  wire_axilite_AWVALID       = access_helper_w ? s_axilite_i2h_awvalid : 0;
    assign /*  input */  wire_axilite_WDATA         = s_axilite_i2h_wdata;
    assign /*  input */  wire_axilite_WSTRB         = s_axilite_i2h_wstrb;
    assign /*  input */  wire_axilite_WVALID        = s_axilite_i2h_wvalid;
    assign /*  input */  wire_axilite_BREADY        = s_axilite_i2h_bready;
    assign /*  input */  wire_axilite_ARADDR        = s_axilite_i2h_araddr;
    assign /*  input */  wire_axilite_ARVALID       = access_helper_r ? s_axilite_i2h_arvalid : 0;
    assign /*  input */  wire_axilite_RREADY        = s_axilite_i2h_rready;

    // 

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
    assign    /*input */  m_axi_h2i_awuser     = o_context ;//Context (PASID)
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
    assign    /*input */  m_axi_h2i_aruser     = o_context ;//Context (PASID)
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

module verilog_helper_s_axi
    #(parameter
        C_S_AXI_ADDR_WIDTH = 17            ,
        C_S_AXI_DATA_WIDTH = 32            ,
        KERNEL_TYPE        = 32'h0000ABCD  ,
        RELEASE_LEVEL      = 32'h00000001  ,
        KERNEL_NAME_STR1   = 32'h7473_6574 ,
        KERNEL_NAME_STR2   = 32'h2020_2020 ,
        KERNEL_NAME_STR3   = 32'h2020_2020 ,
        KERNEL_NAME_STR4   = 32'h2020_2020 ,
        KERNEL_NAME_STR5   = 32'h2020_2020 ,
        KERNEL_NAME_STR6   = 32'h2020_2020 ,
        KERNEL_NAME_STR7   = 32'h2020_2020 ,
        KERNEL_NAME_STR8   = 32'h2020_2020 ,
        CTXW               = 9
    )(
        input  wire                          ACLK          ,
        input  wire                          ARESET        ,
        input  wire                          ACLK_EN       ,
        input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR        ,
        input  wire                          AWVALID       ,
        output wire                          AWREADY       ,
        input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA         ,
        input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB       ,
        input  wire                          WVALID        ,
        output wire                          WREADY        ,
        output wire [1:0]                    BRESP         ,
        output wire                          BVALID        ,
        input  wire                          BREADY        ,
        input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR        ,
        input  wire                          ARVALID       ,
        output wire                          ARREADY       ,
        output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA         ,
        output wire [1:0]                    RRESP         ,
        output wire                          RVALID        ,
        input  wire                          RREADY        ,
        input  wire                          interrupt_i   ,
        output wire                          interrupt_req ,
        output wire [63:0]                   interrupt_src ,
        output wire [CTXW-1:0]               interrupt_ctx ,
        input  wire                          interrupt_ack ,
        output wire [CTXW-1:0]               o_context
        );
    //------------------------Parameter----------------------
    // Special Register Offset
    localparam ADDR_KERNEL_TYPE                  = 'h10; //Read Only
    localparam ADDR_RELEASE_LEVEL                = 'h14; //Read Only
    localparam ADDR_KERNEL_INTERRUPT_SRC_ADDR_LO = 'h18; //Write Only
    localparam ADDR_KERNEL_INTERRUPT_SRC_ADDR_HI = 'h1C; //Write Only
    localparam ADDR_CONTEXT                      = 'h20; //Read-Write
    localparam ADDR_KERNEL_NAME_STR1             = 'h30; //Read Only
    localparam ADDR_KERNEL_NAME_STR2             = 'h34; //Read Only
    localparam ADDR_KERNEL_NAME_STR3             = 'h38; //Read Only
    localparam ADDR_KERNEL_NAME_STR4             = 'h3C; //Read Only
    localparam ADDR_KERNEL_NAME_STR5             = 'h40; //Read Only
    localparam ADDR_KERNEL_NAME_STR6             = 'h44; //Read Only
    localparam ADDR_KERNEL_NAME_STR7             = 'h48; //Read Only
    localparam ADDR_KERNEL_NAME_STR8             = 'h4C; //Read Only
    localparam WRIDLE                            = 2'd0;
    localparam WRDATA                            = 2'd1;
    localparam WRRESP                            = 2'd2;
    localparam WRRESET                           = 2'd3;
    localparam RDIDLE                            = 2'd0;
    localparam RDDATA                            = 2'd1;
    localparam RDRESET                           = 2'd2;


    //------------------------Local signal-------------------
    reg  [1:0]                    wstate = WRRESET;
    reg  [1:0]                    wnext;
    reg  [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate = RDRESET;
    reg  [1:0]                    rnext;
    reg  [C_S_AXI_DATA_WIDTH-1:0] rdata;
    wire                          ar_hs;
    wire [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    // internal registers
    reg [31:0]                    reg_context;
    reg [31:0]                    reg_interrupt_src_hi;
    reg [31:0]                    reg_interrupt_src_lo;
    reg                           interrupt_q;
    reg                           interrupt_wait_ack_q;

    assign o_context = reg_context;

    //--------- Interrupt handshaking logic -----------
    always @ (posedge ACLK)
        if (ARESET) begin
            interrupt_q          <= 1'b0;
            interrupt_wait_ack_q <= 1'b0;
        end
        else begin
            interrupt_wait_ack_q <= (interrupt_i & ~interrupt_q ) | (interrupt_wait_ack_q & ~interrupt_ack);
            interrupt_q          <= interrupt_i & (interrupt_q | ~interrupt_wait_ack_q);
        end

    // Interrupt output signals
    // Generating interrupt pulse
    assign  interrupt_req = interrupt_i & ~interrupt_q;
    assign  interrupt_src = {reg_interrupt_src_hi, reg_interrupt_src_lo};
    // context ID
    assign  interrupt_ctx = reg_context;

    //------------------------Instantiation------------------

    //------------------------AXI write fsm------------------
    assign AWREADY = (wstate == WRIDLE);
    assign WREADY  = (wstate == WRDATA);
    assign BRESP   = 2'b00;  // OKAY
    assign BVALID  = (wstate == WRRESP);
    assign aw_hs   = AWVALID & AWREADY;
    assign w_hs    = WVALID & WREADY;

    // wstate
    always @(posedge ACLK) begin
        if (ARESET)
            wstate <= WRRESET;
        else if (ACLK_EN)
            wstate <= wnext;
    end

    // wnext
    always @(*) begin
        case (wstate)
            WRIDLE:
                if (AWVALID)
                    wnext = WRDATA;
                else
                    wnext = WRIDLE;
            WRDATA:
                if (WVALID)
                    wnext = WRRESP;
                else
                    wnext = WRDATA;
            WRRESP:
                if (BREADY)
                    wnext = WRIDLE;
                else
                    wnext = WRRESP;
            default:
                wnext = WRIDLE;
        endcase
    end

    // waddr
    always @(posedge ACLK) begin
        if (ACLK_EN) begin
            if (aw_hs)
                waddr <= AWADDR[C_S_AXI_ADDR_WIDTH-1:0];
        end
    end

    //------------------------AXI read fsm-------------------
    assign ARREADY = (rstate == RDIDLE);
    assign RDATA   = rdata;
    assign RRESP   = 2'b00;  // OKAY
    assign RVALID  = (rstate == RDDATA);
    assign ar_hs   = ARVALID & ARREADY;
    assign raddr   = ARADDR[C_S_AXI_ADDR_WIDTH-1:0];

    // rstate
    always @(posedge ACLK) begin
        if (ARESET)
            rstate <= RDRESET;
        else if (ACLK_EN)
            rstate <= rnext;
    end

    // rnext
    always @(*) begin
        case (rstate)
            RDIDLE:
                if (ARVALID)
                    rnext = RDDATA;
                else
                    rnext = RDIDLE;
            RDDATA:
                if (RREADY & RVALID)
                    rnext = RDIDLE;
                else
                    rnext = RDDATA;
            default:
                rnext = RDIDLE;
        endcase
    end

    // rdata
    always @(posedge ACLK) begin
        if (ACLK_EN) begin
            if (ar_hs) begin
                rdata <= 1'b0;
                case (raddr)
                    ADDR_CONTEXT: begin
                        rdata <= reg_context[31:0];
                    end
                    ADDR_KERNEL_TYPE: begin
                        rdata <= KERNEL_TYPE;
                    end
                    ADDR_RELEASE_LEVEL: begin
                        rdata <= RELEASE_LEVEL;
                    end
                    ADDR_KERNEL_NAME_STR1: begin
                        rdata <= KERNEL_NAME_STR1;
                    end
                    ADDR_KERNEL_NAME_STR2: begin
                        rdata <= KERNEL_NAME_STR2;
                    end
                    ADDR_KERNEL_NAME_STR3: begin
                        rdata <= KERNEL_NAME_STR3;
                    end
                    ADDR_KERNEL_NAME_STR4: begin
                        rdata <= KERNEL_NAME_STR4;
                    end
                    ADDR_KERNEL_NAME_STR5: begin
                        rdata <= KERNEL_NAME_STR5;
                    end
                    ADDR_KERNEL_NAME_STR6: begin
                        rdata <= KERNEL_NAME_STR6;
                    end
                    ADDR_KERNEL_NAME_STR7: begin
                        rdata <= KERNEL_NAME_STR7;
                    end
                    ADDR_KERNEL_NAME_STR8: begin
                        rdata <= KERNEL_NAME_STR8;
                    end
                endcase
            end
        end
    end

    //------------------------Register logic-----------------
    // reg_context
    always @(posedge ACLK) begin
        if (ARESET)
            reg_context[31:0] <= 0;
        else if (ACLK_EN) begin
            if (w_hs && waddr == ADDR_CONTEXT)
                reg_context[31:0] <= WDATA[C_S_AXI_DATA_WIDTH-1:0];
        end
    end

    // reg_interrupt_src_lo
    always @(posedge ACLK) begin
        if (ARESET)
            reg_interrupt_src_lo[31:0] <= 0;
        else if (ACLK_EN) begin
            if (w_hs && waddr == ADDR_KERNEL_INTERRUPT_SRC_ADDR_LO)
                reg_interrupt_src_lo[31:0] <= WDATA[C_S_AXI_DATA_WIDTH-1:0];
        end
    end

    // reg_interrupt_src_hi
    always @(posedge ACLK) begin
        if (ARESET)
            reg_interrupt_src_hi[31:0] <= 0;
        else if (ACLK_EN) begin
            if (w_hs && waddr == ADDR_KERNEL_INTERRUPT_SRC_ADDR_HI)
                reg_interrupt_src_hi[31:0] <= WDATA[C_S_AXI_DATA_WIDTH-1:0];
        end
    end
    //------------------------Memory logic-------------------

endmodule
