
set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set fpga_part        $::env(FPGACHIP)
set project "A1_minimum"
set project_dir      $root_dir/build/temp_bd/$project

set ip_repo_dir     $root_dir/ip_repo
set interfaces_dir  $root_dir/interfaces
set bd_name         "A1"

create_project $project $project_dir -part $fpga_part
create_bd_design $bd_name
set_property  ip_repo_paths  [list $ip_repo_dir $interfaces_dir] [current_project]
update_ip_catalog

# Add IPs
startgroup
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:action_wrapper:1.0 action_wrapper_0
set_property -dict [list CONFIG.C_M_AXI_HOST_MEM_ID_WIDTH {3}] [get_bd_cells action_wrapper_0]
endgroup


# Annouce external pins
startgroup
create_bd_port -dir I -type clk -freq_hz 100000000 ap_clk
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins action_wrapper_0/ap_clk] 

make_bd_pins_external  [get_bd_pins action_wrapper_0/ap_rst_n]
make_bd_intf_pins_external  [get_bd_intf_pins action_wrapper_0/m_axi_host_mem]
make_bd_intf_pins_external  [get_bd_intf_pins action_wrapper_0/s_axi_ctrl_reg]
make_bd_pins_external  [get_bd_pins action_wrapper_0/interrupt]
make_bd_pins_external  [get_bd_pins action_wrapper_0/interrupt_ack]
make_bd_pins_external  [get_bd_pins action_wrapper_0/interrupt_src]
make_bd_pins_external  [get_bd_pins action_wrapper_0/interrupt_ctx]
endgroup



# Save and Make wrapper
regenerate_bd_layout
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name/bd] -top

ipx::package_project -root_dir $root_dir/ip_repo -vendor opencapi.org -library ocaccel -taxonomy /UserIP -module $bd_name -import_files

set_property core_revision 2 [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::create_xgui_files [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::update_checksums [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::save_core [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
close_project
