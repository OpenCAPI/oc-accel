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

set fpga_card_lcase     [string tolower $::env(FPGACARD)]

set root_dir            $::env(SNAP_HARDWARE_ROOT)
set ip_dir              $root_dir/ip
set hls_ip_dir          $ip_dir/hls_ip_project/hls_ip_project.srcs/sources_1/ip
set hbm_ip_dir          $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/ip
set action_dir          $::env(ACTION_ROOT)
set action_hw_dir       $action_dir/hw
set action_ip_dir       $action_dir/ip/action_ip_prj/action_ip_prj.srcs/sources_1/ip
set action_bd_dir       $action_dir/ip/action_ip_prj/action_ip_prj.srcs/sources_1/bd
set action_tcl          [exec find $action_hw_dir -name tcl -type d]

#set usr_ip_dir          $ip_dir/managed_ip_project/managed_ip_project.srcs/sources_1/ip
set card_ip_dir         $root_dir/viv_project/framework.srcs/sources_1/ip
set hdl_dir             $root_dir/hdl
set sim_dir             $root_dir/oc-bip/sim
set sim_src             $sim_dir/src
set sim_top             top
set fpga_top            oc_fpga_top
set fpga_part           $::env(FPGACHIP)
set fpga_card           $::env(FPGACARD)
set capi_ver            $::env(CAPI_VER)
set fpga_card_dir       $root_dir/oc-bip/board_support_packages/$fpga_card_lcase
set top_src_dir         $fpga_card_dir/verilog
set fpga_top_src_dir    $fpga_card_dir/verilog/framework_top
set top_xdc_dir         $fpga_card_dir/xdc
set nvme_used           $::env(NVME_USED)
set bram_used           $::env(BRAM_USED)
set sdram_used          $::env(SDRAM_USED)
set hbm_used            $::env(HBM_USED)
set eth_used            $::env(ETHERNET_USED)
set eth_loop_back       $::env(ETH_LOOP_BACK)
set user_clock          $::env(USER_CLOCK)
set ila_debug           [string toupper $::env(ILA_DEBUG)]
set simulator           $::env(SIMULATOR)
set denali_used         $::env(DENALI_USED)
set unit_sim_used       $::env(UNIT_SIM_USED)
set odma_used           $::env(ODMA_USED)
set log_dir             $::env(LOGS_DIR)
set log_file            $log_dir/create_framework.log
set vivadoVer           [version -short]

if { $unit_sim_used == "TRUE" } {
    puts "!!ATTENTION: UNIT SIM enabled, no OCSE and software, only UVM based testbench and TLX-AXI bridge."
    set sim_top unit_top
}

if { $odma_used == "TRUE" } {
    puts "!!ATTENTION: ODMA enabled, no TLX-AXI bridge is available"
    set sim_top unit_top
}

if { [info exists ::env(HLS_SUPPORT)] == 1 } {
  set hls_support [string toupper $::env(HLS_SUPPORT)]
} elseif { [string first "/HLS" [string toupper $action_dir]] != -1 } {
  puts "                        INFO: action is contained in path starting with \"HLS\"."
  puts "                              Setting HLS_SUPPORT to TRUE."
  set hls_support "TRUE"
} else {
  set hls_support "not defined"
}

# HLS generates VHDL and Verilog files, SNAP is using the VHDL files
if { $hls_support == "TRUE" } {
  set action_hw_dir $::env(ACTION_ROOT)/hw/hls_syn_vhdl
}

if { [info exists ::env(PSL_DCP)] == 1 } {
  set psl_dcp $::env(PSL_DCP)
} else {
  set psl_dcp "FALSE"
}

# Create a new Vivado Project
puts "\[CREATE_FRAMEWORK....\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project framework $root_dir/viv_project -part $fpga_part -force >> $log_file

