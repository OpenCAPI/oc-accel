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
                      input                            clk              ,
                      input                            resetn            ,

                      //---- AXI Lite bus----
                        // AXI write address channel
                      output reg                       s_axi_awready    ,
                      input      [ADDR_WIDTH - 1:0]    s_axi_awaddr     ,
                      input                            s_axi_awvalid    ,
                        // axi write data channel
                      output reg                       s_axi_wready     ,
                      input      [DATA_WIDTH - 1:0]    s_axi_wdata      ,
                      input      [(DATA_WIDTH/8) - 1:0]s_axi_wstrb      ,
                      input                            s_axi_wvalid     ,
                        // AXI response channel
                      output     [01:0]                s_axi_bresp      ,
                      output reg                       s_axi_bvalid     ,
                      input                            s_axi_bready     ,
                        // AXI read address channel
                      output reg                       s_axi_arready    ,
                      input                            s_axi_arvalid    ,
                      input      [ADDR_WIDTH - 1:0]    s_axi_araddr     ,
                        // AXI read data channel
                      output reg [DATA_WIDTH - 1:0]    s_axi_rdata      ,
                      output     [01:0]                s_axi_rresp      ,
                      input                            s_axi_rready     ,
                      output reg                       s_axi_rvalid     ,

                      //---- local control ----
                      output wire                      engine_start_pulse, //Send to AXI data read or write senders
                      output wire                      wrap_mode        , // 1 for wrap, 0 for incr
                      output wire [03:0]               wrap_len         ,
                      output     [63:0]                source_address   ,
                      output     [63:0]                target_address   ,
                      output     [31:0]                rd_init_data     ,
                      output     [31:0]                wr_init_data     ,
                      output     [31:0]                rd_pattern       ,
                      output     [31:0]                rd_number        ,
                      output     [31:0]                wr_pattern       ,
                      output     [31:0]                wr_number        ,

                      //---- local status ----
                      input                            rd_done_pulse    ,
                      input                            wr_done_pulse    ,
                      input      [01:0]                rd_error         , //bit 0 means response error, bit 1 means data error
                      input      [63:0]                rd_error_info    ,
                      input                            wr_error         , //write response error
                      input                            tt_arvalid       , //arvalid & arready
                      input                            tt_rlast         , //rlast & rvalid & rready
                      input                            tt_awvalid       , //awvalid & awready
                      input                            tt_bvalid        , //bvalid & bready

                      input      [4:0]                 tt_arid       ,
                      input      [4:0]                 tt_awid       ,
                      input      [4:0]                 tt_rid       ,
                      input      [4:0]                 tt_bid       

                      );
            

//---- declarations ----
 wire[31:0] REG_ocaccel_control_rd;
 wire[31:0] REG_user_status;  /*RO*/

 wire[31:0] regw_ocaccel_control;
 wire[31:0] regw_ocaccel_int_enable;

 wire[31:0] regw_control;
 wire[31:0] regw_mode;
 wire[31:0] regw_init_rdata;
 wire[31:0] regw_init_wdata;
 wire[31:0] regw_rd_pattern;
 wire[31:0] regw_rd_number;
 wire[31:0] regw_wr_pattern;
 wire[31:0] regw_wr_number;
 wire[63:0] regw_source_address;
 wire[63:0] regw_target_address;
 wire [31:0] regw_soft_reset;

 reg [31:0] write_address;
