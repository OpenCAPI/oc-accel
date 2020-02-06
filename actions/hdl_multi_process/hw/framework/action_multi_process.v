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

//Don't touch the interface to connect to action-_wrapper!
module action_multi_process # (
    parameter ENGINE_NUM = 8,
    parameter ACTION_ID_WIDTH = 5,

    // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
    parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,

    // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    parameter C_M_AXI_HOST_MEM_ID_WIDTH      = 4,
    parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
    parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = 512,
    parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1,
    parameter INT_BITS                       = 3,
    parameter CONTEXT_BITS                   = 8
)
(
    input              clk                      ,
    input              rst_n                    , 


    //---- AXI bus interfaced with OCACCEL core ----               
    // AXI write address channel      
    output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_ocaccel_awid          ,  
    output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_ocaccel_awaddr        ,  
    output    [0007:0] m_axi_ocaccel_awlen         ,  
    output    [0002:0] m_axi_ocaccel_awsize        ,  
    output    [0001:0] m_axi_ocaccel_awburst       ,  
    output    [0003:0] m_axi_ocaccel_awcache       ,  
    output    [0001:0] m_axi_ocaccel_awlock        ,  
    output    [0002:0] m_axi_ocaccel_awprot        ,  
    output    [0003:0] m_axi_ocaccel_awqos         ,  
    output    [0003:0] m_axi_ocaccel_awregion      ,  
    output    [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0] m_axi_ocaccel_awuser        ,  
    output             m_axi_ocaccel_awvalid       ,  
    input              m_axi_ocaccel_awready       ,
    // AXI write data channel         
    output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_ocaccel_wid           , 
    output    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_ocaccel_wdata         ,  
    output    [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) -1:0] m_axi_ocaccel_wstrb         ,  
    output             m_axi_ocaccel_wlast         ,  
    output             m_axi_ocaccel_wvalid        ,  
    input              m_axi_ocaccel_wready        ,
    // AXI write response channel     
    output             m_axi_ocaccel_bready        ,  
    input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_ocaccel_bid           ,
    input     [0001:0] m_axi_ocaccel_bresp         ,
    input              m_axi_ocaccel_bvalid        ,
    // AXI read address channel       
    output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_ocaccel_arid          ,  
    output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_ocaccel_araddr        ,  
    output    [0007:0] m_axi_ocaccel_arlen         ,  
    output    [0002:0] m_axi_ocaccel_arsize        ,  
    output    [0001:0] m_axi_ocaccel_arburst       ,  
    output    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_ocaccel_aruser        , 
    output    [0002:0] m_axi_ocaccel_arcache       , 
    output    [0001:0] m_axi_ocaccel_arlock        ,  
    output    [0002:0] m_axi_ocaccel_arprot        , 
    output    [0003:0] m_axi_ocaccel_arqos         , 
    output    [0008:0] m_axi_ocaccel_arregion      , 
    output             m_axi_ocaccel_arvalid       , 
    input              m_axi_ocaccel_arready       ,
    // AXI  ead data channel          
    output             m_axi_ocaccel_rready        , 
    input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_ocaccel_rid           ,
    input     [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_ocaccel_rdata         ,
    input     [0001:0] m_axi_ocaccel_rresp         ,
    input              m_axi_ocaccel_rlast         ,
    input              m_axi_ocaccel_rvalid        ,

    //---- AXI Lite bus interfaced with OCACCEL core ----               
    // AXI write address channel
    output             s_axi_ocaccel_awready       ,   
    input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_ocaccel_awaddr        ,
    input     [0002:0] s_axi_ocaccel_awprot        ,
    input              s_axi_ocaccel_awvalid       ,
    // axi write data channel             
    output             s_axi_ocaccel_wready        ,
    input     [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_ocaccel_wdata         ,
    input     [(C_S_AXI_CTRL_REG_DATA_WIDTH/8) -1:0] s_axi_ocaccel_wstrb         ,
    input              s_axi_ocaccel_wvalid        ,
    // AXI response channel
    output    [0001:0] s_axi_ocaccel_bresp         ,
    output             s_axi_ocaccel_bvalid        ,
    input              s_axi_ocaccel_bready        ,
    // AXI read address channel
    output             s_axi_ocaccel_arready       ,
    input              s_axi_ocaccel_arvalid       ,
    input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_ocaccel_araddr        ,
    input     [0002:0] s_axi_ocaccel_arprot        ,
    // AXI read data channel
    output    [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_ocaccel_rdata         ,
    output    [0001:0] s_axi_ocaccel_rresp         ,
    input              s_axi_ocaccel_rready        ,
    output             s_axi_ocaccel_rvalid        ,

    // Other signals
    input      [31:0]  i_action_type            ,
    input      [31:0]  i_action_version         ,
    output             o_interrupt              ,
    input              i_interrupt_ack
    );

    reg [0000:0] app_ready;

    always @(posedge clk) begin
        if (rst_n == 0) begin
            app_ready <= 0;
        end else begin
            app_ready <= 1;
        end
    end

    multi_process_framework #(
        // This is a 8 kernel framework
        .ENGINE_NUM                    (ENGINE_NUM),

        // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
        .C_S_AXI_CTRL_REG_DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
        .C_S_AXI_CTRL_REG_ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   ),

        // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
        .C_M_AXI_HOST_MEM_ID_WIDTH     (ACTION_ID_WIDTH     ),
        .C_M_AXI_HOST_MEM_ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
        .C_M_AXI_HOST_MEM_DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
        .C_M_AXI_HOST_MEM_AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
        .C_M_AXI_HOST_MEM_ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
        .C_M_AXI_HOST_MEM_WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
        .C_M_AXI_HOST_MEM_RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
        .C_M_AXI_HOST_MEM_BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
    ) multi_process_framework_0 (

        .clk                      (clk                             ) ,
        .rst_n                    (rst_n                           ) ,
        .m_axi_ocaccel_awid          (m_axi_ocaccel_awid                 ) ,
        .m_axi_ocaccel_awaddr        (m_axi_ocaccel_awaddr               ) ,
        .m_axi_ocaccel_awlen         (m_axi_ocaccel_awlen                ) ,
        .m_axi_ocaccel_awsize        (m_axi_ocaccel_awsize               ) ,
        .m_axi_ocaccel_awburst       (m_axi_ocaccel_awburst              ) ,
        .m_axi_ocaccel_awcache       (m_axi_ocaccel_awcache              ) ,
        .m_axi_ocaccel_awlock        (                                ) ,
        .m_axi_ocaccel_awprot        (m_axi_ocaccel_awprot               ) ,
        .m_axi_ocaccel_awqos         (m_axi_ocaccel_awqos                ) ,
        .m_axi_ocaccel_awregion      (m_axi_ocaccel_awregion             ) ,
        .m_axi_ocaccel_awuser        (m_axi_ocaccel_awuser) ,
        .m_axi_ocaccel_awvalid       (m_axi_ocaccel_awvalid              ) ,
        .m_axi_ocaccel_awready       (m_axi_ocaccel_awready              ) ,
        .m_axi_ocaccel_wid           (m_axi_ocaccel_wid                  ) ,
        .m_axi_ocaccel_wdata         (m_axi_ocaccel_wdata                ) ,
        .m_axi_ocaccel_wstrb         (m_axi_ocaccel_wstrb                ) ,
        .m_axi_ocaccel_wlast         (m_axi_ocaccel_wlast                ) ,
        .m_axi_ocaccel_wvalid        (m_axi_ocaccel_wvalid               ) ,
        .m_axi_ocaccel_wready        (m_axi_ocaccel_wready               ) ,
        .m_axi_ocaccel_bready        (m_axi_ocaccel_bready               ) ,
        .m_axi_ocaccel_bid           (m_axi_ocaccel_bid                  ) ,
        .m_axi_ocaccel_bresp         (m_axi_ocaccel_bresp                ) ,
        .m_axi_ocaccel_bvalid        (m_axi_ocaccel_bvalid               ) ,
        .m_axi_ocaccel_arid          (m_axi_ocaccel_arid                 ) ,
        .m_axi_ocaccel_araddr        (m_axi_ocaccel_araddr               ) ,
        .m_axi_ocaccel_arlen         (m_axi_ocaccel_arlen                ) ,
        .m_axi_ocaccel_arsize        (m_axi_ocaccel_arsize               ) ,
        .m_axi_ocaccel_arburst       (m_axi_ocaccel_arburst              ) ,
        .m_axi_ocaccel_aruser        (m_axi_ocaccel_aruser) ,
        .m_axi_ocaccel_arcache       (m_axi_ocaccel_arcache              ) ,
        .m_axi_ocaccel_arlock        (                                ) ,
        .m_axi_ocaccel_arprot        (m_axi_ocaccel_arprot               ) ,
        .m_axi_ocaccel_arqos         (m_axi_ocaccel_arqos                ) ,
        .m_axi_ocaccel_arregion      (m_axi_ocaccel_arregion             ) ,
        .m_axi_ocaccel_arvalid       (m_axi_ocaccel_arvalid              ) ,
        .m_axi_ocaccel_arready       (m_axi_ocaccel_arready              ) ,
        .m_axi_ocaccel_rready        (m_axi_ocaccel_rready               ) ,
        .m_axi_ocaccel_rid           (m_axi_ocaccel_rid ) ,
        .m_axi_ocaccel_rdata         (m_axi_ocaccel_rdata                ) ,
        .m_axi_ocaccel_rresp         (m_axi_ocaccel_rresp                ) ,
        .m_axi_ocaccel_rlast         (m_axi_ocaccel_rlast                ) ,
        .m_axi_ocaccel_rvalid        (m_axi_ocaccel_rvalid               ) ,
        .s_axi_ocaccel_awready       (s_axi_ocaccel_awready              ) ,
        .s_axi_ocaccel_awaddr        (s_axi_ocaccel_awaddr               ) ,
        .s_axi_ocaccel_awprot        (s_axi_ocaccel_awprot               ) ,
        .s_axi_ocaccel_awvalid       (s_axi_ocaccel_awvalid              ) ,
        .s_axi_ocaccel_wready        (s_axi_ocaccel_wready               ) ,
        .s_axi_ocaccel_wdata         (s_axi_ocaccel_wdata                ) ,
        .s_axi_ocaccel_wstrb         (s_axi_ocaccel_wstrb                ) ,
        .s_axi_ocaccel_wvalid        (s_axi_ocaccel_wvalid               ) ,
        .s_axi_ocaccel_bresp         (s_axi_ocaccel_bresp                ) ,
        .s_axi_ocaccel_bvalid        (s_axi_ocaccel_bvalid               ) ,
        .s_axi_ocaccel_bready        (s_axi_ocaccel_bready               ) ,
        .s_axi_ocaccel_arready       (s_axi_ocaccel_arready              ) ,
        .s_axi_ocaccel_arvalid       (s_axi_ocaccel_arvalid              ) ,
        .s_axi_ocaccel_araddr        (s_axi_ocaccel_araddr               ) ,
        .s_axi_ocaccel_arprot        (s_axi_ocaccel_arprot               ) ,
        .s_axi_ocaccel_rdata         (s_axi_ocaccel_rdata                ) ,
        .s_axi_ocaccel_rresp         (s_axi_ocaccel_rresp                ) ,
        .s_axi_ocaccel_rready        (s_axi_ocaccel_rready               ) ,
        .s_axi_ocaccel_rvalid        (s_axi_ocaccel_rvalid               ) ,
        .i_app_ready              (app_ready                       ) ,
        .i_action_type            (i_action_type                   ) ,
        .i_action_version         (i_action_version                ) ,
        .o_interrupt              (o_interrupt                     ) ,
        .i_interrupt_ack          (i_interrupt_ack                 )
                                                                   ) ;

endmodule
