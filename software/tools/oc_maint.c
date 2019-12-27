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

/*
 * SNAP Maintenance tool Written by Eberhard S. Amann esa@de.ibm.com.
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
#include <endian.h>
#include <sys/stat.h>

#if !defined(OPENCAPI30)
#include <libcxl.h>
#endif

#include <osnap_internal.h>
#include <libosnap.h>
#include <osnap_tools.h>
#include <osnap_global_regs.h>
#include <osnap_hls_if.h>
#include "snap_actions.h"

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
    int loop;                /* Loop Counter */
    int card;                /* Card no (0,1,2,3 */
    void* handle;                /* The snap handle */
    int dt;                        /* Delay time in sec (1 sec default) */
    int count;                /* Number of loops to do, (-1) = forever */
    bool daemon;                /* TRUE if forked */
    uint64_t wed;                /* This is a dummy only for attach */
    bool quiet;                /* False or true -q option */
    pid_t pid;
    pid_t my_sid;                /* for sid */
	int mode;		/* See below */
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
        VERBOSE0 ("Error: Can not open CAPI-SNAP Device: %s\n",
                  device);

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


static uint32_t snap_read32 (void* handle, uint32_t addr)
{
    uint32_t reg;
    int rc;

    rc = snap_action_read32 (handle, (uint64_t)addr, &reg);

    if (0 != rc) {
        VERBOSE3 ("[%s] Error Reading MMIO %x\n", __func__, addr);
    }

    return reg;
}


static void snap_version (void* handle)
{
    uint64_t reg;
    unsigned long ioctl_data;

    VERBOSE2 ("[%s] Enter\n", __func__);

    /* Read Card Capabilities */
    snap_card_ioctl (handle, GET_CARD_TYPE, (unsigned long)&ioctl_data);
    VERBOSE1 ("SNAP Card Id: 0x%x ", (int)ioctl_data);

    /* Get Card name */
    char buffer[16];
    snap_card_ioctl (handle, GET_CARD_NAME, (unsigned long)&buffer);
    VERBOSE1 ("Name: %s. ", buffer);

    VERBOSE1 ("NVME ");
    snap_card_ioctl (handle, GET_NVME_ENABLED, (unsigned long)&ioctl_data);

    if (1 == ioctl_data) {
        VERBOSE1 ("enabled");
    } else {
        VERBOSE1 ("disabled");
    }

    snap_card_ioctl (handle, GET_SDRAM_SIZE, (unsigned long)&ioctl_data);
    VERBOSE1 (", %d MB DRAM available. ", (int)ioctl_data);

    snap_card_ioctl (handle, GET_DMA_ALIGN, (unsigned long)&ioctl_data);
    VERBOSE1 ("(Align: %d ", (int)ioctl_data);

    snap_card_ioctl (handle, GET_DMA_MIN_SIZE, (unsigned long)&ioctl_data);
    VERBOSE1 ("Min_DMA: %d)\n", (int)ioctl_data);

    reg = snap_read64 (handle, SNAP_IVR);
    VERBOSE1 ("SNAP FPGA Release: v%d.%d.%d Distance: %d GIT: 0x%8.8x\n",
              (int) (reg >> 56),
              (int) (reg >> 48ll) & 0xff,
              (int) (reg >> 40ll) & 0xff,
              (int) (reg >> 32ull) & 0xff,
              (uint32_t)reg);

    reg = snap_read64 (handle, SNAP_BDR);
    VERBOSE1 ("SNAP FPGA Build (Y/M/D): %04x/%02x/%02x Time (H:M): %02x:%02x\n",
              (int) (reg >> 32ll) & 0xffff,
              (int) (reg >> 24ll) & 0xff,
              (int) (reg >> 16) & 0xff,
              (int) (reg >> 8) & 0xff,
              (int) (reg) & 0xff);

    VERBOSE2 ("[%s] Exit\n", __func__);
    return;
}

static bool decode_action (uint32_t atype)
{
    int i;
    int md_size = sizeof (snap_actions) / sizeof (struct actions_tab);

    for (i = 0; i < md_size; i++) {
        if (atype == snap_actions[i].dev1) {
            VERBOSE1 ("%s %s\n", snap_actions[i].vendor,
                      snap_actions[i].description);
            return true;
        }
    }

    return false;
}

static void snap_decode (uint32_t atype, uint32_t level)
{

    VERBOSE1 ("     %d     0x%8.8x     0x%8.8x  ",
              0, atype, level);

    if (decode_action (atype)) {
        return;
    }

    VERBOSE1 ("UNKNOWN Action.....\n");
    return;
}


static int snap_action_info (void* handle)
{
    uint32_t action_type, action_release;
    int rc;

    VERBOSE2 ("[%s] Enter\n", __func__);
    VERBOSE1 ("   Short |  Action Type |   Level   | Action Name\n");
    VERBOSE1 ("   ------+--------------+-----------+------------\n");

    action_type = snap_read32 (handle, ACTION_TYPE_REG);
    action_release = snap_read32 (handle, ACTION_RELEASE_REG);
    snap_decode (action_type, action_release);
    rc = 0;

    VERBOSE2 ("[%s] Exit rc: %d\n", __func__, rc);
    return rc;
}

