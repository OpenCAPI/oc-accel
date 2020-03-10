
set bd_hier "infra_wrap"
set action_frequency    $::env(ACTION_CLOCK_FREQUENCY)
set action_name         $::env(ACTION_NAME)
set kernel_number       $::env(KERNEL_NUMBER)
set width_aximm_ports   $::env(WIDTH_AXIMM_PORTS)
set axiport_number      [expr $kernel_number+1]
# Create BD Hier
create_bd_cell -type hier $bd_hier

###############################################################################
# Additiona preparations
source $hardware_dir/setup/common/common_funcs.tcl
set imp_version      [ eval my_get_imp_version                    ]
set build_date       [ eval my_get_build_date                     ]
set date_string      [ eval my_get_date_string $build_date        ]
set card_type        [ eval my_get_card_type                      ]
set action_name_str1 [ eval my_get_action_name_str 1 $action_name ]
set action_name_str2 [ eval my_get_action_name_str 2 $action_name ]
set action_name_str3 [ eval my_get_action_name_str 3 $action_name ]
set action_name_str4 [ eval my_get_action_name_str 4 $action_name ]
set infra_template_value 0x2
###############################################################################
# Create pins for AXIlite / AXIMM ports
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_aximm_slave$xx
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $bd_hier/pin_axilite_master$xx
    create_bd_intf_pin -mode Slave  -vlnv opencapi.org:ocaccel:oc_interrupt_rtl:1.0 $bd_hier/pin_${xx}_interrupt
    create_bd_pin -dir I $bd_hier/pin_${xx}_kernel_done
}

###############################################################################
# Create pins for clocks and resets
create_bd_pin -dir I $bd_hier/pin_clock_tlx
create_bd_pin -dir I $bd_hier/pin_clock_afu
create_bd_pin -dir I $bd_hier/pin_reset_afu_n
create_bd_pin -dir O $bd_hier/pin_clock_action
create_bd_pin -dir O $bd_hier/pin_reset_action_n



###############################################################################
# Add basic IPs
add_files -norecurse $hardware_dir/hdl/infrastructure/clock_reset_gen/clock_reset_gen.v
create_bd_cell -type module -reference clock_reset_gen $bd_hier/clock_reset_gen

create_bd_cell -type ip -vlnv opencapi.org:ocaccel:bridge_axi_slave:1.0 $bd_hier/bridge_axi_slave
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:data_bridge:1.0 $bd_hier/data_bridge
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:mmio_axilite_master:1.0 $bd_hier/mmio_axilite_master
set_property -dict [ list CONFIG.IMP_VERSION $imp_version             ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.BUILD_DATE $build_date               ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.ACTION_NAME_STR1 $action_name_str1   ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.ACTION_NAME_STR2 $action_name_str2   ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.ACTION_NAME_STR3 $action_name_str3   ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.ACTION_NAME_STR4 $action_name_str4   ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.KERNEL_NUMBER $kernel_number         ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.INFRA_TEMPLATE $infra_template_value ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
set_property -dict [ list CONFIG.CARD_TYPE $card_type                 ] [ get_bd_cells $bd_hier/mmio_axilite_master ]
# Set the same image name and register readout
exec echo $date_string > $hardware_dir/setup/build_image/bitstream_date.txt

create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_c1:1.0 $bd_hier/opencapi30_c1
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_mmio:1.0 $bd_hier/opencapi30_mmio
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:jm_framework:1.0 $bd_hier/jm_framework
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    create_bd_cell -type ip -vlnv opencapi.org:ocaccel:axi_lite_adaptor:1.0 $bd_hier/axilite_adaptor${xx}
}

###############################################################################
# Add Clock Wizard if necessary

