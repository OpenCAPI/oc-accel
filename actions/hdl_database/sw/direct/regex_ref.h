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
// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
// Author: Gou Peng Fei (shgoupf@cn.ibm.com)
// ****************************************************************

#ifndef F_REGEX_REF
#define F_REGEX_REF

#include <inttypes.h>

typedef struct {
    uint32_t packet_id;
    uint32_t pattern_id;
    uint16_t offset;
} sm_stat;

#ifdef __cplusplus
extern "C" {
#endif
void    regex_ref_push_pattern (const char* in_patt);
void    regex_ref_push_packet (const char* in_pkt);
void    regex_ref_run_match ();
sm_stat regex_ref_get_result (uint32_t in_pkt_id);
int     regex_ref_get_num_matched_pkt();
#ifdef __cplusplus
}
#endif

#endif
