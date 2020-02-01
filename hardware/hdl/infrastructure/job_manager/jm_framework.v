`timescale 1ns/1ps
//Yanheng Lu
//IBM CSL OpenPower
//lyhlu@cn.ibm.com
`define RETURN_CODE_ENABLE

module jm_framework #(
    parameter ID_WIDTH = 1,
    parameter ARUSER_WIDTH = 9,
    parameter AWUSER_WIDTH = 9,
    parameter RETURN_WIDTH = 41,
    parameter PINFO_WIDTH = 88,
    parameter PASID_WIDTH = 9,
    parameter KERNEL_NUM = 2,
    parameter LITE_DWIDTH = 32,
    parameter LITE_AWIDTH = 32,
    parameter HOST_DWIDTH = 1024,
    parameter HOST_AWIDTH = 64
)(
        input                           clk             ,
        input                           rst_n           ,

        output      [KERNEL_NUM-1:0]    engine_start    ,
        output      [HOST_DWIDTH-1:0]   jd_payload      ,
        input       [KERNEL_NUM-1:0]    engine_done     ,
    `ifdef RETURN_CODE_ENABLE
        input       [RETURN_WIDTH-65:0] return_code     ,
    `endif
        //---- AXI Lite bus----
          // AXI write address channel
        output                          s_axi_awready   ,
        input       [LITE_AWIDTH-1:0]   s_axi_awaddr    ,
        input       [02:0]              s_axi_awprot    ,
        input                           s_axi_awvalid   ,
          // AXI write data channel
        output                          s_axi_wready    ,
        input       [LITE_DWIDTH-1:0]   s_axi_wdata     ,
        input       [LITE_DWIDTH/8-1:0] s_axi_wstrb     ,
        input                           s_axi_wvalid    ,
          // AXI response channel
        output      [01:0]              s_axi_bresp     ,
        output                          s_axi_bvalid    ,
        input                           s_axi_bready    ,
          // AXI read address channel
        output                          s_axi_arready   ,
        input                           s_axi_arvalid   ,
        input       [LITE_AWIDTH-1:0]   s_axi_araddr    ,
        input       [02:0]              s_axi_arprot    ,
          // AXI read data channel
        output      [LITE_DWIDTH - 1:0] s_axi_rdata     ,
        output      [01:0]              s_axi_rresp     ,
        input                           s_axi_rready    ,
        output                          s_axi_rvalid    ,
        //---- AXI bus ----
        // AXI write address channel
        output      [ID_WIDTH-1:0]      job_m_axi_awid     ,
        output      [HOST_AWIDTH-1:0]   job_m_axi_awaddr   ,
        output      [0007:0]            job_m_axi_awlen    ,
        output      [0002:0]            job_m_axi_awsize   ,
        output      [0001:0]            job_m_axi_awburst  ,
        output      [0003:0]            job_m_axi_awcache  ,
        output                          job_m_axi_awlock   ,
        output      [0002:0]            job_m_axi_awprot   ,
        output      [0003:0]            job_m_axi_awqos    ,
        output      [0003:0]            job_m_axi_awregion ,
        output      [AWUSER_WIDTH-1:0]  job_m_axi_awuser   ,
        output                          job_m_axi_awvalid  ,
        input                           job_m_axi_awready  ,
        // AXI write data channel
        output      [ID_WIDTH-1:0]      job_m_axi_wid      ,
        output      [HOST_DWIDTH-1:0]   job_m_axi_wdata    ,
        output      [HOST_DWIDTH/8-1:0] job_m_axi_wstrb    ,
        output                          job_m_axi_wlast    ,
        output                          job_m_axi_wvalid   ,
        input                           job_m_axi_wready   ,
        // AXI write response channel
        output                          job_m_axi_bready   ,
        input       [ID_WIDTH-1:0]      job_m_axi_bid      ,
        input       [0001:0]            job_m_axi_bresp    ,
        input                           job_m_axi_bvalid   ,
           // AXI read address channel
        output      [ID_WIDTH-1:0]      job_m_axi_arid     ,
        output      [HOST_AWIDTH-1:0]   job_m_axi_araddr   ,
        output      [007:0]             job_m_axi_arlen    ,
        output      [002:0]             job_m_axi_arsize   ,
        output      [001:0]             job_m_axi_arburst  ,
        output      [ARUSER_WIDTH-1:0]  job_m_axi_aruser   ,
        output      [003:0]             job_m_axi_arcache  ,
        output      [001:0]             job_m_axi_arlock   ,
        output      [002:0]             job_m_axi_arprot   ,
        output      [003:0]             job_m_axi_arqos    ,
        output      [003:0]             job_m_axi_arregion ,
        output                          job_m_axi_arvalid  ,
        input                           job_m_axi_arready  ,
          // axi_snap read data channel
        output                          job_m_axi_rready   ,
        input       [ARUSER_WIDTH-1:0]  job_m_axi_ruser    ,// no use
        input       [ID_WIDTH-1:0]      job_m_axi_rid      ,
        input       [HOST_DWIDTH-1:0]   job_m_axi_rdata    ,
        input       [001:0]             job_m_axi_rresp    ,
        input                           job_m_axi_rlast    ,
        input                           job_m_axi_rvalid
);

    wire    [PINFO_WIDTH-1:0]       process_info_w  ;
    wire                            process_start_w ;
    wire                            process_ready_w ;
    wire                            dsc0_pull_w     ;
    wire                            dsc0_ready_w    ;
    wire    [HOST_DWIDTH-1:0]       dsc0_data_w     ;
    wire                            complete_push_w ;
    wire    [RETURN_WIDTH-1:0]      return_data_w   ;
    wire                            complete_ready_w;
    wire    [31:0]                  cmpl_ram_data_w ;
    wire    [PASID_WIDTH-1:0]       cmpl_ram_addr_w ;
    wire                            cmpl_ram_hi_w   ;
    wire                            cmpl_ram_lo_w   ;

