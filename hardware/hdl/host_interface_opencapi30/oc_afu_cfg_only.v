/*
 * Copyright 2020 International Business Machines
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

// It is simply a wrapper of afu_descriptor
// Running at tlx clock



module oc_afu_cfg_only (

  // // Clocks & Reset
    input                 clock_tlx
  , input                 reset

  // // AFU Index
  , input           [5:0] afu_index                            // // This AFU's Index within the Function
                                                             

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

  );

  // // ********************************************************************************************************************************
  // // wires
  // // ********************************************************************************************************************************


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
  // // AFU DESCRIPTOR TIES
  // // ********************************************************************************************************************************

  assign  ro_name_space[191:0]            =  { "IBM,oc-accel", { 12{8'h00} } };    // // Keep this string EXACTLY 24 characters long
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
      .reset                                       ( reset                           ) , // input

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


endmodule

