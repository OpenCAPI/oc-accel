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

module action_single_engine # (
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
           parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1
)
(
input                                          clk                  ,
input                                          resetn                ,


//---- AXI bus interfaced with OCACCEL core ----
  // AXI write address channel
output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_ocaccel_awid     ,
output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]   m_axi_ocaccel_awaddr   ,
output    [0007:0]                              m_axi_ocaccel_awlen    ,
output    [0002:0]                              m_axi_ocaccel_awsize   ,
output    [0001:0]                              m_axi_ocaccel_awburst  ,
output    [0003:0]                              m_axi_ocaccel_awcache  ,
output    [0001:0]                              m_axi_ocaccel_awlock   ,
output    [0002:0]                              m_axi_ocaccel_awprot   ,
output    [0003:0]                              m_axi_ocaccel_awqos    ,
output    [0003:0]                              m_axi_ocaccel_awregion ,
output    [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0] m_axi_ocaccel_awuser   ,
output                                          m_axi_ocaccel_awvalid  ,
input                                           m_axi_ocaccel_awready  ,
  // AXI write data channel
output    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]   m_axi_ocaccel_wdata    ,
output    [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) -1:0]m_axi_ocaccel_wstrb    ,
output                                          m_axi_ocaccel_wlast    ,
output                                          m_axi_ocaccel_wvalid   ,
input                                           m_axi_ocaccel_wready   ,
  // AXI write response channel
output                                          m_axi_ocaccel_bready   ,
input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_ocaccel_bid      ,
input     [0001:0]                              m_axi_ocaccel_bresp    ,
input                                           m_axi_ocaccel_bvalid   ,
  // AXI read address channel
output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_ocaccel_arid     ,
output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0]   m_axi_ocaccel_araddr   ,
output    [0007:0]                              m_axi_ocaccel_arlen    ,
output    [0002:0]                              m_axi_ocaccel_arsize   ,
output    [0001:0]                              m_axi_ocaccel_arburst  ,
output    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_ocaccel_aruser   ,
output    [0003:0]                              m_axi_ocaccel_arcache  ,
output    [0001:0]                              m_axi_ocaccel_arlock   ,
output    [0002:0]                              m_axi_ocaccel_arprot   ,
output    [0003:0]                              m_axi_ocaccel_arqos    ,
output    [0003:0]                              m_axi_ocaccel_arregion ,
output                                          m_axi_ocaccel_arvalid  ,
input                                           m_axi_ocaccel_arready  ,
  // AXI  ead data channel
output                                          m_axi_ocaccel_rready   ,
input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0]     m_axi_ocaccel_rid      ,
input     [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0]   m_axi_ocaccel_rdata    ,
input     [0001:0]                              m_axi_ocaccel_rresp    ,
input                                           m_axi_ocaccel_rlast    ,
input                                           m_axi_ocaccel_rvalid   ,


//---- AXI Lite bus interfaced with OCACCEL core ----
  // AXI write address channel
output                                          s_axi_ocaccel_awready  ,
input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0]   s_axi_ocaccel_awaddr   ,
input                                           s_axi_ocaccel_awvalid  ,
  // axi write data channel
output                                          s_axi_ocaccel_wready   ,
input     [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0]   s_axi_ocaccel_wdata    ,
input     [(C_S_AXI_CTRL_REG_DATA_WIDTH/8) -1:0]s_axi_ocaccel_wstrb    ,
input                                           s_axi_ocaccel_wvalid   ,
  // AXI response channel
output    [0001:0]                              s_axi_ocaccel_bresp    ,
output                                          s_axi_ocaccel_bvalid   ,
input                                           s_axi_ocaccel_bready   ,
  // AXI read address channel
output                                          s_axi_ocaccel_arready  ,
input                                           s_axi_ocaccel_arvalid  ,
input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0]   s_axi_ocaccel_araddr   ,
  // AXI read data channel
output    [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0]   s_axi_ocaccel_rdata    ,
output    [0001:0]                              s_axi_ocaccel_rresp    ,
input                                           s_axi_ocaccel_rready   ,
output                                          s_axi_ocaccel_rvalid   ,

// Other signals
input      [31:0]                               i_action_type       ,
input      [31:0]                               i_action_version
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
wire  [31:0]    ocaccel_context       ;



//---- registers hub for AXI Lite interface ----
 axi_lite_slave #(
           .DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   )
 ) maxi_lite_slave (
                      .clk                ( clk                ) ,
                      .resetn              ( resetn              ) ,
                      .s_axi_awready      ( s_axi_ocaccel_awready ) ,
                      .s_axi_awaddr       ( s_axi_ocaccel_awaddr  ) ,//32b
                      .s_axi_awvalid      ( s_axi_ocaccel_awvalid ) ,
                      .s_axi_wready       ( s_axi_ocaccel_wready  ) ,
                      .s_axi_wdata        ( s_axi_ocaccel_wdata   ) ,//32b
                      .s_axi_wstrb        ( s_axi_ocaccel_wstrb   ) ,//4b
                      .s_axi_wvalid       ( s_axi_ocaccel_wvalid  ) ,
                      .s_axi_bresp        ( s_axi_ocaccel_bresp   ) ,//2b
                      .s_axi_bvalid       ( s_axi_ocaccel_bvalid  ) ,
                      .s_axi_bready       ( s_axi_ocaccel_bready  ) ,
                      .s_axi_arready      ( s_axi_ocaccel_arready ) ,
                      .s_axi_arvalid      ( s_axi_ocaccel_arvalid ) ,
                      .s_axi_araddr       ( s_axi_ocaccel_araddr  ) ,//32b
                      .s_axi_rdata        ( s_axi_ocaccel_rdata   ) ,//32b
                      .s_axi_rresp        ( s_axi_ocaccel_rresp   ) ,//2b
                      .s_axi_rready       ( s_axi_ocaccel_rready  ) ,
                      .s_axi_rvalid       ( s_axi_ocaccel_rvalid  ) ,

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
                      .tt_bid             ( tt_bid             ) ,

                      .i_action_type      ( i_action_type      ) ,
                      .i_action_version   ( i_action_version   ) ,
                      .o_ocaccel_context     ( ocaccel_context       )
           );
 assign tt_arvalid = m_axi_ocaccel_arvalid && m_axi_ocaccel_arready;
 assign tt_rlast = m_axi_ocaccel_rvalid && m_axi_ocaccel_rready && m_axi_ocaccel_rlast;
 assign tt_arid = m_axi_ocaccel_arid;
 assign tt_rid = m_axi_ocaccel_rid;

 assign tt_awvalid = m_axi_ocaccel_awvalid && m_axi_ocaccel_awready;
 assign tt_bvalid = m_axi_ocaccel_bvalid && m_axi_ocaccel_bready;
 assign tt_awid = m_axi_ocaccel_awid;
 assign tt_bid = m_axi_ocaccel_bid;

