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

set root_dir      $::env(SNAP_HARDWARE_ROOT)
set logs_dir      $::env(LOGS_DIR)
set img_dir       $::env(IMG_DIR)
set dcp_dir       $::env(DCP_DIR)
set rpt_dir       $::env(RPT_DIR)

set action_root   $::env(ACTION_ROOT)
set action_name   [exec basename $action_root]
set fpgacard      $::env(FPGACARD)
set sdram_used    $::env(SDRAM_USED)
set bram_used     $::env(BRAM_USED)
set hbm_used      $::env(HBM_USED)


set flash_interface $::env(FLASH_INTERFACE)
set flash_size      $::env(FLASH_SIZE)

#Checkpoint file => input file
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"
#Image file => output file
set oc_action_name_image "oc_pr_${fpgacard}_${action_name}"

#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22
set ::env(WIDTHCOL1) $widthCol1
set ::env(WIDTHCOL2) $widthCol2
set ::env(WIDTHCOL3) $widthCol3
set ::env(WIDTHCOL4) $widthCol4

##
## generating bitstream name
set IMAGE_NAME [exec cat $root_dir/.bitstream_name.txt]

# append phy_speed
append IMAGE_NAME [expr {$::env(PHY_SPEED) == "20.0" ? "_20G" : "_25G"}]

# append action name 
set ACTION_NAME [lrange [file split $action_root] end end]
append IMAGE_NAME [format {_%s} $ACTION_NAME]

# append ram_type and timing information
if { $bram_used == "TRUE" } {
  set RAM_TYPE BRAM
} elseif { $sdram_used == "TRUE" } {
  set RAM_TYPE SDRAM
} elseif { $hbm_used == "TRUE" } {
  set RAM_TYPE HBM
} else {
  set RAM_TYPE noSDRAM
}
if { [info exists ::env(TIMING_WNS)] == 1 } {
  append IMAGE_NAME [format {_%s_PR_OC-%s_%s} $RAM_TYPE $fpgacard $::env(TIMING_WNS)]
} else {
  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     Timing WNS not found"]
  append IMAGE_NAME [format {_%s_PR_OC-%s} $RAM_TYPE $fpgacard]
}

##
## open oc-accel project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start generating images files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening $oc_action_name_routed_dcp"]
open_checkpoint  $dcp_dir/$oc_action_name_routed_dcp  >> $logfile

## writing bitstream
set step     write_bitstream
set logfile  $logs_dir/${step}.log
set command "write_bitstream -force -bin_file $img_dir/${IMAGE_NAME}"

puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     generating .bin, .bit and partial.bit files"]
if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" ]
  puts [format "%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" ]
  exit 42
} else {

  # generates from the bit file the primary.bin and secondary.bin
  #set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
  #set_property CONFIG_MODE SPIx8 [current_design]

  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     converting the bin file into the card flash format"]
  write_cfgmem -force -format bin -size $flash_size -interface  $flash_interface -loadbit "up 0 $img_dir/${IMAGE_NAME}.bit" $img_dir/${IMAGE_NAME} >> $logfile
}

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     closing project" $widthCol3 "" $widthCol4 ""]

#Remove unncessary files which will not been used
#exec rm -rf $img_dir/${oc_action_name_image}.bin
exec mv $img_dir/${IMAGE_NAME}_pblock_dynamic_PR_partial.bit $img_dir/${IMAGE_NAME}_partial.bit
exec mv $img_dir/${IMAGE_NAME}_pblock_dynamic_PR_partial.bin $img_dir/${IMAGE_NAME}_partial.bin
#exec rm -rf $img_dir/${IMAGE_NAME}_pblock_dynamic_PR_partial.bin
#keep a copy of the generated partial bit files in DCP
exec cp $img_dir/${IMAGE_NAME}_partial.bit $dcp_dir/.
exec cp $img_dir/${IMAGE_NAME}_partial.bin $dcp_dir/.

close_project  >> $logfile

