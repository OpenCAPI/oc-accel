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

module brdg_tlx_cmd_converter (
                          input                      clk_tlx                        ,
                          input                      clk_afu                        ,
                          input                      rst_n                          ,

                          //---- configuration --------------------------------------
                          input      [007:0]         cfg_bdf_bus                    ,
                          input      [004:0]         cfg_bdf_device                 ,
                          input      [002:0]         cfg_bdf_function               ,

                          //---- TLX side interface --------------------------------
                            // command
                          output reg                 afu_tlx_cmd_valid              ,    
                          output reg [007:0]         afu_tlx_cmd_opcode             ,     
                          output reg [011:0]         afu_tlx_cmd_actag              ,    
                          output     [003:0]         afu_tlx_cmd_stream_id          ,        
                          output reg [067:0]         afu_tlx_cmd_ea_or_obj          ,        
                          output reg [015:0]         afu_tlx_cmd_afutag             ,     
                          output reg [001:0]         afu_tlx_cmd_dl                 , 
                          output reg [002:0]         afu_tlx_cmd_pl                 , 
                          output                     afu_tlx_cmd_os                 , 
                          output     [063:0]         afu_tlx_cmd_be                 , 
                          output     [003:0]         afu_tlx_cmd_flag               ,   
                          output                     afu_tlx_cmd_endian             ,     
                          output     [015:0]         afu_tlx_cmd_bdf                ,  
                          output reg [019:0]         afu_tlx_cmd_pasid              ,    
                          output     [005:0]         afu_tlx_cmd_pg_size            ,
                            // write data
                          output reg                 afu_tlx_cdata_valid            ,      
                          output                     afu_tlx_cdata_bdi              ,    
                          output reg [511:0]         afu_tlx_cdata_bus              ,    
                            // command and write data credit
                          input                      tlx_afu_cmd_credit             ,   
                          input                      tlx_afu_cmd_data_credit        ,   
                          input      [003:0]         tlx_afu_cmd_initial_credit     ,   
                          input      [005:0]         tlx_afu_cmd_data_initial_credit,  

                          //---- AFU side interface --------------------------------
                            // write channel
                          input                      tlx_wr_cmd_valid               ,    
                          input      [0007:0]        tlx_wr_cmd_opcode              ,     
                          input      [0067:0]        tlx_wr_cmd_ea_or_obj           ,        
                          input      [0015:0]        tlx_wr_cmd_afutag              ,     
                          input      [0001:0]        tlx_wr_cmd_dl                  , 
                          input      [0002:0]        tlx_wr_cmd_pl                  , 
                          input      [0063:0]        tlx_wr_cmd_be                  , 
                          input      [1023:0]        tlx_wr_cdata_bus               ,    
                          output                     tlx_wr_cmd_ready               ,
                            // read channel
                          input                      tlx_rd_cmd_valid               ,    
                          input      [0007:0]        tlx_rd_cmd_opcode              ,     
                          input      [0067:0]        tlx_rd_cmd_ea_or_obj           ,        
                          input      [0015:0]        tlx_rd_cmd_afutag              ,     
                          input      [0001:0]        tlx_rd_cmd_dl                  , 
                          input      [0002:0]        tlx_rd_cmd_pl                  , 
                          output                     tlx_rd_cmd_ready               ,
                            // context channel
                          input                      tlx_ac_cmd_valid               ,
                          input      [0019:0]        tlx_ac_cmd_pasid               ,
                          input      [0011:0]        tlx_ac_cmd_actag               ,
                          input      [0007:0]        tlx_ac_cmd_opcode              ,

                          // interrupt channel
                          input                      tlx_in_cmd_valid               ,
                          input      [0067:0]        tlx_in_cmd_obj                 ,
                          input      [0015:0]        tlx_in_cmd_afutag              ,
                          input      [0007:0]        tlx_in_cmd_opcode              ,

                          //---- control and status --------------------------------
                          input      [031:0]         debug_tlx_cmd_idle_lim         ,
                          output reg                 debug_tlx_cmd_idle             ,
                          output reg [0004:0]        fir_fifo_overflow              ,
                          output reg [0001:0]        fir_tlx_command_credit
                          );


 reg [003:0] cmd_credit_cnt;
 reg [005:0] cmd_data_credit_cnt;
 reg         cmd_credit_run_out;
 reg         cmd_data_credit_run_out;
 reg         cmd_data_credit_lt_4;
 reg         cmd_data_credit_lt_2;
 wire[096:0] fifo_w_cmdcnv_din;  
 wire[096:0] fifo_w_cmdcnv_dout;  
 wire[511:0] fifo_w_datcnv_o_din;
 wire[511:0] fifo_w_datcnv_o_dout;
 wire[511:0] fifo_w_datcnv_e_din;
 wire[511:0] fifo_w_datcnv_e_dout;
 wire        fifo_w_datcnv_e_dv; 
 wire        fifo_w_cmdcnv_den; 
 wire        fifo_w_cmdcnv_half_full; 
 wire[004:0] fifo_w_cmdcnv_wrcnt; 
 wire        fifo_w_datcnv_o_den; 
 wire        fifo_w_datcnv_e_den; 
 wire        fifo_w_cmdcnv_rdrq; 
 wire        fifo_w_datcnv_o_rdrq; 
 wire        fifo_w_datcnv_o_dv; 
 wire        fifo_w_datcnv_e_rdrq; 
 wire        fifo_w_cmdcnv_dv; 
 wire[007:0] fifo_w_cmdcnv_dout_opcode;
 wire[015:0] fifo_w_cmdcnv_dout_afutag;
 wire[067:0] fifo_w_cmdcnv_dout_ea;
 wire[001:0] fifo_w_cmdcnv_dout_dl;   
 wire[002:0] fifo_w_cmdcnv_dout_pl;   
 wire[007:0] fifo_a_cmdcnv_dout_opcode;
 wire[011:0] fifo_a_cmdcnv_dout_actag; 
 wire[019:0] fifo_a_cmdcnv_dout_pasid;
 wire[007:0] fifo_r_cmdcnv_dout_opcode;
 wire[015:0] fifo_r_cmdcnv_dout_afutag;
 wire[067:0] fifo_r_cmdcnv_dout_ea;
 wire[001:0] fifo_r_cmdcnv_dout_dl;   
 wire[002:0] fifo_r_cmdcnv_dout_pl;   
 wire[096:0] fifo_r_cmdcnv_din;  
 wire[096:0] fifo_r_cmdcnv_dout;  
 wire        fifo_r_cmdcnv_den; 
 wire        fifo_r_cmdcnv_dv; 
 wire        fifo_r_cmdcnv_rdrq; 
 wire        fifo_r_cmdcnv_half_full;
 wire[004:0] fifo_r_cmdcnv_wrcnt; 
 wire        fifo_a_cmdcnv_rdrq; 
 wire        fifo_a_cmdcnv_empty; 
 wire        fifo_a_cmdcnv_dv; 
 wire        fifo_a_cmdcnv_den; 
 wire[039:0] fifo_a_cmdcnv_din; 
 wire[039:0] fifo_a_cmdcnv_dout; 
 reg         cmd_crankshaft_main; 
 reg         cmd_crankshaft_sub; 
 wire        fifo_a_cmdcnv_ovfl; 
 wire        fifo_r_cmdcnv_ovfl; 
 wire        fifo_w_datcnv_e_ovfl; 
 wire        fifo_w_datcnv_o_ovfl; 
 wire        fifo_w_cmdcnv_ovfl; 
 reg         tlx_in_cmd_req;
 reg         tlx_in_cmd_ack;
 reg         tlx_in_cmd_rec;
 reg [002:0] tlx_in_cmd_rec_pipe; 
 reg [002:0] tlx_in_cmd_req_pipe; 
 reg         tlx_in_cmd_pending;
 wire        tlx_interrupt_valid_pre;
 reg         tlx_interrupt_valid;
 reg [007:0] tlx_in_cmd_opcode_sync;
 reg [015:0] tlx_in_cmd_afutag_sync;
 reg [067:0] tlx_in_cmd_obj_sync;
 reg [007:0] tlx_interrupt_opcode; 
 reg [015:0] tlx_interrupt_afutag; 
 reg [067:0] tlx_interrupt_obj; 


