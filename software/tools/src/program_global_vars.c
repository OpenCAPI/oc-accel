#ifndef FLSH_GLOBAL_VARS_C_
#define FLSH_GLOBAL_VARS_C_

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

#include "program_common_defs.h"

// Variables to control trace printing, one for each level of functionality.
int TRC_CONFIG    = TRC_OFF;   // Show config_write / config_read commands
int TRC_AXI       = TRC_OFF;   // Show axi_write / axi_read commands
int TRC_FLASH     = TRC_OFF;   // Show flash_op commands
int TRC_FLASH_CMD = TRC_OFF;   // Print msg on commands to FLASH facilities

// Variable to hold CFG Linux file descriptor
int CFG_FD;

// Variable to hold number of errors detected during execution
int ERRORS_DETECTED = 0;

// When enabled, flash_op does extra checking on the Quad SPI core. However this may impact performance.
int FLASH_OP_CHECK = FO_CHK_OFF;

// Accumulate the number of FLASH ops performed since the test started
int FLASH_OP_COUNT = 0;    

// Reusable array of bytes to hold lower 3 bytes of address, use for invoking FLASH operation
byte FLASH_ADDR[] = { 0x00, 0x00, 0x00 };

// Hold upper address byte (4th address byte), one per FLASH. Apply to FLASH via EXTENDED ADDRESS REGISTER.
// Note: Setting the 4th address byte allows FLASH operations to be 3 address bytes, making them more efficient.
byte FLASH_UPPER_ADDR_DEV1 = 0x00;
byte FLASH_UPPER_ADDR_DEV2 = 0x00;

// Set to size of DTR / DRR FIFOs used in IP wizard when generating Quad SPI core (16 or 256 bytes)
//const int FIFO_DEPTH = 256;    
  const int FIFO_DEPTH = 16;     


#endif
