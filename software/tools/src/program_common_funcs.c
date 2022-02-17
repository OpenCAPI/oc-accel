#ifndef FLSH_COMMON_FUNCS_C_
#define FLSH_COMMON_FUNCS_C_

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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// For lseek, read, write
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>

#include "program_common_defs.h"
#include "program_global_vars.h"
#include "program_common_funcs.h"

// Provide cross references to System Verilog tasks for Incisive simulation of C code
#ifdef USE_SIM_TO_TEST
  #include "svdpi.h"
  extern void CFG_WR_C(unsigned int, unsigned int, unsigned int, const char*);
  extern void CFG_RD_C(unsigned int, unsigned int*, const char*);
  extern void WORKAROUND_FORCE_DQ(unsigned int);
  extern void WORKAROUND_RELEASE_DQ(unsigned int);
#endif

static int GlobalEOS = 0;

// --------------------------------------------------------------------------------------------------------
// Configuration register operations
// - String is used to describe the purpose of the operation when tracing is enabled. Fill with NULL if unused.
void config_write(                    // Host issues 'config_write' instruction over OpenCAPI interface to AFU config space
                   u32 addr           //   Configuration register address
                 , u32 wdata          //   Data to write into configuration register
                 , int num_bytes      //   Can write 1, 2, or 4 bytes
                 , char *s)           //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.
{ int rc;

  if (TRC_CONFIG == TRC_ON)
    printf("trace      config_write  addr h%8x, wdata h%8x, num_bytes %1d, <%s>\n", addr, wdata, num_bytes, s);

  if (!(num_bytes == 1 || num_bytes == 2 || num_bytes == 4)) {
    printf("*** ERROR in config_write(), num_bytes must be 1, 2, or 4 ***: addr h%8x, wdata h%8x, num_bytes %d, <%s>\n", addr, wdata, num_bytes, s);
    ERRORS_DETECTED++;
    printf("    Aborting config_write operation\n");
    return;  // Abort operation
  };

#ifdef USE_SIM_TO_TEST
  // For simulation
  CFG_WR_C( addr, wdata, num_bytes, s);

  // To prevent warnings, assign and use 'rc'
  rc = 0;
  if (rc == 1) printf("WARNING: config_read rc=1, shouldn't happen\n");
#elif defined USE_CRONUS_ACCESS
  char command1[1024];
  char command2[1024];
  char writedatastr[64] = "";
  char writedatastr2[64] = "";
  strcpy(command1, "putmemproc -ci 60302016E0000 80000");

  strcat(command1, addr);
  strcat(command1, "00000000");
  strcpy(command2, "putmemproc -ci 60302016E0080 ");
  //printf("%s\n",command1);
  system(command1);
  if(num_bytes == 1) {
    sprintf(writedatastr, "%08x", wdata);
    writedatastr2[0] = writedatastr[6];
    writedatastr2[1] = writedatastr[7];
    strcat(command2, writedatastr2);
    //printf("%s\n",command2);
    system(command2);
  }
  else if(num_bytes == 2) {
    sprintf(writedatastr, "%08x", wdata);
    writedatastr2[0] = writedatastr[6];
    writedatastr2[1] = writedatastr[7];
    writedatastr2[2] = writedatastr[4];
    writedatastr2[3] = writedatastr[5];
    strcat(command2, writedatastr2);
    //printf("%s\n",command2);
    system(command2);
  }
  else {
    sprintf(writedatastr, "%08x", wdata);
    //Swap endianness
    writedatastr2[0] = writedatastr[6];
    writedatastr2[1] = writedatastr[7];
    writedatastr2[2] = writedatastr[4];
    writedatastr2[3] = writedatastr[5];
    writedatastr2[4] = writedatastr[2];
    writedatastr2[5] = writedatastr[3];
    writedatastr2[6] = writedatastr[0];
    writedatastr2[7] = writedatastr[1];
    strcat(command2, writedatastr2);
    //printf("%s\n",command2);
    system(command2);
  }
#else
  // For Linux running on real FPGA card
  rc = lseek(CFG_FD, addr, SEEK_SET);   // Find register in config space
  if (rc == -1) {
    printf("*** ERROR in config_write(), lseek() ***: addr h%8x, wdata h%8x, num_bytes %1d, <%s>\n", addr, wdata, num_bytes, s);
    perror("  ");   // Print meaning of the error placed in errno
    ERRORS_DETECTED++;
  };
  write(CFG_FD, &wdata, num_bytes);     // Write bytes
  if (rc != num_bytes) {
    //printf("*** ERROR in config_write(), write() ***: addr h%8x, wdata h%8x, num_bytes %1d, <%s>\n", addr, wdata, num_bytes, s);
    //printf("  number of bytes written, which should be %1d, = %d\n", num_bytes, rc);
    //perror("  errno (if it exists) = ");   // Print meaning of the error placed in errno
    //ERRORS_DETECTED++;
  };
#endif

  return;
}



// --------------------------------------------------------------------------------------------------------
u32  config_read(                     // Host issues 'config_read' instruction over OpenCAPI interface to AFU config space
                  u32 addr            //   Always reads 4 bytes
                , char *s)            //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.
{ int rc;
  u32 rdata;

#ifdef USE_SIM_TO_TEST
  // For simulation
  CFG_RD_C(addr, &rdata, s);

  // To prevent warnings, assign and use 'rc'
  rc = 0;
  if (rc == 1) printf("WARNING: config_read rc=1, shouldn't happen\n");
#elif defined USE_CRONUS_ACCESS
  char  addr_offset_string[3];
  char buf[3];
  char command1[1024];
  char command2[1024];
  char outputjunkbuffer[1024];
  char readdatastr[1024] = "";
  char readdatastr2[1024] = "";
  strcpy(command1, "putmemproc -ci 60302016E0000 80000");

  strcat(command1, addr);
  strcat(command1, "00000000");
  strcpy(command2, "getmemproc -ci 60302016E0080 4");
  //printf("%s\n",command1);
  system(command1);
  //printf("%s\n",command2);
  FILE *memprocout = popen(command2,"r");
  if (!memprocout) {
    exit(-1);
  }
  char *getmemline = fgets(outputjunkbuffer,sizeof(outputjunkbuffer),memprocout);
  //toss out first line. relevant cronus output on second line from console.
  fgets(outputjunkbuffer,sizeof(outputjunkbuffer),memprocout);
  //grab portion of string that is relevant
  memcpy(readdatastr,&outputjunkbuffer[18],8);
  pclose(memprocout);
  //Swap endianness
  readdatastr2[0] = readdatastr[6];
  readdatastr2[1] = readdatastr[7];
  readdatastr2[2] = readdatastr[4];
  readdatastr2[3] = readdatastr[5];
  readdatastr2[4] = readdatastr[2];
  readdatastr2[5] = readdatastr[3];
  readdatastr2[6] = readdatastr[0];
  readdatastr2[7] = readdatastr[1];
  //printf("I got %s as config read data!\n", readdatastr);
  char *nextptr;
  rdata = strtoul(readdatastr2,&nextptr,16);
  //printf("I got %08x as config read data!\n", rdata);
#else
  // For Linux running on real FPGA card
  rc = lseek(CFG_FD, addr, SEEK_SET);   // Find register in config space
  if (rc == -1) {
    printf("*** ERROR in config_read(), lseek() ***: addr h%8x, <%s>\n", addr, s);
    perror("  ");   // Print meaning of the error placed in errno
    ERRORS_DETECTED++;
  };
  read(CFG_FD, &rdata, 4);              // Always read 4 bytes
  if (rc != 4) {
    //printf("*** ERROR in config_read(), read() ***: addr h%8x, rdata h%8x, <%s>\n", addr, rdata, s);
    //printf("  number of bytes read, which should be 4, = %d\n", rc);
    //perror("  errno (if it exists) = ");   // Print meaning of the error placed in errno
    //ERRORS_DETECTED++;
  };
#endif

  if (TRC_CONFIG == TRC_ON)
    printf("trace      config_read   addr h%8x, rdata h%8x,              <%s>\n", addr, rdata, s);

  return (rdata);
}



// --------------------------------------------------------------------------------------------------------
// Combine values to create the value to load into the CFG_FLASH_ADDR field
u32  form_FLASH_ADDR(                 // Assemble fields into value to load into CFG_FLASH_ADDR register
                      u32 devsel      // Select AXI4-Lite slave that is target of operation
                    , u32 addr        // Select target register within the selected core
                    , u32 strobes     // Choose operation type, write or read
                    , u32 exp_enab    // Choose whether to use data expander
                    , u32 exp_dir     // Determine expander direction
                    )
{ return (exp_enab | exp_dir | strobes | devsel | addr);   // OR together, assume constant values passed in are pre-aligned to correct bit field
}



// --------------------------------------------------------------------------------------------------------
// AXI4-Lite Operations when using CFG_FLASH_ADDR and CFG_FLASH_DATA
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
void check_axi_status(              // Check 'device specific status' signals saved in CFG_FLASH_ADDR register after AXI operation completes
                       u32 rdata    //   Data read from CFG_FLASH_ADDR, upper bits contain 'device specific status'
                     , u32 mask     //   Set the apppropriate status bit to suppress checking it (normally set to 0x00000000, U32_ZERO)
                     , char *s   )  //   String to add to trace print message, identifying more about this instance of invocation. Set to NULL if unused.
{ u32 qspi_interrupt_bit, qspi_interrupt_mask;
  u32 icap_interrupt_bit, icap_interrupt_mask;
  u32 preq_bit          , preq_mask;
  u32 eos_bit           , eos_mask;

  // Extract bits and masks
  qspi_interrupt_bit  = rdata & DEVSTAT_QSPI_INTERRUPT;
  icap_interrupt_bit  = rdata & DEVSTAT_ICAP_INTERRUPT;
  preq_bit            = rdata & DEVSTAT_PREQ;
  eos_bit             = rdata & DEVSTAT_EOS;

  qspi_interrupt_mask = mask  & DEVSTAT_QSPI_INTERRUPT;
  icap_interrupt_mask = mask  & DEVSTAT_ICAP_INTERRUPT;
  preq_mask           = mask  & DEVSTAT_PREQ;
  eos_mask            = mask  & DEVSTAT_EOS;

  if (qspi_interrupt_mask == U32_ZERO && qspi_interrupt_bit != U32_ZERO) {
    ERRORS_DETECTED++;
    printf("(check_axi_status) <%s>: ***ERROR - qspi_interrupt bit is set ***\n", s);
  }
  if (icap_interrupt_mask == U32_ZERO && icap_interrupt_bit != U32_ZERO) {
    ERRORS_DETECTED++;
    printf("(check_axi_status) <%s>: ***ERROR - icap_interrupt bit is set ***\n", s);
  }
  if (preq_mask           == U32_ZERO && preq_bit           != U32_ZERO) {
    ERRORS_DETECTED++;
    printf("(check_axi_status) <%s>: ***ERROR - preq bit is set ***\n", s);
  }
  if (eos_mask            == U32_ZERO && eos_bit            != DEVSTAT_EOS  && GlobalEOS ==0) {
    ERRORS_DETECTED++;
    printf("\n(check_axi_status) <%s>: ***ERROR - eos bit is not set ***\n", s);
    GlobalEOS = 1;
  }
  return;
}



// --------------------------------------------------------------------------------------------------------
char* axi_devsel_as_str(u32 axi_devsel)  // Convert device select value to string for nicer printing
{ if (axi_devsel == FA_QSPI) return "QSPI";
  if (axi_devsel == FA_ICAP) return "ICAP";

  ERRORS_DETECTED++;
  printf("(axi_devsel_as_str): ***ERROR - unrecognized axi_devsel (h%8x) ***\n", axi_devsel);
  return "<UNKNOWN>";
}



// --------------------------------------------------------------------------------------------------------
char* exp_enab_as_str(u32 exp_enab)      // Convert byte expander enable to string for nicer printing
{ if (exp_enab == FA_EXP_OFF) return "OFF";
  if (exp_enab == FA_EXP_ON)  return "ON ";

  ERRORS_DETECTED++;
  printf("(exp_enab_as_str): ***ERROR - unrecognized exp_enab (h%8x) ***\n", exp_enab);
  return "<UNKNOWN>";
}



// --------------------------------------------------------------------------------------------------------
char* exp_dir_as_str(u32 exp_dir)        // Convert byte expander direction to string for nicer printing
{ if (exp_dir == FA_EXP_0123) return "0123";
  if (exp_dir == FA_EXP_3210) return "3210";

  ERRORS_DETECTED++;
  printf("(exp_dir_as_str): ***ERROR - unrecognized exp_dir (h%8x) ***\n", exp_dir);
  return "<UNKNOWN>";
}


