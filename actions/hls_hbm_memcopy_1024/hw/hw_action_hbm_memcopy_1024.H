#ifndef __ACTION_HLS_HBM_MEMCOPY_H__
#define __ACTION_HLS_HBM_MEMCOPY_H__

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

#include "hls_snap_1024.H"
#include <action_memcopy.h> /* Memcopy Job definition */


#define MAX_NB_OF_BYTES_READ	(128 * 1024)
#define LCL_MEM_MAX_SIZE	(256 * 1024 * 1024)  // HBM is 256MB each
#define MAX_NB_OF_WORDS_READ_256    (MAX_NB_OF_BYTES_READ/BPERDW_256)
#define MAX_NB_OF_WORDS_READ_512    (MAX_NB_OF_BYTES_READ/BPERDW_512)
#define MAX_NB_OF_WORDS_READ_1024	(MAX_NB_OF_BYTES_READ/BPERDW_1024)

//---------------------------------------------------------------------
typedef struct {
	CONTROL Control;	/*  16 bytes */
	memcopy_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(memcopy_job_t)];
} action_reg;

#endif  /* __ACTION_HLS_HBM_MEMCOPY_H__ */
