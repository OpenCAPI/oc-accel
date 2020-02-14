############################################################################
############################################################################
##
## Copyright 2020 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################
set fpga_card      $::env(FPGACARD)
set root_dir       $::env(OCACCEL_HARDWARE_ROOT)
set simulator      $::env(SIMULATOR)
set fpga_card_dir  $root_dir/oc-accel-bsp/$fpga_card

set host_if_dir  $root_dir/hdl/host_interface_opencapi30
set dlx_dir      $root_dir/hdl/host_interface_opencapi30/dlx
set tlx_dir      $root_dir/hdl/host_interface_opencapi30/tlx
set cfg_dir      $root_dir/hdl/host_interface_opencapi30/config_subsystem
set xdc_dir      $fpga_card_dir/xdc


set transceiver_type   "bypass"
set transceiver_speed  $::env(PHY_SPEED)


############################################################################
#    Print information
puts "transceiver type=$transceiver_type, speed=$transceiver_speed"



############################################################################
#    Prepare files and contraints
set verilog_DLx   [list \
 $dlx_dir/ocx_bram_infer.v \
 $dlx_dir/ocx_dlx_crc.v \
 $dlx_dir/ocx_dlx_rx_lane.v \
 $dlx_dir/ocx_dlx_rx_lane_66.v \
 $dlx_dir/ocx_dlx_rx_main.v \
 $dlx_dir/ocx_dlx_rxdf.v \
 $dlx_dir/ocx_dlx_top.v \
 $dlx_dir/ocx_dlx_tx_ctl.v \
 $dlx_dir/ocx_dlx_tx_flt.v \
 $dlx_dir/ocx_dlx_tx_gbx.v \
 $dlx_dir/ocx_dlx_tx_que.v \
 $dlx_dir/ocx_dlx_txdf.v \
 $dlx_dir/ocx_dlx_xlx_if.v \
]
set verilog_TLx   [list \
 $tlx_dir/bram_syn_test.v \
 $tlx_dir/dram_syn_test.v \
 $tlx_dir/ocx_leaf_inferd_regfile.v \
 $tlx_dir/ocx_tlx_513x32_fifo.v \
 $tlx_dir/ocx_tlx_514x16_fifo.v \
 $tlx_dir/ocx_tlx_bdi_mac.v \
 $tlx_dir/ocx_tlx_cfg_mac.v \
 $tlx_dir/ocx_tlx_cmd_fifo_mac.v \
 $tlx_dir/ocx_tlx_ctl_fsm.v \
 $tlx_dir/ocx_tlx_data_arb.v \
 $tlx_dir/ocx_tlx_data_fifo_mac.v \
 $tlx_dir/ocx_tlx_dcp_fifo_ctl.v \
 $tlx_dir/ocx_tlx_fifo_cntlr.v \
 $tlx_dir/ocx_tlx_flit_parser.v \
 $tlx_dir/ocx_tlx_framer.v \
 $tlx_dir/ocx_tlx_framer_cmd_fifo.v \
 $tlx_dir/ocx_tlx_framer_rsp_fifo.v \
 $tlx_dir/ocx_tlx_parse_mac.v \
 $tlx_dir/ocx_tlx_parser_err_mac.v \
 $tlx_dir/ocx_tlx_rcv_mac.v \
 $tlx_dir/ocx_tlx_rcv_top.v \
 $tlx_dir/ocx_tlx_resp_fifo_mac.v \
 $tlx_dir/ocx_tlx_top.v \
 $tlx_dir/ocx_tlx_vc0_fifo_ctl.v \
 $tlx_dir/ocx_tlx_vc1_fifo_ctl.v \
]

set verilog_cfg [list \
 $cfg_dir/cfg_cmdfifo.v \
 $cfg_dir/cfg_descriptor.v \
 $cfg_dir/cfg_fence.v \
 $cfg_dir/cfg_func1_init.v \
 $cfg_dir/cfg_func1.v \
 $cfg_dir/cfg_func0_init.v \
 $cfg_dir/cfg_func0.v \
 $cfg_dir/cfg_respfifo.v \
 $cfg_dir/cfg_seq.v \
 $fpga_card_dir/hdl/opencapi30/cfg_cardinfo/cfg_tieoffs.v \
 $cfg_dir/oc_cfg.v \
]