// --------------------------------------------------------------------------------------------------------
char* axi_addr_as_str(                   // Convert slave address to register name for nicer printing
                        u32 axi_devsel   //   Need device select to know which slave is targeted
                      , u32 axi_addr)    //   Targeted address in slave
{ if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SRR    ) return "SRR   ";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SPICR  ) return "SPICR ";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SPISR  ) return "SPISR ";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SPIDTR ) return "SPIDTR";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SPIDRR ) return "SPIDRR";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_SPISSR ) return "SPISSR";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_TXFIFO ) return "TXFIFO";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_RDFIFO ) return "RDFIFO";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_DGIER  ) return "DGIER ";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_IPISR  ) return "IPISR ";
  if (axi_devsel == FA_QSPI && axi_addr == FA_QSPI_IPIER  ) return "IPIER ";

  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_GIER   ) return "GIER  ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_ISR    ) return "ISR   ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_IER    ) return "IER   ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_WF     ) return "WF    ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_RF     ) return "RF    ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_SZ     ) return "SZ    ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_CR     ) return "CR    ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_SR     ) return "SR    ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_WFV    ) return "WFV   ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_RFO    ) return "RFO   ";
  if (axi_devsel == FA_ICAP && axi_addr == FA_ICAP_ASR    ) return "ASR   ";

  //ERRORS_DETECTED++;
  //printf("(axi_addr_as_str): ***ERROR - unrecognized combination of axi_devsel (h%8x) and axi_addr (h%8x) ***\n", axi_devsel, axi_addr);
  return "<UNKNOWN>";
}


// --------------------------------------------------------------------------------------------------------
// This write is used for the reload once the specific sequence has been written and before a reset. No more read can then be done.
void axi_write_no_check(                     // Initiate a write operation on the AXI4-Lite bus
                u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
              , u32 axi_addr        //   Select target register within the selected core
              , u32 exp_enab        //   Choose whether to use data expander
              , u32 exp_dir         //   Determine expander direction
              , u32 axi_wdata       //   Data written to AXI4-Lite slave
              , char *s             //   Comment to be printed in trace message
              )
{
  char call_args[1024];
  u32 read_FA;
  u32 resp;
  int saved_TRC_CONFIG;
  char s_err[1024];
  char s_devstat[1044];
 //int cnt ;
  snprintf(call_args, sizeof(call_args),
           "devsel %s, addr %s (h%8.8X), wdata h%8.8x, exp_enab %s, exp_dir %s, <%s>",
           axi_devsel_as_str(axi_devsel), axi_addr_as_str(axi_devsel,axi_addr), axi_addr, axi_wdata, exp_enab_as_str(exp_enab), exp_dir_as_str(exp_dir), s);

  if (TRC_AXI == TRC_ON) printf("trace    axi_write     %s\n", call_args);
  //printf("trace    axi_write     %s\n", call_args);

  // Step 1: config_write to FLASH_DATA, then FLASH_ADDR initiating AXI write
  config_write(CFG_FLASH_DATA, axi_wdata, 4, "axi_write - step 1a: store write data into FLASH_DATA register");
  config_write(CFG_FLASH_ADDR, form_FLASH_ADDR(axi_devsel, axi_addr, FA_WR, exp_enab, exp_dir), 4, "axi_write - step 1b: write to FLASH_ADDR initiates");

  return;
}

// --------------------------------------------------------------------------------------------------------
void axi_write(                     // Initiate a write operation on the AXI4-Lite bus
                u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
              , u32 axi_addr        //   Select target register within the selected core
              , u32 exp_enab        //   Choose whether to use data expander
              , u32 exp_dir         //   Determine expander direction
              , u32 axi_wdata       //   Data written to AXI4-Lite slave
              , char *s             //   Comment to be printed in trace message
              )
{
  char call_args[1024];
  u32 read_FA;
  u32 resp;
  int saved_TRC_CONFIG;
  char s_err[1024];
  char s_devstat[1044];
  snprintf(call_args, sizeof(call_args),
	   "devsel %s, addr %s (h%8.8X), wdata h%8.8x, exp_enab %s, exp_dir %s, <%s>",
	   axi_devsel_as_str(axi_devsel), axi_addr_as_str(axi_devsel,axi_addr), axi_addr, axi_wdata, exp_enab_as_str(exp_enab), exp_dir_as_str(exp_dir), s);

  if (TRC_AXI == TRC_ON) printf("trace    axi_write     %s\n", call_args);

  // Step 1: config_write to FLASH_DATA, then FLASH_ADDR initiating AXI write
  config_write(CFG_FLASH_DATA, axi_wdata, 4, "axi_write - step 1a: store write data into FLASH_DATA register");
  config_write(CFG_FLASH_ADDR, form_FLASH_ADDR(axi_devsel, axi_addr, FA_WR, exp_enab, exp_dir), 4, "axi_write - step 1b: write to FLASH_ADDR initiates");

  // Step 2: config_read's to poll on Write Strobe to see when it is finished. Print trace msg on only the first one to avoid cluttering output
  saved_TRC_CONFIG = TRC_CONFIG;
  do
  { read_FA = config_read(CFG_FLASH_ADDR, "axi_write - step  2: wait for Write Strobe to become 0 indicating AXI write is complete");
    TRC_CONFIG = 0;  // After 1st poll, stop printing lower level msgs. Reduces clutter, plus doesn't multi-count config_read ops when timing isn't real
  } while ((read_FA & FA_WR) == FA_WR);    // Continue while Write Strobe is 1
  TRC_CONFIG = saved_TRC_CONFIG;   // Restore trace setting

   // Step 3: Check Write Response and Device Specific Status
  resp = (read_FA & FA_WR_RESP_FIELD);
  if (resp != FA_WR_RESP_OK) {
    ERRORS_DETECTED++;
    switch (resp)
    { case FA_WR_RESP_OK     : sprintf(s_err,"SUCCESSFUL    "); break;
      case FA_WR_RESP_RSVD   : sprintf(s_err,"RESERVED      "); break;
      case FA_WR_RESP_SLVERR : sprintf(s_err,"SLAVE_ERROR   "); break;
      case FA_WR_RESP_INVLD  : sprintf(s_err,"INVALID SELECT"); break;
      default                : sprintf(s_err,"<UNKNOWN>     ");
    }
    printf("(axi_write): %s:  *** ERROR - detected bad response on axi_write of %s (h%8x) ***\n", call_args, s_err, resp);
  }

  // Check device status signals
  // set GlobalEOS to 1 with Partial Reconfiguration to remove "eos bit unset" error message
  if((axi_devsel == FA_ICAP ) && (axi_addr == FA_ICAP_CR)) GlobalEOS = 1;

  snprintf(s_devstat, sizeof(s_devstat), "(axi_write): %s ", call_args);
  check_axi_status(read_FA, U32_ZERO, s_devstat);

  return;
}



// --------------------------------------------------------------------------------------------------------
u32 axi_read(                      // Initiate a read operation on the AXI4-Lite bus. Read data is returned.
               u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
             , u32 axi_addr        //   Select target register within the selected core
             , u32 exp_enab        //   Choose whether to use data expander
             , u32 exp_dir         //   Determine expander direction
             , char *s             //   Comment to be printed in trace message
             )
{
  char call_args[1024];
  u32 read_FA;
  u32 resp;
  u32 rdata;
  int saved_TRC_CONFIG;
  char s_err[1024];
  char s_devstat[1044];

  snprintf(call_args, sizeof(call_args),
	   "devsel %s, addr %s (h%8.8X),                  exp_enab %s, exp_dir %s, <%s>",
	   axi_devsel_as_str(axi_devsel), axi_addr_as_str(axi_devsel,axi_addr), axi_addr, exp_enab_as_str(exp_enab), exp_dir_as_str(exp_dir), s);

  if (TRC_AXI == TRC_ON) printf("trace    axi_read      %s\n", call_args);

  // Step 1: config_write to FLASH_ADDR initiating AXI read
  config_write(CFG_FLASH_ADDR, form_FLASH_ADDR(axi_devsel, axi_addr, FA_RD, exp_enab, exp_dir), 4, "axi_read  - step 1: write to FLASH_ADDR to initiate AXI read");

  // Step 2a: config_read's to poll on Read Strobe to see when it is finished. Print trace msg on only the first one to avoid cluttering output
  saved_TRC_CONFIG = TRC_CONFIG;
  do
  { read_FA = config_read(CFG_FLASH_ADDR, "axi_read  - step 2: wait for Read Strobe to become 0 indicating AXI read is complete");
    TRC_CONFIG = 0;  // After 1st poll, stop printing lower level msgs. Reduces clutter, plus doesn't multi-count config_read ops when timing isn't real
  } while ((read_FA & FA_RD) == FA_RD);    // Continue while Read Strobe is 1
  TRC_CONFIG = saved_TRC_CONFIG;           // Restore trace setting

  // Step 2b: Check Read Response and Device Specific Status
  resp = (read_FA & FA_RD_RESP_FIELD);
  if (resp != FA_RD_RESP_OK) {
    ERRORS_DETECTED++;
    switch (resp)
    { case FA_RD_RESP_OK     : sprintf(s_err,"SUCCESSFUL    "); break;
      case FA_RD_RESP_RSVD   : sprintf(s_err,"RESERVED      "); break;
      case FA_RD_RESP_SLVERR : sprintf(s_err,"SLAVE_ERROR   "); break;
      case FA_RD_RESP_INVLD  : sprintf(s_err,"INVALID SELECT"); break;
      default                : sprintf(s_err,"<UNKNOWN>     ");
    }
    printf("(axi_read): %s:  *** ERROR - detected bad response on axi_read of %s (h%8x) ***\n", call_args, s_err, resp);
  }

  // Check device status signals
  // set GlobalEOS to 1 with Partial Reconfiguration to remove "eos bit unset" error message
  if((axi_devsel == FA_ICAP ) && (axi_addr == FA_ICAP_CR)) GlobalEOS = 1;

  snprintf(s_devstat, sizeof(s_devstat), "(axi_read): %s ", call_args);
  check_axi_status(read_FA, U32_ZERO, s_devstat);

  // Step 4: Read returned data
  rdata = config_read(CFG_FLASH_DATA, "axi_read  - step 3: retrieve data from FLASH_DATA register");

  if (TRC_AXI == TRC_ON) printf("trace    axi_read completion   (rdata h%8x)\n", rdata);

  return rdata;
}

void axi_write_zynq(                     // Initiate a write operation on the AXI4-Lite bus 
                u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
              , u32 axi_addr        //   Select target register within the selected core
              , u32 exp_enab        //   Choose whether to use data expander
              , u32 exp_dir         //   Determine expander direction
              , u32 axi_wdata       //   Data written to AXI4-Lite slave
              , char *s             //   Comment to be printed in trace message
              )
{
  char call_args[1024];
  u32 read_FA;
  u32 resp;
  int saved_TRC_CONFIG;
  char s_err[1024];
  char s_devstat[1044];
  
  sprintf(call_args,"devsel %s, addr %s (h%8.8X), wdata h%8.8x, exp_enab %s, exp_dir %s, <%s>",
    axi_devsel_as_str(axi_devsel), axi_addr_as_str(axi_devsel,axi_addr), axi_addr, axi_wdata, exp_enab_as_str(exp_enab), exp_dir_as_str(exp_dir), s); 

  if (TRC_AXI == TRC_ON) printf("trace    axi_write     %s\n", call_args); 

  // Step 1: config_write to FLASH_DATA, then FLASH_ADDR initiating AXI write
  config_write(CFG_FLASH_DATA, axi_wdata, 4, "axi_write - step 1a: store write data into FLASH_DATA register");
  config_write(CFG_FLASH_ADDR, form_FLASH_ADDR(axi_devsel, axi_addr, FA_WR, exp_enab, exp_dir), 4, "axi_write - step 1b: write to FLASH_ADDR initiates");

  // Step 2: config_read's to poll on Write Strobe to see when it is finished. Print trace msg on only the first one to avoid cluttering output
  saved_TRC_CONFIG = TRC_CONFIG;
  do  
  { read_FA = config_read(CFG_FLASH_ADDR, "axi_write - step  2: wait for Write Strobe to become 0 indicating AXI write is complete");
    TRC_CONFIG = 0;  // After 1st poll, stop printing lower level msgs. Reduces clutter, plus doesn't multi-count config_read ops when timing isn't real
  } while ((read_FA & FA_WR) == FA_WR);    // Continue while Write Strobe is 1
  TRC_CONFIG = saved_TRC_CONFIG;   // Restore trace setting

   // Step 3: Check Write Response and Device Specific Status
  resp = (read_FA & FA_WR_RESP_FIELD);
  if (resp != FA_WR_RESP_OK) {
    ERRORS_DETECTED++;
    switch (resp)
    { case FA_WR_RESP_OK     : sprintf(s_err,"SUCCESSFUL    "); break; 
      case FA_WR_RESP_RSVD   : sprintf(s_err,"RESERVED      "); break;
      case FA_WR_RESP_SLVERR : sprintf(s_err,"SLAVE_ERROR   "); break;
      case FA_WR_RESP_INVLD  : sprintf(s_err,"INVALID SELECT"); break;
      default                : sprintf(s_err,"<UNKNOWN>     "); 
    }
    printf("(axi_write): %s:  *** ERROR - detected bad response on axi_write of %s (h%8x) ***\n", call_args, s_err, resp);
  }    
  //sprintf(s_devstat,"(axi_write): %s ", call_args);
  snprintf(s_devstat, sizeof(s_devstat), "(axi_write): %s ", call_args);

  return;
}



