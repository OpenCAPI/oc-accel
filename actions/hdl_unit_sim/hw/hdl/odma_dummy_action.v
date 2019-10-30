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
module odma_dummy_action #(
    parameter AXI_ID_WIDTH      = 5,
    parameter AXI_ADDR_WIDTH    = 64,
    parameter AXI_DATA_WIDTH    = 1024,
    parameter AXI_AWUSER_WIDTH  = 9,
    parameter AXI_ARUSER_WIDTH  = 9,
    parameter AXI_WUSER_WIDTH   = 1,
    parameter AXI_RUSER_WIDTH   = 1,
    parameter AXI_BUSER_WIDTH   = 1,
    parameter AXIL_ADDR_WIDTH   = 32,
    parameter AXIL_DATA_WIDTH   = 32
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
    output reg                          axi_rvalid,         
    //----- AXI4 write addr interface -----
    input  [AXI_ADDR_WIDTH-1 : 0]       axi_awaddr,         
    input  [1 : 0]                      axi_awburst,        
    input  [3 : 0]                      axi_awcache,        
    input  [AXI_ID_WIDTH-1 : 0]         axi_awid,           
    input  [7 : 0]                      axi_awlen,         
    input  [1 : 0]                      axi_awlock,         
    input  [2 : 0]                      axi_awprot,         
    input  [3 : 0]                      axi_awqos,          
    output reg                          axi_awready,       
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
    output reg                          axi_wready,         
    //----- AXI4 write resp interface -----
    output reg                          axi_bvalid,         
    output [1 : 0]                      axi_bresp,         
    output [AXI_BUSER_WIDTH-1 : 0 ]     axi_buser,          
    output [AXI_ID_WIDTH-1 : 0 ]        axi_bid,
    input                               axi_bready,
    //----- AXI lite slave interface -----
    input                               s_lite_arvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]      s_lite_araddr,         
    output reg                          s_lite_arready,        
    output reg                          s_lite_rvalid,         
    output [AXIL_DATA_WIDTH-1 : 0 ]     s_lite_rdata,          
    output [1 : 0 ]                     s_lite_rresp,          
    input                               s_lite_rready,         
    input                               s_lite_awvalid,        
    input  [AXIL_ADDR_WIDTH-1 : 0]      s_lite_awaddr,         
    output reg                          s_lite_awready,        
    input                               s_lite_wvalid,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]     s_lite_wdata,          
    input  [(AXIL_DATA_WIDTH/8)-1 : 0 ] s_lite_wstrb,          
    output reg                          s_lite_wready,         
    output reg                          s_lite_bvalid,         
    output [1 : 0 ]                     s_lite_bresp,          
    input                               s_lite_bready,         
    //----- AXI lite master interface -----
    output                              m_lite_arvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]      m_lite_araddr,         
    input                               m_lite_arready,        
    input                               m_lite_rvalid,         
    input  [AXIL_DATA_WIDTH-1 : 0 ]     m_lite_rdata,          
    input  [1 : 0 ]                     m_lite_rresp,          
    output                              m_lite_rready,         
    output                              m_lite_awvalid,        
    output [AXIL_ADDR_WIDTH-1 : 0]      m_lite_awaddr,         
    input                               m_lite_awready,        
    output                              m_lite_wvalid,         
    output [AXIL_DATA_WIDTH-1 : 0 ]     m_lite_wdata,          
    output [(AXIL_DATA_WIDTH/8)-1 : 0 ] m_lite_wstrb,          
    input                               m_lite_wready,         
    input                               m_lite_bvalid,         
    input  [1 : 0 ]                     m_lite_bresp,          
    output                              m_lite_bready       
);
//------------------------------------------------------------------------------
parameter AXIL_STRB_WIDTH = AXIL_DATA_WIDTH/8;

