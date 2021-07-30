#-----------------------------------------------------------
#
# Copyright 2019, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------

set vivadoVer    [version -short]
set root_dir    $::env(SNAP_HARDWARE_ROOT)
set denali_used $::env(DENALI_USED)
set fpga_part   $::env(FPGACHIP)
set fpga_card   $::env(FPGACARD)
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_hbm_host.log
set hbm_axi_if_num   $::env(HBM_AXI_IF_NUM)

# user can set a specific value for the Action clock lower than the 250MHz nominal clock
# as of now, only 3 clock frequencies are enabled in this file: 200MHz, 225MHz and 250MHz
# At this time, only AXI Action clock which can be used is the 200MHz nominal clock
set action_clock_freq "200MHz"
#overide default value if variable exist
#set action_clock_freq $::env(FPGA_ACTION_CLK)

set prj_name hbm
set bd_name  hbm_top


# _______________________________________________________________________________
# In this file, we define all the logic to have independent 256MB/2Gb memories
# each with an independent AXI interfaces which will be connected to the action
# The number of HBM interfaces is selected by the Kconfig menu
# It needs to be in sync with the param #define HBM_AXI_IF_NB which should be 
# defined in actions/hls_hbm_memcopy_1024/hw/hw_action_hbm_memcopy_1024.cpp
# _______________________________________________________________________________

# Create HBM project
create_project   $prj_name $root_dir/ip/hbm -part $fpga_part -force >> $log_file
set_property target_language VHDL [current_project]

#Create block design
create_bd_design $bd_name  >> $log_file
current_bd_design $bd_name

# Create HBM IP
puts "                        generating HBM Host IP with $hbm_axi_if_num AXI interfaces of 256MB HBM each"

#======================================================
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
  }
  set source_set [get_filesets sources_1]

  # Set source set properties
  set_property "generic" "" $source_set


#====================
#create the constants
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_zero
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells constant_1_zero]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_one
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells constant_1_one]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_22_zero
set_property -dict [list CONFIG.CONST_WIDTH {22} CONFIG.CONST_VAL {0}] [get_bd_cells constant_22_zero]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_32_zero
set_property -dict [list CONFIG.CONST_WIDTH {32} CONFIG.CONST_VAL {0}] [get_bd_cells constant_32_zero]


#====================
#create the clocks and the reset signals for the design
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_bufg_apb_clk
set_property -dict [list CONFIG.C_BUF_TYPE {BUFGCE_DIV} CONFIG.C_BUFGCE_DIV {4}] [get_bd_cells refclk_bufg_apb_clk]

#====================
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins refclk_bufg_apb_clk/BUFGCE_CLR]
connect_bd_net [get_bd_pins constant_1_one/dout] [get_bd_pins refclk_bufg_apb_clk/BUFGCE_CE]

#ARESETN is used for HBM reset
set port [create_bd_port -dir I ARESETN]
#CRESETN is used for converters reset 
set port [create_bd_port -dir I CRESETN]

#====================
#Use the HBM RIGHT stack 0 only (16 modules of 256MB/2Gb = 4GB)
#LEFT stack is used for SNAP/CAPI2.0 since BSP/PSL logic is using right resources of the FPGA
#RIGHT stack is used for OC-Accel/OCAPI3.0 since TLX/DLX logic is using left resources of the FPGA
set cell [create_bd_cell -quiet -type ip -vlnv {xilinx.com:ip:hbm:*} hbm]
         #create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 hbm

#Common params for the HBM not depending on the number of memories enabled
# The reference clock provided to HBM is AXI clock
#  AXI clk = 200MHz => HBM refclk = 900MHz
#  AXI clk = 225MHz => HBM refclk = 875MHz
#  AXI clk = 250MHz => HBM refclk = 875MHz
#in AD9H3, HBM LEFT stack is used for SNAP/CAPI2.0 since BSP/PSL logic is using right resources of the FPGA
#in AD9H3, HBM RIGHT stack is used for OC-Accel.OC3.0 since TLx/DLx logic is using left resources of the FPGA
#in AD9H7, HBM LEFT stack is used for OC-Accel.OC3.0 since path is quicker to HBM left resources of the FPGA

#Setting for Production chips: HBM_REF_CLK=200MHz
set_property -dict [list                               \
  CONFIG.USER_AUTO_POPULATE {yes}                      \
  CONFIG.USER_SWITCH_ENABLE_00 {FALSE}                 \
  CONFIG.USER_XSDB_INTF_EN {FALSE}                     \
  ] $cell >> $log_file

