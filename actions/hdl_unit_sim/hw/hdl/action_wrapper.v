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
`include "snap_global_vars.v"

`ifndef ENABLE_ODMA
module action_wrapper #(
    // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
    parameter C_M_AXI_CARD_MEM0_ID_WIDTH     = 4,
    parameter C_M_AXI_CARD_MEM0_ADDR_WIDTH   = 33,
    parameter C_M_AXI_CARD_MEM0_DATA_WIDTH   = 512,
    parameter C_M_AXI_CARD_MEM0_AWUSER_WIDTH = 1,
    parameter C_M_AXI_CARD_MEM0_ARUSER_WIDTH = 1,
    parameter C_M_AXI_CARD_MEM0_WUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_RUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_BUSER_WIDTH  = 1,

    // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
    parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,

    // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    parameter C_M_AXI_HOST_MEM_ID_WIDTH      = `IDW,
    parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
    parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = `AXI_MM_DW,
    parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = `CTXW,
    parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = `CTXW,
    parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1,

    // Parameters of Interrupt Interface
    parameter SOURCE_BITS                    = 64,
    parameter CONTEXT_BITS                   = `CTXW

)
(
    input  ap_clk                    ,
    input  ap_rst_n                  ,
    output interrupt                 ,
    output [SOURCE_BITS-1  : 0] interrupt_src             ,
    output [CONTEXT_BITS-1 : 0] interrupt_ctx             ,
    input  interrupt_ack             ,
    //                                                                                                 
    /*                                                                                                 
    // AXI SDRAM Interface                                                                             
    output [C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 : 0 ] m_axi_card_mem0_araddr    ,     
    output [1 : 0 ] m_axi_card_mem0_arburst   ,                                  
    output [3 : 0 ] m_axi_card_mem0_arcache   ,                                  
    output [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_arid      ,       
    output [7 : 0 ] m_axi_card_mem0_arlen     ,                                  
    output [1 : 0 ] m_axi_card_mem0_arlock    ,                                  
    output [2 : 0 ] m_axi_card_mem0_arprot    ,                                  
    output [3 : 0 ] m_axi_card_mem0_arqos     ,                                  
    input  m_axi_card_mem0_arready   ,                                                        
    output [3 : 0 ] m_axi_card_mem0_arregion  ,                                  
    output [2 : 0 ] m_axi_card_mem0_arsize    ,                                  
    output [C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 : 0 ] m_axi_card_mem0_aruser    ,   
    output m_axi_card_mem0_arvalid   ,                                                        
    output [C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 : 0 ] m_axi_card_mem0_awaddr    ,     
    output [1 : 0 ] m_axi_card_mem0_awburst   ,                                  
    output [3 : 0 ] m_axi_card_mem0_awcache   ,                                  
    output [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_awid      ,       
    output [7 : 0 ] m_axi_card_mem0_awlen     ,                                  
    output [1 : 0 ] m_axi_card_mem0_awlock    ,                                  
    output [2 : 0 ] m_axi_card_mem0_awprot    ,                                  
    output [3 : 0 ] m_axi_card_mem0_awqos     ,                                  
    input  m_axi_card_mem0_awready   ,                                                        
    output [3 : 0 ] m_axi_card_mem0_awregion  ,                                  
    output [2 : 0 ] m_axi_card_mem0_awsize    ,                                  
    output [C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 : 0 ] m_axi_card_mem0_awuser    ,   
    output m_axi_card_mem0_awvalid   ,                                                        
    input  [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_bid       ,       
    output m_axi_card_mem0_bready    ,                                                        
    input  [1 : 0 ] m_axi_card_mem0_bresp     ,                                  
    input  [C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 : 0 ] m_axi_card_mem0_buser     ,    
    input  m_axi_card_mem0_bvalid    ,                                                        
    input  [C_M_AXI_CARD_MEM0_DATA_WIDTH-1 : 0 ] m_axi_card_mem0_rdata     ,     
    input  [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_rid       ,       
    input  m_axi_card_mem0_rlast     ,                                                        
    output m_axi_card_mem0_rready    ,                                                        
    input  [1 : 0 ] m_axi_card_mem0_rresp     ,                                  
    input  [C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 : 0 ] m_axi_card_mem0_ruser     ,    
    input  m_axi_card_mem0_rvalid    ,                                                        
    output [C_M_AXI_CARD_MEM0_DATA_WIDTH-1 : 0 ] m_axi_card_mem0_wdata     ,     
    output m_axi_card_mem0_wlast     ,                                                        
    input  m_axi_card_mem0_wready    ,                                                        
    output [(C_M_AXI_CARD_MEM0_DATA_WIDTH/8)-1 : 0 ] m_axi_card_mem0_wstrb     , 
    output [C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 : 0 ] m_axi_card_mem0_wuser     ,    
    output m_axi_card_mem0_wvalid    ,                                                        
 */
    //
    // AXI Control Register Interface
    input  [C_S_AXI_CTRL_REG_ADDR_WIDTH-1 : 0 ] s_axi_ctrl_reg_araddr     ,
    output s_axi_ctrl_reg_arready    ,
    input  s_axi_ctrl_reg_arvalid    ,
    input  [C_S_AXI_CTRL_REG_ADDR_WIDTH-1 : 0 ] s_axi_ctrl_reg_awaddr     ,
    output s_axi_ctrl_reg_awready    ,
    input  s_axi_ctrl_reg_awvalid    ,
    input  s_axi_ctrl_reg_bready     ,
    output [1 : 0 ] s_axi_ctrl_reg_bresp      ,
    output s_axi_ctrl_reg_bvalid     ,
    output [C_S_AXI_CTRL_REG_DATA_WIDTH-1 : 0 ] s_axi_ctrl_reg_rdata      ,
    input  s_axi_ctrl_reg_rready     ,
    output [1 : 0 ] s_axi_ctrl_reg_rresp      ,
    output s_axi_ctrl_reg_rvalid     ,
    input  [C_S_AXI_CTRL_REG_DATA_WIDTH-1 : 0 ] s_axi_ctrl_reg_wdata      ,
    output s_axi_ctrl_reg_wready     ,
    input  [(C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 : 0 ] s_axi_ctrl_reg_wstrb      ,
    input  s_axi_ctrl_reg_wvalid     ,
    //
    // AXI Host Memory Interface
    output [C_M_AXI_HOST_MEM_ADDR_WIDTH-1 : 0 ] m_axi_host_mem_araddr     ,
    output [1 : 0 ] m_axi_host_mem_arburst    ,
    output [3 : 0 ] m_axi_host_mem_arcache    ,
    output [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_arid       ,
    output [7 : 0 ] m_axi_host_mem_arlen      ,
    output [1 : 0 ] m_axi_host_mem_arlock     ,
    output [2 : 0 ] m_axi_host_mem_arprot     ,
    output [3 : 0 ] m_axi_host_mem_arqos      ,
    input  m_axi_host_mem_arready    ,
    output [3 : 0 ] m_axi_host_mem_arregion   ,
    output [2 : 0 ] m_axi_host_mem_arsize     ,
    output [C_M_AXI_HOST_MEM_ARUSER_WIDTH-1 : 0 ] m_axi_host_mem_aruser     ,
    output m_axi_host_mem_arvalid    ,
    output [C_M_AXI_HOST_MEM_ADDR_WIDTH-1 : 0 ] m_axi_host_mem_awaddr     ,
    output [1 : 0 ] m_axi_host_mem_awburst    ,
    output [3 : 0 ] m_axi_host_mem_awcache    ,
    output [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_awid       ,
    output [7 : 0 ] m_axi_host_mem_awlen      ,
    output [1 : 0 ] m_axi_host_mem_awlock     ,
    output [2 : 0 ] m_axi_host_mem_awprot     ,
    output [3 : 0 ] m_axi_host_mem_awqos      ,
    input  m_axi_host_mem_awready    ,
    output [3 : 0 ] m_axi_host_mem_awregion   ,
    output [2 : 0 ] m_axi_host_mem_awsize     ,
    output [C_M_AXI_HOST_MEM_AWUSER_WIDTH-1 : 0 ] m_axi_host_mem_awuser     ,
    output m_axi_host_mem_awvalid    ,
    input  [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_bid        ,
    output m_axi_host_mem_bready     ,
    input  [1 : 0 ] m_axi_host_mem_bresp      ,
    input  [C_M_AXI_HOST_MEM_BUSER_WIDTH-1 : 0 ] m_axi_host_mem_buser      ,
    input  m_axi_host_mem_bvalid     ,
    input  [C_M_AXI_HOST_MEM_DATA_WIDTH-1 : 0 ] m_axi_host_mem_rdata      ,
    input  [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_rid        ,
    input  m_axi_host_mem_rlast      ,
    output m_axi_host_mem_rready     ,
    input  [1 : 0 ] m_axi_host_mem_rresp      ,
    input  [C_M_AXI_HOST_MEM_RUSER_WIDTH-1 : 0 ] m_axi_host_mem_ruser      ,
    input  m_axi_host_mem_rvalid     ,
    output [C_M_AXI_HOST_MEM_DATA_WIDTH-1 : 0 ] m_axi_host_mem_wdata      ,
    output m_axi_host_mem_wlast      ,
    input  m_axi_host_mem_wready     ,
    output [(C_M_AXI_HOST_MEM_DATA_WIDTH/8)-1 : 0 ] m_axi_host_mem_wstrb      ,
    output [C_M_AXI_HOST_MEM_WUSER_WIDTH-1 : 0 ] m_axi_host_mem_wuser      ,
    output m_axi_host_mem_wvalid
);

    // Make wuser stick to 0
    assign m_axi_card_mem0_wuser = 0;
    assign m_axi_host_mem_wuser = 0;

    action_hdl_bridge_test #(
           // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
           .C_M_AXI_CARD_MEM0_ID_WIDTH    (C_M_AXI_CARD_MEM0_ID_WIDTH    ),
           .C_M_AXI_CARD_MEM0_ADDR_WIDTH  (C_M_AXI_CARD_MEM0_ADDR_WIDTH  ),
           .C_M_AXI_CARD_MEM0_DATA_WIDTH  (C_M_AXI_CARD_MEM0_DATA_WIDTH  ),
           .C_M_AXI_CARD_MEM0_AWUSER_WIDTH(C_M_AXI_CARD_MEM0_AWUSER_WIDTH),
           .C_M_AXI_CARD_MEM0_ARUSER_WIDTH(C_M_AXI_CARD_MEM0_ARUSER_WIDTH),
           .C_M_AXI_CARD_MEM0_WUSER_WIDTH (C_M_AXI_CARD_MEM0_WUSER_WIDTH ),
           .C_M_AXI_CARD_MEM0_RUSER_WIDTH (C_M_AXI_CARD_MEM0_RUSER_WIDTH ),
           .C_M_AXI_CARD_MEM0_BUSER_WIDTH (C_M_AXI_CARD_MEM0_BUSER_WIDTH ),

           // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
           .C_S_AXI_CTRL_REG_DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .C_S_AXI_CTRL_REG_ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   ),

           // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
           .C_M_AXI_HOST_MEM_ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
           .C_M_AXI_HOST_MEM_ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
           .C_M_AXI_HOST_MEM_DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
           .C_M_AXI_HOST_MEM_AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
           .C_M_AXI_HOST_MEM_ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
           .C_M_AXI_HOST_MEM_WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
           .C_M_AXI_HOST_MEM_RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
           .C_M_AXI_HOST_MEM_BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  ),
           .SOURCE_BITS                   (SOURCE_BITS                   ),
           .CONTEXT_BITS                  (CONTEXT_BITS                  )
    ) action_hdl_bridge_test (
        .clk                   (ap_clk),
        .rst_n                 (ap_rst_n), 
    
        //---- AXI bus interfaced with SNAP core ----               
        // AXI write address channel      
        .m_axi_snap_awid       (m_axi_host_mem_awid),  
        .m_axi_snap_awaddr     (m_axi_host_mem_awaddr),  
        .m_axi_snap_awlen      (m_axi_host_mem_awlen),  
        .m_axi_snap_awsize     (m_axi_host_mem_awsize),  
        .m_axi_snap_awburst    (m_axi_host_mem_awburst),  
        .m_axi_snap_awcache    (m_axi_host_mem_awcache),  
        .m_axi_snap_awlock     (m_axi_host_mem_awlock),  
        .m_axi_snap_awprot     (m_axi_host_mem_awprot),  
        .m_axi_snap_awqos      (m_axi_host_mem_awqos),  
        .m_axi_snap_awregion   (m_axi_host_mem_awregion),  
        .m_axi_snap_awuser     (m_axi_host_mem_awuser),  
        .m_axi_snap_awvalid    (m_axi_host_mem_awvalid),  
        .m_axi_snap_awready    (m_axi_host_mem_awready),
        // AXI write data channel         
        //.m_axi_snap_wid        (0), 
        .m_axi_snap_wdata      (m_axi_host_mem_wdata),  
        .m_axi_snap_wstrb      (m_axi_host_mem_wstrb),  
        .m_axi_snap_wlast      (m_axi_host_mem_wlast),  
        .m_axi_snap_wvalid     (m_axi_host_mem_wvalid),  
        .m_axi_snap_wready     (m_axi_host_mem_wready),
        // AXI write response channel     
        .m_axi_snap_bready     (m_axi_host_mem_bready),  
        .m_axi_snap_bid        (m_axi_host_mem_bid),
        .m_axi_snap_bresp      (m_axi_host_mem_bresp),
        .m_axi_snap_bvalid     (m_axi_host_mem_bvalid),
        // AXI read address channel       
        .m_axi_snap_arid       (m_axi_host_mem_arid),  
        .m_axi_snap_araddr     (m_axi_host_mem_araddr),  
        .m_axi_snap_arlen      (m_axi_host_mem_arlen),  
        .m_axi_snap_arsize     (m_axi_host_mem_arsize),  
        .m_axi_snap_arburst    (m_axi_host_mem_arburst),  
        .m_axi_snap_aruser     (m_axi_host_mem_aruser), 
        .m_axi_snap_arcache    (m_axi_host_mem_arcache), 
        .m_axi_snap_arlock     (m_axi_host_mem_arlock),  
        .m_axi_snap_arprot     (m_axi_host_mem_arprot), 
        .m_axi_snap_arqos      (m_axi_host_mem_arqos), 
        .m_axi_snap_arregion   (m_axi_host_mem_arregion), 
        .m_axi_snap_arvalid    (m_axi_host_mem_arvalid), 
        .m_axi_snap_arready    (m_axi_host_mem_arready),
        // AXI  ead data channel          
        .m_axi_snap_rready     (m_axi_host_mem_rready), 
        .m_axi_snap_rid        (m_axi_host_mem_rid),
        .m_axi_snap_rdata      (m_axi_host_mem_rdata),
        .m_axi_snap_rresp      (m_axi_host_mem_rresp),
        .m_axi_snap_rlast      (m_axi_host_mem_rlast),
        .m_axi_snap_rvalid     (m_axi_host_mem_rvalid),
    
    /*
        //---- AXI bus interfaced with DDR ----               
        // AXI write address channel      
        .m_axi_ddr_awid        (m_axi_card_mem0_awid),  
        .m_axi_ddr_awaddr      (m_axi_card_mem0_awaddr),  
        .m_axi_ddr_awlen       (m_axi_card_mem0_awlen),  
        .m_axi_ddr_awsize      (m_axi_card_mem0_awsize),  
        .m_axi_ddr_awburst     (m_axi_card_mem0_awburst),  
        .m_axi_ddr_awcache     (m_axi_card_mem0_awcache),  
        .m_axi_ddr_awlock      (m_axi_card_mem0_awlock),  
        .m_axi_ddr_awprot      (m_axi_card_mem0_awprot),  
        .m_axi_ddr_awqos       (m_axi_card_mem0_awqos),  
        .m_axi_ddr_awregion    (m_axi_card_mem0_awregion),  
        .m_axi_ddr_awuser      (m_axi_card_mem0_awuser),  
        .m_axi_ddr_awvalid     (m_axi_card_mem0_awvalid),  
        .m_axi_ddr_awready     (m_axi_card_mem0_awready),
        // AXI write data channel         
        //.m_axi_ddr_wid         (0), 
        .m_axi_ddr_wdata       (m_axi_card_mem0_wdata),  
        .m_axi_ddr_wstrb       (m_axi_card_mem0_wstrb),  
        .m_axi_ddr_wlast       (m_axi_card_mem0_wlast),  
        .m_axi_ddr_wvalid      (m_axi_card_mem0_wvalid),  
        .m_axi_ddr_wready      (m_axi_card_mem0_wready),
        // AXI write response channel     
        .m_axi_ddr_bready      (m_axi_card_mem0_bready),  
        .m_axi_ddr_bid         (m_axi_card_mem0_bid),
        .m_axi_ddr_bresp       (m_axi_card_mem0_bresp),
        .m_axi_ddr_bvalid      (m_axi_card_mem0_bvalid),
        // AXI read address channel       
        .m_axi_ddr_arid        (m_axi_card_mem0_arid),  
        .m_axi_ddr_araddr      (m_axi_card_mem0_araddr),  
        .m_axi_ddr_arlen       (m_axi_card_mem0_arlen),  
        .m_axi_ddr_arsize      (m_axi_card_mem0_arsize),  
        .m_axi_ddr_arburst     (m_axi_card_mem0_arburst),  
        .m_axi_ddr_aruser      (m_axi_card_mem0_aruser), 
        .m_axi_ddr_arcache     (m_axi_card_mem0_arcache), 
        .m_axi_ddr_arlock      (m_axi_card_mem0_arlock),  
        .m_axi_ddr_arprot      (m_axi_card_mem0_arprot), 
        .m_axi_ddr_arqos       (m_axi_card_mem0_arqos), 
        .m_axi_ddr_arregion    (m_axi_card_mem0_arregion), 
        .m_axi_ddr_arvalid     (m_axi_card_mem0_arvalid), 
        .m_axi_ddr_arready     (m_axi_card_mem0_arready),
        // AXI  ead data channel          
        .m_axi_ddr_rready      (m_axi_card_mem0_rready), 
        .m_axi_ddr_rid         (m_axi_card_mem0_rid),
        .m_axi_ddr_rdata       (m_axi_card_mem0_rdata),
        .m_axi_ddr_rresp       (m_axi_card_mem0_rresp),
        .m_axi_ddr_rlast       (m_axi_card_mem0_rlast),
        .m_axi_ddr_rvalid      (m_axi_card_mem0_rvalid),
        */
    
        //---- AXI Lite bus interfaced with SNAP core ----               
        // AXI write address channel
        .s_axi_snap_awready    (s_axi_ctrl_reg_awready),   
        .s_axi_snap_awaddr     (s_axi_ctrl_reg_awaddr),
        .s_axi_snap_awprot     (s_axi_ctrl_reg_awprot),
        .s_axi_snap_awvalid    (s_axi_ctrl_reg_awvalid),
        // axi write data channel             
        .s_axi_snap_wready     (s_axi_ctrl_reg_wready),
        .s_axi_snap_wdata      (s_axi_ctrl_reg_wdata),
        .s_axi_snap_wstrb      (s_axi_ctrl_reg_wstrb),
        .s_axi_snap_wvalid     (s_axi_ctrl_reg_wvalid),
        // AXI response channel
        .s_axi_snap_bresp      (s_axi_ctrl_reg_bresp),
        .s_axi_snap_bvalid     (s_axi_ctrl_reg_bvalid),
        .s_axi_snap_bready     (s_axi_ctrl_reg_bready),
        // AXI read address channel
        .s_axi_snap_arready    (s_axi_ctrl_reg_arready),
        .s_axi_snap_arvalid    (s_axi_ctrl_reg_arvalid),
        .s_axi_snap_araddr     (s_axi_ctrl_reg_araddr),
        .s_axi_snap_arprot     (s_axi_ctrl_reg_arprot),
        // AXI read data channel
        .s_axi_snap_rdata      (s_axi_ctrl_reg_rdata),
        .s_axi_snap_rresp      (s_axi_ctrl_reg_rresp),
        .s_axi_snap_rready     (s_axi_ctrl_reg_rready),
        .s_axi_snap_rvalid     (s_axi_ctrl_reg_rvalid),
        .i_action_type         (32'h10142004), //Should match ACTION_TYPE_HDL_BRIDGE_TEST with sw
        .i_action_version      (32'h00000001), //Hardware Version
        .interrupt             (interrupt),
        .interrupt_ack         (interrupt_ack),
        .interrupt_src         (interrupt_src),
        .interrupt_ctx         (interrupt_ctx)
    );
    
endmodule
`else
// Place holder for ODMA unit sim AFU.
//
module action_wrapper #(
    // Parameters of Axi MM Bus Interface
    parameter  AXI_ID_WIDTH                  = 5, 
    parameter  AXI_ADDR_WIDTH                = 64,
    parameter  AXI_DATA_WIDTH                = `AXI_MM_DW,
    parameter  AXI_AWUSER_WIDTH              = 9, 
    parameter  AXI_ARUSER_WIDTH              = 9, 
    parameter  AXI_WUSER_WIDTH               = 1, 
    parameter  AXI_RUSER_WIDTH               = 1, 
    parameter  AXI_BUSER_WIDTH               = 1, 
    parameter  AXIL_ADDR_WIDTH               = 32,
    parameter  AXIL_DATA_WIDTH               = 32, 

    // Parameters of Axi Stream Bus Interface
    parameter AXIS_ID_WIDTH                  = `IDW,
    parameter AXIS_DATA_WIDTH                = `AXI_ST_DW,
    parameter AXIS_USER_WIDTH                = `CTXW,

    // Parameters of Interrupt Interface
    parameter SOURCE_BITS                    = 64,
    parameter CONTEXT_BITS                   = `CTXW)
(
    input  ap_clk                    ,
    input  ap_rst_n                  ,
    output interrupt                 ,
    output [SOURCE_BITS-1  : 0] interrupt_src             ,
    output [CONTEXT_BITS-1 : 0] interrupt_ctx             ,
    input  interrupt_ack             ,
    `ifndef ENABLE_ODMA_ST_MODE    
        //----- AXI4 read addr interface -----
        input  [AXI_ADDR_WIDTH-1 : 0]       axi_mm_araddr,         
        input  [1 : 0]                      axi_mm_arburst,        
        input  [3 : 0]                      axi_mm_arcache,        
        input  [AXI_ID_WIDTH-1 : 0]         axi_mm_arid,           
        input  [7 : 0]                      axi_mm_arlen,         
        input  [1 : 0]                      axi_mm_arlock,         
        input  [2 : 0]                      axi_mm_arprot,         
        input  [3 : 0]                      axi_mm_arqos,          
        output                              axi_mm_arready,       
        input  [3 : 0]                      axi_mm_arregion,       
        input  [2 : 0]                      axi_mm_arsize,         
        input  [AXI_ARUSER_WIDTH-1 : 0]     axi_mm_aruser,         
        input                               axi_mm_arvalid,       
        //----- AXI4 read data interface -----
        output [AXI_DATA_WIDTH-1 : 0 ]      axi_mm_rdata,          
        output [AXI_ID_WIDTH-1 : 0 ]        axi_mm_rid,            
        output                              axi_mm_rlast,          
        input                               axi_mm_rready,         
        output [1 : 0 ]                     axi_mm_rresp,        
        output [AXI_RUSER_WIDTH-1 : 0 ]     axi_mm_ruser,          
        output                              axi_mm_rvalid,         
        //----- AXI4 write addr interface -----
        input  [AXI_ADDR_WIDTH-1 : 0]       axi_mm_awaddr,         
        input  [1 : 0]                      axi_mm_awburst,        
        input  [3 : 0]                      axi_mm_awcache,        
        input  [AXI_ID_WIDTH-1 : 0]         axi_mm_awid,           
        input  [7 : 0]                      axi_mm_awlen,         
        input  [1 : 0]                      axi_mm_awlock,         
        input  [2 : 0]                      axi_mm_awprot,         
        input  [3 : 0]                      axi_mm_awqos,          
        output                              axi_mm_awready,       
        input  [3 : 0]                      axi_mm_awregion,       
        input  [2 : 0]                      axi_mm_awsize,         
        input  [AXI_AWUSER_WIDTH-1 : 0]     axi_mm_awuser,         
        input                               axi_mm_awvalid,       
        //----- AXI4 write data interface -----
        input  [AXI_DATA_WIDTH-1 : 0 ]      axi_mm_wdata,          
        input  [(AXI_DATA_WIDTH/8)-1 : 0 ]  axi_mm_wstrb,          
        input                               axi_mm_wlast,          
        input  [AXI_WUSER_WIDTH-1 : 0 ]     axi_mm_wuser,          
        input                               axi_mm_wvalid,         
        output                              axi_mm_wready,         
        //----- AXI4 write resp interface -----
        output                              axi_mm_bvalid,         
        output [1 : 0]                      axi_mm_bresp,         
        output [AXI_BUSER_WIDTH-1 : 0 ]     axi_mm_buser,          
        output [AXI_ID_WIDTH-1 : 0 ]        axi_mm_bid,
        input                               axi_mm_bready,
    `else
        output                              m_axis_tready,
        input                               m_axis_tlast,
        input [`AXI_ST_DW - 1:0]            m_axis_tdata,
        input [`AXI_ST_DW/8 - 1:0]          m_axis_tkeep,
        input                               m_axis_tvalid,
        input [`IDW - 1:0]                  m_axis_tid,
        input [`AXI_ST_USER - 1:0]          m_axis_tuser,
        input                               s_axis_tready,
        output                              s_axis_tlast,
        output  [`AXI_ST_DW - 1:0]          s_axis_tdata,
        output  [`AXI_ST_DW/8 - 1:0]        s_axis_tkeep ,
        output                              s_axis_tvalid,
        output  [`IDW - 1:0]                s_axis_tid,
        output  [`AXI_ST_USER - 1:0]        s_axis_tuser,
    `endif
    //----- AXI lite slave interface -----
    input                               a_s_axi_arvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]      a_s_axi_araddr,         
    output                              a_s_axi_arready,        
    output                              a_s_axi_rvalid,         
    output [AXIL_DATA_WIDTH-1 : 0 ]     a_s_axi_rdata,          
    output [1 : 0 ]                     a_s_axi_rresp,          
    input                               a_s_axi_rready,         
    input                               a_s_axi_awvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]      a_s_axi_awaddr,         
    output                              a_s_axi_awready,        
    input                               a_s_axi_wvalid,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]     a_s_axi_wdata,          
    input  [(AXIL_DATA_WIDTH/8)-1 : 0 ] a_s_axi_wstrb,          
    output                              a_s_axi_wready,         
    output                              a_s_axi_bvalid,         
    output [1 : 0 ]                     a_s_axi_bresp,          
    input                               a_s_axi_bready,         
    //----- AXI lite master interface -----
    output                              a_m_axi_arvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]      a_m_axi_araddr,         
    input                               a_m_axi_arready,        
    input                               a_m_axi_rvalid,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]     a_m_axi_rdata,          
    input  [1 : 0 ]                     a_m_axi_rresp,          
    output                              a_m_axi_rready,         
    output                              a_m_axi_awvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]      a_m_axi_awaddr,         
    input                               a_m_axi_awready,        
    output                              a_m_axi_wvalid,         
    output [AXIL_DATA_WIDTH-1 : 0 ]     a_m_axi_wdata,          
    output [(AXIL_DATA_WIDTH/8)-1 : 0 ] a_m_axi_wstrb,          
    input                               a_m_axi_wready,         
    input                               a_m_axi_bvalid,         
    input  [1 : 0 ]                     a_m_axi_bresp,          
    output                              a_m_axi_bready
);

    //TODO: Send interrupt
    assign interrupt_src=0;
    assign interrupt=0;
    assign interrupt_ctx=0;
//wire tempwire1, tempwire2, tempwire3, tempwire4, tempwire5, tempwire6, tempwire7, tempwir8;

// odma_dummy_action #(
//                    .AXI_ID_WIDTH    ( AXI_ID_WIDTH    ), 
//                    .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH  ), 
//                    .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH  ), 
//                    .AXI_AWUSER_WIDTH ( AXI_AWUSER_WIDTH ),
//                    .AXI_ARUSER_WIDTH ( AXI_ARUSER_WIDTH ),
//                    .AXI_WUSER_WIDTH ( AXI_WUSER_WIDTH ), 
//                    .AXI_RUSER_WIDTH ( AXI_RUSER_WIDTH ), 
//                    .AXI_BUSER_WIDTH ( AXI_BUSER_WIDTH ), 
//                    .AXIL_ADDR_WIDTH ( AXIL_ADDR_WIDTH ), 
//                    .AXIL_DATA_WIDTH ( AXIL_DATA_WIDTH ) 
//                   ) 
//                   dummy_action (
//
//     /*input                              */   .clk           ( ap_clk          ),
//     /*input                              */   .rst_n         ( ap_rst_n        ),
//     /* AXI4 read addr interface */
//     /*input  [AXI_ADDR_WIDTH-1 : 0]      */   .axi_araddr    ( axi_mm_araddr   ),         
//     /*input  [1 : 0]                     */   .axi_arburst   ( axi_mm_arburst  ),        
//     /*input  [3 : 0]                     */   .axi_arcache   ( axi_mm_arcache  ),        
//     /*input  [AXI_ID_WIDTH-1 : 0]        */   .axi_arid      ( axi_mm_arid     ),           
//     /*input  [7 : 0]                     */   .axi_arlen     ( axi_mm_arlen    ),         
//     /*input  [1 : 0]                     */   .axi_arlock    ( axi_mm_arlock   ),         
//     /*input  [2 : 0]                     */   .axi_arprot    ( axi_mm_arprot   ),         
//     /*input  [3 : 0]                     */   .axi_arqos     ( axi_mm_arqos    ),          
//     /*output                             */   .axi_arready   ( axi_mm_arready  ),       
//     /*input  [3 : 0]                     */   .axi_arregion  ( axi_mm_arregion ),       
//     /*input  [2 : 0]                     */   .axi_arsize    ( axi_mm_arsize   ),         
//     /*input  [AXI_ARUSER_WIDTH-1 : 0]    */   .axi_aruser    ( axi_mm_aruser   ),         
//     /*input                              */   .axi_arvalid   ( axi_mm_arvalid  ),       
//     /* AXI4 read data interface */                                           
//     /*output [AXI_DATA_WIDTH-1 : 0 ]     */   .axi_rdata     ( axi_mm_rdata    ),          
//     /*output [AXI_ID_WIDTH-1 : 0 ]       */   .axi_rid       ( axi_mm_rid      ),            
//     /*output                             */   .axi_rlast     ( axi_mm_rlast    ),          
//     /*input                              */   .axi_rready    ( axi_mm_rready   ),         
//     /*output [1 : 0 ]                    */   .axi_rresp     ( axi_mm_rresp    ),        
//     /*output [AXI_RUSER_WIDTH-1 : 0 ]    */   .axi_ruser     ( axi_mm_ruser    ),          
//     /*output reg                         */   .axi_rvalid    ( axi_mm_rvalid   ),         
//     /* AXI4 write addr interface */                                          
//     /*input  [AXI_ADDR_WIDTH-1 : 0]      */   .axi_awaddr    ( axi_mm_awaddr   ),         
//     /*input  [1 : 0]                     */   .axi_awburst   ( axi_mm_awburst  ),        
//     /*input  [3 : 0]                     */   .axi_awcache   ( axi_mm_awcache  ),        
//     /*input  [AXI_ID_WIDTH-1 : 0]        */   .axi_awid      ( axi_mm_awid     ),           
//     /*input  [7 : 0]                     */   .axi_awlen     ( axi_mm_awlen    ),         
//     /*input  [1 : 0]                     */   .axi_awlock    ( axi_mm_awlock   ),         
//     /*input  [2 : 0]                     */   .axi_awprot    ( axi_mm_awprot   ),         
//     /*input  [3 : 0]                     */   .axi_awqos     ( axi_mm_awqos    ),          
//     /*output reg                         */   .axi_awready   ( axi_mm_awready  ),       
//     /*input  [3 : 0]                     */   .axi_awregion  ( axi_mm_awregion ),       
//     /*input  [2 : 0]                     */   .axi_awsize    ( axi_mm_awsize   ),         
//     /*input  [AXI_ARUSER_WIDTH-1 : 0]    */   .axi_awuser    ( axi_mm_awuser   ),         
//     /*input                              */   .axi_awvalid   ( axi_mm_awvalid  ),       
//     /* AXI4 write data interface */                                          
//     /*input  [AXI_DATA_WIDTH-1 : 0 ]     */   .axi_wdata     ( axi_mm_wdata    ),          
//     /*input  [(AXI_DATA_WIDTH/8)-1 : 0 ] */   .axi_wstrb     ( axi_mm_wstrb    ),          
//     /*input                              */   .axi_wlast     ( axi_mm_wlast    ),          
//     /*input  [AXI_WUSER_WIDTH-1 : 0 ]    */   .axi_wuser     ( axi_mm_wuser    ),          
//     /*input                              */   .axi_wvalid    ( axi_mm_wvalid   ),         
//     /*output reg                         */   .axi_wready    ( axi_mm_wready   ),         
//     /* AXI4 write resp interface */                                          
//     /*output reg                         */   .axi_bvalid    ( axi_mm_bvalid   ),         
//     /*output [1 : 0]                     */   .axi_bresp     ( axi_mm_bresp    ),         
//     /*output [AXI_BUSER_WIDTH-1 : 0 ]    */   .axi_buser     ( axi_mm_buser    ),          
//     /*output [AXI_ID_WIDTH-1 : 0 ]       */   .axi_bid       ( axi_mm_bid      ),
//     /*input                              */   .axi_bready    ( axi_mm_bready   ),
//
//     /* AXI lite slave interface */                                           
//     /*input                              */   .s_lite_arvalid( a_s_axi_arvalid ),        
//     /*input  [AXIL_ADDR_WIDTH-1 : 0]     */   .s_lite_araddr ( a_s_axi_araddr  ),         
//     /*output reg                         */   .s_lite_arready( a_s_axi_arready ),        
//     /*output reg                         */   .s_lite_rvalid ( a_s_axi_rvalid  ),         
//     /*output [AXIL_DATA_WIDTH-1 : 0 ]    */   .s_lite_rdata  ( a_s_axi_rdata   ),          
//     /*output [1 : 0 ]                    */   .s_lite_rresp  ( a_s_axi_rresp   ),          
//     /*input                              */   .s_lite_rready ( a_s_axi_rready  ),         
//     /*input                              */   .s_lite_awvalid( a_s_axi_awvalid ),        
//     /*input  [AXIL_ADDR_WIDTH-1 : 0]     */   .s_lite_awaddr ( a_s_axi_awaddr  ),         
//     /*output reg                         */   .s_lite_awready( a_s_axi_awready ),        
//     /*input                              */   .s_lite_wvalid ( a_s_axi_wvalid  ),         
//     /*input  [AXIL_DATA_WIDTH-1 : 0 ]    */   .s_lite_wdata  ( a_s_axi_wdata   ),          
//     /*input  [(AXIL_DATA_WIDTH/8)-1 : 0 ]*/   .s_lite_wstrb  ( a_s_axi_wstrb   ),          
//     /*output reg                         */   .s_lite_wready ( a_s_axi_wready  ),         
//     /*output reg                         */   .s_lite_bvalid ( a_s_axi_bvalid  ),         
//     /*output [1 : 0 ]                    */   .s_lite_bresp  ( a_s_axi_bresp   ),          
//     /*input                              */   .s_lite_bready ( a_s_axi_bready  ),         
//     /* AXI lite master interface */                                      
//     /*output                             */   .m_lite_arvalid( a_m_axi_arvalid ),        
//     /*output [AXIL_ADDR_WIDTH-1 : 0]     */   .m_lite_araddr ( a_m_axi_araddr  ),         
//     /*input                              */   .m_lite_arready( a_m_axi_arready ),        
//     /*input                              */   .m_lite_rvalid ( a_m_axi_rvalid  ),         
//     /*input  [AXIL_DATA_WIDTH-1 : 0 ]    */   .m_lite_rdata  ( a_m_axi_rdata   ),          
//     /*input  [1 : 0 ]                    */   .m_lite_rresp  ( a_m_axi_rresp   ),          
//     /*output                             */   .m_lite_rready ( a_m_axi_rready  ),         
//     /*output                             */   .m_lite_awvalid( a_m_axi_awvalid ),        
//     /*output [AXIL_ADDR_WIDTH-1 : 0]     */   .m_lite_awaddr ( a_m_axi_awaddr  ),         
//     /*input                              */   .m_lite_awready( a_m_axi_awready ),        
//     /*output                             */   .m_lite_wvalid ( a_m_axi_wvalid  ),         
//     /*output [AXIL_DATA_WIDTH-1 : 0 ]    */   .m_lite_wdata  ( a_m_axi_wdata   ),          
//     /*output [(AXIL_DATA_WIDTH/8)-1 : 0 ]*/   .m_lite_wstrb  ( a_m_axi_wstrb   ),          
//     /*input                              */   .m_lite_wready ( a_m_axi_wready  ),         
//     /*input                              */   .m_lite_bvalid ( a_m_axi_bvalid  ),         
//     /*input  [1 : 0 ]                    */   .m_lite_bresp  ( a_m_axi_bresp   ),          
//     /*output                             */   .m_lite_bready ( a_m_axi_bready  )   
//                   );

`ifndef ENABLE_ODMA_ST_MODE
    //odma_axi_slave is ready, codes are as follows
    odma_axi_slave  axi_slave(
    /*input                              */   .clk           ( ap_clk         ),
    /*input                              */   .rst_n         ( ap_rst_n       ),
    /* AXI4 read addr interface */
    /*input  [AXI_ADDR_WIDTH-1 : 0]      */   .axi_araddr    ( axi_mm_araddr     ),         
    /*input  [1 : 0]                     */   .axi_arburst   ( axi_mm_arburst    ),        
    /*input  [3 : 0]                     */   .axi_arcache   ( axi_mm_arcache    ),        
    /*input  [AXI_ID_WIDTH-1 : 0]        */   .axi_arid      ( axi_mm_arid       ),           
    /*input  [7 : 0]                     */   .axi_arlen     ( axi_mm_arlen      ),         
    /*input  [1 : 0]                     */   .axi_arlock    ( axi_mm_arlock     ),         
    /*input  [2 : 0]                     */   .axi_arprot    ( axi_mm_arprot     ),         
    /*input  [3 : 0]                     */   .axi_arqos     ( axi_mm_arqos      ),          
    /*output                             */   .axi_arready   ( axi_mm_arready    ),       
    /*input  [3 : 0]                     */   .axi_arregion  ( axi_mm_arregion   ),       
    /*input  [2 : 0]                     */   .axi_arsize    ( axi_mm_arsize     ),         
    /*input  [AXI_ARUSER_WIDTH-1 : 0]    */   .axi_aruser    ( axi_mm_aruser     ),         
    /*input                              */   .axi_arvalid   ( axi_mm_arvalid    ),       
    /* AXI4 read data interface */                                           
    /*output [AXI_DATA_WIDTH-1 : 0 ]     */   .axi_rdata     ( axi_mm_rdata      ),          
    /*output [AXI_ID_WIDTH-1 : 0 ]       */   .axi_rid       ( axi_mm_rid        ),            
    /*output                             */   .axi_rlast     ( axi_mm_rlast      ),          
    /*input                              */   .axi_rready    ( axi_mm_rready     ),         
    /*output [1 : 0 ]                    */   .axi_rresp     ( axi_mm_rresp      ),        
    /*output [AXI_RUSER_WIDTH-1 : 0 ]    */   .axi_ruser     ( axi_mm_ruser      ),          
    /*output reg                         */   .axi_rvalid    ( axi_mm_rvalid     ),         
    /* AXI4 write addr interface */                                          
    /*input  [AXI_ADDR_WIDTH-1 : 0]      */   .axi_awaddr    ( axi_mm_awaddr     ),         
    /*input  [1 : 0]                     */   .axi_awburst   ( axi_mm_awburst    ),        
    /*input  [3 : 0]                     */   .axi_awcache   ( axi_mm_awcache    ),        
    /*input  [AXI_ID_WIDTH-1 : 0]        */   .axi_awid      ( axi_mm_awid       ),           
    /*input  [7 : 0]                     */   .axi_awlen     ( axi_mm_awlen      ),         
    /*input  [1 : 0]                     */   .axi_awlock    ( axi_mm_awlock     ),         
    /*input  [2 : 0]                     */   .axi_awprot    ( axi_mm_awprot     ),         
    /*input  [3 : 0]                     */   .axi_awqos     ( axi_mm_awqos      ),          
    /*output reg                         */   .axi_awready   ( axi_mm_awready    ),       
    /*input  [3 : 0]                     */   .axi_awregion  ( axi_mm_awregion   ),       
    /*input  [2 : 0]                     */   .axi_awsize    ( axi_mm_awsize     ),         
    /*input  [AXI_ARUSER_WIDTH-1 : 0]    */   .axi_awuser    ( axi_mm_awuser     ),         
    /*input                              */   .axi_awvalid   ( axi_mm_awvalid    ),       
    /* AXI4 write data interface */                                          
    /*input  [AXI_DATA_WIDTH-1 : 0 ]     */   .axi_wdata     ( axi_mm_wdata      ),          
    /*input  [(AXI_DATA_WIDTH/8)-1 : 0 ] */   .axi_wstrb     ( axi_mm_wstrb      ),          
    /*input                              */   .axi_wlast     ( axi_mm_wlast      ),          
    /*input  [AXI_WUSER_WIDTH-1 : 0 ]    */   .axi_wuser     ( axi_mm_wuser      ),          
    /*input                              */   .axi_wvalid    ( axi_mm_wvalid     ),         
    /*output reg                         */   .axi_wready    ( axi_mm_wready     ),         
    /* AXI4 write resp interface */                                          
    /*output reg                         */   .axi_bvalid    ( axi_mm_bvalid     ),         
    /*output [1 : 0]                     */   .axi_bresp     ( axi_mm_bresp      ),         
    /*output [AXI_BUSER_WIDTH-1 : 0 ]    */   .axi_buser     ( axi_mm_buser      ),          
    /*output [AXI_ID_WIDTH-1 : 0 ]       */   .axi_bid       ( axi_mm_bid        ),
    /*input                              */   .axi_bready    ( axi_mm_bready     )
    );
`else
    //odma_axi_st_slave is ready, codes are as follows
    odma_axi_st_slave #(
        .AXIS_ID_WIDTH      ( AXIS_ID_WIDTH ),
        .AXIS_USER_WIDTH    ( AXIS_USER_WIDTH ),
        .AXIS_DATA_WIDTH    ( AXIS_DATA_WIDTH )
    ) st_slave(
        .clk                (ap_clk),
        .rst_n              (ap_rst_n),
        .axis_tvalid        (m_axis_tvalid),
        .axis_tready        (m_axis_tready),
        .axis_tdata         (m_axis_tdata),
        .axis_tkeep         (m_axis_tkeep),
        .axis_tlast         (m_axis_tlast),
        .axis_tid           (m_axis_tid),
        .axis_tuser         (m_axis_tuser)
    );

    //odma_axi_st_master is ready, codes are as follows
    odma_axi_st_master #(
        .AXIS_ID_WIDTH      ( AXIS_ID_WIDTH ),
        .AXIS_USER_WIDTH    ( AXIS_USER_WIDTH ),
        .AXIS_DATA_WIDTH    ( AXIS_DATA_WIDTH )
    ) st_master(
        .clk                (ap_clk),
        .rst_n              (ap_rst_n),
        .axis_tvalid        (s_axis_tvalid),
        .axis_tready        (s_axis_tready),
        .axis_tdata         (s_axis_tdata),
        .axis_tkeep         (s_axis_tkeep),
        .axis_tlast         (s_axis_tlast),
        .axis_tid           (s_axis_tid),
        .axis_tuser         (s_axis_tuser)
    );
`endif

//odma_axi_lite_slave is ready, codes are as follows		  
odma_axi_lite_slave 		lite_slave(
    .clk           (ap_clk         ),
    .aresetn       (ap_rst_n       ),
    
    .s_lite_arvalid(a_s_axi_arvalid),        
    .s_lite_araddr (a_s_axi_araddr ),         
    .s_lite_arready(a_s_axi_arready),        
    .s_lite_rvalid (a_s_axi_rvalid ),         
    .s_lite_rdata  (a_s_axi_rdata  ),          
    .s_lite_rresp  (a_s_axi_rresp  ),          
    .s_lite_rready (a_s_axi_rready ),         
    .s_lite_awvalid(a_s_axi_awvalid),        
    .s_lite_awaddr (a_s_axi_awaddr ),         
    .s_lite_awready(a_s_axi_awready),        
    .s_lite_wvalid (a_s_axi_wvalid ),         
    .s_lite_wdata  (a_s_axi_wdata  ),          
    .s_lite_wstrb  (a_s_axi_wstrb  ),          
    .s_lite_wready (a_s_axi_wready ),         
    .s_lite_bvalid (a_s_axi_bvalid ),         
    .s_lite_bresp  (a_s_axi_bresp  ),          
    .s_lite_bready (a_s_axi_bready )
);

odma_axi_lite_master 		lite_master(
    /*output                             */   .m_lite_arvalid( a_m_axi_arvalid ),        
    /*output [AXIL_ADDR_WIDTH-1 : 0]     */   .m_lite_araddr ( a_m_axi_araddr  ),         
    /*input                              */   .m_lite_arready( a_m_axi_arready ),        
    /*input                              */   .m_lite_rvalid ( a_m_axi_rvalid  ),         
    /*input  [AXIL_DATA_WIDTH-1 : 0 ]    */   .m_lite_rdata  ( a_m_axi_rdata   ),          
    /*input  [1 : 0 ]                    */   .m_lite_rresp  ( a_m_axi_rresp   ),          
    /*output                             */   .m_lite_rready ( a_m_axi_rready  ),         
    /*output                             */   .m_lite_awvalid( a_m_axi_awvalid ),        
    /*output [AXIL_ADDR_WIDTH-1 : 0]     */   .m_lite_awaddr ( a_m_axi_awaddr  ),         
    /*input                              */   .m_lite_awready( a_m_axi_awready ),        
    /*output                             */   .m_lite_wvalid ( a_m_axi_wvalid  ),         
    /*output [AXIL_DATA_WIDTH-1 : 0 ]    */   .m_lite_wdata  ( a_m_axi_wdata   ),          
    /*output [(AXIL_DATA_WIDTH/8)-1 : 0 ]*/   .m_lite_wstrb  ( a_m_axi_wstrb   ),          
    /*input                              */   .m_lite_wready ( a_m_axi_wready  ),         
    /*input                              */   .m_lite_bvalid ( a_m_axi_bvalid  ),         
    /*input  [1 : 0 ]                    */   .m_lite_bresp  ( a_m_axi_bresp   ),          
    /*output                             */   .m_lite_bready ( a_m_axi_bready  ) 
);

endmodule
`endif