# Project Settings
# General
puts "                        setting up project settings"
set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]
# Simulation
if { ( $simulator == "irun" ) } {
  set_property target_simulator IES [current_project]
  set_property compxlib.ies_compiled_library_dir $::env(IES_LIBS) [current_project]
  set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc} -objects [current_fileset -simset]

  if { $hbm_used == TRUE } {
    #NEW - 3 following lines to circumvent Xilinx bug when simulating HBM (PG276)
    set_property -name {ies.simulate.ncsim.more_options} -value {+notimingchecks} -objects [get_filesets sim_1]
    set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc -notimingchecks} -objects [get_filesets sim_1]
    set_property -name {ies.simulate.runtime} -value {1ms} -objects [get_filesets sim_1]
  }
} elseif { $simulator == "xcelium" } {
  set_property target_simulator Xcelium [current_project]
  set_property compxlib.xcelium_compiled_library_dir $::env(IES_LIBS) [current_project]
  if { $hbm_used == TRUE } {
    #NEW - 2 following lines to circumvent Xilinx bug when simulating HBM (PG276)
    set_property -name {xcelium.simulate.xmsim.more_options} -value {-notimingcheck} -objects [get_filesets sim_1]
    set_property -name {xcelium.simulate.runtime} -value {1ms} -objects [get_filesets sim_1]
    set_property -name {xcelium.elaborate.xmelab.more_options} -value {-notimingchecks -relax} -objects [get_filesets sim_1]
  }
} elseif { $simulator == "xsim" } {
  set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_lib libdpi -sv_root .} -objects [current_fileset -simset]
}
if { $simulator != "nosim" } {
  set_property top $sim_top [get_filesets sim_1]
  set_property export.sim.base_dir $root_dir [current_project]
}

#set_property include_dirs $top_src_dir [current_fileset]
#add_files -fileset utils_1 -norecurse $root_dir/setup/snap_bitstream_post.tcl

# Synthesis
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property flow "Vivado Synthesis 2018"         [get_runs synth_1]

set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              400     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          off     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            5       [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         rebuilt [get_runs synth_1]

# Implementaion
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream

#set_property STEPS.WRITE_BITSTREAM.TCL.PRE  $root_dir/oc-bip/board_support_packages/$fpga_card_lcase/xdc/snap_bitstream_pre.tcl  [get_runs impl_1]
# this tcl is generated from Makefile
set_property STEPS.WRITE_BITSTREAM.TCL.POST $root_dir/setup/snap_bitstream_post.tcl [get_runs impl_1] >> $log_file

# Add Files
puts "                        importing design files"
# SNAP core Files
add_files -scan_for_includes $hdl_dir/core  >> $log_file
add_files -scan_for_includes $hdl_dir/oc >> $log_file
add_files -scan_for_includes $fpga_top_src_dir/oc_fpga_top.v >> $log_file

set file "snap_global_vars.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set_property used_in_simulation false [get_files $fpga_top_src_dir/oc_fpga_top.v]
set_property top $fpga_top [current_fileset]

# ODMA specific
if { $odma_used == "TRUE" } {
    puts "                        importing ODMA sources"
    add_files -scan_for_includes $hdl_dir/odma/  >> $log_file
    set_property file_type {Verilog Header} [get_files $hdl_dir/odma/odma_defines.v]
}

# Action Files
if { $hls_support == "TRUE" } {
  add_files -scan_for_includes $hdl_dir/hls/ >> $log_file
}

add_files -scan_for_includes $action_hw_dir/ >> $log_file

# Action Specific tcl
if { [file exists $action_tcl] == 1 } {
  set tcl_exists [exec find $action_tcl -name *.tcl]
  if { $tcl_exists != "" } {
    foreach tcl_file [glob -nocomplain -dir $action_tcl *.tcl] {
      set tcl_file_name [exec basename $tcl_file]
      puts "                        sourcing $tcl_file_name"
      source $tcl_file
    }
  }
}



# Sim Files
if { $simulator != "nosim" } {
  puts "                        importing simulation files for $simulator"
  if {$unit_sim_used == "TRUE"} {
    add_files -scan_for_includes $root_dir/sim/unit_verif  >> $log_file
  }
  add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_src/$sim_top.sv  >> $log_file
  set_property file_type SystemVerilog [get_files $sim_src/$sim_top.sv]
  set_property used_in_synthesis false [get_files $sim_src/$sim_top.sv]
  
  # DDR4 Sim Files
  if { ($fpga_card == "AD9V3") && ($sdram_used == "TRUE") } {
    #keep the 3 following lines
    add_files -norecurse $ip_dir/ddr4sdram_ex/imports/bd_2a05_lmb_bram_I_0.mem
    add_files -norecurse $ip_dir/ddr4sdram_ex/imports/bd_2a05_second_lmb_bram_I_0.mem
    update_ip_catalog  >> $log_file

    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/src/ddr4_dimm_ad9v3.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/src/ddr4_dimm_ad9v3.sv]
  }
  if { ($fpga_card == "BW250SOC") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/src/ddr4_dimm_250soc.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/src/ddr4_dimm_250soc.sv]
  }
}

