/*
 * Copyright 2020 International Business Machines
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

#include <string.h>
#include "ap_int.h"
#include <unistd.h>
//#include "osnap_hls_if.h"
//#include "hls_snap_1024.H"
#include "hls_udp.h"
#include "action_test.h"

void process_frames(AXI_STREAM &din_eth, eth_settings_t eth_settings, eth_stat_t &eth_stat, snap_membus_512_t *dout_gmem, uint64_t out_frame_buffer_addr) {
	#pragma HLS DATAFLOW
	DATA_STREAM raw;
	#pragma HLS STREAM variable=raw depth=2048
	read_eth_packet(din_eth, raw, eth_settings, eth_stat);
	write_data(raw, dout_gmem, out_frame_buffer_addr);


}

void make_packet(AXI_STREAM &stream, uint64_t frame_number, uint32_t eth_packet, uint16_t *data) {

//add following pragma to parallelize make_packet and process_frames functions (mandatory for Vitis_hls)
 #pragma HLS INLINE off
	static char buff[130*64];
	RAW_JFUDP_Packet *packet = (RAW_JFUDP_Packet *)buff;

	packet->dest_mac[0] = 0xAA;
	packet->dest_mac[1] = 0xBB;
	packet->dest_mac[2] = 0xCC;
	packet->dest_mac[3] = 0xDD;
	packet->dest_mac[4] = 0xEE;
	packet->dest_mac[5] = 0xF1;
	packet->ether_type = 0x0008;
	packet->ipv4_header_h = 0x45; // Big endian in IP header!
	packet->ipv4_header_total_length = 0x4C20; // Big endian in IP header!
	packet->ipv4_header_ttl_protocol = 0x1100;
	packet->ipv4_header_dest_ip = 0x0532010A; // Big endian in IP header! 0x0A013205
	packet->framenum = frame_number;
	packet->sour_mac[5] = 0x00; // module 0
	packet->packetnum = eth_packet;
	packet->headerVersion = 4;

	for (int i = 0; i < 4096; i++) {
		packet->data[i] = data[i];
	}

	ap_axiu_for_eth packet_in;
	ap_uint<512> *obuff;
	for (int i = 0; i < 130; i++) {
		if (i == 129) packet_in.last = 1;
		else packet_in.last = 0;
		packet_in.keep = 0xFFFFFFFFFFFFFFFF;
		packet_in.user = 0; // TODO: Check 1
		obuff = (ap_uint<512> *)&(buff[i*64]);
		packet_in.data = *obuff;
		stream.write(packet_in);
	}

}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_512_t *din_gmem,
		snap_membus_512_t *dout_gmem,
		AXI_STREAM &din_eth,
		AXI_STREAM &dout_eth,
		action_reg *act_reg)
{
	uint16_t data[4096];
    int rc = 0;
	snapu64_t access_address = 0;
	//AXI_STREAM d_simu;

	for (int i = 0; i < 4096; i++) data[i] = i;
	// set code in the first 512 bytes for test check
	data[20] = 0x31; data[21] = 0x39; data[22] = 0x36; data[23]= 0x36;

	uint64_t  out_frame_buffer_addr;
	out_frame_buffer_addr = act_reg->Data.out_frame_buffer.addr >> ADDR_RIGHT_SHIFT_512;

	uint64_t bytes_written = 0;

	eth_settings_t eth_settings;
	eth_settings.fpga_mac_addr = act_reg->Data.fpga_mac_addr;
	eth_settings.fpga_ipv4_addr = act_reg->Data.fpga_ipv4_addr;
	//eth_settings.fpga_ipv4_addr = 0x0532010A;

	eth_settings.expected_packets = act_reg->Data.packets_to_read;

	eth_stat_t eth_stats;
	eth_stats.bad_packets = 0;
	eth_stats.good_packets = 0;
	eth_stats.ignored_packets = 0;


	make_packet(dout_eth, 1, 1, data); // recup data memory debug mode
	//make_packet(din_eth, 1, 1, data); // recup data memory sim test with internal loop

	process_frames(din_eth, eth_settings, eth_stats, dout_gmem, out_frame_buffer_addr);

	act_reg->Data.good_packets = eth_stats.good_packets;
	act_reg->Data.bad_packets = eth_stats.bad_packets;
	act_reg->Data.ignored_packets = eth_stats.ignored_packets;

	act_reg->Control.Retc = SNAP_RETC_SUCCESS;


	return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_512_t *din_gmem,
		snap_membus_512_t *dout_gmem,
		AXI_STREAM &din_eth,
		AXI_STREAM &dout_eth,
                volatile ap_uint<1> &eth_reset,
		action_reg *act_reg)
{
//----------------------------------------------------------------------
//---- din_gmem  is the 512b/64B bus to read data from host memory -----
//---- dout_gmem is the 512b/64B bus to write data to host memory ------
//----------------------------------------------------------------------
	// Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
		max_read_burst_length=64  max_write_burst_length=64 latency=16
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
		max_read_burst_length=64  max_write_burst_length=64 latency=16
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// Host Memory AXI Lite Master Interface - NO CHANGE BELOW
#ifdef HLS_VITIS_USED
       #pragma HLS AGGREGATE variable=act_reg
#else
       #pragma HLS DATA_PACK variable=act_reg
#endif
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

#pragma HLS INTERFACE axis register off port=din_eth
#pragma HLS INTERFACE axis register off port=dout_eth
#pragma HLS INTERFACE ap_none port=eth_reset


				if (act_reg->Data.mode == MODE_RESET)
				{
#pragma HLS PROTOCOL fixed
					int i = 0;
					eth_reset = 1;
					while (i < 32) {
						i++; ap_wait();
					}
					if (i == 32) eth_reset = 0;
			} else
	process_action(din_gmem, dout_gmem, din_eth, dout_eth, act_reg);


}

//--------------------------------------------------------------------------------------//
// All code below is for self-test/debug purpose only. This code will not be synthesize //
//--------------------------------------------------------------------------------------//
#ifdef NO_SYNTH

// From snap_tools.h - gcc doesn't like something in this file :(
static inline void __hexdump(FILE *fp, const void *buff, unsigned int size)
{
        unsigned int i;
        const uint8_t *b = (uint8_t *)buff;
        char ascii[17];
        char str[2] = { 0x0, };

        if (size == 0)
                return;

        for (i = 0; i < size; i++) {
                if ((i & 0x0f) == 0x00) {
                        fprintf(fp, " %08x:", i);
                        memset(ascii, 0, sizeof(ascii));
                }
                fprintf(fp, " %02x", b[i]);
                str[0] = isalnum(b[i]) ? b[i] : '.';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        // print trailing up to a 16 byte boundary.
        for (; i < ((size + 0xf) & ~0xf); i++) {
                fprintf(fp, "   ");
                str[0] = ' ';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        fprintf(fp, "\n");
}



int main(int argc, char *argv[]) {
	snap_membus_512_t din_gmem[1024];
	snap_membus_512_t *dout_gmem = 0;

	const  char cve_map[4096] = "0123456789 ceci est un test";
	uint64_t taille;
	taille = FRAME_BUF_SIZE*NMODULES*MODULE_COLS*MODULE_LINES*sizeof(uint16_t);
	void *out_frame_buffer = snap_malloc(16384);


	AXI_STREAM din_eth;
	AXI_STREAM dout_eth;

	action_reg action_register;
	action_register.Data.packets_to_read = 1;
	action_register.Control.flags = 1;
	action_register.Data.fpga_mac_addr = 0xAABBCCDDEEF1;
	action_register.Data.fpga_ipv4_addr = 0x0A013205; // 10.1.50.5
	action_register.Data.out_frame_buffer.addr = (uint64_t) out_frame_buffer;

	printf("Output frame buff %016llx\n",(long long)&out_frame_buffer);
    hls_action(din_gmem, dout_gmem, din_eth, dout_eth, &action_register);

    printf("Good packets %ld\n",action_register.Data.good_packets);
    printf("Bad packets %ld\n",action_register.Data.bad_packets);
    printf("Ignored packets %ld\n",action_register.Data.ignored_packets);

	ap_axiu_for_eth packet_out;

	printf("ARP out\n");

	__hexdump(stdout, (void *)out_frame_buffer,64*2);
	return 0;
}

#endif
