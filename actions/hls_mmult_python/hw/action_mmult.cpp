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

/*
 * SNAP HLS_HELLOWORLD EXAMPLE
 *
 * Tasks for the user:
 *   1. Explore HLS pragmas to get better timing behavior.
 *   2. Try to measure the time needed to do data transfers (advanced)
 */

#include <string.h>
#include "ap_int.h"
#include "action_mmult.H"


void mmult(int *a, // Read-Only Matrix A
		   int *b, // Read-Only Matrix B
		   int *c,       // Output Result
           uint32_t a_row,    // Matrix A Row Size
           uint32_t a_col,    // Matrix A Col Size
           uint32_t b_col     // Matrix B Col Size
) {
/*   #pragma HLS INTERFACE m_axi port=a offset=slave bundle=gmem
   #pragma HLS INTERFACE m_axi port=b offset=slave bundle=gmem
   #pragma HLS INTERFACE m_axi port=c offset=slave bundle=gmem

   #pragma HLS INTERFACE s_axilite port=a bundle=control
   #pragma HLS INTERFACE s_axilite port=b bundle=control
   #pragma HLS INTERFACE s_axilite port=c bundle=control
   #pragma HLS INTERFACE s_axilite port=a_row bundle=control
   #pragma HLS INTERFACE s_axilite port=a_col bundle=control
   #pragma HLS INTERFACE s_axilite port=b_col bundle=control
   #pragma HLS INTERFACE s_axilite port=return bundle=control
*/
    uint32_t b_row = a_col;
    uint32_t c_row = a_row;
    uint32_t c_col = b_col;

    // Local memory to store input and output matrices
    int localA[MAX_SIZE][MAX_SIZE];
   #pragma HLS ARRAY_PARTITION variable=localA dim=1 complete

    int localB[MAX_SIZE][MAX_SIZE];
   #pragma HLS ARRAY_PARTITION variable=localB dim=2 complete

    int localC[MAX_SIZE][MAX_SIZE];
#pragma HLS ARRAY_PARTITION variable = localC dim = 0 complete

// Burst reads on input matrices from global memory
// Read Input A
readA:
    for (uint32_t loc = 0, i = 0, j = 0; loc < a_row * a_col; loc++, j++) {
       #pragma HLS LOOP_TRIPCOUNT min=c_size*c_size max=c_size*c_size
       #pragma HLS PIPELINE II=1
        if (j == a_col) {
            i++;
            j = 0;
        }
        localA[i][j] = a[loc];
    }

// Read Input B
readB:
    for (uint32_t loc = 0, i = 0, j = 0; loc < b_row * b_col; loc++, j++) {
       #pragma HLS LOOP_TRIPCOUNT min=c_size*c_size max=c_size*c_size
       #pragma HLS PIPELINE II=1
        if (j == b_col) {
            i++;
            j = 0;
        }
        localB[i][j] = b[loc];
    }

    // Perform systolic matrix multiply
    // local matrices localA and localB have been partitioned in dimensions
    // 1 and 2 respectively. local matrix C has been partitioned completely

    // This partitioning enables to access MAX_SIZE elements in parallel in
    // the local matrices. Because of the mode of access of array elements,
    // we are able to perform MAX_SIZE*MAX_SIZE operations in parallel.

    // Note : i, j and k loops are interchanged.

    // The top loop systolic1 runs only for a_col iterations instead of
    // MAX_SIZE like the inner loops. The inner loops have fixed loop
    // iteration counts to enable complete unroll

    // The following diagram explains how the matrix multiply happens
    //
    //        B_0        B_1        B_2        B_3
    //         |          |          |          |
    //         v          v          v          v
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A0_->|C00| ---- |C01| ---- |C02| ---- |C03|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A1_->|C10| ---- |C11| ---- |C12| ---- |C13|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A2_->|C20| ---- |C21| ---- |C21| ---- |C21|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A3_->|C30| ---- |C31| ---- |C32| ---- |C33|
    //       |___|      |___|      |___|      |___|

systolic1:
    for (uint32_t k = 0; k < a_col; k++) {
       #pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
       #pragma HLS PIPELINE II=1
    systolic2:
        for (uint32_t i = 0; i < MAX_SIZE; i++) {
        systolic3:
            for (uint32_t j = 0; j < MAX_SIZE; j++) {

                // Get previous sum
                uint32_t last = (k == 0) ? 0 : localC[i][j];

                // Update current sum
                // Handle boundary conditions
                int a_val = (i < a_row && k < a_col) ? localA[i][k] : 0;
                int b_val = (k < b_row && j < b_col) ? localB[k][j] : 0;
                int result = last + a_val * b_val;

                // Write back results
                localC[i][j] = result;
            }
        }
    }

// Burst write from output matrices to global memory
// Burst write from matrix C
writeC:
    for (uint32_t loc = 0, i = 0, j = 0; loc < c_row * c_col; loc++, j++) {
       #pragma HLS LOOP_TRIPCOUNT min=c_size*c_size max=c_size*c_size
       #pragma HLS PIPELINE II=1
        if (j == c_col) {
            i++;
            j = 0;
        }
        c[loc] = localC[i][j];
    }
}


