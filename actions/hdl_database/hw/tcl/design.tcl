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
set action_hw $::env(ACTION_ROOT)/hw
set action_ip_dir $::env(ACTION_ROOT)/ip
set regex_verilog_dir  $::env(ACTION_ROOT)/hw/engines/regex/
set regex_ipdir $::env(ACTION_ROOT)/ip/engines/regex/

add_files -scan_for_includes -norecurse $action_hw/framework
add_files -scan_for_includes -norecurse $regex_verilog_dir/snap_adapter
add_files -scan_for_includes -norecurse $regex_verilog_dir/core

#User IPs
foreach usr_ip [list \
                $regex_ipdir/bram_1744x16                   \
                $regex_ipdir/bram_dual_port_64x512          \
                $regex_ipdir/fifo_48x16_async               \
                $regex_ipdir/fifo_512x64_sync_bram          \
                $regex_ipdir/fifo_80x16_async               \
                $regex_ipdir/unit_fifo_48x16_async          \
                $regex_ipdir/fifo_sync_32_512i512o          \
                $regex_ipdir/fifo_sync_32_5i5o              \
                $regex_ipdir/ram_512i_512o_dual_64          \
                $regex_ipdir/axi_register_slice_0           \
                $regex_ipdir/axi_lite_register_slice_0      \
               ] {
  foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
    set ip_name [exec basename $usr_ip_xci .xci]
    puts "                        importing IP $ip_name (in regex core)"
    add_files -norecurse $usr_ip_xci >> $log_file
    set_property generate_synth_checkpoint false  [ get_files $usr_ip_xci] >> $log_file
    generate_target {instantiation_template}      [ get_files $usr_ip_xci] >> $log_file
    generate_target all                           [ get_files $usr_ip_xci] >> $log_file
    export_ip_user_files -of_objects              [ get_files $usr_ip_xci] -no_script -sync -force -quiet >> $log_file
  }
}

# Set the action_string_match.v file to systemverilog mode for $clog2()
# support
set_property file_type SystemVerilog [get_files string_match_core_top.v]

# Framework and Regex IP
foreach ip_xci [exec find $action_ip_dir -name *.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        importing IP $ip_name (in framework)"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}