// --------------------------------------------------------------------------------------------------------
u32 axi_read_zynq(                      // Initiate a read operation on the AXI4-Lite bus. Read data is returned.
               u32 axi_devsel      //   Select AXI4-Lite slave that is target of operation
             , u32 axi_addr        //   Select target register within the selected core
             , u32 exp_enab        //   Choose whether to use data expander
             , u32 exp_dir         //   Determine expander direction
             , char *s             //   Comment to be printed in trace message
             )
{
  char call_args[1024];
  u32 read_FA;
  u32 resp;
  u32 rdata;
  int saved_TRC_CONFIG;
  char s_err[1024];
  char s_devstat[1044];
 
  sprintf(call_args,"devsel %s, addr %s (h%8.8X),                  exp_enab %s, exp_dir %s, <%s>",
    axi_devsel_as_str(axi_devsel), axi_addr_as_str(axi_devsel,axi_addr), axi_addr, exp_enab_as_str(exp_enab), exp_dir_as_str(exp_dir), s); 

  if (TRC_AXI == TRC_ON) printf("trace    axi_read      %s\n", call_args); 

  // Step 1: config_write to FLASH_ADDR initiating AXI read
  config_write(CFG_FLASH_ADDR, form_FLASH_ADDR(axi_devsel, axi_addr, FA_RD, exp_enab, exp_dir), 4, "axi_read  - step 1: write to FLASH_ADDR to initiate AXI read");

  // Step 2a: config_read's to poll on Read Strobe to see when it is finished. Print trace msg on only the first one to avoid cluttering output
  saved_TRC_CONFIG = TRC_CONFIG;
  do  
  { read_FA = config_read(CFG_FLASH_ADDR, "axi_read  - step 2: wait for Read Strobe to become 0 indicating AXI read is complete");
    TRC_CONFIG = 0;  // After 1st poll, stop printing lower level msgs. Reduces clutter, plus doesn't multi-count config_read ops when timing isn't real
  } while ((read_FA & FA_RD) == FA_RD);    // Continue while Read Strobe is 1
  TRC_CONFIG = saved_TRC_CONFIG;           // Restore trace setting

  // Step 2b: Check Read Response and Device Specific Status
  resp = (read_FA & FA_RD_RESP_FIELD);
  if (resp != FA_RD_RESP_OK) {
    ERRORS_DETECTED++;
    switch (resp)
    { case FA_RD_RESP_OK     : sprintf(s_err,"SUCCESSFUL    "); break; 
      case FA_RD_RESP_RSVD   : sprintf(s_err,"RESERVED      "); break;
      case FA_RD_RESP_SLVERR : sprintf(s_err,"SLAVE_ERROR   "); break;
      case FA_RD_RESP_INVLD  : sprintf(s_err,"INVALID SELECT"); break;
      default                : sprintf(s_err,"<UNKNOWN>     "); 
    }
    printf("(axi_read): %s:  *** ERROR - detected bad response on axi_read of %s (h%8x) ***\n", call_args, s_err, resp);
  }
  //sprintf(s_devstat,"(axi_read): %s ", call_args);
  snprintf(s_devstat, sizeof(s_devstat), "(axi_read): %s ", call_args);

  // Step 4: Read returned data
  rdata = config_read(CFG_FLASH_DATA, "axi_read  - step 3: retrieve data from FLASH_DATA register");

  if (TRC_AXI == TRC_ON) printf("trace    axi_read completion   (rdata h%8x)\n", rdata); 

  return rdata;
}

u32 read_ICAP_reg(u32 reg_addr)
{
  u32 rdata;

  rdata = axi_read(FA_ICAP, reg_addr, FA_EXP_OFF, FA_EXP_0123, "reading selected ICAP reg");
  printf("Read data %x\n", rdata);
  return rdata;
}

void write_ICAP_reg(u32 reg_addr, u32 wdata)
{
  printf("Writing data %x\n", wdata);
  axi_write(FA_ICAP, reg_addr, FA_EXP_OFF, FA_EXP_0123, wdata, "writing selected ICAP reg");
  return;
}

void reset_ICAP()
{
  write_ICAP_reg(FA_ICAP_CR, 0x00000008);
  write_ICAP_reg(FA_ICAP_CR, 0x00000000);
  return;
}

u32 wait_ICAP_write_done()
{
  u32 rdata;
  int i = 0;
  int maxcount = 1000;
  //write_ICAP_reg(FA_ICAP_CR,0x00000001);
  for(i=0;i<=maxcount;i++) {
    rdata = read_ICAP_reg(FA_ICAP_CR);
    if(((rdata & 0x00000001) == 0x00000001) && (i >= maxcount)) {
      ERRORS_DETECTED++;
      printf("ERROR: poll of ICAP write data drain timed out\n");
    }
    else if((rdata & 0x00000001) == 0x00000000) {
      return 0;
    }
  }
  return 1; //return error

}

void write_ICAP_bitstream_word(u32 wdata)
{
  write_ICAP_reg(FA_ICAP_SZ, 0x00000001);
  write_ICAP_reg(FA_ICAP_WF,wdata);
  write_ICAP_reg(FA_ICAP_CR,0x00000001);
}

u32 read_ICAP_wfifo_size()
{
  u32 rdata;

  rdata = read_ICAP_reg(FA_ICAP_WFV);
  return rdata;
}

// --------------------------------------------------------------------------------------------------------
void read_ICAP_regs()    // Read and display all AXI readable registers in HWICAP core
{ u32 rdata;
  printf("\n (read_ICAP_regs): ---- Display all HWICAP register readable via AXI bus ----\n");

  rdata = axi_read(FA_ICAP, FA_ICAP_GIER, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP GIER   = h%8x  (RW) Global Interrupt Enable Register \n", FA_ICAP_GIER, rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_ISR , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP ISR    = h%8x  (RW) IP Interrupt Status Register     \n", FA_ICAP_ISR , rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_IER , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP IER    = h%8x  (RW) IP Interrupt Enable Register     \n", FA_ICAP_IER , rdata);

//rdata = axi_read(FA_ICAP, FA_ICAP_WF  , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
//printf("(h%4x) ICAP WF     = h%8x  (WO) Write FIFO Keyhole Register      \n", FA_ICAP_WF  , rdata);
  printf("(h%4x) ICAP WF     = not_read   (WO) Write FIFO Keyhole Register      \n", FA_ICAP_WF);

  rdata = axi_read(FA_ICAP, FA_ICAP_RF  , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP RF     = h%8x  (RO) Read FIFO Keyhole Register       \n", FA_ICAP_RF  , rdata);

//rdata = axi_read(FA_ICAP, FA_ICAP_SZ  , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
//printf("(h%4x) ICAP SZ     = h%8x  (WO) Size Register                    \n", FA_ICAP_SZ  , rdata);
  printf("(h%4x) ICAP SZ     = not_read   (WO) Size Register                    \n", FA_ICAP_SZ);

  rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP CR     = h%8x  (RW) Control Register                 \n", FA_ICAP_CR  , rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP SR     = h%8x  (RO) Status Register                  \n", FA_ICAP_SR  , rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_WFV , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP WFV    = h%8x  (RO) Write FIFO Vacancy Register      \n", FA_ICAP_WFV , rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_RFO , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP RFO    = h%8x  (RO) Read FIFO Occupancy Register     \n", FA_ICAP_RFO , rdata);

  rdata = axi_read(FA_ICAP, FA_ICAP_ASR , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) ICAP ASR    = h%8x  (RO) Abort Status Register            \n", FA_ICAP_ASR , rdata);

  printf("\n");
  return;
}


// Read IDCODE certify the exact type of the FPGA
void read_FPGA_IDCODE()
{
  u32 wdata, wdatatmp, rdata, burst_size;
  u32 CR_Write_clear = 0, CR_Write_cmd = 1, SR_ICAPEn_EOS=5;
  u32 SZ_Read_One_Word = 1, CR_Read_cmd = 2, RFO_wait_rd_done=1;

//==============================================

  //printf("Read IDCODE from AXI_HWICAP                      \n");

  rdata = 0;
  while (rdata != SR_ICAPEn_EOS)  {
     rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
     //printf("Waiting for ICAP SR = 5 \e[1A\n");
  }
  wdata = 0xFFFFFFFF;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0x000000BB;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0x11220044;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0xFFFFFFFF;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0xAA995566;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0x20000000;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0x28018001;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  wdata = 0x20000000;
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");
  // flush
  axi_write(FA_ICAP, FA_ICAP_CR, FA_EXP_OFF, FA_EXP_0123, CR_Write_cmd, "ICAP: write CR (initiate bitstream writing)");
  rdata = 0;
  while (rdata != 0x0000003F) {
    rdata = axi_read(FA_ICAP, FA_ICAP_WFV  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read WFV (monitor ICAPEn)");
    //printf("waiting for WFV - h%x\t.", rdata);
  }

  axi_write(FA_ICAP, FA_ICAP_SZ, FA_EXP_OFF, FA_EXP_0123, SZ_Read_One_Word, "ICAP: write SZ ");
  rdata = 1;
  while (rdata != CR_Write_clear) {
     rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read CR (monitor ICAPEn)");
     //printf("Waiting for ICAP CR = 0 (actual =  h%x)\e[1A\n", rdata);
  }

  axi_write(FA_ICAP, FA_ICAP_CR, FA_EXP_OFF, FA_EXP_0123, CR_Read_cmd, "ICAP: Read cmd ");
  rdata = 0;
  while (rdata != RFO_wait_rd_done) {
     rdata = axi_read(FA_ICAP, FA_ICAP_RFO  , FA_EXP_OFF, FA_EXP_0123, "ICAP: poll RFO until read completed");
     //printf("Waiting for ICAP RFO = 1 \e[1A           \n");
  }

  rdata = axi_read(FA_ICAP, FA_ICAP_RF , FA_EXP_OFF, FA_EXP_0123, "ICAP: read FIFO");

  //find IDCODE of ultracsale in UG570 and of zync in UG1085
  if      (rdata == 0x14b39093) printf("Read IDCODE from AXI_HWICAP is 0x%x = VU3P  (AD9V3) \n", rdata);
  else if (rdata == 0x14b69093) printf("Read IDCODE from AXI_HWICAP is 0x%x = VU33P (AD9H3) \n", rdata);
  else if (rdata == 0x14b79093) printf("Read IDCODE from AXI_HWICAP is 0x%x = VU33P (AD9H7) \n", rdata);
  else if (rdata == 0x14758093) printf("Read IDCODE from AXI_HWICAP is 0x%x = ZU18EG (250SOC) \n", rdata);
  else                         printf("Read IDCODE from AXI_HWICAP is 0x%x (see UG570 or UG1085 \n", rdata);

 // End of IDCODE read
//==============================================

  return;
}


// --------------------------------------------------------------------------------------------------------
void read_QSPI_regs()    // Read and display all AXI readable registers in Quad SPI core
{ u32 rdata;
  printf("\n (read_QSPI_regs): ---- Display all Quad SPI (QSPI) register readable via AXI bus ----\n");

//rdata = axi_read(FA_QSPI, FA_QSPI_SRR   , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
//printf("(h%4x) QSPI SRR    = h%8x  (WO)    Software Reset Register                 \n", FA_QSPI_SRR   , rdata);
  printf("(h%4x) QSPI SRR    = not_read   (WO)    Software Reset Register                 \n", FA_QSPI_SRR);

  rdata = axi_read(FA_QSPI, FA_QSPI_SPICR , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI SPICR  = h%8x  (RW)    SPI Control Register                    \n", FA_QSPI_SPICR , rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_SPISR , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI SPISR  = h%8x  (RO)    SPI Status Register                     \n", FA_QSPI_SPISR , rdata);

//rdata = axi_read(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
//printf("(h%4x) QSPI SPIDTR = h%8x  (WO)    SPI Data Transmit Register              \n", FA_QSPI_SPIDTR, rdata);
  printf("(h%4x) QSPI SPIDTR = not_read   (WO)    SPI Data Transmit Register              \n", FA_QSPI_SPIDTR);

//rdata = axi_read(FA_QSPI, FA_QSPI_SPIDRR, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
//printf("(h%4x) QSPI SPIDRR = h%8x  (RO)    SPI Data Receive Register               \n", FA_QSPI_SPIDRR, rdata);
  printf("(h%4x) QSPI SPIDRR = not_read   (RO)    SPI Data Receive Register (issues SLAVE_ERROR if read when empty)\n", FA_QSPI_SPIDRR);

  rdata = axi_read(FA_QSPI, FA_QSPI_SPISSR, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI SPISSR = h%8x  (RW)    SPI Slave Select Register               \n", FA_QSPI_SPISSR, rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_TXFIFO, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI TXFIFO = h%8x  (RO)    Transmit FIFO Occupancy Register        \n", FA_QSPI_TXFIFO, rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_RDFIFO, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI RDFIFO = h%8x  (RO)    Receive FIFO Occupancy Register         \n", FA_QSPI_RDFIFO, rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_DGIER , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI DGIER  = h%8x  (RW)    Device Global Interrupt Enable Register \n", FA_QSPI_DGIER , rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_IPISR , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI IPISR  = h%8x  (R/TOW) IP Interrupt Status Register            \n", FA_QSPI_IPISR , rdata);

  rdata = axi_read(FA_QSPI, FA_QSPI_IPIER , FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");
  printf("(h%4x) QSPI IPIER  = h%8x  (RW)    IP Interrupt Enable Register            \n", FA_QSPI_IPIER , rdata);

  printf("\n");
  return;
}




// --------------------------------------------------------------------------------------------------------
// Setup QSPI registers for 9V3 board usage
//   per Quad SPI spec (pg153-axi-quad-spi.pdf, section "Protocol Description", sub-section "Dual/Quad SPI Mode Transactions"
void QSPI_setup()
{ u32           axi_wdata;  // AXI4-Lite data bus width is 4 bytes
  u32           axi_rdata;
//  unsigned char rdata[];      // use malloc to allocate arrays of bytes to write and read into QSPI DTR and DRR buffers
//  unsigned char wdata[];

  // SRR (Software Reset Register) [Write only]
  // - Reset core to start
  axi_wdata = 0x0000000A;
  axi_write(FA_QSPI, FA_QSPI_SRR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "QSPI_setup: write SRR (reset core to start)");

  // Issue axi_read to any register to provide delay for reset (need 16 cycles minimum for reset to take effect, assume this takes more time than that)
  axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, "QSPI_setup: axi_read provides delay, allowing QSPI core to reset");

  // DGIER (Device Global Interrupt Enable Register)
  // -    [31] Global Interrupt Enable (0 = disabled)
  // - [30: 0] Reserved
  axi_wdata = 0x00000000;
  axi_write(FA_QSPI, FA_QSPI_DGIER, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "QSPI_setup: write DGIER  (disable global interrupt)");

  // IPIER (IP Interrupt Enable Register)
  // - [31:14] Reserved
  // -    [13] Command Error
  // -    [12] Loop Back Error
  // -    [11] MSB Error
  // -    [10] Slave Mode Error
  // -    [ 9] CPOL_CPHA Error
  // -    [ 8] DRR_Not_Empty (no meaning in Quad mode)
  // -    [ 7] Slave_Select_Mode (no meaning in Quad mode)
  // -    [ 6] TX FIFO Half Empty
  // -    [ 5] DRR Overrun
  // -    [ 4] DRR Full
  // -    [ 3] DTR Underrun
  // -    [ 2] DTR Empty
  // -    [ 1] Slave MODF
  // -    [ 0] Mode Fault Error
  // - Set all bits to 0 to disable interrupt generation for the condition.
  axi_wdata = 0x00000000;
  axi_write(FA_QSPI, FA_QSPI_IPIER, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "QSPI_setup: write IPIER  (disable all interrupts)");

  // IPISR (IP Interrupt Status Register) - Clear any pending flags
  axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, "QSPI_setup: read  IPISR  (see what error flags are set before writing DTR)");
  axi_write(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, axi_rdata, "QSPI_setup: write back IPISR  (clear all error flags before writing DTR)");
  axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, "QSPI_setup: read  IPISR  (check error flags are clear before writing DTR)");
  if (axi_rdata != 0x00000000) {
    ERRORS_DETECTED++;
    printf("(QSPI_setup):  *** ERROR - IPISR is remains non-zero after clearing procedure (h%8x) ***\n", axi_rdata);
  }

  return;
}

// --------------------------------------------------------------------------------------------------------
char* flash_devsel_as_str(u32 flash_devsel)  // Convert FLASH device select value to string for nicer printing
{ if (flash_devsel == SPISSR_SEL_DEV1) return "DEV1";
  if (flash_devsel == SPISSR_SEL_DEV2) return "DEV2";
  if (flash_devsel == SPISSR_SEL_NONE) return "NONE";

  ERRORS_DETECTED++;
  printf("(flash_devsel_as_str): ***ERROR - unrecognized flash_devsel (h%8x) ***\n", flash_devsel);
  return "<UNKNOWN>";
}



// --------------------------------------------------------------------------------------------------------
char* fo_dir_as_str(int dir)  // Convert flash_op direction value to string for nicer printing
{ if (dir == FO_DIR_XCHG) return "XCHG ";
  if (dir == FO_DIR_RD  ) return "READ ";
  if (dir == FO_DIR_WR  ) return "WRITE";

  ERRORS_DETECTED++;
  printf("(fo_dir_as_str): ***ERROR - unrecognized direction (%d) ***\n", dir);
  return "<UNKNOWN>";
}



// --------------------------------------------------------------------------------------------------------
void fo_wait_for_DTR_FIFO_empty()  // Wait for IPISR[2] to become 1 indicating DTR FIFO has been emptied (all bytes sent to the FLASH)
{
  const int maxloops = 5;       // Timeout waiting for FLASH to respond to operation

  int  i;
  int  saved_TRC_AXI;
  int  saved_TRC_CONFIG;
  u32  axi_rdata;
  u32  axi_wdata;
  int  debug = 0;             // 0 = normal, 1 = add more print msgs
  char ds[1024];

  i = 0;
  saved_TRC_AXI    = TRC_AXI;
  saved_TRC_CONFIG = TRC_CONFIG;
  do {
      i++;
      sprintf(ds, "flash_op-fo_wait_for_DTR_FIFO_empty: read  IPISR  (wait for [2] to become 1 meaning DTR FIFO is empty - iteration %d", i);
      axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, ds);
      TRC_AXI    = 0;  // Disable printing of subsequent iterations, want only one AXI_RD msg for this step
      TRC_CONFIG = 0;  // Disable printing of subsequent iterations, want only config msgs for one AXI_RD msg for this step
  } while (i < maxloops && ((axi_rdata & 0x00000004) == 0x00000000) );  // iterate while [2] = 0
  TRC_AXI    = saved_TRC_AXI;
  TRC_CONFIG = saved_TRC_CONFIG;
  if (i == maxloops) {
    ERRORS_DETECTED++;
    printf("(flash_op-fo_wait_for_DTR_FIFO_empty):  *** ERROR - Poll of IPISR[2] waiting for DTR Empty interrupt exceeded max loop iterations (%d) ***\n", maxloops);
  } else {
    if (debug == 1) printf("flash_op-fo_wait_for_DTR_FIFO_empty: DTR FIFO is empty after iteration %d, continue\n", i);
    sprintf(ds, "flash_op-fo_wait_for_DTR_FIFO_empty: write IPISR  (clear [2] to prepare for next write to DTR FIFO - after poll iteration %d", i);
    axi_wdata = 0x00000004;  // Clear bit [2] from 1 to 0 by writing to toggle it
    axi_write(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, ds);
  }
  return;
}



