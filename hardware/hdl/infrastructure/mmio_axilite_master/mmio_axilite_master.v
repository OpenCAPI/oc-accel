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


module mmio_axilite_master
            # (
                parameter IMP_VERSION = 64'h1000_0000_0000_0000,
                parameter BUILD_DATE = 64'h0000_2000_0101_0800,
                parameter OTHER_CAPABILITY = 56'h0,
                parameter CARD_TYPE = 8'h31
              )
              (
                     input                 clk_afu                          ,
                     input                 rst_n                            ,


                     //---- local information input --------------------------
                     output                debug_info_clear                  , 
                     input         [195:0] debug_bus_data_bridge            ,
`ifdef OPENCAPI30
                     input         [476:0] debug_bus_trans_protocol         ,
`endif
`ifdef CAPI20
`endif

                     //---- local control output -----------------------------
                     output                soft_reset_brdg_odma             ,
                     output                soft_reset_action                ,

                     //---- MMIO side interface --------------------
                     input                mmio_wr                    ,
                     input                mmio_rd                    ,
                     input                mmio_dw                    ,
                     input         [31:0] mmio_addr                  ,
                     input         [63:0] mmio_din                   ,
                     output reg    [63:0] mmio_dout                  ,
                     output reg           mmio_done                  ,
                     output reg           mmio_failed                ,


                     //---- master side AXI Lite bus ----
                       // AXI write address channel
                     input                 m_axi_awready                    ,   
                     output         [31:0] m_axi_awaddr                     ,
                     output         [02:0] m_axi_awprot                     , // not supported
                     output                m_axi_awvalid                    ,

                       // axi write data channel             
                     input                 m_axi_wready                     ,
                     output         [31:0] m_axi_wdata                      ,
                     output         [03:0] m_axi_wstrb                      , // not supported
                     output                m_axi_wvalid                     ,

                       // AXI response channel
                     input          [01:0] m_axi_bresp                      ,
                     input                 m_axi_bvalid                     ,
                     output                m_axi_bready                     ,

                       // AXI read address channel
                     input                 m_axi_arready                    ,
                     output                m_axi_arvalid                    ,
                     output         [31:0] m_axi_araddr                     ,
                     output         [02:0] m_axi_arprot                     , // not supported

                       // AXI read data channel
                     input          [31:0] m_axi_rdata                      ,
                     input          [01:0] m_axi_rresp                      ,
                     output                m_axi_rready                     ,
                     input                 m_axi_rvalid                     
                     );


 wire          lcl_wr     ;
 wire          lcl_rd     ;
 wire  [31:0]  lcl_addr   ;
 wire  [31:0]  lcl_din    ;
 wire          lcl_ack    ;
 wire          lcl_rsp    ;
 wire  [31:0]  lcl_dout   ;
 wire          lcl_dv     ;


//---- route TLX access to local SNAP registers or action register space ---- 
 mmio # (
                .IMP_VERSION (IMP_VERSION ),
                .BUILD_DATE (BUILD_DATE ),
                .OTHER_CAPABILITY (OTHER_CAPABILITY ),
                .CARD_TYPE (CARD_TYPE )
              )
        mmio_path_and_regs (
             .clk                        (clk_afu                    ),
             .rst_n                      (rst_n                      ),
             .debug_info_clear           (debug_info_clear            ),
             .debug_bus_trans_protocol   (debug_bus_trans_protocol   ),
             .debug_bus_data_bridge      (debug_bus_data_bridge      ),
             .soft_reset_brdg_odma       (soft_reset_brdg_odma       ),
             .soft_reset_action          (soft_reset_action          ),
             .mmio_wr                    (mmio_wr                    ),
             .mmio_rd                    (mmio_rd                    ),
             .mmio_dw                    (mmio_dw                    ),
             .mmio_addr                  (mmio_addr                  ),
             .mmio_din                   (mmio_din                   ),
             .mmio_dout                  (mmio_dout                  ),
             .mmio_done                  (mmio_done                  ),
             .mmio_failed                (mmio_failed                ),
             .lcl_wr                     (lcl_wr                     ),
             .lcl_rd                     (lcl_rd                     ),
             .lcl_addr                   (lcl_addr                   ),
             .lcl_din                    (lcl_din                    ),
             .lcl_ack                    (lcl_ack                    ),
             .lcl_rsp                    (lcl_rsp                    ),
             .lcl_dout                   (lcl_dout                   ),
             .lcl_dv                     (lcl_dv                     ) 
             );


//---- AXI lite interface to action as master ----
 axilite_shim axilite_shim (
                                   .clk           (clk_afu      ),
                                   .rst_n         (rst_n        ),
                                   .m_axi_awready (m_axi_awready),   
                                   .m_axi_awaddr  (m_axi_awaddr ),
                                   .m_axi_awprot  (m_axi_awprot ), // not supported
                                   .m_axi_awvalid (m_axi_awvalid),
                                   .m_axi_wready  (m_axi_wready ),
                                   .m_axi_wdata   (m_axi_wdata  ),
                                   .m_axi_wstrb   (m_axi_wstrb  ), // not supported
                                   .m_axi_wvalid  (m_axi_wvalid ),
                                   .m_axi_bresp   (m_axi_bresp  ),
                                   .m_axi_bvalid  (m_axi_bvalid ),
                                   .m_axi_bready  (m_axi_bready ),
                                   .m_axi_arready (m_axi_arready),
                                   .m_axi_arvalid (m_axi_arvalid),
                                   .m_axi_araddr  (m_axi_araddr ),
                                   .m_axi_arprot  (m_axi_arprot ), // not supported
                                   .m_axi_rdata   (m_axi_rdata  ),
                                   .m_axi_rresp   (m_axi_rresp  ),
                                   .m_axi_rready  (m_axi_rready ),
                                   .m_axi_rvalid  (m_axi_rvalid ),
                                   .lcl_wr        (lcl_wr       ), // write enable
                                   .lcl_rd        (lcl_rd       ), // read enable
                                   .lcl_addr      (lcl_addr     ), // write/read address
                                   .lcl_din       (lcl_din      ), // write data
                                   .lcl_ack       (lcl_ack      ), // write data acknowledgement
                                   .lcl_rsp       (lcl_rsp      ), // write/read response: 0: good; 1: bad
                                   .lcl_dout      (lcl_dout     ), // read data
                                   .lcl_dv        (lcl_dv       )  // read data valid
                                  );


endmodule
