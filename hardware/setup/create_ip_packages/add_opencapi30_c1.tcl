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

set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set src_dir          $root_dir/hdl/infrastructure/opencapi30_c1
set common_dir       $root_dir/hdl/common

set verilog_opencapi30_c1 [list \
 $common_dir/fifo_async.v    \
 $common_dir/fifo_sync.v    \
 $common_dir/ram_simple_dual.v    \
 $common_dir/ram_true_dual.v    \
 $src_dir/command_encode.v \
 $src_dir/context_surveil.v \
 $src_dir/interrupt_tlx.v \
 $src_dir/partial_sequencer.v \
 $src_dir/response_decode.v \
 $src_dir/retry_queue.v \
 $src_dir/tlx_cmd_converter.v \
 $src_dir/tlx_rsp_converter.v \
 $src_dir/opencapi30_c1.v \

]



############################################################################
#Add source files
puts "	                Adding design sources to opencapi30_c1 project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]
set files [list {*}$verilog_opencapi30_c1 ]
add_files -norecurse -fileset $obj $files


#set file "snap_global_vars.v"
#set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
#set_property -name "file_type" -value "Verilog Header" -objects $file_obj


