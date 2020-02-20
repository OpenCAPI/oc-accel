
set action_root $::env(ACTION_ROOT)
set fpga_part $::env(FPGACHIP)
set software_root $::env(OCACCEL_ROOT)/software

set hls_proj $::env(ACTION_NAME)_${fpga_part}
set cflags " -I$action_root/include -I$software_root/include"

open_project $hls_proj

# top_name should match the name of the entry function
set top_name vadd
set_top $top_name

# Can that be a list?
foreach file [ list vadd.cpp ] {
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

csynth_design
#export_design -format ip_catalog -rtl vhdl
exit
