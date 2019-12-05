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
`ifndef _BRDG_CFG_OBJ_SV
`define _BRDG_CFG_OBJ_SV

class brdg_cfg_obj extends uvm_object;

    bit cmd_rd_256_enable;        //Enable to check afu-tlx read 256B
    bit cmd_wr_256_enable;        //Enable to check afu-tlx write 256B
    int brdg_send_cmd_timer;      //Timer in ns for brdg to send commands
    bit enable_brdg_ref_model;    //Enabel referance model in bridge scoreboard
    bit enable_brdg_scoreboard;   //Enabel bridge scoreboard
    bit enable_odma_scoreboard;   //Enabel odma scoreboard
    int total_intrp_num;          //Total number of interrupt
    int total_read_num;           //Total number of read
    int total_write_num;          //Total number of write    

    `uvm_object_utils_begin(brdg_cfg_obj)
        `uvm_field_int          (cmd_rd_256_enable,                  UVM_ALL_ON)
        `uvm_field_int          (cmd_wr_256_enable,                  UVM_ALL_ON)
        `uvm_field_int          (brdg_send_cmd_timer,                UVM_ALL_ON)
        `uvm_field_int          (enable_brdg_ref_model,              UVM_ALL_ON)
        `uvm_field_int          (enable_brdg_scoreboard,             UVM_ALL_ON)
        `uvm_field_int          (enable_odma_scoreboard,             UVM_ALL_ON)
        `uvm_field_int          (total_intrp_num,                    UVM_ALL_ON)
        `uvm_field_int          (total_read_num,                     UVM_ALL_ON)
        `uvm_field_int          (total_write_num,                    UVM_ALL_ON)

    `uvm_object_utils_end

    function new(string name="brdg_cfg_obj");
        super.new(name);
        default_config();
    endfunction: new

    function void default_config();
        cmd_rd_256_enable = 1;
        cmd_wr_256_enable = 1;
        brdg_send_cmd_timer = 1000;
        enable_brdg_ref_model = 0;
        enable_brdg_scoreboard = 1;
        enable_odma_scoreboard = 0;
        total_intrp_num = 0;
        total_read_num = 0;
        total_write_num = 0;
    endfunction: default_config

endclass: brdg_cfg_obj

`endif

