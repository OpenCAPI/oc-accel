# According to ug904 (Vivado Implementation) 
# Vivado 2018.3 supports many other strategies to implement the design
# This script includes them. 
#
# Generally, it has 5 categories:
# * Performance
# * Area
# * Power
# * Flow
# * Congestion
#
# For all of the strageties, use 
# join [list_property_value strategy [get_runs impl_1] ]
#
set root_dir            $::env(SNAP_HARDWARE_ROOT)
set logs_dir            $::env(LOGS_DIR)
set fpga_part           $::env(FPGACHIP)
set timing_lablimit     $::env(TIMING_LABLIMIT)
set lsf_impl_list       $root_dir/setup/build_image/$::env(LSF_IMPL_LIST)
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

set logfile  $logs_dir/create_other_strategy_impls.log

if {[file exists $lsf_impl_list] == 0} {
    set impl_strategies { \
        Performance_Explore \
        Performance_ExplorePostRoutePhysOpt \
        Performance_ExploreWithRemap \
        Performance_WLBlockPlacement \
        Performance_WLBlockPlacementFanoutOpt \
        Performance_EarlyBlockPlacement \
        Performance_NetDelay_high \
        Performance_NetDelay_low \
        Performance_Retiming \
        Performance_ExtraTimingOpt \
        Performance_RefinePlacement \
        Performance_SpreadSLLs \
        Performance_BalanceSLLs \
        Performance_BalanceSLRs \
        Performance_HighUtilSLRs \
        Congestion_SpreadLogic_high \
        Congestion_SpreadLogic_medium \
        Congestion_SpreadLogic_low \
        Congestion_SSI_SpreadLogic_high \
        Congestion_SSI_SpreadLogic_low \
    }
    puts "                        create impl runs from default list" 
} else {
    source $lsf_impl_list
    puts "                        create impl runs from $lsf_impl_list" 
}

current_run -synthesis [get_runs synth_1]
#set_property design_mode GateLvl [current_fileset ]
puts "                        create more impl runs ..."
set i 0
set run_list ""
foreach stg $impl_strategies {
  if {[string equal [get_runs -quiet impl_${i}_${stg}] ""]} {
    create_run -name impl_${i}_${stg} -part $fpga_part -flow {Vivado Implementation 2018} -strategy "$stg" -constrset constrs_1 -parent_run synth_1 -quiet > $logfile
  } else {
    set_property strategy "$stg" [get_runs impl_${i}_${stg}]
    set_property flow "Vivado Implementation 2018" [get_runs impl_${i}_${stg}]
  }
  #set_property STEPS.WRITE_BITSTREAM.TCL.POST ${root_dir}/setup/snap_bitstream_post.tcl [get_runs impl_${i}_${stg}]
  puts "                        create impl_${i}_${stg} runs done"
  lappend run_list impl_${i}_${stg}
  incr i
}

launch_runs $run_list -lsf {bsub -P P9 -G p91_unit -M 32 -n 2 -R \"select[osname==linux]\" -R \"select[type==X86_64]\" -q normal} -jobs $i > $logfile
puts "                        launch $i impl runs done"

puts "                        waiting on all runs"
foreach my_run $run_list {
    wait_on_run $my_run > $logfile
    puts "                        $my_run finished"
}

set best_run impl_1_Performance_Explore
set best_wns [get_property STATS.WNS [get_runs impl_1_Performance_Explore]]

foreach my_run $run_list {
    set wns [get_property STATS.WNS [get_runs $my_run]]
    if { [info exists $wns] == 0 } {
        puts "WARNING: $my_run has no WNS property, failed run?"
    } else {
        puts "$my_run WNS: $wns"
        if { [expr $wns > $best_wns] } {
            set best_wns $wns
            set best_run $my_run
        }
    }
}

puts "                        best run is $best_run, WNS: $best_wns"

# Change to ps
set TIMING_WNS [expr $best_wns * 1000]
# Round to integer
set TIMING_WNS [expr int($TIMING_WNS) + 1]
## set TIMING_WNS for bitstream generation
set ::env(TIMING_WNS) $TIMING_WNS
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]

if { [expr $TIMING_WNS < $timing_lablimit ] } {
     puts "Will not open the checkpoint"
     #EXIT!!!!
     exit
}

# Open checkpoint
set best_run_dir [get_property DIRECTORY [get_runs $best_run]]
if {[file exists $best_run_dir/oc_fpga_top_postroute_physopt.dcp] == 1} {
    puts "                        Opening oc_fpga_top_postroute_physopt.dcp"
    open_checkpoint $best_run_dir/oc_fpga_top_postroute_physopt.dcp 
} else {
    puts "                        Opening oc_fpga_top_routed.dcp"
    open_checkpoint $best_run_dir/oc_fpga_top_routed.dcp 
}



