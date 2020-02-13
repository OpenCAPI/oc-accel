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

//                                    opencapi30_c1, the left side
//+------------------------------------------------------------------------------------------+
//|                                                                                          |
//| +--------+                                    +--------------------+                     |
//| |        |<-----------------------------------|   context_surveil  |<------------        |
//| |        |                                    +--------------------+            |        |
//| |  tlx_  |   +---------------------+       $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  |
//| |  cmd_  |<--|    command_encode   |       $$ +--------------------+            |        |
//| | clock_ |   |     write_channel   |<------$$-+                    |     +------+------+ |
//| |  conv  |   +---------------------+       $$ |                    |<----|             | |
//| |        |   +---------------------+  +----$$>|     data_bridge    |     |             | |
//| |        |   |    command_encode   |  |    $$ |    write_channel   |     |             | |
//| |        |<--|     read_channel    |<-+--+ $$ |                    |---->|             | |
//| +--------+   +---------------------+  |  | $$ +--------------------+     |             | |
//|                                       |  | $$                            |  axi_slave  | |
//|                                       |  | $$                            |             | |
//| +--------+   +---------------------+  |  | $$ +--------------------+     |             | |
//| |        |-->|    response_decode  +--+  | $$ |                    |<----|             | |
//| |  tlx_  |   |     write_channel   |     +-$$-+     data_bridge    |     |             | |
//| |  resp_ |   +---------------------+       $$ |     read_channel   |     |             | |
//| | clock_ |   +---------------------+    +--$$>|                    |---->|             | |
//| |  conv  |   |    response_decode  |    |  $$ +--------------------+     |             | |
//| |        |-->|     read_channel    |----+  $$                            |             | |
//| +--------+   +---------------------+       $$                            +-------------+ |
//+--------------------------------------------$$--------------------------------------------+

module opencapi30_c1
                 #(
                   parameter TAGW = 7,   //Use 128 afu tags
                   parameter CTXW = 9   //Use 128 afu tags
                  )
                  (
                   //---- synchronous clocks and reset ----------------------
                   input                 clock_tlx                        ,
                   input                 clock_afu                        ,
                   input                 resetn                            ,

                   //---- configurations ------------------------------------
                   input      [0003:0]   cfg_infra_backoff_timer              ,
                   input      [0007:0]   cfg_infra_bdf_bus                    ,
                   input      [0004:0]   cfg_infra_bdf_device                 ,
                   input      [0002:0]   cfg_infra_bdf_function               ,
                   input      [0011:0]   cfg_infra_actag_base                 ,
                   input      [0019:0]   cfg_infra_pasid_base                 ,
                   input      [0004:0]   cfg_infra_pasid_length               ,

                   //---- mmio debug and FIR --------------------------------
                   input                 debug_info_clear                ,
                   output     [0476:0]   debug_bus                      ,

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

                   //----- dma  --------------------------------------
                          //---- command encoder ---------------
                   output                dma_wr_cmd_ready       ,
                   input                 dma_wr_cmd_valid       ,
                   input     [1023:0]    dma_wr_cmd_data        ,
                   input     [0127:0]    dma_wr_cmd_be          ,
                   input     [0063:0]    dma_wr_cmd_ea          ,
                   input   [TAGW-1:0]    dma_wr_cmd_tag         ,

                          //---- response decoder --------------
                   output                dma_wr_resp_valid      ,
                   output      [1023:0]  dma_wr_resp_data       ,//N/A
                   output    [TAGW-1:0]  dma_wr_resp_tag        ,
                   output      [0001:0]  dma_wr_resp_pos        ,
                   output      [0002:0]  dma_wr_resp_code       ,
                          //---- command encoder ---------------
                   output                dma_rd_cmd_ready     ,
                   input                 dma_rd_cmd_valid     ,
                   input     [1023:0]    dma_rd_cmd_data      ,
                   input     [0127:0]    dma_rd_cmd_be        ,
                   input     [0063:0]    dma_rd_cmd_ea        ,
                   input   [TAGW-1:0]    dma_rd_cmd_tag       ,

                          //---- response decoder --------------
                   output                dma_rd_resp_valid    ,
                   output      [1023:0]  dma_rd_resp_data     ,
                   output    [TAGW-1:0]  dma_rd_resp_tag      ,
                   output      [0001:0]  dma_rd_resp_pos      ,
                   output      [0002:0]  dma_rd_resp_code     ,

                   // context
                   input      [008:0]    lcl_wr_ctx            ,
                   input      [008:0]    lcl_rd_ctx            ,
                   input                 lcl_wr_ctx_valid      ,
                   input                 lcl_rd_ctx_valid      ,

                   // interrupt
                   output                interrupt_ack          ,
                   input                 interrupt              ,
                   input      [063:0]    interrupt_src          ,
                   input      [008:0]    interrupt_ctx
                   );



