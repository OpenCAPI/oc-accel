
## Env Variables

set action_root [lindex $argv 0]
set fpga_part   [lindex $argv 1]
set num_kernels [lindex $argv 2]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir     $action_root/ip/framework
#set log_dir     $action_root/../../hardware/logs
set log_dir     .
set log_file    $log_dir/create_multiprocess_framework_ip.log
set src_dir     $aip_dir/framework_ip_prj/framework_ip_prj.srcs/sources_1/ip


## Create a new Vivado IP Project
puts "\[CREATE_MULTIPROCESS_FRAMEWORK_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        NUM_KERNELS = $num_kernels"
puts "                        Creating IP in $src_dir"
create_project framework_ip_prj $aip_dir/framework_ip_prj -force -part $fpga_part -ip > $log_file

# Project IP Settings
# General
puts "                        Generating fifo_sync_256_64i64o ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_sync_256_64i64o  >> $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {64} CONFIG.Input_Depth {256} CONFIG.Output_Data_Width {64} CONFIG.Output_Depth {256} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {8} CONFIG.Write_Data_Count_Width {8} CONFIG.Read_Data_Count_Width {8} CONFIG.Full_Threshold_Assert_Value {254} CONFIG.Full_Threshold_Negate_Value {253} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_sync_256_64i64o]
set_property generate_synth_checkpoint false [get_files $src_dir/fifo_sync_256_64i64o/fifo_sync_256_64i64o.xci] >> $log_file
generate_target all [get_files $src_dir/fifo_sync_256_64i64o/fifo_sync_256_64i64o.xci] >> $log_file


puts "                        Generating host_axi_interconnect_0 ......"
create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name host_axi_interconnect_0 >> $log_file
set_property -dict [list CONFIG.AXI_ADDR_WIDTH {64} \
CONFIG.INTERCONNECT_DATA_WIDTH {1024} \
CONFIG.THREAD_ID_WIDTH {0} \
CONFIG.M00_AXI_DATA_WIDTH {1024} \
CONFIG.M00_AXI_WRITE_ISSUING {32} \
CONFIG.M00_AXI_READ_ISSUING {32} \
CONFIG.M00_AXI_WRITE_FIFO_DEPTH {0} \
CONFIG.M00_AXI_READ_FIFO_DEPTH {0} \
CONFIG.M00_AXI_REGISTER {1}] \
[get_ips host_axi_interconnect_0] >> $log_file

# Set data width for each slave
set_property CONFIG.NUM_SLAVE_PORTS [expr ${num_kernels}+1] [get_ips host_axi_interconnect_0] >> $log_file
set i 0
while {$i < [expr ${num_kernels}+1]} {
    set s_config [format "S%02d_AXI_DATA_WIDTH" $i]
    set_property CONFIG.${s_config} {1024} [get_ips host_axi_interconnect_0] >> $log_file
    set s_config [format "S%02d_AXI_WRITE_ACCEPTANCE" $i]
    set_property CONFIG.${s_config} {32} [get_ips host_axi_interconnect_0] >> $log_file
    set s_config [format "S%02d_AXI_READ_ACCEPTANCE" $i]
    set_property CONFIG.${s_config} {32} [get_ips host_axi_interconnect_0] >> $log_file
    set s_config [format "S%02d_AXI_WRITE_FIFO_DEPTH" $i]
    set_property CONFIG.${s_config} {0} [get_ips host_axi_interconnect_0] >> $log_file
    set s_config [format "S%02d_AXI_READ_FIFO_DEPTH" $i]
    set_property CONFIG.${s_config} {0} [get_ips host_axi_interconnect_0] >> $log_file
    set s_config [format "S%02d_AXI_REGISTER" $i]
    set_property CONFIG.${s_config} {1} [get_ips host_axi_interconnect_0] >> $log_file
    incr i
}

set_property generate_synth_checkpoint false [get_files $src_dir/host_axi_interconnect_0/host_axi_interconnect_0.xci] >> $log_file
generate_target all [get_files $src_dir/host_axi_interconnect_0/host_axi_interconnect_0.xci] >> $log_file

puts "                        Generating host_axi_lite_crossbar_0 ......"
create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name host_axi_lite_crossbar_0 >> $log_file
set_property CONFIG.PROTOCOL {AXI4LITE} [get_ips host_axi_lite_crossbar_0] >> $log_file

