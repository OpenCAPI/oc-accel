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

//UVM ENV
import uvm_pkg::*;
`include "uvm_macros.svh"

//AXI VIP PKG
import axi_vip_pkg::*;
import axi_vip_mm_check_pkg::*;
import axi_lite_passthrough_pkg::*;

`define AXI_VIP_MM_CHECK_PARAMS  #(axi_vip_mm_check_VIP_PROTOCOL    , axi_vip_mm_check_VIP_ADDR_WIDTH    , axi_vip_mm_check_VIP_DATA_WIDTH    , axi_vip_mm_check_VIP_DATA_WIDTH    , axi_vip_mm_check_VIP_ID_WIDTH    , axi_vip_mm_check_VIP_ID_WIDTH    , axi_vip_mm_check_VIP_AWUSER_WIDTH    , axi_vip_mm_check_VIP_WUSER_WIDTH    , axi_vip_mm_check_VIP_BUSER_WIDTH    , axi_vip_mm_check_VIP_ARUSER_WIDTH    , axi_vip_mm_check_VIP_RUSER_WIDTH   , axi_vip_mm_check_VIP_SUPPORTS_NARROW    , axi_vip_mm_check_VIP_HAS_BURST    , axi_vip_mm_check_VIP_HAS_LOCK    , axi_vip_mm_check_VIP_HAS_CACHE    , axi_vip_mm_check_VIP_HAS_REGION    , axi_vip_mm_check_VIP_HAS_PROT    , axi_vip_mm_check_VIP_HAS_QOS    , axi_vip_mm_check_VIP_HAS_WSTRB    , axi_vip_mm_check_VIP_HAS_BRESP    , axi_vip_mm_check_VIP_HAS_RRESP    , axi_vip_mm_check_VIP_HAS_ARESETN   )
`define AXI_LITE_PARAMS          #(axi_lite_passthrough_VIP_PROTOCOL, axi_lite_passthrough_VIP_ADDR_WIDTH, axi_lite_passthrough_VIP_DATA_WIDTH, axi_lite_passthrough_VIP_DATA_WIDTH, axi_lite_passthrough_VIP_ID_WIDTH, axi_lite_passthrough_VIP_ID_WIDTH, axi_lite_passthrough_VIP_AWUSER_WIDTH, axi_lite_passthrough_VIP_WUSER_WIDTH, axi_lite_passthrough_VIP_BUSER_WIDTH, axi_lite_passthrough_VIP_ARUSER_WIDTH,axi_lite_passthrough_VIP_RUSER_WIDTH, axi_lite_passthrough_VIP_SUPPORTS_NARROW, axi_lite_passthrough_VIP_HAS_BURST, axi_lite_passthrough_VIP_HAS_LOCK, axi_lite_passthrough_VIP_HAS_CACHE, axi_lite_passthrough_VIP_HAS_REGION, axi_lite_passthrough_VIP_HAS_PROT, axi_lite_passthrough_VIP_HAS_QOS, axi_lite_passthrough_VIP_HAS_WSTRB, axi_lite_passthrough_VIP_HAS_BRESP, axi_lite_passthrough_VIP_HAS_RRESP, axi_lite_passthrough_VIP_HAS_ARESETN)

//INTERFACE & TRANSACTIONS
`include "../util/brdg_cfg_obj.sv"
`include "../util/tlx_afu_interface.sv"
`include "../util/intrp_interface.sv"
`include "../util/axi_mm_transaction.sv"
`include "../util/afu_tlx_transaction.sv"
`include "../util/tlx_afu_transaction.sv"
`include "../util/axi_lite_transaction.sv"
`include "../util/intrp_transaction.sv"

//MONITORS
`include "../mon/axi_mm_monitor.sv"
`include "../mon/tlx_afu_monitor.sv"
`include "../mon/axi_lite_monitor.sv"

//SCOREBOARDS
`include "../sb/bridge_check_scoreboard.sv"

//AGENTS
`include "../tl_bfm/env/tl_bfm_pkg.svh"

//SEQUENCER
`include "tb_vseqr.sv"

//VERIF TOP
`include "action_tb_env.sv"
`include "action_tb_base_test.sv"
`include "action_tb_test_lib.sv"
`include "odma_test_lib.sv"

`endif // _ACTION_TB_PKG_SVH_
