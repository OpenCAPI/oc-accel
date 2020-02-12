
set bd_hier "bd_infra"
# Create BD Hier
create_bd_cell -type hier $bd_hier

###############################################################################
# Additiona preparations
source $root_dir/setup/common/common_funcs.tcl
set imp_version [eval my_get_imp_version]
set build_date [eval my_get_build_date]
set date_string [eval my_get_date_string $build_date]
set card_type [eval my_get_card_type]

###############################################################################
# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:bridge_axi_slave:1.0 $bd_hier/bridge_axi_slave
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:data_bridge:1.0 $bd_hier/data_bridge
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:mmio_axilite_master:1.0 $bd_hier/mmio_axilite_master
set_property -dict [list CONFIG.IMP_VERSION $imp_version ] [get_bd_cells $bd_hier/mmio_axilite_master]
set_property -dict [list CONFIG.BUILD_DATE $build_date ] [get_bd_cells $bd_hier/mmio_axilite_master]
set_property -dict [list CONFIG.CARD_TYPE $card_type ] [get_bd_cells $bd_hier/mmio_axilite_master]
# Set the same image name and register readout
exec echo $date_string > $root_dir/setup/build_image/bitstream_date.txt

create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_c1:1.0 $bd_hier/opencapi30_c1
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_mmio:1.0 $bd_hier/opencapi30_mmio



###############################################################################
# Only make **internal ** connections
connect_bd_net [get_bd_pins $bd_hier/opencapi30_c1/debug_bus] [get_bd_pins $bd_hier/mmio_axilite_master/debug_bus_trans_protocol]
connect_bd_intf_net [get_bd_intf_pins $bd_hier/opencapi30_mmio/ocaccel_mmio] [get_bd_intf_pins $bd_hier/mmio_axilite_master/ocaccel_mmio]
connect_bd_intf_net [get_bd_intf_pins $bd_hier/data_bridge/ocaccel_dma_wr] [get_bd_intf_pins $bd_hier/opencapi30_c1/ocaccel_dma_wr]
connect_bd_intf_net [get_bd_intf_pins $bd_hier/data_bridge/ocaccel_dma_rd] [get_bd_intf_pins $bd_hier/opencapi30_c1/ocaccel_dma_rd]
connect_bd_intf_net [get_bd_intf_pins $bd_hier/bridge_axi_slave/ocaccel_lcl_wr] [get_bd_intf_pins $bd_hier/data_bridge/ocaccel_lcl_wr]
connect_bd_intf_net [get_bd_intf_pins $bd_hier/bridge_axi_slave/ocaccel_lcl_rd] [get_bd_intf_pins $bd_hier/data_bridge/ocaccel_lcl_rd]



connect_bd_net [get_bd_pins $bd_hier/mmio_axilite_master/debug_info_clear] [get_bd_pins $bd_hier/opencapi30_c1/debug_info_clear]
connect_bd_net [get_bd_pins $bd_hier/bridge_axi_slave/lcl_wr_ctx_valid] [get_bd_pins $bd_hier/opencapi30_c1/lcl_wr_ctx_valid]
connect_bd_net [get_bd_pins $bd_hier/bridge_axi_slave/lcl_rd_ctx_valid] [get_bd_pins $bd_hier/opencapi30_c1/lcl_rd_ctx_valid]
connect_bd_net [get_bd_pins $bd_hier/bridge_axi_slave/lcl_wr_ctx] [get_bd_pins $bd_hier/opencapi30_c1/lcl_wr_ctx]
connect_bd_net [get_bd_pins $bd_hier/bridge_axi_slave/lcl_rd_ctx] [get_bd_pins $bd_hier/opencapi30_c1/lcl_rd_ctx]
connect_bd_net [get_bd_pins $bd_hier/data_bridge/debug_bus] [get_bd_pins $bd_hier/mmio_axilite_master/debug_bus_data_bridge]

# Connect clocks so top just needs to connect one clock
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/clock_afu] [get_bd_pins $bd_hier/bridge_axi_slave/clk]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/clock_afu] [get_bd_pins $bd_hier/data_bridge/clk]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/clock_afu] [get_bd_pins $bd_hier/mmio_axilite_master/clk]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/clock_afu] [get_bd_pins $bd_hier/opencapi30_c1/clock_afu]

connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/clock_tlx] [get_bd_pins $bd_hier/opencapi30_c1/clock_tlx]

# Connect Resets
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/resetn] [get_bd_pins $bd_hier/bridge_axi_slave/resetn]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/resetn] [get_bd_pins $bd_hier/data_bridge/resetn]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/resetn] [get_bd_pins $bd_hier/mmio_axilite_master/resetn]
connect_bd_net [get_bd_pins $bd_hier/opencapi30_mmio/resetn] [get_bd_pins $bd_hier/opencapi30_c1/resetn]
