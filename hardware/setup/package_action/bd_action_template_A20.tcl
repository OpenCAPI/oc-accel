set kernel_number $::env(KERNEL_NUMBER)
set kernel_name   $::env(KERNEL_NAME)
set hls_support   $::env(HLS_SUPPORT)
set axi_id_width  $::env(AXI_ID_WIDTH)

source $hardware_dir/setup/common/common_funcs.tcl
for {set x 1} {$x <= 8} {incr x} {
    set kernel_name_str(${x}) [ eval my_get_kernel_name_str $x $kernel_name ]
}

set bd_hier "act_wrap"
# Create BD Hier
create_bd_cell -type hier $bd_hier

###############################################################################
# Create Pins of this bd level
puts "kernel_number is $kernel_number"
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_kernel${xx}_aximm
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_kernel${xx}_axilite
    create_bd_pin -dir O $bd_hier/pin_kernel${xx}_done
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
add_files -norecurse $hardware_dir/hdl/action_wrapper/kernel_helper_A10.v

for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    set kernel_hier $bd_hier/kernel${xx}_wrap
    create_bd_cell -type hier $kernel_hier

    # Add kernel helper (a small module to handle interrupt src, etc)
    create_bd_cell -type module -reference kernel_helper $kernel_hier/kernel_helper
    for {set i 1} {$i <= 8} {incr i} {
        set prop_name [format "KERNEL_NAME_STR%d" $i]
        set_property CONFIG.${prop_name} $kernel_name_str($i) [get_bd_cells $kernel_hier/kernel_helper]
    }

    if { $hls_support == "TRUE" } {
        # Add kernel instance
        create_bd_cell -type ip -vlnv opencapi.org:ocaccel:${kernel_name}:1.0 $kernel_hier/${kernel_name}
        source $hardware_dir/setup/package_action/hls_action_parse.tcl


        # Add kernel smart connect
        create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $kernel_hier/smartconnect_hls
        set_property -dict [list CONFIG.NUM_SI ${num_kernel_axi_masters} \
                                 CONFIG.NUM_MI {1} ] \
                           [get_bd_cells $kernel_hier/smartconnect_hls]
        set_property -dict [list CONFIG.C_S_AXI_CONTROL_ADDR_WIDTH $kernel_axilite_addr_width] [get_bd_cells $kernel_hier/kernel_helper]
    } else { 
        # For hdl design
        create_bd_cell -type ip -vlnv opencapi.org:ocaccel:${kernel_name}:1.0 $kernel_hier/${kernel_name}

    }


    ###############################################################################
    # Create kernel_hier pins
    create_bd_pin -dir I $kernel_hier/pin_clock_kernel
    create_bd_pin -dir I $kernel_hier/reset_n
    create_bd_intf_pin -mode Master -vlnv opencapi.org:ocaccel:oc_interrupt_rtl:1.0 $kernel_hier/pin_kernel${xx}_interrupt

    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/axi_m
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/s_axilite
    
    connect_bd_net [get_bd_pins $bd_hier/pin_clock_action] [get_bd_pins $kernel_hier/pin_clock_kernel]
    connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n] [get_bd_pins $kernel_hier/reset_n]


    # Make connections inside kernel${xx}_wrap
    # Connect clock and reset -----------------
    if { $hls_support == "TRUE" } {
        connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_clock_pin_name}]
         connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_reset_pin_name}]
    } else {
        connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/${kernel_name}/clk]
        connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/${kernel_name}/resetn]
    }


    connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/kernel_helper/clk]
    connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/kernel_helper/resetn]
    
    if { $hls_support == "TRUE" } {
        connect_bd_net [get_bd_pins $kernel_hier/pin_clock_kernel] [get_bd_pins $kernel_hier/smartconnect_hls/aclk]
        connect_bd_net [get_bd_pins $kernel_hier/reset_n] [get_bd_pins $kernel_hier/smartconnect_hls/aresetn]
    }

    # Connect axilite -----------------
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/pin_kernel${xx}_axilite] [get_bd_intf_pins $kernel_hier/s_axilite]
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/s_axilite] [get_bd_intf_pins $kernel_hier/kernel_helper/s_axilite_i2h] 
    if { $hls_support == "TRUE" } {
        # The name is inferred from hls json
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/s_axilite_h2k] [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_axilite_name] 
    } else {
        # The name is fixed for HDL design
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/s_axilite_h2k] [get_bd_intf_pins $kernel_hier/${kernel_name}/s_axilite_cfg] 
    }


    # Connect aximm -----------------
    if { $hls_support == "TRUE" } {
        # Connect many aximm ports from the HLS kernel to smartconnect_hls 
        set axi_m_idx 0
        foreach m $kernel_axi_masters {
            set kernel_master_port_name [dict get $m port_prefix]
            set sc_id [format "%02d" $axi_m_idx]
            connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_hls/S${sc_id}_AXI] [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_master_port_name]
            incr axi_m_idx
        }
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_hls/M00_AXI] [get_bd_intf_pins $kernel_hier/kernel_helper/m_axi_k2h]
    } else {
        # HDL design doesn't use smartconnect, and the name if fixed as 'm_axi_gmem'
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/$kernel_name/m_axi_gmem] [get_bd_intf_pins $kernel_hier/kernel_helper/m_axi_k2h]
    }

    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/m_axi_h2i] [get_bd_intf_pins $kernel_hier/axi_m]
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/axi_m] [get_bd_intf_pins $bd_hier/pin_kernel${xx}_aximm]

    # Connect interrupt -----------------
    connect_bd_net [get_bd_pins $kernel_hier/${kernel_name}/interrupt] [get_bd_pins $kernel_hier/kernel_helper/interrupt_i]
    connect_bd_net [get_bd_pins $kernel_hier/${kernel_name}/interrupt] [get_bd_pins $bd_hier/pin_kernel${xx}_done]

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
