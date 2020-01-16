
## Env Variables

set action_root [lindex $argv 0]
set fpga_part  	[lindex $argv 1]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir 	$action_root/ip
set log_dir     $action_root/../../hardware/logs
set log_file    $log_dir/create_action_ip.log
set src_dir 	$aip_dir/action_ip_prj/action_ip_prj.srcs/sources_1/ip
set odma_512_used [string toupper $::env(ODMA_512_USED)]
set odma_st_mode_used [string toupper $::env(ODMA_ST_MODE_USED)]

## Create a new Vivado IP Project
puts "\[CREATE_ACTION_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        Creating IP in $src_dir"
create_project action_ip_prj $aip_dir/action_ip_prj -force -part $fpga_part -ip >> $log_file

# Project IP Settings
# General
puts "                        Generating fifo_sync_32_512i512o ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_sync_32_512i512o  >> $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {512} CONFIG.Input_Depth {32} CONFIG.Output_Data_Width {512} CONFIG.Output_Depth {32} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {5} CONFIG.Write_Data_Count_Width {5} CONFIG.Read_Data_Count_Width {5} CONFIG.Full_Threshold_Assert_Value {30} CONFIG.Full_Threshold_Negate_Value {29} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_sync_32_512i512o]
set_property generate_synth_checkpoint false [get_files $src_dir/fifo_sync_32_512i512o/fifo_sync_32_512i512o.xci] >> $log_file
generate_target all [get_files $src_dir/fifo_sync_32_512i512o/fifo_sync_32_512i512o.xci] >> $log_file

