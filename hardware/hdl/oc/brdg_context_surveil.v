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

module brdg_context_surveil ( 
                             input                      clk                   ,
                             input                      rst_n                 ,

                             //---- configuration --------------------------------------
                             input      [011:0]         cfg_actag_base        ,
                             input      [019:0]         cfg_pasid_base        ,
                             input      [019:0]         cfg_pasid_mask        ,

                             //---- local interface ------------------------------------
                             input      [`CTXW-1:0]     lcl_wr_ctx            ,
                             input      [`CTXW-1:0]     lcl_rd_ctx            ,
                             input                      lcl_wr_ctx_valid      ,
                             input                      lcl_rd_ctx_valid      ,
                             input      [`CTXW-1:0]     interrupt_ctx         ,
                             input                      interrupt             ,
                             output                     context_suspend       ,

                             //---- TLX interface --------------------------------------
                             output                     tlx_cmd_valid         ,
                             output     [019:0]         tlx_cmd_pasid         ,
                             output     [011:0]         tlx_cmd_actag         ,
                             output     [007:0]         tlx_cmd_opcode
                             );



 localparam [7:0] AFU_TLX_CMD_OPCODE_ASSIGN_ACTAG  = 8'b0101_0000;  // Assign acTag

 parameter CTX_DEPTH = 2**`CTXW;

 reg [019:0] cmd_pasid_aligned;
 reg [011:0] cmd_actag;
 reg         cmd_valid;
 reg [`CTXW-1:0] ctx_value_selected;
 reg [`CTXW-1:0] ctx_value;
 reg         ctx_valid;

//-----------------------------------------------------------------------------------------------------------
// CONTEXT UPDATE ARBITRARY
//
//   avoid coincidence of write, read and interrupt context valid 
//                             --     --         ---    
//   write context s0 ======> |s1|=> |s2|=====> |   |
//                     ||      --     --        |   |   
//                     ||      ||=============> | A |
//                     ||=====================> | R |
//                             --     --        | B |    
//   read context s0  ======> |s1|=> |s2|=====> | I |                ---------------------------------------------
//                     ||      --     --        | T |=> ctx_value => |  ctx_fifo (512 entries for used contexts) |
//                     ||      ||=============> | R |       ||       ---------------------------------------------
//                     ||=====================> | A |       ||         ||      ||====>  ---
//                             --     --        | T |       ||         ||       ....   | C |
//   interrupt context s0 ==> |s1|=> |s2|=====> | O |       ||         ==============> | M |-> ctx_unique-> tlx_cmd_valid
//                     ||      --     --        | R |       ||                         | P |
//                     ||      ||=============> |   |       =========================>  ---
//                     ||=====================> |   |                             ||
//                                               ---                              ||    -------------
//                                                                                =====| CALCULATION |=> tlx_cmd_actag/pasid
//                                                                                      -------------
// 1. shift contexts from write, read and interrupt channels rightwards to S1 and S2;
// 2. priority of selection for ctx_value: S2 > S1 > S0;
// 3. priority in the same stage: write > read > interrupt;
// 4. require context input to suspend when context reaches S2.  
//-----------------------------------------------------------------------------------------------------------

 //---- valid signals for context shift-registers, with identical context screened out ----
 reg ctx_w_v1, ctx_w_v2;
 reg ctx_r_v1, ctx_r_v2;
 reg ctx_i_v1, ctx_i_v2;
 wire ctx_w_v0 = lcl_wr_ctx_valid;
 //wire ctx_r_v0 = (lcl_rd_ctx != lcl_wr_ctx)? lcl_rd_ctx_valid : 1'b0;
 //wire ctx_i_v0 = ((interrupt_ctx != lcl_rd_ctx) && (interrupt_ctx != lcl_wr_ctx))? interrupt : 1'b0;
 wire ctx_r_v0 = lcl_rd_ctx_valid;
 wire ctx_i_v0 = interrupt;

 //---- shift-registers for 3-channel contexts, push context rightward when there's valid context at S0 ----
 reg[`CTXW-1:0] ctx_w_s1, ctx_w_s2;
 reg[`CTXW-1:0] ctx_r_s1, ctx_r_s2;
 reg[`CTXW-1:0] ctx_i_s1, ctx_i_s2;
 wire[`CTXW-1:0] ctx_w_s0 = lcl_wr_ctx;
 wire[`CTXW-1:0] ctx_r_s0 = lcl_rd_ctx;
 wire[`CTXW-1:0] ctx_i_s0 = interrupt_ctx;

 always@(posedge clk)
   if(ctx_w_v0)
     begin
       ctx_w_s2 <= ctx_w_s1;
       ctx_w_s1 <= ctx_w_s0;
     end

 always@(posedge clk)
   if(ctx_r_v0)
     begin
       ctx_r_s2 <= ctx_r_s1;
       ctx_r_s1 <= ctx_r_s0;
     end

 always@(posedge clk)
   if(ctx_i_v0)
     begin
       ctx_i_s2 <= ctx_i_s1;
       ctx_i_s1 <= ctx_i_s0;
     end


 //---- prioritize contexts to be selected for downstream command converter ----
 wire[8:0] ctx_v_asm = {ctx_w_v2, ctx_r_v2, ctx_i_v2, ctx_w_v1, ctx_r_v1, ctx_i_v1, ctx_w_v0, ctx_r_v0, ctx_i_v0};
 reg [8:0] ctx_pos;

 always@*
   casez(ctx_v_asm)
     9'b1??_???_??? : ctx_pos = 9'b100_000_000;  //bit8 : w2
     9'b01?_???_??? : ctx_pos = 9'b010_000_000;  //bit7 : r2
     9'b001_???_??? : ctx_pos = 9'b001_000_000;  //bit6 : i2
     9'b000_1??_??? : ctx_pos = 9'b000_100_000;  //bit5 : w1
     9'b000_01?_??? : ctx_pos = 9'b000_010_000;  //bit4 : r1
     9'b000_001_??? : ctx_pos = 9'b000_001_000;  //bit3 : i1
     9'b0000_00_1?? : ctx_pos = 9'b000_000_100;  //bit2 : w0
     9'b0000_00_01? : ctx_pos = 9'b000_000_010;  //bit1 : r0
     9'b0000_00_001 : ctx_pos = 9'b000_000_001;  //bit0 : i0
     default        : ctx_pos = 9'b0;
   endcase

 //---- clear shift-register valid signals when corresponding context has been selected, otherwise keep shifting ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     begin
       ctx_w_v2 <= 1'b0;
       ctx_r_v2 <= 1'b0;
       ctx_i_v2 <= 1'b0;
       ctx_w_v1 <= 1'b0;
       ctx_r_v1 <= 1'b0;
       ctx_i_v1 <= 1'b0;
     end
   else 
     begin
       ctx_w_v2 <= (ctx_pos[8] || ctx_pos[5])? 1'b0 : ctx_w_v1;
       ctx_r_v2 <= (ctx_pos[7] || ctx_pos[4])? 1'b0 : ctx_r_v1;
       ctx_i_v2 <= (ctx_pos[6] || ctx_pos[3])? 1'b0 : ctx_i_v1;
       ctx_w_v1 <= (ctx_pos[5] || ctx_pos[2])? 1'b0 : ctx_w_v0;
       ctx_r_v1 <= (ctx_pos[4] || ctx_pos[1])? 1'b0 : ctx_r_v0;
       ctx_i_v1 <= (ctx_pos[3] || ctx_pos[0])? 1'b0 : ctx_i_v0;
     end

//---- select out the context for further evaluation and output ----
 always@*
   casez(ctx_v_asm)
     9'b1??_???_??? : ctx_value_selected = ctx_w_s2;
     9'b01?_???_??? : ctx_value_selected = ctx_r_s2;
     9'b001_???_??? : ctx_value_selected = ctx_i_s2;
     9'b000_1??_??? : ctx_value_selected = ctx_w_s1;
     9'b000_01?_??? : ctx_value_selected = ctx_r_s1;
     9'b000_001_??? : ctx_value_selected = ctx_i_s1;
     9'b0000_00_1?? : ctx_value_selected = ctx_w_s0;
     9'b0000_00_01? : ctx_value_selected = ctx_r_s0;
     9'b0000_00_001 : ctx_value_selected = ctx_i_s0;
     default        : ctx_value_selected = {`CTXW{1'b0}};
   endcase

 always@(posedge clk or negedge rst_n)
 begin
     if(~rst_n)
         ctx_valid <= 1'b0;
     else
         ctx_valid <= |ctx_v_asm;
 end

 always@(posedge clk or negedge rst_n)
 begin
     if(~rst_n)
         ctx_value <= {`CTXW{1'b0}};
     else if(|ctx_v_asm)
         ctx_value <= ctx_value_selected;
 end


//-----------------------------------------------------------------------------------------------------------
// CONTEXT FIFO 
//
//   * stores context values that's been sent to TLX with assign_actag command
//   * updated when new context comes
//   * cleared when updated
//-----------------------------------------------------------------------------------------------------------

 wire[CTX_DEPTH-1 : 0] ctx_no_match;
 wire                  ctx_unique;
 reg [`CTXW-1 : 0] ctx_fifo [CTX_DEPTH-1:0];
 reg [0:0] ctx_sent[CTX_DEPTH-1 : 0];

 // compare new context value with all FIFO contents at once
 genvar i;
 generate 
   for(i = 0; i < CTX_DEPTH; i = i+1)
     begin : sent_ctx_match
       assign ctx_no_match[i] = ctx_sent[i]? (ctx_valid && (ctx_fifo[i] != ctx_value)) : ctx_valid;
     end
 endgenerate 

 assign ctx_unique = &ctx_no_match;

// accepts new context only when it's not equal to any valid content in the FIFO
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     begin
       ctx_fifo[0] <= 'd0;
       ctx_sent[0] <= 1'b0;
     end
   else if(ctx_unique)
     begin
       ctx_fifo[0] <= ctx_value;
       ctx_sent[0] <= 1'b1;
     end

 genvar j;
 generate 
   for(j = 1; j < CTX_DEPTH; j = j+1)
     begin : sent_ctx_FIFO
       always@(posedge clk or negedge rst_n)
         if(~rst_n) 
           begin
             ctx_fifo[j] <= 'd0;
             ctx_sent[j] <= 1'b0;
           end
         else if(ctx_unique)
           begin
             ctx_fifo[j] <= ctx_fifo[j-1];
             ctx_sent[j] <= ctx_sent[j-1];
           end
     end
 endgenerate 


//---- require context suspension whenever any context is shifted to S2 ----
 assign context_suspend = |{ctx_w_v2, ctx_r_v2, ctx_i_v2};



//-----------------------------------------------------------------------------------------------------------
// ASSIGN ACTAG COMMAND
//-----------------------------------------------------------------------------------------------------------

//---- the aligned pasid to be issued to TLX ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     cmd_pasid_aligned <= 20'd0;
   else if(ctx_valid)
     cmd_pasid_aligned <= ((cfg_pasid_base & cfg_pasid_mask) | ({{(20-`CTXW){1'd0}}, ctx_value} & ~cfg_pasid_mask));

//---- the actag to be issued to TLX ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     cmd_actag <= 12'd0;
   else if(ctx_valid)
     cmd_actag <= cfg_actag_base + {{(12-`CTXW){1'd0}},ctx_value}; 

//---- assign_actag command output ready ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     cmd_valid <= 1'b0;
   else
     cmd_valid <= ctx_unique;


//---- outgoing info for TLX ----
 assign tlx_cmd_valid  = cmd_valid;
 assign tlx_cmd_pasid  = cmd_pasid_aligned; 
 assign tlx_cmd_actag  = cmd_actag; 
 assign tlx_cmd_opcode = AFU_TLX_CMD_OPCODE_ASSIGN_ACTAG;



 // psl default clock = (posedge clk);

//==== PSL ASSERTION ==============================================================================
 // psl NEW_CONTEXT_CONGESTED : assert always onehot0({ctx_w_v2, ctx_r_v2, ctx_i_v2}) report "new contexts from write, read and interrupt channels are too many to be handled!";
//==== PSL ASSERTION ==============================================================================

//==== PSL COVERAGE ==============================================================================
 // psl WR_RD_CONTEXT_CONCUR : cover {(ctx_w_v0 && ctx_r_v0)};
 // psl WR_IN_CONTEXT_CONCUR : cover {(ctx_w_v0 && ctx_i_v0)};
 // psl RD_IN_CONTEXT_CONCUR : cover {(ctx_r_v0 && ctx_i_v0)};
 // psl WR_RD_IN_CONTEXT_CONCUR : cover {(ctx_w_v0 && ctx_r_v0 && ctx_i_v0)};
 
 // psl ALL_CONTEXT_COMMITTED : cover {ctx_sent[CTX_DEPTH-1]};
//==== PSL COVERAGE ==============================================================================



endmodule
