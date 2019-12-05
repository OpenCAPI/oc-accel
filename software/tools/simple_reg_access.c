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
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#include "libocxl.h"
#define DEVICE "IBM,oc-snap"

static int verbose = 1;
int main()
{
    ocxl_afu_h afu_h;
    ocxl_err err;
    ocxl_mmio_h pp_mmio, global;

    uint64_t reg_addr, reg_data64;
    uint32_t reg_data32;


    ocxl_enable_messages (OCXL_ERRORS);

    // open(context 0)
    if (verbose) {
        printf ("Calling ocxl_afu_open\n");
    }

    err = ocxl_afu_open (DEVICE, &afu_h);

    if (err != OCXL_OK) {
        printf (" Hit Error %d \n", err);
        perror ("ocxl_afu_open:"DEVICE);
        return err;
    }

    // attach to afu - attach does not "start" the afu anymore
    if (verbose) {
        printf ("Calling ocxl_afu_attach\n");
    }

    err = ocxl_afu_attach (afu_h, OCXL_ATTACH_FLAGS_NONE);

    if (err != OCXL_OK) {
        perror ("ocxl_afu_attach:"DEVICE);
        return err;
    }

    // map the mmio spaces
    err = ocxl_mmio_map (afu_h, OCXL_PER_PASID_MMIO, &pp_mmio);

    if (err != OCXL_OK) {
        perror ("per-process ocxl_mmio_map:"DEVICE);
        return err;
    }

    err = ocxl_mmio_map (afu_h, OCXL_GLOBAL_MMIO, &global);

    if (err != OCXL_OK) {
        perror ("global ocxl_mmio_map:"DEVICE);
        return err;
    }

    printf ("Device opened. MMIO mapped.\n");

    /////////////////////////////////////////////////////
    //    global mmio testing
    /////////////////////////////////////////////////////
    reg_addr = 0x0;
    err = ocxl_mmio_read64 (global, reg_addr, OCXL_MMIO_LITTLE_ENDIAN, &reg_data64);

    if (err != OCXL_OK) {
        perror ("ocxl_mmio_read64:"DEVICE);
        return err;
    }

    printf ("Read Register addr %lx, data %lx\n", reg_addr, reg_data64);
    reg_addr = 0x08;
    err = ocxl_mmio_read64 (global, reg_addr, OCXL_MMIO_LITTLE_ENDIAN, &reg_data64);

    if (err != OCXL_OK) {
        perror ("ocxl_mmio_read64:"DEVICE);
        return err;
    }

    printf ("Read Register addr %lx, data %lx\n", reg_addr, reg_data64);

    /////////////////////////////////////////////////////
    //    pp mmio testing
    /////////////////////////////////////////////////////
    reg_addr = 0x0;
    err = ocxl_mmio_read32 (pp_mmio, reg_addr, OCXL_MMIO_LITTLE_ENDIAN, &reg_data32);

    if (err != OCXL_OK) {
        perror ("ocxl_mmio_read64:"DEVICE);
        return err;
    }

    printf ("Read Register addr %lx, data %x\n", reg_addr, reg_data32);
    reg_addr = 0x04;
    err = ocxl_mmio_read32 (pp_mmio, reg_addr, OCXL_MMIO_LITTLE_ENDIAN, &reg_data32);

    if (err != OCXL_OK) {
        perror ("ocxl_mmio_read64:"DEVICE);
        return err;
    }

    printf ("Read Register addr %lx, data %x\n", reg_addr, reg_data32);
    sleep (1);

    printf ("Free afu\n");
    ocxl_afu_close (afu_h);

    return 0;
}
