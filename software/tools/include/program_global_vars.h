#ifndef FLSH_GLOBAL_VARS_H_
#define FLSH_GLOBAL_VARS_H_

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


// Variables to control trace printing, one for each level of functionality.
extern int TRC_CONFIG   ;
extern int TRC_AXI      ;
extern int TRC_FLASH    ;
extern int TRC_FLASH_CMD;

// Variable to hold CFG Linux file descriptor
extern int CFG_FD;

// Variable to hold number of errors detected during execution
extern int ERRORS_DETECTED;

// When enabled, flash_op does extra checking on the Quad SPI core. However this may impact performance.
extern int FLASH_OP_CHECK;

// Accumulate the number of FLASH ops performed since the test started
extern int FLASH_OP_COUNT;    

// Reusable array of bytes to hold lower 3 bytes of address, use for invoking FLASH operation
extern byte FLASH_ADDR[];

// Hold upper address byte (4th address byte), one per FLASH. Apply to FLASH via EXTENDED ADDRESS REGISTER.
// Note: Setting the 4th address byte allows FLASH operations to be 3 address bytes, making them more efficient.
extern byte FLASH_UPPER_ADDR_DEV1;
extern byte FLASH_UPPER_ADDR_DEV2;

// Set to size of DTR / DRR FIFOs used in IP wizard when generating Quad SPI core (16 or 256 bytes)
extern const int FIFO_DEPTH;

#endif
