/*
 * Copyright 2020 Paul Scherrer Institute
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

#ifndef JFAPP_H_
#define JFAPP_H_

#include <stdlib.h>
#include <string>
#include <pthread.h>
#include <lz4.h>
#include <infiniband/verbs.h>

// Contains variables shared with FPGA
#include "action_rx100G.h"

#define COMPOSED_IMAGE_SIZE (514L*1030L*NMODULES)

#define TCPIP_CONN_MAGIC_NUMBER 123434L
#define TCPIP_DONE_MAGIC_NUMBER  56789L

// Number of images per single CUDA run
// This number is 1/2 if 32-bit pixel depth is used
#define NIMAGES_PER_STREAM 320L

// Number of FPGA boards in total for the whole setup
#define NCARDS 2

#define WVL_1A_IN_KEV           12.39854
#define SENSOR_THICKNESS_IN_UM 320.0
#define PIXEL_SIZE_IN_UM        75.0
#define PIXEL_SIZE_IN_MM       (PIXEL_SIZE_IN_UM/1000.0)
#define DETECTOR_NAME          "JF4M"
#define SOURCE_NAME_SHORT      "SLS"
#define SOURCE_NAME            "Swiss Light Source"
#define INSTRUMENT_NAME        "X06DA"
#define INSTRUMENT_NAME_SHORT  "PXIII"
#define SENSOR_MATERIAL        "Si"

#define HORIZONTAL_GAP_PIXELS  36
#define VERTICAL_GAP_PIXELS     8

// Settings exchanged between writer and receiver
struct experiment_settings_t {
    uint8_t  conversion_mode;

    uint64_t nframes_to_collect;
    uint64_t nimages_to_write;
    uint64_t nimages_to_write_per_trigger;
    uint16_t ntrigger;

    uint32_t pedestalG0_frames;
    uint32_t pedestalG1_frames;
    uint32_t pedestalG2_frames;
    uint32_t summation;

    bool     jf_full_speed;
    double   count_time;            // in s Beamline
    double   frame_time;            // in s Beamline
    double   frame_time_detector;   // in s Detector
    double   count_time_detector;   // in s Detector
    size_t   pixel_depth;           // in byte !! code is only safe for pixe depth of 2 and 4 !!

    double   energy_in_keV;         // in keV
    double   beam_x;                // in pixel
    double   beam_y;                // in pixel
    double   detector_distance;     // in mm
    double   transmission;          // 1.0 = full transmission
    double   total_flux;            // in e/s
    double   omega_start;           // in degrees
    double   omega_angle_per_image; // in degrees
    double   beam_size_x;           // in micron
    double   beam_size_y;           // in micron
    double   beamline_delay;        // in seconds delay between arm succeed and trigger opening (maximal)
    double   shutter_delay;         // in seconds delay between trigger and shutter
    double   sample_temperature;    // in K

    bool     enable_spot_finding;          // true = spot finding is ON
    bool     connect_spots_between_frames; // true = rotation measurement, false = raster, jet
    double   strong_pixel;                 // STRONG_PIXEL in XDS
    uint16_t max_spot_depth;               // Maximum images per spot
    uint16_t min_pixels_per_spot;          // Minimum pixels per spot
};

struct receiver_output_t {
    uint64_t frame_when_trigger_observed;
    uint64_t packets_collected_ok;
};

// Settings for IB connection
struct ib_comm_settings_t {
    uint16_t dlid;
    uint32_t qp_num;
    uint32_t rq_psn;
    uint32_t frame_buffer_rkey;
    uint64_t frame_buffer_remote_addr;
};

// IB context
struct ib_settings_t {
    // IB data structures
    ibv_mr *buffer_mr;
    ibv_context *context;
    ibv_pd *pd;
    ibv_cq *cq;
    ibv_qp *qp;
    ibv_port_attr port_attr;
};

// Definition of Bragg spot
struct spot_t {
    float x,y,z;      // Coordinates in "data" array (not exactly detector configuration)
    float d;          // Resolution [in Angstrom]
    float q[3];       // Reciprocal vector for "node", see Gevorkov et al. 2019
    float photons;    // total photon count
    int16_t min_col, max_col, min_line, max_line; // Limits of the spot in X and Y directions
    uint32_t first_frame, last_frame; // Limits of the spot in time direction
};

// IB Verbs function wrappers
int setup_ibverbs(ib_settings_t &settings, std::string ib_device_name, size_t send_queue_size, size_t receive_queue_size);
int switch_to_rtr(ib_settings_t &settings, uint32_t rq_psn, uint16_t dlid, uint32_t dest_qp_num);
int switch_to_rts(ib_settings_t &settings, uint32_t sq_psn);
int switch_to_init(ib_settings_t &settings);
int switch_to_reset(ib_settings_t &settings);
int close_ibverbs(ib_settings_t &settings);

#endif // JFAPP_H_
