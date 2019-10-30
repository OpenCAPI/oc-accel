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

module axi_lite_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
                      input             clk                   ,
                      input             rst_n                 ,

                      //---- AXI Lite bus----
                        // AXI write address channel
                      output reg        s_axi_awready         ,   
                      input      [ADDR_WIDTH - 1:0] s_axi_awaddr          ,
                      input      [02:0] s_axi_awprot          ,
                      input             s_axi_awvalid         ,
                        // axi write data channel             
                      output reg        s_axi_wready          ,
                      input      [DATA_WIDTH - 1:0] s_axi_wdata           ,
                      input      [(DATA_WIDTH/8) - 1:0] s_axi_wstrb           ,
                      input             s_axi_wvalid          ,
                        // AXI response channel
                      output     [01:0] s_axi_bresp           ,
                      output reg        s_axi_bvalid          ,
                      input             s_axi_bready          ,
                        // AXI read address channel
                      output reg        s_axi_arready         ,
                      input             s_axi_arvalid         ,
                      input      [ADDR_WIDTH - 1:0] s_axi_araddr          ,
                      input      [02:0] s_axi_arprot          ,
                        // AXI read data channel
                      output reg [DATA_WIDTH - 1:0] s_axi_rdata           ,
                      output     [01:0] s_axi_rresp           ,
                      input             s_axi_rready          ,
                      output reg        s_axi_rvalid          ,

                      //---- local control ----
                      output            memcpy_enable ,
                      output     [63:0] source_address,
                      output     [63:0] target_address,
                      output     [63:0] source_size   ,
                      output     [63:0] target_size   ,
                      output     [31:0] read_number   ,
                      output     [31:0] read_rand_patt, 
                      output     [31:0] write_number  ,
                      output     [31:0] write_rand_patt,
                      output     [31:0] seed          ,                       
                      output     [31:0] interrupt_patt,                       

                      //---- local status ----
                      input             memcpy_done   ,

                      //---- snap status ----
                      input             i_app_ready           ,
                      input      [31:0] i_action_type         ,
                      input      [31:0] i_action_version      ,
                      output     [31:0] o_snap_context
                      );
            

//---- declarations ----
 wire[31:0] write_data_snap_status;
 wire[31:0] write_data_snap_int_enable;
 wire[31:0] write_data_snap_context;
 wire[63:0] write_data_control;
 wire[63:0] write_data_source_address;
 wire[63:0] write_data_target_address; 
 wire[63:0] write_data_source_size;
 wire[63:0] write_data_target_size;
 wire[31:0] write_data_read_config;
 wire[31:0] write_data_write_config;
 wire[31:0] write_data_seed;
 wire[31:0] write_data_interrupt;   
 reg [31:0] write_address;
 wire[31:0] wr_mask;
 wire[31:0] REG_snap_status_rd;
 wire       idle;
 reg        idle_q;
 reg        app_done_q;
 reg        app_start_q;
 reg        reg_snap_status_bit0;
 
 
 ///////////////////////////////////////////////////
 //***********************************************//
 //>                REGISTERS                    <//
 //***********************************************//
 //                                               //
 /**/   reg [31:0] REG_snap_status           ;  /**/
 /**/   reg [31:0] REG_snap_int_enable       ;  /**/
 /**/   reg [31:0] REG_snap_context          ;  /**/
 /**/   reg [63:0] REG_control               ;  /**/
 /**/   reg [63:0] REG_source_address        ;  /**/
 /**/   reg [63:0] REG_target_address        ;  /**/
 /**/   reg [63:0] REG_source_size           ;  /**/
 /**/   reg [63:0] REG_target_size           ;  /**/
 /**/   reg [63:0] REG_read_config           ;  /**/
 /**/   reg [63:0] REG_write_config          ;  /**/
 /**/   reg [63:0] REG_seed                  ;  /**/
 /**/   reg [63:0] REG_interrupt_patt        ;  /**/ 
 /**/   reg [63:0] REG_status                ;  /**/
 //                                               //
 //-----------------------------------------------//
 //                                               //
 ///////////////////////////////////////////////////


