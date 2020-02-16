
set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set fpga_part        $::env(FPGACHIP)
set fpga_card        $::env(FPGACARD)
set project "top_project"
set project_dir      $root_dir/build/$project

set ip_repo_dir     $root_dir/build/ip_repo
set interfaces_dir  $root_dir/build/interfaces
set bd_name         "top"

create_project $project $project_dir -part $fpga_part -force
create_bd_design $bd_name
set_property  ip_repo_paths  [list $ip_repo_dir $interfaces_dir] [current_project]
update_ip_catalog
add_files -norecurse $root_dir/oc-accel-bsp/AD9V3/hdl/misc/iprog_icap.vhdl


# Add sub block designs
# bd_act and bd_infra
source $root_dir/setup/package_action/bd_action_template_A10.tcl
source $root_dir/setup/package_infrastructure/bd_infra_template_T1.tcl

# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:oc_host_if:1.0 oc_host_if
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:flash_vpd_wrapper:1.0 flash_vpd_wrapper
create_bd_cell -type module -reference iprog_icap iprog_icap


# Connections 
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_afu_tlx] [get_bd_intf_pins bd_infra/opencapi30_c1/ocaccel_afu_tlx]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_vpd] [get_bd_intf_pins flash_vpd_wrapper/ocaccel_cfg_vpd]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_flsh] [get_bd_intf_pins flash_vpd_wrapper/ocaccel_cfg_flsh]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_tlx_afu] [get_bd_intf_pins bd_infra/opencapi30_mmio/ocaccel_tlx_afu]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_infra_c1] [get_bd_intf_pins bd_infra/opencapi30_c1/ocaccel_cfg_infra_c1]
connect_bd_net [get_bd_pins oc_host_if/cfg_infra_f1_mmio_bar0] [get_bd_pins bd_infra/opencapi30_mmio/cfg_f1_mmio_bar0]
connect_bd_net [get_bd_pins oc_host_if/cfg_infra_f1_mmio_bar0_mask] [get_bd_pins bd_infra/opencapi30_mmio/cfg_f1_mmio_bar0_mask]
connect_bd_net [get_bd_pins oc_host_if/icap_clk] [get_bd_pins flash_vpd_wrapper/icap_clk]
connect_bd_net [get_bd_pins oc_host_if/icap_clk] [get_bd_pins iprog_icap/clk]
connect_bd_net [get_bd_pins oc_host_if/iprog_go_or] [get_bd_pins iprog_icap/go]

connect_bd_net [get_bd_pins bd_infra/opencapi30_c1/interrupt_ack] [get_bd_pins bd_act/action_wrapper/interrupt_ack]
connect_bd_net [get_bd_pins bd_infra/opencapi30_c1/interrupt] [get_bd_pins bd_act/action_wrapper/interrupt]
connect_bd_net [get_bd_pins bd_infra/opencapi30_c1/interrupt_src] [get_bd_pins bd_act/action_wrapper/interrupt_src]
connect_bd_net [get_bd_pins bd_infra/opencapi30_c1/interrupt_ctx] [get_bd_pins bd_act/action_wrapper/interrupt_ctx]

connect_bd_intf_net [get_bd_intf_pins bd_infra/bridge_axi_slave/s_axi] [get_bd_intf_pins bd_act/action_wrapper/m_axi_host_mem]
connect_bd_intf_net [get_bd_intf_pins bd_infra/mmio_axilite_master/m_axi] [get_bd_intf_pins bd_act/action_wrapper/s_axi_ctrl_reg]

#Clock and resets

connect_bd_net [get_bd_pins oc_host_if/clock_tlx] [get_bd_pins bd_infra/opencapi30_mmio/clock_tlx]
connect_bd_net [get_bd_pins oc_host_if/clock_tlx] [get_bd_pins flash_vpd_wrapper/clock_tlx]

connect_bd_net [get_bd_pins oc_host_if/clock_afu] [get_bd_pins bd_act/action_wrapper/clk]
connect_bd_net [get_bd_pins oc_host_if/clock_afu] [get_bd_pins bd_infra/opencapi30_mmio/clock_afu]
connect_bd_net [get_bd_pins oc_host_if/clock_afu] [get_bd_pins flash_vpd_wrapper/clock_afu]

connect_bd_net [get_bd_pins oc_host_if/reset_afu_n] [get_bd_pins flash_vpd_wrapper/reset_afu_n]
connect_bd_net [get_bd_pins oc_host_if/reset_afu_n] [get_bd_pins bd_infra/opencapi30_mmio/resetn]
connect_bd_net [get_bd_pins oc_host_if/reset_afu_n] [get_bd_pins bd_act/action_wrapper/resetn]


# Create Ports
create_bd_intf_port -mode Slave -vlnv opencapi.org:ocaccel:oc_phy_rtl:1.0 ocaccel_oc_phy
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_oc_phy] [get_bd_intf_ports ocaccel_oc_phy]
create_bd_port -dir IO FPGA_FLASH_CE2_L
connect_bd_net [get_bd_pins /flash_vpd_wrapper/FPGA_FLASH_CE2_L] [get_bd_ports FPGA_FLASH_CE2_L]
create_bd_port -dir IO FPGA_FLASH_DQ4
connect_bd_net [get_bd_pins /flash_vpd_wrapper/FPGA_FLASH_DQ4] [get_bd_ports FPGA_FLASH_DQ4]
create_bd_port -dir IO FPGA_FLASH_DQ5
connect_bd_net [get_bd_pins /flash_vpd_wrapper/FPGA_FLASH_DQ5] [get_bd_ports FPGA_FLASH_DQ5]
create_bd_port -dir IO FPGA_FLASH_DQ6
connect_bd_net [get_bd_pins /flash_vpd_wrapper/FPGA_FLASH_DQ6] [get_bd_ports FPGA_FLASH_DQ6]
create_bd_port -dir IO FPGA_FLASH_DQ7
connect_bd_net [get_bd_pins /flash_vpd_wrapper/FPGA_FLASH_DQ7] [get_bd_ports FPGA_FLASH_DQ7]
create_bd_port -dir I ocde
connect_bd_net [get_bd_pins /oc_host_if/ocde] [get_bd_ports ocde]

assign_bd_address [get_bd_addr_segs {bd_infra/bridge_axi_slave/s_axi/reg0 }]
assign_bd_address [get_bd_addr_segs {bd_act/action_wrapper/s_axi_ctrl_reg/reg0 }]

# Save and Make wrapper
regenerate_bd_layout
validate_bd_design
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top -force
add_files -norecurse $project_dir/${project}.srcs/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

# use bypass
# Is it a good way to organize like this?
#        $root_dir/oc-accel-bsp/$fpga_card/xdc/qspi_timing.xdc \
#
#
add_files -fileset constrs_1 -norecurse  [list \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/gty_properties.xdc \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/main_pinout.xdc \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/main_placement_bypass.xdc \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/main_timing.xdc \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/bitstream_config.xdc \
                                         $root_dir/oc-accel-bsp/$fpga_card/xdc/qspi_pinout.xdc \
                                         ] 

close_project
