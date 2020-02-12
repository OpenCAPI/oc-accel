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


module axilite_shim (
                        input             clk                   ,
                        input             resetn                 ,

                        //---- master side AXI Lite bus ----
                          // AXI write address channel
                        input             m_axi_awready         ,   
                        output reg [31:0] m_axi_awaddr          ,
                        output     [02:0] m_axi_awprot          , // not supported
                        output reg        m_axi_awvalid         ,
                          // axi write data channel             
                        input             m_axi_wready          ,
                        output reg [31:0] m_axi_wdata           ,
                        output     [03:0] m_axi_wstrb           , // not supported
                        output reg        m_axi_wvalid          ,
                          // AXI response channel
                        input      [01:0] m_axi_bresp           ,
                        input             m_axi_bvalid          ,
                        output reg        m_axi_bready          ,
                          // AXI read address channel
                        input             m_axi_arready         ,
                        output reg        m_axi_arvalid         ,
                        output reg [31:0] m_axi_araddr          ,
                        output     [02:0] m_axi_arprot          , // not supported
                          // AXI read data channel
                        input      [31:0] m_axi_rdata           ,
                        input      [01:0] m_axi_rresp           ,
                        output reg        m_axi_rready          ,
                        input             m_axi_rvalid          ,

                        //---- local bus ----
                        input             lcl_mmio_wr                , // write enable
                        input             lcl_mmio_rd                , // read enable
                        input      [31:0] lcl_mmio_addr              , // write/read address
                        input      [31:0] lcl_mmio_din               , // write data
                        output reg        lcl_mmio_ack               , // write data acknowledgement
                        output reg        lcl_mmio_rsp               , // write/read response: 0: good; 1: bad
                        output reg [31:0] lcl_mmio_dout              , // read data
                        output reg        lcl_mmio_dv                  // read data valid
                        );



 assign m_axi_awprot = 3'b000;
 assign m_axi_wstrb = 4'b1111;
 assign m_axi_arprot = 3'b000;


//=========================================================
// WRITE CHANNEL
// --------------
//
//   lcl_mmio_wr        __/-\______/-\___________
//   lcl_mmio_din/addr  --<=>------<=>-----------
//   lcl_mmio_ack       _______/-\__________/-\__
//=========================================================

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     m_axi_awvalid <= 1'b0;
   else if(lcl_mmio_wr)
     m_axi_awvalid <= 1'b1;
   else if(m_axi_awready)
     m_axi_awvalid <= 1'b0;

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     m_axi_wvalid <= 1'b0;
   else if(lcl_mmio_wr)
     m_axi_wvalid <= 1'b1;
   else if(m_axi_wready)
     m_axi_wvalid <= 1'b0;

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     begin
       m_axi_wdata  <= 32'd0;
       m_axi_awaddr <= 32'd0;
     end
   else if(lcl_mmio_wr)
     begin
       m_axi_wdata  <= lcl_mmio_din;
       m_axi_awaddr <= lcl_mmio_addr;
     end

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     m_axi_bready <= 1'b0;
   else 
     m_axi_bready <= ~(m_axi_awvalid || m_axi_wvalid);

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     lcl_mmio_ack <= 1'b0;
   else 
     lcl_mmio_ack <= (m_axi_bready && m_axi_bvalid);
    

//=========================================================
// READ CHANNEL
// --------------
//
//   lcl_mmio_rd        __/-\______/-\___________
//   lcl_mmio_addr      --<=>------<=>-----------
//   lcl_mmio_dv        _______/-\__________/-\__
//   lcl_mmio_addr      -------<=>----------<=>--
//=========================================================

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     m_axi_arvalid <= 1'b0;
   else if(lcl_mmio_rd)
     m_axi_arvalid <= 1'b1;
   else if(m_axi_arready)
     m_axi_arvalid <= 1'b0;

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     m_axi_rready <= 1'b0;
   else if(lcl_mmio_rd)
     m_axi_rready <= 1'b1;
   else if(m_axi_rvalid)
     m_axi_rready <= 1'b0;

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     begin
       m_axi_araddr <= 32'd0;
     end
   else if(lcl_mmio_rd)
     begin
       m_axi_araddr <= lcl_mmio_addr;
     end

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     lcl_mmio_dout <= 32'b0;
   else if(m_axi_rready && m_axi_rvalid)
     lcl_mmio_dout <= m_axi_rdata;

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     lcl_mmio_dv <= 1'b0;
   else 
     lcl_mmio_dv <= (m_axi_rready && m_axi_rvalid);
    

//=========================================================
// common response for write and read channels
//=========================================================

 always@(posedge clk or negedge resetn)
   if(~resetn) 
     lcl_mmio_rsp <= 1'b0;
   else if(m_axi_bready && m_axi_bvalid)
     lcl_mmio_rsp <= (m_axi_bresp == 2'b00);
   else
     lcl_mmio_rsp <= (m_axi_rresp == 2'b00);



endmodule
