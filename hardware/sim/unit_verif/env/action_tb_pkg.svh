/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
`ifndef _ACTION_TB_PKG_SVH_
`define _ACTION_TB_PKG_SVH_

`include "../../../hdl/core/snap_global_vars.v"

//UVM ENV
import uvm_pkg::*;
`include "uvm_macros.svh"

//AXI VIP PKG
import axi_vip_pkg::*;
`ifndef ENABLE_ODMA
    import axi_vip_mm_passthrough_pkg::*;
    import axi_vip_mm_master_pkg::*;
`else
    `ifndef ENABLE_ODMA_ST_MODE
        import axi_vip_mm_passthrough_pkg::*;
        import axi_vip_mm_slave_pkg::*;
    `else
        import axi4stream_vip_pkg::*;
        import axi_vip_st_passthrough_h2a_pkg::*;
        import axi_vip_st_passthrough_a2h_pkg::*;
        import axi_vip_st_slave_pkg::*;
        import axi_vip_st_master_pkg::*;
    `endif
`endif
import axi_vip_lite_passthrough_pkg::*;
import axi_vip_lite_slave_pkg::*;

`define AXI_VIP_MM_PASSTHROUGH_PARAMS #(axi_vip_mm_passthrough_VIP_PROTOCOL    , axi_vip_mm_passthrough_VIP_ADDR_WIDTH    , axi_vip_mm_passthrough_VIP_DATA_WIDTH    , axi_vip_mm_passthrough_VIP_DATA_WIDTH    , axi_vip_mm_passthrough_VIP_ID_WIDTH    , axi_vip_mm_passthrough_VIP_ID_WIDTH    , axi_vip_mm_passthrough_VIP_AWUSER_WIDTH    , axi_vip_mm_passthrough_VIP_WUSER_WIDTH    , axi_vip_mm_passthrough_VIP_BUSER_WIDTH    , axi_vip_mm_passthrough_VIP_ARUSER_WIDTH    , axi_vip_mm_passthrough_VIP_RUSER_WIDTH   , axi_vip_mm_passthrough_VIP_SUPPORTS_NARROW    , axi_vip_mm_passthrough_VIP_HAS_BURST    , axi_vip_mm_passthrough_VIP_HAS_LOCK    , axi_vip_mm_passthrough_VIP_HAS_CACHE    , axi_vip_mm_passthrough_VIP_HAS_REGION    , axi_vip_mm_passthrough_VIP_HAS_PROT    , axi_vip_mm_passthrough_VIP_HAS_QOS    , axi_vip_mm_passthrough_VIP_HAS_WSTRB    , axi_vip_mm_passthrough_VIP_HAS_BRESP    , axi_vip_mm_passthrough_VIP_HAS_RRESP    , axi_vip_mm_passthrough_VIP_HAS_ARESETN   )
`define AXI_VIP_MM_SLAVE_PARAMS #(axi_vip_mm_slave_VIP_PROTOCOL    , axi_vip_mm_slave_VIP_ADDR_WIDTH    , axi_vip_mm_slave_VIP_DATA_WIDTH    , axi_vip_mm_slave_VIP_DATA_WIDTH    , axi_vip_mm_slave_VIP_ID_WIDTH    , axi_vip_mm_slave_VIP_ID_WIDTH    , axi_vip_mm_slave_VIP_AWUSER_WIDTH    , axi_vip_mm_slave_VIP_WUSER_WIDTH    , axi_vip_mm_slave_VIP_BUSER_WIDTH    , axi_vip_mm_slave_VIP_ARUSER_WIDTH    , axi_vip_mm_slave_VIP_RUSER_WIDTH   , axi_vip_mm_slave_VIP_SUPPORTS_NARROW    , axi_vip_mm_slave_VIP_HAS_BURST    , axi_vip_mm_slave_VIP_HAS_LOCK    , axi_vip_mm_slave_VIP_HAS_CACHE    , axi_vip_mm_slave_VIP_HAS_REGION    , axi_vip_mm_slave_VIP_HAS_PROT    , axi_vip_mm_slave_VIP_HAS_QOS    , axi_vip_mm_slave_VIP_HAS_WSTRB    , axi_vip_mm_slave_VIP_HAS_BRESP    , axi_vip_mm_slave_VIP_HAS_RRESP    , axi_vip_mm_slave_VIP_HAS_ARESETN   )
`define AXI_VIP_MM_MASTER_PARAMS #(axi_vip_mm_master_VIP_PROTOCOL    , axi_vip_mm_master_VIP_ADDR_WIDTH    , axi_vip_mm_master_VIP_DATA_WIDTH    , axi_vip_mm_master_VIP_DATA_WIDTH    , axi_vip_mm_master_VIP_ID_WIDTH    , axi_vip_mm_master_VIP_ID_WIDTH    , axi_vip_mm_master_VIP_AWUSER_WIDTH    , axi_vip_mm_master_VIP_WUSER_WIDTH    , axi_vip_mm_master_VIP_BUSER_WIDTH    , axi_vip_mm_master_VIP_ARUSER_WIDTH    , axi_vip_mm_master_VIP_RUSER_WIDTH   , axi_vip_mm_master_VIP_SUPPORTS_NARROW    , axi_vip_mm_master_VIP_HAS_BURST    , axi_vip_mm_master_VIP_HAS_LOCK    , axi_vip_mm_master_VIP_HAS_CACHE    , axi_vip_mm_master_VIP_HAS_REGION    , axi_vip_mm_master_VIP_HAS_PROT    , axi_vip_mm_master_VIP_HAS_QOS    , axi_vip_mm_master_VIP_HAS_WSTRB    , axi_vip_mm_master_VIP_HAS_BRESP    , axi_vip_mm_master_VIP_HAS_RRESP    , axi_vip_mm_master_VIP_HAS_ARESETN   )
`define AXI_VIP_LITE_PASSTHROUGH_PARAMS #(axi_vip_lite_passthrough_VIP_PROTOCOL, axi_vip_lite_passthrough_VIP_ADDR_WIDTH, axi_vip_lite_passthrough_VIP_DATA_WIDTH, axi_vip_lite_passthrough_VIP_DATA_WIDTH, axi_vip_lite_passthrough_VIP_ID_WIDTH, axi_vip_lite_passthrough_VIP_ID_WIDTH, axi_vip_lite_passthrough_VIP_AWUSER_WIDTH, axi_vip_lite_passthrough_VIP_WUSER_WIDTH, axi_vip_lite_passthrough_VIP_BUSER_WIDTH, axi_vip_lite_passthrough_VIP_ARUSER_WIDTH,axi_vip_lite_passthrough_VIP_RUSER_WIDTH, axi_vip_lite_passthrough_VIP_SUPPORTS_NARROW, axi_vip_lite_passthrough_VIP_HAS_BURST, axi_vip_lite_passthrough_VIP_HAS_LOCK, axi_vip_lite_passthrough_VIP_HAS_CACHE, axi_vip_lite_passthrough_VIP_HAS_REGION, axi_vip_lite_passthrough_VIP_HAS_PROT, axi_vip_lite_passthrough_VIP_HAS_QOS, axi_vip_lite_passthrough_VIP_HAS_WSTRB, axi_vip_lite_passthrough_VIP_HAS_BRESP, axi_vip_lite_passthrough_VIP_HAS_RRESP, axi_vip_lite_passthrough_VIP_HAS_ARESETN)
`define AXI_VIP_LITE_SLAVE_PARAMS #(axi_vip_lite_slave_VIP_PROTOCOL, axi_vip_lite_slave_VIP_ADDR_WIDTH, axi_vip_lite_slave_VIP_DATA_WIDTH, axi_vip_lite_slave_VIP_DATA_WIDTH, axi_vip_lite_slave_VIP_ID_WIDTH, axi_vip_lite_slave_VIP_ID_WIDTH, axi_vip_lite_slave_VIP_AWUSER_WIDTH, axi_vip_lite_slave_VIP_WUSER_WIDTH, axi_vip_lite_slave_VIP_BUSER_WIDTH, axi_vip_lite_slave_VIP_ARUSER_WIDTH,axi_vip_lite_slave_VIP_RUSER_WIDTH, axi_vip_lite_slave_VIP_SUPPORTS_NARROW, axi_vip_lite_slave_VIP_HAS_BURST, axi_vip_lite_slave_VIP_HAS_LOCK, axi_vip_lite_slave_VIP_HAS_CACHE, axi_vip_lite_slave_VIP_HAS_REGION, axi_vip_lite_slave_VIP_HAS_PROT, axi_vip_lite_slave_VIP_HAS_QOS, axi_vip_lite_slave_VIP_HAS_WSTRB, axi_vip_lite_slave_VIP_HAS_BRESP, axi_vip_lite_slave_VIP_HAS_RRESP, axi_vip_lite_slave_VIP_HAS_ARESETN)
`define AXI_VIP_ST_PASSTHROUGH_H2A_PARAMS #(axi_vip_st_passthrough_h2a_VIP_SIGNAL_SET, axi_vip_st_passthrough_h2a_VIP_DEST_WIDTH, axi_vip_st_passthrough_h2a_VIP_DATA_WIDTH, axi_vip_st_passthrough_h2a_VIP_ID_WIDTH, axi_vip_st_passthrough_h2a_VIP_USER_WIDTH, axi_vip_st_passthrough_h2a_VIP_USER_BITS_PER_BYTE, axi_vip_st_passthrough_h2a_VIP_HAS_ARESETN)
`define AXI_VIP_ST_PASSTHROUGH_A2H_PARAMS #(axi_vip_st_passthrough_a2h_VIP_SIGNAL_SET, axi_vip_st_passthrough_a2h_VIP_DEST_WIDTH, axi_vip_st_passthrough_a2h_VIP_DATA_WIDTH, axi_vip_st_passthrough_a2h_VIP_ID_WIDTH, axi_vip_st_passthrough_a2h_VIP_USER_WIDTH, axi_vip_st_passthrough_a2h_VIP_USER_BITS_PER_BYTE, axi_vip_st_passthrough_a2h_VIP_HAS_ARESETN)
`define AXI_VIP_ST_SLAVE_PARAMS #(axi_vip_st_slave_VIP_SIGNAL_SET, axi_vip_st_slave_VIP_DEST_WIDTH, axi_vip_st_slave_VIP_DATA_WIDTH, axi_vip_st_slave_VIP_ID_WIDTH, axi_vip_st_slave_VIP_USER_WIDTH, axi_vip_st_slave_VIP_USER_BITS_PER_BYTE, axi_vip_st_slave_VIP_HAS_ARESETN)
`define AXI_VIP_ST_MASTER_PARAMS #(axi_vip_st_master_VIP_SIGNAL_SET, axi_vip_st_master_VIP_DEST_WIDTH, axi_vip_st_master_VIP_DATA_WIDTH, axi_vip_st_master_VIP_ID_WIDTH, axi_vip_st_master_VIP_USER_WIDTH, axi_vip_st_master_VIP_USER_BITS_PER_BYTE, axi_vip_st_master_VIP_HAS_ARESETN)

//INTERFACE & TRANSACTIONS
`include "../util/brdg_cfg_obj.sv"
`include "../util/tlx_afu_interface.sv"
`include "../util/intrp_interface.sv"
`include "../util/axi_mm_transaction.sv"
`include "../util/afu_tlx_transaction.sv"
`include "../util/tlx_afu_transaction.sv"
`include "../util/axi_lite_transaction.sv"
`include "../util/odma_desp_transaction.sv"
`include "../util/intrp_transaction.sv"
`include "../util/axi_st_transaction.sv"

//MONITORS
`ifndef ENABLE_ODMA_ST_MODE
    `include "../mon/axi_mm_monitor.sv"
`else
    `include "../mon/axi_st_monitor.sv"
`endif
`include "../mon/tlx_afu_monitor.sv"
`include "../mon/axi_lite_monitor.sv"

//SCOREBOARDS
`ifndef ENABLE_ODMA
    `include "../sb/bridge_check_scoreboard.sv"
`else
    `include "../sb/odma_check_scoreboard.sv"
`endif

//AGENTS
`include "../action_bfm/action_bfm_pkg.svh"
`include "../tl_bfm/env/tl_bfm_pkg.svh"

//SEQUENCER
`include "tb_vseqr.sv"

//VERIF TOP
`include "action_tb_env.sv"
`include "action_tb_base_test.sv"
`include "action_tb_test_lib.sv"
`include "odma_test_lib.sv"
`include "odma_test_lib_st.sv"

`endif // _ACTION_TB_PKG_SVH_
