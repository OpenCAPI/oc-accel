############################################################################
############################################################################
##
## Copyright 2016-2018 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

set fpga_card_lcase [string tolower $::env(FPGACARD)]

set root_dir      $::env(SNAP_HARDWARE_ROOT)
set fpga_part     $::env(FPGACHIP)
set fpga_card     $::env(FPGACARD)
set ip_dir        $root_dir/ip
set top_xdc_dir   $root_dir/oc-bip/board_support_packages/$fpga_card_lcase/xdc
set usr_ip_dir    $ip_dir/managed_ip_project/managed_ip_project.srcs/sources_1/ip
set action_root   $::env(ACTION_ROOT)

set sdram_used    $::env(SDRAM_USED)
set hbm_used      $::env(HBM_USED)
set bram_used     $::env(BRAM_USED)
set nvme_used     $::env(NVME_USED)
set user_clock    $::env(USER_CLOCK)
set half_width    $::env(HALF_WIDTH)
set unit_sim_used $::env(UNIT_SIM_USED)
set log_dir       $::env(LOGS_DIR)
set log_file      $log_dir/create_snap_ip.log
set ila_debug     [string toupper $::env(ILA_DEBUG)]
set odma_used     [string toupper $::env(ODMA_USED)]

set user_clk_freq $::env(USER_CLOCK_FREQ)
set axi_id_width  $::env(AXI_ID_WIDTH)

## Create a new Vivado IP Project
puts "\[CREATE_SNAP_IPs.....\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project managed_ip_project $ip_dir/managed_ip_project -force -part $fpga_part -ip >> $log_file

# Project IP Settings
# General
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

#choose type of RAM that will be connected to the DDR AXI Interface
# BRAM_USED=TRUE  500KB BRAM
# OpenCAPI3.0
# SDRAM_USED=TRUE   8GB AlphaData 9V3     DDR4 RAM CUSTOM_DBI_K4A8G085WB-RC (8Gb, x8)
set create_clkconv_snap FALSE
set create_clkconv_mem  FALSE
set create_clkconv_lite FALSE
set create_dwidth_conv  FALSE
set create_interconnect FALSE
set create_bram         FALSE
set create_ddr4_ad9v3   FALSE
set create_hbm_ad9h3   FALSE
set create_hbm_ad9h7   FALSE

if { $bram_used == "TRUE" } {
  set create_clkconv_mem  TRUE
  set create_bram        TRUE
} elseif { $sdram_used == "TRUE" } {
  set create_clkconv_mem  TRUE
  if { $fpga_card == "AD9V3"  } {
     set create_ddr4_ad9v3   TRUE
  }
} elseif {$hbm_used == "TRUE" } {
  if { $fpga_card == "AD9H3" } {
     set create_hbm_ad9h3   TRUE
  }
  if { $fpga_card == "AD9H7" } {
     set create_hbm_ad9h7   TRUE
  }
}

if { $half_width == "TRUE" } {
  set create_dwidth_conv    TRUE
} elseif { $user_clock == "TRUE" } {
  set create_clkconv_lite   TRUE
  set create_clkconv_snap   TRUE
}
if { $user_clock == "TRUE" } {
  set create_clkconv_lite   TRUE
}


