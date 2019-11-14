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

#ifndef __SNAP_ACTIONS_H__
#define __SNAP_ACTIONS_H__

#include <stdint.h>

struct actions_tab {
    const char* vendor;
    uint32_t dev1;
    const char* description;
};

static const struct actions_tab snap_actions[] = {
    { "IBM", 0x10140000, "hdl_example in VHDL  (512b)"                           },
    { "IBM", 0x10140002, "hdl_single_engine in Verilog (1024b)"                  },
    { "IBM", 0x10140004, "UVM test for unit verification (no OCSE and software)" },
    { "IBM", 0x1014100E, "HDL multi-process example"                             },
    { "IBM", 0x1014100D, "HDL database example"                                  },

    { "IBM", 0x10141008, "HLS Hello World      (512b)"                           },
    { "IBM", 0x1014100B, "HLS Memcopy 1024     (1024b)"                          },
};

#endif  /* __SNAP_ACTIONS_H__ */
