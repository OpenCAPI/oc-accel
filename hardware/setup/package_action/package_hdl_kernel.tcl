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

# This is script is used for HDL User Design. It helps packaging the kernel into an IP
set kernel_name         $::env(KERNEL_NAME)
set capi_ver            $::env(CAPI_VER)
set fpga_card           $::env(FPGACARD)
set fpga_part           $::env(FPGACHIP)

set hardware_dir        $::env(OCACCEL_HARDWARE_ROOT)
set fpga_card_dir       $hardware_dir/oc-accel-bsp/$fpga_card

set tcl_dir             $hardware_dir/setup/package_action
source $hardware_dir/setup/common/common_funcs.tcl

set bus_array ""
my_package_custom_ip $hardware_dir/build/temp_projs      \
                     $hardware_dir/build/ip_repo         \
                     $hardware_dir/build/interfaces      \
                     $fpga_part                          \
                     $kernel_name                        \
                     $tcl_dir/add_hdl_kernel.tcl         \
                     $bus_array
#ipx::associate_bus_interfaces -busif m_axi_host_mem -clock ap_clk [ipx::current_core]
#ipx::associate_bus_interfaces -busif s_axi_ctrl_reg -clock ap_clk [ipx::current_core]
