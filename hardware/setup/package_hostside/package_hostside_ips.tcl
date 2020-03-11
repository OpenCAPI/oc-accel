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

set hardware_dir        $::env(OCACCEL_HARDWARE_ROOT)
set simulator           $::env(SIMULATOR)
set fpga_card_dir       $hardware_dir/oc-accel-bsp/$fpga_card

set tcl_dir             $hardware_dir/setup/package_hostside
source $hardware_dir/setup/common/common_funcs.tcl


#------------------------------------------------------------------------------
proc package_ip {proj_path ip_path if_path fpga_part ip_name addfile_script bus_array} {

   puts "    <<< Package customer design $ip_name to $ip_path"
   set vendor "opencapi.org"
   set lib "ocaccel"
   set ver "1.0"
   set project viv_${ip_name}
   set project_dir $proj_path/$project
   create_project $project $project_dir -part $fpga_part -force

   # Set 'sources_1' fileset object, create list of all nececessary verilog files
   set obj [get_filesets sources_1]
   
   
   # Add source files and import
   source $addfile_script

   #------------------------------------------------------------------------------
   # Add interface path to allow auto-infering
   set_property ip_repo_paths  $if_path [current_project]
   update_ip_catalog -rebuild -scan_changes
   # Start to package this project as an IP
   ipx::package_project -root $ip_path/$ip_name -import_files -force -vendor $vendor -library $lib -taxonomy /UserIP

   if { $simulator != "nosim" } {
       ipx::add_file src/${ip_name}.sv [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]

       # Remove IPs from simulation
       if {$ip_name == "oc_host_if" } {
           ipx::remove_file src/vio_reset_n/vio_reset_n.xci [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
           ipx::remove_file src/DLx_phy/DLx_phy.xci [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
           ipx::remove_file src/DLx_phy_vio_0/DLx_phy_vio_0.xci [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
       }

       if {$ip_name == "flash_vpd_wrapper"} {
           ipx::remove_file src/axi_quad_spi_0/axi_quad_spi_0.xci [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
           ipx::remove_file src/axi_hwicap_0/axi_hwicap_0.xci [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
       }
   }

   foreach bus [dict keys $bus_array] {
       set mode [dict get $bus_array $bus]
       ipx::infer_bus_interfaces $vendor:$lib:${bus}_rtl:$ver [ipx::current_core]
       if { $mode ne "" } {
           set_property interface_mode $mode [ipx::get_bus_interfaces ${lib}_${bus} -of_objects [ipx::current_core]]
       }
   }
   ipx::create_xgui_files [ipx::current_core]
   ipx::update_checksums [ipx::current_core]
   ipx::save_core [ipx::current_core]

   close_project
}

##proc my_package_custom_ip {proj_path ip_path if_path fpga_part ip_name addfile_script bus_array} {
#############################################################################
set bus_array [dict create tlx_afu "master" \
                          afu_tlx "slave"   \
                          cfg_flsh "master" \
                          cfg_vpd "master"  \
                          cfg_infra_c1 "master"  \
                          oc_phy  ""        \
             ]
package_ip $hardware_dir/build/temp_projs \
           $hardware_dir/build/ip_repo    \
           $hardware_dir/build/interfaces \
           $fpga_part           \
           oc_host_if           \
           $tcl_dir/add_opencapi30_host_if.tcl      \
           $bus_array

############################################################################
set bus_array [dict create cfg_flsh "slave"   \
                           cfg_vpd "slave"     \
             ]
package_ip $hardware_dir/build/temp_projs \
           $hardware_dir/build/ip_repo    \
           $hardware_dir/build/interfaces \
           $fpga_part           \
           flash_vpd_wrapper    \
           $fpga_card_dir/tcl/add_flash_vpd_wrapper.tcl      \
           $bus_array

