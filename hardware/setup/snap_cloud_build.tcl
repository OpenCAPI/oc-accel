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

#package require fileutil

set root_dir      $::env(SNAP_HARDWARE_ROOT)
set logs_dir      $::env(LOGS_DIR)
set logfile       $logs_dir/snap_cloud_build.log
set fpgacard      $::env(FPGACARD)
set action_root   $::env(ACTION_ROOT)
set action_name   [exec basename $action_root]
set ila_debug     [string toupper $::env(ILA_DEBUG)]
set cloud_run     $::env(CLOUD_RUN)
set vivadoVer     [version -short]

#Checkpoint directory
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

#Checkpoint file
set oc_fpga_static_synth_dcp  "oc_${fpgacard}_static_synth.dcp"
set oc_action_name_synth_dcp  "oc_${fpgacard}_${action_name}_synth.dcp"

#Report directory
set rpt_dir        $root_dir/build/Reports
set ::env(RPT_DIR) $rpt_dir

#Image directory
set img_dir $root_dir/build/Images
set ::env(IMG_DIR) $img_dir

#Remove temp files
set ::env(REMOVE_TMP_FILES) TRUE

if { [info exists ::env(CLOUD_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(CLOUD_BUILD_BITFILE)]
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


## open snap project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  open_project $root_dir/viv_project/framework.xpr > $logfile


## run synthesis
if { ($cloud_run == "ACTION") || ($cloud_run == "BASE") } {
  source $root_dir/setup/oc_pr_synth_action.tcl
}

if { ($cloud_run == "BASE") } {
  source $root_dir/setup/oc_pr_synth_static.tcl
}


## run implementation in the base flow
if { ($cloud_run == "BASE") } {
  source $root_dir/setup/oc_pr_route_static.tcl
}

if { ($cloud_run == "ACTION") } {
  source $root_dir/setup/oc_pr_route_action.tcl
}

if { $cloud_build_bitfile == "TRUE" } {
## writing bitstream
  source $root_dir/setup/oc_pr_image.tcl
}


##
## writing debug probes
if { $ila_debug == "TRUE" } {
  set step     write_debug_probes
  set logfile  $logs_dir/${step}.log
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "writing debug probes" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  write_debug_probes $img_dir/$IMAGE_NAME.ltx >> $logfile
}


##
## removing temporary checkpoint files
if { $::env(REMOVE_TMP_FILES) == "TRUE" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "removing synth dcp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
}
  exec rm -rf $dcp_dir/$oc_fpga_static_synth_dcp
  exec rm -rf $dcp_dir/$oc_action_name_synth_dcp
#}
exec rm -rf $logs_dir/*.backup*

#close_project >> $logfile
