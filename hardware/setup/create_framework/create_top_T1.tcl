set root_dir           $::env(OCACCEL_ROOT)
set hardware_dir       $::env(OCACCEL_HARDWARE_ROOT)

if { [info exists ::env(OCACCEL_HARDWARE_BUILD_DIR)] } { 
    set hardware_build_dir    $::env(OCACCEL_HARDWARE_BUILD_DIR)
} else {
    set hardware_build_dir    $hardware_dir
}

set fpga_part          $::env(FPGACHIP)
set fpga_card          $::env(FPGACARD)
set action_name        $::env(ACTION_NAME)
set kernels            $::env(KERNELS)
set kernel_number      $::env(KERNEL_NUMBER)
set project            "top_project"
set project_dir        $hardware_build_dir/output/$project

set kernel_ip_root  $hardware_build_dir/output/hls
set ip_repo_dir     $hardware_build_dir/output/ip_repo
set interfaces_dir  $hardware_build_dir/output/interfaces
set bd_name         "top"

source $hardware_dir/setup/common/common_funcs.tcl

create_project $project $project_dir -part $fpga_part -force
create_bd_design $bd_name

# Set up the ip_repos for this project
set_ip_repos $fpga_part $hardware_build_dir $kernel_ip_root $kernels

add_files -norecurse $hardware_dir/oc-accel-bsp/AD9V3/hdl/misc/iprog_icap.vhdl

# Add sub block designs
# act_wrap and infra_wrap
source $hardware_dir/setup/package_action/bd_action_template_A10.tcl
source $hardware_dir/setup/package_infrastructure/bd_infra_template_T1.tcl

# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:oc_host_if:1.0 oc_host_if
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:flash_vpd_wrapper:1.0 flash_vpd_wrapper
create_bd_cell -type module -reference iprog_icap iprog_icap


###############################################################################
# General Connections 
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_afu_tlx] [get_bd_intf_pins infra_wrap/opencapi30_c1/ocaccel_afu_tlx]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_vpd] [get_bd_intf_pins flash_vpd_wrapper/ocaccel_cfg_vpd]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_flsh] [get_bd_intf_pins flash_vpd_wrapper/ocaccel_cfg_flsh]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_tlx_afu] [get_bd_intf_pins infra_wrap/opencapi30_mmio/ocaccel_tlx_afu]
connect_bd_intf_net [get_bd_intf_pins oc_host_if/ocaccel_cfg_infra_c1] [get_bd_intf_pins infra_wrap/opencapi30_c1/ocaccel_cfg_infra_c1]
connect_bd_net [get_bd_pins oc_host_if/cfg_infra_f1_mmio_bar0] [get_bd_pins infra_wrap/opencapi30_mmio/cfg_f1_mmio_bar0]
connect_bd_net [get_bd_pins oc_host_if/cfg_infra_f1_mmio_bar0_mask] [get_bd_pins infra_wrap/opencapi30_mmio/cfg_f1_mmio_bar0_mask]
connect_bd_net [get_bd_pins oc_host_if/icap_clk] [get_bd_pins flash_vpd_wrapper/icap_clk]
connect_bd_net [get_bd_pins oc_host_if/icap_clk] [get_bd_pins iprog_icap/clk]
connect_bd_net [get_bd_pins oc_host_if/iprog_go_or] [get_bd_pins iprog_icap/go]

#TODO
#connect_bd_net [get_bd_pins infra_wrap/opencapi30_c1/interrupt_ack] [get_bd_pins act_wrap/kernel_wrap/interrupt_ack]
#connect_bd_net [get_bd_pins infra_wrap/opencapi30_c1/interrupt] [get_bd_pins act_wrap/kernel_wrap/interrupt]
#connect_bd_net [get_bd_pins infra_wrap/opencapi30_c1/interrupt_src] [get_bd_pins act_wrap/kernel_wrap/interrupt_src]
#connect_bd_net [get_bd_pins infra_wrap/opencapi30_c1/interrupt_ctx] [get_bd_pins act_wrap/kernel_wrap/interrupt_ctx]

