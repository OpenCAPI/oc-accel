//=============================================================================
//                                 oc_host_if
//                     The module to talk to OpenCAPI links
//=============================================================================
//  External interfaces:
//=============================================================================
//   <=> VPD
//   <=> Flash Subsystem
//   <=> PHY IO
//   <=> oc-infrastructure
//           <----> TLX to AFU (Master)
//           <----> AFU to TLX (Slave)
//           <----> Configuration ports
//
//
//=============================================================================
//  Note:
//        oc_cfg is different than the original, it contains cfg_descriptor
//        and cfg_func1
//
//        dlx_phy_wrap and cfg_tieoffs are FPGACARD Specific
//  Modules:
//=============================================================================
//  dlx_phy_wrap
//  ocx_tlx_top
//  cfg_reg_to_axilite (for flash subsystem)
//  oc_cfg_wrap (new)
//       --- cfg_fence
//       --- cfg_seq
//       --- cfg_cmdfifo
//       --- cfg_respfifo
//       --- cfg_func0
//       --- cfg_descriptor
//       --- cfg_func1
//       --- cfg_tieoffs
//=============================================================================
//  Associated Constraint file: oc_host_if.xdc (FPGACARD Specific)
`timescale 1ns/1ps




module oc_host_if (

//=============================================================================
//                              Reset and clock
  // -- Reset
    input                 ocde              // FPGA board reset input
   ,output                clock_afu         // From dlx_phy 201MHz
   ,output                clock_tlx         // From dlx_phy 402MHz
   ,output                reset_tlx_n      
   ,output                reset_afu
//=============================================================================
//                              PHY
   ,input                 freerun_clk_p
   ,input                 freerun_clk_n

  // -- Phy Interface
   ,output                ch0_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch0_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch1_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch1_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch2_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch2_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch3_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch3_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch4_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch4_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch5_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch5_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch6_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch6_gtytxp_out     // -- XLX PHY transmit channels
   ,output                ch7_gtytxn_out     // -- XLX PHY transmit channels
   ,output                ch7_gtytxp_out     // -- XLX PHY transmit channels

   ,input                 ch0_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch0_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch1_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch1_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch2_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch2_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch3_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch3_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch4_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch4_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch5_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch5_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch6_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch6_gtyrxp_in      // -- XLX PHY receive channels
   ,input                 ch7_gtyrxn_in      // -- XLX PHY receive channels
   ,input                 ch7_gtyrxp_in      // -- XLX PHY receive channels

   ,input                 mgtrefclk1_x0y0_p  // -- XLX PHY transcieve clocks 156.25 MHz
   ,input                 mgtrefclk1_x0y0_n  // -- XLX PHY transcieve clocks 156.25 MHz
   ,input                 mgtrefclk1_x0y1_p  // -- XLX PHY transcieve clocks 156.25 MHz
   ,input                 mgtrefclk1_x0y1_n  // -- XLX PHY transcieve clocks 156.25 MHz

//=============================================================================
//                           VPD

  , output  [14:0] cfg_vpd_addr               // Address for write or read
  , output         cfg_vpd_wren               // Held at 1 to write a location until it sees vpd_done = 1 then clear to 0
  , output  [31:0] cfg_vpd_wdata              // Contains data to write to VPD register (valid while wren=1)
  , output         cfg_vpd_rden               // Held at 1 to read  a location until it sees vpd_done = 1 then clear to 0
  , input [31:0]   vpd_cfg_rdata              // Contains data read back from VPD register (valid when rden=1 and vpd_done=1)
  , input          vpd_cfg_done               // VPD pulses to 1 for 1 cycle when write is complete, or when rdata contains valid results

    // Error indicator
  , input          vpd_err_unimplemented_addr // Connect into internal error vector if desired

//=============================================================================
//                           Flash Subsystem

    // Interface to CFG registers, which act as an AXI4-Lite Master
  , output    [1:0] cfg_flsh_devsel         // Select which AXI4-Lite slave is the target of the command
  , output   [13:0] cfg_flsh_addr           // Read or write address to selected target (set upper unused bits to 0)
  , output          cfg_flsh_wren           // Set to 1 to write a location, held stable through operation until done=1
  , output   [31:0] cfg_flsh_wdata          // Contains write data (valid while wren=1)
  , output          cfg_flsh_rden           // Set to 1 to read  a location, held stable through operation until done=1
  , input  [31:0]   flsh_cfg_rdata          // Contains read data (valid when rden=1 and done=1)
  , input           flsh_cfg_done           // AXI logic pulses to 1 for 1 cycle when write is complete, or when rdata contains valid results
  , input   [1:0]   flsh_cfg_bresp          // Write response from selected AXI4-Lite device
  , input   [1:0]   flsh_cfg_rresp          // Read  response from selected AXI4-Lite device
  , input   [7:0]   flsh_cfg_status         // Device Specific status information
  , output          cfg_flsh_expand_enable     // When 1, expand/collapse 4 bytes of data into four, 1 byte AXI operations
  , output          cfg_flsh_expand_dir        // When 0, expand bytes [3:0] in order 0,1,2,3 . When 1, expand in order 3,2,1,0 .

//=============================================================================
//                           oc-infrastructure

//configuration
   , output [3:0]                             cfg_infra_backoff_timer
   , output [7:0]                             cfg_infra_bdf_bus
   , output [4:0]                             cfg_infra_bdf_device
   , output [2:0]                             cfg_infra_bdf_function
   , output [11:0]                            cfg_infra_actag_base
   , output [19:0]                            cfg_infra_pasid_base
   , output [4:0]                             cfg_infra_pasid_length
   , output [63:0]                            cfg_infra_f1_mmio_bar0
   , output [63:0]                            cfg_infra_f1_mmio_bar0_mask

//AFU-TLX command transmit interface
   , input                                  afu_tlx_cmd_valid
   , input [7:0]                            afu_tlx_cmd_opcode
   , input [11:0]                           afu_tlx_cmd_actag
   , input [3:0]                            afu_tlx_cmd_stream_id
   , input [67:0]                           afu_tlx_cmd_ea_or_obj
   , input [15:0]                           afu_tlx_cmd_afutag
   , input [1:0]                            afu_tlx_cmd_dl
   , input [2:0]                            afu_tlx_cmd_pl
   , input                                  afu_tlx_cmd_os
   , input [63:0]                           afu_tlx_cmd_be
   , input [3:0]                            afu_tlx_cmd_flag
   , input                                  afu_tlx_cmd_endian
   , input [15:0]                           afu_tlx_cmd_bdf
   , input [19:0]                           afu_tlx_cmd_pasid
   , input [5:0]                            afu_tlx_cmd_pg_size
   , input                                  afu_tlx_cdata_valid
   , input                                  afu_tlx_cdata_bdi
   , input [511:0]                          afu_tlx_cdata_bus
   , output                                 tlx_afu_cmd_credit
   , output                                 tlx_afu_cmd_data_credit
   , output [3:0]                           tlx_afu_cmd_initial_credit
   , output [5:0]                           tlx_afu_cmd_data_initial_credit
//
//TLX-AFU response receive interface
   , output                                 tlx_afu_resp_valid
   , output [7:0]                           tlx_afu_resp_opcode
   , output [15:0]                          tlx_afu_resp_afutag
   , output [3:0]                           tlx_afu_resp_code
   , output [1:0]                           tlx_afu_resp_dl
   , output [1:0]                           tlx_afu_resp_dp
   , input                                  afu_tlx_resp_rd_req
   , input [2:0]                            afu_tlx_resp_rd_cnt
   , output                                 tlx_afu_resp_data_valid
   , output                                 tlx_afu_resp_data_bdi
   , output [511:0]                         tlx_afu_resp_data_bus
   , input                                  afu_tlx_resp_credit
   , input [6:0]                            afu_tlx_resp_initial_credit
//
//TLX-AFU command receive interface
   , output                                 tlx_afu_cmd_valid
   , output [7:0]                           tlx_afu_cmd_opcode
   , output [15:0]                          tlx_afu_cmd_capptag
   , output [1:0]                           tlx_afu_cmd_dl
   , output [2:0]                           tlx_afu_cmd_pl
   , output [63:0]                          tlx_afu_cmd_be
   , output                                 tlx_afu_cmd_end
   , output [63:0]                          tlx_afu_cmd_pa
   , output [3:0]                           tlx_afu_cmd_flag
   , output                                 tlx_afu_cmd_os

   , input                                  afu_tlx_cmd_credit
   , input [6:0]                            afu_tlx_cmd_initial_credit

   , input                                  afu_tlx_cmd_rd_req
   , input [2:0]                            afu_tlx_cmd_rd_cnt

   , output                                 tlx_afu_cmd_data_valid
   , output                                 tlx_afu_cmd_data_bdi
   , output [511:0]                         tlx_afu_cmd_data_bus
//
//AFU-TLX response transmit interface
   , input                                  afu_tlx_resp_valid
   , input [7:0]                            afu_tlx_resp_opcode
   , input [1:0]                            afu_tlx_resp_dl
   , input [15:0]                           afu_tlx_resp_capptag
   , input [1:0]                            afu_tlx_resp_dp
   , input [3:0]                            afu_tlx_resp_code

   , input                                  afu_tlx_rdata_valid
   , input                                  afu_tlx_rdata_bdi
   , input [511:0]                          afu_tlx_rdata_bus

   , output                                 tlx_afu_resp_credit
   , output                                 tlx_afu_resp_data_credit
   , output [3:0]                           tlx_afu_resp_initial_credit
   , output [5:0]                           tlx_afu_resp_data_initial_credit
//

   , output                                 icap_clk
   , output                                 iprog_go_or
);

//=============================================================================
//=============================================================================
//                           Wire/Reg Declarations
//=============================================================================
//=============================================================================

  
  
  // -- IBERT Ports
  wire     [7:0] rxlpmen_int;
  wire    [39:0] txpostcursor_int;
  wire    [39:0] txprecursor_int;
  wire    [39:0] txdiffctrl_int;
  wire    [23:0] rxrate_int;
  `ifdef BUFFER_ELASTIC
  wire     [7:0] drpen_int;
  wire     [7:0] drpwe_int;
  wire    [79:0] drpaddr_int;
  wire     [7:0] drpclk_int;
  wire   [127:0] drpdi_int;
  wire     [7:0] eyescanreset_int;
  wire   [127:0] drpdo_int;
  wire     [7:0] drprdy_int;
  `endif
  wire           init_done_int;
  wire     [3:0] init_retry_ctr_int;
  wire           gtwiz_reset_tx_done_vio_sync;
  wire           gtwiz_reset_rx_done_vio_sync;
  wire           gtwiz_buffbypass_tx_done_vio_sync;
  wire           gtwiz_buffbypass_rx_done_vio_sync;
  wire           gtwiz_buffbypass_tx_error_vio_sync;
  wire           gtwiz_buffbypass_rx_error_vio_sync;
  wire           hb_gtwiz_reset_all_vio_int;
  wire           hb0_gtwiz_reset_tx_pll_and_datapath_int;
  wire           hb0_gtwiz_reset_tx_datapath_int;
  wire           hb_gtwiz_reset_rx_pll_and_datapath_vio_int;
  wire           hb_gtwiz_reset_rx_datapath_vio_int;

  // -- DLX to TLX Parser Interface
  wire            dlx_tlx_flit_valid;
  wire    [511:0] dlx_tlx_flit;
  wire            dlx_tlx_flit_crc_err;
  wire            dlx_tlx_link_up;

  // -- TLX Framer to DLX Interface
  wire      [2:0] dlx_tlx_init_flit_depth;
  wire            dlx_tlx_flit_credit;
  wire            tlx_dlx_flit_valid;
  wire    [511:0] tlx_dlx_flit;
  wire      [3:0] tlx_dlx_debug_encode;
  wire     [31:0] tlx_dlx_debug_info;
  wire     [31:0] dlx_config_info;

  // -- Miscellaneous
  wire            clock_156_25;
  wire            send_first;
  wire            dlx_tlx_link_up_din;
  reg             reset_n_q;
  reg             dlx_tlx_link_up_q;
  wire [2:0]      unused;

  // -- for oc_cfg
wire   [4:0]   ro_device;
wire   [31:0]  ro_dlx0_version;
wire   [31:0]  ro_tlx0_version;
wire           wire_tlx_afu_ready;
wire   [6:0]   wire_afu_tlx_cmd_initial_credit;
wire           wire_afu_tlx_cmd_credit;
wire           wire_tlx_afu_cmd_valid;
wire   [7:0]   wire_tlx_afu_cmd_opcode;
wire   [1:0]   wire_tlx_afu_cmd_dl;
wire           wire_tlx_afu_cmd_end;
wire   [63:0]  wire_tlx_afu_cmd_pa;
wire   [3:0]   wire_tlx_afu_cmd_flag;
wire           wire_tlx_afu_cmd_os;
wire   [15:0]  wire_tlx_afu_cmd_capptag;
wire   [2:0]   wire_tlx_afu_cmd_pl;
wire   [63:0]  wire_tlx_afu_cmd_be;
wire   [6:0]   wire_afu_tlx_resp_initial_credit;
wire           wire_afu_tlx_resp_credit;
wire           wire_tlx_afu_resp_valid;
wire   [7:0]   wire_tlx_afu_resp_opcode;
wire   [15:0]  wire_tlx_afu_resp_afutag;
wire   [3:0]   wire_tlx_afu_resp_code;
wire   [5:0]   wire_tlx_afu_resp_pg_size;
wire   [1:0]   wire_tlx_afu_resp_dl;
wire   [1:0]   wire_tlx_afu_resp_dp;
wire   [23:0]  wire_tlx_afu_resp_host_tag;
wire   [3:0]   wire_tlx_afu_resp_cache_state;
wire   [17:0]  wire_tlx_afu_resp_addr_tag;
wire           wire_afu_tlx_cmd_rd_req;
wire   [2:0]   wire_afu_tlx_cmd_rd_cnt;
wire           wire_tlx_afu_cmd_data_valid;
wire           wire_tlx_afu_cmd_data_bdi;
wire   [511:0] wire_tlx_afu_cmd_data_bus;
wire           wire_afu_tlx_resp_rd_req;
wire   [2:0]   wire_afu_tlx_resp_rd_cnt;
wire           wire_tlx_afu_resp_data_valid;
wire           wire_tlx_afu_resp_data_bdi;
wire   [511:0] wire_tlx_afu_resp_data_bus;
wire           cfg0_tlx_xmit_tmpl_config_0;
wire           cfg0_tlx_xmit_tmpl_config_1;
wire           cfg0_tlx_xmit_tmpl_config_2;
wire           cfg0_tlx_xmit_tmpl_config_3;
wire   [3:0]   cfg0_tlx_xmit_rate_config_0;
wire   [3:0]   cfg0_tlx_xmit_rate_config_1;
wire   [3:0]   cfg0_tlx_xmit_rate_config_2;
wire   [3:0]   cfg0_tlx_xmit_rate_config_3;
wire           tlx_cfg0_in_rcv_tmpl_capability_0;
wire           tlx_cfg0_in_rcv_tmpl_capability_1;
wire           tlx_cfg0_in_rcv_tmpl_capability_2;
wire           tlx_cfg0_in_rcv_tmpl_capability_3;
wire   [3:0]   tlx_cfg0_in_rcv_rate_capability_0;
wire   [3:0]   tlx_cfg0_in_rcv_rate_capability_1;
wire   [3:0]   tlx_cfg0_in_rcv_rate_capability_2;
wire   [3:0]   tlx_cfg0_in_rcv_rate_capability_3;
wire   [3:0]   wire_tlx_afu_cmd_initial_credit;
wire   [3:0]   wire_tlx_afu_resp_initial_credit;
wire   [5:0]   wire_tlx_afu_cmd_data_initial_credit;
wire   [5:0]   wire_tlx_afu_resp_data_initial_credit;
wire           wire_tlx_afu_cmd_credit;
wire           wire_afu_tlx_cmd_valid;
wire   [7:0]   wire_afu_tlx_cmd_opcode;
wire   [11:0]  wire_afu_tlx_cmd_actag;
wire   [3:0]   wire_afu_tlx_cmd_stream_id;
wire   [67:0]  wire_afu_tlx_cmd_ea_or_obj;
wire   [15:0]  wire_afu_tlx_cmd_afutag;
wire   [1:0]   wire_afu_tlx_cmd_dl;
wire   [2:0]   wire_afu_tlx_cmd_pl;
wire           wire_afu_tlx_cmd_os;
wire   [63:0]  wire_afu_tlx_cmd_be;
wire   [3:0]   wire_afu_tlx_cmd_flag;
wire           wire_afu_tlx_cmd_endian;
wire   [15:0]  wire_afu_tlx_cmd_bdf;
wire   [19:0]  wire_afu_tlx_cmd_pasid;
wire   [5:0]   wire_afu_tlx_cmd_pg_size;
wire           wire_tlx_afu_cmd_data_credit;
wire           wire_afu_tlx_cdata_valid;
wire   [511:0] wire_afu_tlx_cdata_bus;
wire           wire_afu_tlx_cdata_bdi;
wire           wire_tlx_afu_resp_credit;
wire           wire_afu_tlx_resp_valid;
wire   [7:0]   wire_afu_tlx_resp_opcode;
wire   [1:0]   wire_afu_tlx_resp_dl;
wire   [15:0]  wire_afu_tlx_resp_capptag;
wire   [1:0]   wire_afu_tlx_resp_dp;
wire   [3:0]   wire_afu_tlx_resp_code;
wire           wire_tlx_afu_resp_data_credit;
wire           wire_afu_tlx_rdata_valid;
wire   [511:0] wire_afu_tlx_rdata_bus;
wire           wire_afu_tlx_rdata_bdi;
wire           tlx_cfg0_valid;
wire   [7:0]   tlx_cfg0_opcode;
wire   [63:0]  tlx_cfg0_pa;
wire           tlx_cfg0_t;
wire   [2:0]   tlx_cfg0_pl;
wire   [15:0]  tlx_cfg0_capptag;
wire   [31:0]  tlx_cfg0_data_bus;
wire           tlx_cfg0_data_bdi;
wire   [3:0]   cfg0_tlx_initial_credit;
wire           cfg0_tlx_credit_return;
wire           cfg0_tlx_resp_valid;
wire   [7:0]   cfg0_tlx_resp_opcode;
wire   [15:0]  cfg0_tlx_resp_capptag;
wire   [3:0]   cfg0_tlx_resp_code;
wire   [3:0]   cfg0_tlx_rdata_offset;
wire   [31:0]  cfg0_tlx_rdata_bus;
wire           cfg0_tlx_rdata_bdi;
wire           tlx_cfg0_resp_ack;
wire           cfg_f1_octrl00_resync_credits;



wire           cfg_icap_reload_en;

//For func_cfg_only
wire   [2:0] cfg_function;
wire   [1:0] cfg_portnum;
wire  [11:0] cfg_addr;
wire  [31:0] cfg_wdata;

wire  [31:0] cfg_f1_rdata;
wire         cfg_f1_rdata_vld;
wire         cfg_wr_1B;
wire         cfg_wr_2B;
wire         cfg_wr_4B;
wire         cfg_rd;

wire         cfg_f1_bad_op_or_align;
wire         cfg_f1_addr_not_implemented;

wire [127:0] cfg_errvec;
wire         cfg_errvec_valid;


wire        cfg_f1_octrl00_fence_afu;
wire        cfg0_cff_fifo_overflow;
wire        cfg0_rff_fifo_overflow;

//Cfg tieoffs
wire [31:0] f1_ro_csh_expansion_rom_bar       ;
wire [15:0] f1_ro_csh_subsystem_id            ;
wire [15:0] f1_ro_csh_subsystem_vendor_id     ;
wire [63:0] f1_ro_csh_mmio_bar0_size          ;
wire [63:0] f1_ro_csh_mmio_bar1_size          ;
wire [63:0] f1_ro_csh_mmio_bar2_size          ;
wire        f1_ro_csh_mmio_bar0_prefetchable  ;
wire        f1_ro_csh_mmio_bar1_prefetchable  ;
wire        f1_ro_csh_mmio_bar2_prefetchable  ;
wire  [4:0] f1_ro_pasid_max_pasid_width       ;
wire  [7:0] f1_ro_ofunc_reset_duration        ;
wire        f1_ro_ofunc_afu_present           ;
wire  [4:0] f1_ro_ofunc_max_afu_index         ;
wire  [7:0] f1_ro_octrl00_reset_duration      ;
wire  [5:0] f1_ro_octrl00_afu_control_index   ;
wire  [4:0] f1_ro_octrl00_pasid_len_supported ;
wire        f1_ro_octrl00_metadata_supported  ;
wire [11:0] f1_ro_octrl00_actag_len_supported ;


//reg             iprog_go; //MRF
wire            spoof_reset; //MRF
reg  [7:0]      ocde_q;
wire [7:0]      ocde_din;
wire            reset_all_out;
wire            reset_all_out_din;
reg             reset_all_out_q;
wire            start_reload;
reg  [9:0]      reload_counter;
reg             initial_set;
reg             timed_start_reload;
reg             dlx_tlx_link_up_last;
reg             link_gate;


//=============================================================================
//=============================================================================
//                           Sub Module Instances
//=============================================================================
//=============================================================================

//=============================================================================
//                      phy_vio instance
DLx_phy_vio_0 DLx_phy_vio_0_inst (
   .clk        (clock_156_25)                               // -- [0:0] < input
  ,.probe_in0  (ocde)                                       // -- [0:0] < input
  ,.probe_in1  (iprog_go_or)                                // -- [0:0] < input
  ,.probe_in2  (cfg_icap_reload_en)                         // -- [0:0] < input
  ,.probe_in3  (init_retry_ctr_int)                         // -- [3:0] < input
  ,.probe_in4  (link_gate)                                  // -- [7:0] < input
  ,.probe_in5  (8'b0)                                       // -- [7:0] < input
  ,.probe_in6  (8'b0)                                       // -- [7:0] < input
  ,.probe_in7  (gtwiz_reset_tx_done_vio_sync)               // -- [0:0] < input
  ,.probe_in8  (gtwiz_reset_rx_done_vio_sync)               // -- [0:0] < input
  ,.probe_in9  (gtwiz_buffbypass_tx_done_vio_sync)          // -- [0:0] < input
  ,.probe_in10 (gtwiz_buffbypass_rx_done_vio_sync)          // -- [0:0] < input
  ,.probe_in11 (gtwiz_buffbypass_tx_error_vio_sync)         // -- [0:0] < input
  ,.probe_in12 (gtwiz_buffbypass_rx_error_vio_sync)         // -- [0:0] < input
  ,.probe_out0 (hb_gtwiz_reset_all_vio_int)                 // -- [0:0] > output
  ,.probe_out1 (unused[0])                                  // -- [0:0] > output
  ,.probe_out2 (hb0_gtwiz_reset_tx_pll_and_datapath_int)    // -- [0:0] > output
  ,.probe_out3 (hb0_gtwiz_reset_tx_datapath_int)            // -- [0:0] > output
  ,.probe_out4 (hb_gtwiz_reset_rx_pll_and_datapath_vio_int) // -- [0:0] > output
  ,.probe_out5 (hb_gtwiz_reset_rx_datapath_vio_int)         // -- [0:0] > output
  ,.probe_out6 (spoof_reset)                                // -- [0:0] > output
);

//=============================================================================
// -- DLX & PHY instance

  dlx_phy_wrap dlx_phy
    (
      // -- Differential reference clock inputs
       .mgtrefclk1_x0y0_p                           ( mgtrefclk1_x0y0_p )             // -- input
      ,.mgtrefclk1_x0y0_n                           ( mgtrefclk1_x0y0_n )             // -- input
      ,.mgtrefclk1_x0y1_p                           ( mgtrefclk1_x0y1_p )             // -- input
      ,.mgtrefclk1_x0y1_n                           ( mgtrefclk1_x0y1_n )             // -- input
      ,.freerun_clk_p                               ( freerun_clk_p )                 // -- input
      ,.freerun_clk_n                               ( freerun_clk_n )                 // -- input

      ,.ch0_gtyrxn_in                               ( ch0_gtyrxn_in )                 // -- input
      ,.ch0_gtyrxp_in                               ( ch0_gtyrxp_in )                 // -- input
      ,.ch0_gtytxn_out                              ( ch0_gtytxn_out )                // -- output
      ,.ch0_gtytxp_out                              ( ch0_gtytxp_out )                // -- output
      ,.ch1_gtyrxn_in                               ( ch1_gtyrxn_in )                 // -- input
      ,.ch1_gtyrxp_in                               ( ch1_gtyrxp_in )                 // -- input
      ,.ch1_gtytxn_out                              ( ch1_gtytxn_out )                // -- output
      ,.ch1_gtytxp_out                              ( ch1_gtytxp_out )                // -- output
      ,.ch2_gtyrxn_in                               ( ch2_gtyrxn_in )                 // -- input
      ,.ch2_gtyrxp_in                               ( ch2_gtyrxp_in )                 // -- input
      ,.ch2_gtytxn_out                              ( ch2_gtytxn_out )                // -- output
      ,.ch2_gtytxp_out                              ( ch2_gtytxp_out )                // -- output
      ,.ch3_gtyrxn_in                               ( ch3_gtyrxn_in )                 // -- input
      ,.ch3_gtyrxp_in                               ( ch3_gtyrxp_in )                 // -- input
      ,.ch3_gtytxn_out                              ( ch3_gtytxn_out )                // -- output
      ,.ch3_gtytxp_out                              ( ch3_gtytxp_out )                // -- output
      ,.ch4_gtyrxn_in                               ( ch4_gtyrxn_in )                 // -- input
      ,.ch4_gtyrxp_in                               ( ch4_gtyrxp_in )                 // -- input
      ,.ch4_gtytxn_out                              ( ch4_gtytxn_out )                // -- output
      ,.ch4_gtytxp_out                              ( ch4_gtytxp_out )                // -- output
      ,.ch5_gtyrxn_in                               ( ch5_gtyrxn_in )                 // -- input
      ,.ch5_gtyrxp_in                               ( ch5_gtyrxp_in )                 // -- input
      ,.ch5_gtytxn_out                              ( ch5_gtytxn_out )                // -- output
      ,.ch5_gtytxp_out                              ( ch5_gtytxp_out )                // -- output
      ,.ch6_gtyrxn_in                               ( ch6_gtyrxn_in )                 // -- input
      ,.ch6_gtyrxp_in                               ( ch6_gtyrxp_in )                 // -- input
      ,.ch6_gtytxn_out                              ( ch6_gtytxn_out )                // -- output
      ,.ch6_gtytxp_out                              ( ch6_gtytxp_out )                // -- output
      ,.ch7_gtyrxn_in                               ( ch7_gtyrxn_in )                 // -- input
      ,.ch7_gtyrxp_in                               ( ch7_gtyrxp_in )                 // -- input
      ,.ch7_gtytxn_out                              ( ch7_gtytxn_out )                // -- output
      ,.ch7_gtytxp_out                              ( ch7_gtytxp_out )                // -- output

      ,.dlx_config_info                             ( dlx_config_info[31:0] )         // -- output
      ,.ro_dlx_version                              ( ro_dlx0_version[31:0] )          // -- output [31:0]
      ,.dlx_tlx_init_flit_depth                     ( dlx_tlx_init_flit_depth[2:0] )  // -- output
      ,.dlx_tlx_flit                                ( dlx_tlx_flit[511:0] )           // -- output
      ,.dlx_tlx_flit_crc_err                        ( dlx_tlx_flit_crc_err )          // -- output
      ,.dlx_tlx_flit_credit                         ( dlx_tlx_flit_credit )           // -- output
      ,.dlx_tlx_flit_valid                          ( dlx_tlx_flit_valid )            // -- output
      ,.dlx_tlx_link_up                             ( dlx_tlx_link_up )               // -- output

      ,.tlx_dlx_debug_encode                        ( tlx_dlx_debug_encode[3:0] )     // -- input
      ,.tlx_dlx_debug_info                          ( tlx_dlx_debug_info[31:0] )      // -- input
      ,.tlx_dlx_flit                                ( tlx_dlx_flit[511:0] )           // -- input
      ,.tlx_dlx_flit_valid                          ( tlx_dlx_flit_valid )            // -- input

      ,.send_first                                  ( send_first )                    // -- input
      ,.ocde                                        ( ocde )                          // -- input
      ,.tx_clk_402MHz                               ( clock_tlx )                     // -- output
      ,.tx_clk_201MHz                               ( clock_afu )                     // -- output
      ,.hb_gtwiz_reset_clk_freerun_buf_int          ( clock_156_25 )                  // -- output

      ,.init_done_int                               ( init_done_int )                               // -- output
      ,.init_retry_ctr_int                          ( init_retry_ctr_int[3:0] )                     // -- output
      ,.gtwiz_reset_tx_done_vio_sync                ( gtwiz_reset_tx_done_vio_sync )                // -- output
      ,.gtwiz_reset_rx_done_vio_sync                ( gtwiz_reset_rx_done_vio_sync )                // -- output
      ,.gtwiz_buffbypass_tx_done_vio_sync           ( gtwiz_buffbypass_tx_done_vio_sync )           // -- output
      ,.gtwiz_buffbypass_rx_done_vio_sync           ( gtwiz_buffbypass_rx_done_vio_sync )           // -- output
      ,.gtwiz_buffbypass_tx_error_vio_sync          ( gtwiz_buffbypass_tx_error_vio_sync )          // -- output
      ,.gtwiz_buffbypass_rx_error_vio_sync          ( gtwiz_buffbypass_rx_error_vio_sync )          // -- output
      ,.hb_gtwiz_reset_all_vio_int                  ( hb_gtwiz_reset_all_vio_int )                  // -- input
      ,.hb0_gtwiz_reset_tx_pll_and_datapath_int     ( hb0_gtwiz_reset_tx_pll_and_datapath_int )     // -- input
      ,.hb0_gtwiz_reset_tx_datapath_int             ( hb0_gtwiz_reset_tx_datapath_int )             // -- input
      ,.hb_gtwiz_reset_rx_pll_and_datapath_vio_int  ( hb_gtwiz_reset_rx_pll_and_datapath_vio_int )  // -- input
      ,.hb_gtwiz_reset_rx_datapath_vio_int          ( hb_gtwiz_reset_rx_datapath_vio_int )          // -- input

       // -- IBERT Logic
      ,.rxlpmen_in                                  ( rxlpmen_int[7:0] )                            // -- input
      ,.rxrate_in                                   ( rxrate_int[23:0] )                            // -- input
      ,.txdiffctrl_in                               ( txdiffctrl_int[39:0] )                        // -- input
      ,.txpostcursor_in                             ( txpostcursor_int[39:0] )                      // -- input
      ,.txprecursor_in                              ( txprecursor_int[39:0] )                        // -- input

      `ifdef BUFFER_ELASTIC
      ,.drpaddr_in                                  ( drpaddr_int[79:0] )                           // -- input
      ,.drpclk_in                                   ( drpclk_int[7:0] )                             // -- input
      ,.drpdi_in                                    ( drpdi_int[127:0] )                            // -- input
      ,.drpen_in                                    ( drpen_int[7:0] )                              // -- input
      ,.drpwe_in                                    ( drpwe_int[7:0] )                              // -- input
      ,.eyescanreset_in                             ( eyescanreset_int[7:0] )                       // -- input
      ,.drpdo_out                                   ( drpdo_int[127:0] )                            // -- output
      ,.drprdy_out                                  ( drprdy_int[7:0] )                              // -- output
      `endif
    );

//=============================================================================
//                  TLX instance
  ocx_tlx_top  tlx
    (
      // -- Clocks, Reset, Ready
      .clock                            (clock_tlx                       ) // -- input
     ,.reset_n                          (reset_n_q                     ) // -- input
     ,.tlx_afu_ready                    (wire_tlx_afu_ready                   ) // output
     ,.afu_tlx_cmd_initial_credit       (wire_afu_tlx_cmd_initial_credit      ) // input  [6:0]
     ,.afu_tlx_cmd_credit               (wire_afu_tlx_cmd_credit              ) // input
     ,.tlx_afu_cmd_valid                (wire_tlx_afu_cmd_valid               ) // output
     ,.tlx_afu_cmd_opcode               (wire_tlx_afu_cmd_opcode              ) // output [7:0]
     ,.tlx_afu_cmd_dl                   (wire_tlx_afu_cmd_dl                  ) // output [1:0]
     ,.tlx_afu_cmd_end                  (wire_tlx_afu_cmd_end                 ) // output
     ,.tlx_afu_cmd_pa                   (wire_tlx_afu_cmd_pa                  ) // output [63:0]
     ,.tlx_afu_cmd_flag                 (wire_tlx_afu_cmd_flag                ) // output [3:0]
     ,.tlx_afu_cmd_os                   (wire_tlx_afu_cmd_os                  ) // output
     ,.tlx_afu_cmd_capptag              (wire_tlx_afu_cmd_capptag             ) // output [15:0]
     ,.tlx_afu_cmd_pl                   (wire_tlx_afu_cmd_pl                  ) // output [2:0]
     ,.tlx_afu_cmd_be                   (wire_tlx_afu_cmd_be                  ) // output [63:0]

     ,.cfg_tlx_initial_credit           (cfg_tlx_initial_credit          ) // input  [3:0]
     ,.cfg_tlx_credit_return            (cfg_tlx_credit_return           ) // input
     ,.tlx_cfg_valid                    (tlx_cfg_valid                   ) // output
     ,.tlx_cfg_opcode                   (tlx_cfg_opcode                  ) // output [7:0]
     ,.tlx_cfg_pa                       (tlx_cfg_pa                      ) // output [63:0]
     ,.tlx_cfg_t                        (tlx_cfg_t                       ) // output
     ,.tlx_cfg_pl                       (tlx_cfg_pl                      ) // output [2:0]
     ,.tlx_cfg_capptag                  (tlx_cfg_capptag                 ) // output [15:0]
     ,.tlx_cfg_data_bus                 (tlx_cfg_data_bus                ) // output [31:0]
     ,.tlx_cfg_data_bdi                 (tlx_cfg_data_bdi                ) // output

     ,.afu_tlx_resp_initial_credit      (wire_afu_tlx_resp_initial_credit     ) // input  [6:0]
     ,.afu_tlx_resp_credit              (wire_afu_tlx_resp_credit             ) // input
     ,.tlx_afu_resp_valid               (wire_tlx_afu_resp_valid              ) // output
     ,.tlx_afu_resp_opcode              (wire_tlx_afu_resp_opcode             ) // output [7:0]
     ,.tlx_afu_resp_afutag              (wire_tlx_afu_resp_afutag             ) // output [15:0]
     ,.tlx_afu_resp_code                (wire_tlx_afu_resp_code               ) // output [3:0]
     ,.tlx_afu_resp_pg_size             (wire_tlx_afu_resp_pg_size            ) // output [5:0]
     ,.tlx_afu_resp_dl                  (wire_tlx_afu_resp_dl                 ) // output [1:0]
     ,.tlx_afu_resp_dp                  (wire_tlx_afu_resp_dp                 ) // output [1:0]
     ,.tlx_afu_resp_host_tag            (wire_tlx_afu_resp_host_tag           ) // output [23:0]
     ,.tlx_afu_resp_cache_state         (wire_tlx_afu_resp_cache_state        ) // output [3:0]
     ,.tlx_afu_resp_addr_tag            (wire_tlx_afu_resp_addr_tag           ) // output [17:0]
     ,.afu_tlx_cmd_rd_req               (wire_afu_tlx_cmd_rd_req              ) // input
     ,.afu_tlx_cmd_rd_cnt               (wire_afu_tlx_cmd_rd_cnt              ) // input  [2:0]
     ,.tlx_afu_cmd_data_valid           (wire_tlx_afu_cmd_data_valid          ) // output
     ,.tlx_afu_cmd_data_bus             (wire_tlx_afu_cmd_data_bus            ) // output [511:0]
     ,.tlx_afu_cmd_data_bdi             (wire_tlx_afu_cmd_data_bdi            ) // output
     ,.afu_tlx_resp_rd_req              (wire_afu_tlx_resp_rd_req             ) // input
     ,.afu_tlx_resp_rd_cnt              (wire_afu_tlx_resp_rd_cnt             ) // input  [2:0]
     ,.tlx_afu_resp_data_valid          (wire_tlx_afu_resp_data_valid         ) // output
     ,.tlx_afu_resp_data_bus            (wire_tlx_afu_resp_data_bus           ) // output [511:0]
     ,.tlx_afu_resp_data_bdi            (wire_tlx_afu_resp_data_bdi           ) // output
     ,.tlx_afu_cmd_initial_credit       (wire_tlx_afu_cmd_initial_credit      ) // output [3:0]
     ,.tlx_afu_cmd_credit               (wire_tlx_afu_cmd_credit              ) // output
     ,.afu_tlx_cmd_valid                (wire_afu_tlx_cmd_valid               ) // input
     ,.afu_tlx_cmd_opcode               (wire_afu_tlx_cmd_opcode              ) // input  [7:0]
     ,.afu_tlx_cmd_actag                (wire_afu_tlx_cmd_actag               ) // input  [11:0]
     ,.afu_tlx_cmd_stream_id            (wire_afu_tlx_cmd_stream_id           ) // input  [3:0]
     ,.afu_tlx_cmd_ea_or_obj            (wire_afu_tlx_cmd_ea_or_obj           ) // input  [67:0]
     ,.afu_tlx_cmd_afutag               (wire_afu_tlx_cmd_afutag              ) // input  [15:0]
     ,.afu_tlx_cmd_dl                   (wire_afu_tlx_cmd_dl                  ) // input  [1:0]
     ,.afu_tlx_cmd_pl                   (wire_afu_tlx_cmd_pl                  ) // input  [2:0]
     ,.afu_tlx_cmd_os                   (wire_afu_tlx_cmd_os                  ) // input
     ,.afu_tlx_cmd_be                   (wire_afu_tlx_cmd_be                  ) // input  [63:0]
     ,.afu_tlx_cmd_flag                 (wire_afu_tlx_cmd_flag                ) // input  [3:0]
     ,.afu_tlx_cmd_endian               (wire_afu_tlx_cmd_endian              ) // input
     ,.afu_tlx_cmd_bdf                  (wire_afu_tlx_cmd_bdf                 ) // input  [15:0]
     ,.afu_tlx_cmd_pasid                (wire_afu_tlx_cmd_pasid               ) // input  [19:0]
     ,.afu_tlx_cmd_pg_size              (wire_afu_tlx_cmd_pg_size             ) // input  [5:0]
     ,.tlx_afu_cmd_data_initial_credit  (wire_tlx_afu_cmd_data_initial_credit ) // output [5:0]
     ,.tlx_afu_cmd_data_credit          (wire_tlx_afu_cmd_data_credit         ) // output
     ,.afu_tlx_cdata_valid              (wire_afu_tlx_cdata_valid             ) // input
     ,.afu_tlx_cdata_bus                (wire_afu_tlx_cdata_bus               ) // input  [511:0]
     ,.afu_tlx_cdata_bdi                (wire_afu_tlx_cdata_bdi               ) // input
     ,.tlx_afu_resp_initial_credit      (wire_tlx_afu_resp_initial_credit     ) // output [3:0]
     ,.tlx_afu_resp_credit              (wire_tlx_afu_resp_credit             ) // output
     ,.afu_tlx_resp_valid               (wire_afu_tlx_resp_valid              ) // input
     ,.afu_tlx_resp_opcode              (wire_afu_tlx_resp_opcode             ) // input  [7:0]
     ,.afu_tlx_resp_dl                  (wire_afu_tlx_resp_dl                 ) // input  [1:0]
     ,.afu_tlx_resp_capptag             (wire_afu_tlx_resp_capptag            ) // input  [15:0]
     ,.afu_tlx_resp_dp                  (wire_afu_tlx_resp_dp                 ) // input  [1:0]
     ,.afu_tlx_resp_code                (wire_afu_tlx_resp_code               ) // input  [3:0]
     ,.tlx_afu_resp_data_initial_credit (wire_tlx_afu_resp_data_initial_credit) // output [5:0]
     ,.tlx_afu_resp_data_credit         (wire_tlx_afu_resp_data_credit        ) // output
     ,.afu_tlx_rdata_valid              (wire_afu_tlx_rdata_valid             ) // input
     ,.afu_tlx_rdata_bus                (wire_afu_tlx_rdata_bus               ) // input  [511:0]
     ,.afu_tlx_rdata_bdi                (wire_afu_tlx_rdata_bdi               ) // input

     ,.cfg_tlx_resp_valid               (cfg_tlx_resp_valid              ) // input
     ,.cfg_tlx_resp_opcode              (cfg_tlx_resp_opcode             ) // input  [7:0]
     ,.cfg_tlx_resp_capptag             (cfg_tlx_resp_capptag            ) // input  [15:0]
     ,.cfg_tlx_resp_code                (cfg_tlx_resp_code               ) // input  [3:0]
     ,.tlx_cfg_resp_ack                 (tlx_cfg_resp_ack                ) // output
     ,.cfg_tlx_rdata_offset             (cfg_tlx_rdata_offset            ) // input  [3:0]
     ,.cfg_tlx_rdata_bus                (cfg_tlx_rdata_bus               ) // input  [31:0]
     ,.cfg_tlx_rdata_bdi                (cfg_tlx_rdata_bdi               ) // input

     ,.dlx_tlx_flit_valid               (dlx_tlx_flit_valid              ) // input
     ,.dlx_tlx_flit                     (dlx_tlx_flit                    ) // input  [511:0]
     ,.dlx_tlx_flit_crc_err             (dlx_tlx_flit_crc_err            ) // input
     ,.dlx_tlx_link_up                  (dlx_tlx_link_up_q               ) // input
     ,.dlx_tlx_flit_credit              (dlx_tlx_flit_credit             ) // input
     ,.dlx_tlx_init_flit_depth          (dlx_tlx_init_flit_depth         ) // input  [2:0]
     ,.tlx_dlx_flit_valid               (tlx_dlx_flit_valid              ) // output
     ,.tlx_dlx_flit                     (tlx_dlx_flit                    ) // output [511:0]
     ,.tlx_dlx_debug_encode             (tlx_dlx_debug_encode            ) // output [3:0]
     ,.tlx_dlx_debug_info               (tlx_dlx_debug_info              ) // output [31:0]
     ,.dlx_tlx_dlx_config_info          (dlx_config_info                 ) // input  [31:0]

     ,.cfg_tlx_xmit_tmpl_config_0       (cfg_tlx_xmit_tmpl_config_0      ) // input
     ,.cfg_tlx_xmit_tmpl_config_1       (cfg_tlx_xmit_tmpl_config_1      ) // input
     ,.cfg_tlx_xmit_tmpl_config_2       (cfg_tlx_xmit_tmpl_config_2      ) // input
     ,.cfg_tlx_xmit_tmpl_config_3       (cfg_tlx_xmit_tmpl_config_3      ) // input
     ,.cfg_tlx_xmit_rate_config_0       (cfg_tlx_xmit_rate_config_0      ) // input  [3:0]
     ,.cfg_tlx_xmit_rate_config_1       (cfg_tlx_xmit_rate_config_1      ) // input  [3:0]
     ,.cfg_tlx_xmit_rate_config_2       (cfg_tlx_xmit_rate_config_2      ) // input  [3:0]
     ,.cfg_tlx_xmit_rate_config_3       (cfg_tlx_xmit_rate_config_3      ) // input  [3:0]
     ,.tlx_cfg_in_rcv_tmpl_capability_0 (tlx_cfg_in_rcv_tmpl_capability_0) // output
     ,.tlx_cfg_in_rcv_tmpl_capability_1 (tlx_cfg_in_rcv_tmpl_capability_1) // output
     ,.tlx_cfg_in_rcv_tmpl_capability_2 (tlx_cfg_in_rcv_tmpl_capability_2) // output
     ,.tlx_cfg_in_rcv_tmpl_capability_3 (tlx_cfg_in_rcv_tmpl_capability_3) // output
     ,.tlx_cfg_in_rcv_rate_capability_0 (tlx_cfg_in_rcv_rate_capability_0) // output [3:0]
     ,.tlx_cfg_in_rcv_rate_capability_1 (tlx_cfg_in_rcv_rate_capability_1) // output [3:0]
     ,.tlx_cfg_in_rcv_rate_capability_2 (tlx_cfg_in_rcv_rate_capability_2) // output [3:0]
     ,.tlx_cfg_in_rcv_rate_capability_3 (tlx_cfg_in_rcv_rate_capability_3) // output [3:0]
     ,.tlx_cfg_oc3_tlx_version          (ro_tlx0_version                  ) // output [31:0]
);

//=============================================================================
//                            oc_cfg instance
oc_cfg cfg (
  .clock                             (clock_tlx                        ) //   input
 ,.reset_n                           (reset_n_q                        ) //   input
 ,.ro_device                         (ro_device                        ) //   input  [4:0]
 ,.ro_dlx0_version                   (ro_dlx0_version                  ) //   input  [31:0]
 ,.ro_tlx0_version                   (ro_tlx0_version                  ) //   input  [31:0]
 //--------------- Talk to TLX ------------------
 ,.tlx_afu_ready                     (wire_tlx_afu_ready                    ) //   input
 ,.afu_tlx_cmd_initial_credit        (wire_afu_tlx_cmd_initial_credit       ) //   output [6:0]
 ,.afu_tlx_cmd_credit                (wire_afu_tlx_cmd_credit               ) //   output
 ,.tlx_afu_cmd_valid                 (wire_tlx_afu_cmd_valid                ) //   input
 ,.tlx_afu_cmd_opcode                (wire_tlx_afu_cmd_opcode               ) //   input  [7:0]
 ,.tlx_afu_cmd_dl                    (wire_tlx_afu_cmd_dl                   ) //   input  [1:0]
 ,.tlx_afu_cmd_end                   (wire_tlx_afu_cmd_end                  ) //   input
 ,.tlx_afu_cmd_pa                    (wire_tlx_afu_cmd_pa                   ) //   input  [63:0]
 ,.tlx_afu_cmd_flag                  (wire_tlx_afu_cmd_flag                 ) //   input  [3:0]
 ,.tlx_afu_cmd_os                    (wire_tlx_afu_cmd_os                   ) //   input
 ,.tlx_afu_cmd_capptag               (wire_tlx_afu_cmd_capptag              ) //   input  [15:0]
 ,.tlx_afu_cmd_pl                    (wire_tlx_afu_cmd_pl                   ) //   input  [2:0]
 ,.tlx_afu_cmd_be                    (wire_tlx_afu_cmd_be                   ) //   input  [63:0]
 ,.afu_tlx_resp_initial_credit       (wire_afu_tlx_resp_initial_credit      ) //   output [6:0]
 ,.afu_tlx_resp_credit               (wire_afu_tlx_resp_credit              ) //   output
 ,.tlx_afu_resp_valid                (wire_tlx_afu_resp_valid               ) //   input
 ,.tlx_afu_resp_opcode               (wire_tlx_afu_resp_opcode              ) //   input  [7:0]
 ,.tlx_afu_resp_afutag               (wire_tlx_afu_resp_afutag              ) //   input  [15:0]
 ,.tlx_afu_resp_code                 (wire_tlx_afu_resp_code                ) //   input  [3:0]
 ,.tlx_afu_resp_pg_size              (wire_tlx_afu_resp_pg_size             ) //   input  [5:0]
 ,.tlx_afu_resp_dl                   (wire_tlx_afu_resp_dl                  ) //   input  [1:0]
 ,.tlx_afu_resp_dp                   (wire_tlx_afu_resp_dp                  ) //   input  [1:0]
 ,.tlx_afu_resp_host_tag             (wire_tlx_afu_resp_host_tag            ) //   input  [23:0]
 ,.tlx_afu_resp_cache_state          (wire_tlx_afu_resp_cache_state         ) //   input  [3:0]
 ,.tlx_afu_resp_addr_tag             (wire_tlx_afu_resp_addr_tag            ) //   input  [17:0]
 ,.afu_tlx_cmd_rd_req                (wire_afu_tlx_cmd_rd_req               ) //   output
 ,.afu_tlx_cmd_rd_cnt                (wire_afu_tlx_cmd_rd_cnt               ) //   output [2:0]
 ,.tlx_afu_cmd_data_valid            (wire_tlx_afu_cmd_data_valid           ) //   input
 ,.tlx_afu_cmd_data_bdi              (wire_tlx_afu_cmd_data_bdi             ) //   input
 ,.tlx_afu_cmd_data_bus              (wire_tlx_afu_cmd_data_bus             ) //   input  [511:0]
 ,.afu_tlx_resp_rd_req               (wire_afu_tlx_resp_rd_req              ) //   output
 ,.afu_tlx_resp_rd_cnt               (wire_afu_tlx_resp_rd_cnt              ) //   output [2:0]
 ,.tlx_afu_resp_data_valid           (wire_tlx_afu_resp_data_valid          ) //   input
 ,.tlx_afu_resp_data_bdi             (wire_tlx_afu_resp_data_bdi            ) //   input
 ,.tlx_afu_resp_data_bus             (wire_tlx_afu_resp_data_bus            ) //   input  [511:0]

 ,.cfg0_tlx_xmit_tmpl_config_0       (cfg0_tlx_xmit_tmpl_config_0      ) //   output
 ,.cfg0_tlx_xmit_tmpl_config_1       (cfg0_tlx_xmit_tmpl_config_1      ) //   output
 ,.cfg0_tlx_xmit_tmpl_config_2       (cfg0_tlx_xmit_tmpl_config_2      ) //   output
 ,.cfg0_tlx_xmit_tmpl_config_3       (cfg0_tlx_xmit_tmpl_config_3      ) //   output
 ,.cfg0_tlx_xmit_rate_config_0       (cfg0_tlx_xmit_rate_config_0      ) //   output [3:0]
 ,.cfg0_tlx_xmit_rate_config_1       (cfg0_tlx_xmit_rate_config_1      ) //   output [3:0]
 ,.cfg0_tlx_xmit_rate_config_2       (cfg0_tlx_xmit_rate_config_2      ) //   output [3:0]
 ,.cfg0_tlx_xmit_rate_config_3       (cfg0_tlx_xmit_rate_config_3      ) //   output [3:0]
 ,.tlx_cfg0_in_rcv_tmpl_capability_0 (tlx_cfg0_in_rcv_tmpl_capability_0) //   input
 ,.tlx_cfg0_in_rcv_tmpl_capability_1 (tlx_cfg0_in_rcv_tmpl_capability_1) //   input
 ,.tlx_cfg0_in_rcv_tmpl_capability_2 (tlx_cfg0_in_rcv_tmpl_capability_2) //   input
 ,.tlx_cfg0_in_rcv_tmpl_capability_3 (tlx_cfg0_in_rcv_tmpl_capability_3) //   input
 ,.tlx_cfg0_in_rcv_rate_capability_0 (tlx_cfg0_in_rcv_rate_capability_0) //   input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_1 (tlx_cfg0_in_rcv_rate_capability_1) //   input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_2 (tlx_cfg0_in_rcv_rate_capability_2) //   input  [3:0]
 ,.tlx_cfg0_in_rcv_rate_capability_3 (tlx_cfg0_in_rcv_rate_capability_3) //   input  [3:0]

 ,.tlx_afu_cmd_initial_credit        (wire_tlx_afu_cmd_initial_credit       ) //   input  [3:0]
 ,.tlx_afu_resp_initial_credit       (wire_tlx_afu_resp_initial_credit      ) //   input  [3:0]
 ,.tlx_afu_cmd_data_initial_credit   (wire_tlx_afu_cmd_data_initial_credit  ) //   input  [5:0]
 ,.tlx_afu_resp_data_initial_credit  (wire_tlx_afu_resp_data_initial_credit ) //   input  [5:0]
 ,.tlx_afu_cmd_credit                (wire_tlx_afu_cmd_credit               ) //   input
 ,.afu_tlx_cmd_valid                 (wire_afu_tlx_cmd_valid                ) //   output
 ,.afu_tlx_cmd_opcode                (wire_afu_tlx_cmd_opcode               ) //   output [7:0]
 ,.afu_tlx_cmd_actag                 (wire_afu_tlx_cmd_actag                ) //   output [11:0]
 ,.afu_tlx_cmd_stream_id             (wire_afu_tlx_cmd_stream_id            ) //   output [3:0]
 ,.afu_tlx_cmd_ea_or_obj             (wire_afu_tlx_cmd_ea_or_obj            ) //   output [67:0]
 ,.afu_tlx_cmd_afutag                (wire_afu_tlx_cmd_afutag               ) //   output [15:0]
 ,.afu_tlx_cmd_dl                    (wire_afu_tlx_cmd_dl                   ) //   output [1:0]
 ,.afu_tlx_cmd_pl                    (wire_afu_tlx_cmd_pl                   ) //   output [2:0]
 ,.afu_tlx_cmd_os                    (wire_afu_tlx_cmd_os                   ) //   output
 ,.afu_tlx_cmd_be                    (wire_afu_tlx_cmd_be                   ) //   output [63:0]
 ,.afu_tlx_cmd_flag                  (wire_afu_tlx_cmd_flag                 ) //   output [3:0]
 ,.afu_tlx_cmd_endian                (wire_afu_tlx_cmd_endian               ) //   output
 ,.afu_tlx_cmd_bdf                   (wire_afu_tlx_cmd_bdf                  ) //   output [15:0]
 ,.afu_tlx_cmd_pasid                 (wire_afu_tlx_cmd_pasid                ) //   output [19:0]
 ,.afu_tlx_cmd_pg_size               (wire_afu_tlx_cmd_pg_size              ) //   output [5:0]
 ,.tlx_afu_cmd_data_credit           (wire_tlx_afu_cmd_data_credit          ) //   input
 ,.afu_tlx_cdata_valid               (wire_afu_tlx_cdata_valid              ) //   output
 ,.afu_tlx_cdata_bus                 (wire_afu_tlx_cdata_bus                ) //   output [511:0]
 ,.afu_tlx_cdata_bdi                 (wire_afu_tlx_cdata_bdi                ) //   output
 ,.tlx_afu_resp_credit               (wire_tlx_afu_resp_credit              ) //   input
 ,.afu_tlx_resp_valid                (wire_afu_tlx_resp_valid               ) //   output
 ,.afu_tlx_resp_opcode               (wire_afu_tlx_resp_opcode              ) //   output [7:0]
 ,.afu_tlx_resp_dl                   (wire_afu_tlx_resp_dl                  ) //   output [1:0]
 ,.afu_tlx_resp_capptag              (wire_afu_tlx_resp_capptag             ) //   output [15:0]
 ,.afu_tlx_resp_dp                   (wire_afu_tlx_resp_dp                  ) //   output [1:0]
 ,.afu_tlx_resp_code                 (wire_afu_tlx_resp_code                ) //   output [3:0]
 ,.tlx_afu_resp_data_credit          (wire_tlx_afu_resp_data_credit         ) //   input
 ,.afu_tlx_rdata_valid               (wire_afu_tlx_rdata_valid              ) //   output
 ,.afu_tlx_rdata_bus                 (wire_afu_tlx_rdata_bus                ) //   output [511:0]
 ,.afu_tlx_rdata_bdi                 (wire_afu_tlx_rdata_bdi                ) //   output

 // cfg0 Talk to TLX
 ,.tlx_cfg0_valid                    (tlx_cfg_valid                   ) //   input
 ,.tlx_cfg0_opcode                   (tlx_cfg_opcode                  ) //   input  [7:0]
 ,.tlx_cfg0_pa                       (tlx_cfg_pa                      ) //   input  [63:0]
 ,.tlx_cfg0_t                        (tlx_cfg_t                       ) //   input
 ,.tlx_cfg0_pl                       (tlx_cfg_pl                      ) //   input  [2:0]
 ,.tlx_cfg0_capptag                  (tlx_cfg_capptag                 ) //   input  [15:0]
 ,.tlx_cfg0_data_bus                 (tlx_cfg_data_bus                ) //   input  [31:0]
 ,.tlx_cfg0_data_bdi                 (tlx_cfg_data_bdi                ) //   input

 ,.cfg0_tlx_initial_credit           (cfg_tlx_initial_credit          ) //   output [3:0]
 ,.cfg0_tlx_credit_return            (cfg_tlx_credit_return           ) //   output
 ,.cfg0_tlx_resp_valid               (cfg_tlx_resp_valid              ) //   output
 ,.cfg0_tlx_resp_opcode              (cfg_tlx_resp_opcode             ) //   output [7:0]
 ,.cfg0_tlx_resp_capptag             (cfg_tlx_resp_capptag            ) //   output [15:0]
 ,.cfg0_tlx_resp_code                (cfg_tlx_resp_code               ) //   output [3:0]
 ,.cfg0_tlx_rdata_offset             (cfg_tlx_rdata_offset            ) //   output [3:0]
 ,.cfg0_tlx_rdata_bus                (cfg_tlx_rdata_bus               ) //   output [31:0]
 ,.cfg0_tlx_rdata_bdi                (cfg_tlx_rdata_bdi               ) //   output
 ,.tlx_cfg0_resp_ack                 (tlx_cfg_resp_ack                ) //   input
 //,.cfg_f1_octrl00_resync_credits     (cfg_f1_octrl00_resync_credits    )

 //--------------- Talk to VPD ------------------
 ,.cfg_vpd_addr                      (cfg_vpd_addr                     ) //   output [14:0]
 ,.cfg_vpd_wren                      (cfg_vpd_wren                     ) //   output
 ,.cfg_vpd_wdata                     (cfg_vpd_wdata                    ) //   output [31:0]
 ,.cfg_vpd_rden                      (cfg_vpd_rden                     ) //   output
 ,.vpd_cfg_rdata                     (vpd_cfg_rdata                    ) //   input  [31:0]
 ,.vpd_cfg_done                      (vpd_cfg_done                     ) //   input
 //,.vpd_err_unimplemented_addr        (vpd_err_unimplemented_addr       ) //   input but ignored

 //--------------- Talk to Flash ------------------
 ,.cfg_flsh_devsel                   (cfg_flsh_devsel                  ) //   output [1:0]
 ,.cfg_flsh_addr                     (cfg_flsh_addr                    ) //   output [13:0]
 ,.cfg_flsh_wren                     (cfg_flsh_wren                    ) //   output
 ,.cfg_flsh_wdata                    (cfg_flsh_wdata                   ) //   output [31:0]
 ,.cfg_flsh_rden                     (cfg_flsh_rden                    ) //   output
 ,.flsh_cfg_rdata                    (flsh_cfg_rdata                   ) //   input  [31:0]
 ,.flsh_cfg_done                     (flsh_cfg_done                    ) //   input
 ,.flsh_cfg_status                   (flsh_cfg_status                  ) //   input  [7:0]
 ,.flsh_cfg_bresp                    (flsh_cfg_bresp                   ) //   input  [1:0]
 ,.flsh_cfg_rresp                    (flsh_cfg_rresp                   ) //   input  [1:0]
 ,.cfg_flsh_expand_enable            (cfg_flsh_expand_enable           ) //   output
 ,.cfg_flsh_expand_dir               (cfg_flsh_expand_dir              ) //   output

 //--------------- Talk to oc-infrastructure ------------------
 ,.cfg0_bus_num                      (cfg_infra_bdf_bus               )
 ,.cfg0_device_num                   (cfg_infra_bdf_device            )
 ,.fen_afu_ready                     (                                )  //not used

// Modify the wire names to infer bus automatically
 ,.afu_fen_cmd_initial_credit        (afu_tlx_cmd_initial_credit      )
 ,.afu_fen_cmd_credit                (afu_tlx_cmd_credit              )

 ,.fen_afu_cmd_valid                 (tlx_afu_cmd_valid               )
 ,.fen_afu_cmd_opcode                (tlx_afu_cmd_opcode              )
 ,.fen_afu_cmd_dl                    (tlx_afu_cmd_dl                  )
 ,.fen_afu_cmd_end                   (tlx_afu_cmd_end                 )
 ,.fen_afu_cmd_pa                    (tlx_afu_cmd_pa                  )
 ,.fen_afu_cmd_flag                  (tlx_afu_cmd_flag                )
 ,.fen_afu_cmd_os                    (tlx_afu_cmd_os                  )
 ,.fen_afu_cmd_capptag               (tlx_afu_cmd_capptag             )
 ,.fen_afu_cmd_pl                    (tlx_afu_cmd_pl                  )
 ,.fen_afu_cmd_be                    (tlx_afu_cmd_be                  )

 ,.afu_fen_resp_initial_credit       (afu_tlx_resp_initial_credit     )
 ,.afu_fen_resp_credit               (afu_tlx_resp_credit             )
 ,.fen_afu_resp_valid                (tlx_afu_resp_valid              )
 ,.fen_afu_resp_opcode               (tlx_afu_resp_opcode             )
 ,.fen_afu_resp_afutag               (tlx_afu_resp_afutag             )
 ,.fen_afu_resp_code                 (tlx_afu_resp_code               )
 ,.fen_afu_resp_pg_size              (tlx_afu_resp_pg_size            )
 ,.fen_afu_resp_dl                   (tlx_afu_resp_dl                 )
 ,.fen_afu_resp_dp                   (tlx_afu_resp_dp                 )
 ,.fen_afu_resp_host_tag             (tlx_afu_resp_host_tag           )
 ,.fen_afu_resp_cache_state          (tlx_afu_resp_cache_state        )
 ,.fen_afu_resp_addr_tag             (tlx_afu_resp_addr_tag           )

 ,.afu_fen_cmd_rd_req                (afu_tlx_cmd_rd_req              )
 ,.afu_fen_cmd_rd_cnt                (afu_tlx_cmd_rd_cnt              )
 ,.fen_afu_cmd_data_valid            (tlx_afu_cmd_data_valid          )
 ,.fen_afu_cmd_data_bdi              (tlx_afu_cmd_data_bdi            )
 ,.fen_afu_cmd_data_bus              (tlx_afu_cmd_data_bus            )

 ,.afu_fen_resp_rd_req               (afu_tlx_resp_rd_req             )
 ,.afu_fen_resp_rd_cnt               (afu_tlx_resp_rd_cnt             )
 ,.fen_afu_resp_data_valid           (tlx_afu_resp_data_valid         )
 ,.fen_afu_resp_data_bdi             (tlx_afu_resp_data_bdi           )
 ,.fen_afu_resp_data_bus             (tlx_afu_resp_data_bus           )

 ,.fen_afu_cmd_initial_credit        (tlx_afu_cmd_initial_credit      )
 ,.fen_afu_resp_initial_credit       (tlx_afu_resp_initial_credit     )
 ,.fen_afu_cmd_data_initial_credit   (tlx_afu_cmd_data_initial_credit )
 ,.fen_afu_resp_data_initial_credit  (tlx_afu_resp_data_initial_credit)

 ,.fen_afu_cmd_credit                (tlx_afu_cmd_credit              )
 ,.afu_fen_cmd_valid                 (afu_tlx_cmd_valid               )
 ,.afu_fen_cmd_opcode                (afu_tlx_cmd_opcode              )
 ,.afu_fen_cmd_actag                 (afu_tlx_cmd_actag               )
 ,.afu_fen_cmd_stream_id             (afu_tlx_cmd_stream_id           )
 ,.afu_fen_cmd_ea_or_obj             (afu_tlx_cmd_ea_or_obj           )
 ,.afu_fen_cmd_afutag                (afu_tlx_cmd_afutag              )
 ,.afu_fen_cmd_dl                    (afu_tlx_cmd_dl                  )
 ,.afu_fen_cmd_pl                    (afu_tlx_cmd_pl                  )
 ,.afu_fen_cmd_os                    (afu_tlx_cmd_os                  )
 ,.afu_fen_cmd_be                    (afu_tlx_cmd_be                  )
 ,.afu_fen_cmd_flag                  (afu_tlx_cmd_flag                )
 ,.afu_fen_cmd_endian                (afu_tlx_cmd_endian              )
 ,.afu_fen_cmd_bdf                   (afu_tlx_cmd_bdf                 )
 ,.afu_fen_cmd_pasid                 (afu_tlx_cmd_pasid               )
 ,.afu_fen_cmd_pg_size               (afu_tlx_cmd_pg_size             )

 ,.fen_afu_cmd_data_credit           (tlx_afu_cmd_data_credit         )
 ,.afu_fen_cdata_valid               (afu_tlx_cdata_valid             )
 ,.afu_fen_cdata_bus                 (afu_tlx_cdata_bus               )
 ,.afu_fen_cdata_bdi                 (afu_tlx_cdata_bdi               )

 ,.fen_afu_resp_credit               (tlx_afu_resp_credit             )
 ,.afu_fen_resp_valid                (afu_tlx_resp_valid              )
 ,.afu_fen_resp_opcode               (afu_tlx_resp_opcode             )
 ,.afu_fen_resp_dl                   (afu_tlx_resp_dl                 )
 ,.afu_fen_resp_capptag              (afu_tlx_resp_capptag            )
 ,.afu_fen_resp_dp                   (afu_tlx_resp_dp                 )
 ,.afu_fen_resp_code                 (afu_tlx_resp_code               )

 ,.fen_afu_resp_data_credit          (tlx_afu_resp_data_credit        )
 ,.afu_fen_rdata_valid               (afu_tlx_rdata_valid             )
 ,.afu_fen_rdata_bus                 (afu_tlx_rdata_bus               )
 ,.afu_fen_rdata_bdi                 (afu_tlx_rdata_bdi               )


 //--------------- Talk to func_cfg_only (func1) ------------------

 ,.cfg_function                      (cfg_function               )
 ,.cfg_portnum                       (cfg_portnum                )
 ,.cfg_addr                          (cfg_addr                   )
 ,.cfg_wdata                         (cfg_wdata                  )
 ,.cfg_f1_rdata                      (cfg_f1_rdata               )
 ,.cfg_f1_rdata_vld                  (cfg_f1_rdata_vld           )
 ,.cfg_wr_1B                         (cfg_wr_1B                  )
 ,.cfg_wr_2B                         (cfg_wr_2B                  )
 ,.cfg_wr_4B                         (cfg_wr_4B                  )
 ,.cfg_rd                            (cfg_rd                     )
 ,.cfg_f1_bad_op_or_align            (cfg_f1_bad_op_or_align     )
 ,.cfg_f1_addr_not_implemented       (cfg_f1_addr_not_implemented)

 ,.cfg_f1_octrl00_fence_afu          (cfg_f1_octrl00_fence_afu   ) //input to oc-cfg to control the fence 

 ,.cfg0_cff_fifo_overflow            (cfg0_cff_fifo_overflow )
 //,.cfg1_cff_fifo_overflow            (cfg1_cff_fifo_overflow )
 ,.cfg0_rff_fifo_overflow            (cfg0_rff_fifo_overflow )
 //,.cfg1_rff_fifo_overflow            (cfg1_rff_fifo_overflow )
 ,.cfg_errvec                        (cfg_errvec             )
 ,.cfg_errvec_valid                  (cfg_errvec_valid       )

 ,.cfg_f0_otl0_long_backoff_timer    (cfg_infra_backoff_timer    )
 ,.cfg_f0_otl0_short_backoff_timer   (                           ) //Not used

 ,.f1_csh_expansion_rom_bar           (f1_ro_csh_expansion_rom_bar      )
 ,.f1_csh_subsystem_id                (f1_ro_csh_subsystem_id           )
 ,.f1_csh_subsystem_vendor_id         (f1_ro_csh_subsystem_vendor_id    )
 ,.f1_csh_mmio_bar0_size              (f1_ro_csh_mmio_bar0_size         )
 ,.f1_csh_mmio_bar1_size              (f1_ro_csh_mmio_bar1_size         )
 ,.f1_csh_mmio_bar2_size              (f1_ro_csh_mmio_bar2_size         )
 ,.f1_csh_mmio_bar0_prefetchable      (f1_ro_csh_mmio_bar0_prefetchable )
 ,.f1_csh_mmio_bar1_prefetchable      (f1_ro_csh_mmio_bar1_prefetchable )
 ,.f1_csh_mmio_bar2_prefetchable      (f1_ro_csh_mmio_bar2_prefetchable )
 ,.f1_pasid_max_pasid_width           (f1_ro_pasid_max_pasid_width      )
 ,.f1_ofunc_reset_duration            (f1_ro_ofunc_reset_duration       )
 ,.f1_ofunc_afu_present               (f1_ro_ofunc_afu_present          )
 ,.f1_ofunc_max_afu_index             (f1_ro_ofunc_max_afu_index        )
 ,.f1_octrl00_reset_duration          (f1_ro_octrl00_reset_duration     )
 ,.f1_octrl00_afu_control_index       (f1_ro_octrl00_afu_control_index  )
 ,.f1_octrl00_pasid_len_supported     (f1_ro_octrl00_pasid_len_supported)
 ,.f1_octrl00_metadata_supported      (f1_ro_octrl00_metadata_supported )
 ,.f1_octrl00_actag_len_supported     (f1_ro_octrl00_actag_len_supported)

 //--------------- Misc ------------------
 ,.cfg_icap_reload_en                 (cfg_icap_reload_en               )


);

//=============================================================================
//                       oc_function_cfg_only
// New: This just keeps the cfg_descriptor and cfg_func1.
// Only works at tlx clock
// All the data ports are moved out.

oc_function_cfg_only func_cfg_only(
    .clock_tlx                              ( clock_tlx                          )
  , .reset_in                               ( ~reset_n_q                         )  // (positive active)
  , .reset_afu_out                          ( reset_afu                          )  // out
    // -------------------------------------------------------------
    // Configuration Sequencer Interface [CFG_SEQ -> CFG_Fn (n=1-7)]
    // -------------------------------------------------------------
  , .cfg_function                           ( cfg_function                       )
  , .cfg_portnum                            ( cfg_portnum                        )
  , .cfg_addr                               ( cfg_addr                           )
  , .cfg_wdata                              ( cfg_wdata                          )
  , .cfg_f1_rdata                           ( cfg_f1_rdata                       )
  , .cfg_f1_rdata_vld                       ( cfg_f1_rdata_vld                   )
  , .cfg_wr_1B                              ( cfg_wr_1B                          )
  , .cfg_wr_2B                              ( cfg_wr_2B                          )
  , .cfg_wr_4B                              ( cfg_wr_4B                          )
  , .cfg_rd                                 ( cfg_rd                             )
  , .cfg_f1_bad_op_or_align                 ( cfg_f1_bad_op_or_align             )
  , .cfg_f1_addr_not_implemented            ( cfg_f1_addr_not_implemented        )
    // ------------------------------------
    // Other signals
    // ------------------------------------
    // Fence control
  , .cfg_f1_octrl00_fence_afu               ( cfg_f1_octrl00_fence_afu           ) //output
    // TLX Configuration for the TLX port(s) connected to AFUs under this Function
//, .cfg_f0_otl0_long_backoff_timer         ( cfg_f0_otl0_long_backoff_timer     )
//, .cfg_f0_otl0_short_backoff_timer        ( cfg_f0_otl0_short_backoff_timer    )

    // Error signals into MMIO capture register
  , .vpd_err_unimplemented_addr             ( vpd_err_unimplemented_addr         )
  , .cfg0_cff_fifo_overflow                 ( cfg0_cff_fifo_overflow             )
  , .cfg1_cff_fifo_overflow                 ( 1'b0                               )  // Residual signal left in, tie off
  , .cfg0_rff_fifo_overflow                 ( cfg0_rff_fifo_overflow             )
  , .cfg1_rff_fifo_overflow                 ( 1'b0                               )  // Residual signal left in, tie off
  , .cfg_errvec                             ( cfg_errvec                         )
  , .cfg_errvec_valid                       ( cfg_errvec_valid                   )
    // Resync credits control
  , .cfg_f1_octrl00_resync_credits          ( cfg_f1_octrl00_resync_credits      ) //Not used by anyone

  ,.f1_ro_csh_expansion_rom_bar                 (f1_ro_csh_expansion_rom_bar      )
  ,.f1_ro_csh_subsystem_id                      (f1_ro_csh_subsystem_id           )
  ,.f1_ro_csh_subsystem_vendor_id               (f1_ro_csh_subsystem_vendor_id    )
  ,.f1_ro_csh_mmio_bar0_size                    (f1_ro_csh_mmio_bar0_size         )
  ,.f1_ro_csh_mmio_bar1_size                    (f1_ro_csh_mmio_bar1_size         )
  ,.f1_ro_csh_mmio_bar2_size                    (f1_ro_csh_mmio_bar2_size         )
  ,.f1_ro_csh_mmio_bar0_prefetchable            (f1_ro_csh_mmio_bar0_prefetchable )
  ,.f1_ro_csh_mmio_bar1_prefetchable            (f1_ro_csh_mmio_bar1_prefetchable )
  ,.f1_ro_csh_mmio_bar2_prefetchable            (f1_ro_csh_mmio_bar2_prefetchable )
  ,.f1_ro_pasid_max_pasid_width                 (f1_ro_pasid_max_pasid_width      )
  ,.f1_ro_ofunc_reset_duration                  (f1_ro_ofunc_reset_duration       )
  ,.f1_ro_ofunc_afu_present                     (f1_ro_ofunc_afu_present          )
  ,.f1_ro_ofunc_max_afu_index                   (f1_ro_ofunc_max_afu_index        )
  ,.f1_ro_octrl00_reset_duration                (f1_ro_octrl00_reset_duration     )
  ,.f1_ro_octrl00_afu_control_index             (f1_ro_octrl00_afu_control_index  )
  ,.f1_ro_octrl00_pasid_len_supported           (f1_ro_octrl00_pasid_len_supported)
  ,.f1_ro_octrl00_metadata_supported            (f1_ro_octrl00_metadata_supported )
  ,.f1_ro_octrl00_actag_len_supported           (f1_ro_octrl00_actag_len_supported)

  ,.cfg_f1_csh_mmio_bar0                     (cfg_infra_f1_mmio_bar0                 )
  ,.cfg_f1_csh_mmio_bar0_mask                (cfg_infra_f1_mmio_bar0_mask            )
  ,.cfg_f1_octrl00_afu_actag_base            (cfg_infra_actag_base                   )
  ,.cfg_f1_octrl00_pasid_base                (cfg_infra_pasid_base                   )
  ,.cfg_f1_octrl00_pasid_length_enabled      (cfg_infra_pasid_length                 )
);

//=============================================================================
//                            Logic

assign rxrate_int[23:0]       = {8{3'b000}};
assign txdiffctrl_int[39:0]   = {8{5'b11111}};
assign txprecursor_int[39:0]  = {8{5'b00010}};
assign txpostcursor_int[39:0] = {8{5'b00000}};

`ifdef DFE
   assign rxlpmen_int[ 7:0]      = {8{1'b0}}; //-- DFE ON
`else
   assign rxlpmen_int[ 7:0]      = {8{1'b1}}; //-- DFE OFF
`endif

assign ro_device[4:0] = 5'b0;
assign cfg_infra_bdf_function = 3'b001; //Only support one function (oc_function 1)



assign send_first          =  1'b0;  // -- '0' = receive data before sending, '1' = send data immediately after reset
assign dlx_tlx_link_up_din = dlx_tlx_link_up;
always@(posedge clock_tlx) begin
     reset_n_q       <= dlx_tlx_link_up;
     dlx_tlx_link_up_q   <= dlx_tlx_link_up;
end

assign reset_tlx_n = reset_n_q;

vio_reset_n vio_reset_n_inst_tlx
  (
    .clk        ( clock_tlx ),       // -- input
    .probe_in0  ( dlx_tlx_link_up ), // -- input wire [0 : 0] probe_in0
    .probe_in1  ( tlx_afu_ready ),   // -- input wire [0 : 0] probe_in1
    .probe_out0 ( unused[2] )        // -- output
  );


//=============================================================================
// -- Control ICAP for image reload

assign ocde_din[7:0] = {ocde, ocde_q[7:1]};
assign reset_all_out = ((ocde_q[4:0] == 5'b11111) &  reset_all_out_q) ? 1'b0 :
                       ((ocde_q[4:0] == 5'b00000) & ~reset_all_out_q) ? 1'b1 :
                                                                        reset_all_out_q;
assign start_reload = reset_all_out_q;
assign reset_all_out_din   = reset_all_out;

always @ (posedge clock_156_25) begin
    if ((dlx_tlx_link_up == 1) && (dlx_tlx_link_up_last == 0))
        link_gate <= 1'b1;

    ocde_q          <= ocde_din;
    reset_all_out_q <= reset_all_out_din;
    dlx_tlx_link_up_last <= dlx_tlx_link_up;

end

assign iprog_go_or = (start_reload & link_gate & cfg_icap_reload_en)| spoof_reset;
// choose a clock source for icap that is a global clock.  
// ICAP IP allows this to be async to axi clock
assign icap_clk = clock_156_25;




endmodule //-- oc_host_if
