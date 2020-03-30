#include "ap_int.h"
#define BUFFER_SIZE 256
#define DATA_SIZE 4096

#define BUS_WIDTH 1024

//TRIPCOUNT identifier
const unsigned int c_len = DATA_SIZE / BUFFER_SIZE;
const unsigned int c_size = BUFFER_SIZE;


extern "C" {
void mc_kernel (const ap_uint<BUS_WIDTH> *src, // Read-only source location
                      ap_uint<BUS_WIDTH> *tgt, // Target location
                      unsigned int delay_cycle ,
                      unsigned int size        // size in BUS_WIDTH/8 bytes ( how many beats)
) {
// Here Vitis kernel contains one s_axilite interface which will be used by host application to configure the kernel.
// Here bundle control is defined which is s_axilite interface and associated with all the arguments (in1, in2, out_r and size),
// control interface must also be associated with "return".
// All the global memory access arguments must be associated to one m_axi(AXI Master Interface). Here all three arguments(in1, in2, out_r) are
// associated to bundle gmem which means that a AXI master interface named "gmem" will be created in Kernel and all these variables will be
// accessing global memory through this interface.
// Multiple interfaces can also be created based on the requirements. For example when multiple memory accessing arguments need access to
// global memory simultaneously, user can create multiple master interfaces and can connect to different arguments.
#pragma HLS INTERFACE m_axi port = src offset = slave bundle = gmem
#pragma HLS INTERFACE m_axi port = tgt offset = slave bundle = gmem
#pragma HLS INTERFACE s_axilite port = src bundle = control
#pragma HLS INTERFACE s_axilite port = tgt bundle = control
#pragma HLS INTERFACE s_axilite port = delay_cycle bundle = control
#pragma HLS INTERFACE s_axilite port = size bundle = control
#pragma HLS INTERFACE s_axilite port = return bundle = control

    ap_uint<BUS_WIDTH> temp_buffer[BUFFER_SIZE];   // Local memory to store vector1

    //Per iteration of this loop perform BUFFER_SIZE vector addition
    for (int i = 0; i < size; i += BUFFER_SIZE) {
       #pragma HLS LOOP_TRIPCOUNT min=c_len max=c_len
        int chunk_size = BUFFER_SIZE;
        //boundary checks
        if ((i + BUFFER_SIZE) > size)
            chunk_size = size - i;

        // Transferring data in bursts hides the memory access latency as well as improves bandwidth utilization and efficiency of the memory controller.
        // It is recommended to infer burst transfers from successive requests of data from consecutive address locations.
        // A local memory vl_local is used for buffering the data from a single burst. The entire input vector is read in multiple bursts.
        // The choice of LOCAL_MEM_SIZE depends on the specific applications and available on-chip memory on target FPGA.
        // burst read of v1 and v2 vector from global memory

    read1:
        for (int j = 0; j < chunk_size; j++) {
           #pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
           #pragma HLS PIPELINE II=1
            temp_buffer[j] = src[i + j];
        }

    wait_cycle: 
        for (int cyc = 0; cyc < delay_cycle; cyc++)
            ;

    //burst write the result
    write:
        for (int j = 0; j < chunk_size; j++) {
           #pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
           #pragma HLS PIPELINE II=1
            tgt[i + j] = temp_buffer[j];
        }
    }
}
}