# Create ODMA FIFOs
# Create channel_fifo for dsc_manager
if { $odma_used == "TRUE" }  {
  puts "                        generating FIFOs for ODMA mode"
  puts "                        generating IP channel_fifo input:1024x16 output: 256x64 for dsc_manager"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name channel_fifo -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Valid_Flag {true}                   \
                      CONFIG.Data_Count {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Full_Threshold_Assert_Value {13}    \
                      CONFIG.Full_Threshold_Negate_Value {12}    \
                     ] [get_ips channel_fifo]
  set_property generate_synth_checkpoint false [get_files $ip_dir/channel_fifo/channel_fifo.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/channel_fifo/channel_fifo.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/channel_fifo/channel_fifo.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/channel_fifo/channel_fifo.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/channel_fifo/channel_fifo.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

# Create LCL rdata_fifo for h2a_mm_engine
  puts "                        generating IP fifo_sync_32_1024i1024o for h2a_mm_engine rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_32_1024i1024o -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {32}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {32}                   \
                      CONFIG.Almost_Empty_Flag {true}                       \
                      CONFIG.Almost_Full_Flag {true}                       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count {true}                             \
                      CONFIG.Data_Count_Width {6}                 \
                      CONFIG.Write_Data_Count_Width {6}           \
                      CONFIG.Read_Data_Count_Width {6}           \
                     ] [get_ips fifo_sync_32_1024i1024o]
  set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_sync_32_1024i1024o/fifo_sync_32_1024i1024o.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/fifo_sync_32_1024i1024o/fifo_sync_32_1024i1024o.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/fifo_sync_32_1024i1024o/fifo_sync_32_1024i1024o.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/fifo_sync_32_1024i1024o/fifo_sync_32_1024i1024o.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/fifo_sync_32_1024i1024o/fifo_sync_32_1024i1024o.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

# Create AXI read data fifo for a2h_mm_engine
  puts "                        generating IP fifo_sync_1024x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_1024x8 -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_1024x8]
  set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_sync_1024x8/fifo_sync_1024x8.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/fifo_sync_1024x8/fifo_sync_1024x8.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/fifo_sync_1024x8/fifo_sync_1024x8.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/fifo_sync_1024x8/fifo_sync_1024x8.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/fifo_sync_1024x8/fifo_sync_1024x8.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
  
  puts "                        generating IP fifo_sync_9x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_9x8 -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {9}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {9}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_9x8]
  set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_sync_9x8/fifo_sync_9x8.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/fifo_sync_9x8/fifo_sync_9x8.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/fifo_sync_9x8/fifo_sync_9x8.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/fifo_sync_9x8/fifo_sync_9x8.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/fifo_sync_9x8/fifo_sync_9x8.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  puts "                        generating IP fifo_sync_512x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_512x8 -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {512}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {512}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_512x8]
  set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_sync_512x8/fifo_sync_512x8.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/fifo_sync_512x8/fifo_sync_512x8.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/fifo_sync_512x8/fifo_sync_512x8.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/fifo_sync_512x8/fifo_sync_512x8.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/fifo_sync_512x8/fifo_sync_512x8.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

# Create Descriptor fifo for a2h_mm_engine
  puts "                        generating IP fifo_sync_256x8 for a2h_mm_engine descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_256x8 -dir $ip_dir >> $log_file
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Input_Data_Width {256}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {256}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {4}                 \
                      CONFIG.Write_Data_Count_Width {4}           \
                      CONFIG.Read_Data_Count_Width {4}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_256x8]
  set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_sync_256x8/fifo_sync_256x8.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/fifo_sync_256x8/fifo_sync_256x8.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/fifo_sync_256x8/fifo_sync_256x8.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/fifo_sync_256x8/fifo_sync_256x8.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/fifo_sync_256x8/fifo_sync_256x8.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#create BlockRAM
if { $create_bram == "TRUE" } {
  puts "                        generating IP block_RAM"
  create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.* -module_name block_RAM -dir  $ip_dir >> $log_file
  set_property -dict [list                                                           \
                      CONFIG.Interface_Type {AXI4}                                   \
                      CONFIG.Write_Width_A {256}                                     \
                      CONFIG.AXI_ID_Width {4}                                        \
                      CONFIG.Write_Depth_A {8192}                                    \
                      CONFIG.Use_AXI_ID {true}                                       \
                      CONFIG.Memory_Type {Simple_Dual_Port_RAM}                      \
                      CONFIG.Use_Byte_Write_Enable {true}                            \
                      CONFIG.Byte_Size {8}                                           \
                      CONFIG.Assume_Synchronous_Clk {true}                           \
                      CONFIG.Read_Width_A {256}                                      \
                      CONFIG.Operating_Mode_A {READ_FIRST}                           \
                      CONFIG.Write_Width_B {256}                                     \
                      CONFIG.Read_Width_B {256}                                      \
                      CONFIG.Operating_Mode_B {READ_FIRST}                           \
                      CONFIG.Enable_B {Use_ENB_Pin}                                  \
                      CONFIG.Register_PortA_Output_of_Memory_Primitives {false}      \
                      CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC}           \
                      CONFIG.Port_B_Clock {100}                                      \
                      CONFIG.Port_B_Enable_Rate {100}                                \
                     ] [get_ips block_RAM]
  set_property generate_synth_checkpoint false [get_files $ip_dir/block_RAM/block_RAM.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/block_RAM/block_RAM.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/block_RAM/block_RAM.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/block_RAM/block_RAM.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}


#AXI_VIP create axi_vip_mm_check
if { $unit_sim_used == "TRUE" } {
  create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_mm_check -dir $ip_dir >> $log_file
  set_property -dict [list                                    \
                      CONFIG.ADDR_WIDTH {64}                  \
                      CONFIG.DATA_WIDTH {1024}                \
                      CONFIG.ID_WIDTH {5}                     \
                      CONFIG.AWUSER_WIDTH {9}                 \
                      CONFIG.ARUSER_WIDTH {9}                 \
                      CONFIG.RUSER_WIDTH {1}                  \
                      CONFIG.WUSER_WIDTH {1}                  \
                      CONFIG.BUSER_WIDTH {1}                  \
                     ] [get_ips axi_vip_mm_check] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_vip_mm_check/axi_vip_mm_check.xci]                    >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/axi_vip_mm_check/axi_vip_mm_check.xci]                    >> $log_file
  generate_target all                          [get_files $ip_dir/axi_vip_mm_check/axi_vip_mm_check.xci]                    >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_vip_mm_check/axi_vip_mm_check.xci] -no_script -sync -force -quiet  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/axi_vip_mm_check/axi_vip_mm_check.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  puts "                        generating IP axi_lite_passthrough"
  create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_lite_passthrough -dir $ip_dir >> $log_file
  set_property -dict [list 										   \
					  CONFIG.PROTOCOL {AXI4LITE} 				   \
					  CONFIG.SUPPORTS_NARROW {0} 				   \
					  CONFIG.HAS_BURST {0}						   \
					  CONFIG.HAS_LOCK {0}						   \
					  CONFIG.HAS_CACHE {0} 						   \
					  CONFIG.HAS_REGION {0}						   \
					  CONFIG.HAS_QOS {0}						   \
					  CONFIG.HAS_PROT {0}						   \
					 ] [get_ips axi_lite_passthrough] >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_lite_passthrough/axi_lite_passthrough.xci] -no_script -sync -force -quiet >> $log_file
  export_simulation -of_objects                [get_files $ip_dir/axi_lite_passthrough/axi_lite_passthrough.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
#CONFIG.Component_Name {axi_lite_passthrough}
}