//---- output MUX ----
 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     begin
       afu_tlx_cmd_valid     <= 1'b0;
       afu_tlx_cmd_opcode    <= 8'd0;
       afu_tlx_cmd_afutag    <= 16'd0;
       afu_tlx_cmd_ea_or_obj <= 68'd0;
       afu_tlx_cmd_dl        <= 2'd0;
       afu_tlx_cmd_pl        <= 3'd0;
       afu_tlx_cmd_actag     <= 12'd0;
       afu_tlx_cmd_pasid     <= 20'd0;
       afu_tlx_cdata_valid   <= 1'b0;
       afu_tlx_cdata_bus     <= 512'd0;
     end
   else 
     begin
       afu_tlx_cmd_valid     <= fifo_w_cmdcnv_dv || fifo_r_cmdcnv_dv || fifo_a_cmdcnv_dv || tlx_interrupt_valid;
       afu_tlx_cmd_opcode    <= fifo_w_cmdcnv_dv? fifo_w_cmdcnv_dout_opcode : 
                               (fifo_r_cmdcnv_dv? fifo_r_cmdcnv_dout_opcode : 
                               (fifo_a_cmdcnv_dv? fifo_a_cmdcnv_dout_opcode : 
                                                  tlx_interrupt_opcode));
       afu_tlx_cmd_afutag    <= fifo_w_cmdcnv_dv? fifo_w_cmdcnv_dout_afutag : 
                               (fifo_r_cmdcnv_dv? fifo_r_cmdcnv_dout_afutag : 
                                                  tlx_interrupt_afutag); 
       afu_tlx_cmd_ea_or_obj <= fifo_w_cmdcnv_dv? fifo_w_cmdcnv_dout_ea     : 
                               (fifo_r_cmdcnv_dv? fifo_r_cmdcnv_dout_ea     :
                                                  tlx_interrupt_obj);
       afu_tlx_cmd_dl        <= fifo_w_cmdcnv_dv? fifo_w_cmdcnv_dout_dl     : fifo_r_cmdcnv_dout_dl;
       afu_tlx_cmd_pl        <= fifo_w_cmdcnv_dv? fifo_w_cmdcnv_dout_pl     : fifo_r_cmdcnv_dout_pl;
       afu_tlx_cmd_actag     <= fifo_a_cmdcnv_dv? fifo_a_cmdcnv_dout_actag  : afu_tlx_cmd_actag;
       afu_tlx_cmd_pasid     <= fifo_a_cmdcnv_dv? fifo_a_cmdcnv_dout_pasid  : afu_tlx_cmd_pasid;
       afu_tlx_cdata_valid   <= (fifo_w_datcnv_o_dv  && (afu_tlx_cmd_dl[1])) || fifo_w_datcnv_e_dv;
       afu_tlx_cdata_bus     <= fifo_w_datcnv_e_dv? fifo_w_datcnv_e_dout : fifo_w_datcnv_o_dout;
     end

