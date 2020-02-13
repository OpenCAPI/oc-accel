`timescale 1ns/1ps

module axi_lite_adaptor #(
        parameter   LITE_DWIDTH     = 32,
        parameter   LITE_AWIDTH     = 32,
		parameter   DSC_WIDTH       = 1024,
        parameter   READREG_NUMBER  = 1,
        parameter   READ_BASE_ADDR  = 'h100,
        parameter   WRITEREG_NUMBER = 14
       )(
        input                               clk                 ,
        input                               rst_n               ,
        input                               engine_start        ,
        output                              engine_ready        ,
        input       [DSC_WIDTH-1:0]         engine_data         ,
        output  reg                         complete_ready      ,
        input                               complete_accept     ,
        output      [READREG_NUMBER*32-1:0] complete_data       ,
        input                               engine_interrupt    ,

        //---- AXI Lite bus----
        input                               s_axi_awready       ,
        output  reg [LITE_AWIDTH - 1:0]     s_axi_awaddr        ,
        output      [02:0]                  s_axi_awprot        ,
        output  reg                         s_axi_awvalid       ,
            // axi write data channel
        input                               s_axi_wready        ,
        output      [LITE_DWIDTH - 1:0]     s_axi_wdata         ,
        output      [(LITE_DWIDTH/8) - 1:0] s_axi_wstrb         ,
        output                              s_axi_wvalid        ,
            // AXI response channel
        input       [01:0]                  s_axi_bresp         ,
        input                               s_axi_bvalid        ,
        output                              s_axi_bready        ,
            // AXI read address channel
        input                               s_axi_arready       ,
        output                              s_axi_arvalid       ,
        output      [LITE_AWIDTH - 1:0]     s_axi_araddr        ,
        output      [02:0]                  s_axi_arprot        ,
            // AXI read data channel
        input       [LITE_DWIDTH - 1:0]     s_axi_rdata         ,
        input       [01:0]                  s_axi_rresp         ,
        output                              s_axi_rready        ,
        input                               s_axi_rvalid
);

reg [DSC_WIDTH-1:0]     shift_vector;
reg [4:0]               write_cnt;
reg                     engine_finish;
reg [LITE_AWIDTH-1:0]   s_axi_araddr_r;
reg [4:0]               read_cnt;

assign complete_data = shift_vector[READREG_NUMBER*32-1:0];
assign s_axi_araddr = s_axi_araddr_r;
assign s_axi_arvalid = engine_finish & (s_axi_araddr[31] != 1'b1);
assign engine_ready = 1'b1;
assign s_axi_bready = 1'b1;
assign s_axi_rready = 1'b1;
assign s_axi_arprot = 3'b0;
assign s_axi_awprot = 3'b0;
assign s_axi_wdata = shift_vector[31:0];
assign s_axi_wstrb = 4'b1111;
assign s_axi_wvalid = (write_cnt < WRITEREG_NUMBER + 1);

always @(posedge clk)
    if(engine_start)
        shift_vector <= engine_data;
    else if(s_axi_wvalid & s_axi_wready)
        shift_vector <= {32'b0,shift_vector[DSC_WIDTH-1:32]};
    else if(s_axi_rvalid & s_axi_rready & (s_axi_rresp == 2'b00))
        shift_vector <= {shift_vector[991:0],s_axi_rdata};

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
    else if(s_axi_awvalid & s_axi_awready & (s_axi_awaddr == WRITEREG_NUMBER * 4))
        s_axi_awaddr <= 32'h80;
    else if(s_axi_awvalid & s_axi_awready)
        s_axi_awaddr <= s_axi_awaddr + 4;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        engine_finish <= 1'b0;
    else if(complete_ready & complete_accept)
        engine_finish <= 1'b0;
    else if(engine_interrupt)
        engine_finish <= 1'b1;

always @(posedge clk or negedge rst_n)
	if(!rst_n)
        complete_ready <= 1'b0;
    else if(engine_finish & (read_cnt == READREG_NUMBER))
        complete_ready <= 1'b1;
    else if(complete_accept)
        complete_ready <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        s_axi_araddr_r <= 32'h80000000;
    else if(engine_interrupt)
        s_axi_araddr_r <= READ_BASE_ADDR;
    else if(s_axi_arvalid & s_axi_arready & (s_axi_araddr_r == READ_BASE_ADDR+(READREG_NUMBER-1) * 4))
        s_axi_araddr_r <= 32'h80000000;
    else if(s_axi_arvalid & s_axi_arready)
        s_axi_araddr_r <= s_axi_araddr_r + 4;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        read_cnt <= 'd31;
    else if(engine_start)
        read_cnt <= 'd0;
    else if(s_axi_rvalid & s_axi_rready)
        read_cnt <= read_cnt + 1'b1;

endmodule
