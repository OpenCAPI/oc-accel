#ifndef FLSH_COMMON_FUNCS_H_
#define FLSH_COMMON_FUNCS_H_

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


// Configuration register operations
// - String is optional, used to describe the purpose of the operation when tracing is enabled. Fill with NULL if unused.
void config_write(                    // Host issues 'config_write' instruction over OpenCAPI interface to AFU config space
                   u32 addr           //   Configuration register address
                 , u32 wdata          //   Data to write into configuration register
                 , int num_bytes      //   Can write 1, 2, or 4 bytes
                 , char *s);          //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.

u32  config_read(                     // Host issues 'config_read' instruction over OpenCAPI interface to AFU config space 
                  u32 addr            //   Always reads 4 bytes
                , char *s);           //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.

u32  form_FLASH_ADDR(                 // Assemble fields into value to load into CFG_FLASH_ADDR register
                      u32 devsel      //   Select Quad SPI or HWICAP core as AXI target 
                    , u32 addr        //   Select target register within the selected core
                    , u32 strobes     //   Choose operation type, write or read
                    , u32 exp_enab    //   Choose whether to use data expander
                    , u32 exp_dir);   //   Determine expander direction                    

// AXI4-Lite operations
void check_axi_status(              // Check 'device specific status' signals saved in CFG_FLASH_ADDR register after AXI operation completes
                       u32 rdata    //   Data read from CFG_FLASH_ADDR, upper bits contain 'device specific status'
                     , u32 mask     //   Set the apppropriate status bit to suppress checking it (normally set to 0x00000000, U32_ZERO)
                     , char *s);    //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.

char* axi_devsel_as_str(                  // Convert device select value to string for nicer printing
                         u32 axi_devsel);  

char* exp_enab_as_str(                    // Convert byte expander enable to string for nicer printing
                       u32 exp_enab);

char* exp_dir_as_str(                    // Convert byte expander direction to string for nicer printing
                      u32 exp_dir);

char* axi_addr_as_str(                   // Convert slave address to register name for nicer printing
                        u32 axi_devsel   //   Need device select to know which slave is targeted
                      , u32 axi_addr);   //   Targeted address in slave 

void  axi_write_no_check(            // Initiate a write operation on the AXI4-Lite bus BUT WITHOUT any checking/reading
                 u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
               , u32 axi_addr        //   Select target register within the selected core
               , u32 exp_enab        //   Choose whether to use data expander
               , u32 exp_dir         //   Determine expander direction
               , u32 axi_wdata       //   Data written to AXI4-Lite slave
               , char *s             //   Comment to be printed in trace message
               );


void  axi_write(                     // Initiate a write operation on the AXI4-Lite bus 
                 u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
               , u32 axi_addr        //   Select target register within the selected core
               , u32 exp_enab        //   Choose whether to use data expander
               , u32 exp_dir         //   Determine expander direction
               , u32 axi_wdata       //   Data written to AXI4-Lite slave
               , char *s             //   Comment to be printed in trace message
               );

u32  axi_read(                      // Initiate a read operation on the AXI4-Lite bus. Read data is returned.
                u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
              , u32 axi_addr        //   Select target register within the selected core
              , u32 exp_enab        //   Choose whether to use data expander
              , u32 exp_dir         //   Determine expander direction
              , char *s             //   Comment to be printed in trace message
              );

void  axi_write_zynq(                     // Initiate a write operation on the AXI4-Lite bus 
                 u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
               , u32 axi_addr        //   Select target register within the selected core
               , u32 exp_enab        //   Choose whether to use data expander
               , u32 exp_dir         //   Determine expander direction
               , u32 axi_wdata       //   Data written to AXI4-Lite slave
               , char *s             //   Comment to be printed in trace message
               );

u32  axi_read_zynq(                      // Initiate a read operation on the AXI4-Lite bus. Read data is returned.
                u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
              , u32 axi_addr        //   Select target register within the selected core
              , u32 exp_enab        //   Choose whether to use data expander
              , u32 exp_dir         //   Determine expander direction
              , char *s             //   Comment to be printed in trace message
              );

// snap_peek/poke functions
int snap_peek (
    int card_no,
    int width,
    uint32_t offs,
    uint64_t equal_val,
    uint64_t not_equal_val
    );

void read_ICAP_regs();              // Read and display all AXI readable registers in HWICAP core

void read_QSPI_regs();              // Read and display all AXI readable registers in Quad SPI core

void QSPI_setup();                  // Reset and set up the Quad SPI core to beginning state

char* flash_devsel_as_str(u32 flash_devsel);   // Convert to FLASH device select to string for nicer printing

char* fo_dir_as_str(int dir);                  // Convert flash_op direction value to string for nicer printing

void  fo_wait_for_DTR_FIFO_empty(); // Wait for IPISR[2] to become 1 indicating DTR FIFO has been emptied (all bytes sent to the FLASH)

void fo_read_DRR(                     // Obtain shifted out data. Check that RX FIFO remains not empty for the correct number of data bytes.
                  byte *drr_data      // Pointer to buffer that will hold DRR contents when function is complete 
                , int   load_bytes    // Number of bytes to read from DRR
                , int   dir           // Skip some steps based on the direction of the FLASH operation (FO_DIR_XCHG, FO_DIR_RD, FO_DIR_WR)
                );