//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
	      snap_membus_t *dout_gmem,
	      /* snap_membus_t *d_ddrmem, *//* not needed */
	      action_reg *act_reg)
{
    uint32_t size, bytes_to_transfer;
    uint64_t i_idx, o_idx;

    /* byte address received need to be aligned with port width */
    i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
    o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
    size = act_reg->Data.in.size;

    int a[MAX_SIZE*MAX_SIZE], b[MAX_SIZE*MAX_SIZE], c[MAX_SIZE*MAX_SIZE];

//    main_loop:
//    while (size > 0) {
//#pragma HLS PIPELINE
	unsigned char i;

	/* Limit the number of bytes to process to a 64B word */
	bytes_to_transfer = MIN(size, BPERDW);

        /* Read in one word_t */
	memcpy((int*) a, din_gmem + i_idx, MAX_SIZE * MAX_SIZE * sizeof(int));
	memcpy((int*) b, din_gmem + i_idx, MAX_SIZE * MAX_SIZE * sizeof(int));


    //for (unsigned j = 0; j < 16; ++j) { // FIXME: set 16 dynamic
    //    #pragma HLS UNROLL
    //	value_u = pack((8*sizeof(int)*(j+1))-1, (8*sizeof(int)*j));
    //}

	mmult(	a, // Read-Only Matrix A
        	b, // Read-Only Matrix B
        	c, // Output Result
	        act_reg->Data.a_row,  // Matrix A Row Size
          	act_reg->Data.a_col,  // Matrix A Col Size
          	act_reg->Data.b_col); // Matrix B Col Size

	/* Write out one word_t */
	memcpy(dout_gmem + o_idx, (int*) c, MAX_SIZE * MAX_SIZE * sizeof(int));

	size -= bytes_to_transfer;
	i_idx++;
	o_idx++;
//    }

    act_reg->Control.Retc = SNAP_RETC_SUCCESS;
    return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
	snap_membus_t *dout_gmem,
	/* snap_membus_t *d_ddrmem, // CAN BE COMMENTED IF UNUSED */
	action_reg *act_reg)
{
    // Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

/*  // DDR memory Interface - CAN BE COMMENTED IF UNUSED
 * #pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
 *   max_read_burst_length=64  max_write_burst_length=64
 * #pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050
 */
    // Host Memory AXI Lite Master Interface - NO CHANGE BELOW
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	process_action(din_gmem, dout_gmem, act_reg);
}

//-----------------------------------------------------------------------------
//-- TESTBENCH BELOW IS USED ONLY TO DEBUG THE HARDWARE ACTION WITH HLS TOOL --
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

// Software implementation of Matrix Multiplication
// The inputs are of the size (DATA_SIZE x DATA_SIZE)
void m_softwareGold(
    int* in1, //Input Matrix 1
	int* in2, //Input Matrix 2
	int* out  //Output Matrix
) {
    //Perform Matrix multiply Out = In1 x In2
    for (int i = 0; i < DATA_SIZE; i++) {
        for (int j = 0; j < DATA_SIZE; j++) {
            for (int k = 0; k < DATA_SIZE; k++) {
                out[i * DATA_SIZE + j] +=
                    in1[i * DATA_SIZE + k] * in2[k * DATA_SIZE + j];
            }
        }
  }
}