#create axi_clock_converter_act2mem
if { $create_clkconv_mem == "TRUE" } {
  puts "                        generating IP axi_clock_converter_act2mem"
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter_act2mem -dir $ip_dir  >> $log_file

  set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter_act2mem]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_clock_converter_act2mem/axi_clock_converter_act2mem.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_clock_converter_act2mem/axi_clock_converter_act2mem.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_clock_converter_act2mem/axi_clock_converter_act2mem.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_clock_converter_act2mem/axi_clock_converter_act2mem.xci] -no_script -force >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_clock_converter_act2mem/axi_clock_converter_act2mem.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#create axi_clock_converter_act2snap
if { $create_clkconv_snap == "TRUE" } {
  puts "                        generating IP axi_clock_converter_act2snap"
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter_act2snap -dir $ip_dir  >> $log_file

  set_property -dict [list                               \
                      CONFIG.ADDR_WIDTH {64}             \
                      CONFIG.DATA_WIDTH {1024}           \
                      CONFIG.ID_WIDTH $axi_id_width      \
                      CONFIG.AWUSER_WIDTH {9}            \
                      CONFIG.ARUSER_WIDTH {9}            \
                      CONFIG.RUSER_WIDTH {1}             \
                      CONFIG.WUSER_WIDTH {1}             \
                      CONFIG.BUSER_WIDTH {1}             \
                      CONFIG.ACLK_ASYNC {1}              \
                      ] [get_ips axi_clock_converter_act2snap]
	 
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_clock_converter_act2snap/axi_clock_converter_act2snap.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_clock_converter_act2snap/axi_clock_converter_act2snap.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_clock_converter_act2snap/axi_clock_converter_act2snap.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_clock_converter_act2snap/axi_clock_converter_act2snap.xci] -no_script -force >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_clock_converter_act2snap/axi_clock_converter_act2snap.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