# Set addr width and base addr for each master
set_property CONFIG.NUM_MI [expr ${num_kernels}+1] [get_ips host_axi_lite_crossbar_0] >> $log_file
set i 0
while {$i < [expr ${num_kernels}+1]} {
    set m_config [format "M%02d_A00_ADDR_WIDTH" $i]
    set_property CONFIG.${m_config} 8 [get_ips host_axi_lite_crossbar_0] >> $log_file

    set m_config [format "M%02d_A00_BASE_ADDR" $i]
    set m_value ""
    if {$i == $num_kernels} {
        set m_value [format "0x%016x" 0x0]
    } else {
        set m_value [format "0x%016x" [expr $i*0x100 + 0x200]]
    }
    set_property CONFIG.${m_config} ${m_value} [get_ips host_axi_lite_crossbar_0] >> $log_file
    incr i
}

set_property generate_synth_checkpoint false [get_files $src_dir/host_axi_lite_crossbar_0/host_axi_lite_crossbar_0.xci] >> $log_file
generate_target all [get_files $src_dir/host_axi_lite_crossbar_0/host_axi_lite_crossbar_0.xci] >> $log_file

puts "                        Generating process_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name process_fifo >> $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {88} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {88} CONFIG.Output_Depth {512} CONFIG.Use_Embedded_Registers {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {510} CONFIG.Full_Threshold_Negate_Value {509} ] [get_ips process_fifo]
set_property generate_synth_checkpoint false [get_files $src_dir/process_fifo/process_fifo.xci] >> $log_file
generate_target all [get_files $src_dir/process_fifo/process_fifo.xci] >> $log_file

puts "                        Generating completion_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name completion_fifo >> $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {41} CONFIG.Input_Depth {16} CONFIG.Output_Data_Width {41} CONFIG.Output_Depth {16} CONFIG.Use_Embedded_Registers {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {4} CONFIG.Write_Data_Count_Width {4} CONFIG.Read_Data_Count_Width {4} CONFIG.Full_Threshold_Assert_Value {14} CONFIG.Full_Threshold_Negate_Value {13} ] [get_ips completion_fifo]
set_property generate_synth_checkpoint false [get_files $src_dir/completion_fifo/completion_fifo.xci] >> $log_file
generate_target all [get_files $src_dir/completion_fifo/completion_fifo.xci] >> $log_file

puts "                        Generating descriptor_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name descriptor_fifo >> $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {1024} CONFIG.Input_Depth {64} CONFIG.Output_Data_Width {1024} CONFIG.Output_Depth {64} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {6} CONFIG.Write_Data_Count_Width {6} CONFIG.Read_Data_Count_Width {6} CONFIG.Full_Threshold_Assert_Value {62} CONFIG.Full_Threshold_Negate_Value {61}] [get_ips descriptor_fifo]
set_property generate_synth_checkpoint false [get_files $src_dir/descriptor_fifo/descriptor_fifo.xci] >> $log_file
generate_target all [get_files $src_dir/descriptor_fifo/descriptor_fifo.xci] >> $log_file

puts "                        Generating addr_ram ......"
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name addr_ram >> $log_file
set_property -dict [list CONFIG.depth {512} CONFIG.data_width {32} CONFIG.memory_type {simple_dual_port_ram}] [get_ips addr_ram]
set_property generate_synth_checkpoint false [get_files $src_dir/addr_ram/addr_ram.xci] >> $log_file
generate_target all [get_files $src_dir/addr_ram/addr_ram.xci] >> $log_file

#puts "                        Generating axi_rid_fifo ......"
#create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name axi_rid_fifo >> $log_file
#set_property -dict [list CONFIG.Component_Name {axi_rid_fifo} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {8} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {8} CONFIG.Output_Depth {512} CONFIG.Use_Embedded_Registers {false} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips axi_rid_fifo] >> $log_file
#set_property generate_synth_checkpoint false [get_files $src_dir/axi_rid_fifo/axi_rid_fifo.xci] >> $log_file
#generate_target all [get_files $src_dir/axi_rid_fifo/axi_rid_fifo.xci] >> $log_file
#
#
#puts "                        Generating axi_wid_fifo ......"
#create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name axi_wid_fifo >> $log_file
#set_property -dict [list CONFIG.Component_Name {axi_wid_fifo} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {8} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {8} CONFIG.Output_Depth {512} CONFIG.Use_Embedded_Registers {false} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips axi_wid_fifo] >> $log_file
#set_property generate_synth_checkpoint false [get_files $src_dir/axi_wid_fifo/axi_wid_fifo.xci] >> $log_file
#generate_target all [get_files $src_dir/axi_wid_fifo/axi_wid_fifo.xci] >> $log_file

close_project
puts "\[CREATE_MULTIPROCESS_FRAMEWORK_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