//---- defaults ----
 assign afu_tlx_cmd_stream_id = 4'd0;        
 assign afu_tlx_cmd_os        = 1'd0; 
 assign afu_tlx_cmd_be        = 64'd0; 
 assign afu_tlx_cmd_flag      = 4'd0;   
 assign afu_tlx_cmd_endian    = 1'd0;     
 assign afu_tlx_cmd_bdf       = {cfg_bdf_bus, cfg_bdf_device, cfg_bdf_function}; 
 assign afu_tlx_cmd_pg_size   = 6'd0;
 assign afu_tlx_cdata_bdi     = 1'b0;

//---- prevent command encoder from filling in when FIFO's almost full ----
 assign fifo_w_cmdcnv_half_full = fifo_w_cmdcnv_wrcnt[4];
 assign fifo_r_cmdcnv_half_full = fifo_r_cmdcnv_wrcnt[4];
 assign tlx_wr_cmd_ready = ~fifo_w_cmdcnv_half_full;
 assign tlx_rd_cmd_ready = ~fifo_r_cmdcnv_half_full;



//=================================================================================================================
//
// CLOCK DOMAIN CONVERTION FIFO SET : TLX <- AFU
//
//         +---+    +----------------------------+                                 +--------------------------------
//         |   |<===| write channel command FIFO |<=========== command/info =======| 
//         |   |    +----------------------------+                                 |
//         |   |     ^  +----------------------------+                             |  command_encode
//         |   |<====|==|    even write data FIFO    |<========== even data =======|  (write channel)
//         |   |     |  +----------------------------+                             |
//         | M |     |___^                                                         |
//         |   |     |  +----------------------------+                             |
//         | U |<====|==|     odd write data FIFO    |<========== odd data ========|
//         |   |     |  +----------------------------+                             +--------------------------------
//   T     | X |     |    ^ 
//   L <===|   |     |    | +----------------------------+                         +--------------------------------
//   X     |   |<====|== =|=| read channel command FIFO  |<=== command/info =======| command_encode (read channel)
//         |   |     |    | +----------------------------+                         +--------------------------------
//         |   |     |    |   ^
//         |   |     |    |   |  +----------------------------+                    +--------------------------------
//         |   |<====|====|= =|= | actag channel command FIFO |<=== command/info ==| context_surveil (assign actag)
//         +---+     |    |   |  +----------------------------+                    +--------------------------------
//                   |    |   |   ^
//    +------------+_|    |   |   |
//    | crankshaft |______|___|___|
//    +------------+
//
//=================================================================================================================

