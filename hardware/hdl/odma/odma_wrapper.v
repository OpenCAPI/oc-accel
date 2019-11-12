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

`include "snap_global_vars.v"
//                                  odma_wrapper
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
//|                                       |  |                               |    odma     | |
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

module odma_wrapper #(
                          parameter    IDW = 5,
                          parameter    CTXW = 9,
                          parameter    TAGW = 7,
                          parameter    AXI_MM_DW = 1024,
                          parameter    AXI_MM_AW = 64,
                          parameter    AXI_ST_DW = 1024,
                          parameter    AXI_ST_AW = 64,
                          parameter    AXI_LITE_DW = 32,
                          parameter    AXI_LITE_AW = 32,
                          parameter    AXI_MM_AWUSER = 9,
                          parameter    AXI_MM_ARUSER = 9,
                          parameter    AXI_MM_WUSER = 1,
                          parameter    AXI_MM_RUSER = 1,
                          parameter    AXI_MM_BUSER = 1
                         )
                   (
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

                   //----- AXI MM/ST Data  ----------------------------------
                   //--------------- AXI4-MM Interface --------------//
                   //---------- Write Addr/Req Channel --------------//
                   output [AXI_MM_AW - 1:0]        axi_mm_awaddr     ,
                   output [IDW - 1:0]              axi_mm_awid       ,
                   output [0007:0]                 axi_mm_awlen      ,
                   output [0002:0]                 axi_mm_awsize     ,
                   output [0001:0]                 axi_mm_awburst    ,
                   output [0002:0]                 axi_mm_awprot     ,
                   output [0003:0]                 axi_mm_awqos      ,
                   output [0003:0]                 axi_mm_awregion   ,
                   output [AXI_MM_AWUSER - 1:0]    axi_mm_awuser     ,
                   output                          axi_mm_awvalid    ,
                   output [0001:0]                 axi_mm_awlock     ,
                   output [0003:0]                 axi_mm_awcache    ,
                   input                           axi_mm_awready    ,
                   //---------- Write Data Channel ------------------//
                   output [AXI_MM_DW - 1:0]        axi_mm_wdata      ,
                   output                          axi_mm_wlast      ,
                   output [AXI_MM_DW/8 - 1:0]      axi_mm_wstrb      ,
                   output                          axi_mm_wvalid     ,
                   output [AXI_MM_WUSER - 1:0]     axi_mm_wuser      ,
                   input                           axi_mm_wready     ,
                   //---------- Write Response Channel --------------//
                   input                           axi_mm_bvalid     ,
                   input  [0001:0]                 axi_mm_bresp      ,
                   input  [IDW - 1:0]              axi_mm_bid        ,
                   input  [AXI_MM_BUSER - 1:0]     axi_mm_buser      ,
                   output                          axi_mm_bready     ,
                   //---------- Read Addr/Req Channel  --------------//
                   output [AXI_MM_AW - 1:0]        axi_mm_araddr     ,        
                   output [0001:0]                 axi_mm_arburst    ,        
                   output [0003:0]                 axi_mm_arcache    ,        
                   output [IDW - 1:0]              axi_mm_arid       ,        
                   output [0007:0]                 axi_mm_arlen      ,        
                   output [0001:0]                 axi_mm_arlock     ,        
                   output [0002:0]                 axi_mm_arprot     ,        
                   output [0003:0]                 axi_mm_arqos      ,        
                   input                           axi_mm_arready    ,       
                   output [0003:0]                 axi_mm_arregion   ,       
                   output [0002:0]                 axi_mm_arsize     ,       
                   output [AXI_MM_ARUSER - 1:0]    axi_mm_aruser     ,       
                   output                          axi_mm_arvalid    ,       
                   //------------- Read Data Channel ----------------//
                   input  [AXI_MM_DW - 1:0]        axi_mm_rdata      ,         
                   input  [IDW - 1:0]              axi_mm_rid        ,         
                   input                           axi_mm_rlast      ,         
                   output                          axi_mm_rready     ,         
                   input  [0001:0]                 axi_mm_rresp      ,         
                   input  [AXI_MM_RUSER - 1:0]     axi_mm_ruser      ,         
                   input                           axi_mm_rvalid     ,         
                   // TODO: ST is not supported now
                   ////--------------- AXI4-ST Interface --------------//
                   ////---------- H2C AXI4-ST Channel 0 ---------------//
                   //input                           axi_st_h2c_tready_0,
                   //output                          axi_st_h2c_tlast_0 ,
                   //output [AXI_ST_DW - 1:0]        axi_st_h2c_tdata_0 ,
                   //output                          axi_st_h2c_tvalid_0,
                   //output [AXI_ST_DW/8 - 1:0]      axi_st_h2c_tuser_0 ,
                   ////---------- H2C AXI4-ST Channel 1 ---------------//
                   //input                           axi_st_h2c_tready_1,
                   //output                          axi_st_h2c_tlast_1 ,
                   //output [AXI_ST_DW - 1:0]        axi_st_h2c_tdata_1 ,
                   //output                          axi_st_h2c_tvalid_1,
                   //output [AXI_ST_DW/8 - 1:0]      axi_st_h2c_tuser_1 ,
                   ////---------- H2C AXI4-ST Channel 2 ---------------//
                   //input                           axi_st_h2c_tready_2,
                   //output                          axi_st_h2c_tlast_2 ,
                   //output [AXI_ST_DW - 1:0]        axi_st_h2c_tdata_2 ,
                   //output                          axi_st_h2c_tvalid_2,
                   //output [AXI_ST_DW/8 - 1:0]      axi_st_h2c_tuser_2 ,
                   ////---------- H2C AXI4-ST Channel 3 ---------------//
                   //input                           axi_st_h2c_tready_3,
                   //output                          axi_st_h2c_tlast_3 ,
                   //output [AXI_ST_DW - 1:0]        axi_st_h2c_tdata_3 ,
                   //output                          axi_st_h2c_tvalid_3,
                   //output [AXI_ST_DW/8 - 1:0]      axi_st_h2c_tuser_3 ,
                   ////---------- C2H AXI4-ST Channel 0 ---------------//
                   //output                          axi_st_c2h_tready_0,
                   //input                           axi_st_c2h_tlast_0 ,
                   //input  [AXI_ST_DW - 1:0]        axi_st_c2h_tdata_0 ,
                   //input                           axi_st_c2h_tvalid_0,
                   //input  [AXI_ST_DW/8 - 1:0]      axi_st_c2h_tuser_0 ,
                   ////---------- C2H AXI4-ST Channel 1 ---------------//
                   //output                          axi_st_c2h_tready_1,
                   //input                           axi_st_c2h_tlast_1 ,
                   //input  [AXI_ST_DW - 1:0]        axi_st_c2h_tdata_1 ,
                   //input                           axi_st_c2h_tvalid_1,
                   //input  [AXI_ST_DW/8 - 1:0]      axi_st_c2h_tuser_1 ,
                   ////---------- C2H AXI4-ST Channel 2 ---------------//
                   //output                          axi_st_c2h_tready_2,
                   //input                           axi_st_c2h_tlast_2 ,
                   //input  [AXI_ST_DW - 1:0]        axi_st_c2h_tdata_2 ,
                   //input                           axi_st_c2h_tvalid_2,
                   //input  [AXI_ST_DW/8 - 1:0]      axi_st_c2h_tuser_2 ,
                   ////---------- C2H AXI4-ST Channel 3 ---------------//
                   //output                          axi_st_c2h_tready_3,
                   //input                           axi_st_c2h_tlast_3 ,
                   //input  [AXI_ST_DW - 1:0]        axi_st_c2h_tdata_3 ,
                   //input                           axi_st_c2h_tvalid_3,
                   //input  [AXI_ST_DW/8 - 1:0]      axi_st_c2h_tuser_3 ,
                   //-------- Host AXI-Lite slave Interface ---------//
                   input                           h_s_axi_arvalid   ,        
                   input  [AXI_LITE_AW - 1:0]      h_s_axi_araddr    ,        
                   output                          h_s_axi_arready   ,        
                   output                          h_s_axi_rvalid    ,        
                   output [AXI_LITE_DW - 1:0]      h_s_axi_rdata     ,        
                   output [0001:0]                 h_s_axi_rresp     ,        
                   input                           h_s_axi_rready    ,        
                   input                           h_s_axi_awvalid   ,        
                   input  [AXI_LITE_AW - 1:0]      h_s_axi_awaddr    ,        
                   output                          h_s_axi_awready   ,        
                   input                           h_s_axi_wvalid    ,        
                   input  [AXI_LITE_DW - 1:0]      h_s_axi_wdata     ,        
                   input  [AXI_LITE_DW/8 - 1:0]    h_s_axi_wstrb     ,        
                   output                          h_s_axi_wready    ,        
                   output                          h_s_axi_bvalid    ,        
                   output [0001:0]                 h_s_axi_bresp     ,        
                   input                           h_s_axi_bready    ,        
                   //------- Action AXI-Lite slave Interface --------//
                   input                           a_s_axi_arvalid   ,        
                   input  [AXI_LITE_AW - 1:0]      a_s_axi_araddr    ,        
                   output                          a_s_axi_arready   ,        
                   output                          a_s_axi_rvalid    ,        
                   output [AXI_LITE_DW - 1:0]      a_s_axi_rdata     ,        
                   output [0001:0]                 a_s_axi_rresp     ,        
                   input                           a_s_axi_rready    ,        
                   input                           a_s_axi_awvalid   ,        
                   input  [AXI_LITE_AW - 1:0]      a_s_axi_awaddr    ,        
                   output                          a_s_axi_awready   ,        
                   input                           a_s_axi_wvalid    ,        
                   input  [AXI_LITE_DW - 1:0]      a_s_axi_wdata     ,        
                   input  [AXI_LITE_DW/8 - 1:0]    a_s_axi_wstrb     ,        
                   output                          a_s_axi_wready    ,        
                   output                          a_s_axi_bvalid    ,        
                   output [0001:0]                 a_s_axi_bresp     ,        
                   input                           a_s_axi_bready    ,         
                   //------- Action AXI-Lite master Interface -------//
                   output                          a_m_axi_arvalid   ,
                   output [AXI_LITE_AW - 1:0]      a_m_axi_araddr    ,
                   input                           a_m_axi_arready   ,
                   input                           a_m_axi_rvalid    ,
                   input  [AXI_LITE_DW - 1:0]      a_m_axi_rdata     ,
                   input  [0001:0]                 a_m_axi_rresp     ,
                   output                          a_m_axi_rready    ,
                   output                          a_m_axi_awvalid   ,
                   output [AXI_LITE_AW - 1:0]      a_m_axi_awaddr    ,
                   input                           a_m_axi_awready   ,
                   output                          a_m_axi_wvalid    ,
                   output [AXI_LITE_DW - 1:0]      a_m_axi_wdata     ,
                   output [AXI_LITE_DW/8 - 1:0]    a_m_axi_wstrb     ,
                   input                           a_m_axi_wready    ,
                   input                           a_m_axi_bvalid    ,
                   input  [0001:0]                 a_m_axi_bresp     ,
                   output                          a_m_axi_bready          
                   );


//===============================================================================================================
//         WIRES: local bus between odma and data bridge
//===============================================================================================================

// write address & data channel
wire            lcl_wr_valid;     
wire [63:0]     lcl_wr_ea;        
wire [IDW-1:0]  lcl_wr_axi_id;    
wire [127:0]    lcl_wr_be;        
wire            lcl_wr_first;     
wire            lcl_wr_last;      
wire [1023:0]   lcl_wr_data;      
wire            lcl_wr_idle;      
wire            lcl_wr_ready;     
// write ctx channel
wire            lcl_wr_ctx_valid; 
wire [CTXW-1:0] lcl_wr_ctx;       
// write response channel
wire            lcl_wr_rsp_valid; 
wire [IDW-1:0]  lcl_wr_rsp_axi_id;
wire            lcl_wr_rsp_code;  
wire [31:0]     lcl_wr_rsp_ready; 


// read address channel
wire            lcl_rd_valid;     
wire [63:0]     lcl_rd_ea;        
wire [IDW-1:0]  lcl_rd_axi_id;    
wire [127:0]    lcl_rd_be;        
wire            lcl_rd_first;     
wire            lcl_rd_last;      
wire            lcl_rd_idle;      
wire            lcl_rd_ready;     
// read ctx channel
wire            lcl_rd_ctx_valid; 
wire [CTXW-1:0] lcl_rd_ctx;       
// read response & data channel
wire            lcl_rd_data_valid;
wire [IDW-1:0]  lcl_rd_data_axi_id;
wire [1023:0]   lcl_rd_data;      
wire            lcl_rd_data_last; 
wire            lcl_rd_rsp_code;  
wire [31:0]     lcl_rd_rsp_ready;
wire [31:0]     lcl_rd_rsp_ready_hint;
                
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
wire             dma_w_cmd_ready ;
wire             dma_w_cmd_valid ;
wire [1023:0]    dma_w_cmd_data  ;
wire [0127:0]    dma_w_cmd_be    ;
wire [0063:0]    dma_w_cmd_ea    ;
wire [TAGW-1:0]  dma_w_cmd_tag   ;
wire             w_prt_cmd_valid ;
wire             w_prt_cmd_start ;
wire             w_prt_cmd_last  ;
wire             w_prt_cmd_enable;
//---- response decoder ----;
wire             dma_w_resp_valid;
wire [1023:0]    dma_w_resp_data ;
wire [TAGW-1:0]  dma_w_resp_tag  ;
wire [0001:0]    dma_w_resp_pos  ;
wire [0002:0]    dma_w_resp_code ;

//---- command encoder -----
wire             dma_r_cmd_ready ;
wire             dma_r_cmd_valid ;
wire [1023:0]    dma_r_cmd_data  ;
wire [0127:0]    dma_r_cmd_be    ;
wire [0063:0]    dma_r_cmd_ea    ;
wire [TAGW-1:0]  dma_r_cmd_tag   ;
wire             r_prt_cmd_valid ;
wire             r_prt_cmd_start ;
wire             r_prt_cmd_last  ;
wire             r_prt_cmd_enable;

//---- response decoder ----;
wire             dma_r_resp_valid;
wire [1023:0]    dma_r_resp_data ;
wire [TAGW-1:0]  dma_r_resp_tag  ;
wire [0001:0]    dma_r_resp_pos  ;
wire [0002:0]    dma_r_resp_code ;


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


//===============================================================================================================
// Clock converters:
//     tlx_cmd_converter: from 200MHz (data bridge) to 400MHz (tlx domain)
//     tlx_rsp_converter: from 400MHz (tlx domain)  to 200MHz (data bridge)
//
//===============================================================================================================



brdg_tlx_cmd_converter tlx_cmd_conv (
                                             `ifdef ILA_DEBUG
                                             .fir_cmd_credit_breach           (fir_cmd_credit_breach            ),
                                             .fir_cmd_credit_data_breach      (fir_cmd_credit_data_breach       ),
                                             .fir_fifo_a_cmdcnv_overflow      (fir_fifo_a_cmdcnv_overflow       ), 
                                             .fir_fifo_r_cmdcnv_overflow      (fir_fifo_r_cmdcnv_overflow       ), 
                                             .fir_fifo_w_datcnv_e_overflow    (fir_fifo_w_datcnv_e_overflow     ), 
                                             .fir_fifo_w_datcnv_o_overflow    (fir_fifo_w_datcnv_o_overflow     ), 
                                             .fir_fifo_w_cmdcnv_overflow      (fir_fifo_w_cmdcnv_overflow       ),
                                             `endif

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
                /*input                 */   .tlx_ac_cmd_valid                ( tlx_ac_cmd_valid                ),
                /*input      [0019:0]   */   .tlx_ac_cmd_pasid                ( tlx_ac_cmd_pasid                ),
                /*input      [0011:0]   */   .tlx_ac_cmd_actag                ( tlx_ac_cmd_actag                ),
                /*input      [0007:0]   */   .tlx_ac_cmd_opcode               ( tlx_ac_cmd_opcode               )
                );


brdg_tlx_rsp_converter tlx_rsp_conv(
                                             `ifdef ILA_DEBUG
                                             .fir_fifo_rd_rspcnv_overflow      (fir_fifo_rd_rspcnv_overflow      ),
                                             .fir_fifo_wr_rspcnv_overflow      (fir_fifo_wr_rspcnv_overflow      ),
                                             .fir_fifo_dpdl_o_overflow         (fir_fifo_dpdl_o_overflow         ),
                                             .fir_fifo_dpdl_e_overflow         (fir_fifo_dpdl_e_overflow         ),
                                             .fir_fifo_datcnv_o_overflow       (fir_fifo_datcnv_o_overflow       ),
                                             .fir_fifo_datcnv_e_overflow       (fir_fifo_datcnv_e_overflow       ),
                                             .fir_tlx_rsp_deficient_or_delayed (fir_tlx_rsp_deficient_or_delayed ),
                                             `endif

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
                /*output     [511:0]    */   .tlx_r_rdata_e                  ( tlx_r_rdata_e                  )
                );





//===============================================================================================================
// Command Encode:
//     write_channel
//     read_channel
//===============================================================================================================



brdg_command_encode
                #(
                  .TAGW (TAGW), 
                  .MODE (1'b0) //0: write; 1: read
                  )
                cmd_enc_w (
                                             `ifdef ILA_DEBUG
                                             .fir_fifo_prt_data_overflow   (wr_fir_fifo_prt_data_overflow   ),
                                             .fir_fifo_prt_info_overflow   (wr_fir_fifo_prt_info_overflow   ),
                                             `endif

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
                /*input                 */   .tlx_cmd_rdy                  ( tlx_w_cmd_ready                )
                );


brdg_command_encode
                #(
                  .TAGW (TAGW), 
                  .MODE  (1'b1) //0: write; 1: read
                  )
                cmd_enc_r  (
                                             `ifdef ILA_DEBUG
                                             .fir_fifo_prt_data_overflow   (rd_fir_fifo_prt_data_overflow   ),
                                             .fir_fifo_prt_info_overflow   (rd_fir_fifo_prt_info_overflow   ),
                                             `endif

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
                /*input                 */   .tlx_cmd_rdy                  ( tlx_r_cmd_ready                )
                );

//===============================================================================================================
// Response Decode:
//     write_channel
//     read_channel
//===============================================================================================================

brdg_response_decode
                #(
                  .TAGW (TAGW), 
                 .MODE  (1'b0) //0: write; 1: read
                 )
                rsp_dec_w (
                                             `ifdef ILA_DEBUG
                                             .fir_fifo_rsp_good_overflow (wr_fir_fifo_rsp_good_overflow ),
                                             .fir_fifo_rsp_bad_overflow  (wr_fir_fifo_rsp_bad_overflow  ),
                                             .fir_fifo_rspdat_o_overflow (wr_fir_fifo_rspdat_o_overflow ),
                                             .fir_fifo_rspdat_e_overflow (wr_fir_fifo_rspdat_e_overflow ),
                                             .retry_count                (wr_retry_count),
                                             .rsp_idle_count             (wr_rsp_idle_count),
                                             `endif

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
                /*input                */    .tlx_rdata_o_dv    ( 0                 ),
                /*input                */    .tlx_rdata_e_dv    ( 0                 ),
                /*input                 */   .tlx_rdata_o_bdi   ( 0                 ),
                /*input                 */   .tlx_rdata_e_bdi   ( 0                 ),
                /*input      [0511:0]   */   .tlx_rdata_o       ( 0                 ),
                /*input      [0511:0]   */   .tlx_rdata_e       ( 0                 )
                );


brdg_response_decode
                #(
                  .MODE  (1'b1) //0: write; 1: read
                  )
                rsp_dec_r (
                                             `ifdef ILA_DEBUG
                                             .fir_fifo_rsp_good_overflow (rd_fir_fifo_rsp_good_overflow ),
                                             .fir_fifo_rsp_bad_overflow  (rd_fir_fifo_rsp_bad_overflow  ),
                                             .fir_fifo_rspdat_o_overflow (rd_fir_fifo_rspdat_o_overflow ),
                                             .fir_fifo_rspdat_e_overflow (rd_fir_fifo_rspdat_e_overflow ),
                                             .retry_count                (rd_retry_count),
                                             .rsp_idle_count             (rd_rsp_idle_count),
                                             `endif

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
                /*input      [0511:0]  */   .tlx_rdata_e       ( tlx_r_rdata_e     )
                );

//===============================================================================================================
// Data Bridge:
//     write_channel
//     read_channel
//===============================================================================================================
brdg_data_bridge
                   #(
                     .MODE  (1'b0), //0: write; 1: read
                     .TAGW  (TAGW), 
                     .IDW   (IDW)
                     )
                 data_brg_w (
                                            `ifdef ILA_DEBUG
                                            .fir_fifo_rcy_tag_overflow (wr_fir_fifo_rcy_tag_overflow),
                                            .fir_fifo_rty_tag_overflow (wr_fir_fifo_rty_tag_overflow),
                                            `endif

                /*input                */   .clk                 ( clk_afu             ),
                /*input                */   .rst_n               ( rst_n               ),
                /*output               */   .buf_empty           ( wbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_wr_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_wr_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_wr_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_wr_ea           ),
                /*input      [IDW-1:0] */   .lcl_addr_axi_id     ( lcl_wr_axi_id       ),
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
                /*output     [IDW-1:0] */   .lcl_resp_axi_id     ( lcl_wr_rsp_axi_id   ),
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
                /*input wire           */   .context_update_ongoing ( context_update_ongoing )
                );

brdg_data_bridge
                   #(
                     .TAGW  (TAGW), 
                     .MODE  (1'b1), //0: write; 1: read
                     .IDW   (IDW)
                     )
                data_brg_r (
                                            `ifdef ILA_DEBUG
                                            .fir_fifo_rcy_tag_overflow (rd_fir_fifo_rcy_tag_overflow),
                                            .fir_fifo_rty_tag_overflow (rd_fir_fifo_rty_tag_overflow),
                                            `endif

                /*input                */   .clk                 ( clk_afu             ),
                /*input                */   .rst_n               ( rst_n               ),
                /*output               */   .buf_empty           ( rbuf_empty          ),

                //---- local bus ---------------------
                    //--- address ---
                /*input                */   .lcl_addr_idle       ( lcl_rd_idle         ),
                /*output reg           */   .lcl_addr_ready      ( lcl_rd_ready        ),
                /*input                */   .lcl_addr_valid      ( lcl_rd_valid        ),
                /*input      [0063:0]  */   .lcl_addr_ea         ( lcl_rd_ea           ),
                /*input      [IDW-1:0] */   .lcl_addr_axi_id     ( lcl_rd_axi_id       ),
                /*input                */   .lcl_addr_first      ( lcl_rd_first        ),
                /*input                */   .lcl_addr_last       ( lcl_rd_last         ),
                /*input      [0127:0]  */   .lcl_addr_be         ( lcl_rd_be           ),
                    //--- data ---
                /*input      [1023:0]  */   .lcl_data_in         ( 1024'h0             ),
                /*output     [1023:0]  */   .lcl_data_out        ( lcl_rd_data         ),
                /*output               */   .lcl_data_out_last   ( lcl_rd_data_last    ),
                    //--- response and data out ---
                /*input      [0031:0]  */   .lcl_resp_ready      ( lcl_rd_rsp_ready   ),
                /*input      [0031:0]  */   .lcl_resp_ready_hint ( lcl_rd_rsp_ready_hint ),
                /*output               */   .lcl_resp_valid      ( lcl_rd_data_valid   ),
                /*output     [IDW-1:0] */   .lcl_resp_axi_id     ( lcl_rd_data_axi_id  ),
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
                /*input wire           */   .context_update_ongoing ( context_update_ongoing )
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
//     ODMA Wrapper
//
//===============================================================================================================

odma
                # (
                    .IDW           (IDW),
                    .AXI_MM_DW     (AXI_MM_DW),
                    .AXI_MM_AW     (AXI_MM_AW),
                    .AXI_ST_DW     (AXI_ST_DW),
                    .AXI_ST_AW     (AXI_ST_AW),
                    .AXI_LITE_DW   (AXI_LITE_DW),
                    .AXI_LITE_AW   (AXI_LITE_AW),
                    .AXI_MM_AWUSER (AXI_MM_AWUSER),
                    .AXI_MM_ARUSER (AXI_MM_ARUSER),
                    .AXI_MM_WUSER  (AXI_MM_WUSER),
                    .AXI_MM_RUSER  (AXI_MM_RUSER),
                    .AXI_MM_BUSER  (AXI_MM_BUSER)
                   )
                odma (
                /*input                 */   .clk                      ( clk_afu            ),
                /*input                 */   .rst_n                    ( rst_n              ),
                //-------------- LCL Read Interface --------------//
                //-------------- Read Addr/Req Channel -----------//
                /*output                */          .lcl_rd_valid       ( lcl_rd_valid       ),
                /*output [0063:0]       */          .lcl_rd_ea          ( lcl_rd_ea          ),
                /*output [IDW - 1:0]    */          .lcl_rd_axi_id      ( lcl_rd_axi_id      ),
                /*output                */          .lcl_rd_first       ( lcl_rd_first       ),
                /*output                */          .lcl_rd_last        ( lcl_rd_last        ),
                /*output [0127:0]       */          .lcl_rd_be          ( lcl_rd_be          ),
                /*output [0008:0]       */          .lcl_rd_ctx         ( lcl_rd_ctx         ),
                /*output                */          .lcl_rd_ctx_valid   ( lcl_rd_ctx_valid   ),
                /*input                 */          .lcl_rd_ready       ( lcl_rd_ready && ~context_update_ongoing       ),
                //-------------- Read Data/Resp Channel-----------//
                /*input                 */          .lcl_rd_data_valid  ( lcl_rd_data_valid  ),
                /*input  [1023:0]       */          .lcl_rd_data        ( lcl_rd_data        ),
                /*input  [IDW - 1:0]    */          .lcl_rd_data_axi_id ( lcl_rd_data_axi_id ),
                /*input                 */          .lcl_rd_data_last   ( lcl_rd_data_last   ),
                /*input                 */          .lcl_rd_rsp_code    ( lcl_rd_rsp_code    ),
                /*output [0031:0]       */          .lcl_rd_rsp_ready   ( lcl_rd_rsp_ready   ),
                /*output [0031:0]       */          .lcl_rd_rsp_ready_hint   ( lcl_rd_rsp_ready_hint   ),
                //-------------- LCL Write Interface -------------//
                //-------------- Write Addr/Data Channel ---------//
                /*output                */          .lcl_wr_valid       ( lcl_wr_valid       ),
                /*output [0063:0]       */          .lcl_wr_ea          ( lcl_wr_ea          ),
                /*output [IDW - 1:0]    */          .lcl_wr_axi_id      ( lcl_wr_axi_id      ),
                /*output [0127:0]       */          .lcl_wr_be          ( lcl_wr_be          ),
                /*output                */          .lcl_wr_first       ( lcl_wr_first       ),
                /*output                */          .lcl_wr_last        ( lcl_wr_last        ),
                /*output [1023:0]       */          .lcl_wr_data        ( lcl_wr_data        ),
                /*output [0008:0]       */          .lcl_wr_ctx         ( lcl_wr_ctx         ),
                /*output                */          .lcl_wr_ctx_valid   ( lcl_wr_ctx_valid   ),
                /*input                 */          .lcl_wr_ready       ( lcl_wr_ready && ~context_update_ongoing     ),
                //-------------- Write Response Channel ----------//
                /*input                 */          .lcl_wr_rsp_valid   ( lcl_wr_rsp_valid   ),
                /*input  [IDW - 1:0]    */          .lcl_wr_rsp_axi_id  ( lcl_wr_rsp_axi_id  ),
                /*input                 */          .lcl_wr_rsp_code    ( lcl_wr_rsp_code    ),
                /*output [0031:0]       */          .lcl_wr_rsp_ready   ( lcl_wr_rsp_ready   ),
                //--------------- AXI4-MM Interface --------------//
                //---------- Write Addr/Req Channel --------------//
                /*output [AXI_MM_AW - 1:0]*/        .axi_mm_awaddr     ( axi_mm_awaddr       ),
                /*output [IDW - 1:0]    */          .axi_mm_awid       ( axi_mm_awid         ),
                /*output [0007:0]       */          .axi_mm_awlen      ( axi_mm_awlen        ),
                /*output [0002:0]       */          .axi_mm_awsize     ( axi_mm_awsize       ),
                /*output [0001:0]       */          .axi_mm_awburst    ( axi_mm_awburst      ),
                /*output [0002:0]       */          .axi_mm_awprot     ( axi_mm_awprot       ),
                /*output [0003:0]       */          .axi_mm_awqos      ( axi_mm_awprot       ),
                /*output [0003:0]       */          .axi_mm_awregion   ( axi_mm_awregion     ),
                /*output [AXI_MM_AWUSER - 1:0]*/    .axi_mm_awuser     ( axi_mm_awuser       ),
                /*output                */          .axi_mm_awvalid    ( axi_mm_awvalid      ),
                /*output                */          .axi_mm_awlock     ( axi_mm_awlock       ),
                /*output [0003:0]       */          .axi_mm_awcache    ( axi_mm_awcache      ),
                /*input                 */          .axi_mm_awready    ( axi_mm_awready      ),
                //---------- Write Data Channel ------------------//
                /*output [AXI_MM_DW - 1:0]   */     .axi_mm_wdata      ( axi_mm_wdata        ),
                /*output                     */     .axi_mm_wlast      ( axi_mm_wlast        ),
                /*output [AXI_MM_DW/8 - 1:0] */     .axi_mm_wstrb      ( axi_mm_wstrb        ),
                /*output                     */     .axi_mm_wvalid     ( axi_mm_wvalid       ),
                /*output [AXI_MM_WUSER - 1:0]*/     .axi_mm_wuser      ( axi_mm_wuser        ),
                /*input                      */     .axi_mm_wready     ( axi_mm_wready       ),
                //---------- Write Response Channel --------------//
                /*input                 */          .axi_mm_bvalid     ( axi_mm_bvalid       ),
                /*input  [0001:0]       */          .axi_mm_bresp      ( axi_mm_bresp        ),
                /*input  [IDW - 1:0]    */          .axi_mm_bid        ( axi_mm_bid          ),
                /*input  [AXI_MM_BUSER - 1:0]*/     .axi_mm_buser      ( axi_mm_buser        ),
                /*output                */          .axi_mm_bready     ( axi_mm_bready       ),
                //---------- Read Addr/Req Channel  --------------//
                /*output [AXI_MM_AW - 1:0]    */    .axi_mm_araddr     ( axi_mm_araddr       ),        
                /*output [0001:0]             */    .axi_mm_arburst    ( axi_mm_arburst      ),        
                /*output [0003:0]             */    .axi_mm_arcache    ( axi_mm_arcache      ),        
                /*output [IDW - 1:0]          */    .axi_mm_arid       ( axi_mm_arid         ),        
                /*output [0007:0]             */    .axi_mm_arlen      ( axi_mm_arlen        ),        
                /*output [0001:0]             */    .axi_mm_arlock     ( axi_mm_arlock       ),        
                /*output [0002:0]             */    .axi_mm_arprot     ( axi_mm_arprot       ),        
                /*output [0003:0]             */    .axi_mm_arqos      ( axi_mm_arqos        ),        
                /*input                       */    .axi_mm_arready    ( axi_mm_arready      ),       
                /*output [0003:0]             */    .axi_mm_arregion   ( axi_mm_arregion     ),       
                /*output [0002:0]             */    .axi_mm_arsize     ( axi_mm_arsize       ),       
                /*output [AXI_MM_ARUSER - 1:0]*/    .axi_mm_aruser     ( axi_mm_aruser       ),       
                /*output                      */    .axi_mm_arvalid    ( axi_mm_arvalid      ),       
                //------------- Read Data Channel ----------------//
                /*input  [AXI_MM_DW - 1:0]    */    .axi_mm_rdata      ( axi_mm_rdata        ),         
                /*input  [IDW - 1:0]          */    .axi_mm_rid        ( axi_mm_rid          ),         
                /*input                       */    .axi_mm_rlast      ( axi_mm_rlast        ),         
                /*output                      */    .axi_mm_rready     ( axi_mm_rready       ),         
                /*input  [0001:0]             */    .axi_mm_rresp      ( axi_mm_rresp        ),         
                /*input  [AXI_MM_RUSER - 1:0] */    .axi_mm_ruser      ( axi_mm_ruser        ),         
                /*input                       */    .axi_mm_rvalid     ( axi_mm_rvalid       ),         
                // TODO: ST is not supported now
                ////--------------- AXI4-ST Interface --------------//
                ////---------- H2C AXI4-ST Channel 0 ---------------//
                ///*input                       */    .axi_st_h2c_tready_0 ( axi_st_h2c_tready_0 ),
                ///*output                      */    .axi_st_h2c_tlast_0  ( axi_st_h2c_tlast_0  ),
                ///*output [AXI_ST_DW - 1:0]    */    .axi_st_h2c_tdata_0  ( axi_st_h2c_tdata_0  ),
                ///*output                      */    .axi_st_h2c_tvalid_0 ( axi_st_h2c_tvalid_0 ),
                ///*output [AXI_ST_DW/8 - 1:0]  */    .axi_st_h2c_tuser_0  ( axi_st_h2c_tuser_0  ),
                ////---------- H2C AXI4-ST Channel 1 ---------------//
                ///*input                       */    .axi_st_h2c_tready_1 ( axi_st_h2c_tready_1 ),
                ///*output                      */    .axi_st_h2c_tlast_1  ( axi_st_h2c_tlast_1  ),
                ///*output [AXI_ST_DW - 1:0]    */    .axi_st_h2c_tdata_1  ( axi_st_h2c_tdata_1  ),
                ///*output                      */    .axi_st_h2c_tvalid_1 ( axi_st_h2c_tvalid_1 ),
                ///*output [AXI_ST_DW/8 - 1:0]  */    .axi_st_h2c_tuser_1  ( axi_st_h2c_tuser_1  ),
                ////---------- H2C AXI4-ST Channel 2 ---------------//
                ///*input                       */    .axi_st_h2c_tready_2 ( axi_st_h2c_tready_2 ),
                ///*output                      */    .axi_st_h2c_tlast_2  ( axi_st_h2c_tlast_2  ),
                ///*output [AXI_ST_DW - 1:0]    */    .axi_st_h2c_tdata_2  ( axi_st_h2c_tdata_2  ),
                ///*output                      */    .axi_st_h2c_tvalid_2 ( axi_st_h2c_tvalid_2 ),
                ///*output [AXI_ST_DW/8 - 1:0]  */    .axi_st_h2c_tuser_2  ( axi_st_h2c_tuser_2  ),
                ////---------- H2C AXI4-ST Channel 3 ---------------//
                ///*input                       */    .axi_st_h2c_tready_3 ( axi_st_h2c_tready_3 ),
                ///*output                      */    .axi_st_h2c_tlast_3  ( axi_st_h2c_tlast_3  ),
                ///*output [AXI_ST_DW - 1:0]    */    .axi_st_h2c_tdata_3  ( axi_st_h2c_tdata_3  ),
                ///*output                      */    .axi_st_h2c_tvalid_3 ( axi_st_h2c_tvalid_3 ),
                ///*output [AXI_ST_DW/8 - 1:0]  */    .axi_st_h2c_tuser_3  ( axi_st_h2c_tuser_3  ),
                ////---------- C2H AXI4-ST Channel 0 ---------------//
                ///*output                      */    .axi_st_c2h_tready_0 ( axi_st_c2h_tready_0 ),
                ///*input                       */    .axi_st_c2h_tlast_0  ( axi_st_c2h_tlast_0  ),
                ///*input  [AXI_ST_DW - 1:0]    */    .axi_st_c2h_tdata_0  ( axi_st_c2h_tdata_0  ),
                ///*input                       */    .axi_st_c2h_tvalid_0 ( axi_st_c2h_tvalid_0 ),
                ///*input  [AXI_ST_DW/8 - 1:0]  */    .axi_st_c2h_tuser_0  ( axi_st_c2h_tuser_0  ),
                ////---------- C2H AXI4-ST Channel 1 ---------------//
                ///*output                      */    .axi_st_c2h_tready_1 ( axi_st_c2h_tready_1 ),
                ///*input                       */    .axi_st_c2h_tlast_1  ( axi_st_c2h_tlast_1  ),
                ///*input  [AXI_ST_DW - 1:0]    */    .axi_st_c2h_tdata_1  ( axi_st_c2h_tdata_1  ),
                ///*input                       */    .axi_st_c2h_tvalid_1 ( axi_st_c2h_tvalid_1 ),
                ///*input  [AXI_ST_DW/8 - 1:0]  */    .axi_st_c2h_tuser_1  ( axi_st_c2h_tuser_1  ),
                ////---------- C2H AXI4-ST Channel 2 ---------------//
                ///*output                      */    .axi_st_c2h_tready_2 ( axi_st_c2h_tready_2 ),
                ///*input                       */    .axi_st_c2h_tlast_2  ( axi_st_c2h_tlast_2  ),
                ///*input  [AXI_ST_DW - 1:0]    */    .axi_st_c2h_tdata_2  ( axi_st_c2h_tdata_2  ),
                ///*input                       */    .axi_st_c2h_tvalid_2 ( axi_st_c2h_tvalid_2 ),
                ///*input  [AXI_ST_DW/8 - 1:0]  */    .axi_st_c2h_tuser_2  ( axi_st_c2h_tuser_2  ),
                ////---------- C2H AXI4-ST Channel 3 ---------------//
                ///*output                      */    .axi_st_c2h_tready_3 ( axi_st_c2h_tready_3 ),
                ///*input                       */    .axi_st_c2h_tlast_3  ( axi_st_c2h_tlast_3  ),
                ///*input  [AXI_ST_DW - 1:0]    */    .axi_st_c2h_tdata_3  ( axi_st_c2h_tdata_3  ),
                ///*input                       */    .axi_st_c2h_tvalid_3 ( axi_st_c2h_tvalid_3 ),
                ///*input  [AXI_ST_DW/8 - 1:0]  */    .axi_st_c2h_tuser_3  ( axi_st_c2h_tuser_3  ),
                //-------- Host AXI-Lite slave Interface ---------//
                /*input                       */    .h_s_axi_arvalid   ( h_s_axi_arvalid ),        
                /*input  [AXI_LITE_AW - 1:0]  */    .h_s_axi_araddr    ( h_s_axi_araddr  ),        
                /*output                      */    .h_s_axi_arready   ( h_s_axi_arready ),        
                /*output                      */    .h_s_axi_rvalid    ( h_s_axi_rvalid  ),        
                /*output [AXI_LITE_DW - 1:0]  */    .h_s_axi_rdata     ( h_s_axi_rdata   ),        
                /*output [0001:0]             */    .h_s_axi_rresp     ( h_s_axi_rresp   ),        
                /*input                       */    .h_s_axi_rready    ( h_s_axi_rready  ),        
                /*input                       */    .h_s_axi_awvalid   ( h_s_axi_awvalid ),        
                /*input  [AXI_LITE_AW - 1:0]  */    .h_s_axi_awaddr    ( h_s_axi_awaddr  ),        
                /*output                      */    .h_s_axi_awready   ( h_s_axi_awready ),        
                /*input                       */    .h_s_axi_wvalid    ( h_s_axi_wvalid  ),        
                /*input  [AXI_LITE_DW - 1:0]  */    .h_s_axi_wdata     ( h_s_axi_wdata   ),        
                /*input  [AXI_LITE_DW/8 - 1:0]*/    .h_s_axi_wstrb     ( h_s_axi_wstrb   ),        
                /*output                      */    .h_s_axi_wready    ( h_s_axi_wready  ),        
                /*output                      */    .h_s_axi_bvalid    ( h_s_axi_bvalid  ),        
                /*output [0001:0]             */    .h_s_axi_bresp     ( h_s_axi_bresp   ),        
                /*input                       */    .h_s_axi_bready    ( h_s_axi_bready  ),        
                //------- Action AXI-Lite slave Interface --------//
                /*input                       */    .a_s_axi_arvalid   ( a_s_axi_arvalid ),        
                /*input  [AXI_LITE_AW - 1:0]  */    .a_s_axi_araddr    ( a_s_axi_araddr  ),        
                /*output                      */    .a_s_axi_arready   ( a_s_axi_arready ),        
                /*output                      */    .a_s_axi_rvalid    ( a_s_axi_rvalid  ),        
                /*output [AXI_LITE_DW - 1:0]  */    .a_s_axi_rdata     ( a_s_axi_rdata   ),        
                /*output [0001:0]             */    .a_s_axi_rresp     ( a_s_axi_rresp   ),        
                /*input                       */    .a_s_axi_rready    ( a_s_axi_rready  ),        
                /*input                       */    .a_s_axi_awvalid   ( a_s_axi_awvalid ),        
                /*input  [AXI_LITE_AW - 1:0]  */    .a_s_axi_awaddr    ( a_s_axi_awaddr  ),        
                /*output                      */    .a_s_axi_awready   ( a_s_axi_awready ),        
                /*input                       */    .a_s_axi_wvalid    ( a_s_axi_wvalid  ),        
                /*input  [AXI_LITE_DW - 1:0]  */    .a_s_axi_wdata     ( a_s_axi_wdata   ),        
                /*input  [AXI_LITE_DW/8 - 1:0]*/    .a_s_axi_wstrb     ( a_s_axi_wstrb   ),        
                /*output                      */    .a_s_axi_wready    ( a_s_axi_wready  ),        
                /*output                      */    .a_s_axi_bvalid    ( a_s_axi_bvalid  ),        
                /*output [0001:0]             */    .a_s_axi_bresp     ( a_s_axi_bresp   ),        
                /*input                       */    .a_s_axi_bready    ( a_s_axi_bready  ),         
                //------- Action AXI-Lite master Interface -------//
                /*output                      */    .a_m_axi_arvalid   ( a_m_axi_arvalid ),
                /*output [AXI_LITE_AW - 1:0]  */    .a_m_axi_araddr    ( a_m_axi_araddr  ),
                /*input                       */    .a_m_axi_arready   ( a_m_axi_arready ),
                /*input                       */    .a_m_axi_rvalid    ( a_m_axi_rvalid  ),
                /*input  [AXI_LITE_DW - 1:0]  */    .a_m_axi_rdata     ( a_m_axi_rdata   ),
                /*input  [0001:0]             */    .a_m_axi_rresp     ( a_m_axi_rresp   ),
                /*output                      */    .a_m_axi_rready    ( a_m_axi_rready  ),
                /*output                      */    .a_m_axi_awvalid   ( a_m_axi_awvalid ),
                /*output [AXI_LITE_AW - 1:0]  */    .a_m_axi_awaddr    ( a_m_axi_awaddr  ),
                /*input                       */    .a_m_axi_awready   ( a_m_axi_awready ),
                /*output                      */    .a_m_axi_wvalid    ( a_m_axi_wvalid  ),
                /*output [AXI_LITE_DW - 1:0]  */    .a_m_axi_wdata     ( a_m_axi_wdata   ),
                /*output [AXI_LITE_DW/8 - 1:0]*/    .a_m_axi_wstrb     ( a_m_axi_wstrb   ),
                /*input                       */    .a_m_axi_wready    ( a_m_axi_wready  ),
                /*input                       */    .a_m_axi_bvalid    ( a_m_axi_bvalid  ),
                /*input  [0001:0]             */    .a_m_axi_bresp     ( a_m_axi_bresp   ),
                /*output                      */    .a_m_axi_bready    ( a_m_axi_bready  )     
                );
endmodule

