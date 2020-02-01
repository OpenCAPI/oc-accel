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


module context_surveil ( 
                             input                      clk                   ,
                             input                      rst_n                 ,

                             //---- configuration --------------------------------------
                             input      [011:0]         cfg_actag_base        ,
                             input      [019:0]         cfg_pasid_base        ,
                             input      [004:0]         cfg_pasid_length      ,

                             //---- AXI interface --------------------------------------
                             input      [008:0]         lcl_wr_ctx            ,
                             input      [008:0]         lcl_rd_ctx            ,
                             input                      lcl_wr_ctx_valid      ,
                             input                      lcl_rd_ctx_valid      ,
                             input      [008:0]         interrupt_ctx         ,
                             input                      interrupt             ,

                             //---- status ---------------------------------------------
                             input                      last_context_cleared  ,   // both write buffer and read buffer are empty
                             output reg                 context_update_ongoing,   // screen local burst request
                             
                             //---- TLX interface --------------------------------------
                             output                     tlx_cmd_valid         ,
                             output     [019:0]         tlx_cmd_pasid         ,
                             output     [011:0]         tlx_cmd_actag         ,
                             output     [007:0]         tlx_cmd_opcode
                             );


 localparam [7:0] AFU_TLX_CMD_OPCODE_ASSIGN_ACTAG  = 8'b0101_0000;  // Assign acTag

 reg [019:0] cfg_pasid_mask;
 reg [019:0] cmd_pasid_aligned;
 reg [011:0] cmd_actag;
 reg [008:0] current_context;
 wire[008:0] incoming_context;
 reg         power_up;
 wire        context_changed;


//----------------------------------------------------------------------------------------------
//
// CONTEXT update process
//                                           ___                                 ___
// lcl_wr/rd_ctx_valid     _________________/   \_______________________________|   \________
//                                          _____                                _____
// lcl_wr/rd_ctx           ----------------<__1__>------------------------------<__1__>------
//                         ______________________  __________________________________________
// current_context         ___old context (0)____><_____new context (1)______________________
//                                                ________________________
// context_update_ongoing  ______________________|                        \__________________
//                                                                     ______________________
// last_context_cleared    ___________________________________________|                   \__
//                                                                     ___
// tlx_cmd_valid           ___________________________________________|   \__________________
//                                                                     ______________________
// tlx_cmd_opcode          -------------------------------------------<_assign_actag_________
//
//-----------------------------------------------------------------------------------------------


//---- power up indicator after reset ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     power_up <= 1'b1;
   else if(lcl_wr_ctx_valid || lcl_rd_ctx_valid || interrupt)
     power_up <= 1'b0;

//---- incoming context differs from current context ----
 assign context_changed = (lcl_wr_ctx_valid || lcl_rd_ctx_valid || interrupt) &&      // When: 
                          (power_up ||                                   //   1. after powering up
                          (incoming_context != current_context));       //   2. AXI context different from the last one

//---- incoming context from AXI ----
 assign incoming_context = lcl_wr_ctx_valid? lcl_wr_ctx : (lcl_rd_ctx_valid? lcl_rd_ctx : interrupt_ctx);

//---- adapt current context to incoming context ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     current_context <= 9'd0;
   else if(lcl_wr_ctx_valid || lcl_rd_ctx_valid || interrupt)
     current_context <= incoming_context;

//---- start context updating process whenever context change is detected ----
// AXI transaction will be suspended until the last command from the old context has been completed and assign_actag is issued
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     context_update_ongoing <= 1'b0;
   else if(context_changed)
     context_update_ongoing <= 1'b1;
   else if(last_context_cleared)
     context_update_ongoing <= 1'b0;

//---- convert the enabled pasid length into a mask ----
 always@*
   begin
     case(cfg_pasid_length)
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

 assign current_pasid = current_context;

//---- the aligned pasid to be issued to TLX ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     cmd_pasid_aligned <= 20'd0;
   else if(lcl_wr_ctx_valid || lcl_rd_ctx_valid)
     cmd_pasid_aligned <= ((cfg_pasid_base & cfg_pasid_mask) | ({11'd0, incoming_context} & ~cfg_pasid_mask));

//---- the actag to be issued to TLX ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     cmd_actag <= 12'd0;
   else if(lcl_wr_ctx_valid || lcl_rd_ctx_valid)
     cmd_actag <= cfg_actag_base + {3'd0,incoming_context}; 


//---- outgoing info for TLX ----
 assign tlx_cmd_valid  = (context_update_ongoing && last_context_cleared);
 assign tlx_cmd_pasid  = cmd_pasid_aligned; 
 assign tlx_cmd_actag  = cmd_actag; 
 assign tlx_cmd_opcode = AFU_TLX_CMD_OPCODE_ASSIGN_ACTAG;



endmodule
