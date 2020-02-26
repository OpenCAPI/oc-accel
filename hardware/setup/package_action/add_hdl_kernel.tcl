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
set capi_ver            $::env(CAPI_VER)
set fpga_card           $::env(FPGACARD)
set fpga_part           $::env(FPGACHIP)

set hardware_dir        $::env(OCACCEL_HARDWARE_ROOT)
set fpga_card_dir       $hardware_dir/oc-accel-bsp/$fpga_card
set common_dir          $hardware_dir/hdl/common
set hls_support         $::env(HLS_SUPPORT)
set action_hw_dir       $::env(ACTION_ROOT)/hw


############################################################################
# Here is the suggested directory structure for a user design
# 
# 'hdl': Verilog/VHDL source files, allowing sub-directories
# 'tcl': Tcl files will be sourced
# 'xdc': Constraint files will be added
# 'ip': xci files will be added

set action_hdl_dir       $action_hw_dir/hdl
set action_tcl_dir       $action_hw_dir/tcl
set action_xdc_dir       $action_hw_dir/xdc
set action_ip_dir        $action_hw_dir/ip

if { $hls_support == "TRUE" } {
    puts "This tcl is only used for HDL action. Exit"
    exit
}
############################################################################
#Add source files
puts "                Adding design sources to hdl_kernel project"
set obj [get_filesets sources_1]


add_files -scan_for_includes -fileset $obj $action_hdl_dir

### Assign Header file here
#set file "ocaccel_global_vars.v"
#set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
#set_property -name "file_type" -value "Verilog Header" -objects $file_obj

############################################################################
#Add xci (IP) files
if { [file exists $action_ip_dir] == 1 } {
  set ip_list [exec find $action_ip_dir -name *.xci]
  if { $ip_list != ""} {
    foreach ip_xci $ip_list {
        set ip_name [exec basename $ip_xci .xci]
        puts "                        importing IP $ip_name into hdl_kernel"
        add_files -norecurse $ip_xci -force
        #export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force
    }
  }
}

############################################################################
#Add xdc (Constraints) files
if { [file exists $action_xdc_dir] == 1 } {
  set xdc_list [exec find $action_xdc_dir -name *.xdc]
  if { $xdc_list != ""} {
    foreach xdc_file $xdc_list {
        set xdc_name [exec basename $xdc_file .xdc]
        puts "                        importing xdc $xdc_name into action_wrapper"
        add_files -norecurse $xdc_file -force
    }
  }
}
############################################################################
#Add Use Tcl files
if { [file exists $action_tcl_dir] == 1 } {
  set tcl_list [exec find $action_tcl_dir -name *.tcl]
  if { $tcl_list != ""} {
    foreach tcl_file $tcl_list {
        set tcl_name [exec basename $tcl_file .tcl]
        puts "                        source tcl file $tcl_name"
        source $tcl_file
    }
  }
}