wire   [063:0]  tlx_r_cmd_be     ;

//---- command encoder -----
wire            w_prt_cmd_valid ;
wire            w_prt_cmd_start ;
wire            w_prt_cmd_last  ;
wire            w_prt_cmd_enable;

//---- response decoder ----;

//---- command encoder -----
wire            r_prt_cmd_valid ;
wire            r_prt_cmd_start ;
wire            r_prt_cmd_last  ;
wire            r_prt_cmd_enable;

//---- response decoder ----;

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
wire  [0019:0] tlx_w_cmd_pasid    ;
wire  [0011:0] tlx_w_cmd_actag    ;

wire           tlx_r_cmd_valid    ;
wire  [0007:0] tlx_r_cmd_opcode   ;
wire  [0067:0] tlx_r_cmd_ea_or_obj;
wire  [0015:0] tlx_r_cmd_afutag   ;
wire  [0001:0] tlx_r_cmd_dl       ;
wire  [0002:0] tlx_r_cmd_pl       ;
wire           tlx_r_cmd_ready    ;
wire  [0019:0] tlx_r_cmd_pasid    ;
wire  [0011:0] tlx_r_cmd_actag    ;
wire  [1023:0] tlx_r_cdata_bus    ;

//debug and FIR from submodules
// 1+1+2+2+2+5+6+5+5 + 7*64 = 477
wire           fir_tlx_response_unsupport;
wire           fir_tlx_rsp_err           ;
wire  [0001:0] fir_tlx_command_credit    ;

wire  [0001:0] fir_fifo_overflow_cmdencw ;
wire  [0001:0] fir_fifo_overflow_cmdencr ;
wire  [0004:0] fir_fifo_overflow_cmdcnv  ;
wire  [0005:0] fir_fifo_overflow_rspcnv  ;
wire  [0004:0] fir_fifo_overflow_rspdecw ;
wire  [0004:0] fir_fifo_overflow_rspdecr ;

wire  [0031:0] debug_tlx_cnt_cmd_w       ;
wire  [0031:0] debug_tlx_cnt_rsp_w       ;
wire  [0031:0] debug_tlx_cnt_retry_w     ;
wire  [0031:0] debug_tlx_cnt_fail_w      ;
wire  [0031:0] debug_tlx_cnt_xlt_pd_w    ;
wire  [0031:0] debug_tlx_cnt_xlt_done_w  ;
wire  [0031:0] debug_tlx_cnt_xlt_retry_w ;

wire  [0031:0] debug_tlx_cnt_cmd_r       ;
wire  [0031:0] debug_tlx_cnt_rsp_r       ;
wire  [0031:0] debug_tlx_cnt_retry_r     ;
wire  [0031:0] debug_tlx_cnt_fail_r      ;
wire  [0031:0] debug_tlx_cnt_xlt_pd_r    ;
wire  [0031:0] debug_tlx_cnt_xlt_done_r  ;
wire  [0031:0] debug_tlx_cnt_xlt_retry_r ;

 assign debug_bus = {fir_tlx_response_unsupport, fir_tlx_rsp_err, fir_tlx_command_credit,
                     fir_fifo_overflow_cmdencw, fir_fifo_overflow_cmdencr,
                     fir_fifo_overflow_cmdcnv, fir_fifo_overflow_rspcnv,
                     fir_fifo_overflow_rspdecw, fir_fifo_overflow_rspdecr,
                     debug_tlx_cnt_cmd_w,  debug_tlx_cnt_cmd_r,
                     debug_tlx_cnt_rsp_w,  debug_tlx_cnt_rsp_r,
                     debug_tlx_cnt_retry_w,  debug_tlx_cnt_retry_r,
                     debug_tlx_cnt_fail_w,  debug_tlx_cnt_fail_r,
                     debug_tlx_cnt_xlt_pd_w,  debug_tlx_cnt_xlt_pd_r,
                     debug_tlx_cnt_xlt_done_w,  debug_tlx_cnt_xlt_done_r,
                     debug_tlx_cnt_xlt_retry_w,  debug_tlx_cnt_xlt_retry_r};

