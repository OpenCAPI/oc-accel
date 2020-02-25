set kernel_number $::env(KERNEL_NUMBER)
set kernel_name   $::env(KERNEL_NAME)
set hls_support   $::env(HLS_SUPPORT)
set axi_id_width  $::env(AXI_ID_WIDTH)

set bd_hier "act_wrap"
# Create BD Hier
create_bd_cell -type hier $bd_hier

###############################################################################
# Create Pins of this bd level
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_kernel${xx}_aximm
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_kernel${xx}_axilite
}

create_bd_pin -dir I $bd_hier/pin_clock_action
create_bd_pin -dir I $bd_hier/pin_reset_action_n

#set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_pins $bd_hier/pin_reset_action_n]

###############################################################################
# Add kernel wrappers
#
# Note: This example inserts idential kernel_wraps. 
# If different kernels are used, please modify accordingly
#
#add_files -norecurse $hardware_dir/hdl/action_wrap/kernel_helper.v

for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    set kernel_hier $bd_hier/kernel${xx}_wrap
    create_bd_cell -type hier $kernel_hier

    # Add kernel instance
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:${kernel_name}:1.0 $kernel_hier/${kernel_name}

    # Add kernel helper (a small module to handle interrupt src, etc)
    #create_bd_cell -type module -reference kernel_helper $bd_hier/kernel${xx}_wrap/kernel_helper

    if { $hls_support == "TRUE" } {
        source $hardware_dir/setup/package_action/hls_action_parse.tcl
        create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $kernel_hier/smartconnect_0

        set_property -dict [list CONFIG.NUM_SI ${num_kernel_axi_masters} \
                                 CONFIG.NUM_MI {1} ] \
                           [get_bd_cells $kernel_hier/smartconnect_0]
    }

    # Make connections inside kernel${xx}_wrap
    create_bd_pin -dir I $kernel_hier/pin_clock_kernel
    create_bd_pin -dir I $kernel_hier/reset_n
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/axi_m
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/axilite_s

    connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_clock_pin_name}]
    connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/smartconnect_0/aclk]
    connect_bd_net [get_bd_pins $bd_hier/pin_clock_action] [get_bd_pins $kernel_hier/pin_clock_kernel]

    connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_reset_pin_name}]
    connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/smartconnect_0/aresetn]
    connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n] [get_bd_pins $kernel_hier/reset_n]

    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_axilite_name] [get_bd_intf_pins $kernel_hier/axilite_s]
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/axilite_s] [get_bd_intf_pins $bd_hier/pin_kernel${xx}_axilite]

    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_0/M00_AXI] [get_bd_intf_pins $kernel_hier/axi_m]
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/axi_m] [get_bd_intf_pins $bd_hier/pin_kernel${xx}_aximm]

    set axi_m_idx 0
    foreach m $kernel_axi_masters {
        set kernel_master_port_name [dict get $m port_prefix]
        set sc_id [format "%02d" $axi_m_idx]
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_0/S${sc_id}_AXI] [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_master_port_name]

        # Enable AXI ID and AXI USER ports for each AXI master interface
        set_property -dict [list \
                            CONFIG.C_${kernel_master_port_name}_ENABLE_USER_PORTS {true} \
                           ] \
                           [get_bd_cells $kernel_hier/${kernel_name}]

        # USER WIDTH -> 9
        # ID WIDTH -> set by the environment in ::env(AXI_ID_WIDTH)
        set_property -dict [list \
                            CONFIG.C_${kernel_master_port_name}_AWUSER_WIDTH {9} \
                            CONFIG.C_${kernel_master_port_name}_ARUSER_WIDTH {9} \
                            CONFIG.C_${kernel_master_port_name}_WUSER_WIDTH  {9} \
                            CONFIG.C_${kernel_master_port_name}_RUSER_WIDTH  {9} \
                            CONFIG.C_${kernel_master_port_name}_BUSER_WIDTH  {9} \
                           ] \
                           [get_bd_cells $kernel_hier/${kernel_name}]
        incr axi_m_idx
    }
}

#assign_bd_address [get_bd_addr_segs {act_wrap/kernel_wrap/s_axi_ctrl_reg/reg0 }]


###############################################################################
# Place holder: 
# SmartConnect for perhiperals




###############################################################################
# Place holder: 
# Peripheral Controllers





###############################################################################
# Make **internal** connections under action_wrap hierarchy
# TODO
