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
   `endif
  );

  // // ********************************************************************************************************************************
  // // wires
  // // ********************************************************************************************************************************


  // // Interface between snap_core to (clock/dwidth) converter
`ifndef ENABLE_ODMA
  wire [`AXI_LITE_AW-1:0]     lite_snap2conv_awaddr  ;
  wire [2:0]                 lite_snap2conv_awprot  ;
  wire                       lite_snap2conv_awvalid ;
  wire [`AXI_LITE_DW-1:0]     lite_snap2conv_wdata   ;
  wire [3:0]                 lite_snap2conv_wstrb   ;
  wire                       lite_snap2conv_wvalid  ;
  wire                       lite_snap2conv_bready  ;
  wire [`AXI_LITE_AW-1:0]     lite_snap2conv_araddr  ;
  wire [2:0]                 lite_snap2conv_arprot  ;
  wire                       lite_snap2conv_arvalid ;
  wire                       lite_snap2conv_rready  ;

  wire                       lite_conv2snap_awready ;
  wire                       lite_conv2snap_wready  ;
  wire [1:0]                 lite_conv2snap_bresp   ;
  wire                       lite_conv2snap_bvalid  ;
  wire                       lite_conv2snap_arready ;
  wire [`AXI_LITE_DW-1:0]     lite_conv2snap_rdata   ;
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
`endif
  // // Interface for interrupts
  wire                       int_req_ack     ;
  wire                       int_req         ;
  wire [`INT_BITS-1:0]        int_src         ;
  wire [`CTXW-1:0]            int_ctx         ;

`ifdef ENABLE_ODMA
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

  // // Interface between action_wrapper and (clock/dwidth) converter
  wire [`AXI_LITE_AW-1:0]    lite_conv2act_awaddr  ;
  wire [2:0]                 lite_conv2act_awprot  ;
  wire                       lite_conv2act_awvalid ;
  wire [`AXI_LITE_DW-1:0]    lite_conv2act_wdata   ;
  wire [3:0]                 lite_conv2act_wstrb   ;
  wire                       lite_conv2act_wvalid  ;
  wire                       lite_conv2act_bready  ;
  wire [`AXI_LITE_AW-1:0]    lite_conv2act_araddr  ;
  wire [2:0]                 lite_conv2act_arprot  ;
  wire                       lite_conv2act_arvalid ;
  wire                       lite_conv2act_rready  ;

  wire                       lite_act2conv_awready ;
  wire                       lite_act2conv_wready  ;
  wire [1:0]                 lite_act2conv_bresp   ;
  wire                       lite_act2conv_bvalid  ;
  wire                       lite_act2conv_arready ;
  wire [`AXI_LITE_DW-1:0]    lite_act2conv_rdata   ;
  wire [1:0]                 lite_act2conv_rresp   ;
  wire                       lite_act2conv_rvalid  ;

  wire                       mm_conv2act_awready   ;
  wire                       mm_conv2act_wready    ;
  wire [`IDW-1:0]            mm_conv2act_bid       ;
  wire [`AXI_BUSER-1:0]      mm_conv2act_buser     ;
  wire [1:0]                 mm_conv2act_bresp     ;
  wire                       mm_conv2act_bvalid    ;
  wire [`IDW-1:0]            mm_conv2act_rid       ;
  wire [`AXI_RUSER-1:0]      mm_conv2act_ruser     ;
  wire [`AXI_ACT_DW-1:0]     mm_conv2act_rdata     ;
  wire [1:0]                 mm_conv2act_rresp     ;
  wire                       mm_conv2act_rlast     ;
  wire                       mm_conv2act_rvalid    ;
  wire                       mm_conv2act_arready   ;

  wire [`IDW-1:0]            mm_act2conv_awid      ;
  wire [`AXI_MM_AW-1:0]      mm_act2conv_awaddr    ;
  wire [7:0]                 mm_act2conv_awlen     ;
  wire [2:0]                 mm_act2conv_awsize    ;
  wire [1:0]                 mm_act2conv_awburst   ;
  wire                       mm_act2conv_awlock    ;
  wire [3:0]                 mm_act2conv_awcache   ;
  wire [2:0]                 mm_act2conv_awprot    ;
  wire [3:0]                 mm_act2conv_awqos     ;
  wire [3:0]                 mm_act2conv_awregion  ;
  wire [`AXI_AWUSER-1:0]     mm_act2conv_awuser    ;
  wire                       mm_act2conv_awvalid   ;
  wire [`AXI_ACT_DW-1:0]     mm_act2conv_wdata     ;
  wire [`AXI_WUSER-1:0]      mm_act2conv_wuser     ;
  wire [(`AXI_ACT_DW/8)-1:0]  mm_act2conv_wstrb     ;
  wire                       mm_act2conv_wlast     ;
  wire                       mm_act2conv_wvalid    ;
  wire                       mm_act2conv_bready    ;
  wire [`IDW-1:0]             mm_act2conv_arid      ;
  wire [`AXI_MM_AW-1:0]       mm_act2conv_araddr    ;
  wire [7:0]                 mm_act2conv_arlen     ;
  wire [2:0]                 mm_act2conv_arsize    ;
  wire [1:0]                 mm_act2conv_arburst   ;
  wire [`AXI_ARUSER-1:0]      mm_act2conv_aruser    ;
  wire                       mm_act2conv_arlock    ;
  wire [3:0]                 mm_act2conv_arcache   ;
  wire [2:0]                 mm_act2conv_arprot    ;
  wire [3:0]                 mm_act2conv_arqos     ;
  wire [3:0]                 mm_act2conv_arregion  ;
  wire                       mm_act2conv_arvalid   ;
  wire                       mm_act2conv_rready    ;

`ifdef ENABLE_AXI_CARD_MEM
  wire                                    memctl0_reset_m             ;

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

  wire [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0 ]  memctl0_axi_awaddr          ;
  wire [ 7 : 0 ]                          memctl0_axi_awlen           ;
  wire [ 2 : 0 ]                          memctl0_axi_awsize          ;
  wire [ 1 : 0 ]                          memctl0_axi_awburst         ;
  wire                                    memctl0_axi_awlock          ;
  wire [ 3 : 0 ]                          memctl0_axi_awcache         ;
  wire [ 2 : 0 ]                          memctl0_axi_awprot          ;
  wire [ 3 : 0 ]                          memctl0_axi_awregion        ;
  wire [ 3 : 0 ]                          memctl0_axi_awqos           ;
  wire                                    memctl0_axi_awvalid         ;
  wire                                    memctl0_axi_awready         ;
  wire [ `AXI_CARD_MEM_DATA_WIDTH-1 : 0 ]  memctl0_axi_wdata           ;
  wire [(`AXI_CARD_MEM_DATA_WIDTH/8)-1 : 0] memctl0_axi_wstrb           ;
  wire                                    memctl0_axi_wlast           ;
  wire                                    memctl0_axi_wvalid          ;
  wire                                    memctl0_axi_wready          ;
  wire [ 1 : 0 ]                          memctl0_axi_bresp           ;
  wire                                    memctl0_axi_bvalid          ;
  wire                                    memctl0_axi_bready          ;
  wire [ `AXI_CARD_MEM_ADDR_WIDTH-1 : 0 ]  memctl0_axi_araddr          ;
  wire [ 7 : 0 ]                          memctl0_axi_arlen           ;
  wire [ 2 : 0 ]                          memctl0_axi_arsize          ;
  wire [ 1 : 0 ]                          memctl0_axi_arburst         ;
  wire                                    memctl0_axi_arlock          ;
  wire [ 3 : 0 ]                          memctl0_axi_arcache         ;
  wire [ 2 : 0 ]                          memctl0_axi_arprot          ;
  wire [ 3 : 0 ]                          memctl0_axi_arregion        ;
  wire [ 3 : 0 ]                          memctl0_axi_arqos           ;
  wire                                    memctl0_axi_arvalid         ;
  wire                                    memctl0_axi_arready         ;
  wire [ `AXI_CARD_MEM_DATA_WIDTH-1 : 0 ]  memctl0_axi_rdata           ;
  wire [ 1 : 0 ]                          memctl0_axi_rresp           ;
  wire                                    memctl0_axi_rlast           ;
  wire                                    memctl0_axi_rvalid          ;
  wire                                    memctl0_axi_rready          ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    memctl0_axi_arid            ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    memctl0_axi_awid            ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    memctl0_axi_bid             ;
  wire [ `AXI_CARD_MEM_ID_WIDTH-1 : 0 ]    memctl0_axi_rid             ;
  wire                                    memctl0_init_calib_complete ;
  wire                                    memctl0_ui_clk              ;
  wire                                    memctl0_axi_ctrl_awvalid    ;
  wire                                    memctl0_axi_ctrl_awready    ;
  wire [31 : 0]                           memctl0_axi_ctrl_awaddr     ;
  wire                                    memctl0_axi_ctrl_wvalid     ;
  wire                                    memctl0_axi_ctrl_wready     ;
  wire [31 : 0]                           memctl0_axi_ctrl_wdata      ;
  wire                                    memctl0_axi_ctrl_bvalid     ;
  wire                                    memctl0_axi_ctrl_bready     ;
  wire [1 : 0]                            memctl0_axi_ctrl_bresp      ;
  wire                                    memctl0_axi_ctrl_arvalid    ;
  wire                                    memctl0_axi_ctrl_arready    ;
  wire [31 : 0]                           memctl0_axi_ctrl_araddr     ;
  wire                                    memctl0_axi_ctrl_rvalid     ;
  wire                                    memctl0_axi_ctrl_rready     ;
  wire [31 : 0]                           memctl0_axi_ctrl_rdata      ;
  wire [1 : 0]                            memctl0_axi_ctrl_rresp      ;
  wire                                    memctl0_interrupt           ;
  
`endif
  wire                                    memctl0_axi_rst_n           ;

`ifdef ENABLE_DDR
`ifdef AD9V3
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

  // // ********************************************************************************************************************************
  // // User clock
  // // ********************************************************************************************************************************
  `ifdef ACTION_USER_CLOCK
  wire clock_usr;
  wire user_clock_enabled;
  
  user_clock_gen muser_clock
  (
    .reset          ( reset    ),
    .clk_in1        ( clock_afu),
    .clk_out1       ( clock_usr),
    .locked         ( user_clock_enabled)
  );  
  `endif

  wire clock_act;
  `ifdef ACTION_USER_CLOCK
    assign clock_act = clock_usr;
  `else
    assign clock_act = clock_afu;
  `endif

  wire clock_mem;
  `ifdef ENABLE_DDR
    assign clock_mem = memctl0_ui_clk;
  `else
    assign clock_mem = clock_afu;
  `endif
  // // ********************************************************************************************************************************
  // // Reset signals
  // // ********************************************************************************************************************************
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
  vio_soft_reset  mvio_soft_reset
    (
      .clk        ( clock_afu),
      .probe_out0 ( vio_reset_snap),
      .probe_out1 ( vio_reset_action)
    );  

  // Source 3: from MMIO_register
  wire soft_reset_action;


  //----------------------------------
  // Connections
  // To snap_core      (sampled by clock_afu)
  reg reset_snap_q;     
  always @ (posedge clock_afu)
        reset_snap_q <= input_reset_q || vio_reset_snap;

  // To action_wrapper (sampled by clock_act)
  wire reset_action_d;
  assign reset_action_d = input_reset_q || vio_reset_action || soft_reset_action;
  reg  reset_action_tmp;
  wire reset_action_q;
  always @ (posedge clock_afu) 
        reset_action_tmp <= reset_action_d;
	

  // To mem controllers (sampled by clock_afu)
  // To Action attached converters

  reg reset_nest_q;
  always @ (posedge clock_afu)
    begin
        reset_nest_q <= reset_action_d;
    end

  `ifdef ENABLE_DDR
     assign memctl0_axi_rst_n = ~memctl0_ui_clk_sync_rst;
  `else
     assign memctl0_axi_rst_n = ~reset_nest_q;
  `endif

  // // ********************************************************************************************************************************
  // // AFU DESCRIPTOR TIES
  // // ********************************************************************************************************************************

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

  // // ********************************************************************************************************************************
  // // CFG DESCRIPTOR
  // // ********************************************************************************************************************************

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
      .err_unimplemented_addr                      ( err_unimplemented_addr          ) // // output

    );


  // // ********************************************************************************************************************************
  // // oc_snap_core
  // // ********************************************************************************************************************************


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


`ifndef ENABLE_ODMA
      .lite_snap2conv_awaddr            (lite_snap2conv_awaddr            ),
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


      .lite_conv2snap_awready           (lite_conv2snap_awready           ),
      .lite_conv2snap_wready            (lite_conv2snap_wready            ),
      .lite_conv2snap_bresp             (lite_conv2snap_bresp             ),
      .lite_conv2snap_bvalid            (lite_conv2snap_bvalid            ),
      .lite_conv2snap_arready           (lite_conv2snap_arready           ),
      .lite_conv2snap_rdata             (lite_conv2snap_rdata             ),
      .lite_conv2snap_rresp             (lite_conv2snap_rresp             ),
      .lite_conv2snap_rvalid            (lite_conv2snap_rvalid            ),



      .mm_snap2conv_awready             (mm_snap2conv_awready             ),
      .mm_snap2conv_wready              (mm_snap2conv_wready              ),
      .mm_snap2conv_bid                 (mm_snap2conv_bid                 ),
      .mm_snap2conv_bresp               (mm_snap2conv_bresp               ),
      .mm_snap2conv_bvalid              (mm_snap2conv_bvalid              ),
      .mm_snap2conv_rid                 (mm_snap2conv_rid                 ),
      .mm_snap2conv_rdata               (mm_snap2conv_rdata               ),
      .mm_snap2conv_rresp               (mm_snap2conv_rresp               ),
      .mm_snap2conv_rlast               (mm_snap2conv_rlast               ),
      .mm_snap2conv_rvalid              (mm_snap2conv_rvalid              ),
      .mm_snap2conv_arready             (mm_snap2conv_arready             ),


      .mm_conv2snap_awid                (mm_conv2snap_awid                ),
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

      .int_req_ack                      (int_req_ack                      ),
      .int_req                          (int_req                          ),
      .int_src                          (int_src                          ),
      .int_ctx                          (int_ctx                          )

`else
      // ODMA mode: AXI4-MM Interface to action
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



  // // ********************************************************************************************************************************
  // // action_wrapper
  // // ********************************************************************************************************************************
// async clock handle for reset and interrupt signals
    wire                 action_int_req_ack;
    wire                 action_int_req;
    wire [`INT_BITS-1:0] action_int_src;
    wire [`CTXW-1:0]     action_int_ctx;
`ifdef ACTION_USER_CLOCK
    assign reset_action_q = reset_action_tmp || (!user_clock_enabled);

    reg                 action_int_req_level;
    reg [`INT_BITS-1:0] action_int_src_level;
    reg [`CTXW-1:0]     action_int_ctx_level;
    reg                 int_req_q1;
    reg                 int_req_q2;
    reg [`INT_BITS-1:0] int_src_q1;
    reg [`INT_BITS-1:0] int_src_q2;
    reg [`CTXW-1:0]     int_ctx_q1;
    reg [`CTXW-1:0]     int_ctx_q2;

    always@(posedge clock_act or posedge reset_action_q)
    begin
        if(reset_action_q)
            action_int_req_level <= 1'b0;
        if(action_int_req_ack)
            action_int_req_level <= 1'b0;
        else if(action_int_req)
            action_int_req_level <= 1'b1;
    end

    always@(posedge clock_act)
    begin
        if(action_int_req)
        begin
            action_int_src_level <= action_int_src;
            action_int_ctx_level <= action_int_ctx;
        end
    end

    always@(posedge clock_afu)
    begin
        int_req_q1 <= action_int_req_level;
        int_req_q2 <= int_req_q1;
        int_src_q1 <= action_int_src_level;
        int_src_q2 <= int_src_q1;
        int_ctx_q1 <= action_int_ctx_level;
        int_ctx_q2 <= int_ctx_q1;
    end

    assign int_req = int_req_q2;
    assign int_src = int_src_q2;
    assign int_ctx = int_ctx_q2;
    assign action_int_req_ack = int_req_ack;
`else
    assign reset_action_q = reset_action_tmp;
    assign int_req = action_int_req;
    assign int_src = action_int_src;
    assign int_ctx = action_int_ctx;
    assign action_int_req_ack = int_req_ack;
`endif

`ifndef ENABLE_ODMA
// Bridge Mode action_wrapper
//
  action_wrapper action_w
     (
      .ap_clk                             ( clock_act                  ) ,
      .ap_rst_n                           ( ~reset_action_q            ) ,
      .interrupt_ack                      ( action_int_req_ack         ) ,
      .interrupt                          ( action_int_req             ) ,
      .interrupt_src                      ( action_int_src             ) ,
      .interrupt_ctx                      ( action_int_ctx             ) ,

`ifdef ENABLE_AXI_CARD_MEM
      //
      // AXI card memory Interface
      .m_axi_card_mem0_araddr             ( act_axi_card_mem0_araddr   ) ,
      .m_axi_card_mem0_arburst            ( act_axi_card_mem0_arburst  ) ,
      .m_axi_card_mem0_arcache            ( act_axi_card_mem0_arcache  ) ,
      .m_axi_card_mem0_arid               ( act_axi_card_mem0_arid     ) ,
      .m_axi_card_mem0_arlen              ( act_axi_card_mem0_arlen    ) ,
      .m_axi_card_mem0_arlock             ( act_axi_card_mem0_arlock   ) ,
      .m_axi_card_mem0_arprot             ( act_axi_card_mem0_arprot   ) ,
      .m_axi_card_mem0_arqos              ( act_axi_card_mem0_arqos    ) ,
      .m_axi_card_mem0_arready            ( act_axi_card_mem0_arready  ) ,
      .m_axi_card_mem0_arregion           ( act_axi_card_mem0_arregion ) ,
      .m_axi_card_mem0_arsize             ( act_axi_card_mem0_arsize   ) ,
      .m_axi_card_mem0_aruser             (                            ) ,
      .m_axi_card_mem0_arvalid            ( act_axi_card_mem0_arvalid  ) ,
      .m_axi_card_mem0_awaddr             ( act_axi_card_mem0_awaddr   ) ,
      .m_axi_card_mem0_awburst            ( act_axi_card_mem0_awburst  ) ,
      .m_axi_card_mem0_awcache            ( act_axi_card_mem0_awcache  ) ,
      .m_axi_card_mem0_awid               ( act_axi_card_mem0_awid     ) ,
      .m_axi_card_mem0_awlen              ( act_axi_card_mem0_awlen    ) ,
      .m_axi_card_mem0_awlock             ( act_axi_card_mem0_awlock   ) ,
      .m_axi_card_mem0_awprot             ( act_axi_card_mem0_awprot   ) ,
      .m_axi_card_mem0_awqos              ( act_axi_card_mem0_awqos    ) ,
      .m_axi_card_mem0_awready            ( act_axi_card_mem0_awready  ) ,
      .m_axi_card_mem0_awregion           ( act_axi_card_mem0_awregion ) ,
      .m_axi_card_mem0_awsize             ( act_axi_card_mem0_awsize   ) ,
      .m_axi_card_mem0_awuser             (                            ) ,
      .m_axi_card_mem0_awvalid            ( act_axi_card_mem0_awvalid  ) ,
      .m_axi_card_mem0_bid                ( act_axi_card_mem0_bid      ) ,
      .m_axi_card_mem0_bready             ( act_axi_card_mem0_bready   ) ,
      .m_axi_card_mem0_bresp              ( act_axi_card_mem0_bresp    ) ,
      .m_axi_card_mem0_buser              (1'b0                        ) ,
      .m_axi_card_mem0_bvalid             ( act_axi_card_mem0_bvalid   ) ,
      .m_axi_card_mem0_rdata              ( act_axi_card_mem0_rdata    ) ,
      .m_axi_card_mem0_rid                ( act_axi_card_mem0_rid      ) ,
      .m_axi_card_mem0_rlast              ( act_axi_card_mem0_rlast    ) ,
      .m_axi_card_mem0_rready             ( act_axi_card_mem0_rready   ) ,
      .m_axi_card_mem0_rresp              ( act_axi_card_mem0_rresp    ) ,
      .m_axi_card_mem0_ruser              (1'b0                        ) ,
      .m_axi_card_mem0_rvalid             ( act_axi_card_mem0_rvalid   ) ,
      .m_axi_card_mem0_wdata              ( act_axi_card_mem0_wdata    ) ,
      .m_axi_card_mem0_wlast              ( act_axi_card_mem0_wlast    ) ,
      .m_axi_card_mem0_wready             ( act_axi_card_mem0_wready   ) ,
      .m_axi_card_mem0_wstrb              ( act_axi_card_mem0_wstrb    ) ,
      .m_axi_card_mem0_wuser              (                            ) ,
      .m_axi_card_mem0_wvalid             ( act_axi_card_mem0_wvalid   ) ,
`endif
      //
      // AXI Control Register Interface
      .s_axi_ctrl_reg_araddr              ( lite_conv2act_araddr       ) ,
      .s_axi_ctrl_reg_arready             ( lite_act2conv_arready      ) ,
      .s_axi_ctrl_reg_arvalid             ( lite_conv2act_arvalid      ) ,
      .s_axi_ctrl_reg_awaddr              ( lite_conv2act_awaddr       ) ,
      .s_axi_ctrl_reg_awready             ( lite_act2conv_awready      ) ,
      .s_axi_ctrl_reg_awvalid             ( lite_conv2act_awvalid      ) ,
      .s_axi_ctrl_reg_bready              ( lite_conv2act_bready       ) ,
      .s_axi_ctrl_reg_bresp               ( lite_act2conv_bresp        ) ,
      .s_axi_ctrl_reg_bvalid              ( lite_act2conv_bvalid       ) ,
      .s_axi_ctrl_reg_rdata               ( lite_act2conv_rdata        ) ,
      .s_axi_ctrl_reg_rready              ( lite_conv2act_rready       ) ,
      .s_axi_ctrl_reg_rresp               ( lite_act2conv_rresp        ) ,
      .s_axi_ctrl_reg_rvalid              ( lite_act2conv_rvalid       ) ,
      .s_axi_ctrl_reg_wdata               ( lite_conv2act_wdata        ) ,
      .s_axi_ctrl_reg_wready              ( lite_act2conv_wready       ) ,
      .s_axi_ctrl_reg_wstrb               ( lite_conv2act_wstrb        ) ,
      .s_axi_ctrl_reg_wvalid              ( lite_conv2act_wvalid       ) ,
      //
      // AXI Host Memory Interface
      .m_axi_host_mem_araddr              ( mm_act2conv_araddr         ) ,
      .m_axi_host_mem_arburst             ( mm_act2conv_arburst        ) ,
      .m_axi_host_mem_arcache             ( mm_act2conv_arcache        ) ,
      .m_axi_host_mem_arid                ( mm_act2conv_arid           ) ,
      .m_axi_host_mem_arlen               ( mm_act2conv_arlen          ) ,
      .m_axi_host_mem_arlock              (                            ) ,
      .m_axi_host_mem_arprot              ( mm_act2conv_arprot         ) ,
      .m_axi_host_mem_arqos               ( mm_act2conv_arqos          ) ,
      .m_axi_host_mem_arready             ( mm_conv2act_arready        ) ,
      .m_axi_host_mem_arregion            (                            ) ,
      .m_axi_host_mem_arsize              ( mm_act2conv_arsize         ) ,
      .m_axi_host_mem_aruser              ( mm_act2conv_aruser         ) ,
      .m_axi_host_mem_arvalid             ( mm_act2conv_arvalid        ) ,
      .m_axi_host_mem_awaddr              ( mm_act2conv_awaddr         ) ,
      .m_axi_host_mem_awburst             ( mm_act2conv_awburst        ) ,
      .m_axi_host_mem_awcache             ( mm_act2conv_awcache        ) ,
      .m_axi_host_mem_awid                ( mm_act2conv_awid           ) ,
      .m_axi_host_mem_awlen               ( mm_act2conv_awlen          ) ,
      .m_axi_host_mem_awlock              (                            ) ,
      .m_axi_host_mem_awprot              ( mm_act2conv_awprot         ) ,
      .m_axi_host_mem_awqos               ( mm_act2conv_awqos          ) ,
      .m_axi_host_mem_awready             ( mm_conv2act_awready        ) ,
      .m_axi_host_mem_awregion            (                            ) ,
      .m_axi_host_mem_awsize              ( mm_act2conv_awsize         ) ,
      .m_axi_host_mem_awuser              ( mm_act2conv_awuser         ) ,
      .m_axi_host_mem_awvalid             ( mm_act2conv_awvalid        ) ,
      .m_axi_host_mem_bid                 ( mm_conv2act_bid            ) ,
      .m_axi_host_mem_bready              ( mm_act2conv_bready         ) ,
      .m_axi_host_mem_bresp               ( mm_conv2act_bresp          ) ,
      .m_axi_host_mem_buser               ( 1'b0                       ) ,
      .m_axi_host_mem_bvalid              ( mm_conv2act_bvalid         ) ,
      .m_axi_host_mem_rdata               ( mm_conv2act_rdata          ) ,
      .m_axi_host_mem_rid                 ( mm_conv2act_rid            ) ,
      .m_axi_host_mem_rlast               ( mm_conv2act_rlast          ) ,
      .m_axi_host_mem_rready              ( mm_act2conv_rready         ) ,
      .m_axi_host_mem_rresp               ( mm_conv2act_rresp          ) ,
      .m_axi_host_mem_ruser               ( 1'b0                       ) ,
      .m_axi_host_mem_rvalid              ( mm_conv2act_rvalid         ) ,
      .m_axi_host_mem_wdata               ( mm_act2conv_wdata          ) ,
      .m_axi_host_mem_wlast               ( mm_act2conv_wlast          ) ,
      .m_axi_host_mem_wready              ( mm_conv2act_wready         ) ,
      .m_axi_host_mem_wstrb               ( mm_act2conv_wstrb          ) ,
      .m_axi_host_mem_wuser               (                            ) ,
      .m_axi_host_mem_wvalid              ( mm_act2conv_wvalid         )
 ) ;  // action_w: action_wrapper

`else

    //TODO
    assign int_req_ack = 1'b0;
    // ODMA Mode action_wrapper
  action_wrapper action_w (
      .ap_clk                                ( clock_act               ) ,
      .ap_rst_n                              ( ~reset_action_q         ) ,
      .interrupt_ack                         ( int_req_ack             ) ,
      .interrupt                             ( int_req                 ) ,
      .interrupt_src                         ( int_src                 ) ,
      .interrupt_ctx                         ( int_ctx                 ) ,

      .axi_mm_araddr                         ( axi_mm_araddr           ) ,
      .axi_mm_arburst                        ( axi_mm_arburst          ) ,
      .axi_mm_arcache                        ( axi_mm_arcache          ) ,
      .axi_mm_arid                           ( axi_mm_arid             ) ,
      .axi_mm_arlen                          ( axi_mm_arlen            ) ,
      .axi_mm_arlock                         ( axi_mm_arlock           ) ,
      .axi_mm_arprot                         ( axi_mm_arprot           ) ,
      .axi_mm_arqos                          ( axi_mm_arqos            ) ,
      .axi_mm_arready                        ( axi_mm_arready          ) ,
      .axi_mm_arregion                       ( axi_mm_arregion         ) ,
      .axi_mm_arsize                         ( axi_mm_arsize           ) ,
      .axi_mm_aruser                         ( axi_mm_aruser           ) ,
      .axi_mm_arvalid                        ( axi_mm_arvalid          ) ,
      .axi_mm_rdata                          ( axi_mm_rdata            ) ,
      .axi_mm_rid                            ( axi_mm_rid              ) ,
      .axi_mm_rlast                          ( axi_mm_rlast            ) ,
      .axi_mm_rready                         ( axi_mm_rready           ) ,
      .axi_mm_rresp                          ( axi_mm_rresp            ) ,
      .axi_mm_ruser                          ( axi_mm_ruser            ) ,
      .axi_mm_rvalid                         ( axi_mm_rvalid           ) ,
      .axi_mm_awaddr                         ( axi_mm_awaddr           ) ,
      .axi_mm_awburst                        ( axi_mm_awburst          ) ,
      .axi_mm_awcache                        ( axi_mm_awcache          ) ,
      .axi_mm_awid                           ( axi_mm_awid             ) ,
      .axi_mm_awlen                          ( axi_mm_awlen            ) ,
      .axi_mm_awlock                         ( axi_mm_awlock           ) ,
      .axi_mm_awprot                         ( axi_mm_awprot           ) ,
      .axi_mm_awqos                          ( axi_mm_awqos            ) ,
      .axi_mm_awready                        ( axi_mm_awready          ) ,
      .axi_mm_awregion                       ( axi_mm_awregion         ) ,
      .axi_mm_awsize                         ( axi_mm_awsize           ) ,
      .axi_mm_awuser                         ( axi_mm_awuser           ) ,
      .axi_mm_awvalid                        ( axi_mm_awvalid          ) ,
      .axi_mm_wdata                          ( axi_mm_wdata            ) ,
      .axi_mm_wstrb                          ( axi_mm_wstrb            ) ,
      .axi_mm_wlast                          ( axi_mm_wlast            ) ,
      .axi_mm_wuser                          ( axi_mm_wuser            ) ,
      .axi_mm_wvalid                         ( axi_mm_wvalid           ) ,
      .axi_mm_wready                         ( axi_mm_wready           ) ,
      .axi_mm_bvalid                         ( axi_mm_bvalid           ) ,
      .axi_mm_bresp                          ( axi_mm_bresp            ) ,
      .axi_mm_buser                          ( axi_mm_buser            ) ,
      .axi_mm_bid                            ( axi_mm_bid              ) ,
      .axi_mm_bready                         ( axi_mm_bready           ) ,
      .a_s_axi_arvalid                       ( a_m_axi_arvalid         ) ,
      .a_s_axi_araddr                        ( a_m_axi_araddr          ) ,
      .a_s_axi_arready                       ( a_m_axi_arready         ) ,
      .a_s_axi_rvalid                        ( a_m_axi_rvalid          ) ,
      .a_s_axi_rdata                         ( a_m_axi_rdata           ) ,
      .a_s_axi_rresp                         ( a_m_axi_rresp           ) ,
      .a_s_axi_rready                        ( a_m_axi_rready          ) ,
      .a_s_axi_awvalid                       ( a_m_axi_awvalid         ) ,
      .a_s_axi_awaddr                        ( a_m_axi_awaddr          ) ,
      .a_s_axi_awready                       ( a_m_axi_awready         ) ,
      .a_s_axi_wvalid                        ( a_m_axi_wvalid          ) ,
      .a_s_axi_wdata                         ( a_m_axi_wdata           ) ,
      .a_s_axi_wstrb                         ( a_m_axi_wstrb           ) ,
      .a_s_axi_wready                        ( a_m_axi_wready          ) ,
      .a_s_axi_bvalid                        ( a_m_axi_bvalid          ) ,
      .a_s_axi_bresp                         ( a_m_axi_bresp           ) ,
      .a_s_axi_bready                        ( a_m_axi_bready          ) ,
      .a_m_axi_arvalid                       ( a_s_axi_arvalid         ) ,
      .a_m_axi_araddr                        ( a_s_axi_araddr          ) ,
      .a_m_axi_arready                       ( a_s_axi_arready         ) ,
      .a_m_axi_rvalid                        ( a_s_axi_rvalid          ) ,
      .a_m_axi_rdata                         ( a_s_axi_rdata           ) ,
      .a_m_axi_rresp                         ( a_s_axi_rresp           ) ,
      .a_m_axi_rready                        ( a_s_axi_rready          ) ,
      .a_m_axi_awvalid                       ( a_s_axi_awvalid         ) ,
      .a_m_axi_awaddr                        ( a_s_axi_awaddr          ) ,
      .a_m_axi_awready                       ( a_s_axi_awready         ) ,
      .a_m_axi_wvalid                        ( a_s_axi_wvalid          ) ,
      .a_m_axi_wdata                         ( a_s_axi_wdata           ) ,
      .a_m_axi_wstrb                         ( a_s_axi_wstrb           ) ,
      .a_m_axi_wready                        ( a_s_axi_wready          ) ,
      .a_m_axi_bvalid                        ( a_s_axi_bvalid          ) ,
      .a_m_axi_bresp                         ( a_s_axi_bresp           ) ,
      .a_m_axi_bready                        ( a_s_axi_bready          )
) ;  // action_w: action_wrapper
`endif

  // // ********************************************************************************************************************************
  // // Convertors for AXI lite path
  // // ********************************************************************************************************************************

`ifndef ENABLE_ODMA

`ifdef ACTION_USER_CLOCK

  //
  // AXI_LITE_CLOCK_CONVERTER
  //
  axi_lite_clock_converter axi_lite_clock_converter_snap2act ( 
      .s_axi_aclk     ( clock_afu              ) ,
      .s_axi_aresetn  ( ~reset_nest_q          ) ,
      .s_axi_awaddr   ( lite_snap2conv_awaddr  ) ,
      .s_axi_awprot   ( lite_snap2conv_awprot  ) ,
      .s_axi_awvalid  ( lite_snap2conv_awvalid ) ,
      .s_axi_awready  ( lite_conv2snap_awready ) ,
      .s_axi_wdata    ( lite_snap2conv_wdata   ) ,
      .s_axi_wstrb    ( lite_snap2conv_wstrb   ) ,
      .s_axi_wvalid   ( lite_snap2conv_wvalid  ) ,
      .s_axi_wready   ( lite_conv2snap_wready  ) ,
      .s_axi_bresp    ( lite_conv2snap_bresp   ) ,
      .s_axi_bvalid   ( lite_conv2snap_bvalid  ) ,
      .s_axi_bready   ( lite_snap2conv_bready  ) ,
      .s_axi_araddr   ( lite_snap2conv_araddr  ) ,
      .s_axi_arprot   ( lite_snap2conv_arprot  ) ,
      .s_axi_arvalid  ( lite_snap2conv_arvalid ) ,
      .s_axi_arready  ( lite_conv2snap_arready ) ,
      .s_axi_rdata    ( lite_conv2snap_rdata   ) ,
      .s_axi_rresp    ( lite_conv2snap_rresp   ) ,
      .s_axi_rvalid   ( lite_conv2snap_rvalid  ) ,
      .s_axi_rready   ( lite_snap2conv_rready  ) ,
      .m_axi_aclk     ( clock_act              ) ,
      .m_axi_aresetn  ( ~reset_action_q        ) ,
      .m_axi_awaddr   ( lite_conv2act_awaddr   ) ,
      .m_axi_awprot   (                        ) ,
      .m_axi_awvalid  ( lite_conv2act_awvalid  ) ,
      .m_axi_awready  ( lite_act2conv_awready  ) ,
      .m_axi_wdata    ( lite_conv2act_wdata    ) ,
      .m_axi_wstrb    ( lite_conv2act_wstrb    ) ,
      .m_axi_wvalid   ( lite_conv2act_wvalid   ) ,
      .m_axi_wready   ( lite_act2conv_wready   ) ,
      .m_axi_bresp    ( lite_act2conv_bresp    ) ,
      .m_axi_bvalid   ( lite_act2conv_bvalid   ) ,
      .m_axi_bready   ( lite_conv2act_bready   ) ,
      .m_axi_araddr   ( lite_conv2act_araddr   ) ,
      .m_axi_arprot   (                        ) ,
      .m_axi_arvalid  ( lite_conv2act_arvalid  ) ,
      .m_axi_arready  ( lite_act2conv_arready  ) ,
      .m_axi_rdata    ( lite_act2conv_rdata    ) ,
      .m_axi_rresp    ( lite_act2conv_rresp    ) ,
      .m_axi_rvalid   ( lite_act2conv_rvalid   ) ,
      .m_axi_rready   ( lite_conv2act_rready   )
    ); 
`else

    assign lite_conv2act_awaddr             = lite_snap2conv_awaddr             ;
    assign lite_conv2act_awprot             = lite_snap2conv_awprot             ;
    assign lite_conv2act_awvalid            = lite_snap2conv_awvalid            ;
    assign lite_conv2act_wdata              = lite_snap2conv_wdata              ;
    assign lite_conv2act_wstrb              = lite_snap2conv_wstrb              ;
    assign lite_conv2act_wvalid             = lite_snap2conv_wvalid             ;
    assign lite_conv2act_bready             = lite_snap2conv_bready             ;
    assign lite_conv2act_araddr             = lite_snap2conv_araddr             ;
    assign lite_conv2act_arprot             = lite_snap2conv_arprot             ;
    assign lite_conv2act_arvalid            = lite_snap2conv_arvalid            ;
    assign lite_conv2act_rready             = lite_snap2conv_rready             ;
    
    assign lite_conv2snap_awready            = lite_act2conv_awready            ;
    assign lite_conv2snap_wready             = lite_act2conv_wready             ;
    assign lite_conv2snap_bresp              = lite_act2conv_bresp              ;
    assign lite_conv2snap_bvalid             = lite_act2conv_bvalid             ;
    assign lite_conv2snap_arready            = lite_act2conv_arready            ;
    assign lite_conv2snap_rdata              = lite_act2conv_rdata              ;
    assign lite_conv2snap_rresp              = lite_act2conv_rresp              ;
    assign lite_conv2snap_rvalid             = lite_act2conv_rvalid             ;



`endif

  // // ********************************************************************************************************************************
  // // Convertors for AXI MM Data Path
  // // ********************************************************************************************************************************

`ifdef ACTION_HALF_WIDTH
  //
  // AXI_DWIDTH_CONVERTER
  //
 axi_dwidth_converter axi_dwidth_converter_act2snap (
      .s_axi_aclk        ( clock_act             ) ,
      .s_axi_aresetn     ( ~reset_action_q       ) ,
      .s_axi_awaddr      ( mm_act2conv_awaddr    ) ,
      .s_axi_awid        ( mm_act2conv_awid      ) ,
      .s_axi_awlen       ( mm_act2conv_awlen     ) ,
      .s_axi_awsize      ( mm_act2conv_awsize    ) ,
      .s_axi_awburst     ( mm_act2conv_awburst   ) ,
      .s_axi_awlock      ( 1'b0                   ) ,
      .s_axi_awcache     ( mm_act2conv_awcache   ) ,
      .s_axi_awprot      ( mm_act2conv_awprot    ) ,
      .s_axi_awregion    ( 4'h0                ) ,
      .s_axi_awqos       ( mm_act2conv_awqos     ) ,
      .s_axi_awvalid     ( mm_act2conv_awvalid   ) ,
      .s_axi_awready     ( mm_conv2act_awready   ) ,
      .s_axi_wdata       ( mm_act2conv_wdata     ) ,
      .s_axi_wstrb       ( mm_act2conv_wstrb     ) ,
      .s_axi_wlast       ( mm_act2conv_wlast     ) ,
      .s_axi_wvalid      ( mm_act2conv_wvalid    ) ,
      .s_axi_wready      ( mm_conv2act_wready    ) ,
      .s_axi_bresp       ( mm_conv2act_bresp     ) ,
      .s_axi_bvalid      ( mm_conv2act_bvalid    ) ,
      .s_axi_bid         ( mm_conv2act_bid       ) ,
      .s_axi_bready      ( mm_act2conv_bready    ) ,
      .s_axi_araddr      ( mm_act2conv_araddr    ) ,
      .s_axi_arid        ( mm_act2conv_arid      ) ,
      .s_axi_arlen       ( mm_act2conv_arlen     ) ,
      .s_axi_arsize      ( mm_act2conv_arsize    ) ,
      .s_axi_arburst     ( mm_act2conv_arburst   ) ,
      .s_axi_arlock      ( 1'b0                   ) ,
      .s_axi_arcache     ( mm_act2conv_arcache   ) ,
      .s_axi_arprot      ( mm_act2conv_arprot    ) ,
      .s_axi_arregion    ( 4'h0                ) ,
      .s_axi_arqos       ( mm_act2conv_arqos     ) ,
      .s_axi_arvalid     ( mm_act2conv_arvalid   ) ,
      .s_axi_arready     ( mm_conv2act_arready   ) ,
      .s_axi_rdata       ( mm_conv2act_rdata     ) ,
      .s_axi_rid         ( mm_conv2act_rid       ) ,
      .s_axi_rresp       ( mm_conv2act_rresp     ) ,
      .s_axi_rlast       ( mm_conv2act_rlast     ) ,
      .s_axi_rvalid      ( mm_conv2act_rvalid    ) ,
      .s_axi_rready      ( mm_act2conv_rready    ) ,

      .m_axi_aclk        ( clock_afu             ) ,
      .m_axi_aresetn     ( ~reset_nest_q         ) ,
      .m_axi_awaddr      ( mm_conv2snap_awaddr   ) ,
      .m_axi_awlen       ( mm_conv2snap_awlen    ) ,
      .m_axi_awsize      ( mm_conv2snap_awsize   ) ,
      .m_axi_awburst     ( mm_conv2snap_awburst  ) ,
      .m_axi_awlock      (                       ) ,
      .m_axi_awcache     ( mm_conv2snap_awcache  ) ,
      .m_axi_awprot      ( mm_conv2snap_awprot   ) ,
      .m_axi_awregion    ( mm_conv2snap_awregion ) ,
      .m_axi_awqos       ( mm_conv2snap_awqos    ) ,
      .m_axi_awvalid     ( mm_conv2snap_awvalid  ) ,
      .m_axi_awready     ( mm_snap2conv_awready  ) ,
      .m_axi_wdata       ( mm_conv2snap_wdata    ) ,
      .m_axi_wstrb       ( mm_conv2snap_wstrb    ) ,
      .m_axi_wlast       ( mm_conv2snap_wlast    ) ,
      .m_axi_wvalid      ( mm_conv2snap_wvalid   ) ,
      .m_axi_wready      ( mm_snap2conv_wready   ) ,
      .m_axi_bresp       ( mm_snap2conv_bresp    ) ,
      .m_axi_bvalid      ( mm_snap2conv_bvalid   ) ,
      .m_axi_bready      ( mm_conv2snap_bready   ) ,
      .m_axi_araddr      ( mm_conv2snap_araddr   ) ,
      .m_axi_arlen       ( mm_conv2snap_arlen    ) ,
      .m_axi_arsize      ( mm_conv2snap_arsize   ) ,
      .m_axi_arburst     ( mm_conv2snap_arburst  ) ,
      .m_axi_arlock      (                       ) ,
      .m_axi_arcache     ( mm_conv2snap_arcache  ) ,
      .m_axi_arprot      ( mm_conv2snap_arprot   ) ,
      .m_axi_arregion    ( mm_conv2snap_arregion ) ,
      .m_axi_arqos       ( mm_conv2snap_arqos    ) ,
      .m_axi_arvalid     ( mm_conv2snap_arvalid  ) ,
      .m_axi_arready     ( mm_snap2conv_arready  ) ,
      .m_axi_rdata       ( mm_snap2conv_rdata    ) ,
      .m_axi_rresp       ( mm_snap2conv_rresp    ) ,
      .m_axi_rlast       ( mm_snap2conv_rlast    ) ,
      .m_axi_rvalid      ( mm_snap2conv_rvalid   ) ,
      .m_axi_rready      ( mm_conv2snap_rready   )
) ; // axi_dwidth_converter

assign  mm_conv2snap_aruser = mm_act2conv_aruser;
assign  mm_conv2snap_awuser = mm_act2conv_awuser;

assign  mm_conv2snap_awid = {`IDW{1'b0}};
assign  mm_conv2snap_arid = {`IDW{1'b0}};

`else
  `ifdef ACTION_USER_CLOCK
  //
  // AXI_CLOCK_CONVERTER_ACT2SNAP
  //
  axi_clock_converter_act2snap axi_clkconv_act2snap (
      .s_axi_aclk                         ( clock_act             ) ,
      .s_axi_aresetn                      ( ~reset_action_q       ) ,
      .m_axi_aclk                         ( clock_afu             ) ,
      .m_axi_aresetn                      ( ~reset_nest_q         ) ,
      //
      // FROM ACTION
      .s_axi_araddr                       ( mm_act2conv_araddr    ) ,
      .s_axi_aruser                       ( mm_act2conv_aruser    ) ,
      .s_axi_arburst                      ( mm_act2conv_arburst   ) ,
      .s_axi_arcache                      ( mm_act2conv_arcache   ) ,
      .s_axi_arid                         ( mm_act2conv_arid      ) ,
      .s_axi_arlen                        ( mm_act2conv_arlen     ) ,
      .s_axi_arlock                       ( 1'b0                  ) ,
      .s_axi_arprot                       ( mm_act2conv_arprot    ) ,
      .s_axi_arqos                        ( mm_act2conv_arqos     ) ,
      .s_axi_arready                      ( mm_conv2act_arready   ) ,
      .s_axi_arregion                     ( 4'h0                  ) ,
      .s_axi_arsize                       ( mm_act2conv_arsize    ) ,
      .s_axi_arvalid                      ( mm_act2conv_arvalid   ) ,
      .s_axi_awaddr                       ( mm_act2conv_awaddr    ) ,
      .s_axi_awuser                       ( mm_act2conv_awuser    ) ,
      .s_axi_awburst                      ( mm_act2conv_awburst   ) ,
      .s_axi_awcache                      ( mm_act2conv_awcache   ) ,
      .s_axi_awid                         ( mm_act2conv_awid      ) ,
      .s_axi_awlen                        ( mm_act2conv_awlen     ) ,
      .s_axi_awlock                       ( 1'b0                   ) ,
      .s_axi_awprot                       ( mm_act2conv_awprot    ) ,
      .s_axi_awqos                        ( mm_act2conv_awqos     ) ,
      .s_axi_awready                      ( mm_conv2act_awready   ) ,
      .s_axi_awregion                     ( 4'h0                ) ,
      .s_axi_awsize                       ( mm_act2conv_awsize    ) ,
      .s_axi_awvalid                      ( mm_act2conv_awvalid   ) ,
      .s_axi_bid                          ( mm_conv2act_bid       ) ,
      .s_axi_buser                        ( mm_conv2act_buser     ) ,
      .s_axi_bready                       ( mm_act2conv_bready    ) ,
      .s_axi_bresp                        ( mm_conv2act_bresp     ) ,
      .s_axi_bvalid                       ( mm_conv2act_bvalid    ) ,
      .s_axi_rdata                        ( mm_conv2act_rdata     ) ,
      .s_axi_rid                          ( mm_conv2act_rid       ) ,
      .s_axi_ruser                        ( mm_conv2act_ruser     ) ,
      .s_axi_rlast                        ( mm_conv2act_rlast     ) ,
      .s_axi_rready                       ( mm_act2conv_rready    ) ,
      .s_axi_rresp                        ( mm_conv2act_rresp     ) ,
      .s_axi_rvalid                       ( mm_conv2act_rvalid    ) ,
      .s_axi_wdata                        ( mm_act2conv_wdata     ) ,
      .s_axi_wuser                        ( mm_act2conv_wuser     ) ,
      .s_axi_wlast                        ( mm_act2conv_wlast     ) ,
      .s_axi_wready                       ( mm_conv2act_wready    ) ,
      .s_axi_wstrb                        ( mm_act2conv_wstrb     ) ,
      .s_axi_wvalid                       ( mm_act2conv_wvalid    ) ,
      //
      // TO SNAP
      .m_axi_araddr                       ( mm_conv2snap_araddr   ) ,
      .m_axi_aruser                       ( mm_conv2snap_aruser   ) ,
      .m_axi_arburst                      ( mm_conv2snap_arburst  ) ,
      .m_axi_arcache                      ( mm_conv2snap_arcache  ) ,
      .m_axi_arid                         ( mm_conv2snap_arid     ) ,
      .m_axi_arlen                        ( mm_conv2snap_arlen    ) ,
      .m_axi_arlock                       (                       ) ,
      .m_axi_arprot                       ( mm_conv2snap_arprot   ) ,
      .m_axi_arqos                        ( mm_conv2snap_arqos    ) ,
      .m_axi_arready                      ( mm_snap2conv_arready  ) ,
      .m_axi_arregion                     ( mm_conv2snap_arregion ) ,
      .m_axi_arsize                       ( mm_conv2snap_arsize   ) ,
      .m_axi_arvalid                      ( mm_conv2snap_arvalid  ) ,
      .m_axi_awaddr                       ( mm_conv2snap_awaddr   ) ,
      .m_axi_awuser                       ( mm_conv2snap_awuser   ) ,
      .m_axi_awburst                      ( mm_conv2snap_awburst  ) ,
      .m_axi_awcache                      ( mm_conv2snap_awcache  ) ,
      .m_axi_awid                         ( mm_conv2snap_awid     ) ,
      .m_axi_awlen                        ( mm_conv2snap_awlen    ) ,
      .m_axi_awlock                       (                       ) ,
      .m_axi_awprot                       ( mm_conv2snap_awprot   ) ,
      .m_axi_awqos                        ( mm_conv2snap_awqos    ) ,
      .m_axi_awready                      ( mm_snap2conv_awready  ) ,
      .m_axi_awregion                     ( mm_conv2snap_awregion ) ,
      .m_axi_awsize                       ( mm_conv2snap_awsize   ) ,
      .m_axi_awvalid                      ( mm_conv2snap_awvalid  ) ,
      .m_axi_bid                          ( mm_snap2conv_bid      ) ,
      .m_axi_buser                        ( mm_snap2conv_buser    ) ,
      .m_axi_bready                       ( mm_conv2snap_bready   ) ,
      .m_axi_bresp                        ( mm_snap2conv_bresp    ) ,
      .m_axi_bvalid                       ( mm_snap2conv_bvalid   ) ,
      .m_axi_rdata                        ( mm_snap2conv_rdata    ) ,
      .m_axi_rid                          ( mm_snap2conv_rid      ) ,
      .m_axi_ruser                        ( mm_snap2conv_ruser    ) ,
      .m_axi_rlast                        ( mm_snap2conv_rlast    ) ,
      .m_axi_rready                       ( mm_conv2snap_rready   ) ,
      .m_axi_rresp                        ( mm_snap2conv_rresp    ) ,
      .m_axi_rvalid                       ( mm_snap2conv_rvalid   ) ,
      .m_axi_wdata                        ( mm_conv2snap_wdata    ) ,
      .m_axi_wuser                        ( mm_conv2snap_wuser    ) ,
      .m_axi_wlast                        ( mm_conv2snap_wlast    ) ,
      .m_axi_wready                       ( mm_snap2conv_wready   ) ,
      .m_axi_wstrb                        ( mm_conv2snap_wstrb    ) ,
      .m_axi_wvalid                       ( mm_conv2snap_wvalid   )
 ) ;

  `else
  //No dwith converter, no clock convertor
  //direct connect

assign mm_conv2act_awready              = mm_snap2conv_awready              ;
assign mm_conv2act_wready               = mm_snap2conv_wready               ;
assign mm_conv2act_bid                  = mm_snap2conv_bid                  ;
assign mm_conv2act_bresp                = mm_snap2conv_bresp                ;
assign mm_conv2act_bvalid               = mm_snap2conv_bvalid               ;
assign mm_conv2act_rid                  = mm_snap2conv_rid                  ;
assign mm_conv2act_rdata                = mm_snap2conv_rdata                ;
assign mm_conv2act_rresp                = mm_snap2conv_rresp                ;
assign mm_conv2act_rlast                = mm_snap2conv_rlast                ;
assign mm_conv2act_rvalid               = mm_snap2conv_rvalid               ;
assign mm_conv2act_arready              = mm_snap2conv_arready              ;

assign mm_conv2snap_awid                 = mm_act2conv_awid                 ;
assign mm_conv2snap_awaddr               = mm_act2conv_awaddr               ;
assign mm_conv2snap_awlen                = mm_act2conv_awlen                ;
assign mm_conv2snap_awsize               = mm_act2conv_awsize               ;
assign mm_conv2snap_awburst              = mm_act2conv_awburst              ;
assign mm_conv2snap_awlock               = mm_act2conv_awlock               ;
assign mm_conv2snap_awcache              = mm_act2conv_awcache              ;
assign mm_conv2snap_awprot               = mm_act2conv_awprot               ;
assign mm_conv2snap_awqos                = mm_act2conv_awqos                ;
assign mm_conv2snap_awregion             = mm_act2conv_awregion             ;
assign mm_conv2snap_awuser               = mm_act2conv_awuser               ;
assign mm_conv2snap_awvalid              = mm_act2conv_awvalid              ;
assign mm_conv2snap_wdata                = mm_act2conv_wdata                ;
assign mm_conv2snap_wstrb                = mm_act2conv_wstrb                ;
assign mm_conv2snap_wlast                = mm_act2conv_wlast                ;
assign mm_conv2snap_wvalid               = mm_act2conv_wvalid               ;
assign mm_conv2snap_bready               = mm_act2conv_bready               ;
assign mm_conv2snap_arid                 = mm_act2conv_arid                 ;
assign mm_conv2snap_araddr               = mm_act2conv_araddr               ;
assign mm_conv2snap_arlen                = mm_act2conv_arlen                ;
assign mm_conv2snap_arsize               = mm_act2conv_arsize               ;
assign mm_conv2snap_arburst              = mm_act2conv_arburst              ;
assign mm_conv2snap_aruser               = mm_act2conv_aruser               ;
assign mm_conv2snap_arlock               = mm_act2conv_arlock               ;
assign mm_conv2snap_arcache              = mm_act2conv_arcache              ;
assign mm_conv2snap_arprot               = mm_act2conv_arprot               ;
assign mm_conv2snap_arqos                = mm_act2conv_arqos                ;
assign mm_conv2snap_arregion             = mm_act2conv_arregion             ;
assign mm_conv2snap_arvalid              = mm_act2conv_arvalid              ;
assign mm_conv2snap_rready               = mm_act2conv_rready               ;
  
  `endif
`endif

`endif  // endif for ifndef ENABLE_ODMA



  // // ********************************************************************************************************************************
  // // Convertor for Action to Card mem controller
  // // ********************************************************************************************************************************


`ifdef ENABLE_AXI_CARD_MEM
  //
  // AXI_CLOCK_CONVERTER_ACT2MEM
  //
  axi_clock_converter_act2mem axi_clkconv_act2mem (
      .s_axi_aclk                         ( clock_act                           ) ,
      .s_axi_aresetn                      ( ~reset_action_q                     ) ,
      .m_axi_aclk                         ( clock_mem                           ) ,
      .m_axi_aresetn                      ( memctl0_axi_rst_n                   ) ,
      //
      // FROM ACTION
      .s_axi_araddr                       ( act_axi_card_mem0_araddr            ) ,
      .s_axi_arburst                      ( act_axi_card_mem0_arburst           ) ,
      .s_axi_arcache                      ( act_axi_card_mem0_arcache           ) ,
      .s_axi_arid                         ( act_axi_card_mem0_arid              ) ,
      .s_axi_arlen                        ( act_axi_card_mem0_arlen             ) ,
      .s_axi_arlock                       ( act_axi_card_mem0_arlock[0]         ) ,
      .s_axi_arprot                       ( act_axi_card_mem0_arprot            ) ,
      .s_axi_arqos                        ( act_axi_card_mem0_arqos             ) ,
      .s_axi_arready                      ( act_axi_card_mem0_arready           ) ,
      .s_axi_arregion                     ( act_axi_card_mem0_arregion          ) ,
      .s_axi_arsize                       ( act_axi_card_mem0_arsize            ) ,
      .s_axi_arvalid                      ( act_axi_card_mem0_arvalid           ) ,
      .s_axi_awaddr                       ( act_axi_card_mem0_awaddr            ) ,
      .s_axi_awburst                      ( act_axi_card_mem0_awburst           ) ,
      .s_axi_awcache                      ( act_axi_card_mem0_awcache           ) ,
      .s_axi_awid                         ( act_axi_card_mem0_awid              ) ,
      .s_axi_awlen                        ( act_axi_card_mem0_awlen             ) ,
      .s_axi_awlock                       ( act_axi_card_mem0_awlock[0]         ) ,
      .s_axi_awprot                       ( act_axi_card_mem0_awprot            ) ,
      .s_axi_awqos                        ( act_axi_card_mem0_awqos             ) ,
      .s_axi_awready                      ( act_axi_card_mem0_awready           ) ,
      .s_axi_awregion                     ( act_axi_card_mem0_awregion          ) ,
      .s_axi_awsize                       ( act_axi_card_mem0_awsize            ) ,
      .s_axi_awvalid                      ( act_axi_card_mem0_awvalid           ) ,
      .s_axi_bid                          ( act_axi_card_mem0_bid               ) ,
      .s_axi_bready                       ( act_axi_card_mem0_bready            ) ,
      .s_axi_bresp                        ( act_axi_card_mem0_bresp             ) ,
      .s_axi_bvalid                       ( act_axi_card_mem0_bvalid            ) ,
      .s_axi_rdata                        ( act_axi_card_mem0_rdata             ) ,
      .s_axi_rid                          ( act_axi_card_mem0_rid               ) ,
      .s_axi_rlast                        ( act_axi_card_mem0_rlast             ) ,
      .s_axi_rready                       ( act_axi_card_mem0_rready            ) ,
      .s_axi_rresp                        ( act_axi_card_mem0_rresp             ) ,
      .s_axi_rvalid                       ( act_axi_card_mem0_rvalid            ) ,
      .s_axi_wdata                        ( act_axi_card_mem0_wdata             ) ,
      .s_axi_wlast                        ( act_axi_card_mem0_wlast             ) ,
      .s_axi_wready                       ( act_axi_card_mem0_wready            ) ,
      .s_axi_wstrb                        ( act_axi_card_mem0_wstrb             ) ,
      .s_axi_wvalid                       ( act_axi_card_mem0_wvalid            ) ,
      //
      // TO DDR MIG or BRAM
      .m_axi_araddr                       ( memctl0_axi_araddr                  ) ,
      .m_axi_arburst                      ( memctl0_axi_arburst                 ) ,
      .m_axi_arcache                      ( memctl0_axi_arcache                 ) ,
      .m_axi_arid                         ( memctl0_axi_arid                    ) ,
      .m_axi_arlen                        ( memctl0_axi_arlen                   ) ,
      .m_axi_arlock                       ( memctl0_axi_arlock                  ) ,
      .m_axi_arprot                       ( memctl0_axi_arprot                  ) ,
      .m_axi_arqos                        ( memctl0_axi_arqos                   ) ,
      .m_axi_arready                      ( memctl0_axi_arready                 ) ,
      .m_axi_arregion                     ( memctl0_axi_arregion                ) ,
      .m_axi_arsize                       ( memctl0_axi_arsize                  ) ,
      .m_axi_arvalid                      ( memctl0_axi_arvalid                 ) ,
      .m_axi_awaddr                       ( memctl0_axi_awaddr                  ) ,
      .m_axi_awburst                      ( memctl0_axi_awburst                 ) ,
      .m_axi_awcache                      ( memctl0_axi_awcache                 ) ,
      .m_axi_awid                         ( memctl0_axi_awid                    ) ,
      .m_axi_awlen                        ( memctl0_axi_awlen                   ) ,
      .m_axi_awlock                       ( memctl0_axi_awlock                  ) ,
      .m_axi_awprot                       ( memctl0_axi_awprot                  ) ,
      .m_axi_awqos                        ( memctl0_axi_awqos                   ) ,
      .m_axi_awready                      ( memctl0_axi_awready                 ) ,
      .m_axi_awregion                     ( memctl0_axi_awregion                ) ,
      .m_axi_awsize                       ( memctl0_axi_awsize                  ) ,
      .m_axi_awvalid                      ( memctl0_axi_awvalid                 ) ,
      .m_axi_bid                          ( memctl0_axi_bid                     ) ,
      .m_axi_bready                       ( memctl0_axi_bready                  ) ,
      .m_axi_bresp                        ( memctl0_axi_bresp                   ) ,
      .m_axi_bvalid                       ( memctl0_axi_bvalid                  ) ,
      .m_axi_rdata                        ( memctl0_axi_rdata                   ) ,
      .m_axi_rid                          ( memctl0_axi_rid                     ) ,
      .m_axi_rlast                        ( memctl0_axi_rlast                   ) ,
      .m_axi_rready                       ( memctl0_axi_rready                  ) ,
      .m_axi_rresp                        ( memctl0_axi_rresp                   ) ,
      .m_axi_rvalid                       ( memctl0_axi_rvalid                  ) ,
      .m_axi_wdata                        ( memctl0_axi_wdata                   ) ,
      .m_axi_wlast                        ( memctl0_axi_wlast                   ) ,
      .m_axi_wready                       ( memctl0_axi_wready                  ) ,
      .m_axi_wstrb                        ( memctl0_axi_wstrb                   ) ,
      .m_axi_wvalid                       ( memctl0_axi_wvalid                  )
    );  // axi_clkconv_act2mem: axi_clock_converter_act2mem

  //
  // SDRAM
  //
assign  memctl0_axi_ctrl_awvalid   = 0;
assign  memctl0_axi_ctrl_awaddr    = 0;
assign  memctl0_axi_ctrl_wvalid    = 0;
assign  memctl0_axi_ctrl_wdata     = 0;
assign  memctl0_axi_ctrl_bready    = 0;
assign  memctl0_axi_ctrl_arvalid   = 0;
assign  memctl0_axi_ctrl_araddr    = 0;
assign  memctl0_axi_ctrl_rready    = 0;

`endif



  // // ********************************************************************************************************************************
  // // Card mem controllers
  // // ********************************************************************************************************************************





`ifdef ENABLE_BRAM
  //
  // BLOCK RAM
  //
  block_RAM block_ram_i0
  (
      .s_aresetn                          ( memctl0_axi_rst_n                              ) ,
      .s_aclk                             ( clock_mem                                      ) ,
      .s_axi_araddr                       ( memctl0_axi_araddr[31 : 0]                     ) ,
      .s_axi_arburst                      ( memctl0_axi_arburst                            ) ,
      .s_axi_arid                         ( memctl0_axi_arid                               ) ,
      .s_axi_arlen                        ( memctl0_axi_arlen                              ) ,
      .s_axi_arready                      ( memctl0_axi_arready                            ) ,
      .s_axi_arsize                       ( 3'b101                                         ) ,
      .s_axi_arvalid                      ( memctl0_axi_arvalid                            ) ,
      .s_axi_awaddr                       ( memctl0_axi_awaddr[31 : 0]                     ) ,
      .s_axi_awburst                      ( memctl0_axi_awburst                            ) ,
      .s_axi_awid                         ( memctl0_axi_awid                               ) ,
      .s_axi_awlen                        ( memctl0_axi_awlen                              ) ,
      .s_axi_awready                      ( memctl0_axi_awready                            ) ,
      .s_axi_awsize                       ( 3'b101                                         ) ,
      .s_axi_awvalid                      ( memctl0_axi_awvalid                            ) ,
      .s_axi_bid                          ( memctl0_axi_bid                                ) ,
      .s_axi_bready                       ( memctl0_axi_bready                             ) ,
      .s_axi_bresp                        ( memctl0_axi_bresp                              ) ,
      .s_axi_bvalid                       ( memctl0_axi_bvalid                             ) ,
      .s_axi_rdata                        ( memctl0_axi_rdata[(`AXI_CARD_MEM_DATA_WIDTH/2-1 ): 0]    ) ,
      .s_axi_rid                          ( memctl0_axi_rid                                ) ,
      .s_axi_rlast                        ( memctl0_axi_rlast                              ) ,
      .s_axi_rready                       ( memctl0_axi_rready                             ) ,
      .s_axi_rresp                        ( memctl0_axi_rresp                              ) ,
      .s_axi_rvalid                       ( memctl0_axi_rvalid                             ) ,
      .s_axi_wdata                        ( memctl0_axi_wdata[(`AXI_CARD_MEM_DATA_WIDTH/2) -1 : 0] ) ,
      .s_axi_wlast                        ( memctl0_axi_wlast                              ) ,
      .s_axi_wready                       ( memctl0_axi_wready                             ) ,
      .s_axi_wstrb                        ( memctl0_axi_wstrb[(`AXI_CARD_MEM_DATA_WIDTH/16) -1 : 0] ) ,
      .s_axi_wvalid                       ( memctl0_axi_wvalid                             )
    );  // block_ram_i0: block_RAM

block_RAM block_ram_i1
    (
      .s_aresetn                          ( memctl0_axi_rst_n                                                        ) ,
      .s_aclk                             ( clock_mem                                                                ) ,
      .s_axi_araddr                       ( memctl0_axi_araddr[31 : 0]                                               ) ,
      .s_axi_arburst                      ( memctl0_axi_arburst                                                      ) ,
      .s_axi_arid                         ( memctl0_axi_arid                                                         ) ,
      .s_axi_arlen                        ( memctl0_axi_arlen                                                        ) ,
      .s_axi_arready                      (                                                                          ) ,
      .s_axi_arsize                       ( 3'b101                                                                   ) ,
      .s_axi_arvalid                      ( memctl0_axi_arvalid                                                      ) ,
      .s_axi_awaddr                       ( memctl0_axi_awaddr[31 : 0]                                               ) ,
      .s_axi_awburst                      ( memctl0_axi_awburst                                                      ) ,
      .s_axi_awid                         ( memctl0_axi_awid                                                         ) ,
      .s_axi_awlen                        ( memctl0_axi_awlen                                                        ) ,
      .s_axi_awready                      (                                                                          ) ,
      .s_axi_awsize                       ( 3'b101                                                                   ) ,
      .s_axi_awvalid                      ( memctl0_axi_awvalid                                                      ) ,
      .s_axi_bid                          (                                                                          ) ,
      .s_axi_bready                       ( memctl0_axi_bready                                                       ) ,
      .s_axi_bresp                        (                                                                          ) ,
      .s_axi_bvalid                       (                                                                          ) ,
      .s_axi_rdata                        ( memctl0_axi_rdata[`AXI_CARD_MEM_DATA_WIDTH-1 : (`AXI_CARD_MEM_DATA_WIDTH/2)]) ,
      .s_axi_rid                          (                                                                          ) ,
      .s_axi_rlast                        (                                                                          ) ,
      .s_axi_rready                       ( memctl0_axi_rready                                                       ) ,
      .s_axi_rresp                        (                                                                          ) ,
      .s_axi_rvalid                       (                                                                          ) ,
      .s_axi_wdata                        ( memctl0_axi_wdata[`AXI_CARD_MEM_DATA_WIDTH-1 : (`AXI_CARD_MEM_DATA_WIDTH/2)]) ,
      .s_axi_wlast                        ( memctl0_axi_wlast                                                        ) ,
      .s_axi_wready                       (                                                                          ) ,
      .s_axi_wstrb                        ( memctl0_axi_wstrb[(`AXI_CARD_MEM_DATA_WIDTH/8)-1 : (`AXI_CARD_MEM_DATA_WIDTH/16)]) ,
      .s_axi_wvalid                       ( memctl0_axi_wvalid                                                       )
    );  // block_ram_i1: block_RAM
`endif



`ifdef ENABLE_DDR
`ifdef AD9V3
  //
  // DDR4SDRAM
  //
     ddr4sdram ddr4memctl0_bank
      (
      .c0_init_calib_complete      ( memctl0_init_calib_complete ) ,
      .dbg_clk                     ( ddr4_dbg_clk                ) ,
      .c0_sys_clk_p                ( c0_sys_clk_p                ) ,
      .c0_sys_clk_n                ( c0_sys_clk_n                ) ,
      .dbg_bus                     ( ddr4_dbg_bus                ) ,
      .c0_ddr4_adr                 ( c0_ddr4_adr                 ) ,
      .c0_ddr4_ba                  ( c0_ddr4_ba                  ) ,
      .c0_ddr4_cke                 ( c0_ddr4_cke                 ) ,
      .c0_ddr4_cs_n                ( c0_ddr4_cs_n                ) ,
      .c0_ddr4_dm_dbi_n            ( c0_ddr4_dm_dbi_n            ) ,
      .c0_ddr4_dq                  ( c0_ddr4_dq                  ) ,
      .c0_ddr4_dqs_c               ( c0_ddr4_dqs_c               ) ,
      .c0_ddr4_dqs_t               ( c0_ddr4_dqs_t               ) ,
      .c0_ddr4_odt                 ( c0_ddr4_odt                 ) ,
      .c0_ddr4_bg                  ( c0_ddr4_bg                  ) ,
      .c0_ddr4_reset_n             ( c0_ddr4_reset_n             ) ,
      .c0_ddr4_act_n               ( c0_ddr4_act_n               ) ,
      .c0_ddr4_ck_c                ( c0_ddr4_ck_c                ) ,
      .c0_ddr4_ck_t                ( c0_ddr4_ck_t                ) ,
      .c0_ddr4_ui_clk              ( memctl0_ui_clk              ) ,//output
      .c0_ddr4_ui_clk_sync_rst     ( memctl0_ui_clk_sync_rst     ) ,//output
      .c0_ddr4_aresetn             ( memctl0_axi_rst_n           ) ,
      .c0_ddr4_s_axi_ctrl_awvalid  ( memctl0_axi_ctrl_awvalid    ) ,
      .c0_ddr4_s_axi_ctrl_awready  ( memctl0_axi_ctrl_awready    ) ,
      .c0_ddr4_s_axi_ctrl_awaddr   ( memctl0_axi_ctrl_awaddr     ) ,
      .c0_ddr4_s_axi_ctrl_wvalid   ( memctl0_axi_ctrl_wvalid     ) ,
      .c0_ddr4_s_axi_ctrl_wready   ( memctl0_axi_ctrl_wready     ) ,
      .c0_ddr4_s_axi_ctrl_wdata    ( memctl0_axi_ctrl_wdata      ) ,
      .c0_ddr4_s_axi_ctrl_bvalid   ( memctl0_axi_ctrl_bvalid     ) ,
      .c0_ddr4_s_axi_ctrl_bready   ( memctl0_axi_ctrl_bready     ) ,
      .c0_ddr4_s_axi_ctrl_bresp    ( memctl0_axi_ctrl_bresp      ) ,
      .c0_ddr4_s_axi_ctrl_arvalid  ( memctl0_axi_ctrl_arvalid    ) ,
      .c0_ddr4_s_axi_ctrl_arready  ( memctl0_axi_ctrl_arready    ) ,
      .c0_ddr4_s_axi_ctrl_araddr   ( memctl0_axi_ctrl_araddr     ) ,
      .c0_ddr4_s_axi_ctrl_rvalid   ( memctl0_axi_ctrl_rvalid     ) ,
      .c0_ddr4_s_axi_ctrl_rready   ( memctl0_axi_ctrl_rready     ) ,
      .c0_ddr4_s_axi_ctrl_rdata    ( memctl0_axi_ctrl_rdata      ) ,
      .c0_ddr4_s_axi_ctrl_rresp    ( memctl0_axi_ctrl_rresp      ) ,
      .c0_ddr4_interrupt           ( memctl0_interrupt           ) ,
      .c0_ddr4_s_axi_awid          ( memctl0_axi_awid            ) ,
      .c0_ddr4_s_axi_awaddr        ( memctl0_axi_awaddr          ) ,
      .c0_ddr4_s_axi_awlen         ( memctl0_axi_awlen           ) ,
      .c0_ddr4_s_axi_awsize        ( memctl0_axi_awsize          ) ,
      .c0_ddr4_s_axi_awburst       ( memctl0_axi_awburst         ) ,
      .c0_ddr4_s_axi_awlock        ( memctl0_axi_awlock          ) ,
      .c0_ddr4_s_axi_awcache       ( memctl0_axi_awcache         ) ,
      .c0_ddr4_s_axi_awprot        ( memctl0_axi_awprot          ) ,
      .c0_ddr4_s_axi_awqos         ( memctl0_axi_awqos           ) ,
      .c0_ddr4_s_axi_awvalid       ( memctl0_axi_awvalid         ) ,
      .c0_ddr4_s_axi_awready       ( memctl0_axi_awready         ) ,
      .c0_ddr4_s_axi_wdata         ( memctl0_axi_wdata           ) ,
      .c0_ddr4_s_axi_wstrb         ( memctl0_axi_wstrb           ) ,
      .c0_ddr4_s_axi_wlast         ( memctl0_axi_wlast           ) ,
      .c0_ddr4_s_axi_wvalid        ( memctl0_axi_wvalid          ) ,
      .c0_ddr4_s_axi_wready        ( memctl0_axi_wready          ) ,
      .c0_ddr4_s_axi_bready        ( memctl0_axi_bready          ) ,
      .c0_ddr4_s_axi_bid           ( memctl0_axi_bid             ) ,
      .c0_ddr4_s_axi_bresp         ( memctl0_axi_bresp           ) ,
      .c0_ddr4_s_axi_bvalid        ( memctl0_axi_bvalid          ) ,
      .c0_ddr4_s_axi_arid          ( memctl0_axi_arid            ) ,
      .c0_ddr4_s_axi_araddr        ( memctl0_axi_araddr          ) ,
      .c0_ddr4_s_axi_arlen         ( memctl0_axi_arlen           ) ,
      .c0_ddr4_s_axi_arsize        ( memctl0_axi_arsize          ) ,
      .c0_ddr4_s_axi_arburst       ( memctl0_axi_arburst         ) ,
      .c0_ddr4_s_axi_arlock        ( memctl0_axi_arlock          ) ,
      .c0_ddr4_s_axi_arcache       ( memctl0_axi_arcache         ) ,
      .c0_ddr4_s_axi_arprot        ( memctl0_axi_arprot          ) ,
      .c0_ddr4_s_axi_arqos         ( memctl0_axi_arqos           ) ,
      .c0_ddr4_s_axi_arvalid       ( memctl0_axi_arvalid         ) ,
      .c0_ddr4_s_axi_arready       ( memctl0_axi_arready         ) ,
      .c0_ddr4_s_axi_rready        ( memctl0_axi_rready          ) ,
      .c0_ddr4_s_axi_rlast         ( memctl0_axi_rlast           ) ,
      .c0_ddr4_s_axi_rvalid        ( memctl0_axi_rvalid          ) ,
      .c0_ddr4_s_axi_rresp         ( memctl0_axi_rresp           ) ,
      .c0_ddr4_s_axi_rid           ( memctl0_axi_rid             ) ,
      .c0_ddr4_s_axi_rdata         ( memctl0_axi_rdata           ) ,
      .sys_rst                     ( memctl0_reset_q             )
    );
`endif
`endif

endmodule

