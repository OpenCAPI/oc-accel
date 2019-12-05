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

#ifndef __SNAP_ACTIONS_H__
#define __SNAP_ACTIONS_H__

#include <stdint.h>

struct actions_tab {
    const char* vendor;
    uint32_t dev1;
    const char* description;
};

static const struct actions_tab snap_actions[] = {
/* KEEP names without space as they as reused in test */
/* Recommended Usage OC HDL examples use 0x10142xxx IDs */
    { "IBM", 0x10142000, "hdl_example in VHDL  (512b)"                           },
    { "IBM", 0x10142002, "hdl_single_engine in Verilog (1024b)"                  },
    { "IBM", 0x10142004, "UVM test for unit verification (no OCSE and software)" },
    { "IBM", 0x1014200E, "HDL_multi-process example"                             },
    { "IBM", 0x1014200D, "HDL database example"                                  },
    { "IBM", 0x1014200C, "HDL nvdla multi-kernel example"                        },
/* recommended Usage OC HLS examples use 0x10143xxx IDs */
    { "IBM", 0x10143008, "HLS_Helloworld      (512b)"                           },
    { "IBM", 0x1014300B, "HLS_Memcopy_1024     (1024b)"                          },
};

#endif  /* __SNAP_ACTIONS_H__ */