wire           tlx_i_cmd_valid  ;
wire  [0067:0] tlx_i_cmd_obj    ;
wire  [0015:0] tlx_i_cmd_afutag ;
wire  [0007:0] tlx_i_cmd_opcode ;
wire           tlx_i_rsp_valid  ;
wire  [0015:0] tlx_i_rsp_afutag ;
wire  [0007:0] tlx_i_rsp_opcode ;
wire  [0003:0] tlx_i_rsp_code   ;
wire  [0019:0] tlx_i_cmd_pasid  ;
wire  [0011:0] tlx_i_cmd_actag  ;

reg   [0019:0] cfg_pasid_mask;

//---- convert the enabled pasid length into a mask ----
 always@*
   begin
     case(cfg_infra_pasid_length)
       5'b10011 : cfg_pasid_mask = 20'h80000;
       5'b10010 : cfg_pasid_mask = 20'hC0000;
       5'b10001 : cfg_pasid_mask = 20'hE0000;
       5'b10000 : cfg_pasid_mask = 20'hF0000;
       5'b01111 : cfg_pasid_mask = 20'hF8000;
       5'b01110 : cfg_pasid_mask = 20'hFC000;
       5'b01101 : cfg_pasid_mask = 20'hFE000;
       5'b01100 : cfg_pasid_mask = 20'hFF000;
       5'b01011 : cfg_pasid_mask = 20'hFF800;
       5'b01010 : cfg_pasid_mask = 20'hFFC00;
       5'b01001 : cfg_pasid_mask = 20'hFFE00;
       5'b01000 : cfg_pasid_mask = 20'hFFF00;
       5'b00111 : cfg_pasid_mask = 20'hFFF80;
       5'b00110 : cfg_pasid_mask = 20'hFFFC0;
       5'b00101 : cfg_pasid_mask = 20'hFFFE0;
       5'b00100 : cfg_pasid_mask = 20'hFFFF0;
       5'b00011 : cfg_pasid_mask = 20'hFFFF8;
       5'b00010 : cfg_pasid_mask = 20'hFFFFC;
       5'b00001 : cfg_pasid_mask = 20'hFFFFE;
       5'b00000 : cfg_pasid_mask = 20'hFFFFF;
       default  : cfg_pasid_mask = 20'h00000;
     endcase
   end 



//===============================================================================================================
// Clock converters:
//     tlx_cmd_converter: from 200MHz (data bridge) to 400MHz (tlx domain)
//     tlx_rsp_converter: from 400MHz (tlx domain)  to 200MHz (data bridge)
//
//===============================================================================================================



