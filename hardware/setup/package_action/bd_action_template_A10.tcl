set engine_number $::env(ENGINE_NUMBER)
set hls_support   $::env(HLS_SUPPORT)

set bd_hier "act_wrap"
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

set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_pins $bd_hier/pin_reset_action_n]

###############################################################################
# Add Engine wrappers
#
# Note: This example inserts idential engine_wrappers. 
# If different engines are used, please modify accordingly
#
add_files -norecurse $root_dir/hdl/action_wrapper/engine_helper.v

for {set x 0} {$x < $engine_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_cell -type hier $bd_hier/eng${xx}_wrapper

    # Add engine instance
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:engine_ip:1.0 $bd_hier/eng${xx}_wrapper/engine_ip
    set_property -dict [list CONFIG.C_M_AXI_HOST_MEM_ID_WIDTH {3}] [get_bd_cells $bd_hier/eng${xx}_wrapper/engine_ip ]

    # Add engine helper (a small module to handle interrupt src, etc)
    create_bd_cell -type module -reference engine_helper $bd_hier/eng${xx}_wrapper/engine_helper

    if { $hls_support == "TRUE" } {

        # Add a json derived smartconnect
        # TODO
    }

    # Make connections inside eng${xx}_wrapper
    # TODO
}

#assign_bd_address [get_bd_addr_segs {act_wrap/eng_wrap/s_axi_ctrl_reg/reg0 }]


###############################################################################
# Place holder: 
# SmartConnect for perhiperals




###############################################################################
# Place holder: 
# Peripheral Controllers





###############################################################################
# Make **internal** connections under action_wrapper hierarchy
# TODO
