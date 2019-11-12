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

`include "snap_global_vars.v"
//                                    bridge_wrapper
//+------------------------------------------------------------------------------------------+
//|                                                                                          |
//| +--------+                                    +--------------------+                     |
//| |        |<-----------------------------------|   context_surveil  |<------------        |
//| |        |                                    +--------------------+            |        |
//| |  tlx_  |   +---------------------+                                            |        |
//| |  cmd_  |<--|    command_encode   |          +--------------------+            |        |
//| | clock_ |   |     write_channel   |<---------+                    |     +------+------+ |
//| |  conv  |   +---------------------+          |                    |<----|             | |
//| |        |   +---------------------+  +------>|     data_bridge    |     |             | |
//| |        |   |    command_encode   |  |       |    write_channel   |     |             | |
//| |        |<--|     read_channel    |<-+--+    |                    |---->|             | |
//| +--------+   +---------------------+  |  |    +--------------------+     |             | |
//|                                       |  |                               |  axi_slave  | |
//|                                       |  |                               |             | |
//| +--------+   +---------------------+  |  |    +--------------------+     |             | |
//| |        |-->|    response_decode  +--+  |    |                    |<----|             | |
//| |  tlx_  |   |     write_channel   |     +----+     data_bridge    |     |             | |
//| |  resp_ |   +---------------------+          |     read_channel   |     |             | |
//| | clock_ |   +---------------------+    +---->|                    |---->|             | |
//| |  conv  |   |    response_decode  |    |     +--------------------+     |             | |
//| |        |-->|     read_channel    |----+                                |             | |
//| +--------+   +---------------------+                                     +-------------+ |
//+------------------------------------------------------------------------------------------+

module brdg_wrapper (
                   //---- synchronous clocks and reset ----------------------
                   input                 clk_tlx                        ,
                   input                 clk_afu                        ,
                   input                 rst_n                          ,

                   //---- configurations ------------------------------------
                   input      [0003:0]   cfg_backoff_timer              ,
                   input      [0007:0]   cfg_bdf_bus                    ,
                   input      [0004:0]   cfg_bdf_device                 ,
                   input      [0002:0]   cfg_bdf_function               ,
                   input      [0011:0]   cfg_actag_base                 ,
                   input      [0019:0]   cfg_pasid_base                 ,
                   input      [0004:0]   cfg_pasid_length               ,

                   //---- mmio debug and FIR --------------------------------
                   input                 debug_cnt_clear                ,
                   output     [0063:0]   debug_tlx_cnt_cmd              ,
                   output     [0063:0]   debug_tlx_cnt_rsp              ,
                   output     [0063:0]   debug_tlx_cnt_retry            ,
                   output     [0063:0]   debug_tlx_cnt_fail             ,
                   output     [0063:0]   debug_tlx_cnt_xlt_pd           ,
                   output     [0063:0]   debug_tlx_cnt_xlt_done         ,
                   output     [0063:0]   debug_tlx_cnt_xlt_retry        ,
                   output     [0063:0]   debug_axi_cnt_cmd              ,
                   output     [0063:0]   debug_axi_cnt_rsp              ,
                   output     [0063:0]   debug_buf_cnt                  ,
                   output     [0063:0]   debug_traffic_idle             ,
                   input      [0063:0]   debug_tlx_idle_lim             ,
                   input      [0063:0]   debug_axi_idle_lim             ,
                   output     [0063:0]   fir_fifo_overflow              ,
                   output     [0063:0]   fir_tlx_interface              ,

                   //---- TLX -----------------------------------------------
                   output                afu_tlx_cmd_valid              ,
                   output     [0007:0]   afu_tlx_cmd_opcode             ,
                   output     [0011:0]   afu_tlx_cmd_actag              ,
                   output     [0003:0]   afu_tlx_cmd_stream_id          ,
                   output     [0067:0]   afu_tlx_cmd_ea_or_obj          ,
                   output     [0015:0]   afu_tlx_cmd_afutag             ,
                   output     [0001:0]   afu_tlx_cmd_dl                 ,
                   output     [0002:0]   afu_tlx_cmd_pl                 ,
                   output                afu_tlx_cmd_os                 ,
                   output     [0063:0]   afu_tlx_cmd_be                 ,
                   output     [0003:0]   afu_tlx_cmd_flag               ,
                   output                afu_tlx_cmd_endian             ,
                   output     [0015:0]   afu_tlx_cmd_bdf                ,
                   output     [0019:0]   afu_tlx_cmd_pasid              ,
                   output     [0005:0]   afu_tlx_cmd_pg_size            ,
                   output                afu_tlx_cdata_valid            ,
                   output                afu_tlx_cdata_bdi              ,
                   output     [0511:0]   afu_tlx_cdata_bus              ,
                   input                 tlx_afu_cmd_credit             ,
                   input                 tlx_afu_cmd_data_credit        ,
                   input      [0003:0]   tlx_afu_cmd_initial_credit     ,
                   input      [0005:0]   tlx_afu_cmd_data_initial_credit,
                   input                 tlx_afu_resp_valid             ,
                   input      [0015:0]   tlx_afu_resp_afutag            ,
                   input      [0007:0]   tlx_afu_resp_opcode            ,
                   input      [0003:0]   tlx_afu_resp_code              ,
                   input      [0001:0]   tlx_afu_resp_dl                ,
                   input      [0001:0]   tlx_afu_resp_dp                ,
                   output                afu_tlx_resp_rd_req            ,
                   output     [0002:0]   afu_tlx_resp_rd_cnt            ,
                   input                 tlx_afu_resp_data_valid        ,
                   input      [0511:0]   tlx_afu_resp_data_bus          ,
                   input                 tlx_afu_resp_data_bdi          ,
                   output                afu_tlx_resp_credit            ,
                   output     [0006:0]   afu_tlx_resp_initial_credit    ,

                   //----- AXI (slave) --------------------------------------
                   input     [`IDW-1:0]   s_axi_awid                     ,
                   input      [0063:0]   s_axi_awaddr                   ,
                   input      [0007:0]   s_axi_awlen                    ,
                   input      [0002:0]   s_axi_awsize                   ,
                   input      [0001:0]   s_axi_awburst                  ,
                   input                 s_axi_awvalid                  ,
                   output                s_axi_awready                  ,
                   input    [`CTXW-1:0]   s_axi_awuser                   ,
                   input      [1023:0]   s_axi_wdata                    ,
                   input      [0127:0]   s_axi_wstrb                    ,
                   input                 s_axi_wlast                    ,
                   input                 s_axi_wvalid                   ,
                   output                s_axi_wready                   ,
                   input                 s_axi_bready                   ,
                   output    [`IDW-1:0]   s_axi_bid                      ,
                   output     [0001:0]   s_axi_bresp                    ,
                   output                s_axi_bvalid                   ,
                   input     [`IDW-1:0]   s_axi_arid                     ,
                   input      [0063:0]   s_axi_araddr                   ,
                   input      [0007:0]   s_axi_arlen                    ,
                   input      [0002:0]   s_axi_arsize                   ,
                   input      [0001:0]   s_axi_arburst                  ,
                   input                 s_axi_arvalid                  ,
                   output                s_axi_arready                  ,
                   input    [`CTXW-1:0]   s_axi_aruser                   ,
                   input                 s_axi_rready                   ,
                   output    [`IDW-1:0]   s_axi_rid                      ,
                   output     [1023:0]   s_axi_rdata                    ,
                   output     [0001:0]   s_axi_rresp                    ,
                   output                s_axi_rlast                    ,
                   output                s_axi_rvalid                   ,
                   
                   // interrupt
                   output                interrupt_ack                  ,
                   input                 interrupt                      ,
                   input      [063:0]    interrupt_src                  ,
                   input      [008:0]    interrupt_ctx                  
                   );



//===============================================================================================================
//         WIRES: local bus between axi_slave and data bridge
//===============================================================================================================

// write address & data channel
wire            lcl_wr_valid;     
wire [63:0]     lcl_wr_ea;        
wire [`IDW-1:0]  lcl_wr_axi_id;    
wire [127:0]    lcl_wr_be;        
wire            lcl_wr_first;     
wire            lcl_wr_last;      
wire [1023:0]   lcl_wr_data;      
wire            lcl_wr_idle;      
wire            lcl_wr_ready;     
// write ctx channel
wire            lcl_wr_ctx_valid; 
wire [`CTXW-1:0] lcl_wr_ctx;       
// write response channel
wire            lcl_wr_rsp_valid; 
wire [`IDW-1:0]  lcl_wr_rsp_axi_id;
wire            lcl_wr_rsp_code;  
wire            lcl_wr_rsp_ready; 


