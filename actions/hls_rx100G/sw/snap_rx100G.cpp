/*
 * Copyright 2017 International Business Machines
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

#include <fstream>
#include <iostream>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <assert.h>

/*S2OC #include <snap_tools.h> */
#include <osnap_tools.h>
/*S2OC #include <libsnap.h> */
#include <libosnap.h>
#include <action_rx100G.h>
/*S2OC #include <snap_hls_if.h> */
#include <osnap_hls_if.h>

#define NFRAMES 1
#define NPACKETS

/* main program of the application for the hls_helloworld example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main()
{
	int rc = 0; // return code

	// Card parameters
	int card_no = 1;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];

	// Control register
	struct snap_job cjob;
	struct rx100G_job mjob;

	// Number of frames
	uint64_t frames = NFRAMES;

	// Time out
	unsigned long timeout = 600; //TODO: check if this can be a problem later
	struct timeval etime, stime;

	fprintf(stderr, "  prepare rx100G job of %ld bytes size\n", sizeof(mjob));

	memset(&mjob, 0, sizeof(mjob));

	uint64_t out_data_buffer_size = FRAME_BUF_SIZE * NPIXEL * 2; // can store FRAME_BUF_SIZE frames
	uint64_t out_status_buffer_size = frames*NMODULES*128/8+64; // can store 1 bit per each ETH packet expected
	uint64_t in_parameters_array_size = (6 * NPIXEL * 2); // each entry to in_parameters_array is 2 bytes and there are 6 constants per pixel
	uint64_t out_jf_header_buffer_size = frames*NMODULES*32;

	// Arrays are allocated with mmap for the higest possible performance. Output is page aligned, so it will be also 64b aligned.

	void *out_data_buffer  = mmap (NULL, out_data_buffer_size, PROT_READ | PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) ;
	void *out_status_buffer = mmap (NULL, out_status_buffer_size, PROT_READ | PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
	void *in_parameters_array = mmap (NULL, in_parameters_array_size, PROT_READ | PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
	void *out_jf_header_buffer = mmap (NULL, out_jf_header_buffer_size, PROT_READ | PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);

	if ((out_data_buffer == NULL) || (out_status_buffer == NULL) ||
			(in_parameters_array == NULL) || (out_jf_header_buffer == NULL)) {
		std::cout << "Memory allocation error" << std::endl;
		exit(EXIT_FAILURE);
	}

	// Fill output arrays with zeros
	memset(out_data_buffer, 0x0, out_data_buffer_size);
	memset(out_status_buffer, 0x0, out_status_buffer_size);
	memset(in_parameters_array, 0x0, in_parameters_array_size);
	memset(out_jf_header_buffer, 0x0, out_jf_header_buffer_size);

	mjob.expected_frames = frames;
	mjob.pedestalG0_frames = 0;
	mjob.mode = MODE_RAW;
	mjob.fpga_mac_addr = 0xAABBCCDDEEF1;   // AA:BB:CC:DD:EE:F1
	mjob.fpga_ipv4_addr = 0x0A013205;      // 10.1.50.5

	mjob.in_gain_pedestal_data_addr = (uint64_t) in_parameters_array;
	mjob.out_frame_buffer_addr = (uint64_t) out_data_buffer;
	mjob.out_frame_status_addr = (uint64_t) out_status_buffer;
	mjob.out_jf_packet_headers_addr = (uint64_t) out_jf_header_buffer;

	int exit_code = EXIT_SUCCESS;

	// default is interrupt mode enabled (vs polling)
	snap_action_flag_t action_irq = (snap_action_flag_t) (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	// Allocate the card that will be used
/*S2OC	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no); */
        if(card_no == 0)
                snprintf(device, sizeof(device)-1, "IBM,oc-snap");
        else
                snprintf(device, sizeof(device)-1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", card_no);

	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
			SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
				card_no, strerror(errno));
		exit(EXIT_FAILURE);
	}

	// Attach the action that will be used on the allocated card
/*S2OC	action = snap_attach_action(card, RX100G_ACTION_TYPE, action_irq, 60); */
	action = snap_attach_action(card, ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
				card_no, strerror(errno));
		snap_card_free(card);
		exit(EXIT_FAILURE);
	}

	// Fill the stucture of data exchanged with the action
	snap_job_set(&cjob, &mjob, sizeof(mjob), NULL, 0);

	// Call the action will:
	//    write all the registers to the action (MMIO) 
	//  + start the action 
	//  + wait for completion
	//  + read all the registers from the action (MMIO) 
	rc = snap_action_sync_execute_job(action, &cjob, timeout);

	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
				strerror(errno));
		// snap_detach_action(action);
		//snap_card_free(card);
		// exit(EXIT_FAILURE);
	}

	std::ofstream data_file("output_data.dat",std::ios::out | std::ios::binary);
	data_file.write((char *) out_data_buffer, NFRAMES * NPIXEL * 2);
	data_file.close();

	std::ofstream header_file("output_header.dat",std::ios::out | std::ios::binary);
	header_file.write((char *) out_jf_header_buffer, out_jf_header_buffer_size);
	header_file.close();

	std::ofstream status_file("output_status.dat",std::ios::out | std::ios::binary);
	status_file.write((char *) out_status_buffer, out_status_buffer_size);
	status_file.close();

	std::ofstream calibration_file("output_calib.dat",std::ios::out | std::ios::binary);
	calibration_file.write((char *) in_parameters_array, in_parameters_array_size);
	calibration_file.close();

	std::cout << std::endl;
	std::cout << "General statistics " << std::endl;
	std::cout << "================== " << std::endl << std::endl;
	online_statistics_t *online_statistics = (online_statistics_t *) out_status_buffer;
	std::cout << "Good Ethernet packets: " << online_statistics->good_packets << std::endl ;
	std::cout << "Err  Ethernet packets: " << online_statistics->err_packets << std::endl ;
	for (int i = 0; i < NMODULES; i++)
		std::cout << "Head module " << i << ": " << online_statistics->head[i] << std::endl ;
	std::cout << "Trigger position     : " << online_statistics->trigger_position << std::endl;

	std::cout << std::endl;

	// Detach action + disallocate the card
	snap_detach_action(action);
	snap_card_free(card);


	// Memory deallocation
	munmap(out_data_buffer, out_data_buffer_size);
	munmap(out_status_buffer, out_status_buffer_size);
	munmap(in_parameters_array, in_parameters_array_size);
	munmap(out_jf_header_buffer, out_jf_header_buffer_size);

	exit(exit_code);
}