#puts "                        Generating axi_vip_master ......"
#create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_master >> $log_file
#set_property -dict [list CONFIG.Component_Name {axi_vip_master} CONFIG.INTERFACE_MODE {MASTER} CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {1024} CONFIG.ID_WIDTH {5} CONFIG.AWUSER_WIDTH {9} CONFIG.ARUSER_WIDTH {9} CONFIG.RUSER_WIDTH {1} CONFIG.WUSER_WIDTH {1} CONFIG.BUSER_WIDTH {1}] [get_ips axi_vip_master]
#generate_target {instantiation_template} [get_files  $src_dir/axi_vip_master/axi_vip_master.xci] >> $log_file
#set_property generate_synth_checkpoint false [get_files  $src_dir/axi_vip_master/axi_vip_master.xci] >> $log_file
#generate_target all [get_files  $src_dir/axi_vip_master/axi_vip_master.xci] >> $log_file
#export_ip_user_files -of_objects [get_files $src_dir/axi_vip_master/axi_vip_master.xci] -no_script -sync -force -quiet >> $log_file
#export_simulation -of_objects [get_files $src_dir/axi_vip_master/axi_vip_master.xci] -directory $src_dir/ip_user_files/sim_scripts -force >> $log_file
#
#puts "                        Generating axi_lite_vip_slave ......"
#create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_lite_vip_slave >> $log_file
#set_property -dict [list CONFIG.Component_Name {axi_lite_vip_slave} CONFIG.PROTOCOL {AXI4LITE} CONFIG.INTERFACE_MODE {SLAVE} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0} CONFIG.HAS_PROT {0}] [get_ips axi_lite_vip_slave] >> $log_file
#generate_target {instantiation_template} [get_files $src_dir/axi_lite_vip_slave/axi_lite_vip_slave.xci] >> $log_file
#set_property generate_synth_checkpoint false [get_files  $src_dir/axi_lite_vip_slave/axi_lite_vip_slave.xci] >> $log_file
#generate_target all [get_files  $src_dir/axi_lite_vip_slave/axi_lite_vip_slave.xci] >> $log_file
#export_ip_user_files -of_objects [get_files $src_dir/axi_lite_vip_slave/axi_lite_vip_slave.xci] -no_script -sync -force -quiet >> $log_file
#export_simulation -of_objects [get_files $src_dir/axi_lite_vip_slave/axi_lite_vip_slave.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#
#puts "                        Generating axi_vip_slave ......"
#if { $odma_512_used == "TRUE" } {
#  create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_slave >> $log_file
#  set_property -dict [list CONFIG.Component_Name {axi_vip_slave} CONFIG.PROTOCOL {AXI4} CONFIG.INTERFACE_MODE {SLAVE} CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {5} CONFIG.AWUSER_WIDTH {9} CONFIG.ARUSER_WIDTH {9} CONFIG.RUSER_WIDTH {1} CONFIG.WUSER_WIDTH {1} CONFIG.BUSER_WIDTH {1} CONFIG.SUPPORTS_NARROW {1} CONFIG.HAS_BURST {1} CONFIG.HAS_LOCK {1} CONFIG.HAS_CACHE {1} CONFIG.HAS_REGION {1} CONFIG.HAS_QOS {1} CONFIG.HAS_PROT {1}] [get_ips axi_vip_slave] >> $log_file
#  generate_target {instantiation_template} [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  generate_target all [get_files  $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#} else {
#  create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_slave >> $log_file
#  set_property -dict [list CONFIG.Component_Name {axi_vip_slave} CONFIG.PROTOCOL {AXI4} CONFIG.INTERFACE_MODE {SLAVE} CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {1024} CONFIG.ID_WIDTH {5} CONFIG.AWUSER_WIDTH {9} CONFIG.ARUSER_WIDTH {9} CONFIG.RUSER_WIDTH {1} CONFIG.WUSER_WIDTH {1} CONFIG.BUSER_WIDTH {1} CONFIG.SUPPORTS_NARROW {1} CONFIG.HAS_BURST {1} CONFIG.HAS_LOCK {1} CONFIG.HAS_CACHE {1} CONFIG.HAS_REGION {1} CONFIG.HAS_QOS {1} CONFIG.HAS_PROT {1}] [get_ips axi_vip_slave] >> $log_file
#  generate_target {instantiation_template} [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  generate_target all [get_files  $src_dir/axi_vip_slave/axi_vip_slave.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_vip_slave/axi_vip_slave.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#}
#
#puts "                        Generating axi_lite_vip_master ......"
#create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_lite_vip_master >> $log_file
#set_property -dict [list CONFIG.Component_Name {axi_lite_vip_master} CONFIG.PROTOCOL {AXI4LITE} CONFIG.INTERFACE_MODE {MASTER} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0} CONFIG.HAS_PROT {0}] [get_ips axi_lite_vip_master] >> $log_file
#generate_target {instantiation_template} [get_files $src_dir/axi_lite_vip_master/axi_lite_vip_master.xci] >> $log_file
#set_property generate_synth_checkpoint false [get_files  $src_dir/axi_lite_vip_master/axi_lite_vip_master.xci] >> $log_file
#generate_target all [get_files  $src_dir/axi_lite_vip_master/axi_lite_vip_master.xci] >> $log_file
#export_ip_user_files -of_objects [get_files $src_dir/axi_lite_vip_master/axi_lite_vip_master.xci] -no_script -sync -force -quiet >> $log_file
#export_simulation -of_objects [get_files $src_dir/axi_lite_vip_master/axi_lite_vip_master.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#
## puts "                        Generating axi_lite_passthrough ......"
## create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_lite_passthrough >> $log_file
## set_property -dict [list CONFIG.Component_Name {axi_lite_passthrough} CONFIG.PROTOCOL {AXI4LITE} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0} CONFIG.HAS_PROT {0}] [get_ips axi_lite_passthrough] >> $log_file
## generate_target {instantiation_template} [get_files $src_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
## set_property generate_synth_checkpoint false [get_files  $src_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
## generate_target all [get_files  $src_dir/axi_lite_passthrough/axi_lite_passthrough.xci] >> $log_file
## export_ip_user_files -of_objects [get_files $src_dir/axi_lite_passthrough/axi_lite_passthrough.xci] -no_script -sync -force -quiet >> $log_file
## export_simulation -of_objects [get_files $src_dir/axi_lite_passthrough/axi_lite_passthrough.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#
#puts "                        Generating axi_data_width_converter ......"
#create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_data_width_converter >> $log_file
#set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.SI_DATA_WIDTH {1024} CONFIG.MI_DATA_WIDTH {512} CONFIG.SI_ID_WIDTH {5}] [get_ips axi_data_width_converter] >> $log_file
#generate_target {instantiation_template} [get_files $src_dir/axi_data_width_converter/axi_data_width_converter.xci] >> $log_file
#set_property generate_synth_checkpoint false [get_files  $src_dir/axi_data_width_converter/axi_data_width_converter.xci] >> $log_file
#generate_target all [get_files  $src_dir/axi_data_width_converter/axi_data_width_converter.xci] >> $log_file
#export_ip_user_files -of_objects [get_files $src_dir/axi_data_width_converter/axi_data_width_converter.xci] -no_script -sync -force -quiet >> $log_file
#export_simulation -of_objects [get_files $src_dir/axi_data_width_converter/axi_data_width_converter.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {xcelium=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/xcelium} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#
#if { $odma_512_used == "TRUE" } {
#  puts "                        Generating axi_st_vip_slave ......"
#  create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_st_vip_slave >> $log_file
#  set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.TDATA_NUM_BYTES {64} CONFIG.TID_WIDTH {5} CONFIG.TUSER_WIDTH {9} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axi_st_vip_slave}] [get_ips axi_st_vip_slave]
#  generate_target {instantiation_template} [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  generate_target all [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#  
#  puts "                        Generating axi_st_vip_master ......"
#  create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_st_vip_master >> $log_file
#  set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.TDATA_NUM_BYTES {64} CONFIG.TID_WIDTH {5} CONFIG.TUSER_WIDTH {9} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axi_st_vip_master}] [get_ips axi_st_vip_master]
#  generate_target {instantiation_template} [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  generate_target all [get_files  $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#} else {
#  puts "                        Generating axi_st_vip_slave ......"
#  create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_st_vip_slave >> $log_file
#  set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.TDATA_NUM_BYTES {128} CONFIG.TID_WIDTH {5} CONFIG.TUSER_WIDTH {9} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axi_st_vip_slave}] [get_ips axi_st_vip_slave]
#  generate_target {instantiation_template} [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  generate_target all [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_st_vip_slave/axi_st_vip_slave.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#  
#  puts "                        Generating axi_st_vip_master ......"
#  create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_st_vip_master >> $log_file
#  set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.TDATA_NUM_BYTES {128} CONFIG.TID_WIDTH {5} CONFIG.TUSER_WIDTH {9} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axi_st_vip_master}] [get_ips axi_st_vip_master]
#  generate_target {instantiation_template} [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  set_property generate_synth_checkpoint false [get_files  $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  generate_target all [get_files  $src_dir/axi_st_vip_master/axi_st_vip_master.xci] >> $log_file
#  export_ip_user_files -of_objects [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] -no_script -sync -force -quiet >> $log_file
#  export_simulation -of_objects [get_files $src_dir/axi_st_vip_master/axi_st_vip_master.xci] -directory $src_dir/ip_user_files/sim_scripts -ip_user_files_dir $src_dir/ip_user_files -ipstatic_source_dir $src_dir/ip_user_files/ipstatic -lib_map_path [list {modelsim=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {vcs=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$src_dir/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet >> $log_file
#}
close_project
puts "\[CREATE_ACTION_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