// --------------------------------------------------------------------------------------------------------
void fo_read_DRR(                     // Obtain shifted out data. Check that RX FIFO remains not empty for the correct number of data bytes.
                  byte *drr_data      // Pointer to buffer that will hold DRR contents when function is complete
                , int   load_bytes    // Number of bytes to read from DRR
                , int   dir           // Skip some steps based on the direction of the FLASH operation (FO_DIR_XCHG, FO_DIR_RD, FO_DIR_WR)
                )
{
  u32 axi_rdata;
  int i;
  int remaining_bytes;
  int debug = 0;             // 0 = normal, 1 = add more print msgs
  char ds[1024];

  if ((dir == FO_DIR_XCHG || dir == FO_DIR_RD) || (dir == FO_DIR_WR && FLASH_OP_CHECK == FO_CHK_ON)) {
    remaining_bytes = load_bytes;
    i = 0;    // pointer into return data array
    while (remaining_bytes > 0) {

      if (FLASH_OP_CHECK == FO_CHK_ON) {
        // Check RX FIFO remains not empty
        axi_rdata = axi_read(FA_QSPI, FA_QSPI_SPISR, FA_EXP_OFF, FA_EXP_0123, "flash_op-fo_read_DRR: read  SPISR  (confirm RX FIFO still has a byte, [0] should be 0)");
        if ((axi_rdata & 0x00000001) != 0x00000000) {   // bit [0] != 0
          ERRORS_DETECTED++;
          printf("(flash_op-fo_read_DRR):  *** ERROR - SPISR[0]=1 indicating RX FIFO Empty before reading data byte [%d] of [%d]\n", i, load_bytes-1);
        }
      }

      if (remaining_bytes >= 4) {   // Read 4 bytes at a time using Byte Expander
        sprintf(ds, "flash_op-fo_read_DRR: read SPIDRR (get byte %3d to %3d from RX FIFO)", i, i+3);
        axi_rdata = axi_read(FA_QSPI, FA_QSPI_SPIDRR, FA_EXP_ON, FA_EXP_3210, ds);
        *(drr_data+i  ) = (byte) ((axi_rdata & 0xFF000000) >> 24);
        *(drr_data+i+1) = (byte) ((axi_rdata & 0x00FF0000) >> 16);
        *(drr_data+i+2) = (byte) ((axi_rdata & 0x0000FF00) >>  8);
        *(drr_data+i+3) = (byte) ((axi_rdata & 0x000000FF)      );
        if (debug == 1) printf("flash_op-fo_read_DRR: SPIDRR = h%8X, drr_data[%3d to %3d] = h%2X %2X %2X %2X\n",  axi_rdata, i, i+3,
          *(drr_data+i), *(drr_data+i+1), *(drr_data+i+2), *(drr_data+i+3) );
        remaining_bytes = remaining_bytes - 4;      // Reduce count of bytes to read yet
        i = i + 4;                                  // Point to next free byte location in drr_data
      }
      else {   // less than 4 bytes left, so read one byte at a time
        sprintf(ds, "flash_op-fo_read_DRR: read SPIDRR (get byte %3d from RX FIFO)", i);
        axi_rdata = axi_read(FA_QSPI, FA_QSPI_SPIDRR, FA_EXP_OFF, FA_EXP_3210, ds);    // Byte expander is off
        *(drr_data+i) = (byte) (axi_rdata & 0x000000FF);
        if (debug == 1) printf("flash_op-fo_read_DRR: SPIDRR = h%8X, drr_data[%3d] = h%2X\n",  axi_rdata, i, *(drr_data+i));
        remaining_bytes = remaining_bytes - 1;      // Reduce count of bytes to read yet
        i = i + 1;                                  // Point to next free byte location in drr_data
      }
    }   // while (remaining_bytes > 0)

    if (FLASH_OP_CHECK == FO_CHK_ON) {
      // Check that RX FIFO is empty now
      axi_rdata = axi_read(FA_QSPI, FA_QSPI_SPISR, FA_EXP_OFF, FA_EXP_0123, "flash_op-fo_read_DRR: read  SPISR  (confirm RX FIFO is empty after reading the expected number of data bytes)");
      if ((axi_rdata & 0x00000001) != 0x00000001) {   // bit [0] != 1
        ERRORS_DETECTED++;
        printf("(flash_op-fo_read_DRR):  *** ERROR - SPISR[0]=0 indicating RX FIFO is not Empty after all %d bytes were read\n", load_bytes);
      }
    }

  }  // ((dir == FO_DIR_XCHG || dir == FO_DIR_RD) || (dir == FO_DIR_WR && FLASH_OP_CHECK == FO_CHK_ON))
  else {
    // On an unchecked FLASH write, the shifted out data is ignored. Therefore skip reading DRR FIFO and fill in return array with h00.
    if (debug == 1) printf("flash_op-fo_read_DRR: Skipping read of DRR FIFO, returning h00 in all bytes\n");
    for (i=0; i < load_bytes; i++) {
       *(drr_data+i) = 0x00;
    }
  }

  return;
}



