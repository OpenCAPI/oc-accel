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

set tcl_dir             $root_dir/setup/package_ocaccel_ips
source $root_dir/setup/common_funcs.tcl
source $root_dir/setup/define_interfaces.tcl


#set ip_list [ dict create  \
#        bridge_axi_slave     "$tcl_dir/add_bridge_axi_slave.tcl" \
#        data_bridge          "$tcl_dir/add_data_bridge.tcl" \
#        mmio_axilite_master  "$tcl_dir/add_mmio_axilite_master.tcl" \
#        opencapi30_c1        "$tcl_dir/add_opencapi30_c1.tcl" \
#        opencapi30_mmio      "$tcl_dir/add_opencapi30_mmio.tcl" \
#        opencapi30_host_if   "$tcl_dir/add_opencapi30_host_if.tcl" \
#        flash_vpd_wrapper    "$fpga_card_dir/tcl/add_flash_vpd_wrapper.tcl" \
#        ]
#
#foreach ip_name [dict keys $ip_list ] {
#    set tcl_file [dict get $ip_list $ip_name]
#    my_package_custom_ip $root_dir/temp_projs \
#                         $root_dir/ip_repo    \
#                         $root_dir/interfaces \
#                         $fpga_part           \
#                         $ip_name             \
#                         $tcl_file            
#}



##proc my_package_custom_ip {proj_path ip_path if_path fpga_part ip_name addfile_script bus_array} {
#############################################################################
set bus_array [dict create tlx_afu "master" \
                          afu_tlx "slave"   \
                          cfg_flsh "master" \
                          cfg_vpd "master"  \
                          cfg_infra_c1 "master"  \
                          oc_phy  ""        \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     oc_host_if           \
                     $tcl_dir/add_opencapi30_host_if.tcl      \
                     $bus_array

############################################################################
set bus_array [dict create dma_wr "master"   \
                           dma_rd "master"   \
                           lcl_wr "slave"    \
                           lcl_rd "slave"    \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     data_bridge    \
                     $tcl_dir/add_data_bridge.tcl      \
                     $bus_array
############################################################################
set bus_array [dict create                   \
                           lcl_wr "master"    \
                           lcl_rd "master"    \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     bridge_axi_slave    \
                     $tcl_dir/add_bridge_axi_slave.tcl      \
                     $bus_array

#############################################################################
set bus_array [dict create mmio "slave"   \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     mmio_axilite_master    \
                     $tcl_dir/add_mmio_axilite_master.tcl      \
                     $bus_array

##############################################################################
set bus_array [dict create tlx_afu "slave"   \
                           mmio "master"     \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     opencapi30_mmio    \
                     $tcl_dir/add_opencapi30_mmio.tcl      \
                     $bus_array

############################################################################
set bus_array [dict create afu_tlx "master"   \
                           dma_wr "slave"     \
                           dma_rd "slave"     \
                           cfg_infra_c1 "slave"     \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     opencapi30_c1    \
                     $tcl_dir/add_opencapi30_c1.tcl      \
                     $bus_array

############################################################################
set bus_array [dict create cfg_flsh "slave"   \
                           cfg_vpd "slave"     \
             ]
my_package_custom_ip $root_dir/temp_projs \
                     $root_dir/ip_repo    \
                     $root_dir/interfaces \
                     $fpga_part           \
                     flash_vpd_wrapper    \
                     $fpga_card_dir/tcl/add_flash_vpd_wrapper.tcl      \
                     $bus_array

