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
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/stat.h>

#if !defined(OPENCAPI30)
#include <libcxl.h>
#endif

#include <ocaccel_internal.h>
#include <libocaccel.h>
#include <ocaccel_global_regs.h>

static const char* version = GIT_VERSION;

struct mdev_ctx {
    int card_no;     /* card_no no (0,1,2,3 */
    void* handle; /* The ocaccel handle */
};

static struct mdev_ctx        oc_ctx;

static void* ocaccel_open (struct mdev_ctx* mctx)
{
    char device[64];
    void* handle = NULL;

    if (mctx->card_no == 0) {
        snprintf (device, sizeof (device) - 1, "IBM,oc-accel");
    } else {
        snprintf (device, sizeof (device) - 1, "/dev/ocxl/IBM,oc-accel.000%d:00:00.1.0", mctx->card_no);
    }

    handle = ocaccel_card_alloc_dev (device, 0xffff, 0xffff);

    if (NULL == handle)
        printf ("Error: Can not open CAPI-OCACCEL Device: %s\n",
                device);

    return handle;
}

static int ocaccel_close (struct mdev_ctx* mctx)
{
    int rc = 0;

    if (NULL == mctx->handle) {
        rc =  -1;
    } else {
        ocaccel_card_free (mctx->handle);
        mctx->handle = NULL;
    }

    return rc;
}

static int ocaccel_version (void* handle)
{
    uint64_t reg;
    int rc = 0;

    ocaccel_action_trace ("[%s] Enter\n", __func__);

    printf ("--------------------------------------------------\n");
    printf ("|  Card Name |    Build Date     | GIT Release   |\n");
    printf ("| -----------+-------------------+-------------- |\n");

    /* Get card_no name */
    char buffer[16];
    rc |= ocaccel_card_ioctl (handle, GET_CARD_NAME, buffer);
    printf ("|  %6s    |", buffer);

    rc |= ocaccel_global_read64 (handle, OCACCEL_REG_BUILD_DATE, &reg);
    printf ("  %04x/%02x/%02x %02x:%02x |",
            (int) (reg >> 32ll) & 0xffff,
            (int) (reg >> 24ll) & 0xff,
            (int) (reg >> 16) & 0xff,
            (int) (reg >> 8) & 0xff,
            (int) (reg) & 0xff);

    rc |= ocaccel_global_read64 (handle, OCACCEL_REG_IMP_VERSION, &reg);
    printf ("  %9lx    |\n", reg);

    printf ("--------------------------------------------------\n");

    ocaccel_action_trace ("[%s] Exit\n", __func__);
    return rc;
}

static int ocaccel_capability (void* handle)
{
    char ioctl_data;
    int rc = 0;

    ocaccel_action_trace ("[%s] Enter\n", __func__);

    printf ("--------------------------------------------------\n");
    printf ("| CAPI Version | Infra Template | Act Template   |\n");
    printf ("| -------------+----------------+--------------- |\n");

    rc |= ocaccel_card_ioctl (handle, GET_CAPI_VERSION, &ioctl_data);
    printf ("|     %2x       |", (int) ioctl_data);

    rc |= ocaccel_card_ioctl (handle, GET_INFRA_TEMPLATE, &ioctl_data);
    printf ("      T%02d       |", (int) ioctl_data);

    rc |= ocaccel_card_ioctl (handle, GET_ACTION_TEMPLATE, &ioctl_data);
    printf ("      A%02x       |\n", (int) ioctl_data);

    printf ("--------------------------------------------------\n");
    ocaccel_action_trace ("[%s] Exit\n", __func__);
    return rc;
}

static int ocaccel_action_info (void* handle)
{
    int rc = 0;
    char ioctl_data;
    int kernel_number;

    ocaccel_action_trace ("[%s] Enter\n", __func__);

    char action_name[33];
    rc |= ocaccel_card_ioctl (handle, GET_ACTION_NAME, action_name);
    rc |= ocaccel_card_ioctl (handle, GET_KERNEL_NUMBER, &ioctl_data);
    kernel_number = (int) ioctl_data;

    printf ("--------------------------------------------------\n");
    printf ("  Action Name   ---> %-28s  \n", action_name);

    char kernel_name[33];

    int i;
    for (i = 0; i < kernel_number; i++) {
        if (ocaccel_get_kernel_name (handle, i, kernel_name)) {
            strcpy (kernel_name, "ERROR!");
            rc = -1;
        }

        printf ("                  |--> Kernel[%02d] : %-13s \n", i, kernel_name);
    }

    printf (" %2d kernel(s) found.                            \n", kernel_number);
    printf ("--------------------------------------------------\n");
    ocaccel_action_trace ("[%s] Exit\n", __func__);
    return rc;
}

static void help (char* prog)
{
    printf ("Print Information. Usage: %s [-CVh] \n"
            "\t-C, --card_no <num>        card_no to use (default 0)\n"
            "\t-V, --version        \tPrint Version number\n"
            "\t-h, --help                This help message\n"
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
    struct mdev_ctx* mctx = &oc_ctx;

    mctx->handle = NULL;        /* No handle */
    mctx->card_no = 0;          /* Default, card_no 0 */

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card_no",        required_argument, NULL, 'C' },
            { "version",        no_argument,           NULL, 'V' },
            { "help",        no_argument,           NULL, 'h' },
            { 0,                0,                   NULL,  0  }
        };
        ch = getopt_long (argc, argv, "C:Vh",
                          long_options, &option_index);

        if (-1 == ch) {
            break;
        }

        switch (ch) {
        case 'C':        /* --card_no */
            mctx->card_no = strtol (optarg, (char**)NULL, 0);
            break;

        case 'V':        /* --version */
            printf ("%s\n", version);
            exit (EXIT_SUCCESS);
            break;

        case 'h':        /* --help */
            help (argv[0]);
            exit (EXIT_SUCCESS);
            break;

        default:
            help (argv[0]);
            exit (EXIT_FAILURE);
        }
    }

    mctx->handle = ocaccel_open (mctx);

    if (NULL == mctx->handle) {
        printf ("ERROR: unable to open the card!\n");
        rc = EXIT_FAILURE;
    }

    if (ocaccel_version (mctx->handle)) {
        printf ("ERROR: failed to get card versions!\n");
        rc = EXIT_FAILURE;
    }

    if (ocaccel_capability (mctx->handle)) {
        printf ("ERROR: failed to get card capability!\n");
        rc = EXIT_FAILURE;
    }

    if (ocaccel_action_info (mctx->handle)) {
        printf ("ERROR: failed to get action information!\n");
        rc = EXIT_FAILURE;
    }

    if (ocaccel_close (mctx)) {
        printf ("ERROR: failed to close card!\n");
        rc = EXIT_FAILURE;
    }

    exit (rc);
}
