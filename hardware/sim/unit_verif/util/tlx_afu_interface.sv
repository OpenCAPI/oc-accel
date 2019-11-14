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
//------------------------------------------------------------------------------
//
// CLASS: tlx_afu_interface
//
//------------------------------------------------------------------------------
`ifndef _TLX_AFU_INTERFACE_SV
`define _TLX_AFU_INTERFACE_SV

interface tlx_afu_interface (input logic tlx_clock, input logic afu_clock);

    // Table 1: TLX to AFU Response Interface
    logic             tlx_afu_resp_valid_top;
    logic       [7:0] tlx_afu_resp_opcode_top;
    logic      [15:0] tlx_afu_resp_afutag_top;
    logic       [3:0] tlx_afu_resp_code_top;
    logic       [5:0] tlx_afu_resp_pg_size_top;
    logic       [1:0] tlx_afu_resp_dl_top;
    logic       [1:0] tlx_afu_resp_dp_top;
    logic      [23:0] tlx_afu_resp_host_tag_top;
    logic      [17:0] tlx_afu_resp_addr_tag_top;
    logic       [3:0] tlx_afu_resp_cache_state_top;

    // Table 2: TLX Response Credit Interface
    logic             afu_tlx_resp_credit_top;
    logic       [6:0] afu_tlx_resp_initial_credit_top;

    // Table 3: TLX to AFU Command Interface
    logic             tlx_afu_cmd_valid_top;
    logic       [7:0] tlx_afu_cmd_opcode_top;
    logic      [15:0] tlx_afu_cmd_capptag_top;
    logic       [1:0] tlx_afu_cmd_dl_top;
    logic       [2:0] tlx_afu_cmd_pl_top;
    logic      [63:0] tlx_afu_cmd_be_top;
    logic             tlx_afu_cmd_end_top;
//    logic             tlx_afu_cmd_t_top;
    logic      [63:0] tlx_afu_cmd_pa_top;
    logic       [3:0] tlx_afu_cmd_flag_top;
    logic             tlx_afu_cmd_os_top;

    // Table 4: TLX Command Credit Interface
    logic             afu_tlx_cmd_credit_top;
    logic       [6:0] afu_tlx_cmd_initial_credit_top;

    // Table 5: TLX to AFU Response Data Interface
    logic             tlx_afu_resp_data_valid_top;
    logic     [511:0] tlx_afu_resp_data_bus_top;
    logic             tlx_afu_resp_data_bdi_top;
    logic             afu_tlx_resp_rd_req_top;
    logic       [2:0] afu_tlx_resp_rd_cnt_top;

    // Table 6: TLX to AFU Command Data Interface
    logic             tlx_afu_cmd_data_valid_top;
    logic     [511:0] tlx_afu_cmd_data_bus_top;
    logic             tlx_afu_cmd_data_bdi_top;

    logic   afu_tlx_cmd_rd_req_top;
    logic       [2:0] afu_tlx_cmd_rd_cnt_top;

    // Table 7: TLX Framer credit interface
    logic             tlx_afu_resp_credit_top;
    logic             tlx_afu_resp_data_credit_top;
    logic             tlx_afu_cmd_credit_top;
    logic             tlx_afu_cmd_data_credit_top;
    logic       [3:0] tlx_afu_cmd_resp_initial_credit_top;
    logic       [3:0] tlx_afu_data_initial_credit_top;
    logic       [5:0] tlx_afu_cmd_data_initial_credit_top;
    logic       [5:0] tlx_afu_resp_data_initial_credit_top;

    // Table 8: TLX Framer Command Interface
    logic             afu_tlx_cmd_valid_top;
    logic       [7:0] afu_tlx_cmd_opcode_top;
    logic      [11:0] afu_tlx_cmd_actag_top;
    logic       [3:0] afu_tlx_cmd_stream_id_top;
    logic      [67:0] afu_tlx_cmd_ea_or_obj_top;
    logic      [15:0] afu_tlx_cmd_afutag_top;
    logic       [1:0] afu_tlx_cmd_dl_top;
    logic       [2:0] afu_tlx_cmd_pl_top;
    logic             afu_tlx_cmd_os_top;
    logic      [63:0] afu_tlx_cmd_be_top;
    logic       [3:0] afu_tlx_cmd_flag_top;
    logic             afu_tlx_cmd_endian_top;
    logic      [15:0] afu_tlx_cmd_bdf_top;
    logic      [19:0] afu_tlx_cmd_pasid_top;
    logic       [5:0] afu_tlx_cmd_pg_size_top;
    logic     [511:0] afu_tlx_cdata_bus_top;
    logic             afu_tlx_cdata_bdi_top;// TODO: TLX Ref Design doc lists this as afu_tlx_cdata_bad
    logic             afu_tlx_cdata_valid_top;

    // Table 9: TLX Framer Response Interface
    logic             afu_tlx_resp_valid_top;
    logic       [7:0] afu_tlx_resp_opcode_top;
    logic       [1:0] afu_tlx_resp_dl_top;
    logic      [15:0] afu_tlx_resp_capptag_top;
    logic       [1:0] afu_tlx_resp_dp_top;
    logic       [3:0] afu_tlx_resp_code_top;
    logic             afu_tlx_rdata_valid_top;
    logic     [511:0] afu_tlx_rdata_bus_top;
    logic             afu_tlx_rdata_bdi_top;

    // These signals do not appear on the RefDesign Doc. However it is present
    // on the TLX spec