if { $ila_debug == "TRUE" } {

# create simple ILA
#
  set ila_width "358 4 190"
  set ila_depth "2048 2048 2048"

  set i 0
  foreach j $ila_width {
    set ila_name "ila_p$j"
    puts "                        generating IP $ila_name"
    create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name $ila_name -dir $ip_dir  >> $log_file
    set_property -dict [list CONFIG.C_PROBE0_WIDTH $j CONFIG.C_DATA_DEPTH [lindex $ila_depth $i] CONFIG.C_TRIGOUT_EN {false} CONFIG.C_TRIGIN_EN {false}] [get_ips $ila_name]
    set_property generate_synth_checkpoint false [get_files $ip_dir/$ila_name/$ila_name.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/$ila_name/$ila_name.xci] >> $log_file
    generate_target all                          [get_files $ip_dir/$ila_name/$ila_name.xci] >> $log_file
    export_ip_user_files -of_objects             [get_files $ip_dir/$ila_name/$ila_name.xci] -no_script -force >> $log_file
    export_simulation    -of_objects             [get_files $ip_dir/$ila_name/$ila_name.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

    incr i
  }
}

# create VIO
  puts "                        generating IP vio_soft_reset"
  create_ip -name vio -vendor xilinx.com -library ip -version 3.0 -module_name vio_soft_reset -dir $ip_dir  >> $log_file
  set_property -dict [list CONFIG.C_NUM_PROBE_OUT {2} CONFIG.C_EN_PROBE_IN_ACTIVITY {0} CONFIG.C_NUM_PROBE_IN {0}] [get_ips vio_soft_reset]
  set_property generate_synth_checkpoint false [get_files $ip_dir/vio_soft_reset/vio_soft_reset.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/vio_soft_reset/vio_soft_reset.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/vio_soft_reset/vio_soft_reset.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/vio_soft_reset/vio_soft_reset.xci] -no_script -force >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/vio_soft_reset/vio_soft_reset.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create axi_interconnect
if { $create_interconnect == "TRUE" } {
  puts "                        generating IP axi_interconnect"
  create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name axi_interconnect -dir $ip_dir  >> $log_file
  set_property -dict [list                                  \
                      CONFIG.NUM_SLAVE_PORTS {2}            \
                      CONFIG.THREAD_ID_WIDTH {1}            \
                      CONFIG.INTERCONNECT_DATA_WIDTH {512}  \
                      CONFIG.S00_AXI_DATA_WIDTH {512}       \
                      CONFIG.S01_AXI_DATA_WIDTH {128}       \
                      CONFIG.M00_AXI_DATA_WIDTH {512}       \
                      CONFIG.S00_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.S01_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.M00_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.S00_AXI_REGISTER {1}           \
                      CONFIG.S01_AXI_REGISTER {1}           \
                      CONFIG.M00_AXI_REGISTER {1}           \
                     ] [get_ips axi_interconnect]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_interconnect/axi_interconnect.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

# axi_dwidth_converter
if { $create_dwidth_conv == "TRUE" } {
  puts "                        generating axi_dwidth_converter ......"
  create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_dwidth_converter -dir $ip_dir  >> $log_file
  set_property -dict [list CONFIG.ADDR_WIDTH {64}              \
                           CONFIG.FIFO_MODE {2}                \
                           CONFIG.ACLK_ASYNC {1}               \
                           CONFIG.SI_DATA_WIDTH {512}          \
                           CONFIG.MI_DATA_WIDTH {1024}         \
                           CONFIG.SI_ID_WIDTH $axi_id_width    \
                           ] [get_ips axi_dwidth_converter]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_dwidth_converter/axi_dwidth_converter.xci] >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/axi_dwidth_converter/axi_dwidth_converter.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_dwidth_converter/axi_dwidth_converter.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_dwidth_converter/axi_dwidth_converter.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_dwidth_converter/axi_dwidth_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

# axi_lite_clock_converter
if { $create_clkconv_lite == "TRUE" } {
  puts "                        generating axi_lite_clock_converter ......"
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_lite_clock_converter -dir $ip_dir  >> $log_file
  set_property -dict [list        CONFIG.PROTOCOL {AXI4LITE} \
                                  CONFIG.DATA_WIDTH {32}     \
                                  CONFIG.ID_WIDTH {0}        \
                                  CONFIG.AWUSER_WIDTH {0}    \
                                  CONFIG.ARUSER_WIDTH {0}    \
                                  CONFIG.RUSER_WIDTH {0}     \
                                  CONFIG.WUSER_WIDTH {0}     \
                                  CONFIG.BUSER_WIDTH {0}     \
                                  CONFIG.ACLK_ASYNC {1}      \
                                  ] [get_ips axi_lite_clock_converter]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_lite_clock_converter/axi_lite_clock_converter.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_lite_clock_converter/axi_lite_clock_converter.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_lite_clock_converter/axi_lite_clock_converter.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_lite_clock_converter/axi_lite_clock_converter.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_lite_clock_converter/axi_lite_clock_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

if { $user_clock == "TRUE" } {
  puts "                        generating clk_wiz ......"
  create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name user_clock_gen -dir $ip_dir  >> $log_file
  if { $user_clk_freq == "50" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.355}  \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {4}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {23.875}        \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {23.875}       \
                                    CONFIG.CLKOUT1_JITTER {150.988}             \
                                    CONFIG.CLKOUT1_PHASE_ERROR {151.043}        \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "100" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.710} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {2}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {11.875}        \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {11.875}       \
                                    CONFIG.CLKOUT1_JITTER {114.802}             \
                                    CONFIG.CLKOUT1_PHASE_ERROR {87.006}         \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "150" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {151.065} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {1}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {6.000}         \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {8.000}        \
                                    CONFIG.CLKOUT1_JITTER {97.589}              \
                                    CONFIG.CLKOUT1_PHASE_ERROR {82.304}         \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "250" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {251.775} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {2}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {11.875}        \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.750}        \
                                    CONFIG.CLKOUT1_JITTER {96.816}              \
                                    CONFIG.CLKOUT1_PHASE_ERROR {87.006}         \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "300" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {302.130} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {1}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {6.000}         \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.000}        \
                                    CONFIG.CLKOUT1_JITTER {85.433}              \
                                    CONFIG.CLKOUT1_PHASE_ERROR {82.304}         \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "350" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {352.485} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {4}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {23.625}        \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.375}        \
                                    CONFIG.CLKOUT1_JITTER {108.174}             \
                                    CONFIG.CLKOUT1_PHASE_ERROR {152.728}        \
    ] [get_ips user_clock_gen] 
  } elseif { $user_clk_freq == "400" } {
    set_property -dict [ list       CONFIG.PRIM_IN_FREQ {201.420}               \
                                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {402.840} \
                                    CONFIG.CLKIN1_JITTER_PS {49.64}             \
                                    CONFIG.MMCM_DIVCLK_DIVIDE {1}               \
                                    CONFIG.MMCM_CLKFBOUT_MULT_F {6.000}         \
                                    CONFIG.MMCM_CLKIN1_PERIOD {4.965}           \
                                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}            \
                                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.000}        \
                                    CONFIG.CLKOUT1_JITTER {80.853}              \
                                    CONFIG.CLKOUT1_PHASE_ERROR {82.304}         \
    ] [get_ips user_clock_gen] 
  } else {
    puts "                        ERROR: Unexpected clock frequency for action"
    exit
  }
  set_property generate_synth_checkpoint false [get_files $ip_dir/user_clock_gen/user_clock_gen.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/user_clock_gen/user_clock_gen.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/user_clock_gen/user_clock_gen.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/user_clock_gen/user_clock_gen.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/user_clock_gen/user_clock_gen.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}


