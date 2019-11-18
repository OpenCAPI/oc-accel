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

/* SNAP HLS_MEMCOPY EXAMPLE */

#include <string.h>
#include "ap_int.h"
#include "hw_action_memcopy_1024.H"

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_1024_t *dout_gmem,
				 snap_membus_512_t *d_ddrmem,
				 snapu16_t memory_in_type,
				 snapu16_t memory_out_type,
				 snapu64_t output_address_1024,
				 snapu64_t output_address,
				 snap_membus_1024_t *buffer_gmem,
				 snap_membus_512_t *buffer_ddrmem,
				 snapu64_t size_in_bytes_to_transfer)
{
	short rc;
    ap_int<MEMDW_512> mask_full = -1;
    snap_membus_1024_t mask_512 = snap_membus_512_t(mask_full);
    snap_membus_1024_t data_entry = 0;

	// Prepare Patch to the issue#652 - memcopy doesn't handle small packets
	int size_in_words_1024;
	if(size_in_bytes_to_transfer %BPERDW_1024 == 0)
		size_in_words_1024 = size_in_bytes_to_transfer/BPERDW_1024;
	else
		size_in_words_1024 = (size_in_bytes_to_transfer/BPERDW_1024) + 1;

	int size_in_words_512;
	if(size_in_bytes_to_transfer %BPERDW_512 == 0)
		size_in_words_512 = size_in_bytes_to_transfer/BPERDW_512;
	else
		size_in_words_512 = (size_in_bytes_to_transfer/BPERDW_512) + 1;
	//end of patch
//========================data from buffer_gmem======================================//
	if (memory_in_type == SNAP_ADDRTYPE_HOST_DRAM) {
           if(memory_out_type == SNAP_ADDRTYPE_HOST_DRAM) {
		      // Patch to the issue#652 - memcopy doesn't handle small packets
		      // Do not insert anything more in this loop to not break the burst
		      wb_dout2dout_loop: for (int k=0; k<size_in_words_1024; k++)
		      #pragma HLS PIPELINE
                          (dout_gmem + output_address_1024)[k] = buffer_gmem[k];
		      // end of patch
       	      rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_CARD_DRAM) {
		     wb_gbuf2dbuf_loop: for (int k=0; k<size_in_words_1024; k++) {
                                  for (int j=0; j<MEMDW_1024/MEMDW_512; j++) {
		     #pragma HLS PIPELINE
                                    buffer_ddrmem[k*MEMDW_1024/MEMDW_512+j] = (snap_membus_512_t)((buffer_gmem[k] >> j*MEMDW_512) & mask_512);
                                  }
                               }
		     wb_dbuf2ddr_loop: for (int k=0; k<size_in_words_512; k++)
		     #pragma HLS PIPELINE
                         (d_ddrmem + output_address)[k] = buffer_ddrmem[k];
             rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_UNUSED)
             rc = 0;
           else
             rc = 1;
	}
//=========================data from buffer_ddrmem=====================================//
	else if (memory_in_type == SNAP_ADDRTYPE_CARD_DRAM) {
           if(memory_out_type == SNAP_ADDRTYPE_HOST_DRAM) {
		     wb_dbuf2gbuf_loop: for (int k=0; k<size_in_words_1024; k++) {
                                  for (int j=0; j<MEMDW_1024/MEMDW_512; j++) {
		     #pragma HLS PIPELINE
                                    data_entry |= ((snap_membus_1024_t)(buffer_ddrmem[k*MEMDW_1024/MEMDW_512+j])) << j*MEMDW_512;
                                  }
                                  buffer_gmem[k] = data_entry;
                                  data_entry = 0;
                                }
		     wb_gbuf2dout_loop: for (int k=0; k<size_in_words_1024; k++)
		     #pragma HLS PIPELINE
                         (dout_gmem + output_address_1024)[k] = buffer_gmem[k];
             rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_CARD_DRAM) {
		     wb_ddr2ddr_loop: for (int k=0; k<size_in_words_512; k++)
		     #pragma HLS PIPELINE
                        (d_ddrmem + output_address)[k] = buffer_ddrmem[k];
             rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_UNUSED)
             rc = 0;
           else
             rc = 1;
	}
//========================no data from specified=======================================//
	else if (memory_in_type == SNAP_ADDRTYPE_UNUSED) {
           if(memory_out_type == SNAP_ADDRTYPE_HOST_DRAM) {
		      wb_dout_loop: for (int k=0; k<size_in_words_1024; k++)
		      #pragma HLS PIPELINE
                          (dout_gmem + output_address_1024)[k] = buffer_gmem[k];
       	      rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_CARD_DRAM) {
		     wb_ddr_loop: for (int k=0; k<size_in_words_512; k++)
		     #pragma HLS PIPELINE
                        (d_ddrmem + output_address)[k] = buffer_ddrmem[k];
             rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_UNUSED)
             rc = 0;
           else
             rc = 1;
    }
//=====================================================================================//
	else
		rc = 1;

	return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(snap_membus_1024_t *din_gmem,
				  snap_membus_512_t *d_ddrmem,
				  snapu16_t memory_type,
				  snapu64_t input_address_1024,
				  snapu64_t input_address,
				  snap_membus_1024_t *buffer_gmem,
				  snap_membus_512_t *buffer_ddrmem,
				  snapu64_t size_in_bytes_to_transfer)
{
	short rc;
        int i;

	switch (memory_type) {

	case SNAP_ADDRTYPE_HOST_DRAM:
		memcpy(buffer_gmem, (snap_membus_1024_t  *) (din_gmem + input_address_1024),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_CARD_DRAM:
		memcpy(buffer_ddrmem, (snap_membus_512_t  *) (d_ddrmem + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_UNUSED: /* no copy but with rc =0 */
       		rc =  0;
		break;
	default:
		rc = 1;
	}

	return rc;
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static void process_action(snap_membus_1024_t *din_gmem,
                           snap_membus_1024_t *dout_gmem,
                           snap_membus_512_t *d_ddrmem,
                           action_reg *act_reg)
{
	// VARIABLES
	snapu32_t xfer_size;
	snapu32_t action_xfer_size;
	snapu32_t nb_blocks_to_xfer;
	snapu16_t i;
	short rc = 0;
	snapu32_t ReturnCode = SNAP_RETC_SUCCESS;
	snapu64_t InputAddress_1024;
	snapu64_t OutputAddress_1024;
	snapu64_t address_xfer_offset_1024;
	snapu64_t InputAddress_512;
	snapu64_t OutputAddress_512;
	snapu64_t address_xfer_offset_512;
	snap_membus_1024_t  buf_gmem[MAX_NB_OF_WORDS_READ_1024];
	snap_membus_512_t   buf_ddrmem[MAX_NB_OF_WORDS_READ_512];
	// if 4096 bytes max => 64 words

	// byte address received need to be aligned with port width
	InputAddress_1024 = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT_1024;
	OutputAddress_1024 = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT_1024;
	InputAddress_512 = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT_512;
	OutputAddress_512 = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT_512;

	address_xfer_offset_512 = 0x0;
	address_xfer_offset_1024 = 0x0;
	// testing sizes to prevent from writing out of bounds
	action_xfer_size = MIN(act_reg->Data.in.size,
			       act_reg->Data.out.size);

	if (act_reg->Data.in.type == SNAP_ADDRTYPE_CARD_DRAM and
	    act_reg->Data.in.size > CARD_DRAM_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }
	if (act_reg->Data.out.type == SNAP_ADDRTYPE_CARD_DRAM and
	    act_reg->Data.out.size > CARD_DRAM_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }

	// buffer size is hardware limited by MAX_NB_OF_BYTES_READ
	if(action_xfer_size %MAX_NB_OF_BYTES_READ == 0)
		nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ);
	else
		nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ) + 1;

	// transferring buffers one after the other
	L0:
	for ( i = 0; i < nb_blocks_to_xfer; i++ ) {
#pragma HLS UNROLL		// cannot completely unroll a loop with a variable trip count

		xfer_size = MIN(action_xfer_size,
				(snapu32_t)MAX_NB_OF_BYTES_READ);

		rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem,
			act_reg->Data.in.type,
			InputAddress_1024 + address_xfer_offset_1024, InputAddress_512 + address_xfer_offset_512,
            buf_gmem, buf_ddrmem, xfer_size);

		rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem,
			act_reg->Data.in.type, act_reg->Data.out.type,
			OutputAddress_1024 + address_xfer_offset_1024, OutputAddress_512 + address_xfer_offset_512,
            buf_gmem, buf_ddrmem, xfer_size);

		action_xfer_size -= xfer_size;
		address_xfer_offset_1024 += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT_1024);
		address_xfer_offset_512 += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT_512);
	} // end of L0 loop

	if (rc != 0)
		ReturnCode = SNAP_RETC_FAILURE;

	act_reg->Control.Retc = ReturnCode;
	return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_1024_t *din_gmem,
		snap_membus_1024_t *dout_gmem,
		snap_membus_512_t *d_ddrmem,
		action_reg *act_reg)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512  \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

        process_action(din_gmem, dout_gmem, d_ddrmem, act_reg);
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES_512  1024 /* 64 KiB */
#define MEMORY_LINES_1024 512  /* 64 KiB */
    int rc = 0;
    unsigned int i;
    static snap_membus_1024_t  din_gmem[MEMORY_LINES_1024];
    static snap_membus_1024_t  dout_gmem[MEMORY_LINES_1024];
    static snap_membus_512_t   d_ddrmem[MEMORY_LINES_512];

    action_reg act_reg;


    memset(din_gmem,  0xA, sizeof(din_gmem));
    memset(dout_gmem, 0xB, sizeof(dout_gmem));
    memset(d_ddrmem,  0xC, sizeof(d_ddrmem));

    
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 4096;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 4096;
    act_reg.Data.out.size = 4096;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    hls_action(din_gmem, dout_gmem, d_ddrmem, &act_reg);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	    fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	    return 1;
    }
    if (memcmp((void *)((unsigned long)din_gmem + 0),
	       (void *)((unsigned long)dout_gmem + 4096), 4096) != 0) {
	    fprintf(stderr, " ==> DATA COMPARE FAILURE <==\n");
	    return 1;
    }
    else
    	printf(" ==> DATA COMPARE OK <==\n");

    return 0;
}

#endif
