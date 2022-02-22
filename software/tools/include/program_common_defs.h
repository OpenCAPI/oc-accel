#ifndef FLSH_COMMON_DEFS_H_
#define FLSH_COMMON_DEFS_H_

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

// Set or comment out #define to test C code using Incisive, passing from irun cmd line only seems to define it in SystemVerilog, not C
//#define USE_SIM_TO_TEST 1
//#define USE_CRONUS_ACCESS 1

// For all functions: 
// - Create type for unsigned 32 bit value, allowing machine to machine variation in byte sizes for 'int'
// - Create type for 8 bit byte, making it clearer to understand the code
typedef unsigned int  u32;
typedef unsigned char byte;


// Pass into functions as default argument values 
#define U32_ZERO       0x00000000
#define U32_ONES       0xFFFFFFFF

// For trace variables
#define TRC_OFF 0
#define TRC_ON  1

// For function(s): config_write(), config_read()
// - Addresses in the OpenCAPI Configuration register space for the regs that create the AXI4-Lite master interface
// - Found in Function 0, Vendor DVSEC
#ifdef USE_CRONUS_ACCESS
  #define CFG_DEVID      ((const unsigned char *)"000")
  #define CFG_FLASH_ADDR ((const unsigned char *)"630")
  #define CFG_FLASH_DATA ((const unsigned char *)"634")
#endif
#ifndef USE_CRONUS_ACCESS
  #define CFG_DEVID      0x000
  #define CFG_FLASH_ADDR 0x630
  #define CFG_FLASH_DATA 0x634 
#endif
 #define CFG_SUBSYS 0x02C
// For function(s): form_FLASH_ADDR()
// - Values for fields that combine to form the contents of CFG_FLASH_ADDR
// - Values are already aligned to make combining them easy. Do not change the values unless the hardware implementation changes.
//
//   devsel     [15:14] Select which AXI4-Lite slave to target with the AXI operation
#define FA_QSPI        0x00000000
#define FA_ICAP        0x00004000
//   strobes    [17:16] Perform AXI write or AXI read operation
#define FA_RD          0x00010000
#define FA_WR          0x00020000
//   exp_enab   [19] Enable or disable Byte Expander feature
#define FA_EXP_OFF     0x00000000
#define FA_EXP_ON      0x00080000
//   exp_dir    [18] Direction of bytes used by Byte Expander
#define FA_EXP_0123    0x00000000
#define FA_EXP_3210    0x00040000
//   addr       [13:0] AXI4-Lite addresses, by slave
//              In Quad SPI core:
//              SRR    = Software Reset Register
//              SPICR  = SPI Control Register
//              SPISR  = SPI Status Register
//              SPIDTR = SPI Data Transmit Register
//              SPIDRR = SPI Data Receive Register
//              SPISSR = SPI Slave Select Register
//              TXFIFO = Transmit FIFO Occupancy Register
//              RXFIFO = Receive FIFO Occupancy Register
//              DGIER  = Device Global Interrupt Enable Register
//              IPISR  = IP Interrupt Status Register
//              IPIER  = IP Interrupt Enable Register
#define FA_QSPI_SRR    0x00000040
#define FA_QSPI_SPICR  0x00000060
#define FA_QSPI_SPISR  0x00000064
#define FA_QSPI_SPIDTR 0x00000068
#define FA_QSPI_SPIDRR 0x0000006C
#define FA_QSPI_SPISSR 0x00000070
#define FA_QSPI_TXFIFO 0x00000074
#define FA_QSPI_RDFIFO 0x00000078
#define FA_QSPI_DGIER  0x0000001C
#define FA_QSPI_IPISR  0x00000020
#define FA_QSPI_IPIER  0x00000028
//              In HWICAP core:
//              GIER = Global Interrupt Enable Register
//              ISR  = Abort Status Register
//              IER  = IP Interrupt Enable Register
//              WF   = Write FIFO Keyhole Register
//              RF   = Read FIFO Keyhole Register
//              SZ   = Size Register
//              CR   = Control Register
//              SR   = Status Register
//              WFV  = Write FIFO Vacancy Register
//              RFO  = Read FIFO Occupancy Register
//              ASR  = Abort Status Register
#define FA_ICAP_GIER  0x0000001C
#define FA_ICAP_ISR   0x00000020
#define FA_ICAP_IER   0x00000028
#define FA_ICAP_WF    0x00000100
#define FA_ICAP_RF    0x00000104
#define FA_ICAP_SZ    0x00000108
#define FA_ICAP_CR    0x0000010C
#define FA_ICAP_SR    0x00000110
#define FA_ICAP_WFV   0x00000114
#define FA_ICAP_RFO   0x00000118
#define FA_ICAP_ASR   0x0000011C