#DDR4 create ddr4sdramm with ECC (AD9V3)
if { $create_ddr4_ad9v3 == "TRUE" } {
  puts "	                generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_TimePeriod {833}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {3332}                                  \
                      CONFIG.C0.DDR4_MemoryPart {CUSTOM_DBI_K4A8G085WB-RC}                    \
                      CONFIG.C0.DDR4_DataWidth {72}                                           \
                      CONFIG.C0.DDR4_CasLatency {20}                                          \
                      CONFIG.C0.DDR4_CustomParts $top_xdc_dir/adm-pcie-9v3_custom_parts_2400.csv \
                      CONFIG.C0.DDR4_isCustom {true}                                          \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
                      CONFIG.Simulation_Mode {Unisim}                                         \
                      CONFIG.C0.DDR4_DataMask {NO_DM_DBI_WR_RD}                               \
                      CONFIG.C0.DDR4_Ecc {true}                                               \
                      CONFIG.C0.DDR4_AxiDataWidth {512}                                       \
                      CONFIG.C0.DDR4_AxiAddressWidth {33}                                     \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                           \
                      CONFIG.C0.BANK_GROUP_WIDTH {2}                                          \
                     ] [get_ips ddr4sdram] >> $log_file

  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR4 create ddr4sdramm example design
  puts "	                generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}