mp_control #(
        .PINFO_WIDTH    ( PINFO_WIDTH   ),
        .PASID_WIDTH    ( PASID_WIDTH   ),
        .DATA_WIDTH     ( LITE_DWIDTH   ),
        .ADDR_WIDTH     ( LITE_AWIDTH   )
 ) mp_control1 (
        .clk                        ( clk                   ),
        .rst_n                      ( rst_n                 ),
        .s_axi_awready              ( s_axi_awready         ),
        .s_axi_awaddr               ( s_axi_awaddr          ),//32b
        .s_axi_awprot               ( s_axi_awprot          ),//3b
        .s_axi_awvalid              ( s_axi_awvalid         ),
        .s_axi_wready               ( s_axi_wready          ),
        .s_axi_wdata                ( s_axi_wdata           ),//32b
        .s_axi_wstrb                ( s_axi_wstrb           ),//4b
        .s_axi_wvalid               ( s_axi_wvalid          ),
        .s_axi_bresp                ( s_axi_bresp           ),//2b
        .s_axi_bvalid               ( s_axi_bvalid          ),
        .s_axi_bready               ( s_axi_bready          ),
        .s_axi_arready              ( s_axi_arready         ),
        .s_axi_arvalid              ( s_axi_arvalid         ),
        .s_axi_araddr               ( s_axi_araddr          ),//32b
        .s_axi_arprot               ( s_axi_arprot          ),//3b
        .s_axi_rdata                ( s_axi_rdata           ),//32b
        .s_axi_rresp                ( s_axi_rresp           ),//2b
        .s_axi_rready               ( s_axi_rready          ),
        .s_axi_rvalid               ( s_axi_rvalid          ),
        .cmpl_ram_addr_o            ( cmpl_ram_addr_w       ),
        .cmpl_ram_hi_o              ( cmpl_ram_hi_w         ),
        .cmpl_ram_lo_o              ( cmpl_ram_lo_w         ),
        .cmpl_ram_data_o            ( cmpl_ram_data_w       ),
        .process_info_o             ( process_info_w        ),
        .process_start_o            ( process_start_w       ),
        .process_ready_i            ( process_ready_w       ),
        .i_action_type              ( i_action_type         ),
        .i_action_version           ( i_action_version      )
        );

job_manager #(
        .ID_WIDTH       ( ID_WIDTH      ),
        .ARUSER_WIDTH   ( ARUSER_WIDTH  ),
        .PINFO_WIDTH    ( PINFO_WIDTH   ),
        .PASID_WIDTH    ( PASID_WIDTH   ),
        .DATA_WIDTH     ( HOST_DWIDTH   ),
        .ADDR_WIDTH     ( HOST_AWIDTH   )
    )job_manager0 (
        .clk                        ( clk                   ),
        .rst_n                      ( rst_n                 ),
        .process_info_i             ( process_info_w        ),
        .process_start_i            ( process_start_w       ),
        .process_ready_o            ( process_ready_w       ),
        .dsc0_pull_i                ( dsc0_pull_w           ),
        .dsc0_ready_o               ( dsc0_ready_w          ),
        .dsc0_data_o                ( dsc0_data_w           ),

        //---- AXI bus interfaced with SNAP core ----
        // AXI read address channel
        .m_axi_arid                 ( job_m_axi_arid        ),
        .m_axi_araddr               ( job_m_axi_araddr      ),
        .m_axi_arlen                ( job_m_axi_arlen       ),
        .m_axi_arsize               ( job_m_axi_arsize      ),
        .m_axi_arburst              ( job_m_axi_arburst     ),
        .m_axi_aruser               ( job_m_axi_aruser      ),
        .m_axi_arcache              ( job_m_axi_arcache     ),
        .m_axi_arlock               ( job_m_axi_arlock      ),
        .m_axi_arprot               ( job_m_axi_arprot      ),
        .m_axi_arqos                ( job_m_axi_arqos       ),
        .m_axi_arregion             ( job_m_axi_arregion    ),
        .m_axi_arvalid              ( job_m_axi_arvalid     ),
        .m_axi_arready              ( job_m_axi_arready     ),
        // AXI read data channel
        .m_axi_rready               ( job_m_axi_rready      ),
        .m_axi_rid                  ( job_m_axi_rid         ),
        .m_axi_rdata                ( job_m_axi_rdata       ),
        .m_axi_rresp                ( job_m_axi_rresp       ),
        .m_axi_rlast                ( job_m_axi_rlast       ),
        .m_axi_rvalid               ( job_m_axi_rvalid      )
        );

