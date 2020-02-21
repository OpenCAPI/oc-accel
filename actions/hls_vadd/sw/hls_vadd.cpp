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

/**
 * OCACCEL Vadd Example
 *
 * Demonstration how to get data into the FPGA, process it using a OCACCEL
 * action and move the data out of the FPGA back to host-DRAM.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <assert.h>

#include <ocaccel_tools.h>
#include <libocaccel.h>
#include <ocaccel_hls_if.h>

int verbose_flag = 0;

#define ACTION_TYPE               0x10143009
#define RELEASE_LEVEL             0x00000000

uint32_t addr_lo (void* ptr)
{
    return (uint32_t) (((uint64_t)ptr) & 0xFFFFFFFF);
}


uint32_t addr_hi (void* ptr)
{
    return (uint32_t) ((((uint64_t)ptr) >> 32) & 0xFFFFFFFF);
}

/**
 * @brief    prints valid command line options
 *
 * @param prog    current program's name
 */
static void usage (const char* prog)
{
    printf ("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
            "  -C, --card <cardno>       Check with 'ls /dev/ocxl'\n"
            "  -I, --irq                 Enable Interrupts\n"
            "\n"
            "\n",
            prog);
}


/* main program of the application for the hls_helloworld example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main (int argc, char* argv[])
{
    // Init of all the default values used
    int ch = 0;
    int card_no = 0;
    struct ocaccel_card* card = NULL;
    struct ocaccel_action* action = NULL;
    char device[128];
    unsigned long timeout_ms = 1000;
    unsigned long t0, dt;
    unsigned int status;

    int exit_code = 0;

    //-------------------------------------------------------------------------
    // Data buffers for VADD
    unsigned int* in1_buff = NULL, *in2_buff = NULL;
    unsigned int* result_buff = NULL;
    unsigned int* verify_buff = NULL;
    int size = 50;


    // Default way it to use polling (not using interrupt).
    ocaccel_action_flag_t action_irq = (ocaccel_action_flag_t) 0;

    //-------------------------------------------------------------------------
    // Collect the command line arguments
    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card", required_argument, NULL, 'C' },
            { "irq", no_argument, NULL, 'I' },
            { "size", no_argument, NULL, 's' },
            { "verbose", no_argument, NULL, 'v' },
            { "help", no_argument, NULL, 'h' },
            { 0, no_argument, NULL, 0   },
        };

        ch = getopt_long (argc, argv,
                          "C:Ivh",
                          long_options, &option_index);

        if (ch == -1) {
            break;
        }

        switch (ch) {
        case 'C':
            card_no = strtol (optarg, (char**)NULL, 0);
            break;

        case 's':
            size = strtol (optarg, (char**)NULL, 0);
            break;

        case 'I':
            action_irq = OCACCEL_ACTION_DONE_IRQ;
            break;

        /* service */
        case 'v':
            verbose_flag = 1;
            break;

        case 'h':
            usage (argv[0]);
            exit (EXIT_SUCCESS);
            break;

        default:
            usage (argv[0]);
            exit (EXIT_FAILURE);
        }
    }

    if (optind != argc) {
        usage (argv[0]);
        exit (EXIT_FAILURE);
    }

    if (argc == 1) {       // to provide help when program is called without argument
        usage (argv[0]);
        exit (EXIT_FAILURE);
    }

    //-------------------------------------------------------------------------
    // Initialize buffers

    in1_buff     = (unsigned int*) ocaccel_malloc (size * sizeof (unsigned int));
    in2_buff     = (unsigned int*) ocaccel_malloc (size * sizeof (unsigned int));
    result_buff = (unsigned int*) ocaccel_malloc (size * sizeof (unsigned int));
    verify_buff = (unsigned int*) ocaccel_malloc (size * sizeof (unsigned int));

    printf ("============================\n");
    printf ("in1_buff address = %p\n", in1_buff);
    printf ("in2_buff address = %p\n", in2_buff);
    printf ("result_buff address = %p\n", result_buff);
    printf ("verify_buff address = %p\n", verify_buff);
    printf ("size = %d\n", size);
    printf ("============================\n");


    for (int i = 0; i < size; i++) {
        in1_buff[i] = i;     //Give a simple number for easier debugging.
        in2_buff[i] = i * 2; //Give a simple number for easier debugging.
        result_buff[i] = 0; //Wait FPGA to calculate
        verify_buff[i] = in1_buff[i] + in2_buff[i];
    }

    //-------------------------------------------------------------------------
    // Allocate the card that will be used
    if (card_no == 0) {
        snprintf (device, sizeof (device) - 1, "IBM,oc-accel");
    } else {
        snprintf (device, sizeof (device) - 1, "/dev/ocxl/IBM,oc-accel.000%d:00:00.1.0", card_no);
    }

    card = ocaccel_card_alloc_dev (device, OCACCEL_VENDOR_ID_IBM,
                                   OCACCEL_DEVICE_ID_OCACCEL);

    if (card == NULL) {
        fprintf (stderr, "err: failed to open card %u: %s\n",
                 card_no, strerror (errno));
        fprintf (stderr, "Default mode is FPGA mode.\n");
        fprintf (stderr, "Did you want to run CPU mode ? => add OCACCEL_CONFIG=CPU before your command.\n");
        fprintf (stderr, "Otherwise make sure you ran ocaccel_find_card and ocaccel_maint for your selected card.\n");
        goto out_error;
    }

    //-------------------------------------------------------------------------
    // Attach the action that will be used on the allocated card
    action = ocaccel_attach_action (card, ACTION_TYPE, action_irq, 60);

    if (action_irq) {
        ocaccel_action_assign_irq (action, ACTION_IRQ_SRC_LO);
    }

    if (action == NULL) {
        fprintf (stderr, "err: failed to attach action %u: %s\n",
                 card_no, strerror (errno));
        goto out_error1;
    }

    //-------------------------------------------------------------------------
    // Write Control registers

    ocaccel_action_write32 (card, 0x10, addr_lo (in1_buff));
    ocaccel_action_write32 (card, 0x14, addr_hi (in1_buff));

    ocaccel_action_write32 (card, 0x1c, addr_lo (in2_buff));
    ocaccel_action_write32 (card, 0x20, addr_hi (in2_buff));

    ocaccel_action_write32 (card, 0x28, addr_lo (result_buff));
    ocaccel_action_write32 (card, 0x2c, addr_hi (result_buff));

    ocaccel_action_write32 (card, 0x34, uint32_t (size));

    //-------------------------------------------------------------------------
    // Kick off start

    ocaccel_action_write32 (card, 0x00, 0x1);


    // Wait for Done bit
    t0 = tget_ms();
    dt = 0;

    while (dt < timeout_ms) {
        ocaccel_action_read32 (card, 0x00, &status);

        if ((status & 0x2) == 1) {
            printf ("Done! \n");
            break;
        }

        dt = (tget_ms() - t0);
    }


    //-------------------------------------------------------------------------
    // Verify

    for (int i = 0 ; i < size; i++) {
        if (result_buff[i] != verify_buff[i]) {
            printf ("ERROR: result_buff [%d] is %d, expected to be %d. Exit\n",
                    i, result_buff[i], verify_buff[i]);
            exit_code = EXIT_FAILURE;
            break;
        }
    }

    if (0 == exit_code) {
        printf ("Data checking OK.\n");
    }

    //-------------------------------------------------------------------------
    // Detach action + disallocate the card
    ocaccel_detach_action (action);
    ocaccel_card_free (card);

    __free (in1_buff);
    __free (in2_buff);
    __free (result_buff);
    __free (verify_buff);
    exit (exit_code);

out_error2:
    ocaccel_detach_action (action);
out_error1:
    ocaccel_card_free (card);
out_error:
    exit (EXIT_FAILURE);
}
