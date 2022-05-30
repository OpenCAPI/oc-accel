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
//oc_snap_core
//action_wrapper
//afu_descriptor
//axi_dwidth_converter_act2snap
//
//
//
module framework_afu (

  // // Clocks & Reset
    input                 clock_tlx
  , input                 clock_afu
  , input                 reset
  , input                 decouple
  , input                 ocde                   //connected from top-level port
  , output                ocde_to_bsp_dcpl

  // // AFU Index
  , input           [5:0] afu_index                            // // This AFU's Index within the Function
                                                             
  // // TLX_AFU command receive interface                    
  // TODO tlx_afu_ready is not used anywhere, if should be worked with fence
  , input                 tlx_afu_ready                        // // TLX indicates it is ready to receive cmds and responses from AFU
  , input                 tlx_afu_cmd_valid                    // // Command Valid (Receive)
  , input           [7:0] tlx_afu_cmd_opcode                   // // Command Opcode
  , input          [15:0] tlx_afu_cmd_capptag                  // // Command Tag
  , input           [1:0] tlx_afu_cmd_dl                       // // Command Data Length
  , input           [2:0] tlx_afu_cmd_pl                       // // Command Partial Length
  , input          [63:0] tlx_afu_cmd_be                       // // Command Byte Enable
  , input                 tlx_afu_cmd_end                      // // Endianness
  , input          [63:0] tlx_afu_cmd_pa                       // // Physical Address
  , input           [3:0] tlx_afu_cmd_flag                     // // Atomic memory operation specifier
  , input                 tlx_afu_cmd_os                       // // Ordered segment
                                                             
  , output                afu_tlx_cmd_rd_req                   // // Command Read Request
  , output          [2:0] afu_tlx_cmd_rd_cnt                   // // Command Read Count
                                                             
  , input                 tlx_afu_cmd_data_valid               // // Command Data Valid. Indicates valid data available
  , input                 tlx_afu_cmd_data_bdi                 // // Command Data Bad Data Indicator
  , input         [511:0] tlx_afu_cmd_data_bus                 // // Command Data Bus
                                                                         
  , output                afu_tlx_cmd_credit                   // // AFU returns cmd credit to TLX
  , output          [6:0] afu_tlx_cmd_initial_credit           // // AFU indicates number of command credits available (static value)
                                                             
  // // AFU_TLX response transmit interface                  
  , output                afu_tlx_resp_valid                   // // Response Valid (Transmit)
  , output          [7:0] afu_tlx_resp_opcode                  // // Response Opcode
  , output          [1:0] afu_tlx_resp_dl                      // // Response Data Length
  , output         [15:0] afu_tlx_resp_capptag                 // // Response Tag
  , output          [1:0] afu_tlx_resp_dp                      // // Response Data Part - indicates the data content of the current response packet
  , output          [3:0] afu_tlx_resp_code                    // // Response Code - reason for failed transaction
                                                             
  , output                afu_tlx_rdata_valid                  // // Response Valid
  , output                afu_tlx_rdata_bdi                    // // Response Bad Data Indicator
  , output        [511:0] afu_tlx_rdata_bus                    // // Response Opcode
                                                             
  , input                 tlx_afu_resp_credit                  // // TLX returns resp credit to AFU when resp taken from FIFO by DLX
  , input                 tlx_afu_resp_data_credit             // // TLX returns resp data credit to AFU when resp data taken from FIFO by DLX
                                                             
  // // AFU_TLX command transmit interface                   
  , output                afu_tlx_cmd_valid                    // // Command Valid (Transmit)
  , output          [7:0] afu_tlx_cmd_opcode                   // // Command Opcode
  , output         [11:0] afu_tlx_cmd_actag                    // // Address Context Tag
  , output          [3:0] afu_tlx_cmd_stream_id                // // Stream ID
  , output         [67:0] afu_tlx_cmd_ea_or_obj                // // Effective Address/Object Handle
  , output         [15:0] afu_tlx_cmd_afutag                   // // Command Tag
  , output          [1:0] afu_tlx_cmd_dl                       // // Command Data Length
  , output          [2:0] afu_tlx_cmd_pl                       // // Partial Length
  , output                afu_tlx_cmd_os                       // // Ordered Segment
  , output         [63:0] afu_tlx_cmd_be                       // // Byte Enable
  , output          [3:0] afu_tlx_cmd_flag                     // // Command Flag, used in atomic operations
  , output                afu_tlx_cmd_endian                   // // Endianness
  , output         [15:0] afu_tlx_cmd_bdf                      // // Bus Device Function
  , output         [19:0] afu_tlx_cmd_pasid                    // // User Process ID
  , output          [5:0] afu_tlx_cmd_pg_size                  // // Page Size
                                                             
  , output                afu_tlx_cdata_valid                  // // Command Data Valid. Indicates valid data available
  , output                afu_tlx_cdata_bdi                    // // Command Data Bad Data Indicator
  , output        [511:0] afu_tlx_cdata_bus                    // // Command Data Bus 
                                                             
  , input                 tlx_afu_cmd_credit                   // // TLX returns cmd credit to AFU when cmd taken from FIFO by DLX
  , input                 tlx_afu_cmd_data_credit              // // TLX returns cmd data credit to AFU when cmd data taken from FIFO by DLX
                                                             
//GFP  , input           [4:3] tlx_afu_cmd_resp_initial_credit_x    // // EAC informs AFU of additional cmd/resp credits available
  , input           [4:4] tlx_afu_cmd_initial_credit_x         // // EAC informs AFU of additional cmd credits available
//GFP  , input           [2:0] tlx_afu_cmd_resp_initial_credit      // // TLX informs AFU cmd/resp credits available - same for cmd and resp
  , input           [3:0] tlx_afu_cmd_initial_credit           // // TLX informs AFU cmd credits available
  , input           [3:0] tlx_afu_resp_initial_credit          // // TLX informs AFU resp credits available
//GFP  , input           [6:5] tlx_afu_data_initial_credit_x        // // EAC informs AFU of additional data credits available
  , input           [6:6] tlx_afu_cmd_data_initial_credit_x    // // EAC informs AFU of additional data credits available
//GFP  , input           [4:0] tlx_afu_data_initial_credit          // // TLX informs AFU data credits available
  , input           [5:0] tlx_afu_cmd_data_initial_credit      // // TLX informs AFU data credits available
  , input           [5:0] tlx_afu_resp_data_initial_credit     // // TLX informs AFU data credits available
                                                                                                                          
  // // TLX_AFU response receive interface                   
  , input                 tlx_afu_resp_valid                   // // Response Valid (Receive)
  , input           [7:0] tlx_afu_resp_opcode                  // // Response Opcode
  , input          [15:0] tlx_afu_resp_afutag                  // // Response Tag
  , input           [3:0] tlx_afu_resp_code                    // // Response Code - reason for failed transaction
  , input           [1:0] tlx_afu_resp_dl                      // // Response Data Length
  , input           [1:0] tlx_afu_resp_dp                      // // Response Data Part - indicates the data content of the current response packet
  , input           [5:0] tlx_afu_resp_pg_size                 // // Not used in this implementation
  , input          [17:0] tlx_afu_resp_addr_tag                // // Not used in this implementation
//, input          [23:0] tlx_afu_resp_host_tag                // // Reserved for CAPI 4.0
//, input           [3:0] tlx_afu_resp_cache_state             // // Reserved for CAPI 4.0
                                                             
  , output                afu_tlx_resp_rd_req                  // // Response Read Request
  , output          [2:0] afu_tlx_resp_rd_cnt                  // // Response Read Count
                                                             
  , input                 tlx_afu_resp_data_valid              // // Response Data Valid. Indicates valid data available
  , input                 tlx_afu_resp_data_bdi                // // Response Data Bad Data Indicator
  , input         [511:0] tlx_afu_resp_data_bus                // // Response Data Bus
                                                                           
  , output                afu_tlx_resp_credit                  // // AFU returns resp credit to TLX
  , output          [6:0] afu_tlx_resp_initial_credit          // // AFU indicates number of response credits available (static value)

  , output                afu_tlx_fatal_error                  // // A fatal error occurred on this AFU, or software injected an error

  // // BDF Interface
  , input           [7:0] cfg_afu_bdf_bus 
  , input           [4:0] cfg_afu_bdf_device 
  , input           [2:0] cfg_afu_bdf_function


  // // Configuration Space Outputs used by AFU
 
  // // MMIO
  , input                 cfg_csh_memory_space
  , input          [63:0] cfg_csh_mmio_bar0 

  // // 'assign_actag' generation controls
  , input          [11:0] cfg_octrl00_afu_actag_base        // // This is the base acTag      this AFU can use (linear value)
  , input          [11:0] cfg_octrl00_afu_actag_len_enab    // // This is the range of acTags this AFU can use (linear value)

  // // Process termination controls
  , output                cfg_octrl00_terminate_in_progress // // Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input                 cfg_octrl00_terminate_valid       // // Unused by LPC since it doesn't make sense to terminate the general interrupt process
  , input          [19:0] cfg_octrl00_terminate_pasid       // // Unused by LPC since it doesn't make sense to terminate the general interrupt process 

  // // PASID controls
  , input           [4:0] cfg_octrl00_pasid_length_enabled  // // Should be >=0 for LPC to allow it to have at least 1 PASID for interrupts 
  , input          [19:0] cfg_octrl00_pasid_base            // // Starting value of PASIDs, must be within 'Max PASID Width'
                                                            // // Notes: 
                                                            // // - 'PASID base' is for this AFU, used to keep PASID range within each AFU unique.
                                                            // // - 'PASID Length Enabled' + 'PASID base' must be within range of 'Max PASID Width'
                                                            // // More Notes:
                                                            // // - 'Max PASID Width' and 'PASID Length Supported' are Read Only inputs to cfg_func.
                                                            // // - 'Max PASID Width' is range of PASIDs across all AFUs controlled by this BDF.
                                                            // // - 'PASID Length Supported' can be <, =, or > 'Max PASID Width' 
                                                            // //   The case of 'PASID Length Supported' > 'Max PASID Width' may seem odd. However it 
                                                            // //   is legal since an AFU may support more PASIDs than it advertizes, for instance
                                                            // //   in the case where a more general purpose AFU is reused in an application that
                                                            // //   has a restricted use.
                                                      
  // // Interrupt generation controls                  
  , input           [3:0] cfg_f0_otl0_long_backoff_timer    // // TLX Configuration for the TLX port(s) connected to AFUs under this Function
  , input           [3:0] cfg_f0_otl0_short_backoff_timer
  , input                 cfg_octrl00_enable_afu            // // When 1, the AFU can initiate commands to the host

   // // Metadata
//, input                cfg_octrl00_metadata_enabled       // // Not Used
//, input          [6:0] cfg_octr00l_default_metadata       // // Not Used

  // // AFU Descriptor Table interface to AFU Configuration Space
  , input           [5:0] cfg_desc_afu_index
  , input          [30:0] cfg_desc_offset
  , input                 cfg_desc_cmd_valid
  , output         [31:0] desc_cfg_data
  , output                desc_cfg_data_valid
  , output                desc_cfg_echo_cmd_valid

  // // Errors to record from Configuration Sub-system, Descriptor Table, and VPD
  , input                 vpd_err_unimplemented_addr
  , input                 cfg0_cff_fifo_overflow
//, input                 cfg1_cff_fifo_overflow
  , input                 cfg0_rff_fifo_overflow
//, input                 cfg1_rff_fifo_overflow
  , input         [127:0] cfg_errvec
  , input                 cfg_errvec_valid

  `ifdef ENABLE_DDR 
    `ifdef AD9V3
  
   // DDR4 SDRAM Interface
 // , output [511:0]       dbg_bus //Unused
    , input                  c0_sys_clk_p
    , input                  c0_sys_clk_n
    , output  [16 : 0]       c0_ddr4_adr
    , output  [1 : 0]        c0_ddr4_ba
    , output  [0 : 0]        c0_ddr4_cke
    , output  [0 : 0]        c0_ddr4_cs_n
    , inout   [8 : 0]        c0_ddr4_dm_dbi_n
    , inout   [71 : 0]       c0_ddr4_dq
    , inout   [8 : 0]        c0_ddr4_dqs_c
    , inout   [8 : 0]        c0_ddr4_dqs_t
    , output  [0 : 0]        c0_ddr4_odt
    , output  [1 : 0]        c0_ddr4_bg
    , output                 c0_ddr4_reset_n
    , output                 c0_ddr4_act_n
    , output  [0 : 0]        c0_ddr4_ck_c
    , output  [0 : 0]        c0_ddr4_ck_t
     `endif
     `ifdef BW250SOC
  
   // DDR4 SDRAM Interface
 // , output [511:0]       dbg_bus //Unused
    , input                  c0_sys_clk_p
    , input                  c0_sys_clk_n
    , output  [16 : 0]       c0_ddr4_adr
    , output  [1 : 0]        c0_ddr4_ba
    , output  [0 : 0]        c0_ddr4_cke
    , output  [0 : 0]        c0_ddr4_cs_n
    , inout   [8 : 0]        c0_ddr4_dm_dbi_n
    , inout   [71 : 0]       c0_ddr4_dq
    , inout   [8 : 0]        c0_ddr4_dqs_c
    , inout   [8 : 0]        c0_ddr4_dqs_t
    , output  [0 : 0]        c0_ddr4_odt
    , output  [0 : 0]        c0_ddr4_bg
    , output                 c0_ddr4_reset_n
    , output                 c0_ddr4_act_n
    , output  [0 : 0]        c0_ddr4_ck_c
    , output  [0 : 0]        c0_ddr4_ck_t
      `endif
   `endif

// ETHERNET
  `ifdef ENABLE_ETHERNET 
     `ifndef ENABLE_ETH_LOOP_BACK
    , input                  gt_ref_clk_n
    , input                  gt_ref_clk_p
    , input                  gt_rx_gt_port_0_n
    , input                  gt_rx_gt_port_0_p
    , input                  gt_rx_gt_port_1_n
    , input                  gt_rx_gt_port_1_p
    , input                  gt_rx_gt_port_2_n
    , input                  gt_rx_gt_port_2_p
    , input                  gt_rx_gt_port_3_n
    , input                  gt_rx_gt_port_3_p
    , output                 gt_tx_gt_port_0_n
    , output                 gt_tx_gt_port_0_p
    , output                 gt_tx_gt_port_1_n
    , output                 gt_tx_gt_port_1_p
    , output                 gt_tx_gt_port_2_n
    , output                 gt_tx_gt_port_2_p
    , output                 gt_tx_gt_port_3_n
    , output                 gt_tx_gt_port_3_p
      `endif
   `endif
// in Cloud mode / PRFLOW we need to give access to ICAP to the user (w/o sudo) 
`ifndef ENABLE_ODMA
`ifdef ENABLE_PRFLOW
    , output [`AXI_LITE_AW-1:0]   lite_snap2icap_awaddr
    , output [2:0]                lite_snap2icap_awprot
    , output                      lite_snap2icap_awvalid
    , output [`AXI_LITE_DW-1:0]   lite_snap2icap_wdata
    , output [3:0]                lite_snap2icap_wstrb
    , output                      lite_snap2icap_wvalid
    , output                      lite_snap2icap_bready
    , output [`AXI_LITE_AW-1:0]   lite_snap2icap_araddr
    , output [2:0]                lite_snap2icap_arprot
    , output                      lite_snap2icap_arvalid
    , output                      lite_snap2icap_rready

    , input                       lite_icap2snap_awready
    , input                       lite_icap2snap_wready
    , input [1:0]                 lite_icap2snap_bresp
    , input                       lite_icap2snap_bvalid
    , input                       lite_icap2snap_arready
    , input [`AXI_LITE_DW-1:0]    lite_icap2snap_rdata
    , input [1:0]                 lite_icap2snap_rresp
    , input                       lite_icap2snap_rvalid
`endif
`endif

`ifdef ENABLE_9H3_LED
     , output                 user_led_a0
     , output                 user_led_a1
     , output                 user_led_g0
     , output                 user_led_g1
`endif
`ifdef ENABLE_9H3_EEPROM
     , inout                  eeprom_scl
     , inout                  eeprom_sda
     , output                 eeprom_wp
`endif 
`ifdef ENABLE_9H3_AVR
    , input                  avr_rx
    , output                 avr_tx
    , input                  avr_ck
`endif
  );

  // // ******************************************************************************
  // // wires
  // // ******************************************************************************

  // // Interface between snap_core to (clock/dwidth) converter
