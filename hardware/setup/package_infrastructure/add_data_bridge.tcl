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

set hardware_dir     $::env(OCACCEL_HARDWARE_ROOT)
set src_dir          $hardware_dir/hdl/infrastructure/data_bridge
set common_dir       $hardware_dir/hdl/common

set verilog_data_bridge [list \
 $common_dir/fifo_sync.v    \
 $common_dir/ram_simple_dual.v    \
 $src_dir/rd_order_mng_array.v    \
 $src_dir/wr_order_mng_array.v    \
 $src_dir/data_bridge_channel.v    \
 $src_dir/data_bridge.v    \
]



############################################################################
#Add source files
puts "	                Adding design sources to data_bridge project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]
set files [list {*}$verilog_data_bridge ]
add_files -norecurse -fileset $obj $files


#set file "ocaccel_global_vars.v"
#set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
#set_property -name "file_type" -value "Verilog Header" -objects $file_obj


