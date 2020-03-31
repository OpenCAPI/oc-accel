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
#include "hw_action_hbm_memcopy_1024.H"

//======================== convert buffers format ===================================//
//Convert a 1024 bits buffer to a 256 bits buffer
void get_buffer_256( snap_membus_1024_t *buffer_1024, snap_membus_256_t *buffer_256, int size_in_words_1024)
{
        ap_int<MEMDW_256> mask_full = -1;
        snap_membus_1024_t mask_256 = snap_membus_256_t(mask_full);

        wb_gbuf2dbuf_loop: 
        for (int k=0; k<size_in_words_1024; k++) {
               for (int j=0; j<MEMDW_1024/MEMDW_256; j++) {
#pragma HLS PIPELINE
                  buffer_256[k*MEMDW_1024/MEMDW_256+j] = (snap_membus_256_t)((buffer_1024[k] >> j*MEMDW_256) & mask_256);
               }
        }
	return;
}

//Convert a 256 bits buffer to a 1024 bits buffer
void get_buffer_1024( snap_membus_256_t *buffer_256, snap_membus_1024_t *buffer_1024, int size_in_words_1024)
{
        snap_membus_1024_t data_entry_1024 = 0;
	
        wb_dbuf2gbuf_loop: 
        for (int k=0; k<size_in_words_1024; k++) {
               for (int j=0; j<MEMDW_1024/MEMDW_256; j++) {
#pragma HLS PIPELINE
                  data_entry_1024 |= ((snap_membus_1024_t)(buffer_256[k*MEMDW_1024/MEMDW_256+j])) << j*MEMDW_256;
               }
               buffer_1024[k] = data_entry_1024;
               data_entry_1024 = 0;
        }
	return;
}


// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_1024_t *dout_gmem,
				 snap_membus_256_t *d_hbm_p0,
				 snap_membus_256_t *d_hbm_p1,
				 snap_membus_256_t *d_hbm_p2,
				 snap_membus_256_t *d_hbm_p3,
				 snap_membus_256_t *d_hbm_p4,
				 snap_membus_256_t *d_hbm_p5,
				 snap_membus_256_t *d_hbm_p6,
				 snap_membus_256_t *d_hbm_p7,
				 snap_membus_256_t *d_hbm_p8,
				 snap_membus_256_t *d_hbm_p9,
				 snap_membus_256_t *d_hbm_p10,
				 snap_membus_256_t *d_hbm_p11,
				 snapu16_t memory_in_type,
				 snapu16_t memory_out_type,
				 snapu64_t output_address_1024,
				 snapu64_t output_address_256,
				 snap_membus_1024_t *buf_gmem_1024,
				 snap_membus_256_t *buf_LCLmem_256,
				 snapu64_t size_in_bytes_to_transfer)
{
        short rc;
        static snap_membus_256_t  buf_gmem_256[MAX_NB_OF_WORDS_READ_256];
        static snap_membus_1024_t  buf_LCLmem_1024[MAX_NB_OF_WORDS_READ_1024];

        int size_in_words_1024;
        if(size_in_bytes_to_transfer %BPERDW_1024 == 0)
           size_in_words_1024 = size_in_bytes_to_transfer/BPERDW_1024;
        else
           size_in_words_1024 = (size_in_bytes_to_transfer/BPERDW_1024) + 1;

//========================data from buf_gmem======================================//
        if (memory_in_type == SNAP_ADDRTYPE_HOST_DRAM) {

           // From Host to Host => same 1024 bits data width
           if(memory_out_type == SNAP_ADDRTYPE_HOST_DRAM) {
               memcpy((snap_membus_1024_t  *) (dout_gmem + output_address_1024),
                   buf_gmem_1024, size_in_bytes_to_transfer);
       	       rc = 0;
           }

           // From Host to LCL_mem => data width conversion from 1024 to 256 bits
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P0) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p0 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P1) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p1 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P2) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p2 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P3) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p3 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P4) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p4 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P5) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p5 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P6) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p6 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P7) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p7 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P8) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p8 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P9) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p9 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P10) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p10 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P11) {
               get_buffer_256( buf_gmem_1024, buf_gmem_256, size_in_words_1024);
               memcpy((snap_membus_256_t  *) (d_hbm_p11 + output_address_256),
                    buf_gmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_UNUSED)
               rc = 0;
           else
               rc = 1;
        }
