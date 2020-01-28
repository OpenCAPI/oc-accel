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
`ifndef _ACT_CFG_OBJ_SV
`define _ACT_CFG_OBJ_SV

class act_cfg_obj extends uvm_object;


    typedef enum int{
        MIN_DELAY,
        MAX_DELAY,
        RAND_DELAY,
        LITTLE_DELAY
    } t_MASTER_DELAY;

    t_MASTER_DELAY     mst_dly_mode;                            //Delay mode for master
    bit                mst_dly_adr_enable;                      //Enable address delay from the command being recevied by write/read driver
    bit                mst_dly_data_ins_enable;                 //Enable transactions data insertion delay cycles
    bit                mst_dly_beat_enable;                     //Enable inter-beat delay of beats
    bit                mst_allow_dbc;                           //Enable data beat before command being written to the interface in one transfor
 
    `uvm_object_utils_begin(act_cfg_obj)
        `uvm_field_enum         (t_MASTER_DELAY,    mst_dly_mode,       UVM_ALL_ON)
        `uvm_field_int          (mst_dly_adr_enable,                    UVM_ALL_ON)
        `uvm_field_int          (mst_dly_data_ins_enable,               UVM_ALL_ON)
        `uvm_field_int          (mst_dly_beat_enable,                   UVM_ALL_ON)
        `uvm_field_int          (mst_allow_dbc,                         UVM_ALL_ON)

    `uvm_object_utils_end

    function new(string name="act_cfg_obj");
        super.new(name);
        default_config();
    endfunction: new

    function void default_config();
        mst_dly_mode = LITTLE_DELAY;
        mst_dly_adr_enable = 1;
        mst_dly_data_ins_enable = 1;
        mst_dly_beat_enable = 1;
        mst_allow_dbc = 1;
    endfunction: default_config

endclass: act_cfg_obj

`endif

