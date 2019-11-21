#
# Copyright 2019 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and 
# limitations under the License.
#
## Env Variables

set action_root       [lindex $argv 0]
set fpga_part  	      [lindex $argv 1]
set num_kernels       [lindex $argv 2]
set kernel_data_width [lindex $argv 3]
set sram_data_width   [lindex $argv 4]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir 	$action_root/ip/framework
#set log_dir     $action_root/../../hardware/logs
set log_dir     .
set log_file    $log_dir/create_database_framework_ip.log
set src_dir 	$aip_dir/framework_ip_prj/framework_ip_prj.srcs/sources_1/ip


## Create a new Vivado IP Project
puts "\[CREATE_DATABASE_FRAMEWORK_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        NUM_KERNELS = $num_kernels"
puts "                        KERNELS_DATA_WIDTH = $kernel_data_width"
puts "                        Creating IP in $src_dir"
create_project framework_ip_prj $aip_dir/framework_ip_prj -force -part $fpga_part -ip > $log_file

# Project IP Settings
# General
puts "                        Generating fifo_sync_256_64i64o ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_sync_256_64i64o  > $log_file
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {64} CONFIG.Input_Depth {256} CONFIG.Output_Data_Width {64} CONFIG.Output_Depth {256} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {8} CONFIG.Write_Data_Count_Width {8} CONFIG.Read_Data_Count_Width {8} CONFIG.Full_Threshold_Assert_Value {254} CONFIG.Full_Threshold_Negate_Value {253} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_sync_256_64i64o]
set_property generate_synth_checkpoint false [get_files $src_dir/fifo_sync_256_64i64o/fifo_sync_256_64i64o.xci] > $log_file
generate_target all [get_files $src_dir/fifo_sync_256_64i64o/fifo_sync_256_64i64o.xci] > $log_file


puts "                        Generating host_axi_interconnect_0 ......"
create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name host_axi_interconnect_0 > $log_file
set_property -dict [list CONFIG.AXI_ADDR_WIDTH {64} \
CONFIG.INTERCONNECT_DATA_WIDTH ${kernel_data_width} \
CONFIG.THREAD_ID_WIDTH {4} \
CONFIG.M00_AXI_DATA_WIDTH {1024} \
CONFIG.M00_AXI_WRITE_ISSUING {32} \
CONFIG.M00_AXI_READ_ISSUING {32} \
CONFIG.M00_AXI_WRITE_FIFO_DEPTH {512} \
CONFIG.M00_AXI_READ_FIFO_DEPTH {512}] \
[get_ips host_axi_interconnect_0] > $log_file
#CONFIG.M00_AXI_REGISTER {1}]

# Set data width for each slave
set_property CONFIG.NUM_SLAVE_PORTS ${num_kernels} [get_ips host_axi_interconnect_0] > $log_file
set i 0
while {$i < ${num_kernels}} {
    set s_config [format "S%02d_AXI_DATA_WIDTH" $i]
    set_property CONFIG.${s_config} ${kernel_data_width} [get_ips host_axi_interconnect_0] > $log_file
    set s_config [format "S%02d_AXI_WRITE_ACCEPTANCE" $i]
    set_property CONFIG.${s_config} {32} [get_ips host_axi_interconnect_0] > $log_file
    set s_config [format "S%02d_AXI_READ_ACCEPTANCE" $i]
    set_property CONFIG.${s_config} {32} [get_ips host_axi_interconnect_0] > $log_file
    set s_config [format "S%02d_AXI_WRITE_FIFO_DEPTH" $i]
    set_property CONFIG.${s_config} {512} [get_ips host_axi_interconnect_0] > $log_file
    set s_config [format "S%02d_AXI_READ_FIFO_DEPTH" $i]
    set_property CONFIG.${s_config} {512} [get_ips host_axi_interconnect_0] > $log_file
    #set s_config [format "S%02d_AXI_REGISTER" $i]
    #set_property CONFIG.${s_config} {1} [get_ips host_axi_interconnect_0] > $log_file
    incr i
}