wire [31:0] read_address;
 wire[31:0] wr_mask;
 reg [31:0] current_cycle_L;
 reg [15:0] current_cycle_H;

 wire       soft_reset;
 

 ///////////////////////////////////////////////////
 //***********************************************//
 //>                REGISTERS                    <//
 //***********************************************//
 //                                               //
 /*-----------------------------------------------*/
 /**/   reg [63:0] REG_error_info            ;  /*RO*/

 /**/   reg [31:0] REG_user_mode             ;  /*RW*/
 /**/   reg [31:0] REG_init_rdata            ;  /*RW*/
 /**/   reg [31:0] REG_init_wdata            ;  /*RW*/
 /**/   wire [31:0] cyc_tt_rd_cmd            ;  /*RO, from RAM data_out*/
 /**/   wire [31:0] cyc_tt_rd_rsp            ;  /*RO, from RAM data_out*/
 /**/   wire [31:0] cyc_tt_wr_cmd            ;  /*RO, from RAM data_out*/
 /**/   wire [31:0] cyc_tt_wr_rsp            ;  /*RO, from RAM data_out*/
 /**/   wire [4:0] dout_arid                 ;  /*RO, from RAM data_out*/
 /**/   wire [4:0] dout_awid                 ;  /*RO, from RAM data_out*/
 /**/   wire [4:0] dout_rid                  ;  /*RO, from RAM data_out*/
 /**/   wire [4:0] dout_bid                  ;  /*RO, from RAM data_out*/

 /**/   reg [31:0] REG_rd_pattern            ;  /*RW*/
 /**/   reg [31:0] REG_rd_number             ;  /*RW*/
 /**/   reg [31:0] REG_wr_pattern            ;  /*RW*/
 /**/   reg [31:0] REG_wr_number             ;  /*RW*/
 /**/   reg [63:0] REG_source_address        ;  /*RW*/
 /**/   reg [63:0] REG_target_address        ;  /*RW*/
 /**/   reg [31:0] REG_soft_reset            ;  /*RW*/
 //                                               //
 //-----------------------------------------------//
 //                                               //
 ///////////////////////////////////////////////////


//---- parameters ----
 // Register addresses arrangement
localparam ADDR_OCACCEL_CONTROL        = 32'h00,
           // User defined below
           ADDR_USER_STATUS         = 32'h30,
           ADDR_USER_MODE           = 32'h38,
           ADDR_INIT_RDATA          = 32'h3C, //Non-zero init Read Data 
           ADDR_INIT_WDATA          = 32'h40, //Non-zero init Write Data

           //Following four Time Trace RAMs, when read the MMIO port, the RAM
           //address is increased by 1 automatically
           ADDR_TT_RD_CMD           = 32'h44, //Time Trace RAM, when ARVALID is sent
           ADDR_TT_RD_RSP           = 32'h48, //Time Trace RAM, when RLAST is received
           ADDR_TT_WR_CMD           = 32'h4C, //Time Trace RAM, when AWVALID is sent
           ADDR_TT_WR_RSP           = 32'h50, //Time Trace RAM, when BVALID is received

           ADDR_TT_ARID             = 32'h54, //ID Trace RAM, 
           ADDR_TT_AWID             = 32'h58, //ID Trace RAM, 
           ADDR_TT_RID              = 32'h5C, //ID Trace RAM, 
           ADDR_TT_BID              = 32'h60, //ID Trace RAM, 

           ADDR_RD_PATTERN          = 32'h64, //AXI Read pattern
           ADDR_RD_NUMBER           = 32'h68, //how many AXI Read transactions
           ADDR_WR_PATTERN          = 32'h6C, //AXI Write Pattern
           ADDR_WR_NUMBER           = 32'h70, //how many AXI Write trasactions

           ADDR_SOURCE_ADDRESS_L    = 32'h74,
           ADDR_SOURCE_ADDRESS_H    = 32'h78,
           ADDR_TARGET_ADDRESS_L    = 32'h7C,
           ADDR_TARGET_ADDRESS_H    = 32'h80,

           ADDR_ERROR_INFO_L        = 32'h84,
           ADDR_ERROR_INFO_H        = 32'h88,
           ADDR_SOFT_RESET          = 32'h8C;

localparam AP_READY = 3,
           AP_IDLE  = 2,
           AP_DONE  = 1,
           AP_START = 0;

localparam CLEAR_RAM_BIT = 31;