//=========================data from buffer_LCLmem=====================================//
        else if ((memory_in_type == SNAP_ADDRTYPE_HBM_P0) || (memory_in_type == SNAP_ADDRTYPE_HBM_P1)) {

           // From LCL_mem to Host=> data width conversion from 256 to 1024 bits
           if(memory_out_type == SNAP_ADDRTYPE_HOST_DRAM) {
               get_buffer_1024( buf_LCLmem_256, buf_LCLmem_1024, size_in_words_1024);
               memcpy((snap_membus_1024_t  *) (dout_gmem + output_address_1024),
                   buf_LCLmem_1024, size_in_bytes_to_transfer);
               rc = 0;
           }

           // From LCL_mem to LCL_mem => same 256 bits data width
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P0) {
               memcpy((snap_membus_256_t  *) (d_hbm_p0 + output_address_256),
                   buf_LCLmem_256, size_in_bytes_to_transfer);
               rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P1) {
               memcpy((snap_membus_256_t  *) (d_hbm_p1 + output_address_256),
                   buf_LCLmem_256, size_in_bytes_to_transfer);
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
              memcpy((snap_membus_1024_t  *) (dout_gmem + output_address_1024),
                       buf_gmem_1024, size_in_bytes_to_transfer);
       	      rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P0) {
              memcpy((snap_membus_256_t  *) (d_hbm_p0 + output_address_256),
                       buf_LCLmem_256, size_in_bytes_to_transfer);
              rc = 0;
           }
           else if(memory_out_type == SNAP_ADDRTYPE_HBM_P1) {
              memcpy((snap_membus_256_t  *) (d_hbm_p1 + output_address_256),
                       buf_LCLmem_256, size_in_bytes_to_transfer);
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
				  snap_membus_256_t *d_hbm_p0,
				  snap_membus_256_t *d_hbm_p1,
				  snap_membus_256_t *d_hbm_p2,
				  snap_membus_256_t *d_hbm_p3,
				  snap_membus_256_t *d_hbm_p4,
				  snap_membus_256_t *d_hbm_p5,
				  snap_membus_256_t *d_hbm_p6,
				  snap_membus_256_t *d_hbm_p7,
				  snap_membus_256_t *d_hbm_p8,
				  snap_membus_256_t *d_hbm_p9,
				  snap_membus_256_t *d_hbm_p10,
				  snap_membus_256_t *d_hbm_p11,
				  snapu16_t memory_type,
				  snapu64_t input_address_1024,
				  snapu64_t input_address_256,
				  snap_membus_1024_t *buf_gmem_1024,
				  snap_membus_256_t *buf_LCLmem_256,
				  snapu64_t size_in_bytes_to_transfer)
{
	short rc;
        int i;

        switch (memory_type) {

        case SNAP_ADDRTYPE_HOST_DRAM:
                memcpy(buf_gmem_1024, (snap_membus_1024_t  *) (din_gmem + input_address_1024),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P0:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p0 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P1:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p1 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P2:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p2 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P3:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p3 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P4:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p4 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P5:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p5 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P6:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p6 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P7:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p7 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P8:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p8 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P9:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p9 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P10:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p10 + input_address_256),
                     size_in_bytes_to_transfer);
       		rc =  0;
                break;
        case SNAP_ADDRTYPE_HBM_P11:
                memcpy(buf_LCLmem_256, (snap_membus_256_t  *) (d_hbm_p11 + input_address_256),
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
                           snap_membus_256_t *d_hbm_p0,
                           snap_membus_256_t *d_hbm_p1,
                           snap_membus_256_t *d_hbm_p2,
                           snap_membus_256_t *d_hbm_p3,
                           snap_membus_256_t *d_hbm_p4,
                           snap_membus_256_t *d_hbm_p5,
                           snap_membus_256_t *d_hbm_p6,
                           snap_membus_256_t *d_hbm_p7,
                           snap_membus_256_t *d_hbm_p8,
                           snap_membus_256_t *d_hbm_p9,
                           snap_membus_256_t *d_hbm_p10,
                           snap_membus_256_t *d_hbm_p11,
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
	snapu64_t InputAddress_256;
	snapu64_t OutputAddress_256;
	snapu64_t address_xfer_offset_256;
	snap_membus_1024_t  buf_gmem_1024[MAX_NB_OF_WORDS_READ_1024];
	snap_membus_256_t   buf_LCLmem_256[MAX_NB_OF_WORDS_READ_256];
	// if 4096 bytes max => 64 words

	// byte address received need to be aligned with port width
	InputAddress_1024 = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT_1024;
	OutputAddress_1024 = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT_1024;
	InputAddress_256 = (act_reg->Data.in.addr)    >> ADDR_RIGHT_SHIFT_256;
	OutputAddress_256 = (act_reg->Data.out.addr)  >> ADDR_RIGHT_SHIFT_256;

	address_xfer_offset_256 = 0x0;
	address_xfer_offset_1024 = 0x0;
	// testing sizes to prevent from writing out of bounds
	action_xfer_size = MIN(act_reg->Data.in.size,
			       act_reg->Data.out.size);

	// test done just on HBM_P0 - should be extended if there is any risk
	if (act_reg->Data.in.type == SNAP_ADDRTYPE_HBM_P0 and
	    act_reg->Data.in.size > LCL_MEM_MAX_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }
	if (act_reg->Data.out.type == SNAP_ADDRTYPE_HBM_P0 and
	    act_reg->Data.out.size > LCL_MEM_MAX_SIZE) {
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

		rc |= read_burst_of_data_from_mem(din_gmem, d_hbm_p0, d_hbm_p1,
		        d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5,
		        d_hbm_p6, d_hbm_p7, d_hbm_p8, d_hbm_p9,
		        d_hbm_p10, d_hbm_p11,
			act_reg->Data.in.type,
			InputAddress_1024 + address_xfer_offset_1024, 
                        InputAddress_256 + address_xfer_offset_256,
                        buf_gmem_1024, buf_LCLmem_256, xfer_size);

		rc |= write_burst_of_data_to_mem(dout_gmem, d_hbm_p0, d_hbm_p1,
		        d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5,
		        d_hbm_p6, d_hbm_p7, d_hbm_p8, d_hbm_p9,
		        d_hbm_p10, d_hbm_p11,
			act_reg->Data.in.type, act_reg->Data.out.type,
			OutputAddress_1024 + address_xfer_offset_1024, 
                        OutputAddress_256 + address_xfer_offset_256,
                        buf_gmem_1024, buf_LCLmem_256, xfer_size);

		action_xfer_size -= xfer_size;
		address_xfer_offset_1024 += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT_1024);
		address_xfer_offset_256 += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT_256);
	} // end of L0 loop

	if (rc != 0)
		ReturnCode = SNAP_RETC_FAILURE;

	act_reg->Control.Retc = ReturnCode;
	return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
