############################################################################
############################################################################
##
## Copyright 2016-2020 International Business Machines
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

set root_dir          $::env(SNAP_HARDWARE_ROOT)
set logs_dir          $::env(LOGS_DIR)
set logfile           $logs_dir/snap_cloud_build.log
set fpgacard          $::env(FPGACARD)
set action_root       $::env(ACTION_ROOT)
set action_name       [exec basename $action_root]
set sdram_used        $::env(SDRAM_USED)
set nvme_used         $::env(NVME_USED)
set bram_used         $::env(BRAM_USED)
set pr_run            $::env(PR_RUN)
set vivadoVer         [version -short]

#Checkpoint directory
if { [info exists ::env(DCP_ROOT)] == 1 } {
    set dcp_dir $::env(DCP_ROOT)
} else {
    puts "                        Error: For cloud builds the environment variable DCP_ROOT needs to point to a path for input and output design checkpoints."
    exit 42
}
set ::env(DCP_DIR) $dcp_dir

#Checkpoint file => input files
set oc_fpga_static_synth         "oc_${fpgacard}_static_synth"
set oc_fpga_static_synth_dcp     "${oc_fpga_static_synth}.dcp"
set oc_action_name_synth_dcp  "oc_${fpgacard}_${action_name}_synth.dcp"
#Checkpoint file => output files
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"
set oc_fpga_static_routed_dcp "oc_${fpgacard}_static_routed.dcp"

#Report directory
set rpt_dir        $root_dir/build/Reports
set ::env(RPT_DIR) $rpt_dir

#Image directory
set img_dir $root_dir/build/Images
set ::env(IMG_DIR) $img_dir

#Remove temp files
set ::env(REMOVE_TMP_FILES) TRUE

if { [info exists ::env(PR_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(PR_BUILD_BITFILE)]
} else {
  set cloud_build_bitfile "FALSE"
}

#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22
set ::env(WIDTHCOL1) $widthCol1
set ::env(WIDTHCOL2) $widthCol2
set ::env(WIDTHCOL3) $widthCol3
set ::env(WIDTHCOL4) $widthCol4


#DEBUG
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "DCP directory is $dcp_dir" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

##
## open oc-accel project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "opening $oc_fpga_static_synth_dcp" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_checkpoint  $dcp_dir/$oc_fpga_static_synth_dcp  >> $logfile


# Disable EMCCLK for startup primitive
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [get_designs checkpoint_$oc_fpga_static_synth]
set_property BITSTREAM.CONFIG.CONFIGRATE 51.0 [get_designs checkpoint_$oc_fpga_static_synth]

if { $fpgacard == "AD9H7" } {
   set_property HD.RECONFIGURABLE true [get_cells oc_func0/fw_afu/action_core_i]

   puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "opening $dcp_dir/${oc_action_name_synth_dcp}" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
   read_checkpoint -cell [get_cells oc_func0/fw_afu/action_core_i] $dcp_dir/${oc_action_name_synth_dcp}

   create_pblock hls_action_0_pblock_1
   add_cells_to_pblock [get_pblocks hls_action_0_pblock_1] [get_cells [list oc_func0/fw_afu/action_core_i]]
   resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X4Y4:CLOCKREGION_X7Y11
   resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X0Y6:CLOCKREGION_X3Y11
   resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X5Y0:CLOCKREGION_X6Y3
#HBM in dynamic area
   #resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X0Y0:CLOCKREGION_X7Y0
#HBM in static area
   resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X5Y0:CLOCKREGION_X7Y0

} elseif { $fpgacard == "AD9V3" } {
   set_property HD.RECONFIGURABLE true [get_cells oc_func/fw_afu/action_core_i]

   puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "opening $dcp_dir/${oc_action_name_synth_dcp}" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
   read_checkpoint -cell [get_cells oc_func/fw_afu/action_core_i] $dcp_dir/${oc_action_name_synth_dcp}

   create_pblock hls_action_0_pblock_1
   add_cells_to_pblock [get_pblocks hls_action_0_pblock_1] [get_cells [list oc_func/fw_afu/action_core_i]]
   resize_pblock [get_pblocks hls_action_0_pblock_1] -add CLOCKREGION_X0Y2:CLOCKREGION_X5Y4
}

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "opt design ..." $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
opt_design -directive Explore
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "place design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
place_design -directive Explore
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "phys opt design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
phys_opt_design -directive Explore
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "route design " $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

route_design -directive Explore
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Writing $dcp_dir/${oc_action_name_routed_dcp}" $widthCol4 "" ]
write_checkpoint -force $dcp_dir/${oc_action_name_routed_dcp}


puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Removing reference action from complete routed chip" $widthCol4 "" ]
if { $fpgacard == "AD9H7" } {
   update_design -cell [get_cells oc_func0/fw_afu/action_core_i] -black_box
} else {
   update_design -cell [get_cells oc_func/fw_afu/action_core_i] -black_box
}
lock_design -level routing

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Writing $dcp_dir/${oc_fpga_static_routed_dcp}" $widthCol4 "" ]
write_checkpoint -force $dcp_dir/$oc_fpga_static_routed_dcp

close_project  >> $logfile

