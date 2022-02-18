/*
 * Copyright 2022 International Business Machines
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

//##################################################################################################################
// INCLUDE

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <math.h>
#include <getopt.h>
#include <stdlib.h>
#include <sys/stat.h>
#include "program_common_defs.h"
#include "program_common_funcs.h"
#include "program_global_vars.h"

//FAB: ??
#ifdef USE_SIM_TO_TEST
//  #include "svdpi.h"
//  extern void CFG_NOP( const char*);
//  extern void CFG_NOP2(const char*, int, int, int*);
#endif


//##################################################################################################################
// MAIN

int main(int argc, char *argv[])
{
  //================================================================================================================
  // Variables

  static int verbose_flag = 0;
  static int dualspi_mode_flag = 1; //default to assume x8 spi programming/loading

  // Structure containing the program parameters names (without the "--") and their corresponding small option names
  // (needed by the getopt_long tool below)
  static struct option long_options[] =
  {
    {"verbose", no_argument,       &verbose_flag, 1},
    {"brief",   no_argument,       &verbose_flag, 0},
    {"singlespi",    no_argument,  &dualspi_mode_flag, 0},
    {"dualspi",      no_argument,  &dualspi_mode_flag, 1},
    {"image_file1",  required_argument, 0, 'a'},
    {"image_file2",  required_argument, 0, 'b'},
    {"devicebdf",    required_argument, 0, 'c'},
    {"startaddr",    required_argument, 0, 'd'},
          {0, 0, 0, 0}
  };

  char binfile[1024];
  char binfile2[1024];
  char cfgbdf[1024];
  char cfg_file[1024];
  int CFG;
  int start_addr=0;
  char temp_addr[256];

  u32 temp;
  int vendor, device, subsys;
  int BIN;
  int i, j;

  char *bin_file_extension = "_partial.bin";

  //================================================================================================================
  // Getting the parameters provided to the program

  while(1) {
    int option_index = 0;
    int c;
    c = getopt_long (argc, argv, "a:b:c:d:",
    long_options, &option_index);

    /* Detect the end of the options. */
    if (c == -1)
      break;

    switch (c)
    {
      case 0:
        /* If this option set a flag, do nothing else now. */
        if (long_options[option_index].flag != 0)
          break;
        printf ("option %s", long_options[option_index].name);
        if (optarg)
          printf (" with arg %s", optarg);
        printf ("\n");
        break;

      case 'a':
        if(verbose_flag)
          printf(" Primary Bitstream: %s\n", optarg);
        strcpy(binfile,optarg);
        break;

      case 'b':
        if(verbose_flag)
          printf(" Secondary Bitstream: %s\n", optarg);
        strcpy(binfile2,optarg);
        break;

      case 'c':
        strcpy(cfgbdf,optarg);
        if(verbose_flag)
          printf(" Target Device: %s\n", cfgbdf);
        break;

      case 'd':
        memcpy(temp_addr,&optarg[2],8);
        start_addr = (int)strtol(temp_addr,NULL,16);
        if(verbose_flag)
          printf(" Start Address (same address for SPIx8 on both parts): %d\n", start_addr);
        break;

      case '?':
        /* getopt_long already printed an error message. */
        break;

      default:
        abort ();
    }
  }

  if(verbose_flag) {
    printf("Verbose in use\n");
    printf("Registers value: TRC_CONFIG = %d, TRC_AXI = %d, TRC_FLASH = %d, TRC_FLASH_CMD = %d\n", TRC_CONFIG, TRC_AXI, TRC_FLASH, TRC_FLASH_CMD);
  }

  //================================================================================================================
  // Checking we have provided a binary file and a target device
  if(binfile[0] == '\0') {
    printf("ERROR: Must supply primary bitstream\n");
    printf("Exiting...\n");
    exit(-1);
  }  
  if(cfgbdf[0] == '\0') {
    printf("ERROR: Must supply target device\n");
    printf("Exiting...\n");
    exit(-1);
  } 

  //================================================================================================================
  // Opening the card config file and getting Vendor, Device & Subsystem IDs of the card
  // FAB: is it possible with lambda user ??
  
  // Building the config file full name
  strcpy(cfg_file,"/sys/bus/pci/devices/");
  strcat(cfg_file,cfgbdf);
  strcat(cfg_file,"/config");

  // Opening the card config file
  if ((CFG = open(cfg_file, O_RDWR)) < 0) {
    printf("Can not open %s\n",cfg_file);
    printf("Exiting...\n");
    exit(-1);
  }
  
  // FAB: ??
  //TODO/FIXME: passing this on to global cfg descriptor
  if ((CFG_FD = open(cfg_file, O_RDWR)) < 0) {
    printf("Can not open %s\n",cfg_file);
    printf("Exiting...\n");
    exit(-1);
  }

  // Getting the Vendor and Device IDs and checking they are valid
  temp = config_read(CFG_DEVID,"Read device id of card");
  vendor = temp & 0xFFFF;
  device = (temp >> 16) & 0xFFFF;
  if ( (vendor != 0x1014) || ( device != 0x062B)) {
    printf("ERROR: This card shouldn't be flashed with this script.\n");
    printf("DEVICE: %x VENDOR: %x\n",device,vendor);
    printf("Exiting...\n");
    exit(-1);
  }

  // Getting the Subsystem ID and checking it is valid
  // Other cards than AD9H3 (0x0667) and AD9H7 (0x0666) are not yet supported by Partial Reconfiguration
  // FAB: it should be better to use a global var contaning the valid Subsystems IDs
  temp = config_read(CFG_SUBSYS,"Read subsys id of card");
  subsys = (temp >> 16) & 0xFFFF;
  if ( (subsys != 0x0667) || (subsys != 0x0666)) {
    printf("ERROR: Only AD9H3 or AD9H7 are supported with Partial Reconfiguration\n");
    printf("Exiting...\n");
    exit(-1);
  }

  if(verbose_flag) {
    printf("Card Infos: Vendor ID = %x, Device ID = %x, SubSystem ID = %x\n", vendor, device, subsys);
  }

