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

module kernel_perf_test # (
           // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
           parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
           parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,
       
           // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
           parameter C_M_AXI_HOST_MEM_ID_WIDTH      = 5,
           parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
           parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = 1024,
           parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = 1,
           parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = 1,
           parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
           parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
           parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1
)
(
input                                          clk                  ,
input                                          resetn                ,


//---- AXI bus interfaced with OCACCEL core ----
  // AXI write address channel
output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_gmem_awid     ,
output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]   m_axi_gmem_awaddr   ,
output    [0007:0]                              m_axi_gmem_awlen    ,
output    [0002:0]                              m_axi_gmem_awsize   ,
output    [0001:0]                              m_axi_gmem_awburst  ,
output    [0003:0]                              m_axi_gmem_awcache  ,
output    [0001:0]                              m_axi_gmem_awlock   ,
output    [0002:0]                              m_axi_gmem_awprot   ,
output    [0003:0]                              m_axi_gmem_awqos    ,
output    [0003:0]                              m_axi_gmem_awregion ,
output    [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0] m_axi_gmem_awuser   ,
output                                          m_axi_gmem_awvalid  ,
input                                           m_axi_gmem_awready  ,
  // AXI write data channel
output    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]   m_axi_gmem_wdata    ,
output    [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) -1:0]m_axi_gmem_wstrb    ,
output                                          m_axi_gmem_wlast    ,
output                                          m_axi_gmem_wvalid   ,
input                                           m_axi_gmem_wready   ,
output    [C_M_AXI_HOST_MEM_WUSER_WIDTH - 1:0]  m_axi_gmem_wuser    ,
  // AXI write response channel
output                                          m_axi_gmem_bready   ,
input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_gmem_bid      ,
input     [0001:0]                              m_axi_gmem_bresp    ,
input                                           m_axi_gmem_bvalid   ,
input     [C_M_AXI_HOST_MEM_BUSER_WIDTH - 1:0]  m_axi_gmem_buser    ,
  // AXI read address channel
output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_gmem_arid     ,
output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]   m_axi_gmem_araddr   ,
output    [0007:0]                              m_axi_gmem_arlen    ,
output    [0002:0]                              m_axi_gmem_arsize   ,
output    [0001:0]                              m_axi_gmem_arburst  ,
output    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_gmem_aruser   ,
output    [0003:0]                              m_axi_gmem_arcache  ,
output    [0001:0]                              m_axi_gmem_arlock   ,
output    [0002:0]                              m_axi_gmem_arprot   ,
output    [0003:0]                              m_axi_gmem_arqos    ,
output    [0003:0]                              m_axi_gmem_arregion ,
output                                          m_axi_gmem_arvalid  ,
input                                           m_axi_gmem_arready  ,
  // AXI  ead data channel
output                                          m_axi_gmem_rready   ,
input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_gmem_rid      ,
input     [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]   m_axi_gmem_rdata    ,
input     [0001:0]                              m_axi_gmem_rresp    ,
input                                           m_axi_gmem_rlast    ,
input                                           m_axi_gmem_rvalid   ,
input     [C_M_AXI_HOST_MEM_RUSER_WIDTH - 1:0]  m_axi_gmem_ruser    ,


//---- AXI Lite bus interfaced with OCACCEL core ----
  // AXI write address channel
output                                          s_axilite_cfg_awready  ,
input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0]   s_axilite_cfg_awaddr   ,
input                                           s_axilite_cfg_awvalid  ,
  // axi write data channel
output                                          s_axilite_cfg_wready   ,
input     [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0]   s_axilite_cfg_wdata    ,
input     [(C_S_AXI_CTRL_REG_DATA_WIDTH/8) -1:0]s_axilite_cfg_wstrb    ,
input                                           s_axilite_cfg_wvalid   ,
  // AXI response channel
output    [0001:0]                              s_axilite_cfg_bresp    ,
output                                          s_axilite_cfg_bvalid   ,
input                                           s_axilite_cfg_bready   ,
  // AXI read address channel
output                                          s_axilite_cfg_arready  ,
input                                           s_axilite_cfg_arvalid  ,
input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0]   s_axilite_cfg_araddr   ,
  // AXI read data channel
output    [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0]   s_axilite_cfg_rdata    ,
output    [0001:0]                              s_axilite_cfg_rresp    ,
input                                           s_axilite_cfg_rready   ,
output                                          s_axilite_cfg_rvalid   ,
output                                          interrupt

);

 

