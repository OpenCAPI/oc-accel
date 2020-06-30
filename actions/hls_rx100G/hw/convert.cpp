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

#define URAM_PARITITION 4
#define HBM_BURST_G1G2 4

void update_pedestal(ap_uint<512> data_in, ap_uint<18*32> &data_out, packed_pedeG0_t &packed_pede, ap_uint<1> accumulate, ap_uint<8> mode, ap_uint<32> &mask) {
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off
	// Load current pedestal
	pedeG0_t pedestal[32];
        ap_uint<32> tmp_mask = 0;
	unpack_pedeG0(packed_pede, pedestal);
	for (int j = 0; j < 32; j++) {
		ap_uint<2> gain = data_in(16 * j + 15,16 * j + 14);
		ap_uint<14> adu = data_in(16 * j + 13,16 * j);
		ap_fixed<18,16> val_diff = adu - pedestal[j];

		// Correct pedestal based on gain
		if (((gain == 0x0) && (mode == MODE_PEDEG0)) ||
				((gain == 0x1) && (mode == MODE_PEDEG1)) ||
				((gain == 0x3) && (mode == MODE_PEDEG2))) {

			if (accumulate)
				pedestal[j] += ((pedeG0_t) adu) / PEDESTAL_WINDOW_SIZE;
			else
				pedestal[j] += val_diff / PEDESTAL_WINDOW_SIZE;
		}
                if (((gain != 0x0) && (mode == MODE_PEDEG0)) ||
                    ((gain != 0x1) && (mode == MODE_PEDEG1)) ||
                    ((gain != 0x3) && (mode == MODE_PEDEG2))) {
                        tmp_mask[j] = 1;       
                } else tmp_mask[j] = 0;
		// Calculate G0 pedestal correction - anyway - it will be overwritten on next steps

		for (int k = 0; k < 18; k++)
			data_out[j * 18 + k] = val_diff[k];

	}
	// Save pedestal
	pack_pedeG0(packed_pede, pedestal);

        // Save mask
        mask |= tmp_mask;
}


void pedestalG0(DATA_STREAM &in, DATA_STREAM &out, conversion_settings_t conversion_settings) {
	data_packet_t packet_in, packet_out;

	in >> packet_in;
	while (packet_in.exit == 0) {
		while ((packet_in.exit == 0) && (packet_in.axis_packet % URAM_PARITITION == 0)) {

			ap_uint<8> mode = conversion_settings.conversion_mode;
			ap_uint<28> frame_number = packet_in.frame_number;
			if ((mode == MODE_CONV) && (packet_in.pedestal == 1)) mode = MODE_PEDEG0;

			ap_uint<1> accumulate_pede;
			if (frame_number < PEDESTAL_WINDOW_SIZE) accumulate_pede = 1;
			else accumulate_pede = 0;
#pragma HLS PIPELINE II=4
			size_t offset = packet_in.module * 128 * 128 + 128 * packet_in.eth_packet + packet_in.axis_packet;
			for (int i = 0; i < URAM_PARITITION; i++) {
				// Copy old packet
				packet_out = packet_in;

				update_pedestal(packet_in.data, packet_out.conv_data,packed_pedeG0[offset+i], accumulate_pede, mode, pixel_mask[offset+i]);
				// Send packet out (if it is going to be saved)
                                if (packet_in.save) out << packet_out;
				in >> packet_in;
			}
		}
		while ((packet_in.exit == 0) && (packet_in.axis_packet % URAM_PARITITION != 0)) in >> packet_in;
	}
	out << packet_in;
}

void convert(ap_uint<512> data_in, ap_uint<512> &data_out,
		ap_uint<18*32> after_pedeG0,
		ap_uint<256> packed_gainG0_1, ap_uint<256> packed_gainG0_2,
		ap_uint<256> packed_gainG1_1, ap_uint<256> packed_gainG1_2,
		ap_uint<256> packed_gainG2_1, ap_uint<256> packed_gainG2_2,
		ap_uint<256> packed_pedeG1_1, ap_uint<256> packed_pedeG1_2,
		ap_uint<256> packed_pedeG2_1, ap_uint<256> packed_pedeG2_2,
		ap_uint<2> output_mode)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
	const ap_fixed<18,16, SC_RND_CONV> half = 0.5f;

	ap_uint<16> in_val[32];
	ap_int<16> out_val[32];
	Loop0: for (int i = 0; i < 512; i++) in_val[i/16][i%16] = data_in[i];

	gainG0_t    gainG0[32];
	pedeG1G2_t  pedeG1[32];
	pedeG1G2_t  pedeG2[32];
	gainG1G2_t  gainG1[32];
	gainG1G2_t  gainG2[32];

	unpack_gainG0  (packed_gainG0_1, packed_gainG0_2, gainG0);
	unpack_pedeG1G2(packed_pedeG1_1, packed_pedeG1_2, pedeG1);
	unpack_pedeG1G2(packed_pedeG2_1, packed_pedeG2_2, pedeG2);
	unpack_gainG1G2(packed_gainG1_1, packed_gainG1_2, gainG1);
	unpack_gainG1G2(packed_gainG2_1, packed_gainG2_2, gainG2);

	Convert: for (int i = 0; i < 32; i++) {
		if (in_val[i] == 0xc000) out_val[i] = 32766; // can saturate G2 - overload
		else if (in_val[i] == 0xffff) out_val[i] = -32763; //error
		else if (in_val[i] == 0x4000) out_val[i] = -32764; //cannot saturate G1 - error
		else {

			ap_fixed<18,16, AP_RND_CONV> val_diff;
			ap_fixed<18,16, AP_RND_CONV> val_result = 0;
			ap_uint<2> gain = in_val[i] >>14;
			ap_uint<14> adu = in_val[i]; // take first two bits
			switch (gain) {
			case 0: {
				for (int k = 0; k < 18; k++)
							val_diff[k] = after_pedeG0[i * 18 + k];
				val_result = val_diff * (gainG0[i] / 512);
				//out_val[i] = val_result;
				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;
				break;
			}
			case 1: {
				val_diff     = pedeG1[i] - adu;
				val_result   =  val_diff * gainG1[i];
				//out_val[i] = val_result;
				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;
				break;
			}
			case 2:
				out_val[i] = -32762; // invalid gain
				break;
			case 3: {
				val_diff     = pedeG2[i] - adu;
				val_result   = val_diff * gainG2[i];
				//out_val[i] = val_result;
				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;
				break;
			}
			}
		}
	}
	switch (output_mode) {
	case OUTPUT_CONV:
		data_pack(data_out, out_val);
		break;
//	case OUTPUT_CONV_BSHUF:
//		data_shuffle(data_out, out_val);
//		break;
	default:
// RAW + all pedestal modes return raw data to host memory
		data_out = data_in;
		break;
	}
}