// FAB: ??
TRC_FLASH_CMD = TRC_OFF;
TRC_AXI = TRC_OFF;
TRC_CONFIG = TRC_OFF;


  //================================================================================================================
  // Checking the binary file name ends with "_partial.bin" (Partial Reconfiguration dynamic binary file)

  if (! strstr(binfile, bin_file_extension)){
    printf("ERROR: %s is not a Partial Reconfiguration file\n",binfile);
    printf("Its name should end by %s. Please check.\n",bin_file_extension);
    printf("Exiting...\n");
    exit(-1);
  }

  dualspi_mode_flag = 0;

  if(verbose_flag) {
    printf ("Using Partial reconfiguration mode\n"); 
  }

  //================================================================================================================
  // Partial Reconfiguration doing...

  // IMPORTANT:
  // The first access to FA_ICAP will enable the decoupling  mode in the FPGA to isolate the dynamic code
  // After the last PR programming instruction, a read to FA_QSPI will disable the decoupling mode

  // FAB: Variables to move to the right place
  off_t fsize;
  struct stat tempstat;
  int num_package_icap, icap_burst_size, num_burst, num_package_lastburst, dif;
  u32 wdata, wdatatmp, rdata;
  u32 CR_Write_clear = 0, CR_Write_cmd = 1, SR_ICAPEn_EOS=5;
  int percentage = 0;
  int prev_percentage = 1;
  time_t spt, ept;

  //----------------------------------------------------------------------------------------------------------------
  // Opening the partial bin file
  printf("Opening PR bin file: %s\n", binfile);
  if ((BIN = open(binfile, O_RDONLY)) < 0) {
    printf("ERROR: Can not open %s\n",binfile);
    printf("Exiting...\n");
    exit(-1);
  }

  //----------------------------------------------------------------------------------------------------------------
  // fsize = the size (number of bytes) of the bin file
  if (stat(binfile, &tempstat) != 0) {
    fprintf(stderr, "Cannot determine size of %s: %s\n", binfile, strerror(errno));
    printf("Exiting...\n");
    exit(-1);
  } else {
    fsize = tempstat.st_size;
  }

  //----------------------------------------------------------------------------------------------------------------
  // num_package_icap = the number of 32-bits packets we're going to write
  // "(fsize % 4 != 0)" = 1 if fsize is not divided by 4
  // Examples:
  //   if fsize=1, 2 or 3 bytes then num_package_icap=0+1=1 so one not-full packet
  //   if fsize=8 bytes then num_package_icap=2+0=2 so two full packets
  //   if fsize=9 bytes then num_package_icap=2+1=3 so two full packets + one not-full packet
  num_package_icap = fsize/4 + (fsize % 4 != 0);

  //----------------------------------------------------------------------------------------------------------------
  // Waiting for the ICAP to be ready and listening (by reading at the FA_ICAP_SR address and waiting for SR_ICAPEn_EOS answer)
  rdata = 0;
  while (rdata != SR_ICAPEn_EOS) {
    rdata = axi_read(FA_ICAP, FA_ICAP_SR, FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
    if(verbose_flag) {
      printf("Waiting for ICAP EOS set \e[1A\n");
    }
  }
  if(verbose_flag) {
      printf("ICAP EOS done.\n");
      //Fab:??
      read_QSPI_regs();
      read_ICAP_regs();
      read_FPGA_IDCODE();
  }

  //----------------------------------------------------------------------------------------------------------------
  // icap_burst_size = the free size of the WR Fifo (it should be 0x3F) (by reading at FA_ICAP_WFV address)
  icap_burst_size = axi_read(FA_ICAP, FA_ICAP_WFV, FA_EXP_OFF, FA_EXP_0123, "read_ICAP_regs");

  //----------------------------------------------------------------------------------------------------------------
  // num_burst = number of writes (bursts) to do in order to write num_package_icap 32-bits packets into the WR Fifo
  num_burst = num_package_icap / icap_burst_size;

  //----------------------------------------------------------------------------------------------------------------
  // num_package_lastburst = number of packets still to write after writing the first num_burst bursts
  //                       = the number of packets still to write while doing the last burst
  num_package_lastburst = num_package_icap - num_burst * icap_burst_size;

  if(verbose_flag) {
      printf(" Flashing PR bit file of size %ld bytes. Total package: %d. \n",fsize, num_package_icap);
      printf(" Total burst to transfer: %d with burst size of %d. Number of package is last burst: %d.\n", 
            num_burst, icap_burst_size, num_package_lastburst);
  }

  //----------------------------------------------------------------------------------------------------------------
  // Getting the current time (for reporting the time spent to do all bursts at the end)
  spt = time(NULL); 

  //----------------------------------------------------------------------------------------------------------------
  // Writing the first num_burst bursts
  printf("___________________________________________________________________________\n");
  for(i=0;i<num_burst;i++) {

    // Display the percentage of completion
    percentage = (int)(i*100/num_burst);
    if( ((percentage %5) == 0) && (prev_percentage != percentage)) {
       printf("\e[1m  Writing\e[0m partial image code : \e[1m%d\e[0m %% of %d pages                        \r", percentage, num_burst);
       fflush(stdout);
    }

    // Working on 32-bits packet
    for (j=0;j<icap_burst_size;j++) {
      dif = read(BIN,&wdatatmp,4); // Reading a 32-bits (4 bytes) packet from the bin file
      // Reorganize the packet
      //   12345678.9ABCDEFG.HIJKLMNO.PQRSTUVW --> 32bits (4 octets) packet
      //
      //   00000000.00000000.00000000.12345678 --> >>24 & 0xFF
      //   00000000.HIJKLMNO.00000000.00000000 --> <<8 & 0xFF0000
      //   00000000.00000000.9ABCDEFG.00000000 --> >>8 & 0xFF00
      //   PQRSTUVW.00000000.00000000.00000000 --> <<24 & 0xFF000000
      //   --------------------------------------------------
      //   PQRSTUVW.HIJKLMNO.9ABCDEFG.12345678 --> (>>24 & 0xFF) | (<<8 & 0xFF0000) | (>>8 & 0xFF00) | (<24 & 0xFF000000)
      wdata = ((wdatatmp>>24)&0xff) | ((wdatatmp<<8)&0xff0000) | ((wdatatmp>>8)&0xff00) | ((wdatatmp<<24)&0xff000000);
      // Writing the 32-bits packets into the WR Fifo
      axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");

      // Reading at the FA_ICAP_CR address and waiting for CR_Write_clear answer
      rdata = 1;
      while (rdata != CR_Write_clear) {
        rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read CR (monitor ICAPEn)");
      }

      // Waiting for the ICAP to be ready and listening (by reading at the FA_ICAP_SR address and waiting for SR_ICAPEn_EOS answer)
      rdata = 0;
      while (rdata != SR_ICAPEn_EOS) {
        rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
      }
    }

    // Flushing the WR Fifo (by writing CR_Write_cmd to FA_ICAP_CR address)
    axi_write(FA_ICAP, FA_ICAP_CR, FA_EXP_OFF, FA_EXP_0123, CR_Write_cmd, "ICAP: write CR (initiate bitstream writing)");

    // Reading at the FA_ICAP_CR address and waiting for CR_Write_clear answer
    rdata = 1;
    while (rdata != CR_Write_clear) {
      rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read CR (monitor ICAPEn)");
    }

    // Waiting for the ICAP to be ready and listening (by reading at the FA_ICAP_SR address and waiting for SR_ICAPEn_EOS answer)
    rdata = 0;
    while (rdata != SR_ICAPEn_EOS) {
      rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
    }

    prev_percentage = percentage;
  }

  //----------------------------------------------------------------------------------------------------------------
  // Writing the last incomplete burst
  if(verbose_flag) {
    printf("Working on the last burst.\n");
  }

  // Working on the remaining 32-bits packet
  for (i=0;i<num_package_lastburst;i++) {
    dif = read(BIN,&wdatatmp,4); // Reading a 32-bits (4 bytes) packet from the bin file
    // Reorganize the packet
    //   12345678.9ABCDEFG.HIJKLMNO.PQRSTUVW --> 32bits (4 octets) packet
    //
    //   00000000.00000000.00000000.12345678 --> >>24 & 0xFF
    //   00000000.HIJKLMNO.00000000.00000000 --> <<8 & 0xFF0000
    //   00000000.00000000.9ABCDEFG.00000000 --> >>8 & 0xFF00
    //   PQRSTUVW.00000000.00000000.00000000 --> <<24 & 0xFF000000
    //   --------------------------------------------------
    //   PQRSTUVW.HIJKLMNO.9ABCDEFG.12345678 --> (>>24 & 0xFF) | (<<8 & 0xFF0000) | (>>8 & 0xFF00) | (<24 & 0xFF000000)
    wdata = ((wdatatmp>>24)&0xff) | ((wdatatmp<<8)&0xff0000) | ((wdatatmp>>8)&0xff00) | ((wdatatmp<<24)&0xff000000);
    // Writing the 32-bits packets into the WR Fifo
    axi_write(FA_ICAP, FA_ICAP_WF, FA_EXP_OFF, FA_EXP_0123, wdata, "ICAP: write WF (4B to Keyhole Reg)");

    // Reading at the FA_ICAP_CR address and waiting for CR_Write_clear answer
    rdata = 1;
    while (rdata != CR_Write_clear) {
      rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read CR (monitor ICAPEn)");
    }

    // Waiting for the ICAP to be ready and listening (by reading at the FA_ICAP_SR address and waiting for SR_ICAPEn_EOS answer)
    rdata = 0;
    while (rdata != SR_ICAPEn_EOS) {
      rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
    }
  }

  // Flushing the WR Fifo (by writing CR_Write_cmd to FA_ICAP_CR address)
  axi_write(FA_ICAP, FA_ICAP_CR, FA_EXP_OFF, FA_EXP_0123, CR_Write_cmd, "ICAP: write CR (initiate bitstream writing)");

  // Reading at the FA_ICAP_CR address and waiting for CR_Write_clear answer
  rdata = 1;
  while (rdata != CR_Write_clear) {
    rdata = axi_read(FA_ICAP, FA_ICAP_CR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read CR (monitor ICAPEn)");
  }

  // Waiting for the ICAP to be ready and listening (by reading at the FA_ICAP_SR address and waiting for SR_ICAPEn_EOS answer)
  rdata = 0;
  while (rdata != SR_ICAPEn_EOS) {
    rdata = axi_read(FA_ICAP, FA_ICAP_SR  , FA_EXP_OFF, FA_EXP_0123, "ICAP: read SR (monitor ICAPEn)");
  }

  //----------------------------------------------------------------------------------------------------------------
  // Closing the partial bin file
  close(BIN);

  //----------------------------------------------------------------------------------------------------------------
  // The following read is just to remove the decoupling done in FPGA
  rdata = axi_read(FA_QSPI, FA_QSPI_SPICR, FA_EXP_OFF, FA_EXP_0123, "Test axi_read");

  //---------------------------------------------------------------------------------------------------------------- 
  // Reporting the time spent to do all bursts
  ept = time(NULL); 
  ept = ept - spt;
  printf("\e[1m Partial reprogramming  \033[1mcompleted\033[0m ok in   %d seconds\e[0m           \n", (int)ept);
  printf("___________________________________________________________________________\n");

  //---------------------------------------------------------------------------------------------------------------- 
  // End of MAIN section
  return 0;  // Incisive simulator doesn't like anything other than 0 as return value from main() 
}