// --------------------------------------------------------------------------------------------------------
// FLASH OPeration
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
             )
{
  int  debug = 0;                // Internal debug. 0=no debug msgs, 1=some debug msgs, 2=all debug msgs

  u32  axi_wdata, axi_rdata;
  int  i, j;

  byte header_array[16];                  // 1 cmd + 3 addr + 10 dummy (max) + pad with first few data bytes
                                          //   Why 16? It is the minimum DTR FIFO size in the Quad SPI core. Also it is a multiple of 4 which
                                          //   allows config_write operations to use the Byte Expander to send 4 bytes at a time to the DTR FIFO.
  int  header_bytes;                      // Number of bytes in header_array to send
  int  header_ptr;                        // Index into header_array
  int  remaining_header_bytes;            // Number of free bytes remaining in header array

  int  wdata_ptr, rdata_ptr;              // Index into wdata/rdata arrays where next byte should be written
  int  remaining_total_bytes;             // Total number of bytes remaining to be sent to FLASH
  int  remaining_fifo_bytes;              // Number of bytes remaining to be sent in this iteration of loading/sending the DTR FIFO

  int  fifo_bytes;                        // How many bytes have been written into the DTR FIFO

  char ds[4096], ds_elt[10];              // buffer for debug traces

  byte drr_data[FIFO_DEPTH];              // Temporary storage for data captured by DRR FIFO after shift to FLASH
  int  drr_ptr;                           // Pointer into 'drr_data'
  int  skip_bytes;                        // Number of bytes to skip over which contain shift out from cmd, addr, dummy cycles

  if (TRC_FLASH == TRC_ON) {
    // Save arguments as a string for easier printing later
    snprintf(ds, sizeof(ds),
	     "devsel %s, cmd h%2X, addr h%8X, num_addr %2d, num_dummy %2d, num_bytes %d, dir %s <%s>",
	     flash_devsel_as_str(devsel), cmd, addr, num_addr, num_dummy,
	     num_bytes, fo_dir_as_str(dir), s);
    printf("trace  flash_op        %s\n", ds);
  }

  if (TRC_FLASH == TRC_ON) {
    // Create printable string of write data (up to first 16 bytes)
    if (num_bytes <= 16)
      j = num_bytes;
    else
      j = 16;
    ds[0] = '\0';
    for (i = 0; i < j; i++) {
      snprintf(ds_elt, sizeof(ds_elt), "%2.2X ", wdata[i]);
      strcat(ds, ds_elt);
    }
    if (num_bytes > 16)
      strcat(ds, "...");
    printf("trace  flash_op          (hex) wdata[] = %s\n", ds);
  }

  // Check validity of arguements
  if (num_addr > 4) {
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_addr (%d) is not in the range 0,1,2,3,4 ***\n", num_addr);
    return;   // ABORT
  }
  if (num_dummy > 10) {  // For Micron FLASH, largest number of dummy cycles is 10
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_dummy (%d) is not in the range 0 through 10 inclusive ***\n", num_dummy);
    return;   // ABORT
  }
  if (num_bytes < 0) {
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_bytes (%d) is less than 0 ***\n", num_bytes);
    return;   // ABORT
  }

  // Activate device select for targeted device
  axi_wdata = devsel;
  axi_write(FA_QSPI, FA_QSPI_SPISSR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPISSR (activate device select for targeted device)");

  // SPICR (SPI Control Register) - default h180, [8]=disable master transactions, [6:5]=reset RX,TX FIFOs, [2]=master config, [1]=SPI enable
  axi_wdata = 0x00000166;  // {22'b0,10'b01_0110_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  (Reset RX & TX FIFOs)");

  // SPICR (SPI Control Register) - [6:5]=unreset RX,TX FIFOs
  axi_wdata = 0x00000106;  // {22'b0,10'b01_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  (Remove reset from RX & TX FIFOs)");

  // If all works properly, IPISR[2] (DTR Empty) should be 0 after FIFO reset
  if (FLASH_OP_CHECK == FO_CHK_ON) {
    axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, "flash_op: read  IPISR  (check bit [2] (DTR Empty) is 0 after FIFO reset)");
    if ((axi_rdata & 0x00000004) != 0x00000000) {  // If [2] of [31:0] is not set
      ERRORS_DETECTED++;
      printf("(flash_op):  *** ERROR - IPISR[2] (DTR Empty) was set after FIFO reset (h%8x) ***\n", axi_rdata);
      axi_write(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, (axi_rdata & 0x00000004), "flash_op: write IPISR  (clear bit [2] (DTR Empty) before continuing)");
    }
  }

  //printf("Flash op checkpoint 1\n");
  // Assemble header array containing cmd, addr, dummy cycles, and data to pad it
  header_array[0] = cmd;
  switch (num_addr)
    { case 0: header_ptr = 1;
              break;
      case 1: header_array[1] = (byte)  (addr & 0x000000FF);               // Cast to byte to reduce from 32 bits to 8 bits
              header_ptr = 2;
              break;
      case 2: header_array[1] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[2] = (byte)  (addr & 0x000000FF);
              header_ptr = 3;
              break;
      case 3: header_array[1] = (byte) ((addr & 0x00FF0000) >> 16);
              header_array[2] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[3] = (byte)  (addr & 0x000000FF);
              header_ptr = 4;
              break;
      case 4: header_array[1] = (byte) ((addr & 0xFF000000) >> 24);
              header_array[2] = (byte) ((addr & 0x00FF0000) >> 16);
              header_array[3] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[4] = (byte)  (addr & 0x000000FF);
              header_ptr = 5;
              break;
      default: ERRORS_DETECTED++;   // Shouldn't happen if argument check above is in place
               printf("(flash_op):  *** ERROR - num_addr (%d) is not in the range 0,1,2,3,4 ***\n", num_addr);
               return;   // ABORT
    }
  for (i = 0; i < num_dummy; i++) {   // Fill dummy cycles with pad bytes
    header_array[header_ptr] = 0x00;
    header_ptr++;
  }
  wdata_ptr = 0;                                // Initialize data array pointers
  remaining_header_bytes = 16 - header_ptr;     // Determine amount of space left in header
  if (num_bytes <= remaining_header_bytes) {    // There is room in the header for all data bytes (i.e. cmd has 1 byte of data)
    for (i=0; i < num_bytes; i++) {             // Copy all data into header array
      header_array[header_ptr] = *(wdata + wdata_ptr);
      header_ptr++;
      wdata_ptr++;
    }
    header_bytes = header_ptr;
    remaining_total_bytes = 0;                  // There are no more data bytes to send (overall)
    remaining_fifo_bytes  = 0;                  // There are no more data bytes to send (to fill the FIFO on this iteration)
  }
  else {                                                           // There is more data to send than remains in the header.
    for (i=0; i < remaining_header_bytes; i++) {                   // Fill up the remaining space in the header array with data.
      header_array[header_ptr] = *(wdata + wdata_ptr);
      header_ptr++;
      wdata_ptr++;
    }
    header_bytes = header_ptr;
    remaining_total_bytes = num_bytes  - remaining_header_bytes;   // Number of bytes to send yet (overall)
    remaining_fifo_bytes  = FIFO_DEPTH - header_bytes;             // Number of bytes to send yet (to fill the FIFO on this iteration)
  }
  if (debug >= 1) {   // print header_array
    ds[0] = '\0';
    for (i = 0; i < header_ptr; i++) {
      snprintf(ds_elt, sizeof(ds_elt), "%2.2X ", header_array[i]);
      strcat(ds, ds_elt);
    }
    printf("flash_op (debug): header_ptr = %d, wdata_ptr = %d, header_bytes = %d, remaining_total_bytes = %d, remaining_fifo_bytes = %d\n",
	   header_ptr, wdata_ptr, header_bytes, remaining_total_bytes, remaining_fifo_bytes);
    printf("flash_op (debug): header_array[0:%d] = %s\n", header_bytes-1, ds);
  }

  // With Slave Select off, write first set of bytes, containing header and as many additional data as DTR FIFO can hold
  for (i=0; (i+3) < header_bytes; i=i+4) {  // Load groups of 4 bytes first from header array
    axi_wdata = (header_array[i] << 24) | (header_array[i+1] << 16) | (header_array[i+2] << 8) | header_array[i+3];
    sprintf(ds,"flash_op: write SPIDTR  (header_array[%d:%d])", i, i+3);
    axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
  }
  while (i < header_bytes) {                // Load individual bytes that may remain in header array
    axi_wdata = 0x00000000 | header_array[i];
    sprintf(ds,"flash_op: write SPIDTR  (header_array[%d])", i);
    axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
    i++;
  }
  fifo_bytes = i;  // Note: max size of header_array = 16 which is smallest DTR FIFO allowed, so no risk of overrun when loading header
  if (debug >= 2) printf("flash_op (debug) - (at A) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
  while (remaining_total_bytes > 0 && remaining_fifo_bytes > 0) {   // Fill FIFO with as much remaining data as possible
    if (remaining_total_bytes >= 4 && remaining_fifo_bytes >= 4) {
      axi_wdata = (*(wdata+wdata_ptr) << 24) | (*(wdata+wdata_ptr+1) << 16) | (*(wdata+wdata_ptr+2) << 8) | *(wdata+wdata_ptr+3);
      sprintf(ds,"flash_op: write SPIDTR  (wdata[%d:%d])", wdata_ptr, wdata_ptr+3);
      axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
      wdata_ptr             = wdata_ptr + 4;
      remaining_total_bytes = remaining_total_bytes - 4;
      remaining_fifo_bytes  = remaining_fifo_bytes  - 4;
      fifo_bytes            = fifo_bytes + 4;
    }
    else {   // less than 4 bytes to send or less than 4 bytes in DTR FIFO
      axi_wdata = 0x00000000 | wdata[wdata_ptr];
      sprintf(ds,"flash_op: write SPIDTR  (wdata[%d])", wdata_ptr);
      axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
      wdata_ptr++;
      remaining_total_bytes--;
      remaining_fifo_bytes--;
      fifo_bytes++;
    }
    if (debug >= 2) printf("flash_op (debug) - (at B) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
  }

  //printf("Flash op checkpoint 2\n");
  // Instruct QSPI to send DTR contents to FLASH
  // SPICR (SPI Control Register) - enable Master to drive SPI (starts CCLK and transfer) by disabling Master Transaction Inhibit (bit [8])
  axi_wdata = 0x00000006;  // {22'b0,10'b00_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  ([8]=0 to enable master to drive SPI)");

  // Wait for DTR contents to be transferred. When complete, DRR FIFO contains shifted out bytes.
  fo_wait_for_DTR_FIFO_empty();

  // Read specified number of bytes from DRR FIFO
  fo_read_DRR(drr_data, fifo_bytes, dir);

  // Transfer read bytes to return array, removing cmd, addr, and dummy bytes as needed
  rdata_ptr  = 0;              // Initialize array pointer (once at first time reading DRR FIFO)
  drr_ptr    = 0;              // Initialize array pointer (every time fo_read_DRR() is called)
  skip_bytes = 1 + num_addr + (num_dummy/2);   // Ignore the first bytes returned if they are for (cmd, addr, dummy) cycles
    // IMPORTANT: The assumption is dummy cycles only occur on bulk data movement which will use Quad mode on the SPI bus. This means
    //            every dummy cycle captures 4 bits from the FLASH, so 2 cycles equal a byte. Furthermore it assumes num_dummy will
    //            be an even number, which from the Micron spec appears to be true in all cases. If dummy cycles are used with non-Quad SPI
    //            commands, then another solution needs to be found; like determining the number of dummy bytes from a look up table
    //            based on the 'cmd' value (which is how the Quad SPI IP core does it).
  drr_ptr    = skip_bytes;
  for (i = skip_bytes; i < fifo_bytes; i++) {       // Starting with first real data byte, copy read byts into the return data array
    *(rdata + rdata_ptr) = *(drr_data + drr_ptr);
    if (debug >= 2) printf("flash_op (debug): DATA COPY (header) - rdata_ptr (%d) h%2X, drr_ptr (%d) h%2X\n",
      rdata_ptr, *(rdata+rdata_ptr), drr_ptr, *(drr_data+drr_ptr) );
    rdata_ptr++;
    drr_ptr++;
  }

  // while (remaining_total_bytes > 0),
  while (remaining_total_bytes > 0) {
    if (debug >= 2) printf("flash_op (debug) - (at C) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
    remaining_fifo_bytes = FIFO_DEPTH;   // Clear counts relative to the FIFO
    fifo_bytes = 0;
    while (remaining_total_bytes > 0 && remaining_fifo_bytes > 0) {   // Fill FIFO with as much remaining data as possible
      if (remaining_total_bytes >= 4 && remaining_fifo_bytes >= 4) {
        axi_wdata = (*(wdata+wdata_ptr) << 24) | (*(wdata+wdata_ptr+1) << 16) | (*(wdata+wdata_ptr+2) << 8) | *(wdata+wdata_ptr+3);
        sprintf(ds,"flash_op: write SPIDTR  (wdata[%d:%d])", wdata_ptr, wdata_ptr+3);
        axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
        wdata_ptr             = wdata_ptr + 4;
        remaining_total_bytes = remaining_total_bytes - 4;
        remaining_fifo_bytes  = remaining_fifo_bytes  - 4;
        fifo_bytes            = fifo_bytes + 4;
      }
      else {   // less than 4 bytes to send or less than 4 bytes in DTR FIFO
        axi_wdata = 0x00000000 | wdata[wdata_ptr];
        sprintf(ds,"flash_op: write SPIDTR  (wdata[%d])", wdata_ptr);
        axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
        wdata_ptr++;
        remaining_total_bytes--;
        remaining_fifo_bytes--;
        fifo_bytes++;
      }
    }
    if (debug >= 2) printf("flash_op (debug) - (at D) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);

    // Instruct QSPI to send DTR contents to FLASH  (SKIP THIS STEP AFTER THE FIRST FIFO FILL)
    // SPICR (SPI Control Register) - enable Master to drive SPI (starts CCLK and transfer) by disabling Master Transaction Inhibit (bit [8])

    // Wait for DTR contents to be transferred. When complete, DRR FIFO contains shifted out bytes.
    fo_wait_for_DTR_FIFO_empty();

    // Read specified number of bytes from DRR FIFO
    fo_read_DRR(drr_data, fifo_bytes, dir);

    // Transfer read bytes to return array, removing cmd, addr, and dummy bytes as needed
    drr_ptr = 0;      // Initialize array pointer (every time fo_read_DRR() is called)
    for (i = 0; i < fifo_bytes; i++) {       // Append read bytes into the return data array
      *(rdata + rdata_ptr) = *(drr_data + drr_ptr);
      if (debug >= 2) printf("flash_op (debug): DATA COPY (block data) - rdata_ptr (%d) h%2X, drr_ptr (%d) h%2X\n",
        rdata_ptr, *(rdata+rdata_ptr), drr_ptr, *(drr_data+drr_ptr) );
      rdata_ptr++;
      drr_ptr++;
    }

  } // while (remaining_total_bytes > 0) {

  //printf("Flash op checkpoint 3\n");
  // At this point, all data is transferred, return the QSPI core back to an inactive state, awaiting the next command

  // SPICR (SPI Control Register) - disable master transactions
  axi_wdata = 0x00000106;  // {22'b0,10'b01_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  ([8]=1 to disable master transactions)");

  // When no more data to this device, disable chip select
  axi_wdata = SPISSR_SEL_NONE;
  axi_write(FA_QSPI, FA_QSPI_SPISSR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPISSR (disable all chip selects)");

  if (TRC_FLASH == TRC_ON) {
    // Create printable string of read data
    if (num_bytes <= 16)
      j = num_bytes;
    else
      j = 16;
    strcpy(ds, "rdata (hex)");
    for (i = 0; i < j; i++) {
      snprintf(ds_elt, sizeof(ds_elt), " %2.2X", *(rdata+i));
      strcat(ds, ds_elt);
    }
    printf("trace  flash_op        %s\n\n", ds);
  }

  FLASH_OP_COUNT++;    // Bump FLASH operation count

  //printf("Flash op checkpoint 4\n");
  return;
}


// --------------------------------------------------------------------------------------------------------
// FLASH OPeration
void flash_op_verbose(                      // The SPI interface shifts data in while simultaneously shifting data out, thus "read" is the same as a "write".
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
             )
{
  int  debug = 0;                // Internal debug. 0=no debug msgs, 1=some debug msgs, 2=all debug msgs

  u32  axi_wdata, axi_rdata;
  int  i, j;

  byte header_array[16];                  // 1 cmd + 3 addr + 10 dummy (max) + pad with first few data bytes
                                          //   Why 16? It is the minimum DTR FIFO size in the Quad SPI core. Also it is a multiple of 4 which
                                          //   allows config_write operations to use the Byte Expander to send 4 bytes at a time to the DTR FIFO.
  int  header_bytes;                      // Number of bytes in header_array to send
  int  header_ptr;                        // Index into header_array
  int  remaining_header_bytes;            // Number of free bytes remaining in header array

  int  wdata_ptr, rdata_ptr;              // Index into wdata/rdata arrays where next byte should be written
  int  remaining_total_bytes;             // Total number of bytes remaining to be sent to FLASH
  int  remaining_fifo_bytes;              // Number of bytes remaining to be sent in this iteration of loading/sending the DTR FIFO

  int  fifo_bytes;                        // How many bytes have been written into the DTR FIFO

  char call_args[1024];                   // Buffers for easier printing
  char ds[4096], ds_elt[10];

  byte drr_data[FIFO_DEPTH];              // Temporary storage for data captured by DRR FIFO after shift to FLASH
  int  drr_ptr;                           // Pointer into 'drr_data'
  int  skip_bytes;                        // Number of bytes to skip over which contain shift out from cmd, addr, dummy cycles

  // Save arguments as a string for easier printing later
  sprintf(call_args,"devsel %s, cmd h%2X, addr h%8X, num_addr %2d, num_dummy %2d, num_bytes %d, dir %s <%s>",
    flash_devsel_as_str(devsel), cmd, addr, num_addr, num_dummy, num_bytes, fo_dir_as_str(dir), s);

  if (TRC_FLASH == TRC_ON) {
    // Create printable string of write data (up to first 16 bytes)
    if (num_bytes <= 16)
      j = num_bytes;
    else
      j = 16;
    ds[0] = '\0';
    for (i = 0; i < j; i++) {
      snprintf(ds_elt, sizeof(ds_elt), "%2.2X ", wdata[i]);
      strcat(ds, ds_elt);
    }
    if (num_bytes > 16)
      strcat(ds, "...");
    printf("trace  flash_op          (hex) wdata[] = %s\n", ds);
  }

  // Check validity of arguements
  if (num_addr > 4) {
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_addr (%d) is not in the range 0,1,2,3,4 ***\n", num_addr);
    return;   // ABORT
  }
  if (num_dummy > 10) {  // For Micron FLASH, largest number of dummy cycles is 10
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_dummy (%d) is not in the range 0 through 10 inclusive ***\n", num_dummy);
    return;   // ABORT
  }
  if (num_bytes < 0) {
    ERRORS_DETECTED++;
    printf("(flash_op):  *** ERROR - num_bytes (%d) is less than 0 ***\n", num_bytes);
    return;   // ABORT
  }

  printf("Flash OP checkpoint 1: About to do FPGA axi ops\n");
  // Activate device select for targeted device
  axi_wdata = devsel;
  axi_write(FA_QSPI, FA_QSPI_SPISSR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPISSR (activate device select for targeted device)");

  // SPICR (SPI Control Register) - default h180, [8]=disable master transactions, [6:5]=reset RX,TX FIFOs, [2]=master config, [1]=SPI enable
  axi_wdata = 0x00000166;  // {22'b0,10'b01_0110_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  (Reset RX & TX FIFOs)");

  // SPICR (SPI Control Register) - [6:5]=unreset RX,TX FIFOs
  axi_wdata = 0x00000106;  // {22'b0,10'b01_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  (Remove reset from RX & TX FIFOs)");

  printf("Flash OP checkpoint 2: Got through first axi writes OK\n");

  // If all works properly, IPISR[2] (DTR Empty) should be 0 after FIFO reset
  if (FLASH_OP_CHECK == FO_CHK_ON) {
    axi_rdata = axi_read(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, "flash_op: read  IPISR  (check bit [2] (DTR Empty) is 0 after FIFO reset)");
    if ((axi_rdata & 0x00000004) != 0x00000000) {  // If [2] of [31:0] is not set
      ERRORS_DETECTED++;
      printf("(flash_op):  *** ERROR - IPISR[2] (DTR Empty) was set after FIFO reset (h%8x) ***\n", axi_rdata);
      axi_write(FA_QSPI, FA_QSPI_IPISR, FA_EXP_OFF, FA_EXP_0123, (axi_rdata & 0x00000004), "flash_op: write IPISR  (clear bit [2] (DTR Empty) before continuing)");
    }
  }

  printf("Flash OP checkpoint 3: Got through DTR empty check OK\n");

  //printf("Flash op checkpoint 1\n");
  // Assemble header array containing cmd, addr, dummy cycles, and data to pad it
  header_array[0] = cmd;
  switch (num_addr)
    { case 0: header_ptr = 1;
              break;
      case 1: header_array[1] = (byte)  (addr & 0x000000FF);               // Cast to byte to reduce from 32 bits to 8 bits
              header_ptr = 2;
              break;
      case 2: header_array[1] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[2] = (byte)  (addr & 0x000000FF);
              header_ptr = 3;
              break;
      case 3: header_array[1] = (byte) ((addr & 0x00FF0000) >> 16);
              header_array[2] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[3] = (byte)  (addr & 0x000000FF);
              header_ptr = 4;
              break;
      case 4: header_array[1] = (byte) ((addr & 0xFF000000) >> 24);
              header_array[2] = (byte) ((addr & 0x00FF0000) >> 16);
              header_array[3] = (byte) ((addr & 0x0000FF00) >>  8);
              header_array[4] = (byte)  (addr & 0x000000FF);
              header_ptr = 5;
              break;
      default: ERRORS_DETECTED++;   // Shouldn't happen if argument check above is in place
               printf("(flash_op):  *** ERROR - num_addr (%d) is not in the range 0,1,2,3,4 ***\n", num_addr);
               return;   // ABORT
    }
  for (i = 0; i < num_dummy; i++) {   // Fill dummy cycles with pad bytes
    header_array[header_ptr] = 0x00;
    header_ptr++;
  }
  wdata_ptr = 0;                                // Initialize data array pointers
  remaining_header_bytes = 16 - header_ptr;     // Determine amount of space left in header
  if (num_bytes <= remaining_header_bytes) {    // There is room in the header for all data bytes (i.e. cmd has 1 byte of data)
    for (i=0; i < num_bytes; i++) {             // Copy all data into header array
      header_array[header_ptr] = *(wdata + wdata_ptr);
      header_ptr++;
      wdata_ptr++;
    }
    header_bytes = header_ptr;
    remaining_total_bytes = 0;                  // There are no more data bytes to send (overall)
    remaining_fifo_bytes  = 0;                  // There are no more data bytes to send (to fill the FIFO on this iteration)
  }
  else {                                                           // There is more data to send than remains in the header.
    for (i=0; i < remaining_header_bytes; i++) {                   // Fill up the remaining space in the header array with data.
      header_array[header_ptr] = *(wdata + wdata_ptr);
      header_ptr++;
      wdata_ptr++;
    }
    header_bytes = header_ptr;
    remaining_total_bytes = num_bytes  - remaining_header_bytes;   // Number of bytes to send yet (overall)
    remaining_fifo_bytes  = FIFO_DEPTH - header_bytes;             // Number of bytes to send yet (to fill the FIFO on this iteration)
  }
  if (debug >= 1) {   // print header_array
    ds[0] = '\0';
    for (i = 0; i < header_ptr; i++) {
      snprintf(ds_elt, sizeof(ds_elt), "%2.2X ", header_array[i]);
      strcat(ds, ds_elt);
    }
    printf("flash_op (debug): header_ptr = %d, wdata_ptr = %d, header_bytes = %d, remaining_total_bytes = %d, remaining_fifo_bytes = %d\n",
	   header_ptr, wdata_ptr, header_bytes, remaining_total_bytes, remaining_fifo_bytes);
    printf("flash_op (debug): header_array[0:%d] = %s\n", header_bytes-1, ds);
  }

  printf("Flash OP checkpoint 4: Got through Bus calculations OK\n");

  // With Slave Select off, write first set of bytes, containing header and as many additional data as DTR FIFO can hold
  for (i=0; (i+3) < header_bytes; i=i+4) {  // Load groups of 4 bytes first from header array
    axi_wdata = (header_array[i] << 24) | (header_array[i+1] << 16) | (header_array[i+2] << 8) | header_array[i+3];
    sprintf(ds,"flash_op: write SPIDTR  (header_array[%d:%d])", i, i+3);
    axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
  }
  while (i < header_bytes) {                // Load individual bytes that may remain in header array
    axi_wdata = 0x00000000 | header_array[i];
    sprintf(ds,"flash_op: write SPIDTR  (header_array[%d])", i);
    axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
    i++;
  }
  printf("Flash OP checkpoint 5: Loaded bytes into header array OK\n");
  fifo_bytes = i;  // Note: max size of header_array = 16 which is smallest DTR FIFO allowed, so no risk of overrun when loading header
  if (debug >= 2) printf("flash_op (debug) - (at A) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
  while (remaining_total_bytes > 0 && remaining_fifo_bytes > 0) {   // Fill FIFO with as much remaining data as possible
    if (remaining_total_bytes >= 4 && remaining_fifo_bytes >= 4) {
      axi_wdata = (*(wdata+wdata_ptr) << 24) | (*(wdata+wdata_ptr+1) << 16) | (*(wdata+wdata_ptr+2) << 8) | *(wdata+wdata_ptr+3);
      sprintf(ds,"flash_op: write SPIDTR  (wdata[%d:%d])", wdata_ptr, wdata_ptr+3);
      axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
      wdata_ptr             = wdata_ptr + 4;
      remaining_total_bytes = remaining_total_bytes - 4;
      remaining_fifo_bytes  = remaining_fifo_bytes  - 4;
      fifo_bytes            = fifo_bytes + 4;
    }
    else {   // less than 4 bytes to send or less than 4 bytes in DTR FIFO
      axi_wdata = 0x00000000 | wdata[wdata_ptr];
      sprintf(ds,"flash_op: write SPIDTR  (wdata[%d])", wdata_ptr);
      axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
      wdata_ptr++;
      remaining_total_bytes--;
      remaining_fifo_bytes--;
      fifo_bytes++;
    }
    if (debug >= 2) printf("flash_op (debug) - (at B) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
  }
  printf("Flash OP checkpoint 6: Finished loading DTR Fifo OK\n");
  //printf("Flash op checkpoint 2\n");
  // Instruct QSPI to send DTR contents to FLASH
  // SPICR (SPI Control Register) - enable Master to drive SPI (starts CCLK and transfer) by disabling Master Transaction Inhibit (bit [8])
  axi_wdata = 0x00000006;  // {22'b0,10'b00_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  ([8]=0 to enable master to drive SPI)");

  printf("Flash OP checkpoint 7: Waiting for DTR empty\n");
  // Wait for DTR contents to be transferred. When complete, DRR FIFO contains shifted out bytes.
  fo_wait_for_DTR_FIFO_empty();

  printf("Flash OP checkpoint 8: Reading back from DRR Fifo\n");
  // Read specified number of bytes from DRR FIFO
  fo_read_DRR(drr_data, fifo_bytes, dir);

  // Transfer read bytes to return array, removing cmd, addr, and dummy bytes as needed
  rdata_ptr  = 0;              // Initialize array pointer (once at first time reading DRR FIFO)
  drr_ptr    = 0;              // Initialize array pointer (every time fo_read_DRR() is called)
  skip_bytes = 1 + num_addr + (num_dummy/2);   // Ignore the first bytes returned if they are for (cmd, addr, dummy) cycles
    // IMPORTANT: The assumption is dummy cycles only occur on bulk data movement which will use Quad mode on the SPI bus. This means
    //            every dummy cycle captures 4 bits from the FLASH, so 2 cycles equal a byte. Furthermore it assumes num_dummy will
    //            be an even number, which from the Micron spec appears to be true in all cases. If dummy cycles are used with non-Quad SPI
    //            commands, then another solution needs to be found; like determining the number of dummy bytes from a look up table
    //            based on the 'cmd' value (which is how the Quad SPI IP core does it).
  drr_ptr    = skip_bytes;
  for (i = skip_bytes; i < fifo_bytes; i++) {       // Starting with first real data byte, copy read byts into the return data array
    *(rdata + rdata_ptr) = *(drr_data + drr_ptr);
    if (debug >= 2) printf("flash_op (debug): DATA COPY (header) - rdata_ptr (%d) h%2X, drr_ptr (%d) h%2X\n",
      rdata_ptr, *(rdata+rdata_ptr), drr_ptr, *(drr_data+drr_ptr) );
    rdata_ptr++;
    drr_ptr++;
  }

  printf("Flash OP checkpoint 9: About to do drain DRR fifo\n");

  while (remaining_total_bytes > 0) {
    if (debug >= 2) printf("flash_op (debug) - (at C) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);
    remaining_fifo_bytes = FIFO_DEPTH;   // Clear counts relative to the FIFO
    fifo_bytes = 0;
    while (remaining_total_bytes > 0 && remaining_fifo_bytes > 0) {   // Fill FIFO with as much remaining data as possible
      if (remaining_total_bytes >= 4 && remaining_fifo_bytes >= 4) {
        axi_wdata = (*(wdata+wdata_ptr) << 24) | (*(wdata+wdata_ptr+1) << 16) | (*(wdata+wdata_ptr+2) << 8) | *(wdata+wdata_ptr+3);
        sprintf(ds,"flash_op: write SPIDTR  (wdata[%d:%d])", wdata_ptr, wdata_ptr+3);
        axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_ON, FA_EXP_3210, axi_wdata, ds);
        wdata_ptr             = wdata_ptr + 4;
        remaining_total_bytes = remaining_total_bytes - 4;
        remaining_fifo_bytes  = remaining_fifo_bytes  - 4;
        fifo_bytes            = fifo_bytes + 4;
      }
      else {   // less than 4 bytes to send or less than 4 bytes in DTR FIFO
        axi_wdata = 0x00000000 | wdata[wdata_ptr];
        sprintf(ds,"flash_op: write SPIDTR  (wdata[%d])", wdata_ptr);
        axi_write(FA_QSPI, FA_QSPI_SPIDTR, FA_EXP_OFF, FA_EXP_3210, axi_wdata, ds);
        wdata_ptr++;
        remaining_total_bytes--;
        remaining_fifo_bytes--;
        fifo_bytes++;
      }
    }
    if (debug >= 2) printf("flash_op (debug) - (at D) remaining_total_bytes = %d, remaining_fifo_bytes = %d\n", remaining_total_bytes, remaining_fifo_bytes);

    // Instruct QSPI to send DTR contents to FLASH  (SKIP THIS STEP AFTER THE FIRST FIFO FILL)
    // SPICR (SPI Control Register) - enable Master to drive SPI (starts CCLK and transfer) by disabling Master Transaction Inhibit (bit [8])

    // Wait for DTR contents to be transferred. When complete, DRR FIFO contains shifted out bytes.
    fo_wait_for_DTR_FIFO_empty();

    // Read specified number of bytes from DRR FIFO
    fo_read_DRR(drr_data, fifo_bytes, dir);

    // Transfer read bytes to return array, removing cmd, addr, and dummy bytes as needed
    drr_ptr = 0;      // Initialize array pointer (every time fo_read_DRR() is called)
    for (i = 0; i < fifo_bytes; i++) {       // Append read bytes into the return data array
      *(rdata + rdata_ptr) = *(drr_data + drr_ptr);
      if (debug >= 2) printf("flash_op (debug): DATA COPY (block data) - rdata_ptr (%d) h%2X, drr_ptr (%d) h%2X\n",
        rdata_ptr, *(rdata+rdata_ptr), drr_ptr, *(drr_data+drr_ptr) );
      rdata_ptr++;
      drr_ptr++;
    }

  } // while (remaining_total_bytes > 0)
  printf("Flash OP checkpoint 10: Finished DRR drain\n");
  //printf("Flash op checkpoint 3\n");
  // At this point, all data is transferred, return the QSPI core back to an inactive state, awaiting the next command

  // SPICR (SPI Control Register) - disable master transactions
  axi_wdata = 0x00000106;  // {22'b0,10'b01_0000_0110};
  axi_write(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPICR  ([8]=1 to disable master transactions)");

  printf("Flash OP checkpoint 11: Finished write SPICR\n");

  // When no more data to this device, disable chip select
  axi_wdata = SPISSR_SEL_NONE;
  axi_write(FA_QSPI, FA_QSPI_SPISSR, FA_EXP_OFF, FA_EXP_0123, axi_wdata, "flash_op: write SPISSR (disable all chip selects)");

  printf("Flash OP checkpoint 12: Finished write SPISSR\n");

  if (TRC_FLASH == TRC_ON) {
    // Create printable string of read data
    if (num_bytes <= 16)
      j = num_bytes;
    else
      j = 16;
    strcpy(ds, "rdata (hex)");
    for (i = 0; i < j; i++) {
      snprintf(ds_elt, sizeof(ds_elt), " %2.2X", *(rdata+i));
      strcat(ds, ds_elt);
    }
    printf("trace  flash_op        %s\n\n", ds);
  }
  printf("Flash OP checkpoint 15: Finished debug\n");
  FLASH_OP_COUNT++;    // Bump FLASH operation count
  printf("Flash OP checkpoint 16: Finished op increment\n");
  //printf("Flash op checkpoint 4\n");
  printf("Flash OP checkpoint 17: Finished!\n");
  return;
}

// --------------------------------------------------------------------------------------------------------
void flash_setup(u32 devsel)   // Setup selected FLASH for 9V3 board usage (pass in SPISSR_SEL_DEV1 or SPISSR_SEL_DEV2)
{
  char call_args[1024];        // Buffers for easier printing
  byte rbyte;

  // Save arguments as a string for easier printing later
  sprintf(call_args,"devsel %s", flash_devsel_as_str(devsel));

  if (TRC_FLASH_CMD == TRC_ON) printf("flash_setup: Start - %s\n", call_args);

  // Reset FLASH by performing RESET ENABLE, followed by RESET MEMORY
  fw_Reset_Enable(devsel);
  fw_Reset_Memory(devsel);
  fw_Write_Enable(devsel); // Collin Nov 18th, add this for 9H3 card 4-byte addressing set
  fw_Enter_4B_Adress_Mode(devsel); //rblack must enter 4B address mode for any modern fpga/flash size.
#ifdef USE_SIM_TO_TEST
  // Workaround for sim. Per Kevin Roth at AlphaData, pull up inside Micron part avoids need to do this.
  WORKAROUND_FORCE_DQ(devsel);
#endif

  // Set bit to disable interpretting at DQ3/DQ7 as RESET#, allows write ops to chain together without resetting in between
  // Note: This may only be needed in simulation, but can't hurt to do in hardware also.
  rbyte = fr_Enhanced_Volatile_Configuration_Register(devsel);
  fw_Write_Enable(devsel);
  fw_Enhanced_Volatile_Configuration_Register(devsel, (rbyte & 0xEF));  // Set [4] Reset/hold = 0 (disabled)
  rbyte = fr_Enhanced_Volatile_Configuration_Register(devsel);
  if ((rbyte & 0x10) != 0x00) {
    ERRORS_DETECTED++;
    printf("(flash_setup):  *** ERROR - Write of Enhanced Volatile Configuration Register bit [4] to 0 failed (%s) ***\n", call_args);
  }

#ifdef USE_SIM_TO_TEST
  // Remove sim workaround
  WORKAROUND_RELEASE_DQ(devsel);
#endif

  if (TRC_FLASH_CMD == TRC_ON) printf("flash_setup: End   - %s\n", call_args);

  return;
}



// --------------------------------------------------------------------------------------------------------
void fr_wait_for_WRITE_IN_PROGRESS_to_clear(u32 devsel)     // Wait for 'WRITE IN PROGRESS' status bit to return to not busy state
{
  const int maxloops = 1000000;   // Number of iterations to try before timeout error

  int  debug = 0;              // 0=no iteration msgs, 1 = print msg on each iteration
  char call_args[1024];        // Buffers for easier printing
  byte rbyte;
  int  i;

  int  saved_TRC_FLASH_CMD;
  int  saved_TRC_FLASH;
  int  saved_TRC_AXI;
  int  saved_TRC_CONFIG;

  // Save arguments as a string for easier printing later
  sprintf(call_args,"devsel %s", flash_devsel_as_str(devsel));

  if (TRC_FLASH_CMD == TRC_ON) printf("fr_wait_for_WRITE_IN_PROGRESS_to_clear: Begin polling for STATUS[0] to become 0 on %s\n", call_args);

  saved_TRC_FLASH_CMD = TRC_FLASH_CMD;
  saved_TRC_FLASH     = TRC_FLASH;
  saved_TRC_AXI       = TRC_AXI;
  saved_TRC_CONFIG    = TRC_CONFIG;
  rbyte = 0x01;
  i = 0;
  while (i++ < maxloops && ((rbyte & 0x01) == 0x01) ) {    // Wait for IPISR[0] to become 0 indicating write is not in progress
    rbyte = fr_Status_Register(devsel);
    TRC_FLASH_CMD = TRC_OFF;           // Disable lower level tracing after first iteration
    TRC_FLASH     = TRC_OFF;
    TRC_AXI       = TRC_OFF;
    TRC_CONFIG    = TRC_OFF;
    if (debug) printf("fr_wait_for_WRITE_IN_PROGRESS_to_clear: Poll loop iteration %d, rbyte = %2.2X\n", i, rbyte);
  }

  TRC_FLASH_CMD = saved_TRC_FLASH_CMD; // Restore trace levels
  TRC_FLASH     = saved_TRC_FLASH;
  TRC_AXI       = saved_TRC_AXI;
  TRC_CONFIG    = saved_TRC_CONFIG;

  if (i >= maxloops) {
    ERRORS_DETECTED++;
    printf("fr_wait_for_WRITE_IN_PROGRESS_to_clear:  *** ERROR - Timeout, maximum iteration loops (%d) executed on %s ***\n", i, call_args);
  }
  else {
    if (TRC_FLASH_CMD) printf("fr_wait_for_WRITE_IN_PROGRESS_to_clear: (done) Found STATUS[0]=0 (Write In Progress is READY) after %d iterations\n", i);
  }

  return;
}



// --------------------------------------------------------------------------------------------------------
void read_flash_regs(u32 devsel)    // Read all registers in the targeted FLASH (pass in SPISSR_SEL_DEV1 or SPISSR_SEL_DEV2)
{
  byte rbyte;
  byte rary[20];
  u32  ru32;
  char ds[1024], ds_elt[10];
  int i;
  int saved_TRC_FLASH_CMD;

  saved_TRC_FLASH_CMD = TRC_FLASH_CMD;
  TRC_FLASH_CMD = TRC_OFF;   // prevent register read calls from printing msgs

  printf("read_flash_regs: ----- Display all readable FLASH registers in device %s -----\n", flash_devsel_as_str(devsel) );

  rbyte = fr_Status_Register(devsel);
  printf("   h%2.2X      STATUS REGISTER\n", rbyte);

  rbyte = fr_Flag_Status_Register(devsel);
  printf("   h%2.2X      FLAG STATUS REGISTER\n", rbyte);

  rbyte = fr_Extended_Address_Register(devsel);
  printf("   h%2.2X      EXTENDED ADDRESS REGISTER\n", rbyte);

  ru32  = fr_Nonvolatile_Configuration_Register(devsel);
  printf("   h%2.2X %2.2X   NONVOLATILE CONFIGURATION REGISTER\n", u32tobyte((ru32 & 0x0000FF00) >> 8), u32tobyte(ru32 & 0x000000FF) );

  rbyte = fr_Volatile_Configuration_Register(devsel);
  printf("   h%2.2X      VOLATILE CONFIGURATION REGISTER\n", rbyte);

  rbyte = fr_Enhanced_Volatile_Configuration_Register(devsel);
  printf("   h%2.2X      ENHANCED VOLATILE CONFIGURATION REGISTER\n", rbyte);

  printf("   skipped  READ VOLATILE LOCK BIT REGISTER\n");

  fr_Device_ID_Register(devsel, rary);
  sprintf(ds, "h");
  for (i = 0; i < 20; i++) {
    snprintf(ds_elt, sizeof(ds_elt), " %2.2X", rary[i]);
    strcat(ds, ds_elt);
  }
  printf("            DEVICE ID = %s\n", ds);

  printf("----- (End read_flash_regs) -----\n\n");

  TRC_FLASH_CMD = saved_TRC_FLASH_CMD;
  return;
}



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


byte u32tobyte(u32 x)                   // Simple converter from u32 to byte type
{ return (byte) (x & 0x000000FF);
}



int check_TRC_FLASH_CMD()               // Helper function for read Flash functions
  // Determine if TRC_FLASH_CMD is on, and if so whether lower trace levels are active or not.
  // Use this on 'read' FLASH commands to know whether to print messages before or after 'flash_op' is called.
  // If no lower level trace is on, then defer printing the TRC_FLASH_CMD message until after the read data is available.
  // However if any lower trace msgs will be printed, then print before and after so lower msgs will have a start and end marker.
  // Returns: (0=none are on so suppress begining message, 1=at least one is active so print both start and end messages)
{
  if (TRC_FLASH_CMD == TRC_ON && (TRC_FLASH == TRC_ON || TRC_AXI == TRC_ON || TRC_CONFIG == TRC_ON) ) {
    return 1;
  } else {
    return 0;
  }
}



// --------------------------------------------------------------------------------------------------------
void fw_Reset_Enable(u32 devsel)
{ byte wary[1];
  byte rary[1];
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Reset_Enable: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x66, 0x00000000, 0       , 0        , 0        , wary   , rary   , FO_DIR_WR, "RESET ENABLE");
  return;
}



// --------------------------------------------------------------------------------------------------------
void fw_Reset_Memory(u32 devsel)
{ byte wary[1];
  byte rary[1];
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Reset_Memory: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x99, 0x00000000, 0       , 0        , 0        , wary   , rary   , FO_DIR_WR, "RESET MEMORY");
  return;
}

void fw_Enter_4B_Adress_Mode(u32 devsel)
{ byte wary[1];
  byte rary[1];
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Enter_4B_Address_Mode: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0xB7, 0x00000000, 0       , 0        , 0        , wary   , rary   , FO_DIR_WR, "ENTER 4B ADDR MODE");
return;
}

// --------------------------------------------------------------------------------------------------------
void fw_Write_Enable(u32 devsel)
{ byte wary[1];
  byte rary[1];
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Write_Enable: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x06, 0x00000000, 0       , 0        , 0        , wary   , rary   , FO_DIR_WR, "WRITE ENABLE");
  return;
}



// --------------------------------------------------------------------------------------------------------
byte fr_Enhanced_Volatile_Configuration_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Enhanced_Volatile_Configuration_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x65, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_RD, "READ ENHANCED VOLATILE CONFIGURATION REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Enhanced_Volatile_Configuration_Register: (done) devsel %s, rdata %2.2X\n", flash_devsel_as_str(devsel), rary[0]);
  return rary[0];
}
// --------------------------------------------------------------------------------------------------------
void fw_Enhanced_Volatile_Configuration_Register(u32 devsel, byte wdata)
{ byte wary[1];
  byte rary[1];
  wary[0] = wdata;
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Enhanced_Volatile_Configuration_Register: devsel %s, wdata %2X\n", flash_devsel_as_str(devsel), wdata);
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x61, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_WR, "WRITE ENHANCED VOLATILE CONFIGURATION REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
byte fr_Extended_Address_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Extended_Address_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0xC8, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_RD, "READ EXTENDED ADDRESS REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Extended_Address_Register: (done) devsel %s, rdata %2.2X\n", flash_devsel_as_str(devsel), rary[0]);
  return rary[0];
}
// --------------------------------------------------------------------------------------------------------
void fw_Extended_Address_Register(u32 devsel, byte wdata)
{ byte wary[1];
  byte rary[1];
  wary[0] = wdata;
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Extended_Address_Register: devsel %s, wdata %2X\n", flash_devsel_as_str(devsel), wdata);
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0xC5, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_WR, "WRITE EXTENDED ADDRESS REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
byte fr_Status_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Status_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x05, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_RD, "READ STATUS REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Status_Register: (done) devsel %s, rdata %2.2X\n", flash_devsel_as_str(devsel), rary[0]);
  return rary[0];
}
// --------------------------------------------------------------------------------------------------------
void fw_Status_Register(u32 devsel, byte wdata)
{ byte wary[1];
  byte rary[1];
  wary[0] = wdata;
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Status_Register: devsel %s, wdata %2X\n", flash_devsel_as_str(devsel), wdata);
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x01, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_WR, "WRITE STATUS REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
byte fr_Flag_Status_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Flag_Status_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x70, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_RD, "READ FLAG STATUS REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Flag_Status_Register: (done) devsel %s, rdata %2.2X\n", flash_devsel_as_str(devsel), rary[0]);
  return rary[0];
}
// --------------------------------------------------------------------------------------------------------
void fw_Clear_Flag_Status_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Clear_Flag_Status_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x50, 0x00000000, 0       , 0        , 0        , wary   , rary   , FO_DIR_WR, "CLEAR FLAG STATUS REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
u32 fr_Nonvolatile_Configuration_Register(u32 devsel)
{ byte wary[2];
  byte rary[2];
  u32  retval;
  wary[0] = 0x00;
  wary[1] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Nonvolatile_Configuration_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0xB5, 0x00000000, 0       , 0        , 2        , wary   , rary   , FO_DIR_RD, "READ NONVOLATILE CONFIGURATION REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Nonvolatile_Configuration_Register: (done) devsel %s, rdata %2.2X %2.2X\n", flash_devsel_as_str(devsel), rary[0], rary[1]);
  retval = 0x00000000 | (rary[0] << 8) | rary[1] ;
  return retval;
}
// --------------------------------------------------------------------------------------------------------
void fw_Nonvolatile_Configuration_Register(u32 devsel, u32 wdata)
{ byte wary[2];
  byte rary[2];
  wary[0] = u32tobyte( ((wdata & 0x0000FF00) >> 8) );
  wary[1] = u32tobyte( ((wdata & 0x000000FF)     ) );
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Nonvolatile_Configuration_Register: devsel %s, wdata %2.2X %2.2X\n", flash_devsel_as_str(devsel), wary[0], wary[1]);
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0xB1, 0x00000000, 0       , 0        , 2        , wary   , rary   , FO_DIR_WR, "WRITE NONVOLATILE CONFIGURATION REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
byte fr_Volatile_Configuration_Register(u32 devsel)
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;
  if (check_TRC_FLASH_CMD()) printf("fr_Volatile_Configuration_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x85, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_RD, "READ VOLATILE CONFIGURATION REGISTER");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Volatile_Configuration_Register: (done) devsel %s, rdata %2.2X\n", flash_devsel_as_str(devsel), rary[0]);
  return rary[0];
}
// --------------------------------------------------------------------------------------------------------
void fw_Volatile_Configuration_Register(u32 devsel, byte wdata)
{ byte wary[1];
  byte rary[1];
  wary[0] = wdata;
  if (TRC_FLASH_CMD == TRC_ON) printf("fw_Volatile_Configuration_Register: devsel %s, wdata %2X\n", flash_devsel_as_str(devsel), wdata);
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x81, 0x00000000, 0       , 0        , 1        , wary   , rary   , FO_DIR_WR, "WRITE VOLATILE CONFIGURATION REGISTER");
  return;
}



