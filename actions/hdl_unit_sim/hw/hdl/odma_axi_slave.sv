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
import axi_vip_slave_pkg::*;

module odma_axi_slave #(
    parameter AXI_ID_WIDTH      = 5,
    parameter AXI_ADDR_WIDTH    = 64,
    parameter AXI_DATA_WIDTH    = 1024,
    parameter AXI_AWUSER_WIDTH  = 9,
    parameter AXI_ARUSER_WIDTH  = 9,
    parameter AXI_WUSER_WIDTH   = 1,
    parameter AXI_RUSER_WIDTH   = 1,
    parameter AXI_BUSER_WIDTH   = 1
)
(
    input                               clk,
    input                               rst_n,
    //----- AXI4 read addr interface -----
    input  [AXI_ADDR_WIDTH-1 : 0]       axi_araddr,         
    input  [1 : 0]                      axi_arburst,        
    input  [3 : 0]                      axi_arcache,        
    input  [AXI_ID_WIDTH-1 : 0]         axi_arid,           
    input  [7 : 0]                      axi_arlen,         
    input  [1 : 0]                      axi_arlock,         
    input  [2 : 0]                      axi_arprot,         
    input  [3 : 0]                      axi_arqos,          
    output                              axi_arready,       
    input  [3 : 0]                      axi_arregion,       
    input  [2 : 0]                      axi_arsize,         
    input  [AXI_ARUSER_WIDTH-1 : 0]     axi_aruser,         
    input                               axi_arvalid,       
    //----- AXI4 read data interface -----
    output [AXI_DATA_WIDTH-1 : 0 ]      axi_rdata,          
    output [AXI_ID_WIDTH-1 : 0 ]        axi_rid,            
    output                              axi_rlast,          
    input                               axi_rready,         
    output [1 : 0 ]                     axi_rresp,        
    output [AXI_RUSER_WIDTH-1 : 0 ]     axi_ruser,          
    output                              axi_rvalid,         
    //----- AXI4 write addr interface -----
    input  [AXI_ADDR_WIDTH-1 : 0]       axi_awaddr,         
    input  [1 : 0]                      axi_awburst,        
    input  [3 : 0]                      axi_awcache,        
    input  [AXI_ID_WIDTH-1 : 0]         axi_awid,           
    input  [7 : 0]                      axi_awlen,         
    input  [1 : 0]                      axi_awlock,         
    input  [2 : 0]                      axi_awprot,         
    input  [3 : 0]                      axi_awqos,          
    output                              axi_awready,       
    input  [3 : 0]                      axi_awregion,       
    input  [2 : 0]                      axi_awsize,         
    input  [AXI_ARUSER_WIDTH-1 : 0]     axi_awuser,         
    input                               axi_awvalid,       
    //----- AXI4 write data interface -----
    input  [AXI_DATA_WIDTH-1 : 0 ]      axi_wdata,          
    input  [(AXI_DATA_WIDTH/8)-1 : 0 ]  axi_wstrb,          
    input                               axi_wlast,          
    input  [AXI_WUSER_WIDTH-1 : 0 ]     axi_wuser,          
    input                               axi_wvalid,         
    output                              axi_wready,         
    //----- AXI4 write resp interface -----
    output                              axi_bvalid,         
    output [1 : 0]                      axi_bresp,         
    output [AXI_BUSER_WIDTH-1 : 0 ]     axi_buser,          
    output [AXI_ID_WIDTH-1 : 0 ]        axi_bid,
    input                               axi_bready 
										);

wire [AXI_BUSER_WIDTH-1 : 0 ]     tempwire;

	axi_vip_slave slave(
							.aclk          ( clk          ),
							.aresetn       ( rst_n        ),
							
							.s_axi_awid    ( axi_awid     ),
							.s_axi_awaddr  ( axi_awaddr   ),
							.s_axi_awlen   ( axi_awlen    ),
							.s_axi_awsize  ( axi_awsize   ),
							.s_axi_awburst ( axi_awburst  ),
							.s_axi_awlock  ( axi_awlock   ),
							.s_axi_awcache ( axi_awcache  ),
							.s_axi_awprot  ( axi_awprot   ),
							.s_axi_awregion( axi_awregion ),
							.s_axi_awqos   ( 4'B0         ),
  							.s_axi_awuser  ( 9'B0         ),
  							.s_axi_awvalid ( axi_awvalid  ),
  							.s_axi_awready ( axi_awready  ),
							
  							.s_axi_wdata   ( axi_wdata    ),
  							.s_axi_wstrb   ( axi_wstrb    ),
  							.s_axi_wlast   ( axi_wlast    ),
  							.s_axi_wuser   ( axi_wuser    ),
  							.s_axi_wvalid  ( axi_wvalid   ),
  							.s_axi_wready  ( axi_wready   ),
							
  							.s_axi_bid     ( axi_bid      ),
  							.s_axi_bresp   ( axi_bresp    ),
  							.s_axi_buser   ( axi_buser     ),
  							.s_axi_bvalid  ( axi_bvalid   ),
  							.s_axi_bready  ( axi_bready   ),
							
  							.s_axi_arid    ( axi_arid     ),
  							.s_axi_araddr  ( axi_araddr   ),
  							.s_axi_arlen   ( axi_arlen    ),
  							.s_axi_arsize  ( axi_arsize   ),
  							.s_axi_arburst ( axi_arburst  ),
  							.s_axi_arlock  ( axi_arlock   ),
  							.s_axi_arcache ( axi_arcache  ),
  							.s_axi_arprot  ( axi_arprot   ),
  							.s_axi_arregion( axi_arregion ),
  							.s_axi_arqos   ( axi_arqos    ),
  							.s_axi_aruser  ( axi_aruser   ),
  							.s_axi_arvalid ( axi_arvalid  ),
  							.s_axi_arready ( axi_arready  ),

  							.s_axi_rid     ( axi_rid      ),
  							.s_axi_rdata   ( axi_rdata    ),
  							.s_axi_rresp   ( axi_rresp    ),
  							.s_axi_rlast   ( axi_rlast    ),
  							.s_axi_ruser   ( axi_ruser    ),
  							.s_axi_rvalid  ( axi_rvalid   ),
  							.s_axi_rready  ( axi_rready   )
							     
);
						
	axi_vip_slave_slv_mem_t  axi_vip_slave_slv_mem;

    initial begin : START_axi_lite_vip_slave_SLAVE
		axi_vip_slave_slv_mem = new("axi_vip_slave_slv_mem", slave.inst.IF);
		
		slave.inst.IF.set_enable_xchecks_to_warn();
		slave.inst.IF.set_xilinx_reset_check_to_warn();
	
		axi_vip_slave_slv_mem.start_slave();
	end

//initialize memory in odma_axi_slave here, the codes below is an example
//the format is :
// axi_vip_slave_slv_mem.mem_model.backdoor_memory_write(AXIL_ADDR[63:0], AXIL_DATA[1023:0], strb[3:0]);
//if you do not initialize the memory, it will return random number

/*
initial begin

	axi_vip_slave_slv_mem.mem_model.backdoor_memory_write(32'h0000_004C, 32'hFD55_9826, 4'b1111);

end
*/
endmodule
