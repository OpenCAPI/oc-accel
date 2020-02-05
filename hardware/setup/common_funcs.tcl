# This tcl contains the common functions used in block design creation

#------------------------------------------------------------------------------
proc my_create_bus_interface {bus_path bus_name port_list} {
   puts "    <<<"
   puts "    <<< Creating bus_interface $bus_name to $bus_path"
   puts "    <<<"
   set vendor "opencapi.org"
   set lib "ocaccel"
   set ver "1.0"
   ipx::create_abstraction_definition $vendor $lib ${bus_name}_rtl $ver
   ipx::create_bus_definition $vendor $lib $bus_name $ver
   set_property xml_file_name $bus_path/${bus_name}_rtl.xml [ipx::current_busabs]
   set_property xml_file_name $bus_path/${bus_name}.xml [ipx::current_busdef]
   set_property bus_type_vlnv $vendor:$lib:$bus_name:$ver [ipx::current_busabs]
   ipx::save_bus_definition [ipx::current_busdef]
   ipx::save_abstraction_definition [ipx::current_busabs]

   foreach port $port_list {
       ipx::add_bus_abstraction_port $port [ipx::current_busabs]
   }
   ipx::save_bus_definition [ipx::current_busdef]
   ipx::save_abstraction_definition [ipx::current_busabs]

}

#------------------------------------------------------------------------------
proc my_package_custom_ip {proj_path ip_path if_path fpga_part ip_name addfile_script bus_array} {

   puts "    <<<"
   puts "    <<< Package customer design $ip_name to $ip_path"
   puts "    <<<"
   set vendor "opencapi.org"
   set lib "ocaccel"
   set ver "1.0"
   set project viv_${ip_name}
   set project_dir $proj_path/$project
   create_project $project $project_dir -part $fpga_part

   # Set 'sources_1' fileset object, create list of all nececessary verilog files
   set obj [get_filesets sources_1]
   
   
   # Add source files and import
   source $addfile_script

   #------------------------------------------------------------------------------
   # Add interface path to allow auto-infering
   set_property ip_repo_paths  $if_path [current_project]
   update_ip_catalog -rebuild -scan_changes
   # Start to package this project as an IP
   ipx::package_project -root $ip_path/$ip_name -import_files -force -vendor $vendor -library $lib -taxonomy /UserIP
   
   foreach bus [dict keys $bus_array] {
       set mode [dict get $bus_array $bus]
       ipx::infer_bus_interfaces $vendor:$lib:${bus}_rtl:$ver [ipx::current_core]
       if { $mode ne "" } {
           set_property interface_mode $mode [ipx::get_bus_interfaces ${lib}_${bus} -of_objects [ipx::current_core]]
       }
   }
   ipx::create_xgui_files [ipx::current_core]
   ipx::update_checksums [ipx::current_core]
   ipx::save_core [ipx::current_core]

   close_project
}

proc my_get_build_date {} {
    set build_date [exec date "+%Y%m%d%H%M"]
    puts "build_date is $build_date"
    return "0x$build_date"
}

proc my_get_imp_version {} {
    set imp_version [exec git describe --tags --always]
    return "0x$imp_version"
}

proc my_get_card_type {} {
    set fpgacard $::env(FPGACARD)
    if { $fpgacard eq "AD9V3" } {
        set card_type "0x31"
    }
    if { $fpgacard eq "AD9H3" } {
        set card_type "0x32"
    }
    if { $fpgacard eq "AD9H7" } {
        set card_type "0x33"
    }
    if { $fpgacard eq "N250SOC" } {
        set card_type "0x34"
    }
    return $card_type
}