//---- parameters ----
 // Register addresses arrangement
 parameter ADDR_SNAP_STATUS                      = 32'h00,
           ADDR_SNAP_INT_ENABLE                  = 32'h04,
           ADDR_SNAP_ACTION_TYPE                 = 32'h10,
           ADDR_SNAP_ACTION_VERSION              = 32'h14,
           ADDR_SNAP_CONTEXT                     = 32'h20,
           ADDR_STATUS_L                         = 32'h30,
           ADDR_STATUS_H                         = 32'h34,
           ADDR_CONTROL_L                        = 32'h38,
           ADDR_CONTROL_H                        = 32'h3C,              
           ADDR_SOURCE_ADDRESS_L         = 32'h40,
           ADDR_SOURCE_ADDRESS_H         = 32'h44,
           ADDR_SOURCE_SIZE_L            = 32'h48,
           ADDR_SOURCE_SIZE_H            = 32'h4C,
           ADDR_TARGET_ADDRESS_L         = 32'h50,
           ADDR_TARGET_ADDRESS_H         = 32'h54,
           ADDR_TARGET_SIZE_L            = 32'h58,
           ADDR_TARGET_SIZE_H            = 32'h5C,
           ADDR_READ_NUMBER              = 32'h60,
           ADDR_READ_RAND_PATT           = 32'h64,
           ADDR_WRITE_NUMBER             = 32'h68,
           ADDR_WRITE_RAND_PATT          = 32'h6C,
           ADDR_SEED                     = 32'h70,
           ADDR_INTERRUPT_PATT           = 32'h80;

//---- local controlling signals assignments ----
 assign memcpy_enable  = REG_control[0];
 assign source_address = REG_source_address;
 assign target_address = REG_target_address;
 assign source_size    = REG_source_size;
 assign target_size    = REG_target_size;
 assign read_number    = REG_read_config[31:0];
 assign read_rand_patt = REG_read_config[63:32];
 assign write_number   = REG_write_config[31:0];
 assign write_rand_patt= REG_write_config[63:32];
 assign seed           = REG_seed;
 assign interrupt_patt = REG_interrupt_patt;  
 assign o_snap_context = REG_snap_context;

//---- read-only registers assigned by local signals ----
 always@(posedge clk)
   begin
     REG_status <= {
                    63'd0,
                    memcpy_done
                   };
   end



/***********************************************************************
*                          writing registers                           *
***********************************************************************/

//---- write address capture ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     write_address <= 32'd0;
   else if(s_axi_awvalid & s_axi_awready)
     write_address <= s_axi_awaddr;

//---- write address ready ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     s_axi_awready <= 1'b0;
   else if(s_axi_awvalid)
     s_axi_awready <= 1'b1;
   else if(s_axi_wvalid & s_axi_wready)
     s_axi_awready <= 1'b0;

//---- write data ready ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     s_axi_wready <= 1'b0;
   else if(s_axi_awvalid & s_axi_awready)
     s_axi_wready <= 1'b1;
   else if(s_axi_wvalid)
     s_axi_wready <= 1'b0;

//---- handle write data strobe ----
 assign wr_mask = {{8{s_axi_wstrb[3]}},{8{s_axi_wstrb[2]}},{8{s_axi_wstrb[1]}},{8{s_axi_wstrb[0]}}};

 assign write_data_snap_status            = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_snap_status)}; 
 assign write_data_snap_int_enable        = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_snap_int_enable)}; 
 assign write_data_snap_context           = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_snap_context)}; 
 assign write_data_control                = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_control)}; 
 assign write_data_source_address = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_source_address)};
 assign write_data_target_address = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_target_address)};     
 assign write_data_source_size    = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_source_size)};     
 assign write_data_target_size    = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_target_size)};     
 assign write_data_read_config    = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_read_config)}; 
 assign write_data_write_config   = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_write_config)}; 
 assign write_data_seed           = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_seed)}; 
 assign write_data_interrupt      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_interrupt_patt)}; 