// read address channel
wire            lcl_rd_valid;     
wire [63:0]     lcl_rd_ea;        
wire [`IDW-1:0]  lcl_rd_axi_id;    
wire [127:0]    lcl_rd_be;        
wire            lcl_rd_first;     
wire            lcl_rd_last;      
wire            lcl_rd_idle;      
wire            lcl_rd_ready;     
// read ctx channel
wire            lcl_rd_ctx_valid; 
wire [`CTXW-1:0] lcl_rd_ctx;       
// read response & data channel
wire            lcl_rd_data_valid;
wire [`IDW-1:0]  lcl_rd_data_axi_id;
wire [1023:0]   lcl_rd_data;      
wire            lcl_rd_data_last; 
wire            lcl_rd_rsp_code;  
wire            lcl_rd_data_ready;
                
//===============================================================================================================
//         WIRES: context_surveil to tlx_cmd_conv
//===============================================================================================================

wire            tlx_ac_cmd_valid  ;
wire   [019:0]  tlx_ac_cmd_pasid  ;
wire   [011:0]  tlx_ac_cmd_actag  ;
wire   [007:0]  tlx_ac_cmd_opcode ;
wire   [063:0]  tlx_r_cmd_be      ;

wire wbuf_empty, rbuf_empty;
wire last_context_cleared = wbuf_empty && rbuf_empty;
wire context_update_ongoing   ;

//===============================================================================================================
//         WIRES: data_bridge with cmd_enc & rsp_dec
//===============================================================================================================

//---- command encoder -----
wire            dma_w_cmd_ready ;
wire            dma_w_cmd_valid ;
wire [1023:0]   dma_w_cmd_data  ;
wire [0127:0]   dma_w_cmd_be    ;
wire [0063:0]   dma_w_cmd_ea    ;
wire [`TAGW-1:0] dma_w_cmd_tag   ;
wire            w_prt_cmd_valid ;
wire            w_prt_cmd_start ;
wire            w_prt_cmd_last  ;
wire            w_prt_cmd_enable;

//---- response decoder ----;
wire            dma_w_resp_valid;
wire [1023:0]   dma_w_resp_data ;
wire [`TAGW-1:0] dma_w_resp_tag  ;
wire [0001:0]   dma_w_resp_pos  ;
wire [0002:0]   dma_w_resp_code ;

//---- command encoder -----
wire            dma_r_cmd_ready ;
wire            dma_r_cmd_valid ;
wire [1023:0]   dma_r_cmd_data  ;
wire [0127:0]   dma_r_cmd_be    ;
wire [0063:0]   dma_r_cmd_ea    ;
wire [`TAGW-1:0] dma_r_cmd_tag   ;
wire            r_prt_cmd_valid ;
wire            r_prt_cmd_start ;
wire            r_prt_cmd_last  ;
wire            r_prt_cmd_enable;

