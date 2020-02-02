
set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set fpga_part        $::env(FPGACHIP)
set project "opencapi30_minimum"
set project_dir      $root_dir/temp_bd/$project

set ip_repo_dir     $root_dir/ip_repo
set interfaces_dir  $root_dir/interfaces
set bd_name         "T1"

create_project $project $project_dir -part $fpga_part
create_bd_design $bd_name
set_property  ip_repo_paths  [list $ip_repo_dir $interfaces_dir] [current_project]
update_ip_catalog
add_files -norecurse $root_dir/oc-accel-bsp/AD9V3/hdl/misc/iprog_icap.vhdl

# Add IPs
startgroup
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:oc_host_if:1.0 oc_host_if_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:bridge_axi_slave:1.0 bridge_axi_slave_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:data_bridge:1.0 data_bridge_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:mmio_axilite_master:1.0 mmio_axilite_master_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_c1:1.0 opencapi30_c1_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_mmio:1.0 opencapi30_mmio_0
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:flash_vpd_wrapper:1.0 flash_vpd_wrapper_0
create_bd_cell -type module -reference iprog_icap iprog_icap_0
endgroup

# Make external pins
startgroup
make_bd_intf_pins_external  [get_bd_intf_pins oc_host_if_0/ocaccel_oc_phy]
make_bd_pins_external  [get_bd_pins flash_vpd_wrapper_0/FPGA_FLASH_CE2_L]
make_bd_pins_external  [get_bd_pins flash_vpd_wrapper_0/FPGA_FLASH_DQ4]
make_bd_pins_external  [get_bd_pins flash_vpd_wrapper_0/FPGA_FLASH_DQ5]
make_bd_pins_external  [get_bd_pins flash_vpd_wrapper_0/FPGA_FLASH_DQ6]
make_bd_pins_external  [get_bd_pins flash_vpd_wrapper_0/FPGA_FLASH_DQ7]
make_bd_pins_external  [get_bd_pins oc_host_if_0/ocde]
# To Action Wrapper
make_bd_intf_pins_external  [get_bd_intf_pins mmio_axilite_master_0/m_axi]
make_bd_intf_pins_external  [get_bd_intf_pins bridge_axi_slave_0/s_axi]
make_bd_pins_external  [get_bd_pins mmio_axilite_master_0/soft_reset_action]
make_bd_pins_external  [get_bd_pins opencapi30_c1_0/interrupt]
make_bd_pins_external  [get_bd_pins opencapi30_c1_0/interrupt_src]
make_bd_pins_external  [get_bd_pins opencapi30_c1_0/interrupt_ctx]
make_bd_pins_external  [get_bd_pins opencapi30_c1_0/interrupt_ack]
endgroup


# Address 
assign_bd_address [get_bd_addr_segs {bridge_axi_slave_0/s_axi/reg0 }]

# Make connections
connect_bd_net [get_bd_pins opencapi30_c1_0/debug_bus] [get_bd_pins mmio_axilite_master_0/debug_bus_trans_protocol]
connect_bd_intf_net [get_bd_intf_pins opencapi30_mmio_0/ocaccel_mmio] [get_bd_intf_pins mmio_axilite_master_0/ocaccel_mmio]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_tlx_afu] [get_bd_intf_pins opencapi30_mmio_0/ocaccel_tlx_afu]
connect_bd_intf_net [get_bd_intf_pins data_bridge_0/ocaccel_dma_wr] [get_bd_intf_pins opencapi30_c1_0/ocaccel_dma_wr]
connect_bd_intf_net [get_bd_intf_pins data_bridge_0/ocaccel_dma_rd] [get_bd_intf_pins opencapi30_c1_0/ocaccel_dma_rd]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave_0/ocaccel_lcl_wr] [get_bd_intf_pins data_bridge_0/ocaccel_lcl_wr]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave_0/ocaccel_lcl_rd] [get_bd_intf_pins data_bridge_0/ocaccel_lcl_rd]
connect_bd_intf_net [get_bd_intf_pins opencapi30_c1_0/ocaccel_afu_tlx] [get_bd_intf_pins oc_host_if_0/ocaccel_afu_tlx]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_infra_c1] [get_bd_intf_pins opencapi30_c1_0/ocaccel_cfg_infra_c1]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_afu_tlx] [get_bd_intf_pins opencapi30_c1_0/ocaccel_afu_tlx]

connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_flsh] [get_bd_intf_pins flash_vpd_wrapper_0/ocaccel_cfg_flsh]
connect_bd_intf_net [get_bd_intf_pins oc_host_if_0/ocaccel_cfg_vpd] [get_bd_intf_pins flash_vpd_wrapper_0/ocaccel_cfg_vpd]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins flash_vpd_wrapper_0/clock_afu]
connect_bd_net [get_bd_pins oc_host_if_0/icap_clk] [get_bd_pins flash_vpd_wrapper_0/icap_clk]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins flash_vpd_wrapper_0/reset_afu_n]

connect_bd_net [get_bd_pins oc_host_if_0/cfg_infra_f1_mmio_bar0] [get_bd_pins opencapi30_mmio_0/cfg_f1_mmio_bar0]
connect_bd_net [get_bd_pins oc_host_if_0/cfg_infra_f1_mmio_bar0_mask] [get_bd_pins opencapi30_mmio_0/cfg_f1_mmio_bar0_mask]
connect_bd_net [get_bd_pins oc_host_if_0/clock_tlx] [get_bd_pins opencapi30_mmio_0/clk_tlx]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins opencapi30_mmio_0/clk_afu]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins opencapi30_mmio_0/rst_n]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins mmio_axilite_master_0/clk]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins mmio_axilite_master_0/rst_n]

connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins opencapi30_c1_0/clk_afu]
connect_bd_net [get_bd_pins oc_host_if_0/clock_tlx] [get_bd_pins opencapi30_c1_0/clk_tlx]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins opencapi30_c1_0/rst_n]
connect_bd_net [get_bd_pins mmio_axilite_master_0/debug_info_clear] [get_bd_pins opencapi30_c1_0/debug_info_clear]
connect_bd_net [get_bd_pins bridge_axi_slave_0/lcl_wr_ctx_valid] [get_bd_pins opencapi30_c1_0/lcl_wr_ctx_valid]
connect_bd_net [get_bd_pins bridge_axi_slave_0/lcl_rd_ctx_valid] [get_bd_pins opencapi30_c1_0/lcl_rd_ctx_valid]
connect_bd_net [get_bd_pins bridge_axi_slave_0/lcl_wr_ctx] [get_bd_pins opencapi30_c1_0/lcl_wr_ctx]
connect_bd_net [get_bd_pins bridge_axi_slave_0/lcl_rd_ctx] [get_bd_pins opencapi30_c1_0/lcl_rd_ctx]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave_0/ocaccel_lcl_rd] [get_bd_intf_pins data_bridge_0/ocaccel_lcl_rd]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins data_bridge_0/clk]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins data_bridge_0/rst_n]
connect_bd_net [get_bd_pins oc_host_if_0/clock_afu] [get_bd_pins bridge_axi_slave_0/clk]
connect_bd_net [get_bd_pins oc_host_if_0/reset_afu_n] [get_bd_pins bridge_axi_slave_0/rst_n]
connect_bd_net [get_bd_pins data_bridge_0/debug_bus] [get_bd_pins mmio_axilite_master_0/debug_bus_data_bridge]
connect_bd_net [get_bd_pins data_bridge_0/last_context_cleared] [get_bd_pins opencapi30_c1_0/last_context_cleared]
connect_bd_net [get_bd_pins data_bridge_0/context_update_ongoing] [get_bd_pins opencapi30_c1_0/context_update_ongoing]

connect_bd_net [get_bd_pins oc_host_if_0/iprog_go_or] [get_bd_pins iprog_icap_0/go]
connect_bd_net [get_bd_pins oc_host_if_0/icap_clk] [get_bd_pins iprog_icap_0/clk]

# Save and Make wrapper
regenerate_bd_layout
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name/bd] -top