//---- write registers ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       REG_snap_status            <= 32'd0;
       REG_snap_int_enable        <= 32'd0;
       REG_snap_context           <= 32'd0;
       REG_control                <= 64'd0; 
       REG_source_address <= 64'd0;
       REG_target_address <= 64'd0;  
       REG_source_size    <= 64'd0;
       REG_target_size    <= 64'd0; 
       REG_read_config    <= 64'd0; 
       REG_write_config   <= 64'd0;
       REG_seed           <= 32'd0;
       REG_interrupt_patt <= 32'd0;       
     end
   else if(s_axi_wvalid & s_axi_wready)
     case(write_address)
       ADDR_SNAP_STATUS              : REG_snap_status <= 
                                           write_data_snap_status;
       ADDR_SNAP_INT_ENABLE          : REG_snap_int_enable <= 
                                           write_data_snap_int_enable;
       ADDR_SNAP_CONTEXT             : REG_snap_context <= 
                                           write_data_snap_context;
       ADDR_CONTROL_H                : REG_control <= 
                                           {write_data_control,REG_control[31:00]};
       ADDR_CONTROL_L                : REG_control <= 
                                           {REG_control[63:32],write_data_control};
       ADDR_SOURCE_ADDRESS_H : REG_source_address <= 
                                           {write_data_source_address,REG_source_address[31:00]};
       ADDR_SOURCE_ADDRESS_L : REG_source_address <= 
                                           {REG_source_address[63:32],write_data_source_address};
       ADDR_TARGET_ADDRESS_H : REG_target_address <= 
                                           {write_data_target_address,REG_target_address[31:00]};
       ADDR_TARGET_ADDRESS_L : REG_target_address <= 
                                           {REG_target_address[63:32],write_data_target_address};
       ADDR_SOURCE_SIZE_H    : REG_source_size <= 
                                           {write_data_source_size,REG_source_size[31:00]};
       ADDR_SOURCE_SIZE_L    : REG_source_size <= 
                                           {REG_source_size[63:32],write_data_source_size};
       ADDR_TARGET_SIZE_H    : REG_target_size <= 
                                           {write_data_target_size,REG_target_size[31:00]};
       ADDR_TARGET_SIZE_L    : REG_target_size <= 
                                           {REG_target_size[63:32],write_data_target_size};
       ADDR_READ_RAND_PATT   : REG_read_config <= 
                                           {write_data_read_config,REG_read_config[31:00]};
       ADDR_READ_NUMBER      : REG_read_config <= 
                                           {REG_read_config[63:32],write_data_read_config};
       ADDR_WRITE_RAND_PATT  : REG_write_config <= 
                                           {write_data_write_config,REG_write_config[31:00]};
       ADDR_WRITE_NUMBER     : REG_write_config <= 
                                           {REG_write_config[63:32],write_data_write_config};
       ADDR_SEED             : REG_seed <= 
                                           write_data_seed;
       ADDR_INTERRUPT_PATT   : REG_interrupt_patt <= 
                                           write_data_interrupt;
       default :;
     endcase



// All bit[2:0] from control (0x38) is 0 means idle
assign idle = ~(|(REG_control[2:0]));

// Prepare status for SNAP status register
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin 
        idle_q <= 0;
        app_start_q <= 0;
        reg_snap_status_bit0 <= 0;
        app_done_q <= 0;
    end else begin
        idle_q <= idle;
        reg_snap_status_bit0 <= REG_snap_status[0];

	// Action Status bit 0 means action done
        if ((REG_status[0] == 1)) begin
            app_done_q <= 1;
        end else begin
            app_done_q <= 0;
        end

        // SNAP status bit 0 changed from 0 to 1 means app started
        if ((reg_snap_status_bit0 == 0) && (REG_snap_status[0] == 1)) begin
            app_start_q <= 1;
        end

        // Idle changed from 0 to 1 means app stopped work
        if ((idle_q == 1) && (idle == 0)) begin
            app_start_q <= 0;
        end
    end
