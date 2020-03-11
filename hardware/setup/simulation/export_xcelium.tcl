#-----------------------------------------------------------
#
# Copyright 2016-2018, International Business Machines
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
#-----------------------------------------------------------

set vivadoVer    [version -short]
set sim_top       [lindex $argv 0]
set root_dir     $::env(OCACCEL_HARDWARE_ROOT)
set ies_libs     $::env(IES_LIBS)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/compile_$::env(SIMULATOR).log

puts "                        export simulation for version=$vivadoVer"
open_project $root_dir/build/top_project/top_project.xpr  >> $log_file
puts "                        setting simulation top to $sim_top"
set_property top $sim_top [get_filesets sim_1]
puts "                        generating simulation target"
generate_target Simulation [get_files $root_dir/build/top_project/top_project.srcs/sources_1/bd/top/top.bd] >> $log_file
puts "                        export ip user files"
export_ip_user_files -of_objects [get_files $root_dir/build/top_project/top_project.srcs/sources_1/bd/top/top.bd] -no_script -sync -force -quiet >> $log_file
puts "                        export simulations"
export_simulation -force -directory "$root_dir/sim" -simulator xcelium -lib_map_path "$ies_libs" -ip_user_files_dir "$root_dir/build/top_project/top_project.ip_user_files" -ipstatic_source_dir "$root_dir/build/top_project/top_project.ip_user_files/ipstatic" -use_ip_compiled_libs >> $log_file
close_project  >> $log_file
