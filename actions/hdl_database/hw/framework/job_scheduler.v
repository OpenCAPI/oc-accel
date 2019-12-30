`timescale 1ns/1ps

module job_scheduler #(
    parameter KERNEL_NUM = 8
)(
                      input             clk                   ,
                      input             rst_n                 ,

                      //---- manager ----
                      output                            dsc0_pull_o     ,
                      input                             dsc0_ready_i    ,
                      input         [1023:0]            dsc0_data_i     ,
                      //---- completion ----
                      input                             complete_ready_i,
                      output    reg                     complete_push_o ,
                      output        [40:0]              return_data_o   ,
                      //---- kernel ----
                      output    reg [KERNEL_NUM-1:0]    engine_start    ,
                      output    reg [1023:0]            jd_payload      ,
                      input         [KERNEL_NUM-1:0]    engine_done
                      );


//---- declarations ----
 reg    [KERNEL_NUM-1:0]    kernel_complete_prev;
 reg    [KERNEL_NUM-1:0]    kernel_busy;
 wire   [KERNEL_NUM-1:0]    kernel_complete_posedge;
 reg    [40:0]              kernel0_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel1_info; //40:32 pid 31:0 jobid
/* reg    [40:0]              kernel2_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel3_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel4_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel5_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel6_info; //40:32 pid 31:0 jobid
 reg    [40:0]              kernel7_info; //40:32 pid 31:0 jobid*/
 reg    [40:0]              completion_info;
 reg    [5:0]               completion_kernel;
 reg    [KERNEL_NUM-1:0]    engine_done_r;

/*genvar m;
 reg    [31:0]              process_cnt0[511:0];
 reg    [31:0]              process_cnt1[511:0];
generate
  for (m = 0; m < 512; m = m + 1) begin: process_job_run
    always@(posedge clk or negedge rst_n)
        if(!rst_n)
            process_cnt0[m] <= 'd0;
        else if((|engine_start) & (jd_payload[40:32] == m))
            process_cnt0[m] <= process_cnt0[m] + 1'b1;

    always@(posedge clk or negedge rst_n)
        if(!rst_n)
            process_cnt1[m] <= 'd0;
        else if(complete_push_o & (completion_info[40:32] == m))
            process_cnt1[m] <= process_cnt1[m] + 1'b1;
    end
endgenerate*/

/*genvar i;
generate
  for (i = 0; i < KERNEL_NUM; i = i + 1) begin:kernel_complete_posedge_gen
    assign kernel_complete_posedge[i] = (kernel_complete_prev[i] == 0) & (engine_done[i] == 1);
  end
endgenerate

 always@(posedge clk or negedge rst_n)
   if(~rst_n)
     kernel_complete_prev <= {KERNEL_NUM{1'b1}};
   else
     kernel_complete_prev <= engine_done;*/

assign dsc0_pull_o = !(&kernel_busy) & dsc0_ready_i & !engine_start;
//assign complete_push_o = |(engine_done & kernel_busy);
assign return_data_o = completion_info;

genvar j;
generate
  for (j = 0; j < KERNEL_NUM; j = j + 1) begin:kernel_logic_gen
    always@(posedge clk or negedge rst_n)
        if(!rst_n)
            engine_done_r[j] <= 1'b0;
		else if(engine_start[j])
            engine_done_r[j] <= 1'b0;
		else if(engine_done[j])
            engine_done_r[j] <= 1'b1;

    always@(posedge clk or negedge rst_n)
        if(!rst_n)
            kernel_busy[j] <= 1'b0;
        else if(engine_start[j] == 1'b1)
            kernel_busy[j] <= 1'b1;
        else if(kernel_busy[j] & engine_done_r[j] & (completion_kernel == j) & complete_ready_i)
            kernel_busy[j] <= 1'b0;
  end
endgenerate

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        completion_kernel <= 6'b0;
    else if(completion_kernel == KERNEL_NUM - 1)
        completion_kernel <= 6'b0;
    else if(|kernel_busy)
        completion_kernel <= completion_kernel + 1'b1;

always@(*)
	case(completion_kernel)
        'd0: complete_push_o = engine_done_r[0] & kernel_busy[0] & complete_ready_i;
        'd1: complete_push_o = engine_done_r[1] & kernel_busy[1] & complete_ready_i;
/*        'd2: complete_push_o = engine_done_r[2] & kernel_busy[2] & complete_ready_i;
        'd3: complete_push_o = engine_done_r[3] & kernel_busy[3] & complete_ready_i;
        'd4: complete_push_o = engine_done_r[4] & kernel_busy[4] & complete_ready_i;
        'd5: complete_push_o = engine_done_r[5] & kernel_busy[5] & complete_ready_i;
        'd6: complete_push_o = engine_done_r[6] & kernel_busy[6] & complete_ready_i;
        'd7: complete_push_o = engine_done_r[7] & kernel_busy[7] & complete_ready_i;*/
		default: complete_push_o = 1'b0;
    endcase

always@(*)
    case(completion_kernel)
        'd0: completion_info = kernel0_info;
        'd1: completion_info = kernel1_info;
/*        'd2: completion_info = kernel2_info;
        'd3: completion_info = kernel3_info;
        'd4: completion_info = kernel4_info;
        'd5: completion_info = kernel5_info;
        'd6: completion_info = kernel6_info;
        'd7: completion_info = kernel7_info;*/
		default: completion_info = 'd0;
    endcase

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        engine_start <= 'd0;
    else if(dsc0_pull_o) begin
        case(kernel_busy)
            2'b00: engine_start <= 2'b10;
			2'b01: engine_start <= 2'b10;
			2'b10: engine_start <= 2'b01;
			2'b11: engine_start <= 2'b01;
        /*casex(kernel_busy)
            8'b0xxxxxxx: engine_start <= 8'b10000000;
            8'b10xxxxxx: engine_start <= 8'b01000000;
            8'b110xxxxx: engine_start <= 8'b00100000;
            8'b1110xxxx: engine_start <= 8'b00010000;
            8'b11110xxx: engine_start <= 8'b00001000;
            8'b111110xx: engine_start <= 8'b00000100;
            8'b1111110x: engine_start <= 8'b00000010;
            8'b11111110: engine_start <= 8'b00000001;
            default:     engine_start <= 8'b00000000;*/
        endcase
        end
    else
        engine_start <= 'd0;

always@(posedge clk) if(dsc0_pull_o) jd_payload <= {dsc0_data_i[63:32],dsc0_data_i[1023:64],dsc0_data_i[1023:992]};
always@(posedge clk) if(engine_start[0]) kernel0_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[1]) kernel1_info <= {jd_payload[8:0],jd_payload[1023:992]};
/*always@(posedge clk) if(engine_start[2]) kernel2_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[3]) kernel3_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[4]) kernel4_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[5]) kernel5_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[6]) kernel6_info <= {jd_payload[8:0],jd_payload[1023:992]};
always@(posedge clk) if(engine_start[7]) kernel7_info <= {jd_payload[8:0],jd_payload[1023:992]};*/

/*always@(*)
    if(complete_push_o)
        casex(engine_done & kernel_busy)
            8'b1xxxxxxx: completion_info = kernel7_info;
            8'b01xxxxxx: completion_info = kernel6_info;
            8'b001xxxxx: completion_info = kernel5_info;
            8'b0001xxxx: completion_info = kernel4_info;
            8'b00001xxx: completion_info = kernel3_info;
            8'b000001xx: completion_info = kernel2_info;
            8'b0000001x: completion_info = kernel1_info;
            default: completion_info = kernel0_info;
        endcase
    else
        completion_info = 'd0;*/

endmodule