#HBM controller(AD9H3)
if { $create_hbm_ad9h3 == "TRUE" } {
  puts "                        generating axi_hbm_dwidth_converter ......"
  create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_hbm_dwidth_converter -dir $ip_dir  >> $log_file
  set_property -dict [list CONFIG.PROTOCOL {AXI4}              \
                           CONFIG.ADDR_WIDTH {33}              \
                           CONFIG.SI_DATA_WIDTH {512}          \
                           CONFIG.MI_DATA_WIDTH {256}          \
                           CONFIG.MAX_SPLIT_BEATS {16}         \
                           ] [get_ips axi_hbm_dwidth_converter]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_hbm_dwidth_converter/axi_hbm_dwidth_converter.xci] >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/axi_hbm_dwidth_converter/axi_hbm_dwidth_converter.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_hbm_dwidth_converter/axi_hbm_dwidth_converter.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_hbm_dwidth_converter/axi_hbm_dwidth_converter.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_hbm_dwidth_converter/axi_hbm_dwidth_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  puts "	                generating IP hbm_ctrl for $fpga_card"
  create_ip -name hbm -vendor xilinx.com -library ip -version 1.0 -module_name hbm_ctrl -dir $ip_dir >> $log_file
  set_property -dict [list                                                  \
                      CONFIG.USER_HBM_REF_CLK_0 {200}                       \
                      CONFIG.USER_HBM_REF_CLK_PS_0 {2500.00}                \
                      CONFIG.USER_HBM_REF_CLK_XDC_0 {5.00}                  \
                      CONFIG.USER_HBM_FBDIV_0 {18}                          \
                      CONFIG.USER_HBM_RES_0 {9}                             \
                      CONFIG.USER_HBM_LOCK_REF_DLY_0 {20}                   \
                      CONFIG.USER_HBM_LOCK_FB_DLY_0 {20}                    \
                      CONFIG.USER_HBM_HEX_CP_RES_0 {0x00009600}             \
                      CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_0 {0x00001414}    \
                      CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000482}    \
                      CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK}               \
                      CONFIG.USER_SAXI_01 {false}                           \
                      CONFIG.USER_SAXI_02 {false}                           \
                      CONFIG.USER_SAXI_03 {false}                           \
                      CONFIG.USER_SAXI_04 {false}                           \
                      CONFIG.USER_SAXI_05 {false}                           \
                      CONFIG.USER_SAXI_06 {false}                           \
                      CONFIG.USER_SAXI_07 {false}                           \
                      CONFIG.USER_SAXI_08 {false}                           \
                      CONFIG.USER_SAXI_09 {false}                           \
                      CONFIG.USER_SAXI_10 {false}                           \
                      CONFIG.USER_SAXI_11 {false}                           \
                      CONFIG.USER_SAXI_12 {false}                           \
                      CONFIG.USER_SAXI_13 {false}                           \
                      CONFIG.USER_SAXI_14 {false}                           \
                      CONFIG.USER_SAXI_15 {false}                           \
                     ] [get_ips hbm_ctrl] >> $log_file

  set_property generate_synth_checkpoint false [get_files $ip_dir/hbm_ctrl/hbm_ctrl.xci]                    >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/hbm_ctrl/hbm_ctrl.xci]                    >> $log_file
  generate_target all                          [get_files $ip_dir/hbm_ctrl/hbm_ctrl.xci]                    >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/hbm_ctrl/hbm_ctrl.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/hbm_ctrl/hbm_ctrl.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

# User IPs
set action_vhdl  $action_root/hw/vhdl

if { [file exists $action_vhdl] == 1 } {
  set tcl_exists [exec find $action_vhdl/ -name *.tcl]

  if { $tcl_exists != "" } {
    foreach tcl_file [glob -nocomplain -dir $action_vhdl *.tcl] {
      set tcl_file_name [exec basename $tcl_file]
      puts "                        sourcing $tcl_file_name"
      source $tcl_file >> $log_file
    }
  }

  foreach usr_ip [glob -nocomplain -dir $usr_ip_dir *] {
    set usr_ip_name [exec basename $usr_ip]
    puts "                        generating user IP $usr_ip_name"
    set usr_ip_xci [glob -dir $usr_ip *.xci]
    #generate_target {instantiation_template} [get_files $z] >> $log_file
    generate_target all              [get_files $usr_ip_xci] >> $log_file
    export_ip_user_files -of_objects [get_files $usr_ip_xci] -no_script -force  >> $log_file
    export_simulation -of_objects    [get_files $usr_ip_xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
  }
}

puts "\[CREATE_SNAP_IPs.....\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
