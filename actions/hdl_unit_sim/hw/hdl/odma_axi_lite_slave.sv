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
import axi_lite_vip_slave_pkg::*;

module odma_axi_lite_slave #(
								parameter  AXIL_ADDR_WIDTH   = 32,
								parameter  AXIL_DATA_WIDTH   = 32 
							)
										(
    input                                 clk           ,
	input								  aresetn		,
/* AXI lite master interface */                                      
    input                                 s_lite_arvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]        s_lite_araddr ,         
    output                                s_lite_arready,
	
    output                                s_lite_rvalid ,         
    output [AXIL_DATA_WIDTH-1 : 0 ]       s_lite_rdata  ,          
    output [1 : 0 ]                       s_lite_rresp  ,          
    input                                 s_lite_rready ,
	
    input                                 s_lite_awvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]        s_lite_awaddr ,         
    output                                s_lite_awready,
	
    input                                 s_lite_wvalid ,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]       s_lite_wdata  ,          
    input  [(AXIL_DATA_WIDTH/8)-1 : 0 ]   s_lite_wstrb  ,          
    output                                s_lite_wready ,
	
    output                                s_lite_bvalid ,         
    output [1 : 0 ]                       s_lite_bresp  ,          
    input                                 s_lite_bready 
										);
											 
axi_lite_vip_slave slave(
						.aclk(clk),
						.aresetn(aresetn),
						
						.s_axi_awaddr(s_lite_awaddr),
						.s_axi_awvalid(s_lite_awvalid),
						.s_axi_awready(s_lite_awready),
						
						.s_axi_wdata(s_lite_wdata),
						.s_axi_wstrb(s_lite_wstrb),
						.s_axi_wvalid(s_lite_wvalid),
						.s_axi_wready(s_lite_wready),
						
						.s_axi_bresp(s_lite_bresp),
						.s_axi_bvalid(s_lite_bvalid),
						.s_axi_bready(s_lite_bready),
						
						.s_axi_araddr(s_lite_araddr),
						.s_axi_arvalid(s_lite_arvalid),
						.s_axi_arready(s_lite_arready),
						
						.s_axi_rdata(s_lite_rdata),
						.s_axi_rresp(s_lite_rresp),
						.s_axi_rvalid(s_lite_rvalid),
						.s_axi_rready(s_lite_rready)
						);
						
	axi_lite_vip_slave_slv_mem_t  axi_lite_vip_slave_slv_mem;

    initial begin : START_axi_lite_vip_slave_SLAVE
		axi_lite_vip_slave_slv_mem = new("axi_lite_vip_slave_slv_mem", slave.inst.IF);
		
		slave.inst.IF.set_enable_xchecks_to_warn();
		slave.inst.IF.set_xilinx_reset_check_to_warn();
	
		axi_lite_vip_slave_slv_mem.start_slave();
	end

//initialize memory in odma_axi_lite_slave here, the codes below is an example
//the format is :
// axi_lite_vip_slave_slv_mem.mem_model.backdoor_memory_write(AXIL_ADDR[31:0], AXIL_DATA[31:0], strb[3:0]);
//if you do not initialize the memory, it will return random number

/*
initial begin

	axi_lite_vip_slave_slv_mem.mem_model.backdoor_memory_write(32'h0000_004C, 32'hFD55_9826, 4'b1111);

end
*/
endmodule
