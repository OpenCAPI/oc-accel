set engine_number $::env(ENGINE_NUMBER)
set kernel_name   $::env(KERNEL_NAME)
set hls_support   $::env(HLS_SUPPORT)

set bd_hier "action_wrapper"
# Create BD Hier
create_bd_cell -type hier $bd_hier

###############################################################################
# Create Pins of this bd level
for {set x 0} {$x < $engine_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_eng${xx}_aximm
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_eng${xx}_axilite
}

create_bd_pin -dir I $bd_hier/pin_clock_action
create_bd_pin -dir I $bd_hier/pin_reset_action_n

#set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_pins $bd_hier/pin_reset_action_n]

###############################################################################
# Add Engine wrappers
#
# Note: This example inserts idential engine_wrappers. 
# If different engines are used, please modify accordingly
#
#add_files -norecurse $root_dir/hdl/action_wrapper/engine_helper.v

for {set x 0} {$x < $engine_number } {incr x} {
    set xx [format "%02d" $x]
    set eng_hier $bd_hier/eng${xx}_wrapper
    create_bd_cell -type hier $eng_hier

    # Add engine instance
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:${kernel_name}:1.0 $eng_hier/${kernel_name}
    #set_property -dict [list CONFIG.C_M_AXI_HOST_MEM_ID_WIDTH {3}] [get_bd_cells $eng_hier/${kernel_name}]

    # Add engine helper (a small module to handle interrupt src, etc)
    #create_bd_cell -type module -reference engine_helper $bd_hier/eng${xx}_wrapper/engine_helper

    if { $hls_support == "TRUE" } {
        source $hw_root_dir/setup/package_action/hls_action_parse.tcl
        create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $eng_hier/smartconnect_0

        set_property -dict [list CONFIG.NUM_SI ${num_eng_axi_masters} \
                                 CONFIG.NUM_MI {1} ] \
                           [get_bd_cells $eng_hier/smartconnect_0]
    }

    # Make connections inside eng${xx}_wrapper
    create_bd_pin -dir I $eng_hier/pin_clock_eng
    create_bd_pin -dir I $eng_hier/reset_n
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $eng_hier/axi_m
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $eng_hier/axilite_s

    connect_bd_net [get_bd_pins $eng_hier/pin_clock_eng] [get_bd_pins $eng_hier/${kernel_name}/${eng_clock_pin_name}]
    connect_bd_net [get_bd_pins $eng_hier/pin_clock_eng] [get_bd_pins $eng_hier/smartconnect_0/aclk]
    connect_bd_net [get_bd_pins $bd_hier/pin_clock_action] [get_bd_pins $eng_hier/pin_clock_eng]

    connect_bd_net [get_bd_pins $eng_hier/reset_n] [get_bd_pins $eng_hier/${kernel_name}/${eng_reset_pin_name}]
    connect_bd_net [get_bd_pins $eng_hier/reset_n] [get_bd_pins $eng_hier/smartconnect_0/aresetn]
    connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n] [get_bd_pins $eng_hier/reset_n]

    connect_bd_intf_net [get_bd_intf_pins $eng_hier/${kernel_name}/$eng_axilite_name] [get_bd_intf_pins $eng_hier/axilite_s]
    connect_bd_intf_net [get_bd_intf_pins $eng_hier/axilite_s] [get_bd_intf_pins $bd_hier/pin_eng${xx}_axilite]

    connect_bd_intf_net [get_bd_intf_pins $eng_hier/smartconnect_0/M00_AXI] [get_bd_intf_pins $eng_hier/axi_m]
    connect_bd_intf_net [get_bd_intf_pins $eng_hier/axi_m] [get_bd_intf_pins $bd_hier/pin_eng${xx}_aximm]

    set axi_m_idx 0
    foreach m $eng_axi_masters {
        set eng_master_port_name [dict get $m port_prefix]
        set sc_id [format "%02d" $axi_m_idx]
        connect_bd_intf_net [get_bd_intf_pins $eng_hier/smartconnect_0/S${sc_id}_AXI] [get_bd_intf_pins $eng_hier/${kernel_name}/$eng_master_port_name]
        incr axi_m_idx
    }
}



###############################################################################
# Place holder: 
# SmartConnect for perhiperals




###############################################################################
# Place holder: 
# Peripheral Controllers





###############################################################################
# Make **internal** connections under action_wrapper hierarchy
# TODO
