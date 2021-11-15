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
set rpt_dir         $::env(RPT_DIR)
set action_dcp_dir  $::env(ACTION_DCP_DIR)
set base_dcp_dir    $::env(BASE_DCP_DIR)

set timing_lablimit $::env(TIMING_LABLIMIT)
set fpgacard        $::env(FPGACARD)
set action_root     $::env(ACTION_ROOT)
set action_name     [exec basename $action_root]
set prefix          route_action_

#Define widths of each column
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

#Looking for PRxxxx occurrence in static_routed.dcp filename
#WARNING - dealing with only 1 filename per card
set prefix  "oc_${fpgacard}_PR"
set pr_file_name [exec basename [ exec find $base_dcp_dir/ -name ${prefix}*_static_routed.dcp ]]
if { $pr_file_name != "" } {
   #looking for 3 digits after PR
   set pattern {PR([0-9a-f]{3})}
   set PRC3 [regexp -all $pattern $pr_file_name PRC]
   #puts $PRC
} else {
   puts "-------------------------------------------------------------------------------------"
   puts "ERROR: File ${prefix}*_static_routed.dcp not found in $base_dcp_dir!"
   puts "  Please generate 'make cloud_base' before running 'make cloud_action'."
   puts "               or 'make oc_pr_route_static' before running 'make oc_pr_route_action'."
   puts "-------------------------------------------------------------------------------------"
  exit 42
}

#Checkpoint file => input files
set oc_action_name_synth_dcp  "oc_${fpgacard}_${action_name}_synth.dcp"
set oc_fpga_static_routed_dcp "oc_${fpgacard}_${PRC}_static_routed.dcp"
#Checkpoint file => output files
set oc_action_name_routed_dcp "oc_${fpgacard}_${action_name}_routed.dcp"

##
## open oc-accel project
set step      ${prefix}open_checkpoint
set logfile   $logs_dir/${step}.log
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start routing action" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T}]"]
puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_fpga_static_routed_dcp}"]
open_checkpoint  $base_dcp_dir/$oc_fpga_static_routed_dcp  >> $logfile


puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     opening ${oc_action_name_synth_dcp}"]
if { $fpgacard == "AD9H7" } {
   read_checkpoint -cell [get_cells oc_func0/fw_afu/action_core_i] $action_dcp_dir/${oc_action_name_synth_dcp}  >> $logfile
} else {
   read_checkpoint -cell [get_cells oc_func/fw_afu/action_core_i] $action_dcp_dir/${oc_action_name_synth_dcp} >> $logfile
}

#-----------------------
set step      ${prefix}opt_design
set directive Explore

set logfile   $logs_dir/${step}.log
set command   "opt_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force $action_dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $action_dcp_dir/${step}.dcp          >> $logfile
#  report_utilization -file  ${rpt_dir}_${step}_utilization.rpt -quiet
}

#----------------
## placing design
set step      ${prefix}place_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "place_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: place_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $action_dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $action_dcp_dir/${step}.dcp          >> $logfile
}

#----------------
# physical optimizing design
set step      ${prefix}phys_opt_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start phys_opt" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: phys_opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $action_dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $action_dcp_dir/${step}.dcp          >> $logfile
}

#----------------
## routing design
set step      ${prefix}route_design
set directive Explore
set logfile   $logs_dir/${step}.log
set command   "route_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: route_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $action_dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
#} else {
#  write_checkpoint   -force $action_dcp_dir/${step}.dcp          >> $logfile
}

##----------------
# physical optimizing routed design
set step      ${prefix}opt_routed_design
set directive Explore


set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "     start opt_routed" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_routed_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $action_dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  puts [format "%-*s%-*s"  $widthCol1 "" $widthCol2 "     generating ${oc_action_name_routed_dcp}"]
  write_checkpoint -force $action_dcp_dir/${oc_action_name_routed_dcp} >> $logfile
}

#close_project  >> $logfile
#END these following lines are in snap_cloud_build


## generating reports
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T}]"]
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