// 
//              With ICAP in USER AREA
//              SR   = Status Register
#define USER_ICAP_SR  0x00000F10

//   wr_response [23:22] Response to AXI Write operation
#define FA_WR_RESP_FIELD  0x00C00000
#define FA_WR_RESP_OK     0x00000000
#define FA_WR_RESP_RSVD   0x00400000
#define FA_WR_RESP_SLVERR 0x00800000
#define FA_WR_RESP_INVLD  0x00C00000
//   rd_response [21:20] Response to AXI Read operation
#define FA_RD_RESP_FIELD  0x00300000
#define FA_RD_RESP_OK     0x00000000
#define FA_RD_RESP_RSVD   0x00100000
#define FA_RD_RESP_SLVERR 0x00200000
#define FA_RD_RESP_INVLD  0x00300000
                               
// Device Status Bits (returned after AXI operation in CFG_FLASH_ADDR[27:24])
#define DEVSTAT_QSPI_INTERRUPT  0x08000000
#define DEVSTAT_ICAP_INTERRUPT  0x04000000
#define DEVSTAT_PREQ            0x02000000
#define DEVSTAT_EOS             0x01000000

// QSPI SPISSR (SPI Slave Select Register) (select neither device when no transaction is going on)
// - Select slave 1 [0] or slave 2 [1] (active low)
// - [31: 2] Reserved
// -     [1] Select slave 2 (0 = select, 1 = deselect DQ[7:4])
// -     [0] Select slave 1 (0 = select, 1 = deselect DQ[3:0])
#define SPISSR_SEL_DEV1 0x00000002
#define SPISSR_SEL_DEV2 0x00000001
#define SPISSR_SEL_NONE 0x00000003

// Global variables for 'flash_op', to allow skipping steps if the direction is known
#define FO_DIR_XCHG 0
#define FO_DIR_RD   1
#define FO_DIR_WR   2

// Global variables for 'flash_op', enable or disable extra QSPI checks (use with FLASH_OP_CHECK)
#define FO_CHK_OFF 0
#define FO_CHK_ON  1






// QSPI SPICR (SPI Control Register)
// - [31:10] Reserved
// -    [ 9] LSB First (0 = MSB first)
// -    [ 8] Master Transaction Inhibit (0 = Master transactions enabled, 1 = Master transactions disabled)
// -    [ 7] Manual Slave Select Assertion Enable (0 = Slave Select output asserted by Master core logic)
// -    [ 6] RX FIFO Reset (0 = normal operation, no reset, 1 = reset RX FIFO pointer)
// -    [ 5] TX FIFO Reset (0 = normal operation, no reset, 1 = reset TX FIFO pointer)
// -    [ 4] CPHA, Clock Phase (0 = Data valid on the first SCK edge (rising or falling) after SS_n has been asserted)
// -    [ 3] CPOL, Clock Polarity (0 = Active high clock, SCK idles Low)
// -    [ 2] Master, SPI Master Mode (1 = Master configuration)
// -    [ 1] SPE, SPI System Enable (1 = SPI system enabled)
// -    [ 0] Loop (0 = Normal operation)
//`define SPICR_M_XACT_DISABLED {22'b0,10'b01_0000_0110}
//`define SPICR_M_XACT_ENABLED  {22'b0,10'b00_0000_0110} 
//`define SPICR_RESET_FIFOS     {22'b0,10'b00_0110_0110} 

// -    [ 7] Manual Slave Select Assertion Enable (1 = Slave Select output follows data in slave select register)  (quad-spi, pg 79)
//#define SPICR_M_XACT_DISABLED {22'b0,10'b01_1000_0110}
//#define SPICR_M_XACT_ENABLED  {22'b0,10'b00_1000_0110} 
//#define SPICR_RESET_FIFOS     {22'b0,10'b00_1110_0110} 


#endif  // FLSH_COMMON_DEFS_H_ 