job_scheduler #(
        .HOST_DWIDTH    ( HOST_DWIDTH   ),
        .RETURN_WIDTH   ( RETURN_WIDTH  ),
        .PASID_WIDTH    ( PASID_WIDTH   ),
        .KERNEL_NUM     ( KERNEL_NUM    )
    )job_scheduler0(
        .clk                        ( clk                   ),
        .rst_n                      ( rst_n                 ),
        .dsc0_pull_o                ( dsc0_pull_w           ),
        .dsc0_ready_i               ( dsc0_ready_w          ),
        .dsc0_data_i                ( dsc0_data_w           ),
        .complete_ready_i           ( complete_ready_w      ),
        .complete_push_o            ( complete_push_w       ),
        .return_data_o              ( return_data_w         ),
        .engine_start               ( engine_start          ),
        .jd_payload                 ( jd_payload            ),
    `ifdef RETURN_CODE_ENCABLE
        .return_code                ( return_code           ),
    `endif
        .engine_done                ( engine_done           )
        );

job_completion #(
        .ID_WIDTH       ( ID_WIDTH      ),
        .AWUSER_WIDTH   ( AWUSER_WIDTH  ),
        .RETURN_WIDTH   ( RETURN_WIDTH  ),
        .PASID_WIDTH    ( PASID_WIDTH   ),
        .DATA_WIDTH     ( HOST_DWIDTH   ),
        .ADDR_WIDTH     ( HOST_AWIDTH   )
    )job_completion0(
        .clk                        ( clk                   ),
        .rst_n                      ( rst_n                 ),
        .cmpl_ram_addr_i            ( cmpl_ram_addr_w       ),
        .cmpl_ram_hi_i              ( cmpl_ram_hi_w         ),
        .cmpl_ram_lo_i              ( cmpl_ram_lo_w         ),
        .cmpl_ram_data_i            ( cmpl_ram_data_w       ),
        .complete_ready_o           ( complete_ready_w      ),
        .complete_push_i            ( complete_push_w       ),
        .return_data_i              ( return_data_w         ),
        .m_axi_awid                 ( job_m_axi_awid        ),
        .m_axi_awaddr               ( job_m_axi_awaddr      ),
        .m_axi_awlen                ( job_m_axi_awlen       ),
        .m_axi_awsize               ( job_m_axi_awsize      ),
        .m_axi_awburst              ( job_m_axi_awburst     ),
        .m_axi_awlock               ( job_m_axi_awlock      ),
        .m_axi_awcache              ( job_m_axi_awcache     ),
        .m_axi_awprot               ( job_m_axi_awprot      ),
        .m_axi_awqos                ( job_m_axi_awqos       ),
        .m_axi_awvalid              ( job_m_axi_awvalid     ),
        .m_axi_awready              ( job_m_axi_awready     ),
        .m_axi_awuser               ( job_m_axi_awuser      ),
        .m_axi_wid                  ( job_m_axi_wid         ),
        .m_axi_wdata                ( job_m_axi_wdata       ),
        .m_axi_wstrb                ( job_m_axi_wstrb       ),
        .m_axi_wlast                ( job_m_axi_wlast       ),
        .m_axi_wvalid               ( job_m_axi_wvalid      ),
        .m_axi_wready               ( job_m_axi_wready      ),
        .m_axi_bid                  ( job_m_axi_bid         ),
        .m_axi_bresp                ( job_m_axi_bresp       ),
        .m_axi_bvalid               ( job_m_axi_bvalid      ),
        .m_axi_bready               ( job_m_axi_bready      )
        );

    assign job_m_axi_awregion = 'd0;

endmodule
