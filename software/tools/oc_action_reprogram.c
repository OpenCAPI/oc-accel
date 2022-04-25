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

/*
 * OC-ACCEL dynamic reprograaming tool for a user without any sudo rights
 * This can be used only in Partial Reconfiguration mode meaning
 *  - static code has been flashed by a sudo user using oc-utils/oc-flash-script
 *  - dynamic code has been generated with the same PR code than the static code
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <signal.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <sys/stat.h>

#if !defined(OPENCAPI30)
#include <libcxl.h>
#endif

#include <osnap_internal.h>
#include <libosnap.h>
#include <osnap_global_regs.h>
#include <osnap_hls_if.h>
#include <time.h>
#include <fcntl.h>

static const char* version = GIT_VERSION;
static int verbose = 0;
static FILE* fd_out;

#define VERBOSE0(fmt, ...) do {                                        \
        fprintf(fd_out, fmt, ## __VA_ARGS__);                \
    } while (0)

#define VERBOSE1(fmt, ...) do {                                        \
        if (verbose > 0)                                \
            fprintf(fd_out, fmt, ## __VA_ARGS__);        \
    } while (0)

#define VERBOSE2(fmt, ...) do {                                        \
        if (verbose > 1)                                \
            fprintf(fd_out, fmt, ## __VA_ARGS__);        \
    } while (0)

#define VERBOSE3(fmt, ...) do {                                        \
        if (verbose > 2)                                \
            fprintf(fd_out, fmt, ## __VA_ARGS__);        \
    } while (0)

struct mdev_ctx {
    int loop;           /* Loop Counter */
    int card;           /* Card no (0,1,2,3 */
    void* handle;       /* The snap handle */
    int dt;             /* Delay time in sec (1 sec default) */
    int count;          /* Number of loops to do, (-1) = forever */
    bool daemon;        /* TRUE if forked */
    uint64_t wed;	/* This is a dummy only for attach */
    bool quiet;		/* False or true -q option */
    pid_t pid;
    pid_t my_sid;       /* for sid */
	int mode;	/* See below */
    uint64_t fir[SNAP_M_FIR_NUM];
};

static struct mdev_ctx        master_ctx;

#define MODE_SHOW_ACTION  0x0001
#define MODE_SHOW_NVME    0x0002
#define MODE_SHOW_CARD    0x0004
#define MODE_SHOW_SDRAM   0x0008
#define MODE_SHOW_DMA_ALIGN 0x00010
#define MODE_SHOW_DMA_MIN   0x00020

/*
 * Open AFU Master Device
 */