# Add IP
# SNAP CORE IP
puts "                        importing IP"
foreach ip_xci [glob -nocomplain -dir $ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        adding SNAP IP $ip_name"
  add_files -norecurse $ip_xci  -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -force >> $log_file
}
# HLS Action IP
foreach ip_xci [glob -nocomplain -dir $hls_ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        adding HLS Action IP $ip_name"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}
# HDL Action IP
foreach ip_xci [glob -nocomplain -dir $action_ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        adding HDL Action IP $ip_name"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}

foreach ip_bd [glob -nocomplain -dir $action_bd_dir */*.bd] {
  set bd_name [exec basename $ip_bd .bd]
  puts "                        adding HDL board design $bd_name"
  add_files -norecurse $ip_bd -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_bd"] -no_script -sync -force >> $log_file
}

# Add Ethernet IP
if { $eth_used == TRUE } {
  if { $eth_loop_back == TRUE } {
    puts "                        adding Ethernet loop back  (no MAC)"
  } else {
    puts "                        adding Ethernet block design"
    set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $ip_dir] [current_project] >> $log_file
    update_ip_catalog -rebuild -scan_changes >> $log_file

    # Commented below line for make model, uncomment for make image
    add_files -norecurse  $ip_dir/eth_100G/eth_100G.srcs/sources_1/bd/eth_100G/eth_100G.bd  >> $log_file
    export_ip_user_files -of_objects  [get_files  $ip_dir/eth_100G/eth_100G.srcs/sources_1/bd/eth_100G/eth_100G.bd] -no_script -sync -force -quiet >> $log_file
  }
}

# Add HBM
if { $hbm_used == TRUE } {
  #add_files -norecurse $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hdl/hbm_top_wrapper.vhd >> $log_file
  add_files -norecurse $ip_dir/hbm/hbm.gen/sources_1/bd/hbm_top/hdl/hbm_top_wrapper.vhd >> $log_file
  if { $bram_used == TRUE } {
    puts "                        adding HBM-like block design (BRAM)"
  } else {
    # if BRAM model used replacing HBM do not add specific hbm init files
    puts "                        adding HBM block design"
    puts "                        adding HBM initialization files "
    #add_files -norecurse $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_1.mem
    #add_files -norecurse $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_0.mem
    add_files -norecurse $ip_dir/hbm/hbm.gen/sources_1/bd/hbm_top/ip/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_1.mem
    add_files -norecurse $ip_dir/hbm/hbm.gen/sources_1/bd/hbm_top/ip/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_0.mem
    update_ip_catalog  >> $log_file
  }


  add_files -norecurse $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd  >> $log_file
  export_ip_user_files -of_objects  [get_files  $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -lib_map_path [list {{ies=$root_dir/viv_project/framework.cache/compile_simlib/ies}}] -no_script -sync -force -quiet

  #puts "                        adding HBM initialization files "
  # if BRAM model used to replace HBM then do not add specific hbm init files
  if { $bram_used != TRUE } {
    #import_files -fileset sim_1 -norecurse $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_sim_1.mem
    #import_files -fileset sim_1 -norecurse $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_sim_0.mem
    import_files -fileset sim_1 -norecurse $ip_dir/hbm/hbm.gen/sources_1/bd/hbm_top/ip/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_sim_1.mem
    import_files -fileset sim_1 -norecurse $ip_dir/hbm/hbm.gen/sources_1/bd/hbm_top/ip/hbm_top_hbm_0/hdl/rtl/xpm_internal_config_file_sim_0.mem
  }
  update_compile_order -fileset sim_1 >> $log_file
}

# Add OpenCAPI board support package

if { $unit_sim_used == "TRUE" } {
    puts "                        importing OpenCAPI BSP"
    puts "                        sourcing add_oc_bsp_unit_sim.tcl"
    source $root_dir/oc-bip/tcl/add_oc_bsp_unit_sim.tcl >> $log_file
} else {
    puts "                        importing OpenCAPI BSP"
    puts "                        sourcing add_oc_bsp.tcl"
    source $root_dir/oc-bip/tcl/add_oc_bsp.tcl >> $log_file
    # Add board specific IP
    foreach ip_xci [glob -nocomplain -dir $card_ip_dir */*.xci] {
      set ip_name [exec basename $ip_xci .xci]
      puts "                        adding IP $ip_name"
      add_files -norecurse   $ip_xci  -force >> $log_file
      set_property generate_synth_checkpoint false [get_files $ip_xci]
    }
}

if {$fpga_card == "BW250SOC"} {
  puts "                        adding Flash IP "
  #add_files $ip_dir/flash_ip_project/flash_ip_project.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd -norecurse  >> $log_file
  add_files -norecurse $ip_dir/flash_ip_project/flash_ip_project.srcs/sources_1/bd/design_1/design_1.bd  >> $log_file
  export_ip_user_files -of_objects  [get_files  $ip_dir/flash_ip_project/flash_ip_project.srcs/sources_1/bd/design_1/design_1.bd] -lib_map_path [list {{ies=$root_dir/viv_project/framework.cache/compile_simlib/ies}}] -no_script -sync -force -quiet
#  puts "                        adding  $fpga_card_dir/ip/qspi_mb.elf"
#  add_files -norecurse [get_files "$fpga_card_dir/ip/qspi_mb.elf"]
#  puts "                        setting prop1"
#  set_property SCOPED_TO_REF design_1 [get_files -all -of_objects [get_fileset sources_1] {$fpga_card_dir/ip/qspi_mb.elf}]
#  puts "                        setting prop2"
#  set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sources_1] {$fpga_card_dir/ip/qspi_mb.elf}]
}


# XDC
puts "                        importing other XDCs"

# Bitstream XDC
#  add_files -fileset constrs_1 -norecurse $top_xdc_dir/config_bitstream.xdc
# set false between action clock and snap clock if action clock frequency is different from snap clock
if { $user_clock == "TRUE" } {
  add_files -fileset constrs_1 -norecurse $root_dir/setup/snap_timing.xdc
  set_property used_in_synthesis true [get_files $root_dir/setup/snap_timing.xdc]
  set_property used_in_implementation true [get_files $root_dir/setup/snap_timing.xdc]
}

# DDR XDCs
if { ($fpga_card == "AD9V3") || ($fpga_card == "BW250SOC") } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $top_xdc_dir/snap_ddr4_b0pins.xdc 
    set_property used_in_synthesis false [get_files $top_xdc_dir/snap_ddr4_b0pins.xdc]
  }
}

