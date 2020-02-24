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
set src_dir          $root_dir/hdl/infrastructure/axi_lite_adaptor

set verilog_axilite_adaptor [list \
 $src_dir/axi_lite_adaptor.v \
]

############################################################################
#Add source files
puts "	                Adding design sources to job_manager project"
set obj [get_filesets sources_1]
set files [list {*}$verilog_axilite_adaptor ]
add_files -norecurse -fileset $obj $files

