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
set action_name       [string tolower $::env(ACTION_NAME)]
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

#Checkpoint file => input file
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"
#Image file => output file
set oc_action_name_image "oc_pr_${fpgacard}_${action_name}"

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
# generates from the dcp file the bin + bit + partial.bon + partial.bit
write_bitstream -force -bin_file $img_dir/$oc_action_name_image

# generates from the bit file the primary.bin and secondary.bin
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property CONFIG_MODE SPIx8 [current_design]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Generating  $img_dir/${oc_action_name_image}.bin" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
write_cfgmem -force -format BIN -interface SPIx8 -size 256 -loadbit "up 0 $img_dir/${oc_action_name_image}.bit" $img_dir/${oc_action_name_image}

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Closing project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

exec rm -rf $img_dir/${oc_action_name_image}.bin
exec mv $img_dir/${oc_action_name_image}_hls_action_0_pblock_1_partial.bit $img_dir/${oc_action_name_image}_partial.bit
exec rm -rf $img_dir/${oc_action_name_image}_hls_action_0_pblock_1_partial.bin

close_project  >> $logfile