`ifndef ENABLE_ODMA
  wire [`AXI_LITE_AW-1:0]    lite_snap2conv_awaddr  ;
  wire [2:0]                 lite_snap2conv_awprot  ;
  wire                       lite_snap2conv_awvalid ;
  wire [`AXI_LITE_DW-1:0]    lite_snap2conv_wdata   ;
  wire [3:0]                 lite_snap2conv_wstrb   ;
  wire                       lite_snap2conv_wvalid  ;
  wire                       lite_snap2conv_bready  ;
  wire [`AXI_LITE_AW-1:0]    lite_snap2conv_araddr  ;
  wire [2:0]                 lite_snap2conv_arprot  ;
  wire                       lite_snap2conv_arvalid ;
  wire                       lite_snap2conv_rready  ;

  wire                       reset_action_d_dcpl         ; // decoupling

  wire                       lite_conv2snap_awready ;
  wire                       lite_conv2snap_wready  ;
  wire [1:0]                 lite_conv2snap_bresp   ;
  wire                       lite_conv2snap_bvalid  ;
  wire                       lite_conv2snap_arready ;
  wire [`AXI_LITE_DW-1:0]    lite_conv2snap_rdata   ;
  wire [1:0]                 lite_conv2snap_rresp   ;
  wire                       lite_conv2snap_rvalid  ;

  wire                       mm_snap2conv_awready   ;
  wire                       mm_snap2conv_wready    ;
  wire [`IDW-1:0]             mm_snap2conv_bid      ;
  wire [`AXI_BUSER-1:0]       mm_snap2conv_buser    ;
  wire [1:0]                 mm_snap2conv_bresp     ;
  wire                       mm_snap2conv_bvalid    ;
  wire [`IDW-1:0]             mm_snap2conv_rid      ;
  wire [`AXI_RUSER-1:0]       mm_snap2conv_ruser    ;
  wire [`AXI_MM_DW-1:0]       mm_snap2conv_rdata     ;
  wire [1:0]                 mm_snap2conv_rresp     ;
  wire                       mm_snap2conv_rlast     ;
  wire                       mm_snap2conv_rvalid    ;
  wire                       mm_snap2conv_arready   ;

  wire                       mm_snap2conv_awready_i   ; // decoupling
  wire                       mm_snap2conv_wready_i    ; // decoupling
  wire                       mm_snap2conv_arready_i   ; // decoupling
  wire                       mm_snap2conv_bvalid_i    ; // decoupling
  wire                       mm_snap2conv_rvalid_i    ; // decoupling

  wire [`IDW-1:0]             mm_conv2snap_awid      ;
  wire [`AXI_MM_AW-1:0]       mm_conv2snap_awaddr    ;
  wire [7:0]                 mm_conv2snap_awlen     ;
  wire [2:0]                 mm_conv2snap_awsize    ;
  wire [1:0]                 mm_conv2snap_awburst   ;
  wire                       mm_conv2snap_awlock    ;
  wire [3:0]                 mm_conv2snap_awcache   ;
  wire [2:0]                 mm_conv2snap_awprot    ;
  wire [3:0]                 mm_conv2snap_awqos     ;
  wire [3:0]                 mm_conv2snap_awregion  ;
  wire [`AXI_AWUSER-1:0]      mm_conv2snap_awuser   ;
  wire                       mm_conv2snap_awvalid   ;
  wire [`AXI_MM_DW-1:0]       mm_conv2snap_wdata    ;
  wire [`AXI_WUSER-1:0]       mm_conv2snap_wuser    ;
  wire [(`AXI_MM_DW/8)-1:0]   mm_conv2snap_wstrb    ;
  wire                       mm_conv2snap_wlast     ;
  wire                       mm_conv2snap_wvalid    ;
  wire                       mm_conv2snap_bready    ;
  wire [`IDW-1:0]             mm_conv2snap_arid      ;
  wire [`AXI_MM_AW-1:0]       mm_conv2snap_araddr    ;
  wire [7:0]                 mm_conv2snap_arlen     ;
  wire [2:0]                 mm_conv2snap_arsize    ;
  wire [1:0]                 mm_conv2snap_arburst   ;
  wire [`AXI_AWUSER-1:0]      mm_conv2snap_aruser    ;
  wire                       mm_conv2snap_arlock    ;
  wire [3:0]                 mm_conv2snap_arcache   ;
  wire [2:0]                 mm_conv2snap_arprot    ;
  wire [3:0]                 mm_conv2snap_arqos     ;
  wire [3:0]                 mm_conv2snap_arregion  ;
  wire                       mm_conv2snap_arvalid   ;
  wire                       mm_conv2snap_rready    ;

  wire                       mm_conv2snap_bready_i    ; // decoupling
  wire                       mm_conv2snap_rready_i    ; // decoupling
  wire                       mm_conv2snap_awvalid_i   ; // decoupling
  wire                       mm_conv2snap_wvalid_i    ; // decoupling
  wire                       mm_conv2snap_arvalid_i   ; // decoupling
`endif
  // // Interface for interrupts
  wire                       int_req_ack     ;
  wire                       int_req         ;
  wire [`INT_BITS-1:0]       int_src         ;
  wire [`CTXW-1:0]           int_ctx         ;
  wire                       int_req_ack_dcpl  ; // decoupling
  wire                       int_req_dcpl      ; // decoupling
  wire [`INT_BITS-1:0]       int_src_dcpl      ; // decoupling
  wire [`CTXW-1:0]           int_ctx_dcpl      ; // decoupling
  wire                       ocde_to_bsp       ; // decoupling

`ifdef ENABLE_ODMA
    `ifndef ENABLE_ODMA_ST_MODE
        wire [`AXI_MM_AW-1:0]       axi_mm_awaddr   ;
        wire [`IDW-1:0]             axi_mm_awid     ;
        wire [7:0]                 axi_mm_awlen    ;
        wire [2:0]                 axi_mm_awsize   ;
        wire [1:0]                 axi_mm_awburst  ;
        wire [2:0]                 axi_mm_awprot   ;
        wire [3:0]                 axi_mm_awqos    ;
        wire [3:0]                 axi_mm_awregion ;
        wire [`AXI_AWUSER-1:0]      axi_mm_awuser   ;
        wire                       axi_mm_awvalid  ;
        wire [1:0]                 axi_mm_awlock   ;
        wire [3:0]                 axi_mm_awcache  ;
        wire                       axi_mm_awready  ;
        wire [`AXI_MM_DW-1:0]       axi_mm_wdata    ;
        wire                       axi_mm_wlast    ;
        wire [`AXI_MM_DW/8-1:0]     axi_mm_wstrb    ;
        wire                       axi_mm_wvalid   ;
        wire [`AXI_WUSER-1:0]       axi_mm_wuser    ;
        wire                       axi_mm_wready   ;
        wire                       axi_mm_bvalid   ;
        wire [1:0]                 axi_mm_bresp    ;
        wire [`IDW-1:0]             axi_mm_bid      ;
        wire [`AXI_BUSER-1:0]       axi_mm_buser    ;
        wire                       axi_mm_bready   ;
        wire [`AXI_MM_AW-1:0]       axi_mm_araddr   ;
        wire [1:0]                 axi_mm_arburst  ;
        wire [3:0]                 axi_mm_arcache  ;
        wire [`IDW-1:0]             axi_mm_arid     ;
        wire [7:0]                 axi_mm_arlen    ;
        wire [1:0]                 axi_mm_arlock   ;
        wire [2:0]                 axi_mm_arprot   ;
        wire [3:0]                 axi_mm_arqos    ;
        wire                       axi_mm_arready  ;
        wire [3:0]                 axi_mm_arregion ;
        wire [2:0]                 axi_mm_arsize   ;
        wire [`AXI_ARUSER-1:0]      axi_mm_aruser   ;
        wire                       axi_mm_arvalid  ;
        wire [`AXI_MM_DW-1:0]       axi_mm_rdata    ;
        wire [`IDW-1:0]             axi_mm_rid      ;
        wire                       axi_mm_rlast    ;
        wire                       axi_mm_rready   ;
        wire [1:0]                 axi_mm_rresp    ;
        wire [`AXI_RUSER-1:0]       axi_mm_ruser    ;
        wire                       axi_mm_rvalid   ;
    `else
        wire                        m_axis_tready    ; 
        wire                        m_axis_tlast     ; 
        wire [`AXI_ST_DW - 1:0]      m_axis_tdata     ; 
        wire [`AXI_ST_DW/8 - 1:0]    m_axis_tkeep     ; 
        wire                        m_axis_tvalid    ; 
        wire [`IDW - 1:0]           m_axis_tid        ; 
        wire [`AXI_ST_USER - 1:0]    m_axis_tuser     ; 
        wire                        s_axis_tready    ; 
        wire                        s_axis_tlast     ; 
        wire [`AXI_ST_DW - 1:0]      s_axis_tdata     ; 
        wire [`AXI_ST_DW/8 - 1:0]    s_axis_tkeep     ; 
        wire                        s_axis_tvalid    ; 
        wire [`IDW - 1:0]           s_axis_tid       ; 
        wire [`AXI_ST_USER - 1:0]    s_axis_tuser     ; 
    `endif
  //
  //ActionAXI-LiteslaveInterface
  wire                       a_s_axi_arvalid ;
  wire [`AXI_LITE_AW-1:0]     a_s_axi_araddr  ;
  wire                       a_s_axi_arready ;
  wire                       a_s_axi_rvalid  ;
  wire [`AXI_LITE_DW-1:0]     a_s_axi_rdata   ;
  wire [1:0]                 a_s_axi_rresp   ;
  wire                       a_s_axi_rready  ;
  wire                       a_s_axi_awvalid ;
  wire [`AXI_LITE_AW-1:0]     a_s_axi_awaddr  ;
  wire                       a_s_axi_awready ;
  wire                       a_s_axi_wvalid  ;
  wire [`AXI_LITE_DW-1:0]     a_s_axi_wdata   ;
  wire [`AXI_LITE_DW/8-1:0]   a_s_axi_wstrb   ;
  wire                       a_s_axi_wready  ;
  wire                       a_s_axi_bvalid  ;
  wire [1:0]                 a_s_axi_bresp   ;
  wire                       a_s_axi_bready  ;
  //ActionAXI-LitemasterInterface
  wire                       a_m_axi_arvalid ;
  wire [`AXI_LITE_AW-1:0]    a_m_axi_araddr  ;
  wire                       a_m_axi_arready ;
  wire                       a_m_axi_rvalid  ;
  wire [`AXI_LITE_DW-1:0]    a_m_axi_rdata   ;
  wire [1:0]                 a_m_axi_rresp   ;
  wire                       a_m_axi_rready  ;
  wire                       a_m_axi_awvalid ;
  wire [`AXI_LITE_AW-1:0]    a_m_axi_awaddr  ;
  wire                       a_m_axi_awready ;
  wire                       a_m_axi_wvalid  ;
  wire [`AXI_LITE_DW-1:0]    a_m_axi_wdata   ;
  wire [`AXI_LITE_DW/8-1:0]  a_m_axi_wstrb   ;
  wire                       a_m_axi_wready  ;
  wire                       a_m_axi_bvalid  ;
  wire [1:0]                 a_m_axi_bresp   ;
  wire                       a_m_axi_bready  ;
`endif

  `ifdef ENABLE_HBM
  wire [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0 ]  act_axi_card_mem0_awaddr    ;
  wire [ 7 : 0 ]                          act_axi_card_mem0_awlen     ;
  wire [ 2 : 0 ]                          act_axi_card_mem0_awsize    ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_awburst   ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_awlock    ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_awcache   ;
  wire [ 2 : 0 ]                          act_axi_card_mem0_awprot    ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_awregion  ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_awqos     ;
  wire                                    act_axi_card_mem0_awvalid   ;
  wire                                    act_axi_card_mem0_awready   ;
  wire [ `AXI_CARD_MEM_DATA_WIDTH-1 : 0 ]  act_axi_card_mem0_wdata     ;
  wire [(`AXI_CARD_MEM_DATA_WIDTH/8)-1 : 0] act_axi_card_mem0_wstrb     ;
  wire                                    act_axi_card_mem0_wlast     ;
  wire                                    act_axi_card_mem0_wvalid    ;
  wire                                    act_axi_card_mem0_wready    ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_bresp     ;
  wire                                    act_axi_card_mem0_bvalid    ;
  wire                                    act_axi_card_mem0_bready    ;
  wire [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0 ]  act_axi_card_mem0_araddr    ;
  wire [ 7 : 0 ]                          act_axi_card_mem0_arlen     ;
  wire [ 2 : 0 ]                          act_axi_card_mem0_arsize    ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_arburst   ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_arlock    ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_arcache   ;
  wire [ 2 : 0 ]                          act_axi_card_mem0_arprot    ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_arregion  ;
  wire [ 3 : 0 ]                          act_axi_card_mem0_arqos     ;
  wire                                    act_axi_card_mem0_arvalid   ;
  wire                                    act_axi_card_mem0_arready   ;
  wire [ `AXI_CARD_MEM_DATA_WIDTH-1 : 0 ]  act_axi_card_mem0_rdata     ;
  wire [ 1 : 0 ]                          act_axi_card_mem0_rresp     ;
  wire                                    act_axi_card_mem0_rlast     ;
  wire                                    act_axi_card_mem0_rvalid    ;
  wire                                    act_axi_card_mem0_rready    ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    act_axi_card_mem0_arid      ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    act_axi_card_mem0_awid      ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    act_axi_card_mem0_bid       ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    act_axi_card_mem0_rid       ;

  //wire                                      clock_hbm_ref               ;
  wire                                      act_axi_card_mem0_apb_pclk               ;
  `endif

// if DDR on AD9V3 (No BRAM)
`ifdef ENABLE_DDR
  `ifdef AD9V3
  wire            ddr4_dbg_clk                   ;
  wire [511 : 0]  ddr4_dbg_bus                   ;
  wire            memctl0_ui_clk_sync_rst        ; //reset generated from DDR MIG
  `endif
  `ifdef BW250SOC
  wire            ddr4_dbg_clk                   ;
  wire [511 : 0]  ddr4_dbg_bus                   ;
  wire            memctl0_ui_clk_sync_rst        ; //reset generated from DDR MIG
  `endif

`endif


  // // Interface to AFU Descriptor table (interface is Read Only)
  wire [24*8-1:0] ro_name_space                       ;
  wire      [7:0] ro_afu_version_major                ;
  wire      [7:0] ro_afu_version_minor                ;
  wire      [2:0] ro_afuc_type                        ;
  wire      [2:0] ro_afum_type                        ;
  wire      [7:0] ro_profile                          ;
  wire    [63:16] ro_global_mmio_offset               ;
  wire      [2:0] ro_global_mmio_bar                  ;
  wire     [31:0] ro_global_mmio_size                 ;
  wire            ro_cmd_flag_x1_supported            ;
  wire            ro_cmd_flag_x3_supported            ;
  wire            ro_atc_2M_page_supported            ;
  wire            ro_atc_64K_page_supported           ;
  wire      [4:0] ro_max_host_tag_size                ;
  wire    [63:16] ro_per_pasid_mmio_offset            ;
  wire      [2:0] ro_per_pasid_mmio_bar               ;
  wire    [31:16] ro_per_pasid_mmio_stride            ;
  wire      [7:0] ro_mem_size                         ;
  wire     [63:0] ro_mem_start_addr                   ;
  wire    [127:0] ro_naa_wwid                         ;
  wire     [63:0] ro_system_memory_length             ;

  // // ******************************************************************************
  // // Reset signals
  // // ******************************************************************************
  // Source 1: from input
  wire input_reset_d;
  reg input_reset_q;
  assign input_reset_d = reset; 
  always @ (posedge clock_afu)
    begin
      input_reset_q <= input_reset_d;
    end

  // Source 2: from VIO
  wire vio_reset_action;
  wire vio_reset_snap;
  //vio_soft_reset  mvio_soft_reset
  //  (
  //    .clk        ( clock_afu),
  //    .probe_out0 ( vio_reset_snap),
  //    .probe_out1 ( vio_reset_action)
  //  );  
  // mvio_soft_reset replaced by the following 2 assignments
  assign vio_reset_action = 1'b0; 
  assign vio_reset_snap = 1'b0; 

  // Source 3: from MMIO_register
  wire soft_reset_action;
  wire soft_decouple_action;


  //----------------------------------
  // Connections
  // To snap_core      (sampled by clock_afu)
  reg reset_snap_q;     
  always @ (posedge clock_afu)
        reset_snap_q <= input_reset_q || vio_reset_snap;

 // To action_wrapper (sampled by clock_act)
  wire reset_action_d;
  assign reset_action_d = input_reset_q || vio_reset_action || soft_reset_action;



  // To mem controllers (sampled by clock_afu)
  // To Action attached converters


  // // ******************************************************************************
  // // AFU DESCRIPTOR TIES
  // // ******************************************************************************

  assign  ro_name_space[191:0]            =  { "IBM,oc-snap", { 13{8'h00} } };    // // Keep this string EXACTLY 24 characters long   // AFP3.0
  assign  ro_afu_version_major[7:0]       =    8'h01;
  assign  ro_afu_version_minor[7:0]       =    8'h01;
  assign  ro_afuc_type[2:0]               =    3'b001;                            // // Type C1 issues commands to the host (i.e. interrupts) but does not cache host data
  assign  ro_afum_type[2:0]               =    3'b001;                            // // Type M1 contains host mapped address space, which could be MMIO or memory
  assign  ro_profile[7:0]                 =    8'h01;                             // // Device Interface Class (see AFU documentation for additional command restrictions)
  assign  ro_global_mmio_offset[63:16]    =   48'h0000_0000_0000;                 // // MMIO space starts at BAR 0 address  
  assign  ro_global_mmio_bar[2:0]         =    3'b0;
  assign  ro_global_mmio_size[31:0]       =   32'h8000_0000;                      // // 2GB
  assign  ro_cmd_flag_x1_supported        =    1'b0;                              // // cmd_flag x1 is not supported
  assign  ro_cmd_flag_x3_supported        =    1'b0;                              // // cmd_flag x3 is not supported
  assign  ro_atc_2M_page_supported        =    1'b0;                              // // Address Translation Cache page size of 2MB is not supported
  assign  ro_atc_64K_page_supported       =    1'b0;                              // // Address Translation Cache page size of 64KB is not supported
  assign  ro_max_host_tag_size[4:0]       =    5'b00000;                          // // Caching is not supported
  assign  ro_per_pasid_mmio_offset[63:16] =   48'h0000_0000_8000;                 // // Per Process PASID space starts at BAR 0 + 2GB address
  assign  ro_per_pasid_mmio_bar[2:0]      =    3'b0;
  assign  ro_per_pasid_mmio_stride[31:16] =   16'h0040;                           // // Stride is 4MB per PASID entry
  assign  ro_mem_size[7:0]                =    8'h00;                             // // 64MB MMIO size (64MB = 2^26, 26 decimal = x1A). Set to 0 when no LPC memory space in AFU
  assign  ro_mem_start_addr[63:0]         =   64'h0000_0000_0000_0000;            // // At Device level, Memory Space must start at addr 0
  assign  ro_naa_wwid[127:0]              =  128'b0;                              // // Default is AFU has no WWID
  assign  ro_system_memory_length         =   64'b0;                              // // General Purpose System Memory Size, [15:0] forced to h0000 to align with 64 KB boundary

  // // ******************************************************************************
  // // CFG DESCRIPTOR
  // // ******************************************************************************

  cfg_descriptor  desc
    (
      // // Miscellaneous Ports
      .clock                                       ( clock_tlx                       ) , // input
      .reset                                       ( input_reset_q                   ) , // input

      .ro_name_space                               ( ro_name_space[24*8-1:0]         ) , // input
      .ro_afu_version_major                        ( ro_afu_version_major[7:0]       ) , // input
      .ro_afu_version_minor                        ( ro_afu_version_minor[7:0]       ) , // input
      .ro_afuc_type                                ( ro_afuc_type[2:0]               ) , // input
      .ro_afum_type                                ( ro_afum_type[2:0]               ) , // input
      .ro_profile                                  ( ro_profile[7:0]                 ) , // input
      .ro_global_mmio_offset                       ( ro_global_mmio_offset[63:16]    ) , // input
      .ro_global_mmio_bar                          ( ro_global_mmio_bar[2:0]         ) , // input
      .ro_global_mmio_size                         ( ro_global_mmio_size[31:0]       ) , // input
      .ro_cmd_flag_x1_supported                    ( ro_cmd_flag_x1_supported        ) , // input
      .ro_cmd_flag_x3_supported                    ( ro_cmd_flag_x3_supported        ) , // input
      .ro_atc_2M_page_supported                    ( ro_atc_2M_page_supported        ) , // input
      .ro_atc_64K_page_supported                   ( ro_atc_64K_page_supported       ) , // input
      .ro_max_host_tag_size                        ( ro_max_host_tag_size[4:0]       ) , // input
      .ro_per_pasid_mmio_offset                    ( ro_per_pasid_mmio_offset[63:16] ) , // input
      .ro_per_pasid_mmio_bar                       ( ro_per_pasid_mmio_bar[2:0]      ) , // input
      .ro_per_pasid_mmio_stride                    ( ro_per_pasid_mmio_stride[31:16] ) , // input
      .ro_mem_size                                 ( ro_mem_size[7:0]                ) , // input
      .ro_mem_start_addr                           ( ro_mem_start_addr[63:0]         ) , // input
      .ro_naa_wwid                                 ( ro_naa_wwid[127:0]              ) , // input
      .ro_system_memory_length                     ( ro_system_memory_length[63:0]   ) , // input


      .ro_afu_index                                ( afu_index[5:0]                  ) , // input

      // // Functional interface
      .cfg_desc_cmd_valid                          ( cfg_desc_cmd_valid              ) , // input
      .cfg_desc_afu_index                          ( cfg_desc_afu_index[5:0]         ) , // input
      .cfg_desc_offset                             ( cfg_desc_offset[30:0]           ) , // input

      .desc_cfg_data_valid                         ( desc_cfg_data_valid             ) , // output
      .desc_cfg_data                               ( desc_cfg_data[31:0]             ) , // output
      .desc_cfg_echo_cmd_valid                     ( desc_cfg_echo_cmd_valid         ) , // output

      // // Error indicator
      .err_unimplemented_addr                      ( vpd_err_unimplemented_addr          ) // // output

    );


  // // ******************************************************************************
  // // oc_snap_core
  // // ******************************************************************************


   oc_snap_core snap_core_i (
      //
      // Clocks & Reset
      .clock_tlx                          ( clock_tlx                        ) ,
      .clock_afu                          ( clock_afu                        ) ,
      .reset_snap                         ( reset_snap_q                     ) ,//input

      // Configuration
      .cfg_backoff_timer                  ( cfg_f0_otl0_long_backoff_timer   ) ,
      .cfg_bdf_bus                        ( cfg_afu_bdf_bus                  ) ,
      .cfg_bdf_device                     ( cfg_afu_bdf_device               ) ,
      .cfg_bdf_function                   ( cfg_afu_bdf_function             ) ,
      .cfg_actag_base                     ( cfg_octrl00_afu_actag_base       ) ,
      .cfg_pasid_base                     ( cfg_octrl00_pasid_base           ) ,
      .cfg_pasid_length                   ( cfg_octrl00_pasid_length_enabled ) ,
      .cfg_f1_mmio_bar0                   ( cfg_csh_mmio_bar0                ) ,
      .cfg_f1_mmio_bar0_mask              ( 64'hFFFF_FFFF_0000_0000          ) ,//FIXME this should be bar0_size but doesn't link

      // AFU-TLX command transmit interface
      .afu_tlx_cmd_valid                  ( afu_tlx_cmd_valid                ) ,
      .afu_tlx_cmd_opcode                 ( afu_tlx_cmd_opcode               ) ,
      .afu_tlx_cmd_actag                  ( afu_tlx_cmd_actag                ) ,
      .afu_tlx_cmd_stream_id              ( afu_tlx_cmd_stream_id            ) ,
      .afu_tlx_cmd_ea_or_obj              ( afu_tlx_cmd_ea_or_obj            ) ,
      .afu_tlx_cmd_afutag                 ( afu_tlx_cmd_afutag               ) ,
      .afu_tlx_cmd_dl                     ( afu_tlx_cmd_dl                   ) ,
      .afu_tlx_cmd_pl                     ( afu_tlx_cmd_pl                   ) ,
      .afu_tlx_cmd_os                     ( afu_tlx_cmd_os                   ) ,
      .afu_tlx_cmd_be                     ( afu_tlx_cmd_be                   ) ,
      .afu_tlx_cmd_flag                   ( afu_tlx_cmd_flag                 ) ,
      .afu_tlx_cmd_endian                 ( afu_tlx_cmd_endian               ) ,
      .afu_tlx_cmd_bdf                    ( afu_tlx_cmd_bdf                  ) ,
      .afu_tlx_cmd_pasid                  ( afu_tlx_cmd_pasid                ) ,
      .afu_tlx_cmd_pg_size                ( afu_tlx_cmd_pg_size              ) ,
      .afu_tlx_cdata_valid                ( afu_tlx_cdata_valid              ) ,
      .afu_tlx_cdata_bdi                  ( afu_tlx_cdata_bdi                ) ,
      .afu_tlx_cdata_bus                  ( afu_tlx_cdata_bus                ) ,
      .tlx_afu_cmd_credit                 ( tlx_afu_cmd_credit               ) ,
      .tlx_afu_cmd_data_credit            ( tlx_afu_cmd_data_credit          ) ,
      .tlx_afu_cmd_initial_credit         ( tlx_afu_cmd_initial_credit       ) ,
      .tlx_afu_cmd_data_initial_credit    ( tlx_afu_cmd_data_initial_credit  ) ,
      //
      // TLX-AFU response receive interface
      .tlx_afu_resp_valid                 ( tlx_afu_resp_valid               ) ,
      .tlx_afu_resp_opcode                ( tlx_afu_resp_opcode              ) ,
      .tlx_afu_resp_afutag                ( tlx_afu_resp_afutag              ) ,
      .tlx_afu_resp_code                  ( tlx_afu_resp_code                ) ,
      .tlx_afu_resp_dl                    ( tlx_afu_resp_dl                  ) ,
      .tlx_afu_resp_dp                    ( tlx_afu_resp_dp                  ) ,
      .afu_tlx_resp_rd_req                ( afu_tlx_resp_rd_req              ) ,
      .afu_tlx_resp_rd_cnt                ( afu_tlx_resp_rd_cnt              ) ,
      .tlx_afu_resp_data_valid            ( tlx_afu_resp_data_valid          ) ,
      .tlx_afu_resp_data_bdi              ( tlx_afu_resp_data_bdi            ) ,
      .tlx_afu_resp_data_bus              ( tlx_afu_resp_data_bus            ) ,
      .afu_tlx_resp_credit                ( afu_tlx_resp_credit              ) ,
      .afu_tlx_resp_initial_credit        ( afu_tlx_resp_initial_credit      ) ,
      //
      // TLX-AFU command receive interface
      .tlx_afu_cmd_valid                  ( tlx_afu_cmd_valid                ) ,
      .tlx_afu_cmd_opcode                 ( tlx_afu_cmd_opcode               ) ,
      .tlx_afu_cmd_capptag                ( tlx_afu_cmd_capptag              ) ,
      .tlx_afu_cmd_dl                     ( tlx_afu_cmd_dl                   ) ,
      .tlx_afu_cmd_pl                     ( tlx_afu_cmd_pl                   ) ,
      .tlx_afu_cmd_be                     ( tlx_afu_cmd_be                   ) ,
      .tlx_afu_cmd_end                    ( tlx_afu_cmd_end                  ) ,
      .tlx_afu_cmd_pa                     ( tlx_afu_cmd_pa                   ) ,
      .tlx_afu_cmd_flag                   ( tlx_afu_cmd_flag                 ) ,
      .tlx_afu_cmd_os                     ( tlx_afu_cmd_os                   ) ,
      .afu_tlx_cmd_credit                 ( afu_tlx_cmd_credit               ) ,
      .afu_tlx_cmd_initial_credit         ( afu_tlx_cmd_initial_credit       ) ,
      .afu_tlx_cmd_rd_req                 ( afu_tlx_cmd_rd_req               ) ,
      .afu_tlx_cmd_rd_cnt                 ( afu_tlx_cmd_rd_cnt               ) ,
      .tlx_afu_cmd_data_valid             ( tlx_afu_cmd_data_valid           ) ,
      .tlx_afu_cmd_data_bdi               ( tlx_afu_cmd_data_bdi             ) ,
      .tlx_afu_cmd_data_bus               ( tlx_afu_cmd_data_bus             ) ,
      //
      // AFU-TLX response transmit interface
      .afu_tlx_resp_valid                 ( afu_tlx_resp_valid               ) ,
      .afu_tlx_resp_opcode                ( afu_tlx_resp_opcode              ) ,
      .afu_tlx_resp_dl                    ( afu_tlx_resp_dl                  ) ,
      .afu_tlx_resp_capptag               ( afu_tlx_resp_capptag             ) ,
      .afu_tlx_resp_dp                    ( afu_tlx_resp_dp                  ) ,
      .afu_tlx_resp_code                  ( afu_tlx_resp_code                ) ,
      .afu_tlx_rdata_valid                ( afu_tlx_rdata_valid              ) ,
      .afu_tlx_rdata_bdi                  ( afu_tlx_rdata_bdi                ) ,
      .afu_tlx_rdata_bus                  ( afu_tlx_rdata_bus                ) ,
      .tlx_afu_resp_credit                ( tlx_afu_resp_credit              ) ,
      .tlx_afu_resp_data_credit           ( tlx_afu_resp_data_credit         ) ,
      .tlx_afu_resp_initial_credit        ( tlx_afu_resp_initial_credit      ) ,
      .tlx_afu_resp_data_initial_credit   ( tlx_afu_resp_data_initial_credit ) ,
      //
      // ACTION Interface
      //
      // misc
      .soft_reset_action                ( soft_reset_action               ) ,//output
      .soft_decouple_action             ( soft_decouple_action            ) ,//output      


`ifndef ENABLE_ODMA
      .lite_snap2conv_awaddr            (lite_snap2conv_awaddr            ), // output
      .lite_snap2conv_awprot            (lite_snap2conv_awprot            ),
      .lite_snap2conv_awvalid           (lite_snap2conv_awvalid           ),
      .lite_snap2conv_wdata             (lite_snap2conv_wdata             ),
      .lite_snap2conv_wstrb             (lite_snap2conv_wstrb             ),
      .lite_snap2conv_wvalid            (lite_snap2conv_wvalid            ),
      .lite_snap2conv_bready            (lite_snap2conv_bready            ),
      .lite_snap2conv_araddr            (lite_snap2conv_araddr            ),
      .lite_snap2conv_arprot            (lite_snap2conv_arprot            ),
      .lite_snap2conv_arvalid           (lite_snap2conv_arvalid           ),
      .lite_snap2conv_rready            (lite_snap2conv_rready            ),


      .lite_conv2snap_awready           (lite_conv2snap_awready           ), // input
      .lite_conv2snap_wready            (lite_conv2snap_wready            ),
      .lite_conv2snap_bresp             (lite_conv2snap_bresp             ),
      .lite_conv2snap_bvalid            (lite_conv2snap_bvalid            ),
      .lite_conv2snap_arready           (lite_conv2snap_arready           ),
      .lite_conv2snap_rdata             (lite_conv2snap_rdata             ),
      .lite_conv2snap_rresp             (lite_conv2snap_rresp             ),
      .lite_conv2snap_rvalid            (lite_conv2snap_rvalid            ),

      .mm_snap2conv_awready             (mm_snap2conv_awready             ), // output
      .mm_snap2conv_wready              (mm_snap2conv_wready              ),
      .mm_snap2conv_bid                 (mm_snap2conv_bid                 ),
      .mm_snap2conv_bresp               (mm_snap2conv_bresp               ),
      .mm_snap2conv_buser               (mm_snap2conv_buser               ),
      .mm_snap2conv_bvalid              (mm_snap2conv_bvalid              ),
      .mm_snap2conv_rid                 (mm_snap2conv_rid                 ),
      .mm_snap2conv_rdata               (mm_snap2conv_rdata               ),
      .mm_snap2conv_rresp               (mm_snap2conv_rresp               ),
      .mm_snap2conv_rlast               (mm_snap2conv_rlast               ),
      .mm_snap2conv_rvalid              (mm_snap2conv_rvalid              ),
      .mm_snap2conv_ruser               (mm_snap2conv_ruser               ),
      .mm_snap2conv_arready             (mm_snap2conv_arready             ),


      .mm_conv2snap_awid                (mm_conv2snap_awid                ), // input
      .mm_conv2snap_awaddr              (mm_conv2snap_awaddr              ),
      .mm_conv2snap_awlen               (mm_conv2snap_awlen               ),
      .mm_conv2snap_awsize              (mm_conv2snap_awsize              ),
      .mm_conv2snap_awburst             (mm_conv2snap_awburst             ),
      .mm_conv2snap_awlock              (mm_conv2snap_awlock              ),
      .mm_conv2snap_awcache             (mm_conv2snap_awcache             ),
      .mm_conv2snap_awprot              (mm_conv2snap_awprot              ),
      .mm_conv2snap_awqos               (mm_conv2snap_awqos               ),
      .mm_conv2snap_awregion            (mm_conv2snap_awregion            ),
      .mm_conv2snap_awuser              (mm_conv2snap_awuser              ),
      .mm_conv2snap_awvalid             (mm_conv2snap_awvalid             ),
      .mm_conv2snap_wdata               (mm_conv2snap_wdata               ),
      .mm_conv2snap_wstrb               (mm_conv2snap_wstrb               ),
      .mm_conv2snap_wlast               (mm_conv2snap_wlast               ),
      .mm_conv2snap_wvalid              (mm_conv2snap_wvalid              ),
      .mm_conv2snap_bready              (mm_conv2snap_bready              ),
      .mm_conv2snap_arid                (mm_conv2snap_arid                ),
      .mm_conv2snap_araddr              (mm_conv2snap_araddr              ),
      .mm_conv2snap_arlen               (mm_conv2snap_arlen               ),
      .mm_conv2snap_arsize              (mm_conv2snap_arsize              ),
      .mm_conv2snap_arburst             (mm_conv2snap_arburst             ),
      .mm_conv2snap_aruser              (mm_conv2snap_aruser              ),
      .mm_conv2snap_arlock              (mm_conv2snap_arlock              ),
      .mm_conv2snap_arcache             (mm_conv2snap_arcache             ),
      .mm_conv2snap_arprot              (mm_conv2snap_arprot              ),
      .mm_conv2snap_arqos               (mm_conv2snap_arqos               ),
      .mm_conv2snap_arregion            (mm_conv2snap_arregion            ),
      .mm_conv2snap_arvalid             (mm_conv2snap_arvalid             ),
      .mm_conv2snap_rready              (mm_conv2snap_rready              ),

      .int_req_ack                      (int_req_ack                      ), // output
      .int_req                          (int_req                          ), // input
      .int_src                          (int_src                          ), // input
      .int_ctx                          (int_ctx                          )  // input

`else
      // ODMA mode: AXI4-MM Interface to action
   `ifndef ENABLE_ODMA_ST_MODE
      .axi_mm_awaddr                      ( axi_mm_awaddr  ),
      .axi_mm_awid                        ( axi_mm_awid    ),
      .axi_mm_awlen                       ( axi_mm_awlen   ),
      .axi_mm_awsize                      ( axi_mm_awsize  ),
      .axi_mm_awburst                     ( axi_mm_awburst ),
      .axi_mm_awprot                      ( axi_mm_awprot  ),
      .axi_mm_awqos                       ( axi_mm_awqos   ),
      .axi_mm_awregion                    ( axi_mm_awregion),
      .axi_mm_awuser                      ( axi_mm_awuser  ),
      .axi_mm_awvalid                     ( axi_mm_awvalid ),
      .axi_mm_awlock                      ( axi_mm_awlock  ),
      .axi_mm_awcache                     ( axi_mm_awcache ),
      .axi_mm_awready                     ( axi_mm_awready ),
      .axi_mm_wdata                       ( axi_mm_wdata   ),
      .axi_mm_wlast                       ( axi_mm_wlast   ),
      .axi_mm_wstrb                       ( axi_mm_wstrb   ),
      .axi_mm_wvalid                      ( axi_mm_wvalid  ),
      .axi_mm_wuser                       ( axi_mm_wuser   ),
      .axi_mm_wready                      ( axi_mm_wready  ),
      .axi_mm_bvalid                      ( axi_mm_bvalid  ),
      .axi_mm_bresp                       ( axi_mm_bresp   ),
      .axi_mm_bid                         ( axi_mm_bid     ),
      .axi_mm_buser                       ( axi_mm_buser   ),
      .axi_mm_bready                      ( axi_mm_bready  ),
      .axi_mm_araddr                      ( axi_mm_araddr  ),
      .axi_mm_arburst                     ( axi_mm_arburst ),
      .axi_mm_arcache                     ( axi_mm_arcache ),
      .axi_mm_arid                        ( axi_mm_arid    ),
      .axi_mm_arlen                       ( axi_mm_arlen   ),
      .axi_mm_arlock                      ( axi_mm_arlock  ),
      .axi_mm_arprot                      ( axi_mm_arprot  ),
      .axi_mm_arqos                       ( axi_mm_arqos   ),
      .axi_mm_arready                     ( axi_mm_arready ),
      .axi_mm_arregion                    ( axi_mm_arregion),
      .axi_mm_arsize                      ( axi_mm_arsize  ),
      .axi_mm_aruser                      ( axi_mm_aruser  ),
      .axi_mm_arvalid                     ( axi_mm_arvalid ),
      .axi_mm_rdata                       ( axi_mm_rdata   ),
      .axi_mm_rid                         ( axi_mm_rid     ),
      .axi_mm_rlast                       ( axi_mm_rlast   ),
      .axi_mm_rready                      ( axi_mm_rready  ),
      .axi_mm_rresp                       ( axi_mm_rresp   ),
      .axi_mm_ruser                       ( axi_mm_ruser   ),
      .axi_mm_rvalid                      ( axi_mm_rvalid  ),
   `else
      .m_axis_tready                      ( m_axis_tready  ),
      .m_axis_tlast                       ( m_axis_tlast   ),
      .m_axis_tdata                       ( m_axis_tdata   ),
      .m_axis_tkeep                       ( m_axis_tkeep   ),
      .m_axis_tvalid                      ( m_axis_tvalid  ),
      .m_axis_tid                         ( m_axis_tid     ),
      .m_axis_tuser                       ( m_axis_tuser   ),
      .s_axis_tready                      ( s_axis_tready  ),
      .s_axis_tlast                       ( s_axis_tlast   ),
      .s_axis_tdata                       ( s_axis_tdata   ),
      .s_axis_tkeep                       ( s_axis_tkeep   ),
      .s_axis_tvalid                      ( s_axis_tvalid  ),
      .s_axis_tid                         ( s_axis_tid   ),
      .s_axis_tuser                       ( s_axis_tuser   ),
   `endif 
      // To Action: AXI_Lite Slave Interface
      .a_s_axi_arvalid                    ( a_s_axi_arvalid ),
      .a_s_axi_araddr                     ( a_s_axi_araddr  ),
      .a_s_axi_arready                    ( a_s_axi_arready ),
      .a_s_axi_rvalid                     ( a_s_axi_rvalid  ),
      .a_s_axi_rdata                      ( a_s_axi_rdata   ),
      .a_s_axi_rresp                      ( a_s_axi_rresp   ),
      .a_s_axi_rready                     ( a_s_axi_rready  ),
      .a_s_axi_awvalid                    ( a_s_axi_awvalid ),
      .a_s_axi_awaddr                     ( a_s_axi_awaddr  ),
      .a_s_axi_awready                    ( a_s_axi_awready ),
      .a_s_axi_wvalid                     ( a_s_axi_wvalid  ),
      .a_s_axi_wdata                      ( a_s_axi_wdata   ),
      .a_s_axi_wstrb                      ( a_s_axi_wstrb   ),
      .a_s_axi_wready                     ( a_s_axi_wready  ),
      .a_s_axi_bvalid                     ( a_s_axi_bvalid  ),
      .a_s_axi_bresp                      ( a_s_axi_bresp   ),
      .a_s_axi_bready                     ( a_s_axi_bready  ),
      // To Action: AXI_Lite Master Interface
      .a_m_axi_arvalid                    ( a_m_axi_arvalid), 
      .a_m_axi_araddr                     ( a_m_axi_araddr ), 
      .a_m_axi_arready                    ( a_m_axi_arready), 
      .a_m_axi_rvalid                     ( a_m_axi_rvalid ), 
      .a_m_axi_rdata                      ( a_m_axi_rdata  ), 
      .a_m_axi_rresp                      ( a_m_axi_rresp  ), 
      .a_m_axi_rready                     ( a_m_axi_rready ), 
      .a_m_axi_awvalid                    ( a_m_axi_awvalid), 
      .a_m_axi_awaddr                     ( a_m_axi_awaddr ), 
      .a_m_axi_awready                    ( a_m_axi_awready), 
      .a_m_axi_wvalid                     ( a_m_axi_wvalid ), 
      .a_m_axi_wdata                      ( a_m_axi_wdata  ), 
      .a_m_axi_wstrb                      ( a_m_axi_wstrb  ), 
      .a_m_axi_wready                     ( a_m_axi_wready ), 
      .a_m_axi_bvalid                     ( a_m_axi_bvalid ), 
      .a_m_axi_bresp                      ( a_m_axi_bresp  ), 
      .a_m_axi_bready                     ( a_m_axi_bready ) 
`endif
    );  // snap_core_i: snap_core


`ifndef ENABLE_ODMA
// ---------------------------------------------------------------------------------
// Match one master to two slaves
// ---------------------------------------------------------------------------------
// MMIO is master and allows to access ACTION or ICAP
// ACTION is accessed from 0x000 to 0x1FF - to access ACTION @104 => access MMIO @104
// ICAP   is accessed from 0xE00 to 0xFFF - to access   ICAP @104 => access MMIO @F04

reg                    reg_lite_conv2snap_awready;
reg                    reg_lite_conv2snap_wready;
reg  [1:0]             reg_lite_conv2snap_bresp;
reg                    reg_lite_conv2snap_bvalid;
reg                    reg_lite_conv2snap_arready;
reg  [1:0]             reg_lite_conv2snap_rresp;
reg                    reg_lite_conv2snap_rvalid;
reg [`AXI_LITE_AW-1:0] reg_lite_conv2snap_rdata;

wire                    lite_action2snap_awready;
wire                    lite_action2snap_wready;
wire [0:1]              lite_action2snap_bresp;
wire                    lite_action2snap_bvalid;
wire                    lite_action2snap_arready;
wire [1:0]              lite_action2snap_rresp;
wire [`AXI_LITE_AW-1:0] lite_action2snap_rdata;
wire                    lite_action2snap_rvalid;
wire [`AXI_LITE_AW-1:0] ZERO_VEC = `AXI_LITE_AW'd0;

wire [`AXI_LITE_AW-1:0] lite_snap2action_awaddr;
wire [2:0]              lite_snap2action_awprot;
wire                    lite_snap2action_awvalid;
wire [`AXI_LITE_DW-1:0] lite_snap2action_wdata;
wire [3:0]              lite_snap2action_wstrb;
wire                    lite_snap2action_wvalid;
wire                    lite_snap2action_bready;
wire [`AXI_LITE_AW-1:0] lite_snap2action_araddr;
wire [2:0]              lite_snap2action_arprot;
wire                    lite_snap2action_arvalid;
wire                    lite_snap2action_rready;

(* mark_debug = "TRUE" *) reg decouple_action;

 always @(posedge(clock_tlx)) 
   if (soft_decouple_action == 1'b1)
      decouple_action <= 1'b1;
   else
      decouple_action <= decouple;
      
      
`ifdef ENABLE_PRFLOW
wire [`AXI_LITE_AW-1:0]   reg_lite_snap2icap_awaddr;
wire [2:0]                reg_lite_snap2icap_awprot;
wire                      reg_lite_snap2icap_awvalid;
wire [`AXI_LITE_DW-1:0]   reg_lite_snap2icap_wdata;
wire [3:0]                reg_lite_snap2icap_wstrb;
wire                      reg_lite_snap2icap_wvalid;
wire                      reg_lite_snap2icap_bready;
wire [`AXI_LITE_AW-1:0]   reg_lite_snap2icap_araddr;
wire [2:0]                reg_lite_snap2icap_arprot;
wire                      reg_lite_snap2icap_arvalid;
wire                      reg_lite_snap2icap_rready;

wire                      reg_lite_icap2snap_awready;
wire                      reg_lite_icap2snap_wready;
wire [1:0]                reg_lite_icap2snap_bresp;
wire                      reg_lite_icap2snap_bvalid;
wire                      reg_lite_icap2snap_arready;
wire [`AXI_LITE_DW-1:0]   reg_lite_icap2snap_rdata;
wire [1:0]                reg_lite_icap2snap_rresp;
wire                      reg_lite_icap2snap_rvalid;


(* mark_debug = "TRUE" *) wire select_icap;

 // user registers from 0x0 to 0x1F - use ICAP above (from 0x20 to 0xEF) => 3MSB set to "111"
 assign select_icap = soft_decouple_action;
            
//To ICAP
assign reg_lite_snap2icap_awaddr[`AXI_LITE_AW-1:0]  = (select_icap == 1'b1) ? {20'b00000000000000000000, lite_snap2conv_awaddr[11:0]}  :  ZERO_VEC;
assign reg_lite_snap2icap_awprot[2:0]               = lite_snap2conv_awprot[2:0]  ;
assign reg_lite_snap2icap_awvalid                   = (select_icap == 1'b1) ? lite_snap2conv_awvalid : 1'b0;
assign reg_lite_snap2icap_wdata[`AXI_LITE_DW-1:0]   = lite_snap2conv_wdata[`AXI_LITE_DW-1:0]        ;
assign reg_lite_snap2icap_wstrb[3:0]                = lite_snap2conv_wstrb[3:0]             ;
assign reg_lite_snap2icap_wvalid                    = (select_icap == 1'b1) ? lite_snap2conv_wvalid  : 1'b0;
assign reg_lite_snap2icap_bready                    = lite_snap2conv_bready         ;
assign reg_lite_snap2icap_araddr[`AXI_LITE_AW-1:0]  = (select_icap == 1'b1) ? {20'b00000000000000000000, lite_snap2conv_araddr[11:0]} :  ZERO_VEC;
assign reg_lite_snap2icap_arprot[2:0]               = lite_snap2conv_arprot[2:0]         ;
assign reg_lite_snap2icap_arvalid                   = (select_icap == 1'b1) ? lite_snap2conv_arvalid : 1'b0;
assign reg_lite_snap2icap_rready                    = lite_snap2conv_rready           ;

// Signals from ICAP or ACTION to SNAP logic 
always @(*)  // conv2snap means signals from Action to snap logic
  case (select_icap)
    1'b0: begin  //ACTION
             reg_lite_conv2snap_awready = (~decouple_action) & lite_action2snap_awready;
             reg_lite_conv2snap_wready  = (~decouple_action) & lite_action2snap_wready;
             reg_lite_conv2snap_bresp   = {2{lite_action2snap_bresp}};
             reg_lite_conv2snap_bvalid  = (~decouple_action) & lite_action2snap_bvalid;
             reg_lite_conv2snap_arready = (~decouple_action) & lite_action2snap_arready;
             reg_lite_conv2snap_rdata   = lite_action2snap_rdata;
             reg_lite_conv2snap_rresp   = {2{lite_action2snap_rresp}};
             reg_lite_conv2snap_rvalid  = (~decouple_action) & lite_action2snap_rvalid;
            end
    1'b1: begin //ICAP
             reg_lite_conv2snap_awready = reg_lite_icap2snap_awready;
             reg_lite_conv2snap_wready  = reg_lite_icap2snap_wready;
             reg_lite_conv2snap_bresp   = {2{reg_lite_icap2snap_bresp}};
             reg_lite_conv2snap_bvalid  = reg_lite_icap2snap_bvalid;
             reg_lite_conv2snap_arready = reg_lite_icap2snap_arready;
             reg_lite_conv2snap_rdata   = reg_lite_icap2snap_rdata;
             reg_lite_conv2snap_rresp   = {2{reg_lite_icap2snap_rresp}};
             reg_lite_conv2snap_rvalid  = reg_lite_icap2snap_rvalid;
           end
    default: begin
             reg_lite_conv2snap_awready = 1'b1;
             reg_lite_conv2snap_wready  = 1'b1;
             reg_lite_conv2snap_bresp   = 2'b11;   // DECode ERRor
             reg_lite_conv2snap_bvalid  = 1'b0;
             reg_lite_conv2snap_arready = 1'b1;
             reg_lite_conv2snap_rdata   = 32'h0000_0000;
             reg_lite_conv2snap_rresp   = 2'b00;
             reg_lite_conv2snap_rvalid  = 1'b0;
           end
  endcase
  

// Clock conversion for signals going from here to ICAP which is in TLX clock domain
axi_clock_converter_icapusr clkconverter_icapusr (
  .s_axi_aclk     (clock_afu                       ),        // input wire s_axi_aclk
  .s_axi_aresetn  (~input_reset_q              ),  // input wire s_axi_aresetn
  
  .s_axi_awaddr   (reg_lite_snap2icap_awaddr  ),    // input wire [31 : 0] s_axi_awaddr
  .s_axi_awprot   (reg_lite_snap2icap_awprot  ),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid  (reg_lite_snap2icap_awvalid ),  // input wire s_axi_awvalid
  .s_axi_awready  (reg_lite_icap2snap_awready ),  // output wire s_axi_awready
  .s_axi_wdata    (reg_lite_snap2icap_wdata   ),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb    (reg_lite_snap2icap_wstrb   ),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid   (reg_lite_snap2icap_wvalid  ),    // input wire s_axi_wvalid
  .s_axi_wready   (reg_lite_icap2snap_wready  ),    // output wire s_axi_wready
  .s_axi_bresp    (reg_lite_icap2snap_bresp   ),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid   (reg_lite_icap2snap_bvalid  ),    // output wire s_axi_bvalid
  .s_axi_bready   (reg_lite_snap2icap_bready  ),    // input wire s_axi_bready
  .s_axi_araddr   (reg_lite_snap2icap_araddr  ),    // input wire [31 : 0] s_axi_araddr
  .s_axi_arprot   (reg_lite_snap2icap_arprot  ),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid  (reg_lite_snap2icap_arvalid ),  // input wire s_axi_arvalid
  .s_axi_arready  (reg_lite_icap2snap_arready ),  // output wire s_axi_arready
  .s_axi_rdata    (reg_lite_icap2snap_rdata   ),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp    (reg_lite_icap2snap_rresp   ),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid   (reg_lite_icap2snap_rvalid  ),    // output wire s_axi_rvalid
  .s_axi_rready   (reg_lite_snap2icap_rready  ),    // input wire s_axi_rready
  
  .m_axi_aclk     (clock_tlx                  ),        // input wire m_axi_aclk
  .m_axi_aresetn  (~input_reset_d            ),  // input wire m_axi_aresetn
  .m_axi_awaddr   (lite_snap2icap_awaddr      ),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot   (lite_snap2icap_awprot      ),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid  (lite_snap2icap_awvalid     ),  // output wire m_axi_awvalid
  .m_axi_awready  (lite_icap2snap_awready     ),  // input wire m_axi_awready
  .m_axi_wdata    (lite_snap2icap_wdata       ),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb    (lite_snap2icap_wstrb       ),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid   (lite_snap2icap_wvalid      ),    // output wire m_axi_wvalid
  .m_axi_wready   (lite_icap2snap_wready      ),    // input wire m_axi_wready
  .m_axi_bresp    (lite_icap2snap_bresp       ),      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid   (lite_icap2snap_bvalid      ),    // input wire m_axi_bvalid
  .m_axi_bready   (lite_snap2icap_bready      ),    // output wire m_axi_bready
  .m_axi_araddr   (lite_snap2icap_araddr      ),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot   (lite_snap2icap_arprot      ),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid  (lite_snap2icap_arvalid     ),  // output wire m_axi_arvalid
  .m_axi_arready  (lite_icap2snap_arready     ),  // input wire m_axi_arready
  .m_axi_rdata    (lite_icap2snap_rdata       ),      // input wire [31 : 0] m_axi_rdata
  .m_axi_rresp    (lite_icap2snap_rresp       ),      // input wire [1 : 0] m_axi_rresp
  .m_axi_rvalid   (lite_icap2snap_rvalid      ),    // input wire m_axi_rvalid
  .m_axi_rready   (lite_snap2icap_rready      )    // output wire m_axi_rready
);

`else   // else of ENABLE_PRFLOW

// Signals from ACTION to SNAP logic 
always @(*)  // conv2snap means signals from Action to snap logic
    begin
      reg_lite_conv2snap_awready               <= (~decouple_action) & lite_action2snap_awready;
      reg_lite_conv2snap_wready                <= (~decouple_action) & lite_action2snap_wready;
      reg_lite_conv2snap_bresp                 <= {2{lite_action2snap_bresp}};
      reg_lite_conv2snap_bvalid                <= (~decouple_action) & lite_action2snap_bvalid;
      reg_lite_conv2snap_arready               <= (~decouple_action) & lite_action2snap_arready;
      reg_lite_conv2snap_rdata                 <= lite_action2snap_rdata;
      reg_lite_conv2snap_rresp                 <= {2{lite_action2snap_rresp}};
      reg_lite_conv2snap_rvalid                <= (~decouple_action) & lite_action2snap_rvalid;
    end

`endif // end of ENABLE_PRFLOW

//TO ACTION
assign lite_snap2action_awaddr[`AXI_LITE_AW-1:0]    = {23'b00000000000000000000000, lite_snap2conv_awaddr[8:0]};
assign lite_snap2action_awprot[2:0]                 = lite_snap2conv_awprot[2:0]           ;
assign lite_snap2action_awvalid                     = (~decouple_action) & lite_snap2conv_awvalid;
assign lite_snap2action_wdata[`AXI_LITE_DW-1:0]     = lite_snap2conv_wdata[`AXI_LITE_DW-1:0]            ;
assign lite_snap2action_wstrb[3:0]                  = lite_snap2conv_wstrb[3:0]             ;
assign lite_snap2action_wvalid                      = (~decouple_action) & lite_snap2conv_wvalid;
assign lite_snap2action_bready                      = (~decouple_action) & lite_snap2conv_bready            ;
assign lite_snap2action_araddr[`AXI_LITE_DW-1:0]    = {23'b00000000000000000000000, lite_snap2conv_araddr[8:0]};
assign lite_snap2action_arprot[2:0]                 = lite_snap2conv_arprot[2:0]         ;
assign lite_snap2action_arvalid                     = (~decouple_action) & lite_snap2conv_arvalid;
assign lite_snap2action_rready                      = (~decouple_action) & lite_snap2conv_rready          ;

// Signals from action or ICAP back to the snap logic 
assign lite_conv2snap_awready                       = reg_lite_conv2snap_awready;
assign lite_conv2snap_wready                        = reg_lite_conv2snap_wready;
assign lite_conv2snap_bresp                         = reg_lite_conv2snap_bresp;
assign lite_conv2snap_bvalid                        = reg_lite_conv2snap_bvalid;
assign lite_conv2snap_arready                       = reg_lite_conv2snap_arready;
assign lite_conv2snap_rresp                         = reg_lite_conv2snap_rresp;
assign lite_conv2snap_rvalid                        = reg_lite_conv2snap_rvalid;
assign lite_conv2snap_rdata                         = reg_lite_conv2snap_rdata;



  // // ******************************************************************************
  // // IO AXI-Lite Decoupling Logic
  // // ******************************************************************************
  
  // Decoupling ocde signal coming from dynamic logic to ensure stability of the signal during PR
  // ocde IO is by card design in dynamic zone and needs to stay at '1' when decouple is active
  assign ocde_to_bsp_dcpl                   =  decouple_action | ocde_to_bsp        ;
  
  assign int_req                            =  (~decouple_action) & int_req_dcpl                  ;
  assign int_src                            =  decouple_action ? `INT_BITS'b0 : int_src_dcpl      ;
  assign int_ctx                            =  decouple_action ? `CTXW'b0     : int_ctx_dcpl      ;
  assign int_req_ack_dcpl                   =  (~decouple_action) & int_req_ack                   ;

  assign reset_action_d_dcpl                =  decouple_action  | reset_action_d                  ; // reset is active when decouple

`endif  // end of ENABLE_ODMA


  // // ******************************************************************************
  // // Action core logic 
  // // ******************************************************************************
  oc_action_core action_core_i ( 
      .clock_afu       ( clock_afu                ) ,
      .reset_action_d  ( reset_action_d_dcpl      ) ,
      .ocde            ( ocde                     ) ,  //connected from top-level port
      .ocde_to_bsp     ( ocde_to_bsp              ) ,
      .int_req_ack     ( int_req_ack_dcpl         ) , // input
      .int_req         ( int_req_dcpl             ) , // output
      .int_src         ( int_src_dcpl             ) , // output
      .int_ctx         ( int_ctx_dcpl             ) ,  // output
      
  `ifdef ENABLE_DDR 
    `ifdef AD9V3
  
   // DDR4 SDRAM Interface
      .c0_sys_clk_p     ( c0_sys_clk_p     ) ,
      .c0_sys_clk_n     ( c0_sys_clk_n     ) ,
      .c0_ddr4_adr      ( c0_ddr4_adr      ) ,
      .c0_ddr4_ba       ( c0_ddr4_ba       ) ,
      .c0_ddr4_cke      ( c0_ddr4_cke      ) ,
      .c0_ddr4_cs_n     ( c0_ddr4_cs_n     ) ,
      .c0_ddr4_dm_dbi_n ( c0_ddr4_dm_dbi_n ) ,
      .c0_ddr4_dq       ( c0_ddr4_dq       ) ,
      .c0_ddr4_dqs_c    ( c0_ddr4_dqs_c    ) ,
      .c0_ddr4_dqs_t    ( c0_ddr4_dqs_t    ) ,
      .c0_ddr4_odt      ( c0_ddr4_odt      ) ,
      .c0_ddr4_bg       ( c0_ddr4_bg       ) ,
      .c0_ddr4_reset_n  ( c0_ddr4_reset_n  ) ,
      .c0_ddr4_act_n    ( c0_ddr4_act_n    ) ,
      .c0_ddr4_ck_c     ( c0_ddr4_ck_c     ) ,
      .c0_ddr4_ck_t     ( c0_ddr4_ck_t     ) ,
     `endif
     `ifdef BW250SOC
  
   // DDR4 SDRAM Interface
      .c0_sys_clk_p     ( c0_sys_clk_p     ) ,
      .c0_sys_clk_n     ( c0_sys_clk_n     ) ,
      .c0_ddr4_adr      ( c0_ddr4_adr      ) ,
      .c0_ddr4_ba       ( c0_ddr4_ba       ) ,
      .c0_ddr4_cke      ( c0_ddr4_cke      ) ,
      .c0_ddr4_cs_n     ( c0_ddr4_cs_n     ) ,
      .c0_ddr4_dm_dbi_n ( c0_ddr4_dm_dbi_n ) ,
      .c0_ddr4_dq       ( c0_ddr4_dq       ) ,
      .c0_ddr4_dqs_c    ( c0_ddr4_dqs_c    ) ,
      .c0_ddr4_dqs_t    ( c0_ddr4_dqs_t    ) ,
      .c0_ddr4_odt      ( c0_ddr4_odt      ) ,
      .c0_ddr4_bg       ( c0_ddr4_bg       ) ,
      .c0_ddr4_reset_n  ( c0_ddr4_reset_n  ) ,
      .c0_ddr4_act_n    ( c0_ddr4_act_n    ) ,
      .c0_ddr4_ck_c     ( c0_ddr4_ck_c     ) ,
      .c0_ddr4_ck_t     ( c0_ddr4_ck_t     ) ,
     `endif
   `endif

`ifdef ENABLE_9H3_LED
      .user_led_a0     ( user_led_a0        ),
      .user_led_a1     ( user_led_a1        ),
      .user_led_g0     ( user_led_g0        ),
      .user_led_g1     ( user_led_g1        ),
`endif
`ifdef ENABLE_9H3_EEPROM
      .eeprom_scl_io   ( eeprom_scl         ),
      .eeprom_sda_io   ( eeprom_sda         ),
      .eeprom_wp       ( eeprom_wp          ),
`endif
`ifdef ENABLE_9H3_AVR
      .uc_avr_rx       ( avr_rx             ),
      .uc_avr_tx       ( avr_tx             ),
      .uc_avr_ck       ( avr_ck             ),
 `endif

    // ETHERNET interface
  `ifdef ENABLE_ETHERNET
  `ifndef ENABLE_ETH_LOOP_BACK
      .gt_ref_clk_n      ( gt_ref_clk_n       ),
      .gt_ref_clk_p      ( gt_ref_clk_p       ),
      .gt_rx_gt_port_0_n ( gt_rx_gt_port_0_n  ),
      .gt_rx_gt_port_0_p ( gt_rx_gt_port_0_p  ),
      .gt_rx_gt_port_1_n ( gt_rx_gt_port_1_n  ),
      .gt_rx_gt_port_1_p ( gt_rx_gt_port_1_p  ),
      .gt_rx_gt_port_2_n ( gt_rx_gt_port_2_n  ),
      .gt_rx_gt_port_2_p ( gt_rx_gt_port_2_p  ),
      .gt_rx_gt_port_3_n ( gt_rx_gt_port_3_n  ),
      .gt_rx_gt_port_3_p ( gt_rx_gt_port_3_p  ),
      .gt_tx_gt_port_0_n ( gt_tx_gt_port_0_n  ),
      .gt_tx_gt_port_0_p ( gt_tx_gt_port_0_p  ),
      .gt_tx_gt_port_1_n ( gt_tx_gt_port_1_n  ),
      .gt_tx_gt_port_1_p ( gt_tx_gt_port_1_p  ),
      .gt_tx_gt_port_2_n ( gt_tx_gt_port_2_n  ),
      .gt_tx_gt_port_2_p ( gt_tx_gt_port_2_p  ),
      .gt_tx_gt_port_3_n ( gt_tx_gt_port_3_n  ),
      .gt_tx_gt_port_3_p ( gt_tx_gt_port_3_p  ),
   `endif
   `endif
    
  // // Convertors for AXI Lite Path
      .s_axil_awaddr   ( lite_snap2action_awaddr  ) ,
      .s_axil_awprot   ( lite_snap2action_awprot  ) ,
      .s_axil_awvalid  ( lite_snap2action_awvalid ) ,
      .s_axil_awready  ( lite_action2snap_awready ) ,
      .s_axil_wdata    ( lite_snap2action_wdata   ) ,
      .s_axil_wstrb    ( lite_snap2action_wstrb   ) ,
      .s_axil_wvalid   ( lite_snap2action_wvalid  ) ,
      .s_axil_wready   ( lite_action2snap_wready  ) ,
      .s_axil_bresp    ( lite_action2snap_bresp   ) ,
      .s_axil_rdata    ( lite_action2snap_rdata   ) ,
      .s_axil_rresp    ( lite_action2snap_rresp   ) ,
      .s_axil_bvalid   ( lite_action2snap_bvalid  ) ,
      .s_axil_bready   ( lite_snap2action_bready  ) ,
      .s_axil_araddr   ( lite_snap2action_araddr  ) ,
      .s_axil_arprot   ( lite_snap2action_arprot  ) ,
      .s_axil_arvalid  ( lite_snap2action_arvalid ) ,
      .s_axil_arready  ( lite_action2snap_arready ) ,
      .s_axil_rvalid   ( lite_action2snap_rvalid  ) ,
      .s_axil_rready   ( lite_snap2action_rready  ) ,
  // // Convertors for AXI MM Data Path
      // TO SNAP
      .m_aximm_araddr                       ( mm_conv2snap_araddr   ) ,
      .m_aximm_aruser                       ( mm_conv2snap_aruser   ) ,
      .m_aximm_arburst                      ( mm_conv2snap_arburst  ) ,
      .m_aximm_arcache                      ( mm_conv2snap_arcache  ) ,
      .m_aximm_arid                         ( mm_conv2snap_arid     ) ,
      .m_aximm_arlen                        ( mm_conv2snap_arlen    ) ,
      .m_aximm_arlock                       ( mm_conv2snap_arlock   ) ,
      .m_aximm_arprot                       ( mm_conv2snap_arprot   ) ,
      .m_aximm_arqos                        ( mm_conv2snap_arqos    ) ,
      .m_aximm_arready                      ( mm_snap2conv_arready_i  ) ,
      .m_aximm_arregion                     ( mm_conv2snap_arregion ) ,
      .m_aximm_arsize                       ( mm_conv2snap_arsize   ) ,
      .m_aximm_arvalid                      ( mm_conv2snap_arvalid_i  ) ,
      .m_aximm_awaddr                       ( mm_conv2snap_awaddr   ) ,
      .m_aximm_awuser                       ( mm_conv2snap_awuser   ) ,
      .m_aximm_awburst                      ( mm_conv2snap_awburst  ) ,
      .m_aximm_awcache                      ( mm_conv2snap_awcache  ) ,
      .m_aximm_awid                         ( mm_conv2snap_awid     ) ,
      .m_aximm_awlen                        ( mm_conv2snap_awlen    ) ,
      .m_aximm_awlock                       ( mm_conv2snap_awlock   ) ,
      .m_aximm_awprot                       ( mm_conv2snap_awprot   ) ,
      .m_aximm_awqos                        ( mm_conv2snap_awqos    ) ,
      .m_aximm_awready                      ( mm_snap2conv_awready_i  ) ,
      .m_aximm_awregion                     ( mm_conv2snap_awregion ) ,
      .m_aximm_awsize                       ( mm_conv2snap_awsize   ) ,
      .m_aximm_awvalid                      ( mm_conv2snap_awvalid_i  ) ,
      .m_aximm_bid                          ( mm_snap2conv_bid      ) ,
      .m_aximm_buser                        ( mm_snap2conv_buser    ) ,
      .m_aximm_bready                       ( mm_conv2snap_bready_i   ) ,
      .m_aximm_bresp                        ( mm_snap2conv_bresp    ) ,
      .m_aximm_bvalid                       ( mm_snap2conv_bvalid_i   ) ,
      .m_aximm_rdata                        ( mm_snap2conv_rdata    ) ,
      .m_aximm_rid                          ( mm_snap2conv_rid      ) ,
      .m_aximm_ruser                        ( mm_snap2conv_ruser    ) ,
      .m_aximm_rlast                        ( mm_snap2conv_rlast    ) ,
      .m_aximm_rready                       ( mm_conv2snap_rready_i   ) ,
      .m_aximm_rresp                        ( mm_snap2conv_rresp    ) ,
      .m_aximm_rvalid                       ( mm_snap2conv_rvalid_i   ) ,
      .m_aximm_wdata                        ( mm_conv2snap_wdata    ) ,
      .m_aximm_wuser                        ( mm_conv2snap_wuser    ) ,
      .m_aximm_wlast                        ( mm_conv2snap_wlast    ) ,
      .m_aximm_wready                       ( mm_snap2conv_wready_i   ) ,
      .m_aximm_wstrb                        ( mm_conv2snap_wstrb    ) ,
      .m_aximm_wvalid                       ( mm_conv2snap_wvalid_i   ),
//HBM
      .clock_hbm_ref                        (clock_afu),
      .act_axi_card_mem0_apb_pclk           (act_axi_card_mem0_apb_pclk)
 ) ;

  
  // // ******************************************************************************
  // // IO AXI-MM Decoupling Logic
  // // ******************************************************************************
  assign mm_snap2conv_awready_i                = (~decouple_action) & mm_snap2conv_awready            ; //def 1
  assign mm_snap2conv_wready_i                 = (~decouple_action) & mm_snap2conv_wready             ; //def 1
  assign mm_snap2conv_arready_i                = (~decouple_action) & mm_snap2conv_arready            ; //def 1
  assign mm_snap2conv_bvalid_i                 = (~decouple_action) & mm_snap2conv_bvalid             ; //def 0
  assign mm_snap2conv_rvalid_i                 = (~decouple_action) & mm_snap2conv_rvalid             ; //def 0

  assign mm_conv2snap_bready               = (~decouple_action) & mm_conv2snap_bready_i               ; //def 1
  assign mm_conv2snap_rready               = (~decouple_action) & mm_conv2snap_rready_i               ; //def 1
  assign mm_conv2snap_awvalid              = (~decouple_action) & mm_conv2snap_awvalid_i              ; //def 0
  assign mm_conv2snap_wvalid               = (~decouple_action) & mm_conv2snap_wvalid_i               ; //def 0
  assign mm_conv2snap_arvalid              = (~decouple_action) & mm_conv2snap_arvalid_i              ; //def 0



  // // ******************************************************************************
  // // Convertor for Action to Card mem controller
  // // ******************************************************************************


  // // ******************************************************************************
  // // Card mem controllers
  // // ******************************************************************************

  // //
  // // ******************************************************************************
  // // Ethernet controllers
  // //
  // // ******************************************************************************
`ifdef ENABLE_HBM
  //
//act2hbm
//assign  hbm_ctrl_awid[`AXI_CARD_MEM_ID_WIDTH-1 : 0] = act_axi_card_mem0_awid;
//assign  hbm_ctrl_awid[5 : `AXI_CARD_MEM_ID_WIDTH]   = 'b0;
//assign  hbm_ctrl_arid[`AXI_CARD_MEM_ID_WIDTH-1 : 0] = act_axi_card_mem0_arid;
//assign  hbm_ctrl_arid[5 : `AXI_CARD_MEM_ID_WIDTH]   = 'b0;
//assign  act_axi_card_mem0_bid = hbm_ctrl_bid[`AXI_CARD_MEM_ID_WIDTH-1 : 0];
//assign  act_axi_card_mem0_rid = hbm_ctrl_rid[`AXI_CARD_MEM_ID_WIDTH-1 : 0];

//assign hbm_ctrl_reset_n = hbm_ctrl_apb_complete;

// BUFG for HBM REF CLK and APB CLK
//BUFG u_HBM_REF_CLK_BUFG  (
  //.I (clock_act),
  //.O (clock_hbm_ref)
//);

BUFGCE_DIV #(
      .BUFGCE_DIVIDE(2)
   )
    u_APB_CLK_BUFG  (
  .I (clock_afu),
  .CE (1'b1),
  .CLR (1'b0),
  .O (act_axi_card_mem0_apb_pclk)
);
`endif

endmodule
