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
import axi_lite_vip_master_pkg::*;

module odma_axi_lite_master		#(
								parameter  AXIL_ADDR_WIDTH   = 32,
								parameter  AXIL_DATA_WIDTH   = 32 
								 )
										(
    input                                 clk           ,
	input								  aresetn		,
                                     
	output                                m_lite_arvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]        m_lite_araddr ,         
    input                                 m_lite_arready, 
	
    input                                 m_lite_rvalid ,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]       m_lite_rdata  ,          
    input  [1 : 0 ]                       m_lite_rresp  ,          
    output                                m_lite_rready ,
	
    output                                m_lite_awvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]        m_lite_awaddr ,         
    input                                 m_lite_awready,
    
    output                                m_lite_wvalid ,         
    output [AXIL_DATA_WIDTH-1 : 0 ]       m_lite_wdata  ,          
    output [(AXIL_DATA_WIDTH/8)-1 : 0 ]   m_lite_wstrb  ,          
    input                                 m_lite_wready , 
	
    input                                 m_lite_bvalid ,         
    input  [1 : 0 ]                       m_lite_bresp  ,          
    output                                m_lite_bready 
										);


	
axi_lite_vip_master master(
						.aclk(clk),
						.aresetn(aresetn),
						
						.m_axi_awaddr (m_lite_awaddr),
						.m_axi_awvalid(m_lite_awvalid),
						.m_axi_awready(m_lite_awready),
						
						.m_axi_wdata  (m_lite_wdata),
						.m_axi_wstrb  (m_lite_wstrb),
						.m_axi_wvalid (m_lite_wvalid),
						.m_axi_wready (m_lite_wready),
						
						.m_axi_bresp  (m_lite_bresp),
						.m_axi_bvalid (m_lite_bvalid),
						.m_axi_bready (m_lite_bready),
						
						.m_axi_araddr (m_lite_araddr),
						.m_axi_arvalid(m_lite_arvalid),
						.m_axi_arready(m_lite_arready),
						
						.m_axi_rdata (m_lite_rdata),
						.m_axi_rresp (m_lite_rresp),
						.m_axi_rvalid(m_lite_rvalid),
						.m_axi_rready(m_lite_rready)
						);
						
	axi_lite_vip_master_mst_t  axi_lite_vip_master_mst;

	initial begin : START_axi_lite_vip_master_MASTER
        axi_lite_vip_master_mst = new("axi_lite_vip_master_mst", master.inst.IF);
		
		master.inst.IF.set_enable_xchecks_to_warn();
		master.inst.IF.set_xilinx_reset_check_to_warn();
		
		axi_lite_vip_master_mst.start_master();
	end

endmodule
