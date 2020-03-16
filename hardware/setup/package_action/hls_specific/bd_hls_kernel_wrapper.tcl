

proc insert_hls_kernel_wrapper {kernel_hier kernel_id kernel_name axi_id_width} {
    set xx [format "%02d" $kernel_id]

    create_bd_cell -type hier $kernel_hier
    puts "Insert kernel wrapper $xx ($kernel_name) at $kernel_hier ..."


    ###############################################################################
    # Create Pins of this bd level
    create_bd_pin -dir I $kernel_hier/pin_clock
    create_bd_pin -dir I $kernel_hier/pin_reset_n
    create_bd_intf_pin -mode Master -vlnv opencapi.org:ocaccel:interrupt_bus_rtl:1.0 $kernel_hier/pin_interrupt_bus

    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/pin_axi_m
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $kernel_hier/pin_s_axilite
    


    ###############################################################################
    # Add HLS kernel and its affiliated smartconnect

    # Add kernel instance
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:${kernel_name}:1.0 $kernel_hier/${kernel_name}
    source $hardware_dir/setup/package_action/hls_specific/hls_action_parse.tcl


    # Add kernel smartconnect
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $kernel_hier/smartconnect_hls
    set_property -dict [list CONFIG.NUM_SI ${num_kernel_axi_masters} \
                             CONFIG.NUM_MI {1} ] \
                       [get_bd_cells $kernel_hier/smartconnect_hls]
 
    ###############################################################################
    # Add kernel helper and configure it
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:kernel_helper:1.0 $kernel_hier/kernel_helper
    set_property -dict [list CONFIG.C_M_AXI_GMEM_ID_WIDTH $axi_id_width ] [ get_bd_cells $kernel_hier/kernel_helper ]
    set_property -dict [list CONFIG.C_S_AXI_CONTROL_ADDR_WIDTH $kernel_axilite_addr_width] [get_bd_cells $kernel_hier/kernel_helper]

    for {set j 1} {$j <= 8} {incr j} {
        set kernel_name_str(${j}) [ eval my_get_kernel_name_str $j $kernel_name ]
    }

    for {set i 1} {$i <= 8} {incr i} {
        set prop_name [format "KERNEL_NAME_STR%d" $i]
        set_property CONFIG.${prop_name} $kernel_name_str($i) [get_bd_cells $kernel_hier/kernel_helper]
    }


    ###############################################################################
    # Make connections
    # Clock and reset
    connect_bd_net [get_bd_pins $kernel_hier/pin_clock] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_clock_pin_name}]
    connect_bd_net [get_bd_pins $kernel_hier/pin_reset_n] [get_bd_pins $kernel_hier/${kernel_name}/${kernel_reset_pin_name}]

    connect_bd_net [get_bd_pins $kernel_hier/pin_clock] [get_bd_pins $kernel_hier/kernel_helper/clk]
    connect_bd_net [get_bd_pins $kernel_hier/pin_reset_n] [get_bd_pins $kernel_hier/kernel_helper/resetn]

    connect_bd_net [get_bd_pins $kernel_hier/pin_clock] [get_bd_pins $kernel_hier/smartconnect_hls/aclk]
    connect_bd_net [get_bd_pins $kernel_hier/pin_reset_n] [get_bd_pins $kernel_hier/smartconnect_hls/aresetn]

    # axilite
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/pin_s_axilite] [get_bd_intf_pins $kernel_hier/kernel_helper/s_axilite_i2h] 
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/s_axilite_h2k] [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_axilite_name] 

    # Connect many aximm ports from the HLS kernel to smartconnect_hls 
    set axi_m_idx 0
    set axi_m_data_width {}
    foreach m $kernel_axi_masters {
        set kernel_master_port_name [dict get $m port_prefix]
        lappend axi_m_data_width [dict get $m data_width]
        set sc_id [format "%02d" $axi_m_idx]
        connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_hls/S${sc_id}_AXI] [get_bd_intf_pins $kernel_hier/${kernel_name}/$kernel_master_port_name]
        incr axi_m_idx
    }

    # Set helper's AXIMM bus width
    set max_m_data_width [lindex [lsort -integer $axi_m_data_width] end]
    puts "Max data width of kernel is $max_m_data_width, setting kernel_helper data width to $max_m_data_width"
    set_property -dict [list CONFIG.C_M_AXI_GMEM_DATA_WIDTH $max_m_data_width] [get_bd_cells $kernel_hier/kernel_helper]


    # aximm
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/smartconnect_hls/M00_AXI] [get_bd_intf_pins $kernel_hier/kernel_helper/m_axi_k2h]
    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/m_axi_h2i] [get_bd_intf_pins $kernel_hier/pin_axi_m]

    # interrupt

    connect_bd_intf_net [get_bd_intf_pins $kernel_hier/kernel_helper/interrupt_bus] [get_bd_intf_pins $kernel_hier/pin_interrupt_bus]
    connect_bd_net [get_bd_pins $kernel_hier/${kernel_name}/interrupt] [get_bd_pins $kernel_hier/kernel_helper/interrupt_i]
}