//---- writing channel of AXI master interface facing OCACCEL ----
 axi_master_wr#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
                .AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
                .ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
                .WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
                .RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
                .BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
                ) maxi_master_wr( 
       .clk                (clk                ),
       .resetn              (resetn), 
       .m_axi_awid         (m_axi_ocaccel_awid    ), 
       .m_axi_awaddr       (m_axi_ocaccel_awaddr  ), 
       .m_axi_awlen        (m_axi_ocaccel_awlen   ),
       .m_axi_awsize       (m_axi_ocaccel_awsize  ),
       .m_axi_awburst      (m_axi_ocaccel_awburst ),
       .m_axi_awcache      (m_axi_ocaccel_awcache ),
       .m_axi_awlock       (m_axi_ocaccel_awlock  ),
       .m_axi_awprot       (m_axi_ocaccel_awprot  ),
       .m_axi_awqos        (m_axi_ocaccel_awqos   ),
       .m_axi_awregion     (m_axi_ocaccel_awregion),
       .m_axi_awuser       (m_axi_ocaccel_awuser  ),
       .m_axi_awvalid      (m_axi_ocaccel_awvalid ),
       .m_axi_awready      (m_axi_ocaccel_awready ),
       .m_axi_wdata        (m_axi_ocaccel_wdata   ),
       .m_axi_wstrb        (m_axi_ocaccel_wstrb   ),
       .m_axi_wlast        (m_axi_ocaccel_wlast   ),
       .m_axi_wvalid       (m_axi_ocaccel_wvalid  ),
       .m_axi_wready       (m_axi_ocaccel_wready  ),
       .m_axi_bready       (m_axi_ocaccel_bready  ),
       .m_axi_bid          (m_axi_ocaccel_bid     ), 
       .m_axi_bresp        (m_axi_ocaccel_bresp   ),
       .m_axi_bvalid       (m_axi_ocaccel_bvalid  ),
       .engine_start_pulse (engine_start_pulse ),
       .wrap_mode          ( wrap_mode          ) ,
       .wrap_len           ( wrap_len           ) ,
       .target_address     (target_address     ),
       .wr_init_data       (wr_init_data       ),
       .wr_pattern         (wr_pattern         ),
       .wr_number          (wr_number          ),
       .wr_done_pulse      (wr_done_pulse      ),
       .wr_error           (wr_error           ),
       .i_ocaccel_context     (ocaccel_context       )
      );



//---- writing channel of AXI master interface facing OCACCEL ----
 axi_master_rd#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
                .AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
                .ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
                .WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
                .RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
                .BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
                ) maxi_master_rd( 
      .clk                (clk                ),
      .resetn              (resetn), 
      .m_axi_arid         (m_axi_ocaccel_arid    ),
      .m_axi_araddr       (m_axi_ocaccel_araddr  ),
      .m_axi_arlen        (m_axi_ocaccel_arlen   ),
      .m_axi_arsize       (m_axi_ocaccel_arsize  ),
      .m_axi_arburst      (m_axi_ocaccel_arburst ),
      .m_axi_aruser       (m_axi_ocaccel_aruser  ),
      .m_axi_arcache      (m_axi_ocaccel_arcache ),
      .m_axi_arlock       (m_axi_ocaccel_arlock  ),
      .m_axi_arprot       (m_axi_ocaccel_arprot  ),
      .m_axi_arqos        (m_axi_ocaccel_arqos   ),
      .m_axi_arregion     (m_axi_ocaccel_arregion),
      .m_axi_arvalid      (m_axi_ocaccel_arvalid ),
      .m_axi_arready      (m_axi_ocaccel_arready ),
      .m_axi_rready       (m_axi_ocaccel_rready  ),
      .m_axi_rid          (m_axi_ocaccel_rid     ),
      .m_axi_rdata        (m_axi_ocaccel_rdata   ),
      .m_axi_rresp        (m_axi_ocaccel_rresp   ),
      .m_axi_rlast        (m_axi_ocaccel_rlast   ),
      .m_axi_rvalid       (m_axi_ocaccel_rvalid  ),
      .engine_start_pulse (engine_start_pulse ),
      .wrap_mode          ( wrap_mode          ) ,
      .wrap_len           ( wrap_len           ) ,
      .source_address     (source_address     ),
      .rd_init_data       (rd_init_data       ),
      .rd_pattern         (rd_pattern         ),
      .rd_number          (rd_number          ),
      .rd_done_pulse      (rd_done_pulse      ),
      .rd_error           (rd_error           ),
      .rd_error_info      (rd_error_info      ),
      .i_ocaccel_context     (ocaccel_context       )
     );

endmodule