// snap_membus_1024_t and snap_membus_256_t are defined in actions/include/hls_snap_1024.H
void hls_action(snap_membus_1024_t *din_gmem,
		snap_membus_1024_t *dout_gmem,
		snap_membus_256_t *d_hbm_p0,
		snap_membus_256_t *d_hbm_p1,
		snap_membus_256_t *d_hbm_p2,
		snap_membus_256_t *d_hbm_p3,
		snap_membus_256_t *d_hbm_p4,
		snap_membus_256_t *d_hbm_p5,
		snap_membus_256_t *d_hbm_p6,
		snap_membus_256_t *d_hbm_p7,
		snap_membus_256_t *d_hbm_p8,
		snap_membus_256_t *d_hbm_p9,
		snap_membus_256_t *d_hbm_p10,
		snap_membus_256_t *d_hbm_p11,
		action_reg *act_reg)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512  \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// HBM interfaces
#pragma HLS INTERFACE m_axi port=d_hbm_p0 bundle=card_hbm_p0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p1 bundle=card_hbm_p1 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p2 bundle=card_hbm_p2 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p3 bundle=card_hbm_p3 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p4 bundle=card_hbm_p4 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p5 bundle=card_hbm_p5 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p6 bundle=card_hbm_p6 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p7 bundle=card_hbm_p7 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p8 bundle=card_hbm_p8 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p9 bundle=card_hbm_p9 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p10 bundle=card_hbm_p10 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

#pragma HLS INTERFACE m_axi port=d_hbm_p11 bundle=card_hbm_p11 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 


	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

        process_action(din_gmem, dout_gmem, d_hbm_p0, d_hbm_p1,
                       d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5, 
                       d_hbm_p6, d_hbm_p7, d_hbm_p8, d_hbm_p9, 
                       d_hbm_p10, d_hbm_p11, 
                      act_reg);
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES_256  2048 /* 64 KiB */
#define MEMORY_LINES_1024 512  /* 64 KiB */
    int rc = 0;
    unsigned int i;
    static snap_membus_1024_t  din_gmem[MEMORY_LINES_1024];
    static snap_membus_1024_t  dout_gmem[MEMORY_LINES_1024];
    static snap_membus_256_t   d_hbm_p0[MEMORY_LINES_256];
    static snap_membus_256_t   d_hbm_p1[MEMORY_LINES_256];

    action_reg act_reg;


    memset(din_gmem,  0xA, sizeof(din_gmem));
    memset(dout_gmem, 0xB, sizeof(dout_gmem));
    memset(d_hbm_p0,  0xC, sizeof(d_hbm_p0));
    memset(d_hbm_p1,  0xC, sizeof(d_hbm_p1));

    
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 4096;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 4096;
    act_reg.Data.out.size = 4096;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    hls_action(din_gmem, dout_gmem, d_hbm_p0, d_hbm_p1, &act_reg);
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
