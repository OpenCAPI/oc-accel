
set bd_hier "bd_act"
# Create BD Hier
create_bd_cell -type hier $bd_hier

# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:action_wrapper:1.0 $bd_hier/action_wrapper
set_property -dict [list CONFIG.C_M_AXI_HOST_MEM_ID_WIDTH {3}] [get_bd_cells $bd_hier/action_wrapper]


# Only make **internal** connections