# if less or equal than 16 HBM then 1 stack used
if { $hbm_axi_if_num <= 16 } {
  set_property -dict [list                               \
    CONFIG.USER_HBM_DENSITY {4GB}                        \
    CONFIG.USER_HBM_STACK {1}                            \
    CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK}              \
    ] $cell >> $log_file
    if { $fpga_card == "AD9H3" } {
    set_property -dict [list                             \
      CONFIG.USER_SINGLE_STACK_SELECTION {RIGHT}         \
      ] $cell >> $log_file
    } else {
    set_property -dict [list                             \
      CONFIG.USER_SINGLE_STACK_SELECTION {LEFT}          \
      ] $cell >> $log_file
    }
# 2 stacks
} else {
  set_property -dict [list                               \
     CONFIG.USER_SINGLE_STACK_SELECTION {LEFT}           \
     CONFIG.USER_HBM_DENSITY {8GB}                       \
     CONFIG.USER_HBM_STACK {2}                           \
     CONFIG.USER_SWITCH_ENABLE_01 {FALSE}                \
     CONFIG.USER_CLK_SEL_LIST0 {AXI_07_ACLK}             \
     CONFIG.USER_CLK_SEL_LIST1 {AXI_16_ACLK}             \
     CONFIG.USER_HBM_REF_CLK_PS_1 {2500.00}              \
     CONFIG.USER_HBM_REF_CLK_XDC_1 {5.00}                \
     CONFIG.USER_HBM_RES_1 {9}                           \
     CONFIG.USER_HBM_LOCK_REF_DLY_1 {20}                 \
     CONFIG.USER_HBM_LOCK_FB_DLY_1 {20}                  \
     CONFIG.USER_HBM_REF_CLK_1 {200}                     \
     CONFIG.USER_HBM_FBDIV_1 {18}                        \
     CONFIG.USER_HBM_HEX_CP_RES_1 {0x00009600}           \
     CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_1 {0x00001414}  \
     CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_1 {0x00000482}  \
     CONFIG.USER_MC_ENABLE_APB_01 {TRUE}                 \
     CONFIG.USER_APB_PCLK_1 {50}                         \
     CONFIG.USER_APB_PCLK_PERIOD_1 {20.0}                \
     CONFIG.USER_TEMP_POLL_CNT_1 {50000}                 \
    ] $cell >> $log_file

} 
# AXI clk is 201.420MHZ and is used as HBM_ref_clk 
# AXI clk divided by 3 is used by APB_clock (50-100MHz)
  set_property -dict [list                               \
    CONFIG.USER_HBM_REF_CLK_0 {201}                      \
    CONFIG.USER_HBM_REF_CLK_PS_0 {2487.56}               \
    CONFIG.USER_HBM_REF_CLK_XDC_0 {4.98}                 \
    CONFIG.USER_HBM_FBDIV_0 {17}                         \
    CONFIG.USER_HBM_CP_0 {3}                             \
    CONFIG.USER_HBM_RES_0 {6}                            \
    CONFIG.USER_HBM_LOCK_REF_DLY_0 {19}                  \
    CONFIG.USER_HBM_LOCK_FB_DLY_0 {19}                   \
    CONFIG.USER_HBM_HEX_CP_RES_0 {0x00006300}            \
    CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_0 {0x00001313}   \
    CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000442}   \
    CONFIG.USER_HBM_TCK_0 {855}                          \
    CONFIG.USER_HBM_TCK_0_PERIOD {1.1695906432748537}    \
    CONFIG.USER_tRC_0 {0x29}                             \
    CONFIG.USER_tRAS_0 {0x1D}                            \
    CONFIG.USER_tRCDRD_0 {0xC}                           \
    CONFIG.USER_tRCDWR_0 {0x9}                           \
    CONFIG.USER_tRRDL_0 {0x4}                            \
    CONFIG.USER_tRRDS_0 {0x4}                            \
    CONFIG.USER_tFAW_0 {0xE}                             \
    CONFIG.USER_tRP_0 {0xC}                              \
    CONFIG.USER_tWR_0 {0xE}                              \
    CONFIG.USER_tXP_0 {0x7}                              \
    CONFIG.USER_tRFC_0 {0xDF}                            \
    CONFIG.USER_tRFCSB_0 {0x89}                          \
    CONFIG.USER_tRREFD_0 {0x7}                           \
    CONFIG.USER_APB_PCLK_0 {50}                          \
    CONFIG.USER_APB_PCLK_PERIOD_0 {20.0}                 \
    CONFIG.USER_TEMP_POLL_CNT_0 {50000}                  \
    CONFIG.USER_HBM_REF_OUT_CLK_0 {1710}                 \
    CONFIG.USER_MC0_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC1_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC2_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC3_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC4_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC5_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC6_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_MC7_REF_CMD_PERIOD {0x0D06}              \
    CONFIG.USER_DFI_CLK0_FREQ {427.500}                  \
  ] $cell >> $log_file
 
