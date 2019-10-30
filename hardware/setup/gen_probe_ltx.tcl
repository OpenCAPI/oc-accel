# 1. Copy this file to hardware/build/Checkpoints
# 2. Usage
#  vivado -mode batch -source ./gen_probe_ltx.tcl -notrace
open_checkpoint ../build/Checkpoints/synth_design.dcp
write_debug_probes probe.ltx
close_design
