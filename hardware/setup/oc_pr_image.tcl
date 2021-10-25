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

#Looking for PRxxxx occurrence in static_routed.dcp filename
#WARNING - dealing with only 1 filename per card
set prefix  "oc_${fpgacard}_PR"
set pr_file_name [exec basename [ exec find $dcp_dir/ -name ${prefix}*_static_routed.dcp ]]
if { $pr_file_name != "" } {
   #looking for 3 digits after PR
   set pattern {PR([0-9a-f]{3})}
   set PRC3 [regexp -all $pattern $pr_file_name PRC]
   #puts $PRC
} else {
   puts "-------------------------------------------------------------------------------------"
   puts "ERROR: File $${prefix}*_static_routed.dcp not found in $dcp_dir!"
   puts "  Please generate 'make oc_pr_route_action' or 'make oc_pr_route_static' before running 'make oc_pr_image'."
   puts "-------------------------------------------------------------------------------------"
   exit 42
}


#Checkpoint file => input file
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"

#Define widths of each column
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

##
## generating bitstream name
set IMAGE_NAME [exec cat $root_dir/.bitstream_name.txt]

# append PRC
append IMAGE_NAME "_" ${PRC}

# append phy_speed
append IMAGE_NAME [expr {$::env(PHY_SPEED) == "20.0" ? "_20G" : "_25G"}]

# append action name 
set ACTION_NAME [lrange [file split $action_root] end end]
append IMAGE_NAME [format {_%s} $ACTION_NAME]

# append ram_type and timing information
if { $bram_used == "TRUE" } {
  set RAM_TYPE "_BRAM"
} elseif { $sdram_used == "TRUE" } {
  set RAM_TYPE "_SDRAM"
} elseif { $hbm_used == "TRUE" } {
  set RAM_TYPE "_HBM"
} else {
  set RAM_TYPE ""
}
if { [info exists ::env(TIMING_WNS)] == 1 } {
  append IMAGE_NAME [format {%s_OC-%s_%s} $RAM_TYPE $fpgacard $::env(TIMING_WNS)]
} else {
  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     Timing WNS not found"]
  append IMAGE_NAME [format {%s_OC-%s} $RAM_TYPE $fpgacard]
}

##
## open oc-accel project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start generating images files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T}]"]
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

#Remove unncessary files which will not be used
exec rm -rf $img_dir/${IMAGE_NAME}.bin
#partial.bin is used for PR with oc-flash-script
exec mv $img_dir/${IMAGE_NAME}_pblock_dynamic_PR_partial.bin $img_dir/${IMAGE_NAME}_partial.bin

#partial.bit is used for PR with jtag only
exec mv $img_dir/${IMAGE_NAME}_pblock_dynamic_PR_partial.bit $img_dir/${IMAGE_NAME}_partial.bit
exec rm -f $img_dir/${IMAGE_NAME}_partial.bit

close_project  >> $logfile

