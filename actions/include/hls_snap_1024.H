#ifndef __HLS_SNAP_H__
#define __HLS_SNAP_H__

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

#include <stdint.h>
#include <string.h>
#include <ap_int.h>
#include <hls_stream.h>

/*
 * Hardware implementation is lacking some libc functions. So let us
 * replace those.
 */
#ifndef ULONG_MAX
#  define ULONG_MAX 0xFFFFFFFFUL /* gcc compiler but not HLS compiler */
#endif
#ifndef NULL
#  define NULL 0                 /* gcc compiler but not HLS compiler */
#endif

#if !defined(NO_SYNTH)
#  define printf(fmt, args...)
#  define fprintf(file, fmt, args...)
#  define __unused
#endif

#ifndef MIN
#  define MIN(x, y) ((x) < (y) ? (x) : (y))
#endif

#ifndef ARRAY_SIZE
#  define ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))
#endif

/* General memory Data Width is set as a parameter*/
#define MEMDW_512 512              // 512 or 128 // Bus width in bits for Host memory
#define BPERDW_512 (MEMDW_512/8)   // Bytes per Data Word    if MEMDW=512 => BPERDW = 64
#define WPERDW_512 (64/BPERDW_512) // Number of words per DW if MEMDW=512 => WPERDW =  1 ?????
#define ADDR_RIGHT_SHIFT_512 6
#define SNAP_HLS_JOBSIZE 108
/* 256-bit host AXI data width*/
#define MEMDW_256 256             // 256-bit Bus width for Host memory
#define BPERDW_256 (MEMDW_256/8)  // Bytes per Data Word
#define WPERDW_256 (BPERDW_256/4) // Number of words per DW
#define ADDR_RIGHT_SHIFT_256 5
/* 1024-bit host AXI data width*/
#define MEMDW_1024 1024             // 1024-bit Bus width for Host memory
#define BPERDW_1024 (MEMDW_1024/8)  // Bytes per Data Word
#define WPERDW_1024 (BPERDW_1024/4) // Number of words per DW
#define ADDR_RIGHT_SHIFT_1024 7

typedef ap_uint<MEMDW_256>  snap_membus_256_t;   /* 256-bit ddr memory access */
typedef ap_uint<MEMDW_512>  snap_membus_512_t;   /* 512-bit ddr memory access */
typedef ap_uint<MEMDW_1024> snap_membus_1024_t;  /* 1024-bit snap memory access */
typedef ap_uint<MEMDW_256>  snap_HBMbus_t;       /* 256-bit HBM memory access */
typedef ap_uint<64> snapu64_t;
typedef ap_uint<32> snapu32_t;
typedef ap_uint<16> snapu16_t;
typedef ap_uint<8> snapu8_t;
typedef ap_uint<1> snap_bool_t;

typedef struct {
        snapu8_t sat; // short action type
        snapu8_t flags;
        snapu16_t seq;
        snapu32_t Retc;
        snapu64_t Reserved; // Priv_data
} CONTROL;


#endif  /* __HLS_SNAP_H__ */
