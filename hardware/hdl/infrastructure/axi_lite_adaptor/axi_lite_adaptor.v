`timescale 1ns/1ps

module axi_lite_adaptor #(
    parameter   LITE_DWIDTH     = 32,
    parameter   LITE_AWIDTH     = 32,
    parameter   DSC_WIDTH       = 1024,
    parameter   READREG_NUMBER  = 1,
    parameter   READ_BASE_ADDR  = 'h100,
    parameter   CTRL_OFFSET     = 'h00,
    parameter   GIER_OFFSET     = 'h04,
    parameter   IER_OFFSET      = 'h08,
    parameter   CONTEXT_OFFSET  = 'h20,
    parameter   HELPER_OFFSET   = 'h20000,
    parameter   NUM_SPECIAL_WR  = 3
)(
    input                               clk                 ,
    input                               resetn              ,
    input                               kernel_done         ,
    input                               kernel_start        ,
    output                              kernel_ready        ,
    input       [DSC_WIDTH-1:0]         kernel_data         ,
    output  reg                         complete_ready      ,
    input                               complete_accept     ,
    output      [READREG_NUMBER*32-1:0] complete_data       ,

    //---- Interrupt----
    input                               interrupt_req       ,
    input       [63:0]                  interrupt_src       ,
    input       [8:0]                   interrupt_ctx       ,
    output  reg                         interrupt_ack       ,

    //---- AXI Lite bus----
    input                               s_axi_awready       ,
    output  reg [LITE_AWIDTH - 1:0]     s_axi_awaddr        ,
    output      [02:0]                  s_axi_awprot        ,
    output                              s_axi_awvalid       ,
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

    `include "kernel_register_layout.vh"

    reg [DSC_WIDTH-1:0]     shift_vector;
    reg [4:0]               write_cnt;
    reg [4:0]               awrite_cnt;
    reg                     kernel_finish;
    reg [LITE_AWIDTH-1:0]   s_axi_araddr_r;
    reg [4:0]               read_cnt;
    reg                     kernel_run;
    wire [LITE_AWIDTH-1:0]  write_addr;
    wire [LITE_AWIDTH-1:0]  data_tmp[WRITEREG_NUMBER-1:0];
    wire [LITE_AWIDTH-1:0]  data_tmp2[WRITEREG_NUMBER-1:0];

    genvar i;
    generate
        for(i=0 ; i<WRITEREG_NUMBER ; i=i+1) begin: axi_lite_addr
            if(i==0) begin
                assign data_tmp2[0] = (awrite_cnt==0) ? PARAM_ARRAY[31:0] : 'h0;
                assign data_tmp[0] = data_tmp2[0];
            end
            else begin
                assign data_tmp2[i] = (awrite_cnt==i) ? PARAM_ARRAY[i*32+31:i*32] : 'h0;
                assign data_tmp[i] = data_tmp[i-1] | data_tmp2[i];
            end
        end
    endgenerate
    assign write_addr = (awrite_cnt < WRITEREG_NUMBER)      ? data_tmp[WRITEREG_NUMBER-1] :
                        (awrite_cnt == WRITEREG_NUMBER)     ? GIER_OFFSET                 :
                        (awrite_cnt == WRITEREG_NUMBER + 1) ? IER_OFFSET                  :
                        (awrite_cnt == WRITEREG_NUMBER + 2) ? CTRL_OFFSET                 : 
                                                              0;

    assign complete_data = shift_vector[READREG_NUMBER*32-1:0];
    assign s_axi_araddr = s_axi_araddr_r;
    assign s_axi_arvalid = kernel_finish & (s_axi_araddr[31] != 1'b1);
    assign kernel_ready = !kernel_start & !kernel_run & !kernel_finish;
    assign s_axi_bready = 1'b1;
    assign s_axi_rready = 1'b1;
    assign s_axi_arprot = 3'b0;
    assign s_axi_awprot = 3'b0;
    assign s_axi_wdata = shift_vector[63:32];
    assign s_axi_wstrb = 4'b1111;
    assign s_axi_awvalid = (awrite_cnt <=  WRITEREG_NUMBER + NUM_SPECIAL_WR);
    assign s_axi_wvalid = (write_cnt <= WRITEREG_NUMBER + NUM_SPECIAL_WR);

    always @(posedge clk or negedge resetn)
        if(!resetn)
            kernel_run <= 1'b0;
        else if(kernel_start)
            kernel_run <= 1'b1;
        else if(kernel_done)
            kernel_run <= 1'b0;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            interrupt_ack <= 1'b0;
        else if(kernel_done)
            interrupt_ack <= 1'b1;
        else if(!kernel_done)
            interrupt_ack <= 1'b0;

    always @(posedge clk)
        if(kernel_start)
            shift_vector <= kernel_data;
        else if(s_axi_wvalid & s_axi_wready & (write_cnt >= WRITEREG_NUMBER))
            // TODO:  Write 1 to all special registers ?
            shift_vector <= {shift_vector[DSC_WIDTH-1:64],32'h1,shift_vector[31:0]};
        else if(s_axi_wvalid & s_axi_wready)
            shift_vector <= {32'b0,shift_vector[DSC_WIDTH-1:32]};
        else if(s_axi_rvalid & s_axi_rready & (s_axi_rresp == 2'b00))
            shift_vector <= {shift_vector[991:0],s_axi_rdata};

    always @(posedge clk or negedge resetn)
        if(!resetn)
            awrite_cnt <= 'd31;
        else if(kernel_start)
            awrite_cnt <= 'd0;
        else if(s_axi_awvalid & s_axi_awready)
            awrite_cnt <= awrite_cnt + 1'b1;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            write_cnt <= 'd31;
        else if(kernel_start)
            write_cnt <= 'd0;
        else if(s_axi_wvalid & s_axi_wready)
            write_cnt <= write_cnt + 1'b1;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            s_axi_awaddr <= 'h80;
        else if(kernel_start)
            // Write the PASID ID
            s_axi_awaddr <= HELPER_OFFSET + CONTEXT_OFFSET;
        else if(s_axi_awvalid & s_axi_awready)
            s_axi_awaddr <= write_addr;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            kernel_finish <= 1'b0;
        else if(complete_ready & complete_accept)
            kernel_finish <= 1'b0;
        else if(kernel_done)
            kernel_finish <= 1'b1;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            complete_ready <= 1'b0;
        else if(kernel_finish & (read_cnt == READREG_NUMBER))
            complete_ready <= 1'b1;
        else if(complete_accept)
            complete_ready <= 1'b0;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            s_axi_araddr_r <= 32'h80000000;
        else if(kernel_done)
            s_axi_araddr_r <= READ_BASE_ADDR;
        else if(s_axi_arvalid & s_axi_arready & (s_axi_araddr_r == READ_BASE_ADDR+(READREG_NUMBER-1) * 4))
            s_axi_araddr_r <= 32'h80000000;
        else if(s_axi_arvalid & s_axi_arready)
            s_axi_araddr_r <= s_axi_araddr_r + 4;

    always @(posedge clk or negedge resetn)
        if(!resetn)
            read_cnt <= 'd31;
        else if(kernel_start)
            read_cnt <= 'd0;
        else if(s_axi_rvalid & s_axi_rready)
            read_cnt <= read_cnt + 1'b1;

endmodule