//---- put write data and command in clock converter FIFO ----
 assign fifo_w_cmdcnv_den   = tlx_wr_cmd_valid;
 assign fifo_w_cmdcnv_din   = {tlx_wr_cmd_pl, tlx_wr_cmd_dl, tlx_wr_cmd_afutag, tlx_wr_cmd_ea_or_obj, tlx_wr_cmd_opcode};//3+2+16+68+8 = 97
 assign fifo_w_datcnv_o_den = tlx_wr_cmd_valid;
 assign fifo_w_datcnv_o_din = tlx_wr_cdata_bus[1023:512];
 assign fifo_w_datcnv_e_den = tlx_wr_cmd_valid;
 assign fifo_w_datcnv_e_din = tlx_wr_cdata_bus[0511:000];

//---- FIFO for write command and info ---- 
 fifo_async #(
              .DATA_WIDTH(97),
              .ADDR_WIDTH(5),
              .DISTR(1)
              ) mfifo_w_cmdcnv (
                                .wr_clk        (clk_afu             ),
                                .rd_clk        (clk_tlx             ),
                                .wr_rst        (~rst_n              ),
                                .rd_rst        (~rst_n              ),
                                .din           (fifo_w_cmdcnv_din   ),
                                .wr_en         (fifo_w_cmdcnv_den   ),
                                .rd_en         (fifo_w_cmdcnv_rdrq  ),
                                .valid         (fifo_w_cmdcnv_dv    ),
                                .dout          (fifo_w_cmdcnv_dout  ),
                                .wr_data_count (fifo_w_cmdcnv_wrcnt ), 
                                .overflow      (fifo_w_cmdcnv_ovfl  ),
                                .empty         ()
                                );

//---- FIFO for higher 64B write data ----
 fifo_async #(
              .DATA_WIDTH(512),
              .ADDR_WIDTH(5),
              .DISTR(1)
              ) mfifo_w_datcnv_o (
                                  .wr_clk  (clk_afu              ),
                                  .rd_clk  (clk_tlx              ),
                                  .wr_rst  (~rst_n               ),
                                  .rd_rst  (~rst_n               ),
                                  .din     (fifo_w_datcnv_o_din  ),
                                  .wr_en   (fifo_w_datcnv_o_den  ),
                                  .rd_en   (fifo_w_datcnv_o_rdrq ),
                                  .valid   (fifo_w_datcnv_o_dv   ),
                                  .dout    (fifo_w_datcnv_o_dout ),
                                  .overflow(fifo_w_datcnv_o_ovfl ),
                                  .empty   ()
                                  );

//---- FIFO for lower 64B write data ---- 
 fifo_async #(
              .DATA_WIDTH(512),
              .ADDR_WIDTH(5),
              .DISTR(1)
              ) mfifo_w_datcnv_e (
                                  .wr_clk  (clk_afu              ),
                                  .rd_clk  (clk_tlx              ),
                                  .wr_rst  (~rst_n               ),
                                  .rd_rst  (~rst_n               ),
                                  .din     (fifo_w_datcnv_e_din  ),
                                  .wr_en   (fifo_w_datcnv_e_den  ),
                                  .rd_en   (fifo_w_datcnv_e_rdrq ),
                                  .valid   (fifo_w_datcnv_e_dv   ),
                                  .dout    (fifo_w_datcnv_e_dout ),
                                  .overflow(fifo_w_datcnv_e_ovfl ),
                                  .empty   ()
                                  );