if {$action_frequency != 200} {
    set_property -dict [list CONFIG.INCLUDE_CLK_WIZ {1}] [get_bd_cells $bd_hier/clock_reset_gen]
    set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_pins $bd_hier/clock_reset_gen/clk_wiz_reset]
    
    # Clock Wizard
    create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 $bd_hier/clk_wiz_action 
    set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $action_frequency \
                                    ] [get_bd_cells $bd_hier/clk_wiz_action]
    # Make connections

    connect_bd_net [ get_bd_pins $bd_hier/clk_wiz_action/reset    ] [ get_bd_pins $bd_hier/clock_reset_gen/clk_wiz_reset   ]
    connect_bd_net [ get_bd_pins $bd_hier/clk_wiz_action/clk_in1  ] [ get_bd_pins $bd_hier/pin_clock_afu                   ]
    connect_bd_net [ get_bd_pins $bd_hier/clk_wiz_action/clk_out1 ] [ get_bd_pins $bd_hier/clock_reset_gen/clk_wiz_clk_out ]
    connect_bd_net [ get_bd_pins $bd_hier/clk_wiz_action/locked   ] [ get_bd_pins $bd_hier/clock_reset_gen/clk_wiz_locked  ]
} else {
    set_property -dict [list CONFIG.INCLUDE_CLK_WIZ {0}] [get_bd_cells $bd_hier/clock_reset_gen]
    set_property CONFIG.CLK_DOMAIN top_oc_host_if_0_clock_afu [get_bd_pins $bd_hier/clock_reset_gen/clock_action]
}


###############################################################################
# Add clock convertor for AXI lite Master
if {$action_frequency == 200} {
    # The minimum situation, no SmartConnect is needed
    # Bypass
    puts "Bypass AXI_LITE clock convertor"
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/mmio_axilite_master/m_axi] [get_bd_intf_pins $bd_hier/jm_framework/s_axi]
} else {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 $bd_hier/axilite_clock_convertor
    set_property -dict [list CONFIG.PROTOCOL {AXI4LITE}                     \
                             ] [get_bd_cells $bd_hier/axilite_clock_convertor]

    connect_bd_intf_net [get_bd_intf_pins $bd_hier/jm_framework/s_axi ] [get_bd_intf_pins $bd_hier/axilite_clock_convertor/M_AXI] 
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/mmio_axilite_master/m_axi] [get_bd_intf_pins $bd_hier/axilite_clock_convertor/S_AXI]

    # Clock
    connect_bd_net  [ get_bd_pins $bd_hier/pin_clock_afu                    ] [ get_bd_pins $bd_hier/axilite_clock_convertor/s_axi_aclk     ]
    connect_bd_net  [ get_bd_pins $bd_hier/clock_reset_gen/clock_action     ] [ get_bd_pins $bd_hier/axilite_clock_convertor/m_axi_aclk     ]
    connect_bd_net  [ get_bd_pins $bd_hier/clock_reset_gen/reset_afu_n      ] [ get_bd_pins $bd_hier/axilite_clock_convertor/s_axi_aresetn  ]
    connect_bd_net  [ get_bd_pins $bd_hier/clock_reset_gen/reset_action_n   ] [ get_bd_pins $bd_hier/axilite_clock_convertor/m_axi_aresetn  ]

    # Address map allocation
}


