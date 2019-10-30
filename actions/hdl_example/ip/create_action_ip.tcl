
## Env Variables

set action_root [lindex $argv 0]
set fpga_part  	[lindex $argv 1]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir 	$action_root/ip
set log_dir     $action_root/../../hardware/logs
set log_file    $log_dir/create_action_ip.log
set src_dir 	$aip_dir/action_ip_prj/action_ip_prj.srcs/sources_1/ip

## Create a new Vivado IP Project
puts "\[CREATE_ACTION_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        Creating IP in $src_dir"
#create_project action_ip_prj $aip_dir/action_ip_prj -force -part $fpga_part -ip >> $log_file
#
## Project IP Settings
## General
#puts "                        Generating axi_dwidth_converter ......"
#create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_dwidth_converter_0 >> $log_file
#set_property -dict [list CONFIG.ADDR_WIDTH {64} CONFIG.SI_DATA_WIDTH {512} CONFIG.MI_DATA_WIDTH {1024}] [get_ips axi_dwidth_converter_0]
#
#generate_target all [get_files $src_dir/axi_dwidth_converter_0/axi_dwidth_converter_0.xci] >> $log_file
#
#close_project
puts "\[CREATE_ACTION_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
