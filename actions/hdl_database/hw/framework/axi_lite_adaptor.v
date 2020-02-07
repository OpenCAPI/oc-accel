`timescale 1ns/1ps

module axi_lite_adaptor #(
       parameter DATA_WIDTH     = 32,
       parameter ADDR_WIDTH     = 32
       )(
        input                               clk                   ,
        input                               rst_n                 ,
        input                               engine_start          ,
        output  reg                         engine_done           ,
        input       [1023:0]                payload               ,
        input                               engine_interrupt      ,

        //---- AXI Lite bus----
        input                               s_axi_awready         ,
        output  reg [ADDR_WIDTH - 1:0]      s_axi_awaddr          ,
        output      [02:0]                  s_axi_awprot          ,
        output  reg                         s_axi_awvalid         ,
            // axi write data channel
        input                               s_axi_wready          ,
        output      [DATA_WIDTH - 1:0]      s_axi_wdata           ,
        output      [(DATA_WIDTH/8) - 1:0]  s_axi_wstrb           ,
        output                              s_axi_wvalid          ,
            // AXI response channel
        input       [01:0]                  s_axi_bresp           ,
        input                               s_axi_bvalid          ,
        output                              s_axi_bready          ,
            // AXI read address channel
        input                               s_axi_arready         ,
        output                              s_axi_arvalid         ,
        output      [ADDR_WIDTH - 1:0]      s_axi_araddr          ,
        output      [02:0]                  s_axi_arprot          ,
            // AXI read data channel
        input       [DATA_WIDTH - 1:0]      s_axi_rdata           ,
        input       [01:0]                  s_axi_rresp           ,
        output                              s_axi_rready          ,
        input                               s_axi_rvalid
);

parameter  REGISTER_NUMBER               = 'd14;

reg [1023:0] shift_vector;
reg [4:0] write_cnt;

assign s_axi_bready = 1'b0;
assign s_axi_rready = 1'b0;
assign s_axi_arvalid = 1'b0;
assign s_axi_araddr = 'd0;
assign s_axi_arprot = 3'b0;
assign s_axi_awprot = 3'b0;
assign s_axi_wdata = shift_vector[31:0];
assign s_axi_wstrb = 4'b1111;
assign s_axi_wvalid = (write_cnt < REGISTER_NUMBER + 1);

always @(posedge clk)
    if(engine_start)
        shift_vector <= payload;
    else if(s_axi_wvalid & s_axi_wready)
        shift_vector <= {32'b0,shift_vector[1023:32]};

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        write_cnt <= 'd31;
    else if(engine_start)
        write_cnt <= 'd0;
    else if(s_axi_wvalid & s_axi_wready)
        write_cnt <= write_cnt + 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        s_axi_awvalid <= 1'b0;
    else if(s_axi_awvalid & s_axi_awready)
        s_axi_awvalid <= 1'b0;
    else if((s_axi_awaddr != 'h80) & s_axi_awready)
        s_axi_awvalid <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        s_axi_awaddr <= 'h80;
    else if(engine_start)
        s_axi_awaddr <= 'd0;
    else if(s_axi_awvalid & s_axi_awready & (s_axi_awaddr == REGISTER_NUMBER * 4))
        s_axi_awaddr <= 32'h80;
    else if(s_axi_awvalid & s_axi_awready)
        s_axi_awaddr <= s_axi_awaddr + 4;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        engine_done <= 1'b0;
    else if(engine_start)
        engine_done <= 1'b0;
    else if(engine_interrupt)
        engine_done <= 1'b1;

endmodule