//---- local controlling signals assignments ----
 assign rd_init_data   = REG_init_rdata;
 assign wr_init_data   = REG_init_wdata;
 assign rd_pattern     = REG_rd_pattern;
 assign rd_number      = REG_rd_number;
 assign wr_pattern     = REG_wr_pattern;
 assign wr_number      = REG_wr_number;
 assign source_address = REG_source_address;
 assign target_address = REG_target_address;
 assign soft_reset     = REG_soft_reset[0];
 assign wrap_mode      = REG_user_mode[0];
 assign wrap_len       = REG_user_mode[11:8];

/***********************************************************************
*                          writing registers                           *
***********************************************************************/

//---- write address capture ----
 always@(posedge clk)
   if(~resetn)
     write_address <= 32'd0;
   else if(s_axi_awvalid & s_axi_awready)
     write_address <= s_axi_awaddr;

//---- write address ready ----
 always@(posedge clk)
   if(~resetn)
     s_axi_awready <= 1'b0;
   else if(s_axi_awvalid)
     s_axi_awready <= 1'b1;
   else if(s_axi_wvalid & s_axi_wready)
     s_axi_awready <= 1'b0;

//---- write data ready ----
 always@(posedge clk)
   if(~resetn)
     s_axi_wready <= 1'b0;
   else if(s_axi_awvalid & s_axi_awready)
     s_axi_wready <= 1'b1;
   else if(s_axi_wvalid)
     s_axi_wready <= 1'b0;

//---- handle write data strobe ----
 assign wr_mask = {{8{s_axi_wstrb[3]}},{8{s_axi_wstrb[2]}},{8{s_axi_wstrb[1]}},{8{s_axi_wstrb[0]}}};

 assign regw_mode            = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_user_mode)};
 assign regw_init_rdata      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_init_rdata)};
 assign regw_init_wdata      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_init_wdata)};
 assign regw_rd_pattern      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_rd_pattern)};
 assign regw_rd_number       = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_rd_number)};
 assign regw_wr_pattern      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_wr_pattern)};
 assign regw_wr_number       = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_wr_number)};
 assign regw_source_address  = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_source_address)};
 assign regw_target_address  = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_target_address)};
 assign regw_soft_reset      = {(s_axi_wdata&wr_mask)|(~wr_mask&REG_soft_reset)};

//---- write registers ----
 always@(posedge clk)
   if(~resetn || soft_reset)
    begin
       REG_user_mode       <= 32'd0;
       REG_init_rdata      <= 32'd0;
       REG_init_wdata      <= 32'd0;
       REG_rd_pattern      <= 32'd0;
       REG_rd_number       <= 32'd0;
       REG_wr_pattern      <= 32'd0;
       REG_wr_number       <= 32'd0;
       REG_source_address  <= 64'd0;
       REG_target_address  <= 64'd0;
       REG_soft_reset      <= 32'd0;
    end
   else if(s_axi_wvalid & s_axi_wready)
     case(write_address)

       ADDR_USER_MODE       : REG_user_mode       <= regw_mode;
       ADDR_INIT_RDATA      : REG_init_rdata      <= regw_init_rdata;
       ADDR_INIT_WDATA      : REG_init_wdata      <= regw_init_wdata;
       ADDR_RD_PATTERN      : REG_rd_pattern      <= regw_rd_pattern;
       ADDR_RD_NUMBER       : REG_rd_number       <= regw_rd_number;
       ADDR_WR_PATTERN      : REG_wr_pattern      <= regw_wr_pattern;
       ADDR_WR_NUMBER       : REG_wr_number       <= regw_wr_number;


       ADDR_SOURCE_ADDRESS_H : REG_source_address  <= {regw_source_address,REG_source_address[31:00]};
       ADDR_SOURCE_ADDRESS_L : REG_source_address  <= {REG_source_address[63:32],regw_source_address};

       ADDR_TARGET_ADDRESS_H : REG_target_address  <= {regw_target_address,REG_target_address[31:00]};
       ADDR_TARGET_ADDRESS_L : REG_target_address  <= {REG_target_address[63:32],regw_target_address};
       ADDR_SOFT_RESET       : REG_soft_reset      <= regw_soft_reset;


       default :;
     endcase