tlx_cmd_converter tlx_cmd_conv (
                /*input                 */   .clock_tlx                         ( clock_tlx                         ),
                /*input                 */   .clock_afu                         ( clock_afu                         ),
                /*input                 */   .resetn                           ( resetn                           ),

                //---- configuration ---------------------------------
                /*input      [007:0]    */   .cfg_bdf_bus                     ( cfg_infra_bdf_bus               ),
                /*input      [004:0]    */   .cfg_bdf_device                  ( cfg_infra_bdf_device            ),
                /*input      [002:0]    */   .cfg_bdf_function                ( cfg_infra_bdf_function          ),

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
                /*input      [005:0]    */   .tlx_afu_cmd_data_initial_credit ( tlx_afu_cmd_data_initial_credit ),

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
                /*input      [0019:0]   */   .tlx_wr_cmd_pasid                ( tlx_w_cmd_pasid                ),
                /*input      [0011:0]   */   .tlx_wr_cmd_actag                ( tlx_w_cmd_actag                ),

                // read channel
                /*input                 */   .tlx_rd_cmd_valid                ( tlx_r_cmd_valid                ),
                /*input      [0007:0]   */   .tlx_rd_cmd_opcode               ( tlx_r_cmd_opcode               ),
                /*input      [0067:0]   */   .tlx_rd_cmd_ea_or_obj            ( tlx_r_cmd_ea_or_obj            ),
                /*input      [0015:0]   */   .tlx_rd_cmd_afutag               ( tlx_r_cmd_afutag               ),
                /*input      [0001:0]   */   .tlx_rd_cmd_dl                   ( tlx_r_cmd_dl                   ),
                /*input      [0002:0]   */   .tlx_rd_cmd_pl                   ( tlx_r_cmd_pl                   ),
                /*output                */   .tlx_rd_cmd_ready                ( tlx_r_cmd_ready                ),
                /*input      [0019:0]   */   .tlx_rd_cmd_pasid                ( tlx_r_cmd_pasid                ),
                /*input      [0011:0]   */   .tlx_rd_cmd_actag                ( tlx_r_cmd_actag                ),

                // interrupt channel
                /*input                 */   .tlx_in_cmd_valid                ( tlx_i_cmd_valid                ),
                /*input      [067:0]    */   .tlx_in_cmd_obj                  ( tlx_i_cmd_obj                  ),
                /*input      [015:0]    */   .tlx_in_cmd_afutag               ( tlx_i_cmd_afutag               ),
                /*input      [007:0]    */   .tlx_in_cmd_opcode               ( tlx_i_cmd_opcode               ),
                /*input      [0019:0]   */   .tlx_in_cmd_pasid                ( tlx_i_cmd_pasid                ),
                /*input      [0011:0]   */   .tlx_in_cmd_actag                ( tlx_i_cmd_actag                ),

                //---- control and status --------------------------------
                ///*input      [031:0]    */   .debug_tlx_cmd_idle_lim          ( debug_tlx_cmd_idle_lim         ),
                ///*output                */   .debug_tlx_cmd_idle              ( debug_tlx_cmd_idle             ),
                /*output     [0004:0]   */   .fir_fifo_overflow               ( fir_fifo_overflow_cmdcnv       ),
                /*output     [0001:0]   */   .fir_tlx_command_credit          ( fir_tlx_command_credit         )
                );


tlx_rsp_converter tlx_rsp_conv(
                /*input                 */   .clock_tlx                         ( clock_tlx                         ),
                /*input                 */   .clock_afu                         ( clock_afu                         ),
                /*input                 */   .resetn                           ( resetn                           ),

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
                ///*input      [031:0]   */    .debug_tlx_rsp_idle_lim         ( debug_tlx_rsp_idle_lim         ),
                ///*output               */    .debug_tlx_rsp_idle             ( debug_tlx_rsp_idle             ),
                /*output     [005:0]   */    .fir_fifo_overflow              ( fir_fifo_overflow_rspcnv       ),
	               /*output               */    .fir_tlx_rsp_err                ( fir_tlx_rsp_err                )
                );





//===============================================================================================================
// Command Encode:
//     write_channel
//     read_channel
//===============================================================================================================