// --------------------------------------------------------------------------------------------------------
void fr_Device_ID_Register(u32 devsel, byte *rdata)    // 20 bytes of read data stored in buffer whose address is passed in
{ byte wary[20];
  byte rary[20];
  int i;

  for (i=0; i < 20; i++) {
    wary[i] = 0x00;
  }
  if (check_TRC_FLASH_CMD()) printf("fr_Device_ID_Register: devsel %s\n", flash_devsel_as_str(devsel));
  //       devsel  cmd   addr        num_addr, num_dummy, num_bytes, wdata[], rdata[], dir,
  flash_op(devsel, 0x9E, 0x00000000, 0       , 0        , 20       , wary   , rary   , FO_DIR_RD, "READ DEVICE ID REGISTER");
  for (i=0; i < 20; i++) {
    *(rdata + i) = rary[i];
  }
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Device_ID_Register: (done) devsel %s\n", flash_devsel_as_str(devsel));
  return;
}



// --------------------------------------------------------------------------------------------------------
void fw_4KB_Subsector_Erase(u32 devsel, u32 addr)   // 3 byte address
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;

  if (TRC_FLASH_CMD == TRC_ON) printf("fw_4KB_Subsector_Erase: devsel %s, addr %4X\n", flash_devsel_as_str(devsel), addr);
  //       devsel  cmd   addr  num_addr   num_dummy, num_bytes  , wdata[], rdata[], dir      , comment
