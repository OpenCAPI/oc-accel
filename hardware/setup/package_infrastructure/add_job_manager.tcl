############################################################################
############################################################################
##
## Copyright 2020 International Business Machines
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

set hardware_dir            $::env(OCACCEL_HARDWARE_ROOT)
set kernel_number           $::env(KERNEL_NUMBER)
set src_dir                 $hardware_dir/hdl/infrastructure/job_manager
set logfile                 $hardware_dir/logs/create_job_manager_ips.log
set HDL_PP                  $hardware_dir/../scripts/utils/hdl_pp
set def_file                $src_dir/def.h

exec echo "#define NUM_KERNELS $kernel_number" > $def_file
exec $HDL_PP/vcp -i $src_dir/job_scheduler.v_source -o $src_dir/job_scheduler.vcp -imacros $def_file 2>> $logfile
exec perl -I $HDL_PP/plugins -Meperl $HDL_PP/eperl -o $src_dir/job_scheduler.v $src_dir/job_scheduler.vcp 2>> $logfile
exec $HDL_PP/vcp -i $src_dir/jm_framework.v_source -o $src_dir/jm_framework.vcp -imacros $def_file 2>> $logfile
exec perl -I $HDL_PP/plugins -Meperl $HDL_PP/eperl -o $src_dir/jm_framework.v $src_dir/jm_framework.vcp 2>> $logfile
exec $HDL_PP/vcp -i $src_dir/mp_control.v_source -o $src_dir/mp_control.vcp -imacros $def_file 2>> $logfile
exec perl -I $HDL_PP/plugins -Meperl $HDL_PP/eperl -o $src_dir/mp_control.v $src_dir/mp_control.vcp 2>> $logfile

set verilog_job_manager [list \
 $src_dir/jm_framework.v \
 $src_dir/job_manager.v \
 $src_dir/job_completion.v \
 $src_dir/mp_control.v \
 $src_dir/job_scheduler.v \
]

#########################################################################
### add IPs
puts "                        Generating process_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name process_fifo >> $logfile
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {88} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {88} CONFIG.Output_Depth {512} CONFIG.Use_Embedded_Registers {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {510} CONFIG.Full_Threshold_Negate_Value {509} ] [get_ips process_fifo]

puts "                        Generating completion_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name completion_fifo >> $logfile
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {41} CONFIG.Input_Depth {16} CONFIG.Output_Data_Width {41} CONFIG.Output_Depth {16} CONFIG.Use_Embedded_Registers {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {5} CONFIG.Write_Data_Count_Width {5} CONFIG.Read_Data_Count_Width {5} CONFIG.Full_Threshold_Assert_Value {14} CONFIG.Full_Threshold_Negate_Value {13} ] [get_ips completion_fifo]

puts "                        Generating descriptor_fifo ......"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name descriptor_fifo >> $logfile
set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {1024} CONFIG.Input_Depth {32} CONFIG.Output_Data_Width {1024} CONFIG.Output_Depth {32} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {6} CONFIG.Write_Data_Count_Width {6} CONFIG.Read_Data_Count_Width {6} CONFIG.Full_Threshold_Assert_Value {30} CONFIG.Full_Threshold_Negate_Value {29}] [get_ips descriptor_fifo]

puts "                        Generating addr_ram ......"
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name addr_ram >> $logfile
set_property -dict [list CONFIG.depth {512} CONFIG.data_width {32} CONFIG.memory_type {simple_dual_port_ram}] [get_ips addr_ram]

############################################################################
#Add source files
puts "                Adding design sources to job_manager project"
set obj [get_filesets sources_1]
set files [list {*}$verilog_job_manager ]
add_files -norecurse -fileset $obj $files

