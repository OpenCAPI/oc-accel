
## Env Variables

set action_root [lindex $argv 0]
set fpga_part  	[lindex $argv 1]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir 	$action_root/ip
set log_dir     $action_root/../../hardware/logs
set log_file    $log_dir/create_action_ip.log
set src_dir 	$aip_dir/action_ip_prj/action_ip_prj.srcs/sources_1/ip

# Create a new Vivado IP Project
puts "\[CREATE_ACTION_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        Creating IP in $src_dir"
create_project action_ip_prj $aip_dir/action_ip_prj -force -part $fpga_part -ip >> $log_file

## Project IP Settings
## General
#   create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_p157 -dir $src_dir >> $log_file
#   set_property -dict [list CONFIG.C_PROBE0_WIDTH 157 CONFIG.C_DATA_DEPTH 2048 CONFIG.C_TRIGOUT_EN {false} CONFIG.C_TRIGIN_EN {false}] [get_ips ila_p157]
#    set_property generate_synth_checkpoint false [get_files $src_dir/ila_p157/ila_p157.xci]
#    generate_target {instantiation_template}     [get_files $src_dir/ila_p157/ila_p157.xci] >> $log_file
#    generate_target all                          [get_files $src_dir/ila_p157/ila_p157.xci] >> $log_file


close_project
puts "\[CREATE_ACTION_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
