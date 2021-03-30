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
set root_dir        $::env(SNAP_HARDWARE_ROOT)
set logs_dir        $::env(LOGS_DIR)

if { [info exists ::env(DCP_ROOT)] == 1 } {
    set dcp_dir $::env(DCP_ROOT)
} else {
    puts "                        Error: For cloud builds the environment variable DCP_ROOT needs to point to a path for input and output design checkpoints."
    exit 42
}
set ::env(DCP_DIR) $dcp_dir
#create the DCP dir if it doesn't exist
if {[catch {file mkdir $dcp_dir} err opts] != 0} {
    puts $err
}

if { [info exists ::env(RPT_DIR)] == 1 } {
    set rpt_dir     $::env(RPT_DIR)
} else {
    set rpt_dir        $root_dir/build/Reports
    set ::env(RPT_DIR) $rpt_dir
}
if { [info exists ::env(ILA_DEBUG)] == 1 } {
    set ila_debug     [string toupper $::env(ILA_DEBUG)]
}

set timing_lablimit $::env(TIMING_LABLIMIT)
set fpgacard        $::env(FPGACARD)
set action_root     $::env(ACTION_ROOT)
set action_name     [exec basename $action_root]
set prefix          route_static_

#Define widths of each column
if { [info exists ::env(WIDTHCOL1)] == 1 } {
    set widthCol1 $::env(WIDTHCOL1)
    set widthCol2 $::env(WIDTHCOL2)
    set widthCol3 $::env(WIDTHCOL3)
    set widthCol4 $::env(WIDTHCOL4)
} else {
    set widthCol1 24
    set widthCol2 24
    set widthCol3 36
    set widthCol4 22
    set ::env(WIDTHCOL1) $widthCol1
    set ::env(WIDTHCOL2) $widthCol2
    set ::env(WIDTHCOL3) $widthCol3
    set ::env(WIDTHCOL4) $widthCol4
}


#Checkpoint file => input files
set oc_fpga_static_synth      "oc_${fpgacard}_static_synth"
set oc_fpga_static_synth_dcp  "${oc_fpga_static_synth}.dcp"
set oc_action_name_synth_dcp  "oc_${fpgacard}_${action_name}_synth.dcp"
#Checkpoint file => output files
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"
set oc_fpga_static_routed_dcp "oc_${fpgacard}_static_routed.dcp"

##
## open oc-accel project
set step      ${prefix}open_checkpoint
set logfile   $logs_dir/${step}.log
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start routing static" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_fpga_static_synth_dcp}"]
open_checkpoint  $dcp_dir/$oc_fpga_static_synth_dcp  >> $logfile


# Disable EMCCLK for startup primitive
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [get_designs checkpoint_$oc_fpga_static_synth]
set_property BITSTREAM.CONFIG.CONFIGRATE 51.0 [get_designs checkpoint_$oc_fpga_static_synth]

if { $fpgacard == "AD9H7" } {
   set_property HD.RECONFIGURABLE true [get_cells oc_func0/fw_afu/action_core_i] >> $logfile

   puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_action_name_synth_dcp}"]
   read_checkpoint -cell [get_cells oc_func0/fw_afu/action_core_i] $dcp_dir/${oc_action_name_synth_dcp} >> $logfile

   create_pblock pblock_dynamic_PR >> $logfile
   add_cells_to_pblock [get_pblocks pblock_dynamic_PR] [get_cells [list oc_func0/fw_afu/action_core_i]] >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X4Y3:CLOCKREGION_X7Y11 >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X0Y7:CLOCKREGION_X3Y11 >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X5Y0:CLOCKREGION_X6Y3 >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X0Y0:CLOCKREGION_X7Y0 >> $logfile

} elseif { $fpgacard == "AD9V3" } {
   set_property HD.RECONFIGURABLE true [get_cells oc_func/fw_afu/action_core_i] >> $logfile

   puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_action_name_synth_dcp}"]
   read_checkpoint -cell [get_cells oc_func/fw_afu/action_core_i] $dcp_dir/${oc_action_name_synth_dcp} >> $logfile

   create_pblock pblock_dynamic_PR >> $logfile
   add_cells_to_pblock [get_pblocks pblock_dynamic_PR] [get_cells [list oc_func/fw_afu/action_core_i]] >> $logfile
   #resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X0Y2:CLOCKREGION_X5Y4 >> $logfile
   #following pblock is Zhichao's one
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X2Y1:CLOCKREGION_X3Y2 >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -remove CLOCKREGION_X3Y1 >> $logfile

} elseif { $fpgacard == "AD9H3" } {
   set_property HD.RECONFIGURABLE true [get_cells oc_func/fw_afu/action_core_i] >> $logfile

   puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_action_name_synth_dcp}"]
   read_checkpoint -cell [get_cells oc_func/fw_afu/action_core_i] $dcp_dir/${oc_action_name_synth_dcp} >> $logfile

   create_pblock pblock_dynamic_PR >> $logfile
   add_cells_to_pblock [get_pblocks pblock_dynamic_PR] [get_cells [list oc_func/fw_afu/action_core_i]] >> $logfile
   # right side of the FPGA
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X4Y0:CLOCKREGION_X7Y3 >> $logfile
   # add 3 blocks from bottom left
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X1Y1:CLOCKREGION_X3Y1 >> $logfile
   # top 2 lines of the FPGA
   resize_pblock [get_pblocks pblock_dynamic_PR] -add CLOCKREGION_X0Y2:CLOCKREGION_X7Y3 >> $logfile
   #remove IOB in X4Y0 and X4Y1 used by bsp/FLASH and bsp/dlx_phy
   resize_pblock [get_pblocks pblock_dynamic_PR] -remove {IOB_X0Y52:IOB_X0Y155} >> $logfile
   #remove CONFIG_SITE in X7Y1 for ICAPE3
   resize_pblock [get_pblocks pblock_dynamic_PR] -remove {CONFIG_SITE_X0Y0:CONFIG_SITE_X0Y0 } >> $logfile
   resize_pblock [get_pblocks pblock_dynamic_PR] -add HBM_REF_CLK_X0Y0:HBM_REF_CLK_X0Y1 >> $logfile

} else {
   puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "This script is not adapted for this card"]
   exit 42
}
#-----------------------
set step      ${prefix}opt_design
set directive Explore