command_encode
                #(
                  .TAGW (TAGW),
                  .MODE (1'b0) //0: write; 1: read
                  )
                cmd_enc_w (
                /*input                 */   .clk                          ( clock_afu                      ),
                /*input                 */   .resetn                        ( resetn                        ),

                //---- configuration ---------------------------------
                /*input      [011:0]    */   .cfg_actag_base               ( cfg_actag_base               ),
                /*input      [019:0]    */   .cfg_pasid_base               ( cfg_pasid_base               ),
                /*input      [019:0]    */   .cfg_pasid_mask               ( cfg_pasid_mask               ),

                //---- communication with command decoder -----
                /*output                */   .prt_cmd_valid                ( w_prt_cmd_valid              ),
                /*output                */   .prt_cmd_last                 ( w_prt_cmd_last               ),
                /*output                */   .prt_cmd_start                ( w_prt_cmd_start              ),
                /*input                 */   .prt_cmd_enable               ( w_prt_cmd_enable             ),

                //---- DMA interface ---------------------------------
                /*output                */   .dma_cmd_ready                ( dma_wr_cmd_ready                ),
                /*input                 */   .dma_cmd_valid                ( dma_wr_cmd_valid                ),
                /*input      [1023:0]   */   .dma_cmd_data                 ( dma_wr_cmd_data                 ),
                /*input      [0127:0]   */   .dma_cmd_be                   ( dma_wr_cmd_be                   ),
                /*input      [0063:0]   */   .dma_cmd_ea                   ( dma_wr_cmd_ea                   ),
                /*input      [0005:0]   */   .dma_cmd_tag                  ( dma_wr_cmd_tag                  ),
                /*input      [CTXW-1:0] */   .dma_cmd_ctx                  ( dma_wr_cmd_ctx                  ),

                //---- TLX interface ---------------------------------
                  // command
                /*output reg            */   .tlx_cmd_valid                ( tlx_w_cmd_valid                ),
                /*output reg [0007:0]   */   .tlx_cmd_opcode               ( tlx_w_cmd_opcode               ),
                /*output reg [0067:0]   */   .tlx_cmd_ea_or_obj            ( tlx_w_cmd_ea_or_obj            ),
                /*output reg [0015:0]   */   .tlx_cmd_afutag               ( tlx_w_cmd_afutag               ),
                /*output reg [0001:0]   */   .tlx_cmd_dl                   ( tlx_w_cmd_dl                   ),
                /*output reg [0002:0]   */   .tlx_cmd_pl                   ( tlx_w_cmd_pl                   ),
                /*output     [0063:0]   */   .tlx_cmd_be                   ( tlx_w_cmd_be                   ),
                /*output reg [0019:0]   */   .tlx_cmd_pasid                ( tlx_w_cmd_pasid                ),
                /*output reg [0011:0]   */   .tlx_cmd_actag                ( tlx_w_cmd_actag                ),
                /*output reg [1023:0]   */   .tlx_cdata_bus                ( tlx_w_cdata_bus                ),

                  // credit availability
                /*input                 */   .tlx_cmd_rdy                  ( tlx_w_cmd_ready                ),

                //---- control and status ---------------------
                /*input                 */   .debug_info_clear              (debug_info_clear                 ),
                /*output     [0031:0]   */   .debug_tlx_cnt_cmd            (debug_tlx_cnt_cmd_w             ),
                /*output     [0001:0]   */   .fir_fifo_overflow            (fir_fifo_overflow_cmdencw       )
                );


