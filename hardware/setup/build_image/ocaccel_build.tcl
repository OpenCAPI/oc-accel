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

set root_dir      $::env(OCACCEL_HARDWARE_ROOT)
#set logs_dir      $::env(LOGS_DIR)
#set logfile       $logs_dir/ocaccel_build.log
set capi_ver      $::env(CAPI_VER)
set fpgacard      $::env(FPGACARD)
set ila_debug     [string toupper $::env(ILA_DEBUG)]
set vivadoVer     [version -short]

set timing_lablimit $::env(TIMING_LABLIMIT)
#Image directory
set img_dir $root_dir/build/Images
set ::env(IMG_DIR) $img_dir

#Remove temp files
set ::env(REMOVE_TMP_FILES) TRUE

set lsf_run FALSE

#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22
set ::env(WIDTHCOL1) $widthCol1
set ::env(WIDTHCOL2) $widthCol2
set ::env(WIDTHCOL3) $widthCol3
set ::env(WIDTHCOL4) $widthCol4


############################################################################
## open ocaccel project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open top project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_project $root_dir/build/viv_project/viv_project.xpr


############################################################################
# Set image_name
set IMAGE_NAME [expr {$capi_ver == "OPENCAPI30" ? "oc_" : "fw_"}]
append IMAGE_NAME [exec cat $root_dir/setup/build_image/bitstream_date.txt]
append IMAGE_NAME [expr {$::env(PHY_SPEED) == "20.0" ? "_20G" : "_25G"}]
append IMAGE_NAME [format {_%s} $::env(ACTION_NAME)]
append IMAGE_NAME [format {_%s_%s_%s} $::env(INFRA_TEMPLATE_SELECTION) $::env(ACTION_TEMPLATE_SELECTION) $fpgacard]
puts "IMAGE_NAME is set to $IMAGE_NAME"

############################################################################
# Launch Runs
if { $lsf_run == "TRUE"} {
    # This is a secret switch but hasn't been tested:-)
    source $root_dir/setup/build_image/create_other_strategy_impls.tcl
    # This script will set TIMING_WNS to env

} else {
    # Use default strategy
    launch_runs impl_1 -jobs 8
    wait_on_run [get_runs impl_1]
    puts "impl_1 finished."

    set wns [get_property STATS.WNS [get_runs impl_1]]
    puts "wns is $wns"

    set TIMING_WNS [expr $wns * 1000]
    set TIMING_WNS [expr int($TIMING_WNS) + 1]
    set ::env(TIMING_WNS) $TIMING_WNS
    if { [expr $TIMING_WNS < $timing_lablimit ] } {
        puts "Will not open the checkpoint"
    } else {
        open_run impl_1
    }
}

# Generate bitstream
append IMAGE_NAME [format {_%s} $::env(TIMING_WNS)]

if { [expr $::env(TIMING_WNS) < $timing_lablimit ] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    # EXIT!!!!
    close_project
    exit 11
} else {
    if { [expr $::env(TIMING_WNS) >= 0 ] } {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
    } else {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 ""
    }
    ###########################
    #  Write bitstream
    write_bitstream -force -file $img_dir/$IMAGE_NAME
    write_cfgmem -force -format bin -size $::env(FLASH_SIZE) -interface  $::env(FLASH_INTERFACE) -loadbit "up 0x0 $img_dir/$IMAGE_NAME.bit" $img_dir/$IMAGE_NAME

    ###########################
    #  Write probe file
    if { $ila_debug == "TRUE" } {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "writing debug probes" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
        write_debug_probes $img_dir/$IMAGE_NAME.ltx
    }

}

close_project
