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
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

set capi_ver            $::env(CAPI_VER)
set fpga_card           $::env(FPGACARD)
set fpga_part           $::env(FPGACHIP)

set root_dir            $::env(OCACCEL_HARDWARE_ROOT)
set fpga_card_dir       $root_dir/oc-accel-bsp/$fpga_card

set tcl_dir             $root_dir/setup/package_action
source $root_dir/setup/common/common_funcs.tcl
#source $tcl_dir/define_build/interfaces/g.tcl

set bus_array ""
my_package_custom_ip $root_dir/build/temp_projs \
                     $root_dir/build/ip_repo    \
                     $root_dir/build/interfaces \
                     $fpga_part           \
                     action_wrapper           \
                     $tcl_dir/add_action_wrapper.tcl      \
                     $bus_array

