/*
 * Copyright 2019 Paul Scherrer Institute
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

#include "hw_action_rx100G.h"

void pack_pedeG0(packed_pedeG0_t& out, pedeG0_t in[32]) {
	for (int i = 0; i < 32; i ++) {
		for (int j = 0; j < PEDE_G0_PRECISION; j ++) out[i*PEDE_G0_PRECISION+j] = in[i][j];
	}
}

void pack_pede(packed_pedeG0_t in, ap_uint<512> &out) {
#pragma HLS PIPELINE
	pedeG0_t tmp_full[32];

	unpack_pedeG0(in, tmp_full);
	for (int i = 0; i < 32; i++) {
		pedeG1G2_t tmp1 = tmp_full[i]; // returns limited precision!
		for (int j = 0; j < 16; j++) {
			out[i*16+j] = tmp1[j];
		}
	}
}


void pack_pedeG1G2(packed_pedeG0_t in, ap_uint<256> &out1, ap_uint<256> &out2) {
#pragma HLS PIPELINE
	pedeG0_t tmp_full[32];

	unpack_pedeG0(in, tmp_full);
	for (int i = 0; i < 16; i++) {
		pedeG1G2_t tmp1 = tmp_full[i];
		pedeG1G2_t tmp2 = tmp_full[i+16];
		for (int j = 0; j < 16; j++) {
			out1[i*16+j] = tmp1[j];
			out2[i*16+j] = tmp2[j];
		}
	}
}

void unpack_pedeG0(packed_pedeG0_t in, pedeG0_t out[32]) {
#pragma HLS INLINE
	for (int i = 0; i < 32; i ++) {
		for (int j = 0; j < PEDE_G0_PRECISION; j ++) out[i][j] = in[i*PEDE_G0_PRECISION+j];
	}
}

void unpack_gainG0(ap_uint<512> in, gainG0_t outg[32]) {
	#pragma HLS INLINE
	for (int i = 0; i < 32; i ++) {
		for (int j = 0; j < 16; j ++) {
			outg[i][j] = in[i*16+j];
		}
	}
}

void unpack_pedeG0RMS(ap_uint<512> in, pedeG0RMS_t outr[32]) {
	for (int i = 0; i < 32; i ++) {
		for (int j = 0; j < 16; j ++) {
			outr[i][j] = in[i*16+j];
		}
	}
}

void unpack_gainG0(ap_uint<256> in_1, ap_uint<256> in_2, gainG0_t outg[32]) {
#pragma HLS INLINE
	#pragma HLS PIPELINE
	for (int i = 0; i < 16; i ++) {
		for (int j = 0; j < 16; j ++) {
			outg[i][j] = in_1[i*16+j];
			outg[i+16][j] = in_2[i*16+j];
		}
	}
}

void unpack_pedeG0RMS(ap_uint<256> in_1, ap_uint<256> in_2, pedeG0RMS_t outr[32]) {
#pragma HLS INLINE
#pragma HLS PIPELINE
	for (int i = 0; i < 16; i ++) {
		for (int j = 0; j < 16; j ++) {
			outr[i][j] = in_1[i*16+j];
			outr[i+16][j] = in_2[i*16+j];
		}
	}
}

void unpack_pedeG1G2(ap_uint<256> in_1, ap_uint<256> in_2, pedeG1G2_t outp[32]) {
#pragma HLS INLINE
	#pragma HLS PIPELINE
	for (int i = 0; i < 16; i ++) {
		for (int j = 0; j < 16; j ++) {
			outp[i][j] = in_1[i*16+j];
			outp[i+16][j] = in_2[i*16+j];

		}
	}
}

void unpack_pedeG1G2(ap_uint<512> in, pedeG1G2_t outp[32]) {
#pragma HLS INLINE
#pragma HLS PIPELINE
	for (int i = 0; i < 32; i ++) {
		for (int j = 0; j < 16; j ++) {
			outp[i][j] = in[i*16+j];
		}
	}
}
void unpack_gainG1G2(ap_uint<256> in_1, ap_uint<256> in_2, gainG1G2_t outg[32]) {
#pragma HLS INLINE
	#pragma HLS PIPELINE
	for (int i = 0; i < 16; i ++) {
		for (int j = 0; j < 16; j ++) {
			outg[i][j] = in_1[i*16+j];
			outg[i+16][j] = in_2[i*16+j];
		}
	}
}

void data_shuffle(ap_uint<512> &out, ap_int<16> in[32]) {
#pragma HLS INLINE
	#pragma HLS PIPELINE
	for (int i = 0; i < 512; i++) out[i] = in[i%32][i/32];

}

void data_pack(ap_uint<512> &out, ap_int<16> in[32]) {
	#pragma HLS PIPELINE
#pragma HLS INLINE
	for (int i = 0; i < 512; i++) out[i] = in[i/16][i%16];
}