//---- response decoder ----;
wire            dma_r_resp_valid;
wire [1023:0]   dma_r_resp_data ;
wire [`TAGW-1:0] dma_r_resp_tag  ;
wire [0001:0]   dma_r_resp_pos  ;
wire [0002:0]   dma_r_resp_code ;


//===============================================================================================================
//         WIRES: cmd_enc/rsp_dec to clock converters
//===============================================================================================================
//tlx_rsp_conv
wire           tlx_w_rsp_valid    ;
wire  [0015:0] tlx_w_rsp_afutag   ;
wire  [0007:0] tlx_w_rsp_opcode   ;
wire  [0003:0] tlx_w_rsp_code     ;
wire  [0001:0] tlx_w_rsp_dl       ;
wire  [0001:0] tlx_w_rsp_dp       ;


wire           tlx_r_rsp_valid    ;
wire  [0015:0] tlx_r_rsp_afutag   ;
wire  [0007:0] tlx_r_rsp_opcode   ;
wire  [0003:0] tlx_r_rsp_code     ;
wire  [0001:0] tlx_r_rsp_dl       ;
wire  [0001:0] tlx_r_rsp_dp       ;

wire           tlx_r_rdata_o_dv   ;
wire           tlx_r_rdata_e_dv   ;
wire           tlx_r_rdata_o_bdi  ;
wire           tlx_r_rdata_e_bdi  ;
wire  [0511:0] tlx_r_rdata_o      ;
wire  [0511:0] tlx_r_rdata_e      ;

//tlx_cmd_conv
wire           tlx_w_cmd_valid    ;
wire  [0007:0] tlx_w_cmd_opcode   ;
wire  [0067:0] tlx_w_cmd_ea_or_obj;
wire  [0015:0] tlx_w_cmd_afutag   ;
wire  [0001:0] tlx_w_cmd_dl       ;
wire  [0002:0] tlx_w_cmd_pl       ;
wire  [0063:0] tlx_w_cmd_be       ;
wire  [1023:0] tlx_w_cdata_bus    ;
wire           tlx_w_cmd_ready    ;

wire           tlx_r_cmd_valid    ;
wire  [0007:0] tlx_r_cmd_opcode   ;
wire  [0067:0] tlx_r_cmd_ea_or_obj;
wire  [0015:0] tlx_r_cmd_afutag   ;
wire  [0001:0] tlx_r_cmd_dl       ;
wire  [0002:0] tlx_r_cmd_pl       ;
wire           tlx_r_cmd_ready    ;
wire  [1023:0] tlx_r_cdata_bus    ;

//debug and FIR from submodules
wire  [0031:0] debug_tlx_cnt_cmd_w       ;
wire  [0001:0] fir_fifo_overflow_cmdencw ;
wire  [0031:0] debug_tlx_cnt_cmd_r       ;
wire  [0001:0] fir_fifo_overflow_cmdencr ;
wire           debug_tlx_cmd_idle        ;
wire  [0004:0] fir_fifo_overflow_cmdcnv  ;
wire  [0001:0] fir_tlx_cmd_credit        ;
wire  [0031:0] debug_tlx_rsp_idle_lim   = debug_tlx_idle_lim[63:32];      
wire  [0031:0] debug_tlx_cmd_idle_lim   = debug_tlx_idle_lim[31:00];
wire           debug_tlx_rsp_idle        ;      
wire  [0005:0] fir_fifo_overflow_rspcnv  ;      
wire           fir_tlx_rsp_err           ;      
wire           fir_tlx_response_unsupport;      
wire  [0031:0] debug_tlx_cnt_rsp_w       ;
wire  [0031:0] debug_tlx_cnt_retry_w     ;
wire  [0031:0] debug_tlx_cnt_fail_w      ;
wire  [0031:0] debug_tlx_cnt_xlt_pd_w    ;
wire  [0031:0] debug_tlx_cnt_xlt_done_w  ;
wire  [0031:0] debug_tlx_cnt_xlt_retry_w ;
wire  [0004:0] fir_fifo_overflow_rspdecw ;
wire  [0031:0] debug_tlx_cnt_rsp_r       ;
wire  [0031:0] debug_tlx_cnt_retry_r     ;
wire  [0031:0] debug_tlx_cnt_fail_r      ;
wire  [0031:0] debug_tlx_cnt_xlt_pd_r    ;
wire  [0031:0] debug_tlx_cnt_xlt_done_r  ;
wire  [0031:0] debug_tlx_cnt_xlt_retry_r ;
wire  [0004:0] fir_fifo_overflow_rspdecr ;
wire  [0031:0] debug_axi_cmd_idle_lim_w   = debug_axi_idle_lim[31:00];
wire  [0031:0] debug_axi_rsp_idle_lim_w   = debug_axi_idle_lim[63:32];
wire           debug_axi_cmd_idle_w      ;
wire           debug_axi_rsp_idle_w      ;
wire  [0031:0] debug_axi_cnt_cmd_w       ;
wire  [0031:0] debug_axi_cnt_rsp_w       ;
wire  [0007:0] debug_buf_cnt_w           ;
wire  [0001:0] fir_fifo_overflow_dbw     ;
wire  [0031:0] debug_axi_cmd_idle_lim_r   = debug_axi_idle_lim[31:00];
wire  [0031:0] debug_axi_rsp_idle_lim_r   = debug_axi_idle_lim[63:32];
wire           debug_axi_cmd_idle_r      ;
wire           debug_axi_rsp_idle_r      ;
wire  [0031:0] debug_axi_cnt_cmd_r       ; 
wire  [0031:0] debug_axi_cnt_rsp_r       ; 
wire  [0007:0] debug_buf_cnt_r           ; 
wire  [0001:0] fir_fifo_overflow_dbr     ;
wire  [0001:0] fir_tlx_command_credit    ;

// debug and FIR for MMIO
 assign debug_tlx_cnt_cmd       = {debug_tlx_cnt_cmd_r, debug_tlx_cnt_cmd_w};
 assign debug_tlx_cnt_rsp       = {debug_tlx_cnt_rsp_r, debug_tlx_cnt_rsp_w};
 assign debug_tlx_cnt_retry     = {debug_tlx_cnt_retry_r, debug_tlx_cnt_retry_w};
 assign debug_tlx_cnt_fail      = {debug_tlx_cnt_fail_r, debug_tlx_cnt_fail_w};
 assign debug_tlx_cnt_xlt_pd    = {debug_tlx_cnt_xlt_pd_r, debug_tlx_cnt_xlt_pd_w};
 assign debug_tlx_cnt_xlt_done  = {debug_tlx_cnt_xlt_done_r, debug_tlx_cnt_xlt_done_w};
 assign debug_tlx_cnt_xlt_retry = {debug_tlx_cnt_xlt_retry_r, debug_tlx_cnt_xlt_retry_w};
 assign debug_axi_cnt_cmd       = {debug_axi_cnt_cmd_r, debug_axi_cnt_cmd_w}; 
 assign debug_axi_cnt_rsp       = {debug_axi_cnt_rsp_r, debug_axi_cnt_rsp_w}; 
 assign debug_buf_cnt           = {24'd0, debug_buf_cnt_r, 24'd0, debug_buf_cnt_w}; 
 assign debug_traffic_idle      = {58'd0, debug_tlx_cmd_idle, debug_tlx_rsp_idle, debug_axi_cmd_idle_r, debug_axi_rsp_idle_r, debug_axi_cmd_idle_w, debug_axi_rsp_idle_w};
 assign fir_fifo_overflow       = {56'd0, fir_fifo_overflow_cmdencw, fir_fifo_overflow_cmdencr, fir_fifo_overflow_cmdcnv, fir_fifo_overflow_rspcnv, fir_fifo_overflow_rspdecw, fir_fifo_overflow_rspdecr, fir_fifo_overflow_dbw, fir_fifo_overflow_dbr};
 assign fir_tlx_interface       = {60'd0, fir_tlx_response_unsupport, fir_tlx_rsp_err, fir_tlx_command_credit};


wire           tlx_i_cmd_valid  ;
wire  [0067:0] tlx_i_cmd_obj    ;
wire  [0015:0] tlx_i_cmd_afutag ;
wire  [0007:0] tlx_i_cmd_opcode ;
wire           tlx_i_rsp_valid  ;
wire  [0015:0] tlx_i_rsp_afutag ;
wire  [0007:0] tlx_i_rsp_opcode ;
wire  [0003:0] tlx_i_rsp_code   ;


//===============================================================================================================
// Clock converters:
//     tlx_cmd_converter: from 200MHz (data bridge) to 400MHz (tlx domain)
//     tlx_rsp_converter: from 400MHz (tlx domain)  to 200MHz (data bridge)
//
//===============================================================================================================



brdg_tlx_cmd_converter tlx_cmd_conv (
                /*input                 */   .clk_tlx                         ( clk_tlx                         ),
                /*input                 */   .clk_afu                         ( clk_afu                         ),
                /*input                 */   .rst_n                           ( rst_n                           ),

                //---- configuration ---------------------------------
                /*input      [007:0]    */   .cfg_bdf_bus                     ( cfg_bdf_bus                     ),
                /*input      [004:0]    */   .cfg_bdf_device                  ( cfg_bdf_device                  ),
                /*input      [002:0]    */   .cfg_bdf_function                ( cfg_bdf_function                ),

                //---- TLX side interface --------------------------------
                  // command
                /*output reg            */   .afu_tlx_cmd_valid               ( afu_tlx_cmd_valid               ),
                /*output reg [007:0]    */   .afu_tlx_cmd_opcode              ( afu_tlx_cmd_opcode              ),
                /*output reg [011:0]    */   .afu_tlx_cmd_actag               ( afu_tlx_cmd_actag               ),
                /*output     [003:0]    */   .afu_tlx_cmd_stream_id           ( afu_tlx_cmd_stream_id           ),
                /*output reg [067:0]    */   .afu_tlx_cmd_ea_or_obj           ( afu_tlx_cmd_ea_or_obj           ),
                /*output reg [015:0]    */   .afu_tlx_cmd_afutag              ( afu_tlx_cmd_afutag              ),
                /*output reg [001:0]    */   .afu_tlx_cmd_dl                  ( afu_tlx_cmd_dl                  ),
                /*output reg [002:0]    */   .afu_tlx_cmd_pl                  ( afu_tlx_cmd_pl                  ),
                /*output                */   .afu_tlx_cmd_os                  ( afu_tlx_cmd_os                  ),
                /*output     [063:0]    */   .afu_tlx_cmd_be                  ( afu_tlx_cmd_be                  ),
                /*output     [003:0]    */   .afu_tlx_cmd_flag                ( afu_tlx_cmd_flag                ),
                /*output                */   .afu_tlx_cmd_endian              ( afu_tlx_cmd_endian              ),
                /*output     [015:0]    */   .afu_tlx_cmd_bdf                 ( afu_tlx_cmd_bdf                 ),
                /*output reg [019:0]    */   .afu_tlx_cmd_pasid               ( afu_tlx_cmd_pasid               ),
                /*output     [005:0]    */   .afu_tlx_cmd_pg_size             ( afu_tlx_cmd_pg_size             ),
                  // write data
                /*output reg            */   .afu_tlx_cdata_valid             ( afu_tlx_cdata_valid             ),
                /*output reg            */   .afu_tlx_cdata_bdi               ( afu_tlx_cdata_bdi               ),
                /*output reg [511:0]    */   .afu_tlx_cdata_bus               ( afu_tlx_cdata_bus               ),
                  // command and write data credit
                /*input                 */   .tlx_afu_cmd_credit              ( tlx_afu_cmd_credit              ),
                /*input                 */   .tlx_afu_cmd_data_credit         ( tlx_afu_cmd_data_credit         ),
                /*input      [003:0]    */   .tlx_afu_cmd_initial_credit      ( tlx_afu_cmd_initial_credit      ),
                /*input      [005:0]    */   .tlx_afu_cmd_data_initial_credit (tlx_afu_cmd_data_initial_credit  ),

                //---- AFU side interface --------------------------------
                  // write channel
                /*input                 */   .tlx_wr_cmd_valid                ( tlx_w_cmd_valid                ),
                /*input      [0007:0]   */   .tlx_wr_cmd_opcode               ( tlx_w_cmd_opcode               ),
                /*input      [0067:0]   */   .tlx_wr_cmd_ea_or_obj            ( tlx_w_cmd_ea_or_obj            ),
                /*input      [0015:0]   */   .tlx_wr_cmd_afutag               ( tlx_w_cmd_afutag               ),
                /*input      [0001:0]   */   .tlx_wr_cmd_dl                   ( tlx_w_cmd_dl                   ),
                /*input      [0002:0]   */   .tlx_wr_cmd_pl                   ( tlx_w_cmd_pl                   ),
                /*input      [0063:0]   */   .tlx_wr_cmd_be                   ( tlx_w_cmd_be                   ),
                /*input      [1023:0]   */   .tlx_wr_cdata_bus                ( tlx_w_cdata_bus                ),
                /*output                */   .tlx_wr_cmd_ready                ( tlx_w_cmd_ready                ),

                // read channel
                /*input                 */   .tlx_rd_cmd_valid                ( tlx_r_cmd_valid                ),
                /*input      [0007:0]   */   .tlx_rd_cmd_opcode               ( tlx_r_cmd_opcode               ),
                /*input      [0067:0]   */   .tlx_rd_cmd_ea_or_obj            ( tlx_r_cmd_ea_or_obj            ),
                /*input      [0015:0]   */   .tlx_rd_cmd_afutag               ( tlx_r_cmd_afutag               ),
                /*input      [0001:0]   */   .tlx_rd_cmd_dl                   ( tlx_r_cmd_dl                   ),
                /*input      [0002:0]   */   .tlx_rd_cmd_pl                   ( tlx_r_cmd_pl                   ),
                /*output                */   .tlx_rd_cmd_ready                ( tlx_r_cmd_ready                ),

                // assign ACTAG channel
                /*input                 */   .tlx_ac_cmd_valid                ( tlx_ac_cmd_valid               ),
                /*input      [0019:0]   */   .tlx_ac_cmd_pasid                ( tlx_ac_cmd_pasid               ),
                /*input      [0011:0]   */   .tlx_ac_cmd_actag                ( tlx_ac_cmd_actag               ),
                /*input      [0007:0]   */   .tlx_ac_cmd_opcode               ( tlx_ac_cmd_opcode              ),

                // interrupt channel
                /*input                 */   .tlx_in_cmd_valid                ( tlx_i_cmd_valid                ),
                /*input      [067:0]    */   .tlx_in_cmd_obj                  ( tlx_i_cmd_obj                  ),
                /*input      [015:0]    */   .tlx_in_cmd_afutag               ( tlx_i_cmd_afutag               ),     
                /*input      [007:0]    */   .tlx_in_cmd_opcode               ( tlx_i_cmd_opcode               ),

                //---- control and status --------------------------------
                /*input      [031:0]    */   .debug_tlx_cmd_idle_lim          ( debug_tlx_cmd_idle_lim         ),
                /*output                */   .debug_tlx_cmd_idle              ( debug_tlx_cmd_idle             ),
                /*output     [0004:0]   */   .fir_fifo_overflow               ( fir_fifo_overflow_cmdcnv       ),
                /*output     [0001:0]   */   .fir_tlx_command_credit          ( fir_tlx_command_credit         )
                );


brdg_tlx_rsp_converter tlx_rsp_conv(
                /*input                 */   .clk_tlx                         ( clk_tlx                         ),
                /*input                 */   .clk_afu                         ( clk_afu                         ),
                /*input                 */   .rst_n                           ( rst_n                           ),

                //---- TLX side interface --------------------------------
                  // response
                /*input                 */   .tlx_afu_resp_valid              ( tlx_afu_resp_valid              ),
                /*input      [015:0]    */   .tlx_afu_resp_afutag             ( tlx_afu_resp_afutag             ),
                /*input      [007:0]    */   .tlx_afu_resp_opcode             ( tlx_afu_resp_opcode             ),
                /*input      [003:0]    */   .tlx_afu_resp_code               ( tlx_afu_resp_code               ),
                /*input      [001:0]    */   .tlx_afu_resp_dl                 ( tlx_afu_resp_dl                 ),
                /*input      [001:0]    */   .tlx_afu_resp_dp                 ( tlx_afu_resp_dp                 ),
                  // read data
                /*output reg            */   .afu_tlx_resp_rd_req             ( afu_tlx_resp_rd_req             ),
                /*output reg [002:0]    */   .afu_tlx_resp_rd_cnt             ( afu_tlx_resp_rd_cnt             ),
                /*input                 */   .tlx_afu_resp_data_valid         ( tlx_afu_resp_data_valid         ),
                /*input      [511:0]    */   .tlx_afu_resp_data_bus           ( tlx_afu_resp_data_bus           ),
                /*input                 */   .tlx_afu_resp_data_bdi           ( tlx_afu_resp_data_bdi           ),
                  // response credit
                /*output reg            */   .afu_tlx_resp_credit             ( afu_tlx_resp_credit             ),
                /*output     [006:0]    */   .afu_tlx_resp_initial_credit     ( afu_tlx_resp_initial_credit     ),


                //---- AFU side interface --------------------------------
                  // write channel
                /*output                */   .tlx_w_rsp_valid                ( tlx_w_rsp_valid                ),
                /*output     [015:0]    */   .tlx_w_rsp_afutag               ( tlx_w_rsp_afutag               ),
                /*output     [007:0]    */   .tlx_w_rsp_opcode               ( tlx_w_rsp_opcode               ),
                /*output     [003:0]    */   .tlx_w_rsp_code                 ( tlx_w_rsp_code                 ),
                /*output     [001:0]    */   .tlx_w_rsp_dl                   ( tlx_w_rsp_dl                   ),
                /*output     [001:0]    */   .tlx_w_rsp_dp                   ( tlx_w_rsp_dp                   ),
                  // read channel
                /*output                */   .tlx_r_rsp_valid                ( tlx_r_rsp_valid                ),
                /*output     [015:0]    */   .tlx_r_rsp_afutag               ( tlx_r_rsp_afutag               ),
                /*output     [007:0]    */   .tlx_r_rsp_opcode               ( tlx_r_rsp_opcode               ),
                /*output     [003:0]    */   .tlx_r_rsp_code                 ( tlx_r_rsp_code                 ),
                /*output     [001:0]    */   .tlx_r_rsp_dl                   ( tlx_r_rsp_dl                   ),
                /*output     [001:0]    */   .tlx_r_rsp_dp                   ( tlx_r_rsp_dp                   ),
                /*input                */    .tlx_r_rdata_o_dv               ( tlx_r_rdata_o_dv               ),
                /*input                */    .tlx_r_rdata_e_dv               ( tlx_r_rdata_e_dv               ),
                /*output                */   .tlx_r_rdata_o_bdi              ( tlx_r_rdata_o_bdi              ),
                /*output                */   .tlx_r_rdata_e_bdi              ( tlx_r_rdata_e_bdi              ),
                /*output     [511:0]    */   .tlx_r_rdata_o                  ( tlx_r_rdata_o                  ),
                /*output     [511:0]    */   .tlx_r_rdata_e                  ( tlx_r_rdata_e                  ),
                  // interrupt channel
                /*input              */      .tlx_i_rsp_valid                ( tlx_i_rsp_valid                ),
                /*input      [0015:0]*/      .tlx_i_rsp_afutag               ( tlx_i_rsp_afutag               ),
                /*input      [0007:0]*/      .tlx_i_rsp_opcode               ( tlx_i_rsp_opcode               ),
                /*input      [0003:0]*/      .tlx_i_rsp_code                 ( tlx_i_rsp_code                 ),

                //---- control and status ---------------------
                /*input      [031:0]   */    .debug_tlx_rsp_idle_lim         ( debug_tlx_rsp_idle_lim         ),
                /*output               */    .debug_tlx_rsp_idle             ( debug_tlx_rsp_idle             ),
                /*output     [005:0]   */    .fir_fifo_overflow              ( fir_fifo_overflow_rspcnv       ),
	               /*output               */    .fir_tlx_rsp_err                ( fir_tlx_rsp_err                )
                );





//===============================================================================================================
// Command Encode:
//     write_channel
//     read_channel
//===============================================================================================================



brdg_command_encode
                #(
                  .MODE (1'b0) //0: write; 1: read
                  )
                cmd_enc_w (
                /*input                 */   .clk                          ( clk_afu                      ),
                /*input                 */   .rst_n                        ( rst_n                        ),

                //---- communication with command decoder -----
                /*output                */   .prt_cmd_valid                ( w_prt_cmd_valid              ),
                /*output                */   .prt_cmd_last                 ( w_prt_cmd_last               ),
                /*output                */   .prt_cmd_start                ( w_prt_cmd_start              ),
                /*input                 */   .prt_cmd_enable               ( w_prt_cmd_enable             ),

                //---- DMA interface ---------------------------------
                /*output                */   .dma_cmd_ready                ( dma_w_cmd_ready                ),
                /*input                 */   .dma_cmd_valid                ( dma_w_cmd_valid                ),
                /*input      [1023:0]   */   .dma_cmd_data                 ( dma_w_cmd_data                 ),
                /*input      [0127:0]   */   .dma_cmd_be                   ( dma_w_cmd_be                   ),
                /*input      [0063:0]   */   .dma_cmd_ea                   ( dma_w_cmd_ea                   ),
                /*input      [0005:0]   */   .dma_cmd_tag                  ( dma_w_cmd_tag                  ),

                //---- TLX interface ---------------------------------
                  // command
                /*output reg            */   .tlx_cmd_valid                ( tlx_w_cmd_valid                ),
                /*output reg [0007:0]   */   .tlx_cmd_opcode               ( tlx_w_cmd_opcode               ),
                /*output reg [0067:0]   */   .tlx_cmd_ea_or_obj            ( tlx_w_cmd_ea_or_obj            ),
                /*output reg [0015:0]   */   .tlx_cmd_afutag               ( tlx_w_cmd_afutag               ),
                /*output reg [0001:0]   */   .tlx_cmd_dl                   ( tlx_w_cmd_dl                   ),
                /*output reg [0002:0]   */   .tlx_cmd_pl                   ( tlx_w_cmd_pl                   ),
                /*output     [0063:0]   */   .tlx_cmd_be                   ( tlx_w_cmd_be                   ),
                /*output reg [1023:0]   */   .tlx_cdata_bus                ( tlx_w_cdata_bus                ),

                  // credit availability
                /*input                 */   .tlx_cmd_rdy                  ( tlx_w_cmd_ready                ),

                //---- control and status ---------------------
                /*input                 */   .debug_cnt_clear              (debug_cnt_clear                 ),
                /*output     [0031:0]   */   .debug_tlx_cnt_cmd            (debug_tlx_cnt_cmd_w             ),
                /*output     [0001:0]   */   .fir_fifo_overflow            (fir_fifo_overflow_cmdencw       )
                );


brdg_command_encode
                #(
                  .MODE  (1'b1) //0: write; 1: read
                  )
                cmd_enc_r  (
                /*input                 */   .clk                          ( clk_afu                      ),
                /*input                 */   .rst_n                        ( rst_n                        ),

                //---- communication with command decoder -----
                /*output                */   .prt_cmd_valid                ( r_prt_cmd_valid              ),
                /*output                */   .prt_cmd_last                 ( r_prt_cmd_last               ),
                /*output                */   .prt_cmd_start                ( r_prt_cmd_start              ),
                /*input                 */   .prt_cmd_enable               ( r_prt_cmd_enable             ),

                //---- DMA interface ---------------------------------
                /*output                */   .dma_cmd_ready                ( dma_r_cmd_ready                ),
                /*input                 */   .dma_cmd_valid                ( dma_r_cmd_valid                ),
                /*input      [1023:0]   */   .dma_cmd_data                 ( dma_r_cmd_data                 ),
                /*input      [0127:0]   */   .dma_cmd_be                   ( dma_r_cmd_be                   ),
                /*input      [0063:0]   */   .dma_cmd_ea                   ( dma_r_cmd_ea                   ),
                /*input      [0005:0]   */   .dma_cmd_tag                  ( dma_r_cmd_tag                  ),

                //---- TLX interface ---------------------------------
                  // command
                /*output reg            */   .tlx_cmd_valid                ( tlx_r_cmd_valid                ),
                /*output reg [0007:0]   */   .tlx_cmd_opcode               ( tlx_r_cmd_opcode               ),
                /*output reg [0067:0]   */   .tlx_cmd_ea_or_obj            ( tlx_r_cmd_ea_or_obj            ),
                /*output reg [0015:0]   */   .tlx_cmd_afutag               ( tlx_r_cmd_afutag               ),
                /*output reg [0001:0]   */   .tlx_cmd_dl                   ( tlx_r_cmd_dl                   ),
                /*output reg [0002:0]   */   .tlx_cmd_pl                   ( tlx_r_cmd_pl                   ),
                /*output     [0063:0]   */   .tlx_cmd_be                   ( tlx_r_cmd_be                   ),
                /*output reg [1023:0]   */   .tlx_cdata_bus                ( tlx_r_cdata_bus                ),

                  // credit availability
                /*input                 */   .tlx_cmd_rdy                  ( tlx_r_cmd_ready                ),

                //---- control and status ---------------------
                /*input                 */   .debug_cnt_clear              (debug_cnt_clear                 ),
                /*output     [0031:0]   */   .debug_tlx_cnt_cmd            (debug_tlx_cnt_cmd_r             ),
                /*output     [0001:0]   */   .fir_fifo_overflow            (fir_fifo_overflow_cmdencr       )
                );

//===============================================================================================================
// Response Decode:
//     write_channel
//     read_channel
//===============================================================================================================

brdg_response_decode
                #(
                 .MODE  (1'b0) //0: write; 1: read
                 )
                rsp_dec_w (
                /*input                 */   .clk               ( clk_afu           ),
                /*input                 */   .rst_n             ( rst_n             ),

                //---- configuration --------------------------------------
                /*input      [0003:0]   */   .cfg_backoff_timer ( cfg_backoff_timer ),
                       
                //---- communication with command decoder -----
                /*input                 */   .prt_cmd_valid     ( w_prt_cmd_valid   ),
                /*input                 */   .prt_cmd_last      ( w_prt_cmd_last    ),
                /*output reg            */   .prt_cmd_enable    ( w_prt_cmd_enable  ),
                /*output                */   .prt_cmd_start     ( w_prt_cmd_start   ),

                //---- DMA interface --------------------------
                /*output reg            */   .dma_resp_valid    ( dma_w_resp_valid  ),
                /*output reg [1023:0]   */   .dma_resp_data     ( dma_w_resp_data   ),//N/A
                /*output reg [0005:0]   */   .dma_resp_tag      ( dma_w_resp_tag    ),
                /*output reg [0001:0]   */   .dma_resp_pos      ( dma_w_resp_pos    ),
                /*output reg [0002:0]   */   .dma_resp_code     ( dma_w_resp_code   ),

                //---- TLX interface --------------------------
                /*input                 */   .tlx_rsp_valid     ( tlx_w_rsp_valid   ),
                /*input      [0015:0]   */   .tlx_rsp_afutag    ( tlx_w_rsp_afutag  ),
                /*input      [0007:0]   */   .tlx_rsp_opcode    ( tlx_w_rsp_opcode  ),
                /*input      [0003:0]   */   .tlx_rsp_code      ( tlx_w_rsp_code    ),
                /*input      [0001:0]   */   .tlx_rsp_dl        ( tlx_w_rsp_dl      ),
                /*input      [0001:0]   */   .tlx_rsp_dp        ( tlx_w_rsp_dp      ),
                /*input                */    .tlx_rdata_o_dv    ( 1'b0              ),
                /*input                */    .tlx_rdata_e_dv    ( 1'b0              ),
                /*input                 */   .tlx_rdata_o_bdi   ( 1'b0              ),
                /*input                 */   .tlx_rdata_e_bdi   ( 1'b0              ),
                /*input      [0511:0]   */   .tlx_rdata_o       ( 512'b0            ),
                /*input      [0511:0]   */   .tlx_rdata_e       ( 512'b0            ),

                //---- control and status ---------------------
                /*input                 */   .debug_cnt_clear            ( debug_cnt_clear           ),
                /*output     [0031:0]   */   .debug_tlx_cnt_rsp          ( debug_tlx_cnt_rsp_w       ),
                /*output     [0031:0]   */   .debug_tlx_cnt_retry        ( debug_tlx_cnt_retry_w     ),
                /*output     [0031:0]   */   .debug_tlx_cnt_fail         ( debug_tlx_cnt_fail_w      ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_pd       ( debug_tlx_cnt_xlt_pd_w    ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_done     ( debug_tlx_cnt_xlt_done_w  ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_retry    ( debug_tlx_cnt_xlt_retry_w ),
                /*output     [0004:0]   */   .fir_fifo_overflow          ( fir_fifo_overflow_rspdecw ),
                /*output                */   .fir_tlx_response_unsupport ( fir_tlx_response_unsupport)
                );


brdg_response_decode
                #(
                  .MODE  (1'b1) //0: write; 1: read
                  )
                rsp_dec_r (
                /*input                */   .clk               ( clk_afu           ),
                /*input                */   .rst_n             ( rst_n             ),

                //---- configuration --------------------------------------
                /*input      [0003:0]  */    .cfg_backoff_timer(cfg_backoff_timer  ),

                //---- communication with command decoder -----
                /*input                 */   .prt_cmd_valid     ( r_prt_cmd_valid   ),
                /*input                 */   .prt_cmd_last      ( r_prt_cmd_last    ),
                /*output reg            */   .prt_cmd_enable    ( r_prt_cmd_enable  ),
                /*output                */   .prt_cmd_start     ( r_prt_cmd_start   ),

                //---- DMA interface --------------------------
                /*output reg           */   .dma_resp_valid    ( dma_r_resp_valid  ),
                /*output reg [1023:0]  */   .dma_resp_data     ( dma_r_resp_data   ),
                /*output reg [0005:0]  */   .dma_resp_tag      ( dma_r_resp_tag    ),
                /*output reg [0001:0]  */   .dma_resp_pos      ( dma_r_resp_pos    ),
                /*output reg [0002:0]  */   .dma_resp_code     ( dma_r_resp_code   ),

                //---- TLX interface --------------------------
                /*input                */   .tlx_rsp_valid     ( tlx_r_rsp_valid   ),
                /*input      [0015:0]  */   .tlx_rsp_afutag    ( tlx_r_rsp_afutag  ),
                /*input      [0007:0]  */   .tlx_rsp_opcode    ( tlx_r_rsp_opcode  ),
                /*input      [0003:0]  */   .tlx_rsp_code      ( tlx_r_rsp_code    ),
                /*input      [0001:0]  */   .tlx_rsp_dl        ( tlx_r_rsp_dl      ),
                /*input      [0001:0]  */   .tlx_rsp_dp        ( tlx_r_rsp_dp      ),
                /*input                */   .tlx_rdata_o_dv    ( tlx_r_rdata_o_dv  ),
                /*input                */   .tlx_rdata_e_dv    ( tlx_r_rdata_e_dv  ),
                /*input                */   .tlx_rdata_o_bdi   ( tlx_r_rdata_o_bdi ),
                /*input                */   .tlx_rdata_e_bdi   ( tlx_r_rdata_e_bdi ),
                /*input      [0511:0]  */   .tlx_rdata_o       ( tlx_r_rdata_o     ),
                /*input      [0511:0]  */   .tlx_rdata_e       ( tlx_r_rdata_e     ),

                //---- control and status ---------------------
                /*input                 */   .debug_cnt_clear            ( debug_cnt_clear           ),
                /*output     [0031:0]   */   .debug_tlx_cnt_rsp          ( debug_tlx_cnt_rsp_r       ),
                /*output     [0031:0]   */   .debug_tlx_cnt_retry        ( debug_tlx_cnt_retry_r     ),
                /*output     [0031:0]   */   .debug_tlx_cnt_fail         ( debug_tlx_cnt_fail_r      ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_pd       ( debug_tlx_cnt_xlt_pd_r    ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_done     ( debug_tlx_cnt_xlt_done_r  ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_retry    ( debug_tlx_cnt_xlt_retry_r ),
                /*output     [0004:0]   */   .fir_fifo_overflow          ( fir_fifo_overflow_rspdecr )
                );

//===============================================================================================================
// Data Bridge:
//     write_channel
//     read_channel
//===============================================================================================================
brdg_data_bridge
                   #(
                     .MODE  (1'b0) //0: write; 1: read
                     )
                 data_brg_w (
                /*input                */   .clk                 ( clk_afu             ),
                /*input                */   .rst_n               ( rst_n               ),
                /*output               */   .buf_empty           ( wbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_wr_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_wr_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_wr_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_wr_ea           ),
                /*input      [`IDW-1:0] */   .lcl_addr_axi_id     ( lcl_wr_axi_id       ),
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
                /*output     [`IDW-1:0] */   .lcl_resp_axi_id     ( lcl_wr_rsp_axi_id   ),
                /*output     [0001:0]  */   .lcl_resp_code       ( lcl_wr_rsp_code     ),


                //---- command encoder ---------------
                /*input                */   .dma_cmd_ready       ( dma_w_cmd_ready       ),
                /*output reg           */   .dma_cmd_valid       ( dma_w_cmd_valid       ),
                /*output reg [1023:0]  */   .dma_cmd_data        ( dma_w_cmd_data        ),
                /*output reg [0127:0]  */   .dma_cmd_be          ( dma_w_cmd_be          ),
                /*output reg [0063:0]  */   .dma_cmd_ea          ( dma_w_cmd_ea          ),
                /*output reg [0005:0]  */   .dma_cmd_tag         ( dma_w_cmd_tag         ),

                //---- response decoder --------------
                /*input                */   .dma_resp_valid      ( dma_w_resp_valid      ),
                /*input      [1023:0]  */   .dma_resp_data       ( dma_w_resp_data       ),//N/A
                /*input      [0005:0]  */   .dma_resp_tag        ( dma_w_resp_tag        ),
                /*input      [0001:0]  */   .dma_resp_pos        ( dma_w_resp_pos        ),
                /*input      [0002:0]  */   .dma_resp_code       ( dma_w_resp_code       ),

                //---- context surveil ---------------
                /*input wire           */   .context_update_ongoing ( context_update_ongoing ),

                //---- control and status ------------
                /*input                */   .debug_cnt_clear       ( debug_cnt_clear          ),
                /*input      [0031:0]  */   .debug_axi_cmd_idle_lim( debug_axi_cmd_idle_lim_w ),
                /*input      [0031:0]  */   .debug_axi_rsp_idle_lim( debug_axi_rsp_idle_lim_w ),
                /*output               */   .debug_axi_cmd_idle    ( debug_axi_cmd_idle_w     ),
                /*output               */   .debug_axi_rsp_idle    ( debug_axi_rsp_idle_w     ),
                /*output     [0031:0]  */   .debug_axi_cnt_cmd     ( debug_axi_cnt_cmd_w      ), 
                /*output     [0031:0]  */   .debug_axi_cnt_rsp     ( debug_axi_cnt_rsp_w      ), 
                /*output     [0007:0]  */   .debug_buf_cnt         ( debug_buf_cnt_w          ), 
                /*output     [0001:0]  */   .fir_fifo_overflow     ( fir_fifo_overflow_dbw    )
                );

