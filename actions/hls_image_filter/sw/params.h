/*
 * Copyright 2020 International Business Machines
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

#ifndef _PARAM_H_  // prevent recursive inclusion
#define _PARAM_H_

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
#include <osnap_tools.h>
#include <libosnap.h>
#include <action_pixel_filtering.h>
#include <osnap_hls_if.h>

typedef struct { 
      uint16_t card_no;
      char *input;
      char *output;
      uint8_t addr_in;
      uint8_t addr_out;
      uint8_t type_in;
      uint8_t type_out;
      unsigned long timeout;
      int verify;
      snap_action_flag_t action_irq;
      int verbose_flag;
}
STRparam;

void usage(const char *prog);
STRparam* readParams(int argc, char *argv[]);

static STRparam parms;
	

#endif	