/* Leave a space at each end in the print line so that it can use -m1 -m2 ... */
static void snap_show_cap(void *handle, int mode)
{
	unsigned long val;

	if (MODE_SHOW_NVME == (MODE_SHOW_NVME & mode)) {
		snap_card_ioctl(handle, GET_NVME_ENABLED, (unsigned long)&val);
		if (1 == val)
			VERBOSE0("NVME ");
	}
	if (MODE_SHOW_SDRAM == (MODE_SHOW_SDRAM & mode)) {
		snap_card_ioctl(handle, GET_SDRAM_SIZE, (unsigned long)&val);
		if (0 != val)
			VERBOSE0("%d ", (int)val);
	}
	if (MODE_SHOW_CARD == (MODE_SHOW_CARD & mode)) {
		char buffer[16];
		snap_card_ioctl(handle, GET_CARD_NAME, (unsigned long)&buffer);
		VERBOSE0("%s ", buffer);
	}
	if (MODE_SHOW_DMA_ALIGN == (MODE_SHOW_DMA_ALIGN & mode)) {
		snap_card_ioctl(handle, GET_DMA_ALIGN, (unsigned long)&val);
		VERBOSE0("%d ", (int)val);
	}
	if (MODE_SHOW_DMA_MIN == (MODE_SHOW_DMA_MIN & mode)) {
		snap_card_ioctl(handle, GET_DMA_MIN_SIZE, (unsigned long)&val);
		VERBOSE0("%d ", (int)val);
	}
}

static void help (char* prog)
{
    printf ("Print Information. Usage: %s [-CvhVd] [-f file] [-c count] [-i delay]\n"
            "\t-C, --card <num>        Card to use (default 0)\n"
            "\t-V, --version        \tPrint Version number\n"
            "\t-h, --help                This help message\n"
            "\t-q, --quiet                No output at all\n"
            "\t-v, --verbose        \tverbose mode, up to -vvv\n"
	        "\t-m, --mode		Mode:\n"
	        "\t	1 = Show Action number only\n"
	        "\t	2 = Show NVME if enabled\n"
	        "\t	3 = Show SDRAM Size in MB\n"
	        "\t	4 = Show Card\n"
	        "\t	5 = Show DMA Alignment\n"
	        "\t	6 = Show DMA Minimum Transfer Size\n"
            "\n"
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
    int mode;

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

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card",        required_argument, NULL, 'C' },
            { "version",        no_argument,           NULL, 'V' },
            { "quiet",        no_argument,           NULL, 'q' },
            { "help",        no_argument,           NULL, 'h' },
            { "verbose",        no_argument,           NULL, 'v' },
            { "count",        required_argument, NULL, 'c' },
            { "interval",        required_argument, NULL, 'i' },
            { "daemon",        no_argument,           NULL, 'd' },
			{ "mode",	required_argument, NULL, 'm' },
            { 0,                0,                   NULL,  0  }
        };
        ch = getopt_long (argc, argv, "C:c:i:m:Vqhvd",
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

        case 'c':        /* --count */
            mctx->count = strtoul (optarg, NULL, 0);

            if (0 == mctx->count) {
                mctx->count = 1;
            }

            break;

        case 'i':        /* --interval */
            mctx->dt = strtoul (optarg, NULL, 0);
            break;

        case 'd':        /* --daemon */
            mctx->daemon = true;
            break;

		case 'm':	/* --mode */
			mode = strtoul(optarg, NULL, 0);
			switch (mode) {
			case 1: mctx->mode |= MODE_SHOW_ACTION; break;
			case 2: mctx->mode |= MODE_SHOW_NVME; break;
			case 3: mctx->mode |= MODE_SHOW_SDRAM; break;
			case 4: mctx->mode |= MODE_SHOW_CARD; break;
			case 5: mctx->mode |= MODE_SHOW_DMA_ALIGN; break;
			case 6: mctx->mode |= MODE_SHOW_DMA_MIN; break;
			default:
				fprintf(stderr, "Please provide correct "
					"Mode Option (1..6)\n");
				exit(EXIT_FAILURE);
			}
			break;

        default:
            help (argv[0]);
            exit (EXIT_FAILURE);
        }
    }

    //
    //        if ((mctx->card < 0) || (mctx->card > 3)) {
    //                fprintf(stderr, "Err: %d for option -C is invalid, please provide "
    //                        "0..%d!\n", mctx->card, 3);
    //                exit(EXIT_FAILURE);
    //        }
    VERBOSE2 ("[%s] Enter\n", __func__);



    mctx->handle = snap_open (mctx);

    if (NULL == mctx->handle) {
        rc = ENODEV;
        goto __main_exit;
    }

    snap_version (mctx->handle);


    rc = snap_action_info (mctx->handle);

	/* Show Capabilities for different modes */
	snap_show_cap(mctx->handle, mctx->mode);

    //if (0 != rc)
    goto __main_exit;        /* Exit here.... for now */


__main_exit:
    VERBOSE2 ("[%s] Exit rc: %d\n", __func__, rc);
    snap_close (mctx);
    fflush (fd_out);
    fclose (fd_out);

    exit (rc);
}
