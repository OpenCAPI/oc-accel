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
set action_root       $::env(ACTION_ROOT)
set action_name       [exec basename $action_root]
set fpgacard          $::env(FPGACARD)
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

#Checkpoint file
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"

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
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "opening $dcp_dir/$oc_action_name_routed_dcp" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_checkpoint  $dcp_dir/$oc_action_name_routed_dcp  >> $logfile
write_bitstream -force -bin_file $img_dir/${action_name}
# write_bitstream -force $img_dir/{action_name}
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property CONFIG_MODE SPIx8 [current_design
]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Generating  $img_dir/oc_${action_name}.bin" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
write_cfgmem -force -format BIN -interface SPIx8 -size 256 -loadbit "up 0 $img_dir/${action_name}.bit" $img_dir/${action_name}

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Closing project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

#exec rm -rf $img_dir/.bit
exec rm -rf $img_dir/\*_partial.bin
exec rm -rf $img_dir/${action_name}.bin

close_project  >> $logfile