# AXI Connections between infra_wrap and act_wrap
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    connect_bd_intf_net [get_bd_intf_pins infra_wrap/pin_aximm_slave$xx]    [get_bd_intf_pins act_wrap/pin_kernel${xx}_aximm]
    connect_bd_intf_net [get_bd_intf_pins infra_wrap/pin_axilite_master$xx] [get_bd_intf_pins act_wrap/pin_kernel${xx}_axilite]
}
#Clock and resets

connect_bd_net [get_bd_pins oc_host_if/clock_tlx] [get_bd_pins infra_wrap/pin_clock_tlx]
connect_bd_net [get_bd_pins oc_host_if/clock_tlx] [get_bd_pins flash_vpd_wrapper/clock_tlx]

connect_bd_net [get_bd_pins oc_host_if/clock_afu] [get_bd_pins infra_wrap/pin_clock_afu]
connect_bd_net [get_bd_pins oc_host_if/clock_afu] [get_bd_pins flash_vpd_wrapper/clock_afu]

connect_bd_net [get_bd_pins oc_host_if/reset_afu_n] [get_bd_pins infra_wrap/pin_reset_afu_n]
connect_bd_net [get_bd_pins oc_host_if/reset_afu_n] [get_bd_pins flash_vpd_wrapper/reset_afu_n]

connect_bd_net [get_bd_pins infra_wrap/pin_clock_action] [get_bd_pins act_wrap/pin_clock_action]
connect_bd_net [get_bd_pins infra_wrap/pin_reset_action_n] [get_bd_pins act_wrap/pin_reset_action_n]


###############################################################################
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

save_bd_design [current_bd_design]
###############################################################################
# Allocate Address automatically
assign_bd_address

# Include the 64b aximm space
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    include_bd_addr_seg [get_bd_addr_segs -excluded act_wrap/kernel${xx}_wrap/vadd/Data_m_axi_gmem/SEG_bridge_axi_slave_reg0]
    include_bd_addr_seg [get_bd_addr_segs -excluded act_wrap/kernel${xx}_wrap/vadd/Data_m_axi_gmem/SEG_kernel_helper_reg0]
}

# Give each Kernel 256KB (0x40000) register access space
# Assign the first one
set_property range  256K       [get_bd_addr_segs {infra_wrap/mmio_axilite_master/m_axi/SEG_kernel_helper_reg0}]
set_property offset 0x00000000 [get_bd_addr_segs {infra_wrap/mmio_axilite_master/m_axi/SEG_kernel_helper_reg0}]

# For the remaining kernels
if { $kernel_number > 1 } {
    for {set x 1} {$x < $kernel_number } {incr x} {
        set start_addr [ expr $x * 0x40000 ]
        set_property range  256K         [get_bd_addr_segs infra_wrap/mmio_axilite_master/m_axi/SEG_kernel_helper_reg0$x]
        set_property offset $start_addr  [get_bd_addr_segs infra_wrap/mmio_axilite_master/m_axi/SEG_kernel_helper_reg0$x]
    }
}


###############################################################################
# Save and Make wrapper
regenerate_bd_layout
validate_bd_design
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top -force
add_files -norecurse $project_dir/${project}.srcs/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

###############################################################################
# Add Constraints at last
# use bypass
# Is it a good way to organize like this?
#        $hardware_dir/oc-accel-bsp/$fpga_card/xdc/qspi_timing.xdc \
#
#
add_files -fileset constrs_1 -norecurse  [list \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/gty_properties.xdc \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/main_pinout.xdc \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/main_placement_bypass.xdc \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/main_timing.xdc \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/bitstream_config.xdc \
                                         $hardware_dir/oc-accel-bsp/$fpga_card/xdc/qspi_pinout.xdc \
                                         ] 

close_project