//---- write channel data output ----
 assign fifo_w_cmdcnv_dout_opcode = fifo_w_cmdcnv_dout[007:000];
 assign fifo_w_cmdcnv_dout_ea     = fifo_w_cmdcnv_dout[075:008];
 assign fifo_w_cmdcnv_dout_afutag = fifo_w_cmdcnv_dout[091:076];
 assign fifo_w_cmdcnv_dout_dl     = fifo_w_cmdcnv_dout[093:092];
 assign fifo_w_cmdcnv_dout_pl     = fifo_w_cmdcnv_dout[096:094];

//---- put read command in clock converter FIFO ----
 assign fifo_r_cmdcnv_din = {tlx_rd_cmd_pl, tlx_rd_cmd_dl, tlx_rd_cmd_afutag, tlx_rd_cmd_ea_or_obj, tlx_rd_cmd_opcode};
 assign fifo_r_cmdcnv_den = tlx_rd_cmd_valid;

//---- FIFO for read command and info ---- 
 fifo_async #(
              .DATA_WIDTH(97),
              .ADDR_WIDTH(5),
              .DISTR(1)
              ) mfifo_r_cmdcnv (
                                .wr_clk        (clk_afu             ),
                                .rd_clk        (clk_tlx             ),
                                .wr_rst        (~rst_n              ),
                                .rd_rst        (~rst_n              ),
                                .din           (fifo_r_cmdcnv_din   ),
                                .wr_en         (fifo_r_cmdcnv_den   ),
                                .rd_en         (fifo_r_cmdcnv_rdrq  ),
                                .valid         (fifo_r_cmdcnv_dv    ),
                                .dout          (fifo_r_cmdcnv_dout  ),
                                .wr_data_count (fifo_r_cmdcnv_wrcnt ), 
                                .overflow      (fifo_r_cmdcnv_ovfl  ),
                                .empty         ()
                                );

//---- write channel data output ----
 assign fifo_r_cmdcnv_dout_opcode = fifo_r_cmdcnv_dout[007:000];
 assign fifo_r_cmdcnv_dout_ea     = fifo_r_cmdcnv_dout[075:008];
 assign fifo_r_cmdcnv_dout_afutag = fifo_r_cmdcnv_dout[091:076];
 assign fifo_r_cmdcnv_dout_dl     = fifo_r_cmdcnv_dout[093:092];
 assign fifo_r_cmdcnv_dout_pl     = fifo_r_cmdcnv_dout[096:094];


//---- put assign ACTAG info in clock converter FIFO ----
 assign fifo_a_cmdcnv_din = {tlx_ac_cmd_pasid, tlx_ac_cmd_actag, tlx_ac_cmd_opcode}; //20+12+8 = 40
 assign fifo_a_cmdcnv_den = tlx_ac_cmd_valid;

//---- FIFO for read command and info ---- 
 fifo_async #(
              .DATA_WIDTH(40),
              .ADDR_WIDTH(3)
              ) mfifo_a_cmdcnv (
                                .wr_clk  (clk_afu            ),
                                .rd_clk  (clk_tlx            ),
                                .wr_rst  (~rst_n             ),
                                .rd_rst  (~rst_n             ),
                                .din     (fifo_a_cmdcnv_din  ),
                                .wr_en   (fifo_a_cmdcnv_den  ),
                                .rd_en   (fifo_a_cmdcnv_rdrq ),
                                .valid   (fifo_a_cmdcnv_dv   ),
                                .dout    (fifo_a_cmdcnv_dout ),
                                .overflow(fifo_a_cmdcnv_ovfl ),
                                .empty   (fifo_a_cmdcnv_empty)
                                );

//---- output for assign actag FIFO ----
 assign fifo_a_cmdcnv_dout_opcode = fifo_a_cmdcnv_dout[07:00];
 assign fifo_a_cmdcnv_dout_actag  = fifo_a_cmdcnv_dout[19:08];
 assign fifo_a_cmdcnv_dout_pasid  = fifo_a_cmdcnv_dout[39:20];


