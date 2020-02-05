
set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set fpga_part        $::env(FPGACHIP)
set project "viv_project"
set project_dir      $root_dir/build/$project

set ip_repo_dir     $root_dir/ip_repo
set interfaces_dir  $root_dir/interfaces
set bd_name         "top"

create_project $project $project_dir -part $fpga_part
create_bd_design $bd_name
set_property  ip_repo_paths  [list $ip_repo_dir $interfaces_dir] [current_project]
update_ip_catalog
add_files -norecurse $root_dir/oc-accel-bsp/AD9V3/hdl/misc/iprog_icap.vhdl

# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:A1:1.0 A1_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:T1:1.0 T1_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:oc_host_if:1.0 oc_host_if_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:flash_vpd_wrapper:1.0 flash_vpd_wrapper_0
create_bd_cell -type module -reference iprog_icap iprog_icap_0

# Connections
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_tlx_afu] [get_bd_intf_pins T1_0/ocaccel_tlx_afu_0]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_infra_c1] [get_bd_intf_pins T1_0/ocaccel_cfg_infra_c1_0]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins T1_0/clock_afu]
connect_bd_net [get_bd_pins oc_host_if_0/clock_tlx] [get_bd_pins T1_0/clock_tlx]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins T1_0/rst_n]
connect_bd_net [get_bd_pins oc_host_if_0/cfg_infra_f1_mmio_bar0] [get_bd_pins T1_0/cfg_f1_mmio_bar0_0]
connect_bd_net [get_bd_pins oc_host_if_0/cfg_infra_f1_mmio_bar0_mask] [get_bd_pins T1_0/cfg_f1_mmio_bar0_mask_0]
connect_bd_net [get_bd_pins oc_host_if_0/icap_clk] [get_bd_pins flash_vpd_wrapper_0/icap_clk]
connect_bd_net [get_bd_pins oc_host_if_0/icap_clk] [get_bd_pins iprog_icap_0/clk]
connect_bd_net [get_bd_pins oc_host_if_0/iprog_go_or] [get_bd_pins iprog_icap_0/go]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins flash_vpd_wrapper_0/reset_afu_n]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins flash_vpd_wrapper_0/clock_afu]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_flsh] [get_bd_intf_pins flash_vpd_wrapper_0/ocaccel_cfg_flsh]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_vpd] [get_bd_intf_pins flash_vpd_wrapper_0/ocaccel_cfg_vpd]
connect_bd_intf_net [get_bd_intf_pins T1_0/m_axi_0] [get_bd_intf_pins A1_0/s_axi_ctrl_reg_0]
connect_bd_intf_net [get_bd_intf_pins A1_0/m_axi_host_mem_0] [get_bd_intf_pins T1_0/s_axi_0]
connect_bd_net [get_bd_pins A1_0/ap_clk] [get_bd_pins oc_host_if_0/clock_afu]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_afu_tlx] [get_bd_intf_pins T1_0/ocaccel_afu_tlx_0]
connect_bd_net [get_bd_pins T1_0/interrupt_ack_0] [get_bd_pins A1_0/interrupt_ack_0]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins A1_0/ap_rst_n_0]
connect_bd_net [get_bd_pins A1_0/interrupt_0] [get_bd_pins T1_0/interrupt_0]
connect_bd_net [get_bd_pins A1_0/interrupt_ctx_0] [get_bd_pins T1_0/interrupt_ctx_0]
connect_bd_net [get_bd_pins A1_0/interrupt_src_0] [get_bd_pins T1_0/interrupt_src_0]

# Create Ports
create_bd_intf_port -mode Slave -vlnv opencapi.org:ocaccel:oc_phy_rtl:1.0 ocaccel_oc_phy
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_oc_phy] [get_bd_intf_ports ocaccel_oc_phy]
create_bd_port -dir IO FPGA_FLASH_CE2_L
connect_bd_net [get_bd_pins /flash_vpd_wrapper_0/FPGA_FLASH_CE2_L] [get_bd_ports FPGA_FLASH_CE2_L]
create_bd_port -dir IO FPGA_FLASH_DQ4
connect_bd_net [get_bd_pins /flash_vpd_wrapper_0/FPGA_FLASH_DQ4] [get_bd_ports FPGA_FLASH_DQ4]
create_bd_port -dir IO FPGA_FLASH_DQ5
connect_bd_net [get_bd_pins /flash_vpd_wrapper_0/FPGA_FLASH_DQ5] [get_bd_ports FPGA_FLASH_DQ5]
create_bd_port -dir IO FPGA_FLASH_DQ6
connect_bd_net [get_bd_pins /flash_vpd_wrapper_0/FPGA_FLASH_DQ6] [get_bd_ports FPGA_FLASH_DQ6]
create_bd_port -dir IO FPGA_FLASH_DQ7
connect_bd_net [get_bd_pins /flash_vpd_wrapper_0/FPGA_FLASH_DQ7] [get_bd_ports FPGA_FLASH_DQ7]
create_bd_port -dir I ocde
connect_bd_net [get_bd_pins /oc_host_if_0/ocde] [get_bd_ports ocde]


# Save and Make wrapper
regenerate_bd_layout
validate_bd_design
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name/bd] -top

# Do we need to add constraint files here? 
# They are already added when building IPs
#add_files -fileset constrs_1 -norecurse {$root_dir/oc-accel-bsp/AD9V3/xdc/gty_properties.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/main_pinout.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/main_placement_bypass.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/main_placement_elastic.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/main_timing.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/qspi_pinout.xdc \
# $root_dir/oc-accel-bsp/AD9V3/xdc/qspi_timing.xdc}

close_project