int main(void)
{
#define MEMORY_LINES 5
    int rc = 0;
    unsigned int i;

    action_reg act_reg;

    int size_n, size_k, size_m;
    size_n = size_k = size_m = DATA_SIZE;

    unsigned memory_lines_a = ((unsigned int)ceil((float)(size_n * size_k * sizeof(int)) / (float)sizeof(snap_membus_t)));
    unsigned memory_lines_b = ((unsigned int)ceil((float)(size_k * size_m * sizeof(int)) / (float)sizeof(snap_membus_t)));
    unsigned memory_lines_c = ((unsigned int)ceil((float)(size_n * size_m * sizeof(int)) / (float)sizeof(snap_membus_t)));
    unsigned memory_lines_in = (memory_lines_a + memory_lines_b);
    unsigned memory_lines_out = memory_lines_c;
    unsigned offset_b = memory_lines_a;

    snap_membus_t * din_gmem = (snap_membus_t *)malloc(memory_lines_in*sizeof(snap_membus_t));
    snap_membus_t * dout_gmem = (snap_membus_t *)malloc(memory_lines_out*sizeof(snap_membus_t));
    if ((din_gmem == NULL) || (dout_gmem == NULL)) {
    	fprintf(stderr, "Error allocating memory for snap axi lines in testbench. Aborting...\n\n");
    	return 1;
    }

    printf("INFO: AXI/Cache lines for a  : %u/%u\n", memory_lines_a, memory_lines_a/2);
    printf("INFO: AXI/Cache lines for b  : %u/%u\n", memory_lines_b, memory_lines_b/2 );
    printf("INFO: AXI/Cache lines for IN : %u/%u\n", memory_lines_in, memory_lines_in/2);
    printf("INFO: AXI/Cache lines for OUT: %u/%u\n", memory_lines_out, memory_lines_out/2);
    printf("INFO: size_n=%u, size_k=%u, size_m=%u\n", size_n, size_k, size_m);



    //Allocate Memory in Host Memory
    if (DATA_SIZE > MAX_SIZE) {
        printf( "Size is bigger than internal buffer size, please use a size smaller than %u !\n", 
                  MAX_SIZE);
        return EXIT_FAILURE;
    }

    size_t matrix_size = DATA_SIZE * DATA_SIZE;
    size_t matrix_size_bytes = sizeof(int) * matrix_size;

    int *source_in1 = (int*)malloc(matrix_size_bytes);
    int *source_in2 = (int*)malloc(matrix_size_bytes);
    int *source_hw_results = (int*)malloc(matrix_size_bytes);
    int *source_sw_results = (int*)malloc(matrix_size_bytes);

    if ((source_in1 == NULL) || (source_in2 == NULL) || (source_hw_results == NULL) || (source_sw_results == NULL)) {
        printf( "Failed to allocate memory. Aborting...\n");
        return EXIT_FAILURE;
    }

    // Create the test data and Software Result
    for (size_t i = 0; i < matrix_size; i++) {
        source_in1[i] = i % 10;
        source_in2[i] = i % 10;
        source_sw_results[i] = 0;
        source_hw_results[i] = 0;
    }

    act_reg.Data.a_row = DATA_SIZE;
    act_reg.Data.a_col = DATA_SIZE;
    act_reg.Data.b_col = DATA_SIZE;
    act_reg.Data.offset_to_point_b = offset_b;

    memcpy(din_gmem,   source_in1, MAX_SIZE * MAX_SIZE * sizeof(int));
    //memcpy(din_gmem+2, source_in2, MAX_SIZE * MAX_SIZE * sizeof(int));

    // Processing Phase .....

    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = DATA_SIZE * DATA_SIZE * 2;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = DATA_SIZE * DATA_SIZE * 2;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(din_gmem, dout_gmem, &act_reg);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    memcpy(source_hw_results, dout_gmem, MAX_SIZE * MAX_SIZE * sizeof(int));

    // Compute Software Results
    m_softwareGold(source_in1, source_in2, source_sw_results);


    // Compare the results of the Device to the simulation
    int match = 0;
    for (int i = 0; i < DATA_SIZE * DATA_SIZE; i++) {
        if (source_hw_results[i] != source_sw_results[i]) {
            printf("Error: Result mismatch\n");
            printf("i = %d, CPU result = %d, Device result = %d\n", i, source_sw_results[i], source_hw_results[i]);
            match = 1;
            break;
        }
    }

    printf("TEST %s\n", (match ? "FAILED" : "PASSED"));

    free(source_in1);
    free(source_in2);
    free(source_hw_results);
    free(source_sw_results);

    return (match ? EXIT_FAILURE : EXIT_SUCCESS);

    return 0;
}

#endif
