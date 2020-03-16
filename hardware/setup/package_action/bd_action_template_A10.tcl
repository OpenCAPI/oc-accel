set kernel_number   $::env(KERNEL_NUMBER)
set kernels         $::env(KERNELS)
set hls_support     $::env(HLS_SUPPORT)
set axi_id_width    $::env(AXI_ID_WIDTH)
set kernel_list     [split $kernels ',']
set kernel_list_len [llength $kernel_list]
set width_aximm_ports   $::env(WIDTH_AXIMM_PORTS)

set bd_hier "act_wrap"
# Create BD Hier
create_bd_cell -type hier $bd_hier

source $hardware_dir/setup/common/common_funcs.tcl
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

for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    set kernel_hier $bd_hier/kernel${xx}_wrap

    # get the kernel name from the kernels list. If the length of kernels list is smaller than kernel_number, the kernel name will be the last item in the list for all extra kernels.
    if { $x >= $kernel_list_len } {
        set kernel_top [lindex $kernel_list end]
    } else {
        set kernel_top [lindex $kernel_list $x]
    }

    if {HLS_SUPPORT == "TRUE" } {
        source $hardware_dir/setup/package_action/hls_specific/bd_hls_kernel_wrapper.tcl 
        puts "Calling insert_hls_kernel_wrapper()..."
        insert_hls_kernel_wrapper $kernel_hier $x $kernel_top $axi_id_width
    } else {
        puts "Calling insert_hdl_kernel_wrapper()..."
    }

    connect_bd_net [get_bd_pins $bd_hier/pin_clock_action] [get_bd_pins $kernel_hier/pin_clock]
    connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n] [get_bd_pins $kernel_hier/pin_reset_n]
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/pin_kernel${xx}_axilite] [get_bd_intf_pins $kernel_hier/pin_s_axilite]
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/pin_kernel${xx}_aximm] [get_bd_intf_pins $kernel_hier/pin_axi_m]
}

