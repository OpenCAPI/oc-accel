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


module mmio # (
                parameter IMP_VERSION = 64'h1000_0000_0000_0000,
                parameter BUILD_DATE = 64'h0000_2000_0101_0800,
                parameter OTHER_CAPABILITY = 56'h0,
                parameter CARD_TYPE = 8'h31
              )
        (
             input                clk                        ,
             input                rst_n                      ,

             //---- SNAP debug -----------------------------
             input         [195:0]  debug_bus_data_bridge    ,
`ifdef OPENCAPI30
             input         [476:0]  debug_bus_trans_protocol ,
`endif
`ifdef CAPI20
`endif
             output               debug_info_clear           ,


             //---- local control output -------------------
             output reg           soft_reset_brdg_odma       , // soft reset SNAP logic
             output reg           soft_reset_action          , // soft reset action logic

             //---- MMIO side interface --------------------
             input                mmio_wr                    ,
             input                mmio_rd                    ,
             input                mmio_dw                    ,
             input         [31:0] mmio_addr                  ,
             input         [63:0] mmio_din                   ,
             output reg    [63:0] mmio_dout                  ,
             output reg           mmio_done                  ,
             output reg           mmio_failed                ,

             //---- AXI Lite interface for action ----------
             output reg           lcl_mmio_wr                     , // write enable
             output reg           lcl_mmio_rd                     , // read enable
             output reg    [31:0] lcl_mmio_addr                   , // write/read address
             output reg    [31:0] lcl_mmio_din                    , // write data
             input                lcl_mmio_ack                    , // write data acknowledgement
             input                lcl_mmio_rsp                    , // write/read response: 1: good; 0: bad
             input         [31:0] lcl_mmio_dout                   , // read data
             input                lcl_mmio_dv                       // read data valid
             );



// local status
 reg bridge_idle;  //  Bridge's data buffers are empty
 reg tlx_busy   ;  //  TLX command all responded
 reg axi_busy   ;  //  AXI command all responded
 reg fatal_error;  //  FIFO overflow or TLX command over-commit


//=================================================================================================================
//              MMIO SPACE ALLOCATION
//=================================================================================================================
// +-----------------------------------------------------------------------------------------------+
// |31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
// +-----------------------------------------------------------------------------------------------+
 localparam GLOBAL_PP_MMIO_BIT    = 31; //0: Global Area; 1: PerPASID (Action) Area
 localparam ACTION_ACCESS_BIT     = 31; //0: Infrastructure registers 1: Action registers
 //Global space is for Infrastructure registers
 //PerPASID space is for Action registers

 //PASID: 512 (9bits)
 localparam PASID_START_BIT       = 30;
 localparam PASID_END_BIT         = 22;

 //Infrastructure registers are grouped
 //Decided by base_address + offset
 localparam BASE_START_BIT   = 21;
 localparam BASE_END_BIT     = 8;
 localparam OFFSET_START_BIT = 7;
 localparam OFFSET_END_BIT   = 0;


//=================================================================================================================
//              GLOBAL AREA REGISTERS DECLARATION
//=================================================================================================================

//------------ BASEADDR_INFRASTRUCTURE ---------------
 reg [63:00] REG_implementation_version;
 reg [63:00] REG_build_date            ;
 reg [63:00] REG_command               ;
 reg [63:00] REG_status                ;
 reg [63:00] REG_capability            ;

//------------ BASEADDR_DEBUG --------------
 reg [63:00] REG_debug_clear            ; // clear out all debug registers

`ifdef OPENCAPI30
 reg [63:00] REG_debug_tlx_cnt_cmd      ; // (higher 32b: R, lower 32b: W) number of total TLX command
 reg [63:00] REG_debug_tlx_cnt_rsp      ; // (higher 32b: R, lower 32b: W) number of total TLX responses
 reg [63:00] REG_debug_tlx_cnt_retry    ; // (higher 32b: R, lower 32b: W) number of TLX retry responses
 reg [63:00] REG_debug_tlx_cnt_fail     ; // (higher 32b: R, lower 32b: W) number of TLX fail responses
 reg [63:00] REG_debug_tlx_cnt_xlt_pd   ; // (higher 32b: R, lower 32b: W) number of TLX xlate pending responses
 reg [63:00] REG_debug_tlx_cnt_xlt_done ; // (higher 32b: R, lower 32b: W) number of TLX xlate done responses
 reg [63:00] REG_debug_tlx_cnt_xlt_retry; // (higher 32b: R, lower 32b: W) number of TLX xlate retry responses
`endif
 reg [63:00] REG_debug_axi_cnt_cmd      ; // (higher 32b: R, lower 32b: W) number of total AXI commands
 reg [63:00] REG_debug_axi_cnt_rsp      ; // (higher 32b: R, lower 32b: W) number of total AXI responses
 reg [63:00] REG_debug_buf_cnt          ; // (higher 32b: R, lower 32b: W) number of available tags