#===============================================================================
#== ALL PARAMETERS BELOW DEPEND ON THE NUMBER OF HBM MEMORIES YOU WANT TO USE ==
#===============================================================================
#Define here the configuration you request 
#
#CHANGE_HBM_INTERFACES_NUMBER
#  CONFIG.USER_MEMORY_DISPLAY {2048}  => set the value to 512 by MC used (2048 = 4 MC used)
#  CONFIG.USER_MC_ENABLE_00 {TRUE}    => enable/disable the MC

set axi_mc_nb [expr {(($hbm_axi_if_num +1 ) / 2)}]
set axi_mc_display [expr {($axi_mc_nb * 512)}]
set_property -dict [list \
    CONFIG.USER_MEMORY_DISPLAY {axi_mc_display}  \
  ] $cell >> $log_file

for {set i 0} {$i < 16} {incr i} {
  #Manage 1 vs 2 digits
  if { $i < $axi_mc_nb} {
     if { $i < 10} {
        set_property -dict [list              \
           CONFIG.USER_MC_ENABLE_0$i {TRUE}   \
           CONFIG.USER_PHY_ENABLE_0$i {TRUE}  \
        ] $cell >> $log_file
     } else {
        set_property -dict [list              \
           CONFIG.USER_MC_ENABLE_$i {TRUE}   \
           CONFIG.USER_PHY_ENABLE_$i {TRUE}  \
        ] $cell >> $log_file
     }
  } else {
     if { $i < 10} {
        set_property -dict [list              \
           CONFIG.USER_MC_ENABLE_0$i {FALSE}   \
           CONFIG.USER_PHY_ENABLE_0$i {TRUE}  \
        ] $cell >> $log_file
     } else {
        set_property -dict [list              \
           CONFIG.USER_MC_ENABLE_$i {FALSE}   \
           CONFIG.USER_PHY_ENABLE_$i {TRUE}  \
        ] $cell >> $log_file
     }
  }
}
#Disable the SAXI interface if not used in last MC
if { $hbm_axi_if_num%2 == 1} {
     if { $hbm_axi_if_num < 10} {
        set_property -dict [list CONFIG.USER_SAXI_0$hbm_axi_if_num {FALSE}] $cell >> $log_file
     } else {
        set_property -dict [list CONFIG.USER_SAXI_$hbm_axi_if_num  {FALSE} ] $cell >> $log_file
     }
}
#===============================================================================



#add log_file to remove the warning on screen
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PENABLE] >> $log_file
connect_bd_net [get_bd_pins constant_22_zero/dout] [get_bd_pins hbm/APB_0_PADDR]  >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PSEL]    >> $log_file
connect_bd_net [get_bd_pins constant_32_zero/dout] [get_bd_pins hbm/APB_0_PWDATA] >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PWRITE]  >> $log_file

connect_bd_net [get_bd_pins refclk_bufg_apb_clk/BUFGCE_O] [get_bd_pins hbm/APB_0_PCLK]
connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/APB_0_PRESET_N]

if { $hbm_axi_if_num > 16 } {
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_1_PENABLE] >> $log_file
connect_bd_net [get_bd_pins constant_22_zero/dout] [get_bd_pins hbm/APB_1_PADDR]  >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_1_PSEL]    >> $log_file
connect_bd_net [get_bd_pins constant_32_zero/dout] [get_bd_pins hbm/APB_1_PWDATA] >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_1_PWRITE]  >> $log_file

  connect_bd_net [get_bd_pins refclk_bufg_apb_clk/BUFGCE_O] [get_bd_pins hbm/APB_1_PCLK]
  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/APB_1_PRESET_N]
}
#======
# Connect output ports
set port [create_bd_port -dir O apb_complete]
connect_bd_net [get_bd_ports apb_complete] [get_bd_pins hbm/apb_complete_0]

#====================
#-- Set the upper bound of the loop to the number of memory you use --

