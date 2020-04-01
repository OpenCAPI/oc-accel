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

void filter_packets(DATA_STREAM &in, DATA_STREAM &out) {
	data_packet_t packet_in, packet_out;

	in.read(packet_in);
	ap_uint<8> axis_packet = 0;

	while (packet_in.exit == 0) {
		if (packet_in.axis_packet == axis_packet) {
			// packet_in is what is expected
			packet_out = packet_in;
			out.write(packet_out);
			axis_packet = (axis_packet + 1) % 128;
		} else {
			packet_out.axis_user = 1; // Mark the packet as a wrong one
			for (int i = axis_packet; i < 128; i++) {
				packet_out.axis_packet = i;
				out.write(packet_out);
			}
			packet_out = packet_in;
			out.write(packet_out);
			axis_packet = 1;
		} in.read(packet_in);
	}
	packet_out.axis_user = 1;
	for (int i = 0; i < (128 - axis_packet) % 128; i++) {
		out.write(packet_out);
	}
	out.write(packet_in);
}