command_encode
                #(
                  .TAGW (TAGW),
                  .MODE  (1'b1) //0: write; 1: read
                  )
                cmd_enc_r  (
                /*input                 */   .clk                          ( clock_afu                      ),
                /*input                 */   .resetn                        ( resetn                        ),

                //---- configuration ---------------------------------
                /*input      [011:0]    */   .cfg_actag_base               ( cfg_actag_base               ),
                /*input      [019:0]    */   .cfg_pasid_base               ( cfg_pasid_base               ),
                /*input      [019:0]    */   .cfg_pasid_mask               ( cfg_pasid_mask               ),

                //---- communication with command decoder -----
                /*output                */   .prt_cmd_valid                ( r_prt_cmd_valid              ),
                /*output                */   .prt_cmd_last                 ( r_prt_cmd_last               ),
                /*output                */   .prt_cmd_start                ( r_prt_cmd_start              ),
                /*input                 */   .prt_cmd_enable               ( r_prt_cmd_enable             ),

                //---- DMA interface ---------------------------------
                /*output                */   .dma_cmd_ready                ( dma_rd_cmd_ready                ),
                /*input                 */   .dma_cmd_valid                ( dma_rd_cmd_valid                ),
                /*input      [1023:0]   */   .dma_cmd_data                 ( dma_rd_cmd_data                 ),
                /*input      [0127:0]   */   .dma_cmd_be                   ( dma_rd_cmd_be                   ),
                /*input      [0063:0]   */   .dma_cmd_ea                   ( dma_rd_cmd_ea                   ),
                /*input      [0005:0]   */   .dma_cmd_tag                  ( dma_rd_cmd_tag                  ),
                /*input      [CTXW-1:0] */   .dma_cmd_ctx                  ( dma_rd_cmd_ctx                  ),

                //---- TLX interface ---------------------------------
                  // command
                /*output reg            */   .tlx_cmd_valid                ( tlx_r_cmd_valid                ),
                /*output reg [0007:0]   */   .tlx_cmd_opcode               ( tlx_r_cmd_opcode               ),
                /*output reg [0067:0]   */   .tlx_cmd_ea_or_obj            ( tlx_r_cmd_ea_or_obj            ),
                /*output reg [0015:0]   */   .tlx_cmd_afutag               ( tlx_r_cmd_afutag               ),
                /*output reg [0001:0]   */   .tlx_cmd_dl                   ( tlx_r_cmd_dl                   ),
                /*output reg [0002:0]   */   .tlx_cmd_pl                   ( tlx_r_cmd_pl                   ),
                /*output     [0063:0]   */   .tlx_cmd_be                   ( tlx_r_cmd_be                   ),
                /*output reg [0019:0]   */   .tlx_cmd_pasid                ( tlx_r_cmd_pasid                ),
                /*output reg [0011:0]   */   .tlx_cmd_actag                ( tlx_r_cmd_actag                ),
                /*output reg [1023:0]   */   .tlx_cdata_bus                ( tlx_r_cdata_bus                ),

                  // credit availability
                /*input                 */   .tlx_cmd_rdy                  ( tlx_r_cmd_ready                ),

                //---- control and status ---------------------
                /*input                 */   .debug_info_clear              (debug_info_clear                 ),
                /*output     [0031:0]   */   .debug_tlx_cnt_cmd            (debug_tlx_cnt_cmd_r             ),
                /*output     [0001:0]   */   .fir_fifo_overflow            (fir_fifo_overflow_cmdencr       )
                );

//===============================================================================================================
// Response Decode:
//     write_channel
//     read_channel
//===============================================================================================================