//---- use crankshaft to ensure command data and info from read and write FIFO are popped out alternately ----
 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     cmd_crankshaft_main <= 1'b0;
   else 
     cmd_crankshaft_main <= ~cmd_crankshaft_main;

//---- subordinate crankshaft used for odd data FIFO, it should always follow main crankshaft to guarantee that even data come out first ----
 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     cmd_crankshaft_sub <= 1'b0;
   else 
     cmd_crankshaft_sub <= cmd_crankshaft_main && ~cmd_credit_run_out && ~cmd_data_credit_lt_2;

 assign fifo_w_cmdcnv_rdrq   =  cmd_crankshaft_main && ~cmd_credit_run_out && ~cmd_data_credit_lt_2;
 assign fifo_w_datcnv_e_rdrq =  cmd_crankshaft_main && ~cmd_credit_run_out && ~cmd_data_credit_lt_2;
 assign fifo_w_datcnv_o_rdrq =  cmd_crankshaft_sub;
 assign fifo_r_cmdcnv_rdrq   = ~cmd_crankshaft_main && ~cmd_credit_run_out &&  fifo_a_cmdcnv_empty && ~tlx_interrupt_valid_pre;
 assign fifo_a_cmdcnv_rdrq   = ~cmd_crankshaft_main && ~cmd_credit_run_out && ~fifo_a_cmdcnv_empty && ~tlx_interrupt_valid_pre;



//-----------------------------------------------------------------------------------------------------------------
//  CREDIT MANAGEMENT                                                   
//-----------------------------------------------------------------------------------------------------------------

//---- command and write data credit counters ----
 always@(posedge clk_tlx)
   if(~rst_n) 
     cmd_credit_cnt <= tlx_afu_cmd_initial_credit;   // this should be set through soft resetting 
   else
     case({tlx_afu_cmd_credit, afu_tlx_cmd_valid})
       2'b10 : cmd_credit_cnt <= cmd_credit_cnt + 4'd1;
       2'b01 : cmd_credit_cnt <= cmd_credit_cnt - 4'd1;
       default:;
     endcase

 always@(posedge clk_tlx)
   if(~rst_n) 
     cmd_data_credit_cnt <= tlx_afu_cmd_data_initial_credit;
   else
     case({tlx_afu_cmd_data_credit, afu_tlx_cdata_valid})
       2'b10 : cmd_data_credit_cnt <= cmd_data_credit_cnt + 6'd1;
       2'b01 : cmd_data_credit_cnt <= cmd_data_credit_cnt - 6'd1;
       default:;
     endcase

