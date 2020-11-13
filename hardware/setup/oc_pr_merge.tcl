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
set action_name       $::env(ACTION_NAME) 
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


##
## open oc-accel project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open framework pjt and prep ${action_name} synth" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_project $root_dir/viv_project/framework.xpr >> $logfile

synth_design -directive Default -fanout_limit 400 -fsm_extraction one_hot -resource_sharing off -shreg_min_size 5 -flatten_hierarchy rebuilt -keep_equivalent_registers -no_lc -top oc_action_core -part xcvu3p-ffvc1517-2-e -mode out_of_context


puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "Writing $dcp_dir/oc_${action_name}_synth.dcp" $widthCol4 "" ]
write_checkpoint -force $dcp_dir/oc_${action_name}_synth.dcp >> $logfile

close_project  >> $logfile

