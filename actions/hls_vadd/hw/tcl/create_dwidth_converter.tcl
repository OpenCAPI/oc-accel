#temporal use

create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_dwidth_converter
  set_property -dict [list CONFIG.ADDR_WIDTH {64}              \
                           CONFIG.FIFO_MODE {2}                \
                           CONFIG.ACLK_ASYNC {1}               \
                           CONFIG.SI_DATA_WIDTH {32}           \
                           CONFIG.MI_DATA_WIDTH {1024}         \
                           CONFIG.SI_ID_WIDTH {1}              \
                           ] [get_ips axi_dwidth_converter]
