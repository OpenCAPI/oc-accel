# Processing arguments --------------------------------------------------------
# This script has one argument: root_dir

set root_dir $::env(OCACCEL_HARDWARE_ROOT)
source $root_dir/setup/common/common_funcs.tcl
set interface_repo "$root_dir/build/interfaces"
puts "interface_repo is set to $interface_repo"

# Add interfaces
#------------------------------------------------------------------------------
set port_list_tlx_afu [list \
        afu_tlx_cmd_initial_credit        \
        afu_tlx_cmd_credit                \
        tlx_afu_cmd_valid                 \
        tlx_afu_cmd_opcode                \
        tlx_afu_cmd_dl                    \
        tlx_afu_cmd_end                   \
        tlx_afu_cmd_pa                    \
        tlx_afu_cmd_flag                  \
        tlx_afu_cmd_os                    \
        tlx_afu_cmd_capptag               \
        tlx_afu_cmd_pl                    \
        tlx_afu_cmd_be                    \
        afu_tlx_cmd_rd_req                \
        afu_tlx_cmd_rd_cnt                \
        tlx_afu_cmd_data_valid            \
        tlx_afu_cmd_data_bus              \
        tlx_afu_cmd_data_bdi              \
        tlx_afu_resp_initial_credit       \
        tlx_afu_resp_credit               \
        afu_tlx_resp_valid                \
        afu_tlx_resp_opcode               \
        afu_tlx_resp_dl                   \
        afu_tlx_resp_capptag              \
        afu_tlx_resp_dp                   \
        afu_tlx_resp_code                 \
        tlx_afu_resp_data_initial_credit  \
        tlx_afu_resp_data_credit          \
        afu_tlx_rdata_valid               \
        afu_tlx_rdata_bus                 \
        afu_tlx_rdata_bdi                 \
        ]

my_create_bus_interface $interface_repo "tlx_afu"  $port_list_tlx_afu 

#------------------------------------------------------------------------------
set port_list_afu_tlx [list \
        tlx_afu_cmd_initial_credit        \
        tlx_afu_cmd_credit                \
        afu_tlx_cmd_valid                 \
        afu_tlx_cmd_opcode                \
        afu_tlx_cmd_actag                 \
        afu_tlx_cmd_stream_id             \
        afu_tlx_cmd_ea_or_obj             \
        afu_tlx_cmd_afutag                \
        afu_tlx_cmd_dl                    \
        afu_tlx_cmd_pl                    \
        afu_tlx_cmd_os                    \
        afu_tlx_cmd_be                    \
        afu_tlx_cmd_flag                  \
        afu_tlx_cmd_endian                \
        afu_tlx_cmd_bdf                   \
        afu_tlx_cmd_pasid                 \
        afu_tlx_cmd_pg_size               \
        tlx_afu_cmd_data_initial_credit   \
        tlx_afu_cmd_data_credit           \
        afu_tlx_cdata_valid               \
        afu_tlx_cdata_bus                 \
        afu_tlx_cdata_bdi                 \
        afu_tlx_resp_initial_credit       \
        afu_tlx_resp_credit               \
        tlx_afu_resp_valid                \
        tlx_afu_resp_opcode               \
        tlx_afu_resp_afutag               \
        tlx_afu_resp_code                 \
        tlx_afu_resp_pg_size              \
        tlx_afu_resp_dl                   \
        tlx_afu_resp_dp                   \
        tlx_afu_resp_host_tag             \
        tlx_afu_resp_cache_state          \
        tlx_afu_resp_addr_tag             \
        afu_tlx_resp_rd_req               \
        afu_tlx_resp_rd_cnt               \
        tlx_afu_resp_data_valid           \
        tlx_afu_resp_data_bus             \
        tlx_afu_resp_data_bdi             \
        ]

my_create_bus_interface $interface_repo "afu_tlx" $port_list_afu_tlx


set port_list_cfg_flsh [list     \
        cfg_flsh_devsel          \
        cfg_flsh_addr            \
        cfg_flsh_wren            \
        cfg_flsh_wdata           \
        cfg_flsh_rden            \
        flsh_cfg_rdata           \
        flsh_cfg_done            \
        flsh_cfg_bresp           \
        flsh_cfg_rresp           \
        flsh_cfg_status          \
        cfg_flsh_expand_enable   \
        cfg_flsh_expand_dir      \
        ]

my_create_bus_interface $interface_repo "cfg_flsh" $port_list_cfg_flsh

set port_list_cfg_vpd [list         \
        cfg_vpd_addr                \
        cfg_vpd_wren                \
        cfg_vpd_wdata               \
        cfg_vpd_rden                \
        vpd_cfg_rdata               \
        vpd_cfg_done                \
        vpd_err_unimplemented_addr  \
        ]

my_create_bus_interface $interface_repo "cfg_vpd" $port_list_cfg_vpd


