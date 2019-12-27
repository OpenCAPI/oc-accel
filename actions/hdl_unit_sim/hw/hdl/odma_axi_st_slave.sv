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

`timescale 1ns/1ps


//UVM ENV
import uvm_pkg::*;
`include "uvm_macros.svh"

//AXI VIP PKG
import axi_vip_pkg::*;
import axi_st_vip_slave_pkg::*;

module odma_axi_st_slave #(
    parameter AXIS_ID_WIDTH     = 5,
    parameter AXIS_DATA_WIDTH   = 1024,
    parameter AXIS_USER_WIDTH   = 9)
(
    input                               clk,
    input                               rst_n,
    //----- AXI4 stream interface -----
    input                             axis_tvalid,        //AXI stream valid
    output                            axis_tready,        //AXI stream ready
    input  [AXIS_DATA_WIDTH-1 : 0 ]   axis_tdata,         //AXI stream data
    input  [AXIS_DATA_WIDTH/8-1 : 0 ] axis_tkeep,         //AXI stream keep
    input                             axis_tlast,         //AXI stream last
    input  [AXIS_ID_WIDTH-1 : 0 ]     axis_tid,           //AXI stream ID
    input  [AXIS_USER_WIDTH-1 : 0 ]   axis_tuser          //AXI stream user
);
    
axi_st_vip_slave st_slave(
    .aclk               (clk),
    .aresetn            (rst_n),
    .s_axis_tvalid      (axis_tvalid),
    .s_axis_tready      (axis_tready),
    .s_axis_tdata       (axis_tdata),
    .s_axis_tkeep       (axis_tkeep),
    .s_axis_tlast       (axis_tlast),
    .s_axis_tid         (axis_tid),
    .s_axis_tuser       (axis_tuser)
);

axi_st_vip_slave_slv_t  axi_st_vip_slave_slv;
initial begin : START_axi_st_vip_slave_SLAVE
    axi_st_vip_slave_slv = new("axi_st_vip_slave_slv", st_slave.inst.IF);
    axi_st_vip_slave_slv.start_slave();
    st_slave.inst.IF.set_enable_xchecks_to_warn();
    st_slave.inst.IF.set_xilinx_reset_check_to_warn();
end	

endmodule