response_decode
                #(
                 .TAGW (TAGW),
                 .MODE  (1'b0) //0: write; 1: read
                 )
                rsp_dec_w (
                /*input                 */   .clk               ( clock_afu           ),
                /*input                 */   .resetn             ( resetn             ),

                //---- configuration --------------------------------------
                /*input      [0003:0]   */   .cfg_backoff_timer ( cfg_infra_backoff_timer ),

                //---- communication with command decoder -----
                /*input                 */   .prt_cmd_valid     ( w_prt_cmd_valid   ),
                /*input                 */   .prt_cmd_last      ( w_prt_cmd_last    ),
                /*output reg            */   .prt_cmd_enable    ( w_prt_cmd_enable  ),
                /*output                */   .prt_cmd_start     ( w_prt_cmd_start   ),

                //---- DMA interface --------------------------
                /*output reg            */   .dma_resp_valid    ( dma_wr_resp_valid  ),
                /*output reg [1023:0]   */   .dma_resp_data     ( dma_wr_resp_data   ),//N/A
                /*output reg [0005:0]   */   .dma_resp_tag      ( dma_wr_resp_tag    ),
                /*output reg [0001:0]   */   .dma_resp_pos      ( dma_wr_resp_pos    ),
                /*output reg [0002:0]   */   .dma_resp_code     ( dma_wr_resp_code   ),

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
                /*input                 */   .debug_info_clear            ( debug_info_clear           ),
                /*output     [0031:0]   */   .debug_tlx_cnt_rsp          ( debug_tlx_cnt_rsp_w       ),
                /*output     [0031:0]   */   .debug_tlx_cnt_retry        ( debug_tlx_cnt_retry_w     ),
                /*output     [0031:0]   */   .debug_tlx_cnt_fail         ( debug_tlx_cnt_fail_w      ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_pd       ( debug_tlx_cnt_xlt_pd_w    ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_done     ( debug_tlx_cnt_xlt_done_w  ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_retry    ( debug_tlx_cnt_xlt_retry_w ),
                /*output     [0004:0]   */   .fir_fifo_overflow          ( fir_fifo_overflow_rspdecw ),
                /*output                */   .fir_tlx_response_unsupport ( fir_tlx_response_unsupport)
                );


response_decode
                #(
                  .TAGW (TAGW),
                  .MODE  (1'b1) //0: write; 1: read
                  )
                rsp_dec_r (
                /*input                */   .clk               ( clock_afu           ),
                /*input                */   .resetn             ( resetn             ),

                //---- configuration --------------------------------------
                /*input      [0003:0]  */    .cfg_backoff_timer(cfg_infra_backoff_timer  ),

                //---- communication with command decoder -----
                /*input                 */   .prt_cmd_valid     ( r_prt_cmd_valid   ),
                /*input                 */   .prt_cmd_last      ( r_prt_cmd_last    ),
                /*output reg            */   .prt_cmd_enable    ( r_prt_cmd_enable  ),
                /*output                */   .prt_cmd_start     ( r_prt_cmd_start   ),

                //---- DMA interface --------------------------
                /*output reg           */   .dma_resp_valid    ( dma_rd_resp_valid  ),
                /*output reg [1023:0]  */   .dma_resp_data     ( dma_rd_resp_data   ),
                /*output reg [0005:0]  */   .dma_resp_tag      ( dma_rd_resp_tag    ),
                /*output reg [0001:0]  */   .dma_resp_pos      ( dma_rd_resp_pos    ),
                /*output reg [0002:0]  */   .dma_resp_code     ( dma_rd_resp_code   ),

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
                /*input                 */   .debug_info_clear            ( debug_info_clear           ),
                /*output     [0031:0]   */   .debug_tlx_cnt_rsp          ( debug_tlx_cnt_rsp_r       ),
                /*output     [0031:0]   */   .debug_tlx_cnt_retry        ( debug_tlx_cnt_retry_r     ),
                /*output     [0031:0]   */   .debug_tlx_cnt_fail         ( debug_tlx_cnt_fail_r      ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_pd       ( debug_tlx_cnt_xlt_pd_r    ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_done     ( debug_tlx_cnt_xlt_done_r  ),
                /*output     [0031:0]   */   .debug_tlx_cnt_xlt_retry    ( debug_tlx_cnt_xlt_retry_r ),
                /*output     [0004:0]   */   .fir_fifo_overflow          ( fir_fifo_overflow_rspdecr )
                );

//
//===============================================================================================================

 interrupt_tlx interrupt_tlx (
                       /*input              */  .clk              (clock_afu             ),
                       /*input              */  .resetn            (resetn               ),
                       /*input      [011:0] */  .cfg_actag_base   (cfg_actag_base      ),
                       /*input      [019:0] */  .cfg_pasid_base   (cfg_pasid_base      ),
                       /*input      [019:0] */  .cfg_pasid_mask   (cfg_pasid_mask      ),
                       /*input      [003:0] */  .backoff_limit    (cfg_backoff_timer   ),
                       /*input              */  .interrupt_enable (1'b1                ),
                       /*output             */  .interrupt_ack    (interrupt_ack       ),
                       /*input              */  .interrupt        (interrupt           ),
                       /*input      [067:0] */  .interrupt_src    (interrupt_src       ),
                       /*input      [008:0] */  .interrupt_ctx    (interrupt_ctx       ),
                       /*output reg         */  .tlx_cmd_valid    (tlx_i_cmd_valid     ),
                       /*output reg [067:0] */  .tlx_cmd_obj      (tlx_i_cmd_obj       ),
                       /*output reg [015:0] */  .tlx_cmd_afutag   (tlx_i_cmd_afutag    ),
                       /*output reg [007:0] */  .tlx_cmd_opcode   (tlx_i_cmd_opcode    ),
                       /*output reg [019:0] */  .tlx_cmd_pasid    (tlx_i_cmd_pasid     ),
                       /*output reg [011:0] */  .tlx_cmd_actag    (tlx_i_cmd_actag     ),
                       /*input              */  .tlx_rsp_valid    (tlx_i_rsp_valid     ),
                       /*input      [0015:0]*/  .tlx_rsp_afutag   (tlx_i_rsp_afutag    ),
                       /*input      [0007:0]*/  .tlx_rsp_opcode   (tlx_i_rsp_opcode    ),
                       /*input      [0003:0]*/  .tlx_rsp_code     (tlx_i_rsp_code      )
                       );

endmodule
