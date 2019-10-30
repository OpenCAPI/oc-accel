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
set fpga_part           $::env(FPGACHIP)

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
Area_Explore \
Area_ExploreSequential \
Area_ExploreWithRemap \
Power_DefaultOpt \
Power_ExploreArea \
Flow_RunPhysOpt \
Flow_RunPostRoutePhysOpt \
Flow_RuntimeOptimized \
Flow_Quick \
}

current_run -synthesis [get_runs synth_1]
#set_property design_mode GateLvl [current_fileset ]
puts "                        create more impl runs ..."
set i 2
foreach stg $impl_strategies {
  if {[string equal [get_runs -quiet impl_${i}_${stg}] ""]} {
    create_run -name impl_${i}_${stg} -part $fpga_part -flow {Vivado Implementation 2018} -strategy "$stg" -constrset constrs_1 -parent_run synth_1 -quiet
  } else {
    set_property strategy "$stg" [get_runs impl_${i}_${stg}]
    set_property flow "Vivado Implementation 2018" [get_runs impl_${i}_${stg}]
  }
  set_property STEPS.WRITE_BITSTREAM.TCL.POST ${root_dir}/setup/snap_bitstream_post.tcl [get_runs impl_${i}_${stg}]
  incr i
}
puts "                        create $i impl runs done"
#launch_runs impl_12 -lsf {bsub -R select[type=X86_64] -P P9 -G p91_unit -M 16 -n 1 -q normal}