//------------ BASEADDR_FIR ----------------
 reg [63:00] REG_fir_data_bridge      ; // collection of FIFO overflow indicators
`ifdef OPENCAPI30
 reg [63:00] REG_fir_trans_protocol      ; // submit more commands than credits to TLX
`endif

//=================================================================================================================
//   Corresponding wires

`ifdef OPENCAPI30
wire [63:00] debug_tlx_cnt_cmd      ;
wire [63:00] debug_tlx_cnt_rsp      ;
wire [63:00] debug_tlx_cnt_retry    ;
wire [63:00] debug_tlx_cnt_fail     ;
wire [63:00] debug_tlx_cnt_xlt_pd   ;
wire [63:00] debug_tlx_cnt_xlt_done ;
wire [63:00] debug_tlx_cnt_xlt_retry;
assign debug_tlx_cnt_cmd       = debug_bus_trans_protocol[7*64-1 : (7-1)*64] ;
assign debug_tlx_cnt_rsp       = debug_bus_trans_protocol[6*64-1 : (6-1)*64] ;
assign debug_tlx_cnt_retry     = debug_bus_trans_protocol[5*64-1 : (5-1)*64] ;
assign debug_tlx_cnt_fail      = debug_bus_trans_protocol[4*64-1 : (4-1)*64] ;
assign debug_tlx_cnt_xlt_pd    = debug_bus_trans_protocol[3*64-1 : (3-1)*64] ;
assign debug_tlx_cnt_xlt_done  = debug_bus_trans_protocol[2*64-1 : (2-1)*64] ;
assign debug_tlx_cnt_xlt_retry = debug_bus_trans_protocol[1*64-1 : (1-1)*64] ;
`endif

wire [63:00] debug_axi_cnt_cmd      ;
wire [63:00] debug_axi_cnt_rsp      ;
wire [63:00] debug_buf_cnt          ;
assign debug_axi_cnt_cmd       = debug_bus_data_bridge [3*64-1 : (3-1)*64];
assign debug_axi_cnt_rsp       = debug_bus_data_bridge [2*64-1 : (2-1)*64];
assign debug_buf_cnt           = debug_bus_data_bridge [1*64-1 : (1-1)*64];


