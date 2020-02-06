#ifndef __HLS_OCACCEL_H__
#define __HLS_OCACCEL_H__

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
#define MEMDW 512          // 512 or 128 // Bus width in bits for Host memory
#define BPERDW (MEMDW/8)   // Bytes per Data Word    if MEMDW=512 => BPERDW = 64
#define WPERDW (64/BPERDW) // Number of words per DW if MEMDW=512 => WPERDW =  1
#define ADDR_RIGHT_SHIFT 6
#define OCACCEL_HLS_JOBSIZE 108

typedef ap_uint<MEMDW> ocaccel_membus_t;  /* ocaccel memory access */
typedef ap_uint<64> ocaccelu64_t;
typedef ap_uint<32> ocaccelu32_t;
typedef ap_uint<16> ocaccelu16_t;
typedef ap_uint<8> ocaccelu8_t;
typedef ap_uint<1> ocaccel_bool_t;

typedef struct {
        ocaccelu8_t sat; // short action type
        ocaccelu8_t flags;
        ocaccelu16_t seq;
        ocaccelu32_t Retc;
        ocaccelu64_t Reserved; // Priv_data
} CONTROL;


#endif  /* __HLS_OCACCEL_H__ */