###############################################################################
# Add SmartConnect for AXI MM Slave
if {$action_frequency == 200} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $bd_hier/smartconnect_aximm
    set_property CONFIG.ADVANCED_PROPERTIES 1 [get_bd_cells $bd_hier/smartconnect_aximm]
    set_property -dict [list CONFIG.NUM_SI $axiport_number  \
                             CONFIG.NUM_MI {1}            \
                             CONFIG.HAS_ARESETN {0}       \
                             CONFIG.NUM_CLKS {1}          \
                             ] [get_bd_cells $bd_hier/smartconnect_aximm]

    for {set x 0} {$x < $kernel_number } {incr x} {
        set xx [format "%02d" $x]
        connect_bd_intf_net [get_bd_intf_pins $bd_hier/pin_aximm_slave$xx ] [get_bd_intf_pins $bd_hier/smartconnect_aximm/S${xx}_AXI] 
    }
    set xx [format "%02d" $kernel_number]
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/jm_framework/job_m_axi ] [get_bd_intf_pins $bd_hier/smartconnect_aximm/S${xx}_AXI] 
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/bridge_axi_slave/s_axi] [get_bd_intf_pins $bd_hier/smartconnect_aximm/M00_AXI]

    # Clock
    connect_bd_net [ get_bd_pins $bd_hier/pin_clock_afu                ] [ get_bd_pins $bd_hier/smartconnect_aximm/aclk  ]
} else {
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 $bd_hier/smartconnect_aximm
    set_property CONFIG.ADVANCED_PROPERTIES 1 [get_bd_cells $bd_hier/smartconnect_aximm]
    set_property -dict [list CONFIG.NUM_SI $axiport_number  \
                             CONFIG.NUM_MI {1}            \
                             CONFIG.HAS_ARESETN {0}       \
                             CONFIG.NUM_CLKS {2}          \
                             ] [get_bd_cells $bd_hier/smartconnect_aximm]

    for {set x 0} {$x < $kernel_number } {incr x} {
        set xx [format "%02d" $x]
        connect_bd_intf_net [get_bd_intf_pins $bd_hier/pin_aximm_slave$xx ] [get_bd_intf_pins $bd_hier/smartconnect_aximm/S${xx}_AXI] 
    }
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/bridge_axi_slave/s_axi] [get_bd_intf_pins $bd_hier/smartconnect_aximm/M00_AXI]

    # Clock
    connect_bd_net [ get_bd_pins $bd_hier/pin_clock_afu                ] [ get_bd_pins $bd_hier/smartconnect_aximm/aclk  ]
    connect_bd_net [ get_bd_pins $bd_hier/clock_reset_gen/clock_action ] [ get_bd_pins $bd_hier/smartconnect_aximm/aclk1 ]

}

###############################################################################
# Connect the clock_reset_gen
# input
connect_bd_net                [ get_bd_pins $bd_hier/clock_reset_gen/clock_afu         ] [ get_bd_pins $bd_hier/pin_clock_afu                         ]
connect_bd_net                [ get_bd_pins $bd_hier/clock_reset_gen/reset_afu_n       ] [ get_bd_pins $bd_hier/pin_reset_afu_n                       ]
connect_bd_net                [ get_bd_pins $bd_hier/clock_reset_gen/soft_reset_action ] [ get_bd_pins $bd_hier/mmio_axilite_master/soft_reset_action ]
# output
connect_bd_net                [ get_bd_pins $bd_hier/clock_reset_gen/clock_action      ] [ get_bd_pins $bd_hier/pin_clock_action                      ]
connect_bd_net                [ get_bd_pins $bd_hier/clock_reset_gen/reset_action_n    ] [ get_bd_pins $bd_hier/pin_reset_action_n                    ]


###############################################################################
# Make other **internal ** connections
connect_bd_net      [ get_bd_pins $bd_hier/opencapi30_c1/debug_bus              ] [ get_bd_pins $bd_hier/mmio_axilite_master/debug_bus_trans_protocol ]
connect_bd_intf_net [ get_bd_intf_pins $bd_hier/opencapi30_mmio/ocaccel_mmio    ] [ get_bd_intf_pins $bd_hier/mmio_axilite_master/ocaccel_mmio        ]
connect_bd_intf_net [ get_bd_intf_pins $bd_hier/data_bridge/ocaccel_dma_wr      ] [ get_bd_intf_pins $bd_hier/opencapi30_c1/ocaccel_dma_wr            ]
connect_bd_intf_net [ get_bd_intf_pins $bd_hier/data_bridge/ocaccel_dma_rd      ] [ get_bd_intf_pins $bd_hier/opencapi30_c1/ocaccel_dma_rd            ]
connect_bd_intf_net [ get_bd_intf_pins $bd_hier/bridge_axi_slave/ocaccel_lcl_wr ] [ get_bd_intf_pins $bd_hier/data_bridge/ocaccel_lcl_wr              ]
connect_bd_intf_net [ get_bd_intf_pins $bd_hier/bridge_axi_slave/ocaccel_lcl_rd ] [ get_bd_intf_pins $bd_hier/data_bridge/ocaccel_lcl_rd              ]

connect_bd_net      [ get_bd_pins $bd_hier/mmio_axilite_master/debug_info_clear ] [ get_bd_pins $bd_hier/opencapi30_c1/debug_info_clear               ]
connect_bd_net      [ get_bd_pins $bd_hier/data_bridge/debug_bus                ] [ get_bd_pins $bd_hier/mmio_axilite_master/debug_bus_data_bridge    ]