wire [63:00] fir_data_bridge      ;
assign fir_data_bridge = {60'b0, debug_bus_data_bridge[195:192]} ;

`ifdef OPENCAPI30
wire [63:00] fir_trans_protocol      ;
assign fir_trans_protocol = {35'b0, debug_bus_trans_protocol[476:448]} ;
`endif

//=================================================================================================================
//              GLOBAL AREA REGISTER ADDRESSES
//=================================================================================================================
//-----------------------------------------------------------------------------
 localparam BASEADDR_INFRASTRUCTURE   = 13'h0000,
                INFRA_OFFSET_IMP_VERSION      = 8'h0 , //RO
                INFRA_OFFSET_BUILD_DATE       = 8'h8 , //RO
                INFRA_OFFSET_COMMAND          = 8'h10, //Write-Only!
                INFRA_OFFSET_STATUS           = 8'h18, //RO
                INFRA_OFFSET_CAPABILITY       = 8'h30, //RO

                INFRA_OFFSET_FREERUN_TIMER   = 8'h40, //RO

//-----------------------------------------------------------------------------
           BASEADDR_DEBUG  = 13'h01A0,
                DEBUG_OFFSET_DBG_CLEAR     = 8'h00, //WO, self-clear
`ifdef OPENCAPI30
                DEBUG_OFFSET_CNT_TLX_CMD   = 8'h08, //RO
                DEBUG_OFFSET_CNT_TLX_RSP   = 8'h10, //RO
                DEBUG_OFFSET_CNT_TLX_RTY   = 8'h18, //RO
                DEBUG_OFFSET_CNT_TLX_FAIL  = 8'h20, //RO
                DEBUG_OFFSET_CNT_TLX_XLP   = 8'h28, //RO
                DEBUG_OFFSET_CNT_TLX_XLD   = 8'h30, //RO
                DEBUG_OFFSET_CNT_TLX_XLR   = 8'h38, //RO
`endif
                DEBUG_OFFSET_CNT_AXI_CMD   = 8'h40, //RO
                DEBUG_OFFSET_CNT_AXI_RSP   = 8'h48, //RO
                DEBUG_OFFSET_BUF_CNT       = 8'h50, //RO

//-----------------------------------------------------------------------------
           BASEADDR_FIR    = 13'h01C0,

                FIR_OFFSET_DATA_BRIDGE      = 8'h0 , //RO
`ifdef OPENCAPI30
                FIR_OFFSET_TRANS_PROTOCOL   = 8'h8 ; //RO
`endif

//=================================================================================================================
//              LOGIC
//=================================================================================================================

//---- action access: 4B; Global area access: 8B ----
 wire data_width_incompatible = (mmio_rd || mmio_wr) && ((mmio_addr[ACTION_ACCESS_BIT] && mmio_dw) || (~mmio_addr[ACTION_ACCESS_BIT] && ~mmio_dw));

//---- validated action and global_area access ----
 wire action_access = mmio_addr[ACTION_ACCESS_BIT];
 wire global_area_access = ~mmio_addr[ACTION_ACCESS_BIT];

//---- extract base and offset addresses for global area register set ----
 wire[BASE_START_BIT   - BASE_END_BIT   : 0] global_area_base;
 wire[OFFSET_START_BIT - OFFSET_END_BIT : 0] global_area_offset;
 assign global_area_base   = mmio_addr[BASE_START_BIT  : BASE_END_BIT];
 assign global_area_offset = mmio_addr[OFFSET_START_BIT: OFFSET_END_BIT];


 reg waddr_decode_error, raddr_decode_error;
 reg global_area_wr_ack, global_area_rd_ack;

//---- action write/read valid pulse ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       lcl_mmio_wr <= 1'b0;
       lcl_mmio_rd <= 1'b0;
     end
   else if(action_access)
     begin
       lcl_mmio_wr <= mmio_wr;
       lcl_mmio_rd <= mmio_rd;
     end

//---- action register address ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     lcl_mmio_addr <= 32'd0;
   else
     lcl_mmio_addr <= {1'b0,mmio_addr[30:0]}; //Lower 31bits are transfered to Action.

//---- action write data ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     lcl_mmio_din <= 32'd0;
   else
     lcl_mmio_din <= mmio_addr[2]? mmio_din[63:32] : mmio_din[31:0];

//---- return failure when... ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     mmio_failed <= 1'b0;
   else
     mmio_failed <= (data_width_incompatible )                        ||  // 1. access with unwarrented data widths
                    ((lcl_mmio_ack || lcl_mmio_dv) && (lcl_mmio_rsp == 1'b0))        ||  // 2. receive bad response from action
                    (global_area_wr_ack && waddr_decode_error)               ||  // 3. not able to locate defined SNAP register, or access illegally
                    (global_area_rd_ack && raddr_decode_error);

//---- return done when... ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     mmio_done <= 1'b0;
   else
     mmio_done <= ((lcl_mmio_ack || lcl_mmio_dv) && (lcl_mmio_rsp == 1'b1)) || // 1. receive good response from action
                  (global_area_wr_ack && ~waddr_decode_error)       || // 2. done with SNAP register access
                  (global_area_rd_ack && ~raddr_decode_error);


//---- READ ONLY resigers configuration ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       // BASEADDR_INFRASTRUCTURE
       REG_implementation_version  <= 64'd0;
       REG_build_date              <= 64'd0;
       REG_status                  <= 64'd0;
       REG_capability              <= 64'd0;

       // BASEADDR_DEBUG
`ifdef OPENCAPI30
       REG_debug_tlx_cnt_cmd       <= 64'd0;
       REG_debug_tlx_cnt_rsp       <= 64'd0;
       REG_debug_tlx_cnt_retry     <= 64'd0;
       REG_debug_tlx_cnt_fail      <= 64'd0;
       REG_debug_tlx_cnt_xlt_pd    <= 64'd0;
       REG_debug_tlx_cnt_xlt_done  <= 64'd0;
       REG_debug_tlx_cnt_xlt_retry <= 64'd0;
`endif
       REG_debug_axi_cnt_cmd       <= 64'd0;
       REG_debug_axi_cnt_rsp       <= 64'd0;
       REG_debug_buf_cnt           <= 64'd0;

       // BASEADDR_FIR
       REG_fir_data_bridge       <= 64'd0;
`ifdef OPENCAPI30
       REG_fir_trans_protocol       <= 64'd0;
`endif
     end
   else
     begin
       // BASEADDR_INFRASTRUCTURE
       REG_implementation_version  <= IMP_VERSION;
       REG_build_date              <= BUILD_DATE;
       REG_status                  <= {60'd0, fatal_error, axi_busy, tlx_busy, bridge_idle};
       REG_capability [63:8]       <= OTHER_CAPABILITY;
       REG_capability [7:0]        <= CARD_TYPE;


       // BASEADDR_DEBUG
`ifdef OPENCAPI30
       REG_debug_tlx_cnt_cmd       <= debug_tlx_cnt_cmd      ;
       REG_debug_tlx_cnt_rsp       <= debug_tlx_cnt_rsp      ;
       REG_debug_tlx_cnt_retry     <= debug_tlx_cnt_retry    ;
       REG_debug_tlx_cnt_fail      <= debug_tlx_cnt_fail     ;
       REG_debug_tlx_cnt_xlt_pd    <= debug_tlx_cnt_xlt_pd   ;
       REG_debug_tlx_cnt_xlt_done  <= debug_tlx_cnt_xlt_done ;
       REG_debug_tlx_cnt_xlt_retry <= debug_tlx_cnt_xlt_retry;
`endif
       REG_debug_axi_cnt_cmd       <= debug_axi_cnt_cmd      ;
       REG_debug_axi_cnt_rsp       <= debug_axi_cnt_rsp      ;
       REG_debug_buf_cnt           <= debug_buf_cnt          ;

       // BASEADDR_FIR
       REG_fir_data_bridge         <= fir_data_bridge ;
`ifdef OPENCAPI30
       REG_fir_trans_protocol      <= fir_trans_protocol ;
`endif
     end


//---- Write only/write read REGISTER writing ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       REG_command            <= 64'd0;
       REG_debug_clear        <= 64'd0;
       REG_debug_tlx_idle_lim <= 64'd0;
       REG_debug_axi_idle_lim <= 64'd0;

       waddr_decode_error <= 1'b0;
     end

   else if(global_area_access && mmio_wr)
     case(global_area_base)

       BASEADDR_INFRASTRUCTURE :
          case(global_area_offset)
            INFRA_OFFSET_COMMAND       : REG_command        <= mmio_din;
            default                    : waddr_decode_error <= 1'b1;
          endcase

       BASEADDR_DEBUG :
          case(global_area_offset)
            DEBUG_OFFSET_DBG_CLEAR    : REG_debug_clear    <= mmio_din;
            default                   : waddr_decode_error <= 1'b1;
          endcase

       default                        : waddr_decode_error <= 1'b1;
     endcase
   else
     begin
       REG_debug_clear <= 64'd0;
       REG_command     <= 64'd0;

       waddr_decode_error <= 1'b0;
     end

 always@(posedge clk)
   begin
   end


//---- SNAP/ACTION REGISTER reading ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       mmio_dout <= 64'd0;
       raddr_decode_error <= 1'b0;
     end

   // read value from action registers and place it in correct half for TLX
   else if(lcl_mmio_dv)
     begin
       mmio_dout <= mmio_addr[2]? {lcl_mmio_dout, 32'd0} : {32'd0, lcl_mmio_dout};
       raddr_decode_error <= 1'b0;
     end

   // read from SNAP registers
   else if (global_area_access) begin
     case(global_area_base)

       BASEADDR_INFRASTRUCTURE :
          case(global_area_offset)
            INFRA_OFFSET_IMP_VERSION         : mmio_dout <= REG_implementation_version;
            INFRA_OFFSET_BUILD_DATE          : mmio_dout <= REG_build_date            ;
            INFRA_OFFSET_STATUS              : mmio_dout <= REG_status                ;
            INFRA_OFFSET_CAPABILITY          : mmio_dout <= REG_capability            ;
            default                          : raddr_decode_error <= 1'b1;
          endcase

       BASEADDR_DEBUG :
          case(global_area_offset)
`ifdef OPENCAPI30
            DEBUG_OFFSET_CNT_TLX_CMD   : mmio_dout <= REG_debug_tlx_cnt_cmd      ;
            DEBUG_OFFSET_CNT_TLX_RSP   : mmio_dout <= REG_debug_tlx_cnt_rsp      ;
            DEBUG_OFFSET_CNT_TLX_RTY   : mmio_dout <= REG_debug_tlx_cnt_retry    ;
            DEBUG_OFFSET_CNT_TLX_FAIL  : mmio_dout <= REG_debug_tlx_cnt_fail     ;
            DEBUG_OFFSET_CNT_TLX_XLP   : mmio_dout <= REG_debug_tlx_cnt_xlt_pd   ;
            DEBUG_OFFSET_CNT_TLX_XLD   : mmio_dout <= REG_debug_tlx_cnt_xlt_done ;
            DEBUG_OFFSET_CNT_TLX_XLR   : mmio_dout <= REG_debug_tlx_cnt_xlt_retry;
`endif
            DEBUG_OFFSET_CNT_AXI_CMD   : mmio_dout <= REG_debug_axi_cnt_cmd      ;
            DEBUG_OFFSET_CNT_AXI_RSP   : mmio_dout <= REG_debug_axi_cnt_rsp      ;
            DEBUG_OFFSET_BUF_CNT       : mmio_dout <= REG_debug_buf_cnt          ;
            default                    : raddr_decode_error <= 1'b1;
          endcase

       BASEADDR_FIR :
          case(global_area_offset)
            FIR_OFFSET_DATA_BRIDGE      : mmio_dout <= REG_fir_data_bridge       ;
`ifdef OPENCAPI30
            FIR_OFFSET_TRANS_PROTOCOL   : mmio_dout <= REG_fir_trans_protocol    ;
`endif
            default                     : raddr_decode_error <= 1'b1;
          endcase

       default                          : raddr_decode_error <= 1'b1;
     endcase
   end

//---- SNAP registers acknowledgement ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       global_area_wr_ack <= 1'b0;
       global_area_rd_ack <= 1'b0;
     end
   else
     begin
       global_area_wr_ack <= mmio_wr && global_area_access;
       global_area_rd_ack <= mmio_rd && global_area_access;
     end

//---- local control signals output ----
 reg [3:0] snap_reset_cnt;
 reg [3:0] action_reset_cnt;
 always@(posedge clk or negedge rst_n)   // soft reset lasts 16 cycles
   if(~rst_n)
     soft_reset_brdg_odma <= 1'b0;
   else if(&snap_reset_cnt)
     soft_reset_brdg_odma <= 1'b0;
   else if(REG_command[0])
     soft_reset_brdg_odma <= 1'b1;

 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     snap_reset_cnt <= 4'd0;
   else if(soft_reset_brdg_odma)
     snap_reset_cnt <= snap_reset_cnt + 4'd1;

 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     soft_reset_action <= 1'b0;
   else if(&action_reset_cnt)
     soft_reset_action <= 1'b0;
   else if(REG_command[0])
     soft_reset_action <= 1'b1;

 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     action_reset_cnt <= 4'd0;
   else if(soft_reset_action)
     action_reset_cnt <= action_reset_cnt + 4'd1;

 assign debug_info_clear    = REG_debug_clear[0];

//---- local status signals generation ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     begin
       bridge_idle <= 1'b0;
       tlx_busy    <= 1'b0;
       axi_busy    <= 1'b0;
       fatal_error <= 1'b0;
     end
   else
     begin
       bridge_idle <= (debug_buf_cnt == 64'd0); // SNAP considered in IDLE when both data BUF are empty
       tlx_busy    <= (debug_tlx_cnt_cmd != debug_tlx_cnt_rsp); // only count read and write command/response pair, not viable for split responses
       axi_busy    <= (debug_axi_cnt_cmd != debug_axi_cnt_rsp);
       fatal_error <= |{fir_data_bridge, fir_trans_protocol};
     end


endmodule