void flash_op(                      // The SPI interface shifts data in while simultaneously shifting data out, thus "read" is the same as a "write".
               u32  devsel          // Select FLASH device to target (use SPISSR_SEL_DEV1 or SPISSR_SEL_DEV2) 
             , byte cmd             // Command to sent to FLASH
             , u32  addr            // 0-4 bytes of address to target in FLASH (1B addr in [7:0], 2B in [15:0], 3B in [23:0], 4B in [31:0])
             , int  num_addr        // Number of address bytes (usually 0 or 3 depending on cmd, 3 max)
             , int  num_dummy       // Number of dummy cycles (0 to 10 for Micron FLASH parts)
             , int  num_bytes       // Number of data bytes, 0-N
             , byte *wdata          // Reference to array of bytes to write to FLASH  (note: wdata and rdata arrays should be the same size)
             , byte *rdata          // Reference to array of bytes to place data read from FLASH
             , int  dir             // Skip some steps based on the direction of the FLASH operation (FO_DIR_XCHG, FO_DIR_RD, FO_DIR_WR)
             , char *s              // Comment to be printed in trace string
             );

void flash_setup(u32 devsel);       // Setup selected FLASH for 9V3 board usage (pass in SPISSR_SEL_DEV1 or SPISSR_SEL_DEV2)
 
void fr_wait_for_WRITE_IN_PROGRESS_to_clear(u32 devsel);  // Wait for 'WRITE IN PROGRESS' status bit to return to not busy state

void read_flash_regs(u32 devsel);   // Read all registers in the targeted FLASH (pass in SPISSR_SEL_DEV1 or SPISSR_SEL_DEV2)

// --------------------------------------------------------------------------------------------------------
// FLASH access functions notes
// - The idea is to pass different options into 'flash_op' that are tailored to a specific FLASH facility
//   access. This simplifies the user's code as the only need to call the function for the register of 
//   interest without having to know the details of opcode, dummy cycles, etc. for the command. 
// - Some FLASH facilities have Read Only, Write Only or Read/Write via a "shift exchange" of data. 
//   some steps in 'flash_op' can be skipped if there is knowledge of which direction the access intends
//   to use. The skipped steps reduce the number of AXI, and thus config_*, operations that occur so can
//   have a noticeable performance impact at run time.
// - Prefix's on function names identify the directionality:
//     fo_*    For 'flash_op'
//     fr_*    Read operation, contents of write data shifted in is unimportant
//     fw_*    Write operation, shifted out read data is unimportant
//     fx_*    Exchange operation, both write and read data are important
//   After the prefix, the name of the FLASH facility (taken from the Micron spec) is appended.
// - Functions which return read data return either:
//     byte    Single byte
//     u32     Up to 4 bytes, adjusted to the right when less than 32 bits are used
//             For example, [15:0] for 2 bytes, [23:0] for 3 bytes, [31:0] for 4 bytes.
//     void return type, but pass in address of array of bytes indicating where to store read data
//             This is used for functions returning more than 4 bytes.
// --------------------------------------------------------------------------------------------------------

byte u32tobyte(u32 x);              // Simple converter from u32 to byte type
int  check_TRC_FLASH_CMD();         // Helper function for read Flash functions

void fw_Reset_Enable(u32 devsel);   // FLASH facility access functions
void fw_Reset_Memory(u32 devsel);
void fw_Enter_4B_Adress_Mode(u32 devsel);
void fw_Write_Enable(u32 devsel);
byte fr_Enhanced_Volatile_Configuration_Register(u32 devsel);
void fw_Enhanced_Volatile_Configuration_Register(u32 devsel, byte wdata);
byte fr_Extended_Address_Register(u32 devsel);
void fw_Extended_Address_Register(u32 devsel, byte wdata);
byte fr_Status_Register(u32 devsel);
void fw_Status_Register(u32 devsel, byte wdata);
byte fr_Flag_Status_Register(u32 devsel);
void fw_Clear_Flag_Status_Register(u32 devsel);
u32  fr_Nonvolatile_Configuration_Register(u32 devsel);
void fw_Nonvolatile_Configuration_Register(u32 devsel, u32 wdata);
byte fr_Volatile_Configuration_Register(u32 devsel);
void fw_Volatile_Configuration_Register(u32 devsel, byte wdata);
void fr_Device_ID_Register(u32 devsel, byte *rdata);    // 20 bytes of read data stored in buffer whose address is passed in

// These commands use a 3 byte address. The value in the EXTENDED ADDRESS REGISTER is used to provide the upper bit of address.
void fw_4KB_Subsector_Erase(u32 devsel, u32 addr); 
void fw_64KB_Sector_Erase(u32 devsel, u32 addr);
void fr_Read(u32 devsel, u32 addr, int num_bytes, byte *rary);           
void fw_Page_Program(u32 devsel, u32 addr, int num_bytes, byte *wary);  



// READ (all) FLASH REGISTERS


void Check_Accumulated_Errors(void);  // Check Global error flag to determine if test passed or failed

int reload_image(char image_location[], char cfgbdf[]);
void reset_ICAP();
void read_FPGA_IDCODE();
u32 read_ICAP_wfifo_size();
void write_ICAP_bitstream_word(u32 wdata);
u32 wait_ICAP_write_done();

#endif
