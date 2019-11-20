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
`ifndef _TL_RX_TRANS_SV
`define _TL_RX_TRANS_SV

class tl_rx_trans extends uvm_sequence_item;
    //Data structure
    typedef enum bit [7:0] {
        NOP_R                  = 8'b0000_0000,
        MEM_RD_RESPONSE        = 8'b0000_0001,
        MEM_RD_FAIL            = 8'b0000_0010,
        MEM_RD_RESPONSE_OW     = 8'b0000_0011,
        MEM_WR_RESPONSE        = 8'b0000_0100,
        MEM_WR_FAIL            = 8'b0000_0101,
        MEM_RD_RESPONSE_XW     = 8'b0000_0111,
        RETURN_TL_CREDITS      = 8'b0000_1000,
        MEM_CNTL_DONE          = 8'b0000_1011,
        RD_WNITC               = 8'b0001_0000,
        PR_RD_WNITC            = 8'b0001_0010,
        DMA_W                  = 8'b0010_0000,
        DMA_W_BE               = 8'b0010_1000,
        DMA_PR_W               = 8'b0011_0000,
        ASSIGN_ACTAG           = 8'b0101_0000,
        INTRP_REQ              = 8'b0101_1000,
        INTRP_REQ_D            = 8'b0101_1010, 
        WAKE_HOST_THREAD       = 8'b0101_1100,
        XLATE_TOUCH            = 8'b1110_1000
        } packet_type_enum;

    //Random Variables
    rand packet_type_enum packet_type;
    rand bit              is_cmd;

    //Request field
    rand bit [63:0] Eaddr;
    rand bit [63:0] byte_enable;

    //Response field
    rand bit [15:0] CAPPTag;
    rand bit [2:0]  dP;
    rand bit [1:0]  dL;
    rand bit [3:0]  resp_code;
    rand bit        R;
    rand bit [3:0]  TL_vc0;
    rand bit [3:0]  TL_vc1;
    rand bit [5:0]  TL_dcp0;
    rand bit [5:0]  TL_dcp1;

    //Assign acTag field
    rand bit [11:0] acTag;
    rand bit [15:0] BDF;
    rand bit [19:0] PASID;

    //Interrupt field
    rand bit [3:0]  cmd_flag;
    rand bit [3:0]  stream_id;
    rand bit [63:0] obj_handle;
    rand bit [15:0] AFUTag;
    rand bit [2:0]  pL;

    //Data carrier and error queue 8byte aligned
    rand bit [63:0] data_carrier[32];   //256 Byte
    rand bit [2:0]  data_error[32];
    rand bit [71:0] xmeta[32];
    rand bit [6:0]  meta[32];
    rand int        data_carrier_type;
    rand bit [5:0]  data_template;

    real            time_stamp;

    `uvm_object_utils_begin(tl_rx_trans)
        `uvm_field_enum(packet_type_enum, packet_type,    UVM_ALL_ON)
        `uvm_field_int(is_cmd,                            UVM_ALL_ON)
        `uvm_field_int(Eaddr,                             UVM_ALL_ON)
        `uvm_field_int(byte_enable,                       UVM_ALL_ON)
        `uvm_field_int(CAPPTag,                           UVM_ALL_ON)
        `uvm_field_int(dP,                                UVM_ALL_ON)
        `uvm_field_int(dL,                                UVM_ALL_ON)
        `uvm_field_int(resp_code,                         UVM_ALL_ON)
        `uvm_field_int(R,                                 UVM_ALL_ON)
        `uvm_field_int(TL_vc0,                            UVM_ALL_ON)
        `uvm_field_int(TL_vc1,                            UVM_ALL_ON)
        `uvm_field_int(TL_dcp0,                           UVM_ALL_ON)
        `uvm_field_int(TL_dcp1,                           UVM_ALL_ON)
        `uvm_field_int(acTag,                             UVM_ALL_ON)
        `uvm_field_int(BDF,                               UVM_ALL_ON)
        `uvm_field_int(PASID,                             UVM_ALL_ON)
        `uvm_field_int(cmd_flag,                          UVM_ALL_ON)
        `uvm_field_int(stream_id,                         UVM_ALL_ON)
        `uvm_field_int(obj_handle,                        UVM_ALL_ON)
        `uvm_field_int(AFUTag,                            UVM_ALL_ON)
        `uvm_field_int(pL,                                UVM_ALL_ON)
        `uvm_field_sarray_int(data_carrier,               UVM_ALL_ON)
        `uvm_field_sarray_int(data_error,                 UVM_ALL_ON)
        `uvm_field_sarray_int(xmeta,                      UVM_ALL_ON)
        `uvm_field_sarray_int(meta ,                      UVM_ALL_ON)
        `uvm_field_int(data_carrier_type,                 UVM_ALL_ON)
        `uvm_field_int(data_template,                     UVM_ALL_ON)
        `uvm_field_real(time_stamp,                       UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end

    function new(string name="tl_rx_trans");
        super.new(name);
    endfunction: new

endclass: tl_rx_trans

`endif