set logfile   $logs_dir/${step}.log
set command   "opt_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
#  report_utilization -file  ${rpt_dir}_${step}_utilization.rpt -quiet
}

#----------------
## placing design
set step      ${prefix}place_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "place_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: place_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}

#----------------
# physical optimizing design
set step      ${prefix}phys_opt_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start phys_opt" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: phys_opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}
#-- intermediate WNS display
report_timing_summary -quiet -max_paths 100 -file ${rpt_dir}/timing_summary.rpt
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ${rpt_dir}/timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Estimated Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
#--

#----------------
## routing design
set step      ${prefix}route_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "route_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: route_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}
#-- intermediate WNS display
report_timing_summary -quiet -max_paths 100 -file ${rpt_dir}/timing_summary.rpt
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ${rpt_dir}/timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Estimated Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
#--

##----------------
# physical optimizing routed design
set step      ${prefix}opt_routed_design
set directive Explore

set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"
## Skipping opt_routed step which is too long
##puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start opt_routed" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     SKIPPING  opt_routed" $widthCol3 "" $widthCol4 ""]
##if { [catch "$command > $logfile" errMsg] } {
##  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_routed_design failed" $widthCol4 "" ]
##  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

##  if { ![catch {current_instance}] } {
##    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
##  }
##  exit 42
##} else {
  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     generating ${oc_action_name_routed_dcp}"]
  write_checkpoint -force $dcp_dir/${oc_action_name_routed_dcp} >> $logfile
##}

##----------------
# lock design
if { $fpgacard == "AD9H7" } {
   update_design -cell [get_cells oc_func0/fw_afu/action_core_i] -black_box   >> $logfile
} else {
   update_design -cell [get_cells oc_func/fw_afu/action_core_i] -black_box   >> $logfile
}
set step      ${prefix}lock_design
set logfile   $logs_dir/${step}.log
set command   "lock_design -level routing"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start lock design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: lock design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     generating ${oc_fpga_static_routed_dcp}"]
  write_checkpoint -force $dcp_dir/${oc_fpga_static_routed_dcp}  >> $logfile
}

#close_project  >> $logfile
#END these following lines are in snap_cloud_build


## generating reports
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
report_utilization    -quiet -pblocks [get_pblocks pblock_dynamic_PR]  -file  ${rpt_dir}/utilization_route_design.rpt
report_utilization    -quiet -file  ${rpt_dir}/utilization_route_design.rpt
report_route_status   -quiet -file  ${rpt_dir}/route_status.rpt
report_timing_summary -quiet -max_paths 100 -file ${rpt_dir}/timing_summary.rpt
report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ${rpt_dir}/drc_bitstream_checks.rpt


##
## checking timing
## Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ${rpt_dir}/timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
if { [expr $TIMING_WNS >= 0 ] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
    set ::env(REMOVE_TMP_FILES) TRUE
} elseif { [expr $TIMING_WNS < $timing_lablimit ] && ( $ila_debug != "TRUE" ) } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    puts "---------------------------------------------------------------------------------------------"
    puts "-- The building of the image code has failed for timing reasons.                           --"
    puts "-- The logic was not placed and routed correctly with the constraints provided.            --"
    puts "--  Maximum WNS authorized is set in snap_env.sh by TIMING_LABLIMIT (negative value in ps) --"
    puts "-- Run ./debug_timing to help you finding the paths containing the timing violation        --"
    puts "-- Run vivado hardware/build/Checkpoints/opt_routed_design.dcp to see logic placement.     --"
    puts "---------------------------------------------------------------------------------------------"
    set ::env(REMOVE_TMP_FILES) FALSE
    exit 42
} else {
    if { $ila_debug == "TRUE" } {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use with ILA" $widthCol4 "" ]
    } else {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
    }
    set ::env(REMOVE_TMP_FILES) FALSE
}

##
## set TIMING_WNS for bitstream generation
set ::env(TIMING_WNS) $TIMING_WNS
