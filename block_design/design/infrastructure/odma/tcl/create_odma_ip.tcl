  puts "                        generating FIFOs for ODMA mode"
  puts "                        generating IP channel_fifo input:1024x16 output: 256x64 for dsc_manager"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name channel_fifo
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Valid_Flag {true}                   \
                      CONFIG.Data_Count {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Full_Threshold_Assert_Value {13}    \
                      CONFIG.Full_Threshold_Negate_Value {12}    \
                     ] [get_ips channel_fifo]

# Create LCL rdata_fifo for h2a_mm_engine & h2a_st_engine
  puts "                        generating IP fifo_sync_32_1024i1024o for h2a_mm_engine rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_32_1024i1024o
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {32}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {32}                   \
                      CONFIG.Almost_Empty_Flag {true}                       \
                      CONFIG.Almost_Full_Flag {true}                       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count {true}                             \
                      CONFIG.Data_Count_Width {6}                 \
                      CONFIG.Write_Data_Count_Width {6}           \
                      CONFIG.Read_Data_Count_Width {6}           \
                     ] [get_ips fifo_sync_32_1024i1024o]

# Create AXI read data fifo for a2h_mm_engine & ah2_st_engine
  puts "                        generating IP fifo_sync_1024x8 for a2h_mm_engine&a2h_st_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_1024x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1024}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {1024}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_1024x8]

  puts "                        generating IP fifo_sync_9x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_9x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {9}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {9}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_9x8]

  puts "                        generating IP fifo_sync_512x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_512x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {512}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {512}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_512x8]

# Create Descriptor fifo for a2h_mm_engine
  puts "                        generating IP fifo_sync_std_256x8 for a2h_mm_engine descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_std_256x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Input_Data_Width {256}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {256}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {4}                 \
                      CONFIG.Write_Data_Count_Width {4}           \
                      CONFIG.Read_Data_Count_Width {4}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_std_256x8]

# Create Stream data descriptor fifo for a2h_st_engine
  puts "                        generating IP fifo_sync_256x8 for a2h_st_engine descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_256x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {256}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {256}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {4}                 \
                      CONFIG.Write_Data_Count_Width {4}           \
                      CONFIG.Read_Data_Count_Width {4}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_256x8]

  puts "                        generating IP fifo_sync_123x4 for a2h_st_engine stream data descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_123x4
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {123}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {123}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {3}                 \
                      CONFIG.Write_Data_Count_Width {3}           \
                      CONFIG.Read_Data_Count_Width {3}           \
                     ] [get_ips fifo_sync_123x4]

  puts "                        generating IP fifo_sync_70x8 for a2h_st_engine AXI rtag fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_70x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {70}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {70}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_70x8]

 puts "                        generating IP fifo_sync_134x8 for a2h_mm_engine AXI rdata fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_134x8
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {134}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {134}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {5}                 \
                      CONFIG.Write_Data_Count_Width {5}           \
                      CONFIG.Read_Data_Count_Width {5}           \
                      CONFIG.Full_Threshold_Assert_Value {7}    \
                      CONFIG.Full_Threshold_Negate_Value {6}    \
                     ] [get_ips fifo_sync_134x8]

  puts "                        generating IP fifo_sync_1x4 for a2h_st_engine stream data descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_1x4
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {1}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {1}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {3}                 \
                      CONFIG.Write_Data_Count_Width {3}           \
                      CONFIG.Read_Data_Count_Width {3}           \
                     ] [get_ips fifo_sync_1x4]

  puts "                        generating IP fifo_sync_128x4 for a2h_st_engine stream data descriptor fifos"
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_sync_128x4
  set_property -dict [list                                        \
                      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                      CONFIG.Performance_Options {First_Word_Fall_Through}    \
                      CONFIG.Input_Data_Width {128}                 \
                      CONFIG.Input_Depth {16}                    \
                      CONFIG.Output_Data_Width {128}                \
                      CONFIG.Output_Depth {16}                   \
                      CONFIG.Use_Embedded_Registers {false}     \
                      CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                      CONFIG.Valid_Flag {true}                             \
                      CONFIG.Data_Count_Width {3}                 \
                      CONFIG.Write_Data_Count_Width {3}           \
                      CONFIG.Read_Data_Count_Width {3}           \
                     ] [get_ips fifo_sync_128x4]

