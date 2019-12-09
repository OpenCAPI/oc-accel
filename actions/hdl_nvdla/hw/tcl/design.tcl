#
# Copyright 2019 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and 
# limitations under the License.
#
set engine_dir $action_dir/hw/engines
set framework_dir $action_dir/hw/framework

# Add vlib files
add_files -scan_for_includes $engine_dir/vlibs/RANDFUNC.vlib -verbose
add_files -scan_for_includes $engine_dir/vlibs/nv_assert_no_x.vlib -verbose
#set_property file_type {SystemVerilog} [get_files  $action_dir/hw/engines/*.v]
set_property file_type {SystemVerilog} [get_files *.vlib]
set_property file_type {SystemVerilog} [get_files $engine_dir/vlibs/NV_DW_lsd.v]
#set_property file_type SystemVerilog [get_files $engine_dir/vlibs/RANDFUNC.vlib]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include.vh]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_syn.vh]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_sim.vh]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $engine_dir/defs/project.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_syn.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_sim.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $engine_dir/defs/project.vh]

set_property used_in_synthesis true [get_files -of_objects [get_filesets sources_1]  $framework_dir/global_include.vh]
set_property used_in_synthesis true [get_files -of_objects [get_filesets sources_1]  $framework_dir/global_include_syn.vh]
set_property used_in_synthesis false [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_sim.vh]
#
set_property used_in_implementation false [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_sim.vh]
#
set_property used_in_simulation true [get_files -of_objects [get_filesets sources_1]  $framework_dir/global_include.vh]
set_property used_in_simulation false [get_files -of_objects [get_filesets sources_1] $framework_dir/global_include_syn.vh]
set_property used_in_simulation true [get_files -of_objects [get_filesets sources_1]  $framework_dir/global_include_sim.vh]

## Use fifo in fifo directory
#foreach fifo_file [glob -nocomplain -dir $engine_dir/fifos *.v] {
#    set fifo_file_name [exec basename $fifo_file]
#
#    foreach tmp_file [get_files $fifo_file_name] {
#        set dir_name [exec dirname $tmp_file]
#        if {$dir_name != "$engine_dir/fifos"} {
#            puts "                        NOT from fifo directory: $tmp_file"
#            remove_files $tmp_file
#        }
#    }
#}

#set action_engine_ipdir $::env(ACTION_ROOT)/ip/engines/fpga_ip

##User IPs
#foreach usr_ip [glob -nocomplain -dir $action_engine_ipdir *] {
#    foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
#        set ip_name [file rootname [file tail $usr_ip_xci]]
#        puts "                        importing user IP $ip_name (in nvdla)"
#        add_files -norecurse $usr_ip_xci >> $log_file
#        set_property generate_synth_checkpoint false [ get_files $usr_ip_xci] >> $log_file
#        generate_target {instantiation_template}     [ get_files $usr_ip_xci] >> $log_file
#        generate_target all                          [ get_files $usr_ip_xci] >> $log_file
#        export_ip_user_files -of_objects             [ get_files $usr_ip_xci] -no_script -sync -force -quiet >> $log_file
#    }
#}

puts "                        importing set_max_fanout XDCs"
add_files -fileset constrs_1 -norecurse $engine_dir/../tcl/set_max_fanout.xdc >> $log_file
set_property used_in_synthesis true [get_files $engine_dir/../tcl/set_max_fanout.xdc]
set_property used_in_implementation true [get_files $engine_dir/../tcl/set_max_fanout.xdc]

set action_ip_dir $::env(ACTION_ROOT)/ip

# Framework and nvdla IP
foreach ip_xci [exec find $action_ip_dir -name *.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        importing IP $ip_name (in framework)"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}

#set_property verilog_define {FPGA=1 SYNTHESIS=1 DESIGNWARE_NOEXIST=1 VLIB_BYPASS_POWER_CG=1 NV_FPGA_SYSTEM=1 NV_FPGA_UNIT=1} [current_fileset]
#set_property verilog_define {XSDB_SLV_DIS=1 NV_FPGA_FIFOGEN=1 NV_LARGE=1} [current_fileset]

if { $::env(NVDLA_CONFIG) == "nv_large" } {
    remove_files $engine_dir/nvdla/cdp/NV_NVDLA_CDP_DP_bufferin_tp1.v
    #remove_files $engine_dir/nvdla/cdp/NV_NVDLA_CVIF_WRITE_IG_arb.v
}

