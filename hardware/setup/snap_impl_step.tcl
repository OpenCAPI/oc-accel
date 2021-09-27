############################################################################
############################################################################
##
## Copyright 2016-2018 International Business Machines
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
set dcp_dir         $::env(DCP_DIR)
set capi_ver        $::env(CAPI_VER)
set impl_flow       $::env(IMPL_FLOW)
set timing_lablimit $::env(TIMING_LABLIMIT)
set fpgacard        $::env(FPGACARD)
set ila_debug       $::env(ILA_DEBUG)
set vivadoVer       [version -short]

if { [info exists ::env(IMPL_STEP)] == 1 } {
  set impl_step     $::env(IMPL_STEP)
} else {
  set impl_step   "ALL"
}
#Define widths of each column
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

if { $impl_flow == "CLOUD_BASE" } {
  set cloud_flow TRUE
  set prefix base_
  set rpt_dir_prefix $rpt_dir/${prefix}
} elseif { $impl_flow == "CLOUD_MERGE" } {
  set cloud_flow TRUE
  set prefix merge_
  set rpt_dir_prefix $rpt_dir/${prefix}
} else {
  set cloud_flow FALSE
  set rpt_dir_prefix $rpt_dir/

  ##
  ## save framework directives for later use
  set place_directive     [get_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set phys_opt_directive  [get_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set route_directive     [get_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set opt_route_directive [get_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
}

## Adding elf file to project and loading on microblaze BRAM for 250SOC only

if { $fpgacard == "BW250SOC" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Adding elf file" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  import_files -fileset sim_1 -norecurse $root_dir/oc-bip/board_support_packages/bw250soc/ip/qspi_mb_golden.elf -force
  import_files -norecurse $root_dir/oc-bip/board_support_packages/bw250soc/ip/qspi_mb_golden.elf -force
  set_property SCOPED_TO_REF design_1 [get_files -all -of_objects [get_fileset sources_1] [get_files $root_dir/viv_project/framework.srcs/sources_1/imports/ip/qspi_mb_golden.elf]]
  set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sources_1] [get_files $root_dir/viv_project/framework.srcs/sources_1/imports/ip/qspi_mb_golden.elf]]
  set_property SCOPED_TO_REF design_1 [get_files -all -of_objects [get_fileset sim_1] [get_files $root_dir/viv_project/framework.srcs/sim_1/imports/ip/qspi_mb_golden.elf]]
  set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sim_1] [get_files $root_dir/viv_project/framework.srcs/sim_1/imports/ip/qspi_mb_golden.elf]]
}

##
## optimizing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}opt_design
  set directive Explore
} else {
  set step      opt_design
  set directive [get_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
}

## SYNTH means "synthesis + opt_design"
if { ($impl_step == "SYNTH") || ($impl_step == "ALL") } {
  set logfile   $logs_dir/${step}.log
  set command   "opt_design -directive $directive"
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_design failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  
    if { ![catch {current_instance}] } {
        write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
    }
    exit 42
  } else {
    write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
    report_utilization -file  ${rpt_dir}/${step}_utilization.rpt -quiet
  }
}

##
## Vivado 2017.4 has problems to place the SNAP core logic, if they can place inside the PSL
#if { ($vivadoVer >= "2017.4") && ($cloud_flow == "FALSE") } {
#  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "reload opt_design DCP" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
#  close_project                         >> $logfile
#  open_checkpoint $dcp_dir/${step}.dcp  >> $logfile
#}

## if impl_step == "PLACE" then last dcp needs to be loaded
if { ($impl_step == "PLACE") } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "reload opt_design DCP" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  open_checkpoint $dcp_dir/${step}.dcp  >> $logfile
}

##
## placing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}place_design
  set directive Explore
} else {
  set step      place_design
  set directive $place_directive
}

if { ($impl_step == "PLACE") || ($impl_step == "ALL") } {
  set logfile   $logs_dir/${step}.log
  set command   "place_design -directive $directive"
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  
  ##
  ## prevent placing inside PSL
  if { $capi_ver == "capi10" } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Prevent placing inside PSL" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
    set_property EXCLUDE_PLACEMENT 1 [get_pblocks b_nestedpsl]
  }
  
  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: place_design failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  
    if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
    }
    exit 42
  } else {
    write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  }
}

##
## physical optimizing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}phys_opt_design
  set directive Explore
} else {
  set step      phys_opt_design
  set directive $phys_opt_directive
}

if { ($impl_step == "PLACE") || ($impl_step == "ALL") } {
  set logfile   $logs_dir/${step}.log
  set command   "phys_opt_design  -directive $directive"
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start phys_opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  
  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: phys_opt_design failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  
    if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
    }
    exit 42
  } else {
    write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  }
}

## if impl_step == "ROUTE" then last dcp needs to be loaded
if { ($impl_step == "ROUTE") } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "reload phys_opt_design DCP" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  open_checkpoint $dcp_dir/${step}.dcp  >> $logfile
}
##
## routing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}route_design
  set directive Explore
} else {
  set step      route_design
  set directive $route_directive
}

if { ($impl_step == "ROUTE") || ($impl_step == "ALL") } {
  set logfile   $logs_dir/${step}.log
  set command   "route_design -directive $directive"
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  
  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: route_design failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  
    if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
    }
    exit 42
  } else {
    write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  }
}

##
## physical optimizing routed design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}opt_routed_design
  set directive Explore
} else {
  set step      opt_routed_design
  set directive $opt_route_directive
}

if { ($impl_step == "ROUTE") || ($impl_step == "ALL") } {
  set logfile   $logs_dir/${step}.log
  set command   "phys_opt_design  -directive $directive"
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start opt_routed_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  
  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_routed_design failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  
    if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
    }
    exit 42
  } else {
    write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  }
}

##
## generating reports
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
report_utilization    -quiet -file  ${rpt_dir_prefix}utilization_route_design.rpt
report_route_status   -quiet -file  ${rpt_dir_prefix}route_status.rpt
report_timing_summary -quiet -max_paths 100 -file ${rpt_dir_prefix}timing_summary.rpt
report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ${rpt_dir_prefix}drc_bitstream_checks.rpt


##
## checking timing
## Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ${rpt_dir_prefix}timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
if { ($impl_step == "PLACE") } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Estimated Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
} elseif { ($impl_step == "ROUTE") || ($impl_step == "ALL") } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
}
if { ($impl_step == "ROUTE") || ($impl_step == "ALL") } {
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
}

##
## set TIMING_WNS for bitstream generation
set ::env(TIMING_WNS) $TIMING_WNS