set verilog_bypass  [list \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_bit_sync.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_gtwiz_userclk_tx.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_init.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_reset_sync.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_wrapper_functions.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_wrapper.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_gtwiz_buffbypass_rx.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_gtwiz_buffbypass_tx.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_gtwiz_reset.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/dlx_phy_wrap.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/tx_mod_da_fsm.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/drp_read_modify_write.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_buffer_bypass/DLx_phy_example_reset_inv_sync.v \
]
set verilog_elastic [list \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_bit_sync.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_gtwiz_userclk_tx.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_init.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_reset_sync.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_wrapper_functions.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/DLx_phy_example_wrapper.v \
 $fpga_card_dir/hdl/opencapi30/xilinx_dlx_phy_wrap/encrypted_elastic_buffer/dlx_phy_wrap.v \
]

set verilog_host_if [list \
  $host_if_dir/oc_afu_cfg_only.v \
  $host_if_dir/oc_function_cfg_only.v \
  $host_if_dir/oc_host_if.v \
]

if {$transceiver_type eq "bypass"} {
  set phy_package [list {*}$verilog_bypass]
} else {
  set phy_package [list {*}$verilog_elastic]
}


############################################################################
#Add source files
puts "	        Adding design sources to oc_host_if project"
# Set 'sources_1' fileset object, create list of all nececessary verilog files
set obj [get_filesets sources_1]
set files [list {*}$verilog_DLx {*}$verilog_TLx {*}$phy_package {*}$verilog_cfg {*}$verilog_host_if ]

add_files -norecurse -fileset $obj $files

# deal with header files
set file "DLx_phy_example_wrapper_functions.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func1_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "cfg_func0_init.v"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

if { $simulator != "nosim" } {
  puts "	        Simulation with $simulator enabled, adding $host_if_dir/sim_only/oc_host_if.sv"
  add_files -norecurse -fileset sim_1 $host_if_dir/sim_only/oc_host_if.sv
}

foreach f $phy_package {
  # Phy will only be used in synthesis and implementation
  set_property used_in_simulation     false [get_files $f]
}

foreach f $verilog_DLx {
  # Phy will only be used in synthesis and implementation
  set_property used_in_simulation     false [get_files $f]
}

foreach f $verilog_TLx {
  # Phy will only be used in synthesis and implementation
  set_property used_in_simulation     false [get_files $f]
}

set_property used_in_synthesis      true  [get_files $host_if_dir/oc_host_if.v]
set_property used_in_implementation true  [get_files $host_if_dir/oc_host_if.v]
set_property used_in_simulation     false [get_files $host_if_dir/oc_host_if.v]
if { $simulator != "nosim" } {
  set_property used_in_synthesis      false [get_files $host_if_dir/sim_only/oc_host_if.sv]
  set_property used_in_implementation false [get_files $host_if_dir/sim_only/oc_host_if.sv]
  set_property used_in_simulation     true  [get_files $host_if_dir/sim_only/oc_host_if.sv]
}

#move_files -fileset sim_1 [get_files $host_if_dir/sim_only/oc_host_if.sv]

############################################################################
# Add constraint files
# only add PHY related 
#set xdc_files [list \
#             $xdc_dir/main_pinout.xdc  \
#             $xdc_dir/main_timing.xdc  \
#             $xdc_dir/extra.xdc  \
#           ]

#if {$transceiver_type eq "bypass" } {
#  set xdc_files [list {*}$xdc_files \
#             $xdc_dir/main_placement_bypass.xdc  \
#             $xdc_dir/gty_properties.xdc  \
#           ]
#} else {
#  set xdc_files [list {*}$xdc_files \
#             $xdc_dir/main_placement_elastic.xdc  \
#           ]
#}
##
##
#puts "	        Adding constraints to oc_host_if project"
#set obj [get_filesets constrs_1]
#add_files -fileset constrs_1 -norecurse $xdc_files
#set_property -name "target_constrs_file" -value $xdc_dir/extra.xdc  -objects $obj

############################################################################
set synth_verilog_defines ""
if {$transceiver_type  eq "bypass" } {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_BYPASS"]}
if {$transceiver_type  eq "elastic"} {set synth_verilog_defines [concat $synth_verilog_defines "BUFFER_ELASTIC"]}
set_property verilog_define "$synth_verilog_defines" [get_filesets sources_1]
#set_property verilog_define "$synth_verilog_defines" [get_filesets sim_1]


############################################################################
# Generate board specific IP
#
source $fpga_card_dir/tcl/create_vio_DLx_phy_vio_0.tcl
source $fpga_card_dir/tcl/create_vio_reset_n.tcl
source $fpga_card_dir/tcl/create_DLx_PHY_${transceiver_type}_${transceiver_speed}g.tcl

set_property top oc_host_if [get_filesets sources_1]
set_property top oc_host_if [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
