
set action_root $::env(ACTION_ROOT)
set fpga_part $::env(FPGACHIP)
set software_root $::env(OCACCEL_ROOT)/software
set hardware_dir       $::env(OCACCEL_HARDWARE_ROOT)


set top_name vadd
set hls_proj ${top_name}_${fpga_part}
set cflags " -I$action_root/include -I$software_root/include"

open_project $hls_proj

# top_name should match the name of the entry function
set_top $top_name

# Can that be a list?
foreach file [ list $top_name.cpp ] {
  add_files ${file} -cflags ${cflags}
}

#foreach file [ list vadd.cpp  ] {
#  add_files -tb ${file} -cflags " -DNO_SYNTH -I/afs/vlsilab.boeblingen.ibm.com/data/vlsi/eclipz/c14/usr/luyong/p9nd2/oc_dev/internal2/actions/include -I/afs/vlsilab.boeblingen.ibm.com/data/vlsi/eclipz/c14/usr/luyong/p9nd2/oc_dev/internal2/software/include -I../../../software/examples -I../include"
#}

open_solution $top_name
set_part $fpga_part

create_clock -period 4 -name default
config_interface -m_axi_addr64=true
#config_rtl -reset all -reset_level low
config_export -format ip_catalog -rtl verilog -version 1.0 -vendor opencapi.org -library ocaccel
csynth_design
export_design -format ip_catalog -rtl verilog -vendor "opencapi.org" -library "ocaccel" -version "1.0"

# Generate the register layout header files
set kernel_top $top_name
source $hardware_dir/setup/package_action/hls_specific/hls_action_parse.tcl
exit