brdg_data_bridge
                   #(
                     .MODE  (1'b1) //0: write; 1: read
                     )
                data_brg_r (
                /*input                */   .clk                 ( clk_afu             ),
                /*input                */   .rst_n               ( rst_n               ),
                /*output               */   .buf_empty           ( rbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_rd_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_rd_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_rd_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_rd_ea           ),
                /*input      [`IDW-1:0] */   .lcl_addr_axi_id     ( lcl_rd_axi_id       ),
                /*input                */   .lcl_addr_first      ( lcl_rd_first        ),
                /*input                */   .lcl_addr_last       ( lcl_rd_last         ),
                /*input      [0127:0]  */   .lcl_addr_be         ( lcl_rd_be           ),
                    //--- data ---
                /*input      [1023:0]  */   .lcl_data_in         ( 1024'h0             ),
                /*output     [1023:0]  */   .lcl_data_out        ( lcl_rd_data         ),
                /*output               */   .lcl_data_out_last   ( lcl_rd_data_last    ),
                    //--- response and data out ---
                /*input                */   .lcl_resp_ready      ( lcl_rd_data_ready   ),
                /*output               */   .lcl_resp_valid      ( lcl_rd_data_valid   ),
                /*output     [`IDW-1:0] */   .lcl_resp_axi_id     ( lcl_rd_data_axi_id  ),
                /*output     [0001:0]  */   .lcl_resp_code       ( lcl_rd_rsp_code     ),


                //---- command encoder ---------------
                /*input                */   .dma_cmd_ready       ( dma_r_cmd_ready     ),
                /*output reg           */   .dma_cmd_valid       ( dma_r_cmd_valid     ),
                /*output reg [1023:0]  */   .dma_cmd_data        ( dma_r_cmd_data      ),
                /*output reg [0127:0]  */   .dma_cmd_be          ( dma_r_cmd_be        ),
                /*output reg [0063:0]  */   .dma_cmd_ea          ( dma_r_cmd_ea        ),
                /*output reg [0005:0]  */   .dma_cmd_tag         ( dma_r_cmd_tag       ),

                //---- response decoder --------------
                /*input                */   .dma_resp_valid      ( dma_r_resp_valid    ),
                /*input      [1023:0]  */   .dma_resp_data       ( dma_r_resp_data     ),
                /*input      [0005:0]  */   .dma_resp_tag        ( dma_r_resp_tag      ),
                /*input      [0001:0]  */   .dma_resp_pos        ( dma_r_resp_pos      ),
                /*input      [0002:0]  */   .dma_resp_code       ( dma_r_resp_code     ),

                //---- context surveil ---------------
                /*input wire           */   .context_update_ongoing ( context_update_ongoing ),

                //---- control and status ------------
                /*input                */   .debug_cnt_clear       ( debug_cnt_clear          ),
                /*input      [0031:0]  */   .debug_axi_cmd_idle_lim( debug_axi_cmd_idle_lim_r ),
                /*input      [0031:0]  */   .debug_axi_rsp_idle_lim( debug_axi_rsp_idle_lim_r ),
                /*output               */   .debug_axi_cmd_idle    ( debug_axi_cmd_idle_r     ),
                /*output               */   .debug_axi_rsp_idle    ( debug_axi_rsp_idle_r     ),
                /*output     [0031:0]  */   .debug_axi_cnt_cmd     ( debug_axi_cnt_cmd_r      ), 
                /*output     [0031:0]  */   .debug_axi_cnt_rsp     ( debug_axi_cnt_rsp_r      ), 
                /*output     [0007:0]  */   .debug_buf_cnt         ( debug_buf_cnt_r          ), 
                /*output     [0001:0]  */   .fir_fifo_overflow     ( fir_fifo_overflow_dbr    )
                );

//===============================================================================================================
//
//     Context surveil
//
//===============================================================================================================

brdg_context_surveil ctx_surveil(
                /*input                 */   .clk                    ( clk_afu                ),
                /*input            if()     */   .rst_n                  ( rst_n                  ),

                //---- configuration ---------------------------------
                /*input      [011:0]    */   .cfg_actag_base         ( cfg_actag_base         ),
                /*input      [019:0]    */   .cfg_pasid_base         ( cfg_pasid_base         ),
                /*input      [004:0]    */   .cfg_pasid_length       ( cfg_pasid_length       ),

                //---- AXI interface ---------------------------------
                /*input      [008:0]    */   .lcl_wr_ctx             ( lcl_wr_ctx             ),
                /*input      [008:0]    */   .lcl_rd_ctx             ( lcl_rd_ctx             ),
                /*input                 */   .lcl_wr_ctx_valid       ( lcl_wr_ctx_valid       ),
                /*input                 */   .lcl_rd_ctx_valid       ( lcl_rd_ctx_valid       ),
                /*input              */      .interrupt              ( interrupt              ),
                /*input      [008:0] */      .interrupt_ctx          ( interrupt_ctx          ),

                //---- status ----------------------------------------
                /*input                 */   .last_context_cleared   ( last_context_cleared   ),
                /*output reg            */   .context_update_ongoing ( context_update_ongoing ),

                //---- TLX interface ---------------------------------
                /*output                */   .tlx_cmd_valid          ( tlx_ac_cmd_valid        ),
                /*output     [019:0]    */   .tlx_cmd_pasid          ( tlx_ac_cmd_pasid        ),
                /*output     [011:0]    */   .tlx_cmd_actag          ( tlx_ac_cmd_actag        ),
                /*output     [007:0]    */   .tlx_cmd_opcode         ( tlx_ac_cmd_opcode       )
                );

//===============================================================================================================
//
//    Interrupt 
//
//===============================================================================================================

 brdg_interrupt mbrdg_interrupt ( 
                       /*input              */  .clk              (clk_afu             ),
                       /*input              */  .rst_n            (rst_n               ),
                       /*input      [003:0] */  .backoff_limit    (cfg_backoff_timer   ),
                       /*input              */  .interrupt_enable (last_context_cleared),
                       /*output             */  .interrupt_ack    (interrupt_ack       ),
                       /*input              */  .interrupt        (interrupt           ),
                       /*input      [067:0] */  .interrupt_src    (interrupt_src       ),
                       /*output reg         */  .tlx_cmd_valid    (tlx_i_cmd_valid     ),
                       /*output reg [067:0] */  .tlx_cmd_obj      (tlx_i_cmd_obj       ),
                       /*output reg [015:0] */  .tlx_cmd_afutag   (tlx_i_cmd_afutag    ),     
                       /*output reg [007:0] */  .tlx_cmd_opcode   (tlx_i_cmd_opcode    ),
                       /*input              */  .tlx_rsp_valid    (tlx_i_rsp_valid     ),
                       /*input      [0015:0]*/  .tlx_rsp_afutag   (tlx_i_rsp_afutag    ),
                       /*input      [0007:0]*/  .tlx_rsp_opcode   (tlx_i_rsp_opcode    ),
                       /*input      [0003:0]*/  .tlx_rsp_code     (tlx_i_rsp_code      )
                       );


//===============================================================================================================
//
//     AXI slave
//
//===============================================================================================================

brdg_axi_slave       axi_slv (
                /*input                 */   .clk                   ( clk_afu               ),
                /*input                 */   .rst_n                 ( rst_n                 ),

                //---- local bus --------------------
                // "early" means it should be 1 cycle earlier than lcl_wr_valid or lcl_rd_valid

                  // write address & data channel
                /*output                */   .lcl_wr_valid          ( lcl_wr_valid          ),
                /*output reg [63:0]     */   .lcl_wr_ea             ( lcl_wr_ea             ),
                /*output reg [`IDW-1:0]  */   .lcl_wr_axi_id         ( lcl_wr_axi_id         ),
                /*output     [127:0]    */   .lcl_wr_be             ( lcl_wr_be             ),
                /*output                */   .lcl_wr_first          ( lcl_wr_first          ),
                /*output                */   .lcl_wr_last           ( lcl_wr_last           ),
                /*output     [1023:0]   */   .lcl_wr_data           ( lcl_wr_data           ),
                /*output                */   .lcl_wr_idle           ( lcl_wr_idle           ),
                /*input                 */   .lcl_wr_ready          ( lcl_wr_ready && ~context_update_ongoing          ),
                  // write ctx channel
                /*output                */   .lcl_wr_ctx_valid      ( lcl_wr_ctx_valid      ),
                /*output reg [`CTXW-1:0] */   .lcl_wr_ctx            ( lcl_wr_ctx            ),
                  // write response channel
                /*input                 */   .lcl_wr_rsp_valid      ( lcl_wr_rsp_valid      ),
                /*input      [`IDW-1:0]  */   .lcl_wr_rsp_axi_id     ( lcl_wr_rsp_axi_id     ),
                /*input                 */   .lcl_wr_rsp_code       ( lcl_wr_rsp_code       ),
                /*output                */   .lcl_wr_rsp_ready      ( lcl_wr_rsp_ready      ),


                   // read address channel
                /*output                */   .lcl_rd_valid          ( lcl_rd_valid          ),
                /*output reg [63:0]     */   .lcl_rd_ea             ( lcl_rd_ea             ),
                /*output reg [`IDW-1:0]  */   .lcl_rd_axi_id         ( lcl_rd_axi_id         ),
                /*output     [127:0]    */   .lcl_rd_be             ( lcl_rd_be             ),
                /*output                */   .lcl_rd_first          ( lcl_rd_first          ),
                /*output                */   .lcl_rd_last           ( lcl_rd_last           ),
                /*output                */   .lcl_rd_idle           ( lcl_rd_idle           ),
                /*input                 */   .lcl_rd_ready          ( lcl_rd_ready && ~context_update_ongoing          ),
                  // read ctx channel
                /*output                */   .lcl_rd_ctx_valid      ( lcl_rd_ctx_valid      ),
                /*output reg [`CTXW-1:0] */   .lcl_rd_ctx            ( lcl_rd_ctx            ),
                  // read response & data channel
                /*input                 */   .lcl_rd_data_valid     ( lcl_rd_data_valid     ),
                /*input      [`IDW-1:0]  */   .lcl_rd_data_axi_id    ( lcl_rd_data_axi_id    ),
                /*input [1023:0]        */   .lcl_rd_data           ( lcl_rd_data           ),
                /*input                 */   .lcl_rd_data_last      ( lcl_rd_data_last      ),
                /*input                 */   .lcl_rd_rsp_code       ( lcl_rd_rsp_code       ),
                /*output                */   .lcl_rd_data_ready     ( lcl_rd_data_ready     ),


                //---- AXI bus ----------------------
                  // AXI write address channel
                /*input      [`IDW-1:0]  */   .s_axi_awid            ( s_axi_awid            ),
                /*input      [63:0]     */   .s_axi_awaddr          ( s_axi_awaddr          ),
                /*input      [7:0]      */   .s_axi_awlen           ( s_axi_awlen           ),
                /*input      [2:0]      */   .s_axi_awsize          ( s_axi_awsize          ),
                /*input      [1:0]      */   .s_axi_awburst         ( s_axi_awburst         ),
                /*input      [`CTXW-1:0] */   .s_axi_awuser          ( s_axi_awuser          ),
                /*input                 */   .s_axi_awvalid         ( s_axi_awvalid         ),
                /*output reg            */   .s_axi_awready         ( s_axi_awready         ),
                  // AXI write data channel
                  // We suppose wuser = awuser. No wuser input.
                /*input      [1023:0]   */   .s_axi_wdata           ( s_axi_wdata           ),
                /*input      [127:0]    */   .s_axi_wstrb           ( s_axi_wstrb           ),
                /*input                 */   .s_axi_wlast           ( s_axi_wlast           ),
                /*input                 */   .s_axi_wvalid          ( s_axi_wvalid          ),
                /*output                */   .s_axi_wready          ( s_axi_wready          ),
                  // AXI write response channel
                /*output reg [`IDW-1:0]  */   .s_axi_bid             ( s_axi_bid             ),
                /*output reg [1:0]      */   .s_axi_bresp           ( s_axi_bresp           ),
                /*output reg            */   .s_axi_bvalid          ( s_axi_bvalid          ),
                /*input                 */   .s_axi_bready          ( s_axi_bready          ),
                  // AXI read address channel
                /*input      [`IDW-1:0]  */   .s_axi_arid            ( s_axi_arid            ),
                /*input      [63:0]     */   .s_axi_araddr          ( s_axi_araddr          ),
                /*input      [7:0]      */   .s_axi_arlen           ( s_axi_arlen           ),
                /*input      [2:0]      */   .s_axi_arsize          ( s_axi_arsize          ),
                /*input      [1:0]      */   .s_axi_arburst         ( s_axi_arburst         ),
                /*input      [`CTXW-1:0] */   .s_axi_aruser          ( s_axi_aruser          ),
                /*input                 */   .s_axi_arvalid         ( s_axi_arvalid         ),
                /*output reg            */   .s_axi_arready         ( s_axi_arready         ),
                  // AXI read data channel
                /*output reg [`IDW-1:0]  */   .s_axi_rid             ( s_axi_rid             ),
                /*output reg [1023:0]   */   .s_axi_rdata           ( s_axi_rdata           ),
                /*output reg [1:0]      */   .s_axi_rresp           ( s_axi_rresp           ),
                /*output reg            */   .s_axi_rlast           ( s_axi_rlast           ),
                /*output reg            */   .s_axi_rvalid          ( s_axi_rvalid          ),
                /*input                 */   .s_axi_rready          ( s_axi_rready          )
                );


endmodule