wire            engine_start_pulse ;
wire            wrap_mode          ;
wire  [03:0]    wrap_len           ;
wire  [63:0]    source_address     ;
wire  [63:0]    target_address     ;
wire  [31:0]    rd_init_data       ;
wire  [31:0]    wr_init_data       ;
wire  [31:0]    rd_pattern         ;
wire  [31:0]    rd_number          ;
wire  [31:0]    wr_pattern         ;
wire  [31:0]    wr_number          ;
wire            rd_done_pulse      ;
wire            wr_done_pulse      ;
wire  [1:0]     rd_error           ;
wire  [63:0]    rd_error_info      ;
wire            tt_arvalid         ; //arvalid & arready
wire            tt_rlast           ; //rlast & rvalid & rready
wire            tt_awvalid         ; //awvalid & awready
wire            tt_bvalid          ; //bvalid & bready
wire  [4:0]     tt_arid            ;
wire  [4:0]     tt_awid            ;
wire  [4:0]     tt_rid             ;
wire  [4:0]     tt_bid             ;



//---- registers hub for AXI Lite interface ----
 axi_lite_slave #(
           .DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   )
 ) maxi_lite_slave (
                      .clk                ( clk                ) ,
                      .resetn              ( resetn              ) ,
                      .s_axi_awready      ( s_axilite_cfg_awready ) ,
                      .s_axi_awaddr       ( s_axilite_cfg_awaddr  ) ,//32b
                      .s_axi_awvalid      ( s_axilite_cfg_awvalid ) ,
                      .s_axi_wready       ( s_axilite_cfg_wready  ) ,
                      .s_axi_wdata        ( s_axilite_cfg_wdata   ) ,//32b
                      .s_axi_wstrb        ( s_axilite_cfg_wstrb   ) ,//4b
                      .s_axi_wvalid       ( s_axilite_cfg_wvalid  ) ,
                      .s_axi_bresp        ( s_axilite_cfg_bresp   ) ,//2b
                      .s_axi_bvalid       ( s_axilite_cfg_bvalid  ) ,
                      .s_axi_bready       ( s_axilite_cfg_bready  ) ,
                      .s_axi_arready      ( s_axilite_cfg_arready ) ,
                      .s_axi_arvalid      ( s_axilite_cfg_arvalid ) ,
                      .s_axi_araddr       ( s_axilite_cfg_araddr  ) ,//32b
                      .s_axi_rdata        ( s_axilite_cfg_rdata   ) ,//32b
                      .s_axi_rresp        ( s_axilite_cfg_rresp   ) ,//2b
                      .s_axi_rready       ( s_axilite_cfg_rready  ) ,
                      .s_axi_rvalid       ( s_axilite_cfg_rvalid  ) ,

                      .engine_start_pulse ( engine_start_pulse ) ,
                      .wrap_mode          ( wrap_mode          ) ,
                      .wrap_len           ( wrap_len           ) ,
                      .source_address     ( source_address     ) ,
                      .target_address     ( target_address     ) ,
                      .rd_init_data       ( rd_init_data       ) ,
                      .wr_init_data       ( wr_init_data       ) ,
                      .rd_pattern         ( rd_pattern         ) ,
                      .rd_number          ( rd_number          ) ,
                      .wr_pattern         ( wr_pattern         ) ,
                      .wr_number          ( wr_number          ) ,

                      .rd_done_pulse      ( rd_done_pulse      ) ,
                      .wr_done_pulse      ( wr_done_pulse      ) ,
                      .rd_error           ( rd_error           ) ,
                      .rd_error_info      ( rd_error_info      ) ,
                      .wr_error           ( wr_error           ) ,
                      .tt_arvalid         ( tt_arvalid         ) , //arvalid & arready
                      .tt_rlast           ( tt_rlast           ) , //rlast & rvalid & rready
                      .tt_awvalid         ( tt_awvalid         ) , //awvalid & awready
                      .tt_bvalid          ( tt_bvalid          ) , //bvalid & bready

                      .tt_arid            ( tt_arid            ) ,
                      .tt_awid            ( tt_awid            ) ,
                      .tt_rid             ( tt_rid             ) ,
                      .tt_bid             ( tt_bid             ) 

           );
 assign tt_arvalid = m_axi_gmem_arvalid && m_axi_gmem_arready;
 assign tt_rlast = m_axi_gmem_rvalid && m_axi_gmem_rready && m_axi_gmem_rlast;
 assign tt_arid = m_axi_gmem_arid;
 assign tt_rid = m_axi_gmem_rid;

 assign tt_awvalid = m_axi_gmem_awvalid && m_axi_gmem_awready;
 assign tt_bvalid = m_axi_gmem_bvalid && m_axi_gmem_bready;
 assign tt_awid = m_axi_gmem_awid;
 assign tt_bid = m_axi_gmem_bid;