#ifdef USE_SIM_TO_TEST
  printf("fw_4KB_Subsector_Erase: Skip ERASE cmd when running sim, put back in when running on real hardware (takes too long to run in sim).\n");
  // However from comments from the FLASH model, it looks like the FLASH recognizes and begins to execute the ERASE command properly.
#else
  flash_op(devsel, 0x20, addr, 4        , 0        , 0          , wary   , rary   , FO_DIR_WR, "4KB SUBSECTOR ERASE");
#endif

  return;
}


// --------------------------------------------------------------------------------------------------------
void fw_64KB_Sector_Erase(u32 devsel, u32 addr)   // 3 byte address
{ byte wary[1];
  byte rary[1];
  wary[0] = 0x00;

  if (TRC_FLASH_CMD == TRC_ON) printf("fw_64KB_Sector_Erase: devsel %s, addr %4X\n", flash_devsel_as_str(devsel), addr);
  //       devsel  cmd   addr  num_addr   num_dummy, num_bytes  , wdata[], rdata[], dir      , comment
#ifdef USE_SIM_TO_TEST
  printf("fw_64KB_Sector_Erase: Skip ERASE cmd when running sim, put back in when running on real hardware (takes too long to run in sim).\n");
   // However from comments from the FLASH model, it looks like the FLASH recognizes and begins to execute the ERASE command properly.

#else
  flash_op(devsel, 0xD8, addr, 4        , 0        , 0          , wary   , rary   , FO_DIR_WR, "4KB SUBSECTOR ERASE");
#endif

  return;
}