//---- credit deficiency alert ----
 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     begin
       cmd_credit_run_out      <= 1'b0;
       cmd_data_credit_lt_4    <= 1'b0;
       cmd_data_credit_lt_2    <= 1'b0;
       cmd_data_credit_run_out <= 1'b0;
     end
   else
     begin
       cmd_credit_run_out      <= (cmd_credit_cnt      <= 4'd3);
       cmd_data_credit_lt_4    <= (cmd_data_credit_cnt <  6'd7);
       cmd_data_credit_lt_2    <= (cmd_data_credit_cnt <  6'd5);
       cmd_data_credit_run_out <= (cmd_data_credit_cnt <= 6'd3);
     end


//=================================================================================================================
// STATUS output for SNAP registers
//=================================================================================================================

 reg [31:0] cmd_idle_cnt;
 reg        cmd_idle;
 reg [31:0] cmd_idle_lim;

//---- DEBUG registers ----
 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     cmd_idle <= 1'b0;
   else if(afu_tlx_cmd_valid)
     cmd_idle <= 1'b0;
   else if(cmd_idle_cnt == cmd_idle_lim)
     cmd_idle <= 1'b1;

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     cmd_idle_cnt <= 32'd0;
   else if(afu_tlx_cmd_valid)
     cmd_idle_cnt <= 32'd0;
   else 
     cmd_idle_cnt <= cmd_idle_cnt + 32'd1;

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     cmd_idle_lim <= 32'd0;
   else
     cmd_idle_lim <= debug_tlx_cmd_idle_lim;

 always@(posedge clk_afu or negedge rst_n)
   if(~rst_n) 
     debug_tlx_cmd_idle <= 1'b0;
   else
     debug_tlx_cmd_idle <= cmd_idle;


//-----------------------------------------------------------------------------------------------------------------
//  Interrupt command convertion
//
//    * Handshake between TLX and AFU time domain
//
//          ---- TLX ---- : --- AFU ---
//                        tlx_in_cmd_req
//                        /
//          tlx_in_cmd_rec
//                        \
//                         tlx_in_cmd_ack
//-----------------------------------------------------------------------------------------------------------------


 always@(posedge clk_afu or negedge rst_n)
   if(~rst_n) 
     tlx_in_cmd_req <= 1'b0;
   else if(tlx_in_cmd_ack)
     tlx_in_cmd_req <= 1'b0;
   else if(tlx_in_cmd_valid)
     tlx_in_cmd_req <= 1'b1;

 always@(posedge clk_afu or negedge rst_n)
   if(~rst_n) 
     {tlx_in_cmd_ack, tlx_in_cmd_rec_pipe} <= 4'd0;
   else
     {tlx_in_cmd_ack, tlx_in_cmd_rec_pipe} <= {tlx_in_cmd_rec_pipe, tlx_in_cmd_rec};

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     {tlx_in_cmd_rec, tlx_in_cmd_req_pipe} <= 4'd0;
   else
     {tlx_in_cmd_rec, tlx_in_cmd_req_pipe} <= {tlx_in_cmd_req_pipe, tlx_in_cmd_req};

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     tlx_in_cmd_pending <= 1'b0;
   else if(~cmd_crankshaft_main && ~cmd_credit_run_out)
     tlx_in_cmd_pending <= 1'b0;
   else if(tlx_in_cmd_req_pipe[2] && ~tlx_in_cmd_rec)
     tlx_in_cmd_pending <= 1'b1;

 assign tlx_interrupt_valid_pre = ~cmd_crankshaft_main && ~cmd_credit_run_out && tlx_in_cmd_pending;

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     tlx_interrupt_valid <= 1'b0;
   else
     tlx_interrupt_valid <= tlx_interrupt_valid_pre;

 always@(posedge clk_afu or negedge rst_n)
   if(~rst_n) 
     begin
       tlx_in_cmd_opcode_sync <= 8'd0;
       tlx_in_cmd_afutag_sync <= 16'd0;
       tlx_in_cmd_obj_sync    <= 68'd0;
     end
   else if(tlx_in_cmd_valid)
     begin
       tlx_in_cmd_opcode_sync <= tlx_in_cmd_opcode;
       tlx_in_cmd_afutag_sync <= tlx_in_cmd_afutag;
       tlx_in_cmd_obj_sync    <= tlx_in_cmd_obj;
     end

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     begin
       tlx_interrupt_opcode <= 8'd0;
       tlx_interrupt_afutag <= 16'd0;
       tlx_interrupt_obj    <= 68'd0;
     end
   else 
     begin
       tlx_interrupt_opcode <= tlx_in_cmd_opcode_sync;
       tlx_interrupt_afutag <= tlx_in_cmd_afutag_sync;
       tlx_interrupt_obj    <= tlx_in_cmd_obj_sync;
     end


//---- FAULT ISOLATION REGISTER ----
 reg fir_cmd_credit_breach;
 reg fir_cmd_credit_data_breach;
 reg fir_fifo_a_cmdcnv_overflow; 
 reg fir_fifo_r_cmdcnv_overflow; 
 reg fir_fifo_w_datcnv_e_overflow; 
 reg fir_fifo_w_datcnv_o_overflow; 
 reg fir_fifo_w_cmdcnv_overflow; 

 always@(posedge clk_tlx or negedge rst_n)
   if(~rst_n) 
     begin
       fir_cmd_credit_breach <= 1'b0;
       fir_cmd_credit_data_breach <= 1'b0;
       fir_fifo_a_cmdcnv_overflow <= 1'b0; 
       fir_fifo_r_cmdcnv_overflow <= 1'b0; 
       fir_fifo_w_datcnv_e_overflow <= 1'b0; 
       fir_fifo_w_datcnv_o_overflow <= 1'b0; 
       fir_fifo_w_cmdcnv_overflow <= 1'b0; 
     end
   else
     begin
       if (afu_tlx_cmd_valid && (cmd_credit_cnt == 4'd0)) fir_cmd_credit_breach <= 1'b1;
       if (afu_tlx_cdata_valid && (cmd_data_credit_cnt == 4'd0)) fir_cmd_credit_data_breach <= 1'b1;
       if (fifo_a_cmdcnv_ovfl) fir_fifo_a_cmdcnv_overflow <= 1'b1; 
       if (fifo_r_cmdcnv_ovfl) fir_fifo_r_cmdcnv_overflow <= 1'b1; 
       if (fifo_w_datcnv_e_ovfl) fir_fifo_w_datcnv_e_overflow <= 1'b1; 
       if (fifo_w_datcnv_o_ovfl) fir_fifo_w_datcnv_o_overflow <= 1'b1; 
       if (fifo_w_cmdcnv_ovfl) fir_fifo_w_cmdcnv_overflow <= 1'b1; 
     end


 always@(posedge clk_afu or negedge rst_n)
   if(~rst_n) 
     begin
       fir_fifo_overflow  <= 5'd0;
       fir_tlx_command_credit <= 2'd0;
     end
   else
     begin
       fir_fifo_overflow  <= { fir_fifo_a_cmdcnv_overflow, fir_fifo_r_cmdcnv_overflow, fir_fifo_w_datcnv_e_overflow, fir_fifo_w_datcnv_o_overflow, fir_fifo_w_cmdcnv_overflow };
       fir_tlx_command_credit <= { fir_cmd_credit_breach, fir_cmd_credit_data_breach};
     end


//==== PSL ASSERTION ==============================================================================
 // psl PREMATURE_INTERRUPT : assert never (tlx_in_cmd_valid && tlx_in_cmd_req) @(posedge clk_afu) report "interrupt precedes the last acknowledgement! The interrupt command should never be sent until the last interrupt ackowledgement is confirmed.";
 
 // psl TLX_COMMAND_CHANNELS_CONFLICT : assert always onehot0({fifo_w_cmdcnv_dv, fifo_r_cmdcnv_dv, fifo_a_cmdcnv_dv, tlx_interrupt_valid}) @(posedge clk_tlx) report "TLX commands from write/read/assign_actag/interrupt have conflicts! Each time there's only one channel from write, read, assign_actag and interrupt being enabled.";
 
 // psl TLX_COMMAND_WRITE_DATA_DEFICIENT : assert always ((fifo_w_cmdcnv_rdrq && fifo_w_datcnv_e_rdrq) -> next(fifo_w_datcnv_o_rdrq)) @(posedge clk_tlx) report "lacking command data to TLX! The odd data FIFO should always be read following the reading of even data FIFO.";
//==== PSL ASSERTION ==============================================================================
 

//==== PSL COVERAGE ==============================================================================
 // psl SINGLE_COMMAND_A   : cover {(fifo_a_cmdcnv_dv)} @(posedge clk_tlx) ;
 // psl SINGLE_COMMAND_I   : cover {(tlx_interrupt_valid)} @(posedge clk_tlx) ;
 // psl DUPLEX_COMMAND_W_R : cover {fifo_w_cmdcnv_dv; fifo_r_cmdcnv_dv} @(posedge clk_tlx) ;
 // psl DUPLEX_COMMAND_R_W : cover {fifo_r_cmdcnv_dv; fifo_w_cmdcnv_dv} @(posedge clk_tlx) ;
 
 // psl CMD_CREDIT_RUNOUT : cover {(cmd_credit_run_out)} @(posedge clk_tlx);
 // psl CMD_CREDIT_LT_4 : cover {(cmd_data_credit_lt_4)} @(posedge clk_tlx);
 // psl CMD_CREDIT_LT_2 : cover {(cmd_data_credit_lt_2)} @(posedge clk_tlx);
 // psl CMD_DATA_CREDIT_RUNOUT : cover {(cmd_data_credit_run_out)} @(posedge clk_tlx);
 
 // psl DMA_CMD_JAM : cover {(tlx_wr_cmd_ready || tlx_rd_cmd_ready)} @(posedge clk_afu);
//==== PSL COVERAGE ==============================================================================
 

endmodule