//---- writing channel of AXI master interface facing OCACCEL ----
 axi_master_wr#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   )
                ) maxi_master_wr( 
       .clk                (clk                ),
       .resetn              (resetn), 
       .m_axi_awid         (m_axi_gmem_awid    ), 
       .m_axi_awaddr       (m_axi_gmem_awaddr  ), 
       .m_axi_awlen        (m_axi_gmem_awlen   ),
       .m_axi_awsize       (m_axi_gmem_awsize  ),
       .m_axi_awburst      (m_axi_gmem_awburst ),
       .m_axi_awcache      (m_axi_gmem_awcache ),
       .m_axi_awlock       (m_axi_gmem_awlock  ),
       .m_axi_awprot       (m_axi_gmem_awprot  ),
       .m_axi_awqos        (m_axi_gmem_awqos   ),
       .m_axi_awregion     (m_axi_gmem_awregion),
       .m_axi_awuser       (m_axi_gmem_awuser  ),
       .m_axi_awvalid      (m_axi_gmem_awvalid ),
       .m_axi_awready      (m_axi_gmem_awready ),
       .m_axi_wdata        (m_axi_gmem_wdata   ),
       .m_axi_wstrb        (m_axi_gmem_wstrb   ),
       .m_axi_wlast        (m_axi_gmem_wlast   ),
       .m_axi_wvalid       (m_axi_gmem_wvalid  ),
       .m_axi_wready       (m_axi_gmem_wready  ),
       .m_axi_wuser        (m_axi_gmem_wuser   ),
       .m_axi_bready       (m_axi_gmem_bready  ),
       .m_axi_bid          (m_axi_gmem_bid     ), 
       .m_axi_bresp        (m_axi_gmem_bresp   ),
       .m_axi_bvalid       (m_axi_gmem_bvalid  ),
       .m_axi_buser        (m_axi_gmem_buser  ),
       .engine_start_pulse (engine_start_pulse  ),
       .wrap_mode          ( wrap_mode          ) ,
       .wrap_len           ( wrap_len           ) ,
       .target_address     (target_address     ),
       .wr_init_data       (wr_init_data       ),
       .wr_pattern         (wr_pattern         ),
       .wr_number          (wr_number          ),
       .wr_done_pulse      (wr_done_pulse      ),
       .wr_error           (wr_error           )
      );



//---- writing channel of AXI master interface facing OCACCEL ----
 axi_master_rd#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   )
                ) maxi_master_rd( 
      .clk                (clk                   ),
      .resetn             (resetn                ), 
      .m_axi_arid         (m_axi_gmem_arid    ),
      .m_axi_araddr       (m_axi_gmem_araddr  ),
      .m_axi_arlen        (m_axi_gmem_arlen   ),
      .m_axi_arsize       (m_axi_gmem_arsize  ),
      .m_axi_arburst      (m_axi_gmem_arburst ),
      .m_axi_aruser       (m_axi_gmem_aruser  ),
      .m_axi_arcache      (m_axi_gmem_arcache ),
      .m_axi_arlock       (m_axi_gmem_arlock  ),
      .m_axi_arprot       (m_axi_gmem_arprot  ),
      .m_axi_arqos        (m_axi_gmem_arqos   ),
      .m_axi_arregion     (m_axi_gmem_arregion),
      .m_axi_arvalid      (m_axi_gmem_arvalid ),
      .m_axi_arready      (m_axi_gmem_arready ),
      .m_axi_rready       (m_axi_gmem_rready  ),
      .m_axi_rid          (m_axi_gmem_rid     ),
      .m_axi_rdata        (m_axi_gmem_rdata   ),
      .m_axi_rresp        (m_axi_gmem_rresp   ),
      .m_axi_rlast        (m_axi_gmem_rlast   ),
      .m_axi_rvalid       (m_axi_gmem_rvalid  ),
      .m_axi_ruser        (m_axi_gmem_ruser   ),
      .engine_start_pulse (engine_start_pulse ),
      .wrap_mode          ( wrap_mode          ) ,
      .wrap_len           ( wrap_len           ) ,
      .source_address     (source_address     ),
      .rd_init_data       (rd_init_data       ),
      .rd_pattern         (rd_pattern         ),
      .rd_number          (rd_number          ),
      .rd_done_pulse      (rd_done_pulse      ),
      .rd_error           (rd_error           ),
      .rd_error_info      (rd_error_info      )
     );
assign interrupt = 0;
endmodule