#--------------------- start loop ------------------
for {set i 0} {$i < $hbm_axi_if_num} {incr i} {

  #create the axi4 to axi3 converters
  set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_protocol_converter:*} axi4_to_axi3_$i]
  set_property -dict {      \
    CONFIG.ID_WIDTH {6}     \
    CONFIG.ADDR_WIDTH {34}  \
  } $cell
  

  #create the axi_register_slice converters
  #REG param is set to 10 for SLR crossing and 15 for multi-SLR crossing (auto pipeline)
  set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_register_slice:*} axi_register_slice_$i ]
  set_property -dict {     \
    CONFIG.ADDR_WIDTH {34}              \
    CONFIG.DATA_WIDTH {256}             \
    CONFIG.ID_WIDTH {6}                 \
    CONFIG.REG_AW {10}                  \
    CONFIG.REG_AR {10}                  \
    CONFIG.REG_W {10}                   \
    CONFIG.REG_R {10}                   \
    CONFIG.REG_B {10}                   \
    }  $cell




  #create the ports
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_p$i\_HBM
  set_property -dict [list \
      CONFIG.CLK_DOMAIN {S_AXI_p$i\_HBM_ACLK} \
      CONFIG.NUM_WRITE_OUTSTANDING {2}       \
      CONFIG.NUM_READ_OUTSTANDING {2}        \
      CONFIG.DATA_WIDTH {256}                \
  ] [get_bd_intf_ports S_AXI_p$i\_HBM]

  set_property -dict [list CONFIG.FREQ_HZ {200000000}] [get_bd_intf_ports S_AXI_p$i\_HBM]
  connect_bd_intf_net [get_bd_intf_ports S_AXI_p$i\_HBM] [get_bd_intf_pins axi4_to_axi3_$i/S_AXI]


  if { ($vivadoVer >= "2019.2")} {
    set port [create_bd_port -dir I -type clk -freq_hz 200000000 S_AXI_p$i\_HBM_ACLK]
  } else {
    set port [create_bd_port -dir I -type clk S_AXI_p$i\_HBM_ACLK]
    set_property {CONFIG.FREQ_HZ} {200000000} $port
  }
  connect_bd_net $port [get_bd_pins axi4_to_axi3_$i/aclk]
  connect_bd_net [get_bd_pins CRESETN] [get_bd_pins axi4_to_axi3_$i/aresetn]
  
  #connect axi4_to_axi3 to axi_register_slice
  connect_bd_net [get_bd_ports CRESETN] [get_bd_pins axi_register_slice_$i\/aresetn]
  connect_bd_net [get_bd_ports S_AXI_p$i\_HBM_ACLK] [get_bd_pins axi_register_slice_$i\/aclk]
  connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_$i/M_AXI] [get_bd_intf_pins axi_register_slice_$i/S_AXI]

  #connect axi_register_slice to hbm
  #Manage 1 vs 2 digits
  if { $i < 10} {
    connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_0$i\_ARESET_N]
    connect_bd_net [get_bd_pins axi4_to_axi3_$i/aclk] [get_bd_pins hbm/AXI_0$i\_ACLK]
  # AD9H7 cards require a different AXI name
      if { (($fpga_card != "AD9H7" && $fpga_card != "AD9H335") && $vivadoVer >= "2020.2") } {
	connect_bd_intf_net [get_bd_intf_pins axi_register_slice_$i\/M_AXI] [get_bd_intf_pins hbm/SAXI_0$i\_RT]
	 } else {
        connect_bd_intf_net [get_bd_intf_pins axi_register_slice_$i\/M_AXI] [get_bd_intf_pins hbm/SAXI_0$i]
	 }
  } else {
	connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_$i\_ARESET_N]
        connect_bd_net [get_bd_pins axi4_to_axi3_$i/aclk] [get_bd_pins hbm/AXI_$i\_ACLK]

       if { (($fpga_card != "AD9H7" && $fpga_card != "AD9H335") && $vivadoVer >= "2020.2") } {
	connect_bd_intf_net [get_bd_intf_pins axi_register_slice_$i\/M_AXI] [get_bd_intf_pins hbm/SAXI_$i\_RT]
	 } else {
	connect_bd_intf_net [get_bd_intf_pins axi_register_slice_$i\/M_AXI] [get_bd_intf_pins hbm/SAXI_$i]
	}
  }
}
#--------------------- end loop ------------------

#This line need to be added after the loop since the S_AXI_p0_HBM_ACLK is not defined before
connect_bd_net [get_bd_pins hbm/HBM_REF_CLK_0] [get_bd_pins S_AXI_p0_HBM_ACLK]
connect_bd_net [get_bd_ports S_AXI_p0_HBM_ACLK] [get_bd_pins refclk_bufg_apb_clk/BUFGCE_I]
if { $hbm_axi_if_num > 16 } {
  connect_bd_net [get_bd_pins hbm/HBM_REF_CLK_1] [get_bd_pins S_AXI_p0_HBM_ACLK]
}

assign_bd_address >> $log_file

regenerate_bd_layout
#comment following line if you want to debug this file
validate_bd_design >> $log_file
save_bd_design >> $log_file

#====================
# Generate the Output products of the HBM block design.
# It is important that this are Verilog files and set the synth_checkpoint_mode to None (Global synthesis) before generating targets
puts "                        generating HBM output products"
set_property synth_checkpoint_mode None [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file

#comment following line if you want to debug this file
generate_target all                     [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file

make_wrapper -files [get_files $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -top

#Close the project
close_project >> $log_file