// --------------------------------------------------------------------------------------------------------
void fr_Read(u32 devsel, u32 addr, int num_bytes, byte *rary)   // 3 byte address
{ byte *wary;
  int i;

  wary = (byte *) malloc(num_bytes * sizeof(byte));
  if (wary == NULL) {
    ERRORS_DETECTED++;
    printf("(fr_Read):  *** ERROR - malloc() call failed. READ operation is skipped. ***\n");
    return;
  }
  for (i=0; i < num_bytes; i++) { wary[i] = 0x00; }  // Clear write data

  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Read: devsel %s, addr %4X, num_bytes %d\n", flash_devsel_as_str(devsel), addr, num_bytes);
  //       devsel  cmd   addr  num_addr , num_dummy, num_bytes, wdata[], rdata[], dir      , comment
  flash_op(devsel, 0x03, addr, 4        , 0        , num_bytes, wary   , rary   , FO_DIR_RD, "READ");

  // Free malloc'd memory
  free(wary);

  return;
}



// --------------------------------------------------------------------------------------------------------
void fw_Page_Program(u32 devsel, u32 addr, int num_bytes, byte *wary)   // 3 byte address
{

  //printf("Entered Page Program Function\n");
  byte *rary;
  //printf("Declared rary\n");
  rary = (byte *) malloc(num_bytes * sizeof(byte));  // Just allocate, no need to initialize as it will overwritten by flash_op
  if (rary == NULL) {
    ERRORS_DETECTED++;
    printf("(fr_Page_Program):  *** ERROR - malloc() call failed. READ operation is skipped. ***\n");
    return;
  }

  //printf("Array alloced\n");
  if (TRC_FLASH_CMD == TRC_ON) printf("fr_Page_Program: devsel %s, addr %4X, num_bytes %d\n", flash_devsel_as_str(devsel), addr, num_bytes);
  //       devsel  cmd   addr  num_addr, num_dummy, num_bytes, wdata[], rdata[], dir      , comment
  flash_op(devsel, 0x02, addr, 4       , 0        , num_bytes, wary   , rary   , FO_DIR_WR, "PAGE PROGRAM");

  //printf("Flash Op page program complete\n");

  //printf("Deallocating array\n");
  // Free malloc'd memory
  free(rary);

  //printf("Free array complete\n");
  //printf("Finished deallocating array\n");

  return;
}







// --------------------------------------------------------------------------------------------------------
// End of test check
void Check_Accumulated_Errors(void)  // Check Global error flag to determine if test passed or failed
{ if (ERRORS_DETECTED == 0)
  {  printf(" No error detected.\n");
     return;
  } else
  {  printf("Check_Accumulated_Errors: #### FAIL #### (%d errors detected)\n", ERRORS_DETECTED);
     return;   // main() only allows value of 0 or 1 as return values
  }
}


#endif