###############################################################################
# Connect clocks with input pins
connect_bd_net [get_bd_pins $bd_hier/pin_clock_afu   ] [get_bd_pins $bd_hier/bridge_axi_slave/clk       ]
connect_bd_net [get_bd_pins $bd_hier/pin_clock_afu   ] [get_bd_pins $bd_hier/data_bridge/clk            ]
connect_bd_net [get_bd_pins $bd_hier/pin_clock_afu   ] [get_bd_pins $bd_hier/mmio_axilite_master/clk    ]
connect_bd_net [get_bd_pins $bd_hier/pin_clock_afu   ] [get_bd_pins $bd_hier/opencapi30_c1/clock_afu    ]
connect_bd_net [get_bd_pins $bd_hier/pin_clock_afu   ] [get_bd_pins $bd_hier/opencapi30_mmio/clock_afu  ]

connect_bd_net [get_bd_pins $bd_hier/pin_clock_tlx   ] [get_bd_pins $bd_hier/opencapi30_c1/clock_tlx    ]
connect_bd_net [get_bd_pins $bd_hier/pin_clock_tlx   ] [get_bd_pins $bd_hier/opencapi30_mmio/clock_tlx  ]

# Connect resets with input pins
connect_bd_net [get_bd_pins $bd_hier/pin_reset_afu_n ] [get_bd_pins $bd_hier/bridge_axi_slave/resetn    ]
connect_bd_net [get_bd_pins $bd_hier/pin_reset_afu_n ] [get_bd_pins $bd_hier/data_bridge/resetn         ]
connect_bd_net [get_bd_pins $bd_hier/pin_reset_afu_n ] [get_bd_pins $bd_hier/mmio_axilite_master/resetn ]
connect_bd_net [get_bd_pins $bd_hier/pin_reset_afu_n ] [get_bd_pins $bd_hier/opencapi30_c1/resetn       ]
connect_bd_net [get_bd_pins $bd_hier/pin_reset_afu_n ] [get_bd_pins $bd_hier/opencapi30_mmio/resetn     ]

# Connect jm_framework & AXI_lite_adaptor
connect_bd_net [get_bd_pins $bd_hier/pin_clock_action   ] [get_bd_pins $bd_hier/jm_framework/clk         ]
connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n ] [get_bd_pins $bd_hier/jm_framework/resetn      ]
for {set x 0} {$x < $kernel_number } {incr x} {
    set xx [format "%02d" $x]
    connect_bd_net [get_bd_pins $bd_hier/pin_clock_action   ] [get_bd_pins $bd_hier/axilite_adaptor${xx}/clk     ]
    connect_bd_net [get_bd_pins $bd_hier/pin_reset_action_n ] [get_bd_pins $bd_hier/axilite_adaptor${xx}/resetn  ]
    connect_bd_intf_net [get_bd_intf_pins $bd_hier/axilite_adaptor${xx}/s_axi   ] [get_bd_intf_pins $bd_hier/pin_axilite_master${xx}]     
#connect_bd_intf_net [get_bd_intf_pins $bd_hier/axilite_adaptor${xx}/adap    ] [get_bd_intf_pins $bd_hier/pin_${xx}_interrupt     ]     
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/kernel_done       ] [get_bd_pins $bd_hier/pin_${xx}_kernel_done   ]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/kernel_start      ] [get_bd_pins $bd_hier/jm_framework/kernel_start${xx}   ]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/kernel_ready      ] [get_bd_pins $bd_hier/jm_framework/kernel_ready${xx}   ]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/kernel_data       ] [get_bd_pins $bd_hier/jm_framework/kernel_data${xx}    ]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/complete_accept   ] [get_bd_pins $bd_hier/jm_framework/complete_accept${xx}]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/complete_ready    ] [get_bd_pins $bd_hier/jm_framework/complete_ready${xx} ]
    connect_bd_net [get_bd_pins $bd_hier/axilite_adaptor${xx}/complete_data     ] [get_bd_pins $bd_hier/jm_framework/complete_data${xx}  ]
}


