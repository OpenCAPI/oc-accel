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

set root_dir            $::env(OCACCEL_HARDWARE_ROOT)
set fpga_card_dir       $root_dir/oc-accel-bsp/$fpga_card
set common_dir          $root_dir/hdl/common

set action_hw_dir       $::env(ACTION_ROOT)/hw

set action_hdl_dir       $action_hw_dir/hdl
set action_tcl_dir       $action_hw_dir/tcl
set action_xdc_dir       $action_hw_dir/xdc
set action_ip_dir        $action_hw_dir/ip

############################################################################
#Add source files
puts "                Adding design sources to action_wrapper project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]


#set hdl_source [list \
# $common_dir/fifo_sync.v    \
# $common_dir/ram_simple_dual.v    \
# $src_dir/rd_order_mng_array.v    \
# $src_dir/wr_order_mng_array.v    \
# $src_dir/data_bridge_channel.v    \
# $src_dir/data_bridge.v    \
#]

#set files [list {*}$hdl_source ]

add_files -scan_for_includes -fileset $obj $action_hdl_dir

#set file "snap_global_vars.v"
#set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
#set_property -name "file_type" -value "Verilog Header" -objects $file_obj

############################################################################
#Add xci (IP) files
if { [file exists $action_ip_dir] == 1 } {
  set ip_list [exec find $action_ip_dir -name *.xci]
  if { $ip_list != ""} {
    foreach ip_xci $ip_list {
        set ip_name [exec basename $ip_xci .xci]
        puts "                        importing IP $ip_name into action_wrapper"
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