reg  [7:0]              axi_arlen_l;
reg  [7:0]              axi_awlen_l;
reg  [AXI_ID_WIDTH-1:0] axi_arid_l;
reg  [AXI_ID_WIDTH-1:0] axi_awid_l;
//------------------------------------------------------------------------------
// AXI read
always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_arlen_l <= 8'b0;
  else if(axi_arvalid & axi_arready)
    axi_arlen_l <= axi_arlen;
  else if(axi_rvalid & axi_rready & (axi_arlen_l!=8'b0))
    axi_arlen_l <= axi_arlen_l - 1'b1;
  else
    axi_arlen_l <= axi_arlen_l;
end 

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_arid_l <= {AXI_ID_WIDTH{1'b0}};
  else if(axi_arvalid & axi_arready)
    axi_arid_l <= axi_arid;
  else
    axi_arid_l <= axi_arid_l;
end 

assign axi_arready = axi_arvalid & (axi_arlen_l==8'b0);

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_rvalid <= 1'b0;
  else if(axi_arvalid & axi_arready)
    axi_rvalid <= 1'b1;
  else if(axi_arlen_l==8'b0)
    axi_rvalid <= 1'b0;
  else
    axi_rvalid <= axi_rvalid;
end

assign axi_rdata = {AXI_DATA_WIDTH{1'b0}};
assign axi_rresp = 2'b0;
assign axi_ruser = {AXI_RUSER_WIDTH{1'b0}};
assign axi_rid   = axi_rvalid ? axi_arid_l : {AXI_ID_WIDTH{1'b0}};
assign axi_rlast = axi_rvalid & (axi_arlen_l==8'b0);

// AXI write
always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_awlen_l <= 8'b0;
  else if(axi_awvalid & axi_awready)
    axi_awlen_l <= axi_awlen;
  else if(axi_wvalid & axi_wready & (axi_awlen_l!=8'b0))
    axi_awlen_l <= axi_awlen_l - 1'b1;
  else
    axi_awlen_l <= axi_awlen_l;
end 

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_awid_l <= {AXI_ID_WIDTH{1'b0}};
  else if(axi_awvalid & axi_awready)
    axi_awid_l <= axi_awid;
  else
    axi_awid_l <= axi_awid_l;
end 

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_awready <= 1'b0;
  else if(axi_awvalid & (axi_awlen_l==8'b0))
    axi_awready <= 1'b1;
  else if(axi_awvalid & axi_awready)
    axi_awready <= 1'b0;
  else
    axi_awready <= axi_awready;
end

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_wready <= 1'b0;
  else if(axi_awvalid & axi_awready)
    axi_wready <= 1'b1;
  else if(axi_wlast)
    axi_wready <= 1'b0;
  else
    axi_wready <= axi_wready;
end

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    axi_bvalid <= 1'b0;
  else if(axi_wvalid & axi_wready & axi_wlast)
    axi_bvalid <= 1'b1;
  else if(axi_bvalid & axi_bready)
    axi_bvalid <= 1'b0;
  else
    axi_bvalid <= axi_bvalid;
end

assign axi_bresp = 2'b0;
assign axi_buser = {AXI_BUSER_WIDTH{1'b0}};
assign axi_bid   = axi_bvalid ? axi_awid_l : {AXI_ID_WIDTH{1'b0}};

// AXI lite slave
always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    s_lite_arready <= 1'b1;
  else if(s_lite_arvalid)
    s_lite_arready <= 1'b0;
  else if(s_lite_rvalid & s_lite_rready)
    s_lite_arready <= 1'b1;
  else
    s_lite_arready <= s_lite_arready;
end

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    s_lite_rvalid <= 1'b0;
  else if(s_lite_arvalid & s_lite_arready)
    s_lite_rvalid <= 1'b1;
  else if(s_lite_rready)
    s_lite_rvalid <= 1'b0;
  else
    s_lite_rvalid <= s_lite_rvalid;
end

assign s_lite_rdata = {AXIL_DATA_WIDTH{1'b0}};
assign s_lite_rresp = 2'b0;

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    s_lite_awready <= 1'b0;
  else if(s_lite_awvalid)
    s_lite_awready <= 1'b1;
  else if(s_lite_wvalid & s_lite_wready)
    s_lite_awready <= 1'b0;
  else
    s_lite_awready <= s_lite_awready;
end

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    s_lite_wready <= 1'b0;
  else if(s_lite_awvalid & s_lite_awready)
    s_lite_wready <= 1'b1;
  else if(s_lite_wvalid)
    s_lite_wready <= 1'b0;
  else
    s_lite_wready <= s_lite_wready;
end

always@(posedge clk or negedge rst_n) begin
  if(~rst_n)
    s_lite_bvalid <= 1'b0;
  else if(s_lite_wvalid & s_lite_wready)
    s_lite_bvalid <= 1'b1;
  else if(s_lite_bready)
    s_lite_bvalid <= 1'b0;
  else
    s_lite_bvalid <= s_lite_bvalid;
end

assign s_lite_bresp = 2'b0;

// AXI lite master
assign m_lite_arvalid = 1'b0;
assign m_lite_araddr  = {AXIL_ADDR_WIDTH{1'b0}};
assign m_lite_rready  = 1'b0;
assign m_lite_awvalid = 1'b0;
assign m_lite_awaddr  = {AXIL_ADDR_WIDTH{1'b0}};
assign m_lite_wvalid  = 1'b0;
assign m_lite_wdata   = {AXIL_DATA_WIDTH{1'b0}};
assign m_lite_wstrb   = {AXIL_STRB_WIDTH{1'b0}};
assign m_lite_bready  = 1'b0;

endmodule
