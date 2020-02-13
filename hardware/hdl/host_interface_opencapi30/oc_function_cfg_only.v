/*
 * Copyright 2020International Business Machines
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


module oc_function_cfg_only (

    // -----------------------------------
    // Miscellaneous Ports
    // -----------------------------------
    input          clock_tlx
  , input          reset_in
  , output         reset_afu_n_out

    // -------------------------------------------------------------
    // Configuration Sequencer Interface [CFG_SEQ -> CFG_Fn (n=1-7)]
    // -------------------------------------------------------------

  , input    [2:0] cfg_function
  , input    [1:0] cfg_portnum
  , input   [11:0] cfg_addr
  , input   [31:0] cfg_wdata
  , output  [31:0] cfg_f1_rdata
  , output         cfg_f1_rdata_vld
  , input          cfg_wr_1B
  , input          cfg_wr_2B
  , input          cfg_wr_4B
  , input          cfg_rd
  , output         cfg_f1_bad_op_or_align
  , output         cfg_f1_addr_not_implemented

    // ------------------------------------
    // Other signals
    // ------------------------------------

    // Fence control
  , output         cfg_f1_octrl00_fence_afu

    // TLX Configuration for the TLX port(s) connected to AFUs under this Function
//  , input    [3:0] cfg_f0_otl0_long_backoff_timer
//  , input    [3:0] cfg_f0_otl0_short_backoff_timer

    // Error signals into MMIO capture register
  , input          vpd_err_unimplemented_addr
  , input          cfg0_cff_fifo_overflow
  , input          cfg1_cff_fifo_overflow
  , input          cfg0_rff_fifo_overflow
  , input          cfg1_rff_fifo_overflow
  , input  [127:0] cfg_errvec
  , input          cfg_errvec_valid

    // Resync credits control
  , output         cfg_f1_octrl00_resync_credits


    //cfg tieoff files for cfg_func1
    ,input [31:0] f1_ro_csh_expansion_rom_bar
    ,input [15:0] f1_ro_csh_subsystem_id
    ,input [15:0] f1_ro_csh_subsystem_vendor_id
    ,input [63:0] f1_ro_csh_mmio_bar0_size
    ,input [63:0] f1_ro_csh_mmio_bar1_size
    ,input [63:0] f1_ro_csh_mmio_bar2_size
    ,input        f1_ro_csh_mmio_bar0_prefetchable
    ,input        f1_ro_csh_mmio_bar1_prefetchable
    ,input        f1_ro_csh_mmio_bar2_prefetchable
    ,input  [4:0] f1_ro_pasid_max_pasid_width
    ,input  [7:0] f1_ro_ofunc_reset_duration
    ,input        f1_ro_ofunc_afu_present
    ,input  [4:0] f1_ro_ofunc_max_afu_index
    ,input  [7:0] f1_ro_octrl00_reset_duration
    ,input  [5:0] f1_ro_octrl00_afu_control_index
    ,input  [4:0] f1_ro_octrl00_pasid_len_supported
    ,input        f1_ro_octrl00_metadata_supported
    ,input [11:0] f1_ro_octrl00_actag_len_supported

    //output to oc-infrastructure
    ,output [63:0] cfg_f1_csh_mmio_bar0
    ,output [63:0] cfg_f1_csh_mmio_bar0_mask
    ,output [11:0] cfg_f1_octrl00_afu_actag_base
    ,output [19:0] cfg_f1_octrl00_pasid_base
    ,output [4:0]  cfg_f1_octrl00_pasid_length_enabled



);

// ============================================================================
// @@@  SIG: Internal signals
// ============================================================================

// Interface to AFU Descriptor table (interface is Read Only)
  wire  [5:0] cfg_desc_afu_index
; wire [30:0] cfg_desc_offset
; wire        cfg_desc_cmd_valid
; wire [31:0] desc_cfg_data
; wire        desc_cfg_data_valid
; wire        desc_cfg_echo_cmd_valid
; wire [31:0] desc0_cfg_data
; wire        desc0_cfg_data_valid
; wire        desc0_cfg_echo_cmd_valid

// Between other modules in the file
; wire        reset_afu00
; wire        resync_credits_afu00
;



// =============================================================================
// @@@ CFG_F1: Function 1 Capability Structures (controls AFU)
// =============================================================================

// Signals from AFU
  wire         afu_f1_cfg_terminate_in_progress  // CFG_F1 input

// Declare F1 outputs
//
; wire         cfg_f1_csh_memory_space
; wire  [63:0] cfg_f1_csh_mmio_bar0
; wire  [63:0] cfg_f1_csh_mmio_bar1
; wire  [63:0] cfg_f1_csh_mmio_bar2
; wire  [31:0] cfg_f1_csh_expansion_ROM_bar
; wire         cfg_f1_csh_expansion_ROM_enable
; wire         cfg_f1_ofunc_function_reset
; wire  [11:0] cfg_f1_ofunc_func_actag_base
; wire  [11:0] cfg_f1_ofunc_func_actag_len_enab
; wire   [5:0] cfg_f1_octrl00_afu_control_index
; wire   [3:0] cfg_f1_octrl00_afu_unique
//; wire         cfg_f1_octrl00_fence_afu            Move to 'output'
; wire         cfg_f1_octrl00_enable_afu
; wire         cfg_f1_octrl00_reset_afu
; wire         cfg_f1_octrl00_terminate_valid
; wire  [19:0] cfg_f1_octrl00_terminate_pasid
; wire   [4:0] cfg_f1_octrl00_pasid_length_enabled
; wire         cfg_f1_octrl00_metadata_enabled
; wire   [2:0] cfg_f1_octrl00_host_tag_run_length
; wire  [19:0] cfg_f1_octrl00_pasid_base
; wire  [11:0] cfg_f1_octrl00_afu_actag_len_enab
; wire  [11:0] cfg_f1_octrl00_afu_actag_base
;

wire   cfg_f1_reset;
assign cfg_f1_reset = (reset_in == 1'b1 || cfg_f1_ofunc_function_reset == 1'b1) ? 1'b1 : 1'b0;   // Apply on hardware reset OR software cmd (Function Reset)

//=============================================================================
//                             cfg_func1 instance
cfg_func1 cfg_f1
    (
      // -- Clocks & Reset
      .clock                               ( clock_tlx ),                                     // -- input
      .reset                               ( cfg_f1_reset ),                              // -- input
      .device_reset                        ( reset_in ),                                     // -- input

      // -- READ ONLY field inputs
      // -- Configuration Space Header
      .cfg_ro_csh_device_id                ( 16'h062B ),                                  // -- input
      .cfg_ro_csh_vendor_id                ( 16'h1014 ),                                  // -- input
      .cfg_ro_csh_class_code               ( 24'h120000 ),                                // -- input
      .cfg_ro_csh_revision_id              (  8'h00 ),                                    // -- input
      .cfg_ro_csh_multi_function           (  1'b1 ),                                     // -- input
      .cfg_ro_csh_mmio_bar0_size           ( f1_ro_csh_mmio_bar0_size         ),          // -- input    // -- [63:n+1]=1, [n:0]=0 to indicate MMIO region size (default 64 MB)
      .cfg_ro_csh_mmio_bar1_size           ( f1_ro_csh_mmio_bar1_size         ),          // -- input    // -- [63:n+1]=1, [n:0]=0 to indicate MMIO region size (default 0 MB)
      .cfg_ro_csh_mmio_bar2_size           ( f1_ro_csh_mmio_bar2_size         ),          // -- input    // -- [63:n+1]=1, [n:0]=0 to indicate MMIO region size (default 0 MB)
      .cfg_ro_csh_mmio_bar0_prefetchable   ( f1_ro_csh_mmio_bar0_prefetchable ),          // -- input
      .cfg_ro_csh_mmio_bar1_prefetchable   ( f1_ro_csh_mmio_bar1_prefetchable ),          // -- input
      .cfg_ro_csh_mmio_bar2_prefetchable   ( f1_ro_csh_mmio_bar2_prefetchable ),          // -- input
      .cfg_ro_csh_subsystem_id             ( f1_ro_csh_subsystem_id           ),          // -- input
      .cfg_ro_csh_subsystem_vendor_id      ( f1_ro_csh_subsystem_vendor_id    ),          // -- input
      .cfg_ro_csh_expansion_rom_bar        ( f1_ro_csh_expansion_rom_bar      ),          // -- input    // -- Only [31:11] are used

      // -- PASID
      .cfg_ro_pasid_max_pasid_width        ( f1_ro_pasid_max_pasid_width ),               // -- input    // -- Default is 512 PASIDs

      // -- Function
      .cfg_ro_ofunc_reset_duration         ( f1_ro_ofunc_reset_duration ),                // -- input    // -- Number of cycles Function reset is active (00=256 cycles)
      .cfg_ro_ofunc_afu_present            ( f1_ro_ofunc_afu_present    ),                                     // -- input    // -- Func0=0, FuncN=1 (likely)
      .cfg_ro_ofunc_max_afu_index          ( f1_ro_ofunc_max_afu_index  ),                // -- input    // -- Default is AFU number 0

      // -- AFU 0 Control
      .cfg_ro_octrl00_reset_duration       ( f1_ro_octrl00_reset_duration      ),         // -- input    // -- Number of cycles AFU reset is active (00=256 cycles)
      .cfg_ro_octrl00_afu_control_index    ( f1_ro_octrl00_afu_control_index   ),         // -- input    // -- Control structure for AFU Index 0
      .cfg_ro_octrl00_pasid_len_supported  ( f1_ro_octrl00_pasid_len_supported ),         // -- input    // -- Default is 512 PASID
      .cfg_ro_octrl00_metadata_supported   ( f1_ro_octrl00_metadata_supported  ),         // -- input    // -- MetaData is not supported
      .cfg_ro_octrl00_actag_len_supported  ( f1_ro_octrl00_actag_len_supported ),         // -- input    // -- Default is 32 acTags

      // -- Assigned configuration values
      .cfg_ro_function                     ( ro_function ),                               // -- input

      // -- Functional interface
      .cfg_function                        ( cfg_function[2:0] ),                         // -- input    // -- Targeted Function
      .cfg_portnum                         ( cfg_portnum[1:0] ),                          // -- input    // -- Targeted TLX port
      .cfg_addr                            ( cfg_addr[11:0] ),                            // -- input    // -- Target address for the read or write access
      .cfg_wdata                           ( cfg_wdata[31:0] ),                           // -- input    // -- Write data into selected config reg
      .cfg_rdata                           ( cfg_f1_rdata[31:0] ),                        // -- output   // -- Read  data from selected config reg
      .cfg_rdata_vld                       ( cfg_f1_rdata_vld ),                          // -- output   // -- When observed in the proper cycle, indicates if cfg_rdata has valid information
      .cfg_wr_1B                           ( cfg_wr_1B ),                                 // -- input    // -- When 1, triggers a write operation of 1 byte  (cfg_addr[1:0] selects byte)
      .cfg_wr_2B                           ( cfg_wr_2B ),                                 // -- input    // -- When 1, triggers a write operation of 2 bytes (cfg_addr[1]   selects starting byte)
      .cfg_wr_4B                           ( cfg_wr_4B ),                                 // -- input    // -- When 1, triggers a write operation of all 4 bytes
      .cfg_rd                              ( cfg_rd ),                                    // -- input    // -- When 1, triggers a read operation that returns all 4 bytes of data from the reg
      .cfg_bad_op_or_align                 ( cfg_f1_bad_op_or_align ),                    // -- output   // -- Pulsed when multiple write/read strobes are active or writes are not naturally aligned
      .cfg_addr_not_implemented            ( cfg_f1_addr_not_implemented ),               // -- output   // -- Pulsed when address provided is not implemented within the ACS space

      // -- Inputs defined by active AFU logic
      .cfg_octrl00_terminate_in_progress   ( afu_f1_cfg_terminate_in_progress ),          // -- input    // -- When 1, a PASID is in the process of being terminated (set to 1 immediately after 'terminate valid')

      // -- Individual fields from configuration registers
      // -- CSH
      .cfg_csh_memory_space                ( cfg_f1_csh_memory_space ),                   // -- output
      .cfg_csh_mmio_bar0                   ( cfg_f1_csh_mmio_bar0[63:0] ),                // -- output
      .cfg_csh_mmio_bar1                   ( cfg_f1_csh_mmio_bar1[63:0] ),                // -- output   // -- Unused
      .cfg_csh_mmio_bar2                   ( cfg_f1_csh_mmio_bar2[63:0] ),                // -- output   // -- Unused
      .cfg_csh_expansion_ROM_bar           ( cfg_f1_csh_expansion_ROM_bar[31:0] ),        // -- output   // -- Unused
      .cfg_csh_expansion_ROM_enable        ( cfg_f1_csh_expansion_ROM_enable ),           // -- output   // -- Unused

      // -- OFUNC
      .cfg_ofunc_function_reset            ( cfg_f1_ofunc_function_reset ),               // -- output   // -- When 1, reset this Function
      .cfg_ofunc_func_actag_base           ( cfg_f1_ofunc_func_actag_base[11:0] ),        // -- output
      .cfg_ofunc_func_actag_len_enab       ( cfg_f1_ofunc_func_actag_len_enab[11:0] ),    // -- output

      // -- OCTRL
      .cfg_octrl00_afu_control_index       ( cfg_f1_octrl00_afu_control_index[5:0] ),     // -- output   // -- AFU number that other octrl signals refer to (control 1 AFU at a time)
      .cfg_octrl00_afu_unique              ( cfg_f1_octrl00_afu_unique[3:0] ),            // -- output   // -- Each AFU can assign a use to this (OCTRL, h0C, bit [31:28])
      .cfg_octrl00_fence_afu               ( cfg_f1_octrl00_fence_afu ),                  // -- output   // -- When 1, isolate the selected AFU from all other units (likely in preparation for re-configuring it)
      .cfg_octrl00_enable_afu              ( cfg_f1_octrl00_enable_afu ),                 // -- output   // -- When 1, the selected AFU can initiate commands to the host
      .cfg_octrl00_reset_afu               ( cfg_f1_octrl00_reset_afu ),                  // -- output   // -- When 1, reset the selected AFU
      .cfg_octrl00_terminate_valid         ( cfg_f1_octrl00_terminate_valid ),            // -- output   // -- When 1, terminate the specified PASID process
      .cfg_octrl00_terminate_pasid         ( cfg_f1_octrl00_terminate_pasid[19:0] ),      // -- output   // -- Which PASID 'terminate valid' applies to
      .cfg_octrl00_pasid_length_enabled    ( cfg_f1_octrl00_pasid_length_enabled[4:0] ),  // -- output
      .cfg_octrl00_metadata_enabled        ( cfg_f1_octrl00_metadata_enabled ),           // -- output
      .cfg_octrl00_host_tag_run_length     ( cfg_f1_octrl00_host_tag_run_length[2:0] ),   // -- output
      .cfg_octrl00_pasid_base              ( cfg_f1_octrl00_pasid_base[19:0] ),           // -- output
      .cfg_octrl00_afu_actag_base          ( cfg_f1_octrl00_afu_actag_base[11:0] ),       // -- output
      .cfg_octrl00_afu_actag_len_enab      ( cfg_f1_octrl00_afu_actag_len_enab[11:0] ),   // -- output

      // -- Interface to AFU Descriptor table (interface is Read Only)
      .cfg_desc_afu_index                  ( cfg_desc_afu_index[5:0] ),                   // -- output
      .cfg_desc_offset                     ( cfg_desc_offset[30:0] ),                     // -- output
      .cfg_desc_cmd_valid                  ( cfg_desc_cmd_valid ),                        // -- output
      .desc_cfg_data                       ( desc_cfg_data[31:0] ),                       // -- input
      .desc_cfg_data_valid                 ( desc_cfg_data_valid ),                       // -- input
      .desc_cfg_echo_cmd_valid             ( desc_cfg_echo_cmd_valid )                    // -- input

    );


// Combine Descriptor outputs before sending into Config Space
// When used with multiple descriptors representing multiple AFUs, connect the inputs thusly at the next level up:
//    (into afu_config_space.v) = (out of DESC0 instance)          (out of DESC1 instance)    (out of other DESC instances)
assign desc_cfg_echo_cmd_valid  = desc0_cfg_echo_cmd_valid ; // &  desc1_cfg_echo_cmd_valid & ... ;
assign desc_cfg_data_valid      = desc0_cfg_data_valid     ; // |  desc1_cfg_data_valid     | ... ;
assign desc_cfg_data            = desc0_cfg_data           ; // |  desc1_cfg_data           | ... ;

// Resync credits control
assign cfg_f1_octrl00_resync_credits = cfg_f1_octrl00_afu_unique[0];   // Assign AFU Unique[0] as resync_credits signal
assign resync_credits_afu00          = cfg_f1_octrl00_afu_unique[0];   // Make a copy for internal use, as get Warning when an output as an input




// Set AFU reset on either: card reset OR function reset OR software reset to AFU 0
assign reset_afu00 = ( reset_in == 1'b1        ||
                       cfg_f1_reset == 1'b1 ||
                      (cfg_f1_octrl00_reset_afu == 1'b1 && cfg_f1_octrl00_afu_control_index == 6'b000000) ) ? 1'b1 : 1'b0;

assign reset_afu_n_out = ~reset_afu00;


//=============================================================================
//                             oc_afu_cfg_only instance
oc_afu_cfg_only  oc_afu_cfg_only
    (
      // -- Clocks & Reset
      .clock_tlx                           ( clock_tlx),                                 // -- input
      .reset                               ( reset_afu00 ),                               // -- input
      // -- AFU Index
      .afu_index                           ( 6'b000000 ),                                 // -- input   // -- This AFU is number 0

      // -- Interface to AFU Descriptor table (interface is Read Only
      .cfg_desc_afu_index                  ( cfg_desc_afu_index[5:0] ),                   // -- input
      .cfg_desc_offset                     ( cfg_desc_offset[30:0] ),                     // -- input
      .cfg_desc_cmd_valid                  ( cfg_desc_cmd_valid ),                        // -- input
      .desc_cfg_data                       ( desc0_cfg_data[31:0] ),                      // -- output
      .desc_cfg_data_valid                 ( desc0_cfg_data_valid ),                      // -- output
      .desc_cfg_echo_cmd_valid             ( desc0_cfg_echo_cmd_valid ),                  // -- output

      // -- Errors to record from CFG Sub-System, Descriptor Table, and VPD
      .vpd_err_unimplemented_addr          ( vpd_err_unimplemented_addr ),                // -- input
      .cfg0_cff_fifo_overflow              ( cfg0_cff_fifo_overflow ),                    // -- input
// -- .cfg1_cff_fifo_overflow              ( cfg1_cff_fifo_overflow ),                    // -- input
      .cfg0_rff_fifo_overflow              ( cfg0_rff_fifo_overflow ),                    // -- input
// -- .cfg1_rff_fifo_overflow              ( cfg1_rff_fifo_overflow ),                    // -- input
      .cfg_errvec                          ( cfg_errvec ),                                // -- input
      .cfg_errvec_valid                    ( cfg_errvec_valid )                           // -- input

    );





endmodule //-- oc_cfg
