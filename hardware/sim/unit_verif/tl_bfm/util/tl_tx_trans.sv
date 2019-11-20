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
`ifndef _TL_TX_TRANS_SV
`define _TL_TX_TRANS_SV

class tl_tx_trans extends uvm_sequence_item;
    typedef enum bit [7:0] {
        NOP                    = 8'b0000_0000,
        RETURN_TLX_CREDITS     = 8'b0000_0001,
        TOUCH_RESP             = 8'b0000_0010,
        READ_RESPONSE          = 8'b0000_0100,
        READ_FAILED            = 8'b0000_0101,
        WRITE_RESPONSE         = 8'b0000_1000,
        WRITE_FAILED           = 8'b0000_1001,
        INTRP_RESP             = 8'b0000_1100,
        WAKE_HOST_RESP         = 8'b0001_0000,
        XLATE_DONE             = 8'b0001_1000,
        INTRP_RDY              = 8'b0001_1010,
        RD_MEM                 = 8'b0010_0000,
        RD_PF                  = 8'b0010_0010,
        PR_RD_MEM              = 8'b0010_1000,
        PAD_MEM                = 8'b1000_0000,
        WRITE_MEM              = 8'b1000_0001,
        WRITE_MEM_BE           = 8'b1000_0010,
        PR_WR_MEM              = 8'b1000_0110,
        CONFIG_READ            = 8'b1110_0000,
        CONFIG_WRITE           = 8'b1110_0001,
        MEM_CNTL               = 8'b1110_1111
        } packet_type_enum;

    bit                    is_cmd;
    rand bit               config_type;
    rand bit [2:0]         plength;
    rand bit [1:0]         dlength;
    rand bit [1:0]         dpart;
    rand bit [15:0]        capp_tag;
    rand bit [15:0]        afu_tag;
    rand bit [63:0]        byte_enable;
    rand bit [63:0]        physical_addr;
    rand bit [3:0]         cmd_flag;
    rand bit [63:0]        object_handle;
    rand bit [7:0]         mad;
    rand bit [3:0]         resp_code;
    rand bit [5:0]         tlx_dcp_3;
    rand bit [5:0]         tlx_dcp_0;
    rand bit [3:0]         tlx_vc_3;
    rand bit [3:0]         tlx_vc_0;
    
    rand bit [63:0]        data_carrier[32];
    rand bit [2:0]         data_error[32];           // data_error array associated with data carrier data_error[2:1] for ecc, data_error[0] for bad data field or bad data flit
    rand bit [71:0]        xmeta[32];                // xmeta array associated with data carrier 
    rand bit [6:0]         meta[32];                 // xmeta array associated with data carrier 
                                                     // data flit---xmeta[6:0] is mdf value
                                                     // data field of template 7---xmeta[6:0] is meta value
                                                     // data field of template A---xmeta[71:0] is xmeta value
    rand int               data_carrier_type;
    rand bit [5:0]         data_template;

    bit                    intrp_handler_begin;   
    bit                    intrp_handler_end;

    real                   time_stamp;
                                    

    rand packet_type_enum  packet_type;

    `uvm_object_utils_begin(tl_tx_trans)
        `uvm_field_int          (is_cmd,                        UVM_ALL_ON)
        `uvm_field_int          (config_type,                   UVM_ALL_ON)
        `uvm_field_int          (plength,                       UVM_ALL_ON)
        `uvm_field_int          (dlength,                       UVM_ALL_ON)
        `uvm_field_int          (dpart,                         UVM_ALL_ON)
        `uvm_field_int          (capp_tag,                      UVM_ALL_ON)
        `uvm_field_int          (afu_tag,                       UVM_ALL_ON)
        `uvm_field_int          (byte_enable,                   UVM_ALL_ON)
        `uvm_field_int          (physical_addr,                 UVM_ALL_ON)
        `uvm_field_int          (cmd_flag,                      UVM_ALL_ON)
        `uvm_field_int          (object_handle,                 UVM_ALL_ON)
        `uvm_field_int          (mad,                           UVM_ALL_ON)
        `uvm_field_int          (resp_code,                     UVM_ALL_ON)
        `uvm_field_int          (tlx_dcp_3,                     UVM_ALL_ON)
        `uvm_field_int          (tlx_dcp_0,                     UVM_ALL_ON)
        `uvm_field_int          (tlx_vc_3,                      UVM_ALL_ON)
        `uvm_field_int          (tlx_vc_0,                      UVM_ALL_ON)
        `uvm_field_sarray_int   (data_carrier,                  UVM_ALL_ON)
        `uvm_field_sarray_int   (data_error,                    UVM_ALL_ON)
        `uvm_field_sarray_int   (xmeta,                         UVM_ALL_ON)
        `uvm_field_sarray_int   (meta,                          UVM_ALL_ON)
        `uvm_field_enum         (packet_type_enum, packet_type, UVM_ALL_ON)
        `uvm_field_int          (data_carrier_type,             UVM_ALL_ON)
        `uvm_field_int          (data_template,                 UVM_ALL_ON)
        `uvm_field_real         (time_stamp,                    UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end

    function new(string name="tl_tx_trans");
        super.new(name);
        is_cmd = 1;
        config_type = 0;
        intrp_handler_begin = 0;
        intrp_handler_end = 0;
    endfunction: new

endclass: tl_tx_trans

`endif
