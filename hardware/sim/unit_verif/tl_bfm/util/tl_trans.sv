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
`ifndef _TL_TRANS_SV
`define _TL_TRANS_SV

class tl_trans extends uvm_sequence_item;

    rand tl_tx_trans::packet_type_enum  tx_packet_type;
    rand bit               tx_config_type;
    rand bit [2:0]         tx_plength;
    rand bit [1:0]         tx_dlength;
    rand bit [15:0]        tx_capp_tag;
    rand bit [63:0]        tx_byte_enable;
    rand bit [63:0]        tx_physical_addr;
    rand bit [3:0]         tx_cmd_flag;
    rand bit [63:0]        tx_object_handle;
    rand bit [7:0]         tx_mad;
    rand bit [63:0]        tx_data_carrier[32];
    rand bit [2:0]         tx_data_error[32];           
    rand bit [71:0]        tx_xmeta[32];
    rand bit [6:0]         tx_meta[32];
    rand bit [5:0]         tx_data_template;    
    rand int               tx_data_carrier_type;

    rand tl_rx_trans::packet_type_enum rx_packet_type;
    rand bit [15:0] rx_CAPPTag;
    rand bit [2:0]  rx_dP;
    rand bit [1:0]  rx_dL;
    rand bit [3:0]  rx_resp_code;
    rand bit        rx_R;
    rand bit [63:0] rx_data_carrier[32];   
    rand bit [2:0]  rx_data_error[32];
    rand bit [71:0] rx_xmeta[32];
    rand bit [6:0]  rx_meta[32];
    rand bit [5:0]  rx_data_template;     
    rand int        rx_data_carrier_type;



    `uvm_object_utils_begin(tl_trans)
        `uvm_field_enum   (tl_tx_trans::packet_type_enum, tx_packet_type, UVM_ALL_ON)
        `uvm_field_int                    (tx_config_type,   UVM_ALL_ON)
        `uvm_field_int                    (tx_plength,       UVM_ALL_ON)
        `uvm_field_int                    (tx_dlength,       UVM_ALL_ON)
        `uvm_field_int                    (tx_capp_tag,      UVM_ALL_ON)
        `uvm_field_int                    (tx_byte_enable,   UVM_ALL_ON)
        `uvm_field_int                    (tx_physical_addr, UVM_ALL_ON)
        `uvm_field_int                    (tx_cmd_flag,      UVM_ALL_ON)
        `uvm_field_int                    (tx_object_handle, UVM_ALL_ON)
        `uvm_field_int                    (tx_mad,           UVM_ALL_ON)
        `uvm_field_sarray_int             (tx_data_carrier,  UVM_ALL_ON)
        `uvm_field_sarray_int             (tx_data_error,    UVM_ALL_ON)
        `uvm_field_sarray_int             (tx_xmeta,         UVM_ALL_ON)
        `uvm_field_int(tx_data_carrier_type,                 UVM_ALL_ON)
        `uvm_field_sarray_int             (tx_meta,          UVM_ALL_ON)
        `uvm_field_int                    (tx_data_template, UVM_ALL_ON)           

        `uvm_field_enum   (tl_rx_trans::packet_type_enum, rx_packet_type, UVM_ALL_ON)
        `uvm_field_int(rx_CAPPTag,                           UVM_ALL_ON)
        `uvm_field_int(rx_dP,                                UVM_ALL_ON)
        `uvm_field_int(rx_dL,                                UVM_ALL_ON)
        `uvm_field_int(rx_resp_code,                         UVM_ALL_ON)
        `uvm_field_int(rx_R,                                 UVM_ALL_ON)
        `uvm_field_sarray_int(rx_data_carrier,               UVM_ALL_ON)
        `uvm_field_sarray_int(rx_data_error,                 UVM_ALL_ON)
        `uvm_field_sarray_int(rx_xmeta,                      UVM_ALL_ON)
        `uvm_field_int(rx_data_carrier_type,                 UVM_ALL_ON)
        `uvm_field_sarray_int   (rx_meta,                    UVM_ALL_ON)
        `uvm_field_int          (rx_data_template,           UVM_ALL_ON)           
    `uvm_object_utils_end

    function new(string name="tl_trans");
        super.new(name);
    endfunction: new

endclass: tl_trans

`endif