// mcp3 update on 12/Jun/2017 - port is absent    logic             afu_cfg_in_rcv_tmpl_capability_0_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic             afu_cfg_in_rcv_tmpl_capability_1_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic             afu_cfg_in_rcv_tmpl_capability_2_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic             afu_cfg_in_rcv_tmpl_capability_3_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic [3:0]       afu_cfg_in_rcv_rate_capability_0_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic [3:0]       afu_cfg_in_rcv_rate_capability_1_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic [3:0]       afu_cfg_in_rcv_rate_capability_2_top;
// mcp3 update on 12/Jun/2017 - port is absent    logic [3:0]       afu_cfg_in_rcv_rate_capability_3_top;
    logic             tlx_afu_ready_top;
    logic             tlx_cfg0_in_rcv_tmpl_capability_0_top;
    logic             tlx_cfg0_in_rcv_tmpl_capability_1_top;
    logic             tlx_cfg0_in_rcv_tmpl_capability_2_top;
    logic             tlx_cfg0_in_rcv_tmpl_capability_3_top;
    logic       [3:0] tlx_cfg0_in_rcv_rate_capability_0_top;
    logic       [3:0] tlx_cfg0_in_rcv_rate_capability_1_top;
    logic       [3:0] tlx_cfg0_in_rcv_rate_capability_2_top;
    logic       [3:0] tlx_cfg0_in_rcv_rate_capability_3_top;
    logic             tlx_cfg0_valid_top;
    logic       [7:0] tlx_cfg0_opcode_top;
    logic      [63:0] tlx_cfg0_pa_top;
    logic             tlx_cfg0_t_top;
    logic       [2:0] tlx_cfg0_pl_top;
    logic      [15:0] tlx_cfg0_capptag_top;
    logic      [31:0] tlx_cfg0_data_bus_top;
    logic             tlx_cfg0_data_bdi_top;
    logic             tlx_cfg0_resp_ack_top;
    logic       [3:0] cfg0_tlx_initial_credit_top;
    logic             cfg0_tlx_credit_return_top;
    logic             cfg0_tlx_resp_valid_top ;
    logic       [7:0] cfg0_tlx_resp_opcode_top;
    logic      [15:0] cfg0_tlx_resp_capptag_top;
    logic       [3:0] cfg0_tlx_resp_code_top ;
    logic       [3:0] cfg0_tlx_rdata_offset_top;
    logic      [31:0] cfg0_tlx_rdata_bus_top ;
    logic             cfg0_tlx_rdata_bdi_top;
    logic       [4:0] ro_device_top;

endinterface: tlx_afu_interface

`endif