/***********************************************************************
*                          Control Flow                                *
***********************************************************************/
wire ocaccel_done_d;
reg  ocaccel_done_q;
wire ocaccel_done_pulse;

wire ocaccel_start_d;
reg  ocaccel_start_q;
wire ocaccel_start_pulse;

// Register 0 is a special register that works with job manager
//Address: 0x000
//  31..8  RO: Reserved
//      7  RW: auto restart (not in use)
//   6..4  RO: Reserved
//      3  RO: Ready     (not in use)
//      2  RO: Idle      (in use)
//      1  RC: Done      (in use)
//      0  RW: Start     (in use)

reg          reg_ap_idle;
reg          reg_ap_done = 1'b0;
reg          reg_ap_start = 1'b0;

always @ (posedge clk) begin
    if (~resetn || soft_reset)
        reg_ap_start     <= 1'b0;
    else if (s_axi_wvalid && s_axi_wready && write_address == ADDR_OCACCEL_CONTROL  && s_axi_wstrb[0])
        reg_ap_start    <= s_axi_wdata[0];
    else if (ocaccel_done_pulse)
        reg_ap_start <= 0;
end

always@(posedge clk)
    if (~resetn || soft_reset)
        reg_ap_idle <= 1;
    else if (ocaccel_start_pulse)
        reg_ap_idle <= 0;
    else if (ocaccel_done_pulse)
        reg_ap_idle <= 1;

always @ (posedge clk) begin
    if (~resetn || soft_reset)
        reg_ap_done <= 1'b0;
    else if (ocaccel_done_pulse)
        reg_ap_done <= 1'b1;
    else if (s_axi_arvalid && s_axi_arready && read_address == ADDR_OCACCEL_CONTROL)
        reg_ap_done <= 1'b0; //Clear on Read
end


assign REG_ocaccel_control_rd = {24'h0, 1'b0, 3'h0, 1'b1, reg_ap_idle, reg_ap_done, reg_ap_start };


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

assign ocaccel_start_d = reg_ap_start;

always @(posedge clk) begin
    if ((~resetn) || soft_reset)
        ocaccel_start_q <= 0;
    else
        ocaccel_start_q <= ocaccel_start_d;
end
assign ocaccel_start_pulse = ocaccel_start_d & ~ocaccel_start_q;

