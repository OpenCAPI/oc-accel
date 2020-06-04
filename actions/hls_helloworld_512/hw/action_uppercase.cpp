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
 * SNAP HLS_HELLOWORLD_512 EXAMPLE
 *
 * Tasks for the user:
 *   1. Explore HLS pragmas to get better timing behavior.
 *   2. Try to measure the time needed to do data transfers (advanced)
 */

#include <string.h>
#include "ap_int.h"
#include "action_uppercase.H"

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_512_t *din_gmem,
	      snap_membus_512_t *dout_gmem,
	      /* snap_membus_512_t *d_ddrmem, *//* not needed */
	      action_reg *act_reg)
{
    uint32_t size, bytes_to_transfer;
    uint64_t i_idx, o_idx;

    /* byte address received need to be aligned with port width */
    i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT_512;
    o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT_512;
    size = act_reg->Data.in.size;

    main_loop:
    while (size > 0) {
//#pragma HLS PIPELINE
	word_t text;
	unsigned char i;

	/* Limit the number of bytes to process to a 64B word */
	bytes_to_transfer = MIN(size, BPERDW_512);

        /* Read in one word_t */
	memcpy((char*) text, din_gmem + i_idx, BPERDW_512);

	/* Convert lower cases to upper cases byte per byte */
    uppercase_conversion:
	for (i = 0; i < sizeof(text); i++ ) {
//#pragma HLS UNROLL
	    if (text[i] >= 'a' && text[i] <= 'z')
		text[i] = text[i] - ('a' - 'A');
	}

	/* Write out one word_t */
	memcpy(dout_gmem + o_idx, (char*) text, BPERDW_512);

	size -= bytes_to_transfer;
	i_idx++;
	o_idx++;
    }

    act_reg->Control.Retc = SNAP_RETC_SUCCESS;
    return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
// snap_membus_512_t is defined in actions/include/hls_snap_1024.H
// which deals with both 512 and 1024 bits wide busses
void hls_action(snap_membus_512_t *din_gmem,
	snap_membus_512_t *dout_gmem,
	/* snap_membus_512_t *d_ddrmem, // CAN BE COMMENTED IF UNUSED */
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

int main(void)
{
#define MEMORY_LINES 1
    int rc = 0;
    unsigned int i;
    static snap_membus_512_t  din_gmem[MEMORY_LINES];
    static snap_membus_512_t  dout_gmem[MEMORY_LINES];

    action_reg act_reg;


    // Processing Phase .....
    // Fill the memory with 'c' characters
    memset(din_gmem,  'c', sizeof(din_gmem[0]));
    printf("Input is : %s\n", (char *)((unsigned long)din_gmem + 0));

    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 64;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = 64;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(din_gmem, dout_gmem, &act_reg);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    printf("Output is : %s\n", (char *)((unsigned long)dout_gmem + 0));

    return 0;
}

#endif