static void* snap_open (struct mdev_ctx* mctx)
{
    char device[64];
    void* handle = NULL;

    /*
     * ocapi - /dev/ocxl/<afu_name>.<domain>:<bus>:<device>.<function>.<afu_index>
     * Initially support only 1 afu per function per bus. Bus maps to major.
     * E.g. /dev/ocxl/IBM,MEMCPY3.0000:00:00.1.0
     */
    if (mctx->card == 0) {
        snprintf (device, sizeof (device) - 1, "IBM,oc-snap");
    } else {
        snprintf (device, sizeof (device) - 1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", mctx->card);
    }

    VERBOSE3 ("[%s] Enter: %s\n", __func__, device);
    handle = snap_card_alloc_dev (device, 0xffff, 0xffff);
    VERBOSE3 ("[%s] Exit %p\n", __func__, handle);

    if (NULL == handle)
        {
	VERBOSE0 ("Error: Can not open OC-Accel Device: %s\n",
                  device);
	VERBOSE0("  => Make sure an FPGA card with proper OpenCAPI bin and cable is connected\n");
	VERBOSE0("  => Check all cards availability with $SNAP_ROOT/software/tools/oc_find_card -v -AALL\n");
	VERBOSE0("  => Otherwise you might try with \"sudo\" or adjust Root rights\n");
	VERBOSE0("     to set rights, you may permanently: \n");
	VERBOSE0("       create a /etc/udev/rules.d/20-ocaccel.rules file including:\n");
	VERBOSE0("       SUBSYSTEM==\"ocxl\", DEVPATH==\"*/ocxl/IBM,oc-snap*\", MODE=\"666\", RUN=\"/bin/chmod 666 %%S/%\%p/global_mmio_area\" and reboot \n");

    }
    return handle;
}

static void snap_close (struct mdev_ctx* mctx)
{
    int rc = 0;
    VERBOSE3 ("[%s] Enter\n", __func__);

    if (NULL == mctx->handle) {
        rc =  -1;
    } else {
        snap_card_free (mctx->handle);
        mctx->handle = NULL;
    }

    VERBOSE3 ("[%s] Exit %d\n", __func__, rc);
    return;
}


static uint64_t snap_read64 (void* handle, uint32_t addr)
{
    uint64_t reg;
    int rc;

    rc = snap_global_read64 (handle, (uint64_t)addr, &reg);

    if (0 != rc) {
        VERBOSE0 ("[%s] Error Reading MMIO %x\n", __func__, addr);
    }

    return reg;
}

static void snap_write64 (void* handle, uint32_t addr, uint64_t data)
{
    int rc;

    rc = snap_global_write64 (handle, (uint64_t)addr, data);
    //printf("DBG : snap_global_write64 - addr= %lx - data = %lx\n", (uint64_t)addr, data);

    if (0 != rc) {
        VERBOSE3 ("[%s] Error Writing MMIO %x\e", __func__, addr);
    }

    return;
}


static uint32_t snap_read32 (void* handle, uint32_t addr)
{
    uint32_t reg;
    int rc;

    rc = snap_action_read32 (handle, (uint64_t)addr, &reg);
    //printf("DBG : snap_action_read32 - addr = %lx - data = %x\n", (uint64_t)addr, reg);

    if (0 != rc) {
        VERBOSE3 ("[%s] Error Reading MMIO %x\e", __func__, addr);
    }

    return reg;
}


static void snap_write32 (void* handle, uint32_t addr, uint32_t data)
{
    int rc;

    rc = snap_action_write32 (handle, (uint64_t)addr, data);
    //printf("DBG : snap_action_write32 - addr= %lx - data = %x\n", (uint64_t)addr, data);

    if (0 != rc) {
        VERBOSE3 ("[%s] Error Writing MMIO %x\e", __func__, addr);
    }

    return;
}


#define USR_ICAP_WF    0x00000F00	/* */
#define USR_ICAP_RF    0x00000F04	/* */
#define USR_ICAP_SZ    0x00000F08	/* */
#define USR_ICAP_CR    0x00000F0C	/* */
#define USR_ICAP_SR    0x00000F10	/* */
#define USR_ICAP_WFV   0x00000F14	/* */
#define USR_ICAP_RFO   0x00000F18	/* */
#define USR_ICAP_ASR   0x00000F1C	/* */
#define USR_ICAP_ASR   0x00000F1C	/* */

#define GLB_REG_SCR   0x00000010       /* */
#define GLB_REG_PRC   0x00000060       /* */

static int dynamic_reprogramming (void* handle, char *binfile)
{
    int rc = 0;

    //adding specific code for Partial reconfiguration
    // IMPORTANT //
    // For dynamic partial reconfiguration using MMIO (vs oc-utils) you need to 
    //   - enable  decoupling by writing bit 1 in CSR
    //   - disable decoupling by writing bit 0 in CSR
    // The first access to FA_ICAP will enable the decoupling  mode in the FPGA to isolate the dynamic code
    // After the last PR programming instruction, a read to FA_QSPI will disable the decouple mode
  off_t fsize;
  struct stat tempstat;
  int num_package_icap, icap_burst_size, num_burst, num_package_lastburst;
  uint32_t wdata, wdatatmp, rdata;
  uint32_t CR_Write_clear = 0, CR_Write_cmd = 1, SR_ICAPEn_EOS=5;
  int percentage = 0;
  int prev_percentage = 1;
  time_t spt = 0, ept = 0;
  int i, j, BIN;

  // Working on the partial bin file
  //printf("Opening PR bin file: %s\n", binfile);
  if ((BIN = open(binfile, O_RDONLY)) < 0) {
    printf("\e[31mERROR:\033[0m Can not open %s\n",binfile);
    exit(-1);
  }

  if (stat(binfile, &tempstat) != 0) {
    fprintf(stderr, "Cannot determine size of %s: %s\n", binfile, strerror(errno));
    exit(-1);
  } else {
    fsize = tempstat.st_size;
    //printf("Size is %ld\n", fsize);
  }

  num_package_icap = fsize/4 + (fsize % 4 != 0); //reading 32b words
  //printf("package number  is %d\n", num_package_icap);
  //printf("handle is %p\n", handle);
  
  //====== enable the DECOUPLING=======
  snap_write64(handle, GLB_REG_SCR, 0x00000002);
  //====== enable the DECOUPLING=======

//echo "check that ICAP is ready for programming: Expected read value is 0x00000005"
  rdata = 0;
  //printf("Checking ICAP EOS set \n[1A\n");
  while (rdata != SR_ICAPEn_EOS) {
    rdata = snap_read32 (handle, USR_ICAP_SR);
    //printf("Waiting for ICAP EOS set \e[1A\n");
  }

  //printf("ICAP EOS set ok\n"); 

  icap_burst_size = snap_read32 (handle, USR_ICAP_WFV);
  num_burst = num_package_icap / icap_burst_size;
  num_package_lastburst = num_package_icap - num_burst * icap_burst_size;

  //printf(" Flashing PR bit file of size %ld bytes. Total package: %d. \n",fsize, num_package_icap);
  //printf(" Total burst to transfer: %d with burst size of %d. Number of package is last burst: %d.\n",
  //      num_burst, icap_burst_size, num_package_lastburst);

  spt = time(NULL);
  printf("___________________________________________________________________________\n");
  for(i=0;i<num_burst;i++) {
    percentage = (int)(i*100/num_burst);
    if( ((percentage %5) == 0) && (prev_percentage != percentage)) {
       printf("\e[1m  Writing\e[0m partial image code : \e[1m%d\e[0m %% of %d pages                        \r", percentage, num_burst);
       fflush(stdout);
    }
    for (j=0;j<icap_burst_size;j++) {
      read(BIN,&wdatatmp,4);
      wdata = ((wdatatmp>>24)&0xff) | ((wdatatmp<<8)&0xff0000) | ((wdatatmp>>8)&0xff00) | ((wdatatmp<<24)&0xff000000);
      snap_write32 (handle, USR_ICAP_WF, wdata);
      rdata = 1;
      while (rdata != CR_Write_clear) {
        rdata = snap_read32 (handle, USR_ICAP_CR);
      }
      rdata = 0;
      while (rdata != SR_ICAPEn_EOS) {
        rdata = snap_read32 (handle, USR_ICAP_SR);
      }
    }

    // Flush the WR FIFO
    snap_write32 (handle, USR_ICAP_CR, CR_Write_cmd);
    rdata = 1;
    while (rdata != CR_Write_clear) {
      rdata = snap_read32 (handle, USR_ICAP_CR);
    }
    rdata = 0;
    while (rdata != SR_ICAPEn_EOS) {
      rdata = snap_read32 (handle, USR_ICAP_SR);
    }
    prev_percentage = percentage;
  } //end for

  //printf("Working on the last burst.\n");

  for (i=0;i<num_package_lastburst;i++) {
    read(BIN,&wdatatmp,4);
    wdata = ((wdatatmp>>24)&0xff) | ((wdatatmp<<8)&0xff0000) | ((wdatatmp>>8)&0xff00) | ((wdatatmp<<24)&0xff000000);
    snap_write32 (handle, USR_ICAP_WF, wdata);
    rdata = 1;
    while (rdata != CR_Write_clear) {
      rdata = snap_read32 (handle, USR_ICAP_CR);
    }
    rdata = 0;
    while (rdata != SR_ICAPEn_EOS) {
      rdata = snap_read32 (handle, USR_ICAP_SR);
    }
  }
  snap_write32 (handle, USR_ICAP_CR, CR_Write_cmd);
  rdata = 1;
  while (rdata != CR_Write_clear) {
    rdata = snap_read32 (handle, USR_ICAP_CR);
  }
  rdata = 0;
  while (rdata != SR_ICAPEn_EOS) {
    rdata = snap_read32 (handle, USR_ICAP_SR);
  }
  close(BIN);

  //printf("Resetting the decoupling.\n");
  //====== disable the DECOUPLING=======
  snap_write64(handle, GLB_REG_SCR, 0x00000001);
  //====== disable the DECOUPLING=======
  
  ept = time(NULL);
  ept = ept - spt;
  printf("\e[1m Partial reprogramming  \033[1mcompleted\033[0m ok in   %d seconds\e[0m           \n", (int)ept);
  printf("___________________________________________________________________________\n");

//-----------------------
    rc = 0;
    return rc;
}


static void help (char* prog)
{
    printf ("Print Information. Usage: %s [-CvhVd] [-f file] [-i delay]\n"
            "\t-C, --card <num>       Card to use (default 0)\n"
            "\t-V, --version          Print Version number\n"
            "\t-h, --help             This help message\n"
            "\t-q, --quiet            No output at all\n"
            "\t-v, --verbose          verbose mode, up to -vvv\n"
            "\t-a, --partial binary file\n"
            "\n"
            "Example: ./oc_action_reprogram -C5 -a oc_2022_0310_xxx_partial.bin\n"
            "\n", prog);
}

/**
 * Get command line parameters and create the output file.
 */
int main (int argc, char* argv[])
{
    int rc = EXIT_SUCCESS;
    int ch;
    unsigned int i;
    struct mdev_ctx* mctx = &master_ctx;
    char *binfile = NULL;
    uint64_t read_value;
    char *ret;

    fd_out = stdout;        /* Default */

    mctx->handle = NULL;        /* No handle */
    mctx->loop = 0;                /* Start Loop Counter */
    mctx->quiet = false;        /* Default */
    mctx->dt = 1;                /* Default, 1 sec delay time */
    mctx->count = -1;        /* Default, run forever */
    mctx->card = 0;                /* Default, Card 0 */
    mctx->mode = 0;		    /* Default, nothing to watch */
    mctx->daemon = false;        /* Not in Daemon mode */

    for (i = 0; i < SNAP_M_FIR_NUM; i++) {
        mctx->fir[i] = -1;
    }

    rc = EXIT_SUCCESS;

    printf("\e[1m _____________________________________________\033[0m\n");
    printf("\e[1m OC-Accel FPGA code dynamic reprogramming tool \033[0m\n");

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card",      required_argument, NULL, 'C' },
            { "version",   no_argument,           NULL, 'V' },
            { "quiet",     no_argument,           NULL, 'q' },
            { "help",      no_argument,           NULL, 'h' },
            { "verbose",   no_argument,           NULL, 'v' },
            { "mode",      required_argument,     NULL, 'a' },
            { 0,           0,                     NULL,  0  }
        };
        ch = getopt_long (argc, argv, "C:a:Vqhv",
                          long_options, &option_index);

        if (-1 == ch) {
            break;
        }

        switch (ch) {
        case 'C':        /* --card */
            mctx->card = strtol (optarg, (char**)NULL, 0);
            break;

        case 'V':        /* --version */
            printf ("%s\n", version);
            exit (EXIT_SUCCESS);
            break;

        case 'q':        /* --quiet */
            mctx->quiet = true;
            break;

        case 'h':        /* --help */
            help (argv[0]);
            exit (EXIT_SUCCESS);
            break;

        case 'v':        /* --verbose */
            verbose++;
            break;

        case 'a':	/* --input file */
            //strcpy(binfile,optarg);
            binfile = optarg;
            printf("File given is: %s\n", binfile);
            break;

        default:
            help (argv[0]);
            exit (EXIT_FAILURE);
        }
    }

    VERBOSE2 ("[%s] Enter\n", __func__);

    //adding specific code for Partial reconfiguration (partial bit file provided)
    char bit_file_extension[20] = "_partial.bin";
    if (binfile == NULL) {
      printf("no file to open\n");
      printf("Example: ./oc_action_reprogram -C5 -a oc_2022_0310_xxx_partial.bin\n");
      goto __main_exit;
    }

    if (strstr(binfile, bit_file_extension)){
        printf(" File given is a partial bin file.\n");
    }
    else {
        printf("\e[31mERROR:\033[0m File given is NOT a partial bin file\n");
        goto __main_exit;
    }


    mctx->handle = snap_open (mctx);

    if (NULL == mctx->handle) {
        rc = ENODEV;
        goto __main_exit;
    }
    char str[7];
    char answer;
    // read PR code in the FPGA code
    read_value = snap_read64 (mctx->handle, GLB_REG_PRC);
    sprintf(str, "_PR%.3lx", read_value);
 
    // compare with PR code in file name
    ret = strstr(binfile, str);
    if(ret) {
        printf(" PR code match (PR%.3lx). Programming continues safely\n", read_value);
	printf("\e[1m Do you want to continue (y/n): \033[0m");
	scanf (" %c", &answer);
	if (answer == 'y' || answer == 'Y')
        	rc = dynamic_reprogramming(mctx->handle, binfile);

    } else {
        printf("\e[31mERROR: \033[0m The given file doesn't contain a code compatible with this FPGA (PR%.3lx code based)!\n", read_value );
        printf("       Option 1: Check that you are targeting the card in the right slot. Didn't you forget the '-C' argument?!\n");
        printf("       Option 2: Use a partial.bin file containing PR%.3lx or regenerate the code!\n", read_value );
        printf("       Option 3: Reflash the FPGA base code with a code compatible with your action code\n");
    }



    //if (0 != rc)
    //printf("Exit\n");
    goto __main_exit;        /* Exit here.... for now */


__main_exit:
    VERBOSE2 ("[%s] Exit rc: %d\n", __func__, rc);
    snap_close (mctx);
    fflush (fd_out);
    fclose (fd_out);

    //exit (rc);
    exit(-1);
}