//-----------------------------------------------------------------------------
// Start Clear_RAM job 
//-----------------------------------------------------------------------------
wire clear_ram_start_pulse = ocaccel_start_pulse & (REG_user_mode[CLEAR_RAM_BIT] == 1'b1);

//----------------------------------------------
// Count 4096 cycles
reg clear_ram_done;
reg clear_ram_processing;
reg [11:0] tt_counter;

always @(posedge clk) begin
    if (~resetn || soft_reset)
        clear_ram_processing <= 0;
    else if (clear_ram_start_pulse)
        clear_ram_processing <= 1;
    else if (tt_counter == 0)
        clear_ram_processing <= 0;
end
always @(posedge clk) begin
    if (~resetn || soft_reset)
        tt_counter <= 12'hFFF;
    else if (clear_ram_processing)
        tt_counter <= tt_counter - 1;
    else if (tt_counter == 0)
        tt_counter <= 12'hFFF;
end

always @(posedge clk) begin
    if (~resetn || soft_reset)
        clear_ram_done <= 0;
    else if ( clear_ram_processing & (tt_counter == 0)) // Keeps 1
        clear_ram_done <= 1;
    else if (ocaccel_start_pulse)  //Clear when new job starts
        clear_ram_done <= 0;
end

//-----------------------------------------------------------------------------
// Start AXI data transactions 
//-----------------------------------------------------------------------------

assign engine_start_pulse = ocaccel_start_pulse & (REG_user_mode[CLEAR_RAM_BIT] == 1'b0);

//----------------------------------------------
// AXI transaction done logic

reg [1:0] rd_error_q;
reg        wr_error_q;
reg        rd_done_q;
reg        wr_done_q;

// Error done logic
// When rd data error happens, records the error info
always@(posedge clk)
    if (~resetn || soft_reset)
        REG_error_info  <= 64'd0;
    else if(rd_error[1] & (!rd_error_q[1])) //Record the exact cycle
        REG_error_info  <= rd_error_info;

always@(posedge clk)
    if (~resetn || soft_reset)
        rd_error_q <= 2'b0;
    else if(|rd_error)
        rd_error_q <= rd_error;
    else if (ocaccel_start_pulse)
        rd_error_q <= 2'b0; //Clear when new job starts

always@(posedge clk)
    if (~resetn || soft_reset)
        wr_error_q <= 1'b0;
    else if(wr_error)
        wr_error_q <= 1'b1;
    else if (ocaccel_start_pulse)
        wr_error_q <= 1'b0; //Clear when new job starts

// Normal done logic
always@(posedge clk)
    if (~resetn || soft_reset)
        rd_done_q <= 0;
    else if (rd_done_pulse )
        rd_done_q <= 1;
    else if (ocaccel_start_pulse)
        rd_done_q <= 0; //Clear when new job starts

always@(posedge clk)
   if (~resetn || soft_reset)
       wr_done_q <= 0;
   else if (wr_done_pulse)
       wr_done_q <= 1;
   else if (ocaccel_start_pulse)
       wr_done_q <= 0; //Clear when new job starts

// When rd_number is 0, only check wr_done.
// When wr_number is 0, only check rd_done.
// When both numbers are 0 --> not allowed from software
// When neither is 0, check both wr_done and rd_done

wire transaction_done;
assign transaction_done = (|rd_error_q) || wr_error_q || 
                          ( (rd_number == 0 ) && wr_done_q ) ||
                          ( (wr_number == 0 ) && rd_done_q ) ||
                          ( (rd_number !=0 ) && (wr_number != 0) && wr_done_q && rd_done_q );
reg transaction_processing; 
always@(posedge clk)
   if (~resetn || soft_reset)
        transaction_processing <= 1'b0;
   else if (engine_start_pulse)
        transaction_processing <= 1'b1;
   else if (transaction_done)
        transaction_processing <= 1'b0;

//-----------------------------------------------------------------------------
assign ocaccel_done_d        = clear_ram_done || transaction_done; 
always@(posedge clk)
    if (~resetn || soft_reset)
        ocaccel_done_q <= 1'b0;
    else
        ocaccel_done_q <= ocaccel_done_d;

assign ocaccel_done_pulse = ocaccel_done_d & (~ocaccel_done_q);

assign REG_user_status     = {current_cycle_H, 11'h0, rd_error_q, wr_error_q, rd_done_q, wr_done_q};


/***********************************************************************
*                       reading registers                              *
***********************************************************************/
assign read_address = s_axi_araddr;

//---- read registers ----
 always@(posedge clk)
   if(~resetn)
     s_axi_rdata <= 32'd0;
   else if(s_axi_arvalid & s_axi_arready)
     case(read_address)
       ADDR_OCACCEL_CONTROL        : s_axi_rdata <= REG_ocaccel_control_rd;

       ADDR_USER_STATUS         : s_axi_rdata <= REG_user_status;
       ADDR_USER_MODE           : s_axi_rdata <= REG_user_mode;
       ADDR_INIT_RDATA          : s_axi_rdata <= REG_init_rdata;
       ADDR_INIT_WDATA          : s_axi_rdata <= REG_init_wdata;
       ADDR_TT_RD_CMD           : s_axi_rdata <= cyc_tt_rd_cmd;
       ADDR_TT_RD_RSP           : s_axi_rdata <= cyc_tt_rd_rsp;
       ADDR_TT_WR_CMD           : s_axi_rdata <= cyc_tt_wr_cmd;
       ADDR_TT_WR_RSP           : s_axi_rdata <= cyc_tt_wr_rsp;
       ADDR_TT_ARID             : s_axi_rdata <= {27'd0, dout_arid};
       ADDR_TT_AWID             : s_axi_rdata <= {27'd0, dout_awid};
       ADDR_TT_RID              : s_axi_rdata <= {27'd0, dout_rid};
       ADDR_TT_BID              : s_axi_rdata <= {27'd0, dout_bid};
       ADDR_RD_PATTERN          : s_axi_rdata <= REG_rd_pattern;
       ADDR_RD_NUMBER           : s_axi_rdata <= REG_rd_number;
       ADDR_WR_PATTERN          : s_axi_rdata <= REG_wr_pattern;
       ADDR_WR_NUMBER           : s_axi_rdata <= REG_wr_number;
       ADDR_SOURCE_ADDRESS_L    : s_axi_rdata <= REG_source_address[31  : 0];
       ADDR_SOURCE_ADDRESS_H    : s_axi_rdata <= REG_source_address[63  : 32];
       ADDR_TARGET_ADDRESS_L    : s_axi_rdata <= REG_target_address[31  : 0];
       ADDR_TARGET_ADDRESS_H    : s_axi_rdata <= REG_target_address[63  : 32];
       ADDR_ERROR_INFO_L        : s_axi_rdata <= REG_error_info[31  : 0];
       ADDR_ERROR_INFO_H        : s_axi_rdata <= REG_error_info[63  : 32];
       ADDR_SOFT_RESET          : s_axi_rdata <= REG_soft_reset;
       default                  : s_axi_rdata <= 32'h5a5aa5a5;
     endcase

//---- address ready: deasserts once arvalid is seen; reasserts when current read is done ----
 always@(posedge clk)
   if(~resetn)
     s_axi_arready <= 1'b1;
   else if(s_axi_arvalid)
     s_axi_arready <= 1'b0;
   else if(s_axi_rvalid & s_axi_rready)
     s_axi_arready <= 1'b1;

//---- data ready: deasserts once rvalid is seen; reasserts when new address has come ----
 always@(posedge clk)
   if(~resetn)
     s_axi_rvalid <= 1'b0;
   else if (s_axi_arvalid & s_axi_arready)
     s_axi_rvalid <= 1'b1;
   else if (s_axi_rready)
     s_axi_rvalid <= 1'b0;




/***********************************************************************
*                        status reporting                              *
***********************************************************************/

//---- axi write response ----
 always@(posedge clk)
   if(~resetn) 
     s_axi_bvalid <= 1'b0;
   else if(s_axi_wvalid & s_axi_wready)
     s_axi_bvalid <= 1'b1;
   else if(s_axi_bready)
     s_axi_bvalid <= 1'b0;

 assign s_axi_bresp = 2'd0;

//---- axi read response ----
 assign s_axi_rresp = 2'd0;


/***********************************************************************
*                        Four time trace RAMs                          *
***********************************************************************/
always@(posedge clk)
   if(~resetn || soft_reset || ocaccel_start_pulse) begin
        current_cycle_L <= 32'd0;
        current_cycle_H <= 16'd0;
   end
   else if (transaction_processing) begin
        if (current_cycle_L == 32'hFFFFFFFF) begin
            current_cycle_H <= current_cycle_H + 1;
            current_cycle_L <= 32'd0;
        end
        else
            current_cycle_L <= current_cycle_L + 1;
   end

//Generate RAM address
//wr_done_pulse and rd_done_pulse are 1-cycle pulses. They are Used to reset the RAM address. 
reg [11:0] tt_addr_rd_cmd;
reg [11:0] tt_addr_rd_rsp;
reg [11:0] tt_addr_wr_cmd;
reg [11:0] tt_addr_wr_rsp;

//We spend 4096 cycles to clear the RAMs. At this moment data_in
//(current_cycle_L) is zero.

always@(posedge clk)
    if(~resetn)
        tt_addr_rd_cmd <= 0;
    else if(soft_reset)
        tt_addr_rd_cmd <= 0;
    else if(rd_done_pulse || (|rd_error))
        tt_addr_rd_cmd <= 0;
    else if (tt_arvalid || //Transactions write RAM, repeatedly flush the old data
             clear_ram_processing  || //Clear RAM in the beginning
            ((s_axi_arvalid & s_axi_arready) && (read_address == ADDR_TT_RD_CMD))) //MMIO read tt RAM
        tt_addr_rd_cmd <= tt_addr_rd_cmd + 1;

always@(posedge clk)
    if(~resetn)
        tt_addr_rd_rsp <= 0;
    else if(soft_reset)
        tt_addr_rd_rsp <= 0;
    else if(rd_done_pulse || (|rd_error) )
        tt_addr_rd_rsp <= 0;
    else if (tt_rlast || //Transactions write RAM, repeatedly flush the old data
             clear_ram_processing  || //Clear RAM in the beginning
            ((s_axi_arvalid & s_axi_arready) && (read_address == ADDR_TT_RD_RSP))) //MMIO read tt RAM
        tt_addr_rd_rsp <= tt_addr_rd_rsp + 1;

always@(posedge clk)
    if(~resetn)
        tt_addr_wr_cmd <= 0;
    else if(soft_reset)
        tt_addr_wr_cmd <= 0;
    else if(wr_done_pulse || wr_error)
        tt_addr_wr_cmd <= 0;
    else if (tt_awvalid || //Transactions write RAM, repeatedly flush the old data
             clear_ram_processing  || //Clear RAM in the beginning
            ((s_axi_arvalid & s_axi_arready) && (read_address == ADDR_TT_WR_CMD))) //MMIO read tt RAM
        tt_addr_wr_cmd <= tt_addr_wr_cmd + 1;

always@(posedge clk)
    if(~resetn)
        tt_addr_wr_rsp <= 0;
    else if(soft_reset)
        tt_addr_wr_rsp <= 0;
    else if(wr_done_pulse || wr_error)
        tt_addr_wr_rsp <= 0;
    else if (tt_bvalid || //Transactions write RAM, repeatedly flush the old data
             clear_ram_processing  || //Clear RAM in the beginning
            ((s_axi_arvalid & s_axi_arready) && (read_address == ADDR_TT_WR_RSP))) //MMIO read tt RAM
        tt_addr_wr_rsp <= tt_addr_wr_rsp + 1;




ram_single_port #(.DATA_WIDTH(37), .ADDR_WIDTH(12)) RAM_tt_rd_cmd(
                .clk      ( clk                        ) ,
                .we       ( tt_arvalid || clear_ram_processing    ) ,
                .addr     ( tt_addr_rd_cmd             ) ,
                .data_in  ( {tt_arid,current_cycle_L}  ) ,
                .data_out ( {dout_arid, cyc_tt_rd_cmd} )
                );
ram_single_port #(.DATA_WIDTH(37), .ADDR_WIDTH(12)) RAM_tt_rd_rsp(
                .clk      ( clk                        ) ,
                .we       ( tt_rlast  || clear_ram_processing     ) ,
                .addr     ( tt_addr_rd_rsp             ) ,
                .data_in  ( {tt_rid,current_cycle_L}  ) ,
                .data_out ( {dout_rid, cyc_tt_rd_rsp} )
                );

ram_single_port #(.DATA_WIDTH(37), .ADDR_WIDTH(12)) RAM_tt_wr_cmd(
                .clk      ( clk                        ) ,
                .we       ( tt_awvalid || clear_ram_processing    ) ,
                .addr     ( tt_addr_wr_cmd             ) ,
                .data_in  ( {tt_awid, current_cycle_L}  ) ,
                .data_out ( {dout_awid, cyc_tt_wr_cmd } )
                );
ram_single_port #(.DATA_WIDTH(37), .ADDR_WIDTH(12)) RAM_tt_wr_rsp(
                .clk      ( clk                       ) ,
                .we       ( tt_bvalid  || clear_ram_processing   ) ,
                .addr     ( tt_addr_wr_rsp            ) ,
                .data_in  ( {tt_bid, current_cycle_L} ) ,
                .data_out ( {dout_bid, cyc_tt_wr_rsp} )
                );
endmodule