set_property generate_synth_checkpoint false [get_files $src_dir/host_axi_interconnect_0/host_axi_interconnect_0.xci] > $log_file
generate_target all [get_files $src_dir/host_axi_interconnect_0/host_axi_interconnect_0.xci] > $log_file

puts "                        Generating host_axi_lite_crossbar_0 ......"
create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name host_axi_lite_crossbar_0 > $log_file
set_property CONFIG.PROTOCOL {AXI4LITE} [get_ips host_axi_lite_crossbar_0] > $log_file

# Set addr width and base addr for each master
set_property CONFIG.NUM_MI [expr ${num_kernels}+1] [get_ips host_axi_lite_crossbar_0] > $log_file
set i 0
while {$i < [expr ${num_kernels}+1]} {
    set m_config [format "M%02d_A00_ADDR_WIDTH" $i]
    set_property CONFIG.${m_config} 17 [get_ips host_axi_lite_crossbar_0] > $log_file

    set m_config [format "M%02d_A00_BASE_ADDR" $i]
    set m_value ""
    if {$i == $num_kernels} {
        set m_value [format "0x%022x" 0x0]
    } else {
        set m_value [format "0x%022x" [expr $i*0x20000 + 0x20000]]
    }
    set_property CONFIG.${m_config} ${m_value} [get_ips host_axi_lite_crossbar_0] > $log_file
    incr i
}

set_property generate_synth_checkpoint false [get_files $src_dir/host_axi_lite_crossbar_0/host_axi_lite_crossbar_0.xci] > $log_file
generate_target all [get_files $src_dir/host_axi_lite_crossbar_0/host_axi_lite_crossbar_0.xci] > $log_file

#puts "                        Generating job_manager_fifo ......"
#create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name job_manager_fifo > $log_file
#set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {512} CONFIG.Input_Depth {16} CONFIG.Output_Data_Width {512} CONFIG.Output_Depth {16} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {4} CONFIG.Write_Data_Count_Width {4} CONFIG.Read_Data_Count_Width {4} CONFIG.Full_Threshold_Assert_Value {14} CONFIG.Full_Threshold_Negate_Value {13} CONFIG.Enable_Safety_Circuit {true}] [get_ips job_manager_fifo]
#set_property generate_synth_checkpoint false [get_files $src_dir/job_manager_fifo/job_manager_fifo.xci] > $log_file
#generate_target all [get_files $src_dir/job_manager_fifo/job_manager_fifo.xci] > $log_file

puts "                        Generating AXI2APB bridge ......"
create_ip -name axi_apb_bridge -vendor xilinx.com -library ip -version 3.0 -module_name axi_apb_bridge_0 > $log_file
set_property -dict [list CONFIG.C_APB_NUM_SLAVES {1}] [get_ips axi_apb_bridge_0] > $log_file
set_property generate_synth_checkpoint false [get_files $src_dir/axi_apb_bridge_0/axi_apb_bridge_0.xci] > $log_file
generate_target all [get_files  $src_dir/axi_apb_bridge_0/axi_apb_bridge_0.xci] > $log_file

puts "                        Generating AXI-BRAM ......"
create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name axi_bram_ctrl_0 > $log_file
set_property -dict [list CONFIG.DATA_WIDTH ${sram_data_width} CONFIG.ID_WIDTH {8} CONFIG.SINGLE_PORT_BRAM {1} CONFIG.ECC_TYPE {0} CONFIG.BMG_INSTANCE {INTERNAL}] [get_ips axi_bram_ctrl_0] > $log_file
set_property generate_synth_checkpoint false [get_files $src_dir/axi_bram_ctrl_0/axi_bram_ctrl_0.xci] > $log_file
generate_target all [get_files  $src_dir/axi_bram_ctrl_0/axi_bram_ctrl_0.xci] > $log_file

close_project
puts "\[CREATE_DATABASE_FRAMEWORK_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
