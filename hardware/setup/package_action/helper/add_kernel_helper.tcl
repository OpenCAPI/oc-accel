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
set src_dir          $hardware_dir/hdl/action_wrapper

set verilog_kernel_helper [list \
 $src_dir/kernel_helper_A10.v \
]

############################################################################
#Add source files
puts "                Adding design sources to kernel_helper project"
set obj [get_filesets sources_1]
set files [list {*}$verilog_kernel_helper ]
add_files -norecurse -fileset $obj $files
puts "                kernel_helper IP added"