void apply_gain_correction(DATA_STREAM &in, DATA_STREAM &out,
		rx100g_hbm_t *d_hbm_p0, rx100g_hbm_t *d_hbm_p1,
		rx100g_hbm_t *d_hbm_p2, rx100g_hbm_t *d_hbm_p3,
		rx100g_hbm_t *d_hbm_p4, rx100g_hbm_t *d_hbm_p5,
		rx100g_hbm_t *d_hbm_p6, rx100g_hbm_t *d_hbm_p7,
		rx100g_hbm_t *d_hbm_p8, rx100g_hbm_t *d_hbm_p9,
	    ap_uint<2> output_mode) {
	data_packet_t packet_in;
	in >> packet_in;
	while (packet_in.exit == 0) {
		while ((packet_in.exit == 0) && (packet_in.axis_packet % HBM_BURST_G1G2 == 0)) {
#pragma HLS PIPELINE II=4
			size_t offset = packet_in.module * 128 * 128 + 128 * packet_in.eth_packet + packet_in.axis_packet;

			ap_uint<256> packed_gainG0_1[HBM_BURST_G1G2], packed_gainG0_2[HBM_BURST_G1G2];
			ap_uint<256> packed_gainG1_1[HBM_BURST_G1G2], packed_gainG1_2[HBM_BURST_G1G2];
			ap_uint<256> packed_gainG2_1[HBM_BURST_G1G2], packed_gainG2_2[HBM_BURST_G1G2];
			ap_uint<256> packed_pedeG1_1[HBM_BURST_G1G2], packed_pedeG1_2[HBM_BURST_G1G2];
			ap_uint<256> packed_pedeG2_1[HBM_BURST_G1G2], packed_pedeG2_2[HBM_BURST_G1G2];

			memcpy(packed_gainG0_1,d_hbm_p0+offset, HBM_BURST_G1G2*32);
			memcpy(packed_gainG0_2,d_hbm_p1+offset, HBM_BURST_G1G2*32);
			memcpy(packed_gainG1_1,d_hbm_p2+offset, HBM_BURST_G1G2*32);
			memcpy(packed_gainG1_2,d_hbm_p3+offset, HBM_BURST_G1G2*32);
			memcpy(packed_gainG2_1,d_hbm_p4+offset, HBM_BURST_G1G2*32);
			memcpy(packed_gainG2_2,d_hbm_p5+offset, HBM_BURST_G1G2*32);
			memcpy(packed_pedeG1_1,d_hbm_p6+offset, HBM_BURST_G1G2*32);
			memcpy(packed_pedeG1_2,d_hbm_p7+offset, HBM_BURST_G1G2*32);
			memcpy(packed_pedeG2_1,d_hbm_p8+offset, HBM_BURST_G1G2*32);
			memcpy(packed_pedeG2_2,d_hbm_p9+offset, HBM_BURST_G1G2*32);

			for (int i = 0; i < HBM_BURST_G1G2; i ++) {
				data_packet_t packet_out = packet_in;
				ap_uint<512> tmp_out;
				convert(packet_in.data, packet_out.data, packet_in.conv_data,
						packed_gainG0_1[i],packed_gainG0_2[i],
						packed_gainG1_1[i],packed_gainG1_2[i],
						packed_gainG2_1[i],packed_gainG2_2[i],
						packed_pedeG1_1[i],packed_pedeG1_2[i],
						packed_pedeG2_1[i],packed_pedeG2_2[i],
						output_mode);
				out << packet_out;
				in >> packet_in;
			}
		}
		while ((packet_in.exit == 0) && (packet_in.axis_packet % HBM_BURST_G1G2 != 0)) in >> packet_in;
	}
	out << packet_in;
}