set port_list_oc_phy [list \
        freerun_clk_p       \
        freerun_clk_n       \
        ch0_gtytxn_out      \
        ch0_gtytxp_out      \
        ch1_gtytxn_out      \
        ch1_gtytxp_out      \
        ch2_gtytxn_out      \
        ch2_gtytxp_out      \
        ch3_gtytxn_out      \
        ch3_gtytxp_out      \
        ch4_gtytxn_out      \
        ch4_gtytxp_out      \
        ch5_gtytxn_out      \
        ch5_gtytxp_out      \
        ch6_gtytxn_out      \
        ch6_gtytxp_out      \
        ch7_gtytxn_out      \
        ch7_gtytxp_out      \
        ch0_gtyrxn_in       \
        ch0_gtyrxp_in       \
        ch1_gtyrxn_in       \
        ch1_gtyrxp_in       \
        ch2_gtyrxn_in       \
        ch2_gtyrxp_in       \
        ch3_gtyrxn_in       \
        ch3_gtyrxp_in       \
        ch4_gtyrxn_in       \
        ch4_gtyrxp_in       \
        ch5_gtyrxn_in       \
        ch5_gtyrxp_in       \
        ch6_gtyrxn_in       \
        ch6_gtyrxp_in       \
        ch7_gtyrxn_in       \
        ch7_gtyrxp_in       \
        mgtrefclk1_x0y0_p   \
        mgtrefclk1_x0y0_n   \
        mgtrefclk1_x0y1_p   \
        mgtrefclk1_x0y1_n   \
        ]

my_create_bus_interface $interface_repo "oc_phy" $port_list_oc_phy

set port_list_dma_wr [list \
        dma_wr_cmd_ready    \
        dma_wr_cmd_valid    \
        dma_wr_cmd_data     \
        dma_wr_cmd_be       \
        dma_wr_cmd_ea       \
        dma_wr_cmd_tag      \
        dma_wr_resp_valid   \
        dma_wr_resp_data    \
        dma_wr_resp_tag     \
        dma_wr_resp_pos     \
        dma_wr_resp_code    \
       ]

set port_list_dma_rd [list \
        dma_rd_cmd_ready    \
        dma_rd_cmd_valid    \
        dma_rd_cmd_data     \
        dma_rd_cmd_be       \
        dma_rd_cmd_ea       \
        dma_rd_cmd_tag      \
        dma_rd_resp_valid   \
        dma_rd_resp_data    \
        dma_rd_resp_tag     \
        dma_rd_resp_pos     \
        dma_rd_resp_code    \
        ]

my_create_bus_interface $interface_repo "dma_wr" $port_list_dma_wr
my_create_bus_interface $interface_repo "dma_rd" $port_list_dma_rd

set port_list_lcl_wr [list \
         lcl_wr_valid             \
         lcl_wr_ea                \
         lcl_wr_axi_id            \
         lcl_wr_be                \
         lcl_wr_first             \
         lcl_wr_last              \
         lcl_wr_data              \
         lcl_wr_idle              \
         lcl_wr_ready             \
         lcl_wr_rsp_valid         \
         lcl_wr_rsp_axi_id        \
         lcl_wr_rsp_code          \
         lcl_wr_rsp_ready         \
         ]

set port_list_lcl_rd [list \
         lcl_rd_valid             \
         lcl_rd_ea                \
         lcl_rd_axi_id            \
         lcl_rd_be                \
         lcl_rd_first             \
         lcl_rd_last              \
         lcl_rd_idle              \
         lcl_rd_ready             \
         lcl_rd_data_valid        \
         lcl_rd_data_axi_id       \
         lcl_rd_data              \
         lcl_rd_data_last         \
         lcl_rd_rsp_code          \
         lcl_rd_data_ready        \
         ]


my_create_bus_interface $interface_repo "lcl_wr" $port_list_lcl_wr
my_create_bus_interface $interface_repo "lcl_rd" $port_list_lcl_rd

set port_list_mmio [list \
         mmio_wr         \
         mmio_rd         \
         mmio_dw         \
         mmio_addr       \
         mmio_din        \
         mmio_dout       \
         mmio_done       \
         mmio_failed     \
         ]
my_create_bus_interface $interface_repo "mmio" $port_list_mmio

set port_list_cfg_infra_c1 [list \
          cfg_infra_backoff_timer    \
          cfg_infra_bdf_bus    \
          cfg_infra_bdf_device    \
          cfg_infra_bdf_function    \
          cfg_infra_actag_base    \
          cfg_infra_pasid_base    \
          cfg_infra_pasid_length    \
          ]
         
my_create_bus_interface $interface_repo "cfg_infra_c1" $port_list_cfg_infra_c1

#set port_list_interrupt [list \
#            interrupt      \
#            interrupt_src  \
#            interrupt_ctx  \
#            interrupt_ack  \
#          ]
#my_create_bus_interface $interface_repo "interrupt" $port_list_interrupt
