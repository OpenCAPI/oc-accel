set_property used_in_simulation true [get_files $fpga_top_src_dir/oc_fpga_top.v]
#set_property used_in_simulation true [get_files oc_bsp_wrap.xci]

#foreach verif_file [glob -nocomplain -dir $root_dir/sim/unit_verif */*] {
#    set_property file_type SystemVerilog [get_files $verif_file] >> $log_file
#    set_property used_in_simulation true [get_files $verif_file] >> $log_file
#    set_property used_in_synthesis false [get_files $verif_file] >> $log_file
#    set_property used_in_implementation false [get_files $verif_file] >> $log_file
#}

foreach hw_file [glob -nocomplain -dir $action_hw_dir/hdl *.v] {
    set_property file_type SystemVerilog [get_files $hw_file] >> $log_file
    set_property used_in_simulation true [get_files $hw_file] >> $log_file
    set_property used_in_synthesis false [get_files $hw_file] >> $log_file
    set_property used_in_implementation false [get_files $hw_file] >> $log_file
}