# ETHERNET XDCs
if { $eth_used == "TRUE" } {
  if { $eth_loop_back == "FALSE" } {
    add_files -fileset constrs_1 -norecurse $top_xdc_dir/snap_ethernet_pins.xdc 
    set_property used_in_synthesis false [get_files $top_xdc_dir/snap_ethernet_pins.xdc]
  }
}

# HBM XDCs
if { $hbm_used == "TRUE" } {
  add_files -fileset constrs_1 -norecurse $top_xdc_dir/snap_hbm_timing.xdc
  set_property used_in_synthesis true [get_files $top_xdc_dir/snap_hbm_timing.xdc]
  set_property used_in_implementation true [get_files $top_xdc_dir/snap_hbm_timing.xdc]
}


if { $ila_debug == "TRUE" } {
  # Way1: Use ila_xdc
  if {[file exists $::env(ILA_SETUP_FILE)] } {
    add_files -fileset constrs_1 -norecurse $::env(ILA_SETUP_FILE)
  } else {
    puts "                        ignore \$ILA_SETUP_FILE: not provided or doesn't exist."
    puts "                         (using by default the extra.xdc file)"
  }

  # Way2: Instantiate ila cores
  #Currently the instantiated ila cores are only in verilog designs. 
  #hardware/Makefile handles the macro ILA_DEBUG in hardware/hdl/oc/snap_core_global_vars.v to turn it on/off
}

if { $unit_sim_used == "TRUE" } {
    puts "                        sourcing unit_sim.tcl"
    source $root_dir/setup/unit_sim.tcl >> $log_file
}

#
# update the compile order
update_compile_order >> $log_file

# create other implementation strategies. They are listed but will not automatically run
#source $root_dir/setup/create_other_strategy_impls.tcl
puts "\[CREATE_FRAMEWORK....\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
