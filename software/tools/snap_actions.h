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
        const char *vendor;
        uint32_t dev1;
        uint32_t dev2;
        const char *description;
};

static const struct actions_tab snap_actions[] = {
  { "Reserved", 0x00000000, 0x00000000, "Reserved" },
  { "IBM", 0x10142000, 0x10142000, "HDL_example in VHDL  (512b)" },
  { "IBM", 0x10142002, 0x10142002, "HDL single_engine in Verilog (1024b)" },
  { "IBM", 0x10142004, 0x10142004, "UVM test for unit verification (no OCSE and software)" },
  { "IBM", 0x1014200E, 0x1014200E, "HDL_multi-process example" },
  { "IBM", 0x1014200F, 0x10140FFF, "Reserved for HDL IBM Actions" },
  { "IBM", 0x10143008, 0x10143008, "HLS Helloworld_512    (512b)" },
  { "IBM", 0x10143009, 0x10143009, "HLS Helloworld_1024   (1024b)" },
  { "IBM", 0x1014300B, 0x1014300B, "HLS Memcopy_1024 (1024b)" },
  { "IBM", 0x1014300C, 0x1014300C, "HLS HBM Memcopy  (1024b)" },
  { "IBM", 0x1014300D, 0x1014FFFF, "Reserved for HLS IBM Actions" },
  { "PSI", 0x52320001, 0x523200FF, "X-ray Detector Data Acquisition and Analysis" },
  { "Reserved", 0xFFFF0000, 0xFFFFFFFF, "Reserved" },
};

#endif  /* __SNAP_ACTIONS_H__ */
