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
`timescale 1ns / 1ps


// data_bridge: The common part for CAPI2.0 and OpenCAPI3.0
//
//
//                                    
//             +-----------------+    
//             |   data_bridge   |    
//        <--->|  write_channel  |<-->
//      dma_wr*|                 |lcl_wr*
//             +-----------------+    
//                                    
//             +-----------------+    
//        <--->|   data_bridge   |<-->
//      dma_rd*|  read_channel   |lcl_rd*
//             |                 |    
//             +-----------------+    
//      

module data_bridge #(
                parameter IDW = 3, 
                parameter CTXW = 9, 
                parameter TAGW = 7
                )
                (
                   //---- synchronous clocks and reset ----------------------
                   input                 clk                        ,
                   input                 resetn                          ,


                   //----- lcl_   --------------------------------------
                  // write address & data channel
                   input                  lcl_wr_valid                  ,
                   input     [63:0]       lcl_wr_ea                     ,
                   input     [IDW-1:0]   lcl_wr_axi_id                 ,
                   input     [127:0]      lcl_wr_be                     ,
                   input                  lcl_wr_first                  ,
                   input                  lcl_wr_last                   ,
                   input     [1023:0]     lcl_wr_data                   ,
                   input                  lcl_wr_idle                   ,
                   output                 lcl_wr_ready                  ,
                   input                  lcl_wr_ctx_valid              ,
                   input      [CTXW-1:0]  lcl_wr_ctx                    ,
                  // write response channel
                   output                 lcl_wr_rsp_valid              ,
                   output      [IDW-1:0]  lcl_wr_rsp_axi_id             ,
                   output                 lcl_wr_rsp_code               ,
                   output     [CTXW-1:0]  lcl_wr_rsp_ctx                ,
                   input                  lcl_wr_rsp_ready              ,


                   // read address channel
                   input                  lcl_rd_valid                  ,
                   input     [63:0]       lcl_rd_ea                     ,
                   input     [IDW-1:0]   lcl_rd_axi_id                 ,
                   input     [127:0]      lcl_rd_be                     ,
                   input                  lcl_rd_first                  ,
                   input                  lcl_rd_last                   ,
                   input                  lcl_rd_idle                   ,
                   output                 lcl_rd_ready                  ,
                   input                  lcl_rd_ctx_valid              ,
                   input      [CTXW-1:0]  lcl_rd_ctx                    ,
                  // read response & data channel
                   output                 lcl_rd_data_valid             ,
                   output      [IDW-1:0] lcl_rd_data_axi_id            ,
                   output [1023:0]        lcl_rd_data                   ,
                   output                 lcl_rd_data_last              ,
                   output      [CTXW-1:0] lcl_rd_data_ctx               ,
                   output                 lcl_rd_rsp_code               ,
                   input                  lcl_rd_data_ready             ,


                   // dma interface
                   input                dma_wr_cmd_ready                 ,
                   output               dma_wr_cmd_valid                 ,
                   output     [1023:0]  dma_wr_cmd_data                  ,
                   output     [0127:0]  dma_wr_cmd_be                    ,
                   output     [0063:0]  dma_wr_cmd_ea                    ,
                   output     [TAGW-1:0]  dma_wr_cmd_tag                   ,
                   output     [CTXW-1:0]  dma_wr_cmd_ctx                   ,

                   input                dma_wr_resp_valid                ,
                   input      [1023:0]  dma_wr_resp_data                 ,//N/A
                   input      [TAGW-1:0]  dma_wr_resp_tag                  ,
                   input      [0001:0]  dma_wr_resp_pos                  ,
                   input      [0002:0]  dma_wr_resp_code                 ,
                
                   input                dma_rd_cmd_ready                 ,
                   output               dma_rd_cmd_valid                 ,
                   output     [1023:0]  dma_rd_cmd_data                  ,
                   output     [0127:0]  dma_rd_cmd_be                    ,
                   output     [0063:0]  dma_rd_cmd_ea                    ,
                   output     [TAGW-1:0]  dma_rd_cmd_tag                   ,
                   output     [CTXW-1:0]  dma_rd_cmd_ctx                   ,

                   input                dma_rd_resp_valid                ,
                   input      [1023:0]  dma_rd_resp_data                 ,
                   input      [TAGW-1:0]  dma_rd_resp_tag                  ,
                   input      [0001:0]  dma_rd_resp_pos                  ,
                   input      [0002:0]  dma_rd_resp_code                 ,

                   // debug bus
                   output     [195:0]      debug_bus

                   );



                
//===============================================================================================================
//         WIRES: context_surveil 
//===============================================================================================================

wire wbuf_empty, rbuf_empty;

wire [31:0] debug_axi_cnt_cmd_w;
wire [31:0] debug_axi_cnt_cmd_r;
wire [31:0] debug_axi_cnt_rsp_w;
wire [31:0] debug_axi_cnt_rsp_r;
wire [31:0] debug_buf_cnt_w;
wire [31:0] debug_buf_cnt_r;

wire [1:0] fir_fifo_overflow_dbr;
wire [1:0] fir_fifo_overflow_dbw;

//32*6 + 2 + 2 = 196
assign debug_bus = {fir_fifo_overflow_dbw, fir_fifo_overflow_dbr,
                    debug_axi_cnt_cmd_w, debug_axi_cnt_cmd_r, 
                    debug_axi_cnt_rsp_w, debug_axi_cnt_rsp_r,
                    debug_buf_cnt_w,     debug_buf_cnt_r};
//===============================================================================================================
// Data Bridge:
//     write_channel
//     read_channel
//===============================================================================================================
data_bridge_channel
                   #(
                     .IDW (IDW), 
                     .TAGW (TAGW), 
                     .MODE  (1'b0) //0: write; 1: read
                     )
                 data_brg_w (
                /*input                */   .clk                 ( clk             ),
                /*input                */   .resetn               ( resetn               ),
                /*output               */   .buf_empty           ( wbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_wr_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_wr_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_wr_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_wr_ea           ),
                /*input                */   .lcl_addr_ctx        ( lcl_wr_ctx          ),
                /*input      [CTXW-1:0]*/   .lcl_addr_ctx_valid  ( lcl_wr_ctx_valid    ),
                /*input      [IDW-1:0]*/    .lcl_addr_axi_id     ( lcl_wr_axi_id       ),
                /*input                */   .lcl_addr_first      ( lcl_wr_first        ),
                /*input                */   .lcl_addr_last       ( lcl_wr_last         ),
                /*input      [0127:0]  */   .lcl_addr_be         ( lcl_wr_be           ),
                    //--- data ---
                /*input      [1023:0]  */   .lcl_data_in         ( lcl_wr_data         ),
                /*output     [1023:0]  */   .lcl_data_out        (                     ),
                /*output               */   .lcl_data_out_last   (                     ),
                    //--- response and data out ---
                /*input                */   .lcl_resp_ready      ( lcl_wr_rsp_ready    ),
                /*output               */   .lcl_resp_valid      ( lcl_wr_rsp_valid    ),
                /*output     [IDW-1:0]*/    .lcl_resp_axi_id     ( lcl_wr_rsp_axi_id   ),
                /*output     [0001:0]  */   .lcl_resp_code       ( lcl_wr_rsp_code     ),
                /*output     [0001:0]  */   .lcl_resp_ctx        ( lcl_wr_rsp_ctx      ),


                //---- command encoder ---------------
                /*input                */   .dma_cmd_ready       ( dma_wr_cmd_ready       ),
                /*output reg           */   .dma_cmd_valid       ( dma_wr_cmd_valid       ),
                /*output reg [1023:0]  */   .dma_cmd_data        ( dma_wr_cmd_data        ),
                /*output reg [0127:0]  */   .dma_cmd_be          ( dma_wr_cmd_be          ),
                /*output reg [0063:0]  */   .dma_cmd_ea          ( dma_wr_cmd_ea          ),
                /*output reg [0005:0]  */   .dma_cmd_tag         ( dma_wr_cmd_tag         ),
                /*output reg [CTXW-1:0]*/   .dma_cmd_ctx         ( dma_wr_cmd_ctx         ),

                //---- response decoder --------------
                /*input                */   .dma_resp_valid      ( dma_wr_resp_valid      ),
                /*input      [1023:0]  */   .dma_resp_data       ( dma_wr_resp_data       ),//N/A
                /*input      [0005:0]  */   .dma_resp_tag        ( dma_wr_resp_tag        ),
                /*input      [0001:0]  */   .dma_resp_pos        ( dma_wr_resp_pos        ),
                /*input      [0002:0]  */   .dma_resp_code       ( dma_wr_resp_code       ),

                //---- control and status ------------
                /*input                */   .debug_cnt_clear       ( debug_cnt_clear          ),
                /*input      [0031:0]  */  // .debug_axi_cmd_idle_lim( debug_axi_cmd_idle_lim_w ),
                /*input      [0031:0]  */  // .debug_axi_rsp_idle_lim( debug_axi_rsp_idle_lim_w ),
                /*output               */  // .debug_axi_cmd_idle    ( debug_axi_cmd_idle_w     ),
                /*output               */  // .debug_axi_rsp_idle    ( debug_axi_rsp_idle_w     ),
                /*output     [0031:0]  */   .debug_axi_cnt_cmd     ( debug_axi_cnt_cmd_w      ), 
                /*output     [0031:0]  */   .debug_axi_cnt_rsp     ( debug_axi_cnt_rsp_w      ), 
                /*output     [0007:0]  */   .debug_buf_cnt         ( debug_buf_cnt_w          ), 
                /*output     [0001:0]  */   .fir_fifo_overflow     ( fir_fifo_overflow_dbw    )
                );

data_bridge_channel
                   #(
                     .IDW (IDW), 
                     .TAGW (TAGW), 
                     .MODE  (1'b1) //0: write; 1: read
                     )
                data_brg_r (
                /*input                */   .clk                 ( clk             ),
                /*input                */   .resetn               ( resetn               ),
                /*output               */   .buf_empty           ( rbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_rd_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_rd_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_rd_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_rd_ea           ),
                /*input                */   .lcl_addr_ctx        ( lcl_rd_ctx          ),
                /*input      [CTXW-1:0]*/   .lcl_addr_ctx_valid  ( lcl_rd_ctx_valid    ),
                /*input      [IDW-1:0] */   .lcl_addr_axi_id     ( lcl_rd_axi_id       ),
                /*input                */   .lcl_addr_first      ( lcl_rd_first        ),
                /*input                */   .lcl_addr_last       ( lcl_rd_last         ),
                /*input      [0127:0]  */   .lcl_addr_be         ( lcl_rd_be           ),
                    //--- data ---
                /*input      [1023:0]  */   .lcl_data_in         ( 1024'h0             ),
                /*output     [1023:0]  */   .lcl_data_out        ( lcl_rd_data         ),
                /*output               */   .lcl_data_out_last   ( lcl_rd_data_last    ),
                /*output     [0001:0]  */   .lcl_data_ctx        ( lcl_rd_data_ctx     ),
                    //--- response and data out ---
                /*input                */   .lcl_resp_ready      ( lcl_rd_data_ready   ),
                /*output               */   .lcl_resp_valid      ( lcl_rd_data_valid   ),
                /*output     [IDW-1:0] */   .lcl_resp_axi_id     ( lcl_rd_data_axi_id  ),
                /*output     [0001:0]  */   .lcl_resp_code       ( lcl_rd_rsp_code     ),
                /*output     [0001:0]  */   .lcl_resp_ctx        (                     ),


                //---- command encoder ---------------
                /*input                */   .dma_cmd_ready       ( dma_rd_cmd_ready     ),
                /*output reg           */   .dma_cmd_valid       ( dma_rd_cmd_valid     ),
                /*output reg [1023:0]  */   .dma_cmd_data        ( dma_rd_cmd_data      ),
                /*output reg [0127:0]  */   .dma_cmd_be          ( dma_rd_cmd_be        ),
                /*output reg [0063:0]  */   .dma_cmd_ea          ( dma_rd_cmd_ea        ),
                /*output reg [0005:0]  */   .dma_cmd_tag         ( dma_rd_cmd_tag       ),
                /*output reg [CTXW-1:0]*/   .dma_cmd_ctx         ( dma_rd_cmd_ctx       ),

                //---- response decoder --------------
                /*input                */   .dma_resp_valid      ( dma_rd_resp_valid    ),
                /*input      [1023:0]  */   .dma_resp_data       ( dma_rd_resp_data     ),
                /*input      [0005:0]  */   .dma_resp_tag        ( dma_rd_resp_tag      ),
                /*input      [0001:0]  */   .dma_resp_pos        ( dma_rd_resp_pos      ),
                /*input      [0002:0]  */   .dma_resp_code       ( dma_rd_resp_code     ),

                //---- control and status ------------
                /*input                */   .debug_cnt_clear       ( debug_cnt_clear          ),
                /*input      [0031:0]  */  // .debug_axi_cmd_idle_lim( debug_axi_cmd_idle_lim_r ),
                /*input      [0031:0]  */  // .debug_axi_rsp_idle_lim( debug_axi_rsp_idle_lim_r ),
                /*output               */  // .debug_axi_cmd_idle    ( debug_axi_cmd_idle_r     ),
                /*output               */  // .debug_axi_rsp_idle    ( debug_axi_rsp_idle_r     ),
                /*output     [0031:0]  */   .debug_axi_cnt_cmd     ( debug_axi_cnt_cmd_r      ), 
                /*output     [0031:0]  */   .debug_axi_cnt_rsp     ( debug_axi_cnt_rsp_r      ), 
                /*output     [0007:0]  */   .debug_buf_cnt         ( debug_buf_cnt_r          ), 
                /*output     [0001:0]  */   .fir_fifo_overflow     ( fir_fifo_overflow_dbr    )
                );


endmodule