end

/***********************************************************************
*                       reading registers                              *
***********************************************************************/

assign REG_snap_status_rd = {REG_snap_status[31:4], i_app_ready, idle_q, app_done_q, app_start_q};

//---- read registers ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     s_axi_rdata <= 32'd0;
   else if(s_axi_arvalid & s_axi_arready)
     case(s_axi_araddr)
       ADDR_SNAP_STATUS         : s_axi_rdata <= REG_snap_status_rd[31:0]; 
       ADDR_SNAP_INT_ENABLE     : s_axi_rdata <= REG_snap_int_enable[31:0]; 
       ADDR_SNAP_ACTION_TYPE    : s_axi_rdata <= i_action_type; 
       ADDR_SNAP_ACTION_VERSION : s_axi_rdata <= i_action_version; 
       ADDR_SNAP_CONTEXT        : s_axi_rdata <= REG_snap_context[31:0]; 
       ADDR_STATUS_L            : s_axi_rdata <= REG_status[31:0]; 
       ADDR_STATUS_H            : s_axi_rdata <= REG_status[63:32];
       ADDR_CONTROL_H           : s_axi_rdata <= REG_control[63:0];
       ADDR_CONTROL_L           : s_axi_rdata <= REG_control[31:0];
       ADDR_SOURCE_ADDRESS_H    : s_axi_rdata <= REG_source_address[63:32];
       ADDR_SOURCE_ADDRESS_L    : s_axi_rdata <= REG_source_address[31:0];
       ADDR_TARGET_ADDRESS_H    : s_axi_rdata <= REG_target_address[63:32];
       ADDR_TARGET_ADDRESS_L    : s_axi_rdata <= REG_target_address[31:0];
       ADDR_SOURCE_SIZE_H       : s_axi_rdata <= REG_source_size[63:32];
       ADDR_SOURCE_SIZE_L       : s_axi_rdata <= REG_source_size[31:0];
       ADDR_TARGET_SIZE_H       : s_axi_rdata <= REG_target_size[63:32];
       ADDR_TARGET_SIZE_L       : s_axi_rdata <= REG_target_size[31:0];
       ADDR_READ_RAND_PATT      : s_axi_rdata <= REG_read_config[63:32];
       ADDR_READ_NUMBER         : s_axi_rdata <= REG_read_config[31:0];
       ADDR_WRITE_RAND_PATT     : s_axi_rdata <= REG_write_config[63:32];
       ADDR_WRITE_NUMBER        : s_axi_rdata <= REG_write_config[31:0];
       ADDR_SEED                : s_axi_rdata <= REG_seed[31:0];
       ADDR_INTERRUPT_PATT      : s_axi_rdata <= REG_interrupt_patt[31:0];
       default                  : s_axi_rdata <= 32'h5a5aa5a5;
     endcase

//---- address ready: deasserts once arvalid is seen; reasserts when current read is done ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     s_axi_arready <= 1'b1;
   else if(s_axi_arvalid)
     s_axi_arready <= 1'b0;
   else if(s_axi_rvalid & s_axi_rready)
     s_axi_arready <= 1'b1;

//---- data ready: deasserts once rvalid is seen; reasserts when new address has come ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     s_axi_rvalid <= 1'b0;
   else if (s_axi_arvalid & s_axi_arready)
     s_axi_rvalid <= 1'b1;
   else if (s_axi_rready)
     s_axi_rvalid <= 1'b0;




/***********************************************************************
*                        status reporting                              *
***********************************************************************/

//---- axi write response ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     s_axi_bvalid <= 1'b0;
   else if(s_axi_wvalid & s_axi_wready)
     s_axi_bvalid <= 1'b1;
   else if(s_axi_bready)
     s_axi_bvalid <= 1'b0;

 assign s_axi_bresp = 2'd0;

//---- axi read response ----
 assign s_axi_rresp = 2'd0;


endmodule

