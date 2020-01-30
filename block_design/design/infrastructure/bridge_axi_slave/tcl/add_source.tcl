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

set root_dir         $::env(OCACCEL_BD_ROOT)
set src_dir          $root_dir/design/infrastructure/bridge_axi_slave/verilog
set common_dir       $root_dir/design/common/verilog

set verilog_bridge_axi_slave [list \
 $common_dir/fifo_sync.v    \
 $src_dir/axi_slave_cmd_fifo.v    \
 $src_dir/bridge_axi_slave.v    \
]



############################################################################
#Add source files
puts "	                Adding design sources to bridge_axi_slave project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]
set files [list {*}$verilog_bridge_axi_slave ]
add_files -norecurse -fileset $obj $files


#set file "snap_global_vars.v"
#set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
#set_property -name "file_type" -value "Verilog Header" -objects $file_obj
#

