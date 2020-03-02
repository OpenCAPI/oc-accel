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
#ifndef __LIBOCACCEL_H__
#define __LIBOCACCEL_H__

/**
 * Copyright 2016, 2017 International Business Machines
 * Copyright 2016 Rackspace Inc.
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

#include <stdint.h>

/**
 * During the workshop we discovered that there are two potential
 * application use-cases:
 *  1. Job-execution mode
 *  2. Data-streaming mode with fixed compute kernel assignment
 *
 * 1. Job-execution mode
 *
 * The first one, which we originally proposed
 * is very similar to what we did with CAPI gzip. It uses AFU directed
 * CAPI mode to allow different processes to attach to the card.
 * A job-queue with a request and a completion part is attached to
 * each AFU context. The cards job-manager schedules jobs, which are
 * executed by the next free kernel.
 *
 * This model supports multi-threaded and multi-process applications by
 * offering best hardware utilization due to the build in job scheduling
 * mechanism.
 *
 * When using this mode ,some design assumptions are imposed on the
 * compute kernels:
 *  - Software sets up jobs and the job-manager hardware takes care
 *    to execute them on the next free kernel
 *  - Software does not do MMIOs to the kernel directly, since kernels
 *    are assigned dynamically by the job-manager
 *  - Kernels must not have state, state can be in host DRAM or on card
 *    DRAM
 *  - Interrupt is used to signal job completion, kernels do not send
 *    interrupts while they are running
 *
 * 2. Fixed compute action assignment/data-streaming mode
 *
 * In this mode compute kernels do not execute one job and can be
 * reused after that. Instead they run for the whole application lifetime.
 * An example is a video processing application, looking for a specific
 * pattern e.g. a person with a baguette. In this mode a kernel can
 * be assigned to an AFU context, and can be started and stopped. MMIO
 * and interrupts are possible during runtime to allow communication
 * with the kernel.
 *
 * A data send and receive queue could be a useful extension.
 *
 * Since the kernels are assigned fixed, multiprocessing is restricted
 * to the available number of compute kernels.
 */

#ifdef __cplusplus
extern "C" {
#endif

#define OCACCEL_VERSION                        "0.10.0"

/**********************************************************************
 * OCACCEL Error Codes
 *********************************************************************/

/*
 * Error codes FIXME alternaternatively we could use the errno codes
 * and return -1 in case of error. This would be similar to libcxl.h.
 */

#define OCACCEL_OK        0  /* Everything great */
#define OCACCEL_EBUSY     -1 /* Resource is busy */
#define OCACCEL_ENODEV    -2 /* No such device */
#define OCACCEL_EIO       -3 /* Problem accessing the card */
#define OCACCEL_ENOENT    -4 /* Entry not found */
#define OCACCEL_EFAULT    -5 /* Illegal address */
#define OCACCEL_ETIMEDOUT -6 /* Timeout error */
#define OCACCEL_EINVAL    -7 /* Invalid parameters */
#define OCACCEL_EATTACH   -8 /* Attach error */
#define OCACCEL_EDETACH   -9 /* Detach error */

/**********************************************************************
 * OCACCEL Common Definitions
 *********************************************************************/

struct ocaccel_card;

/******************************************************************************
 * OCACCEL Card Access
 *****************************************************************************/

#define OCACCEL_VENDOR_ID_ANY        0xffff
#define OCACCEL_DEVICE_ID_ANY        0xffff
#define OCACCEL_VENDOR_ID_IBM        0x1014
#define OCACCEL_DEVICE_ID_OCACCEL    0x0632 /* Assigned for OCACCEL framework  */

/*
 * Opens the device given by the path. Checks if the given vendor and device
 * id match the values in the CAPI AFU config space, fails if the IDs don't
 * match.
 *
 * @path        name of the CAPI device node in /dev
 * @vendor_id   vendor_id in AFU config space. Use the IBM id in case of doubt.
 * @device_id   CAPI OCACCEL device_id. See above. This makes sure you are really
 *              talking to a CAPI card supporting OCACCEL.
 * @return      ocaccel_device handle or NULL in case of error.
 */
struct ocaccel_card* ocaccel_card_alloc_dev (const char* path,
        uint16_t vendor_id, uint16_t device_id);

/*
 * Free OCACCEL device
 *
 * @card        ocaccel_card device handle.
 */
void ocaccel_card_free (struct ocaccel_card* card);

/*
 * MMIO Access functions
 *
 * @card        ocaccel_card device handle.
 * @offset      offset in AFU global MMIO register space.
 * @data        data to read/write.
 * @return      OCACCEL_OK in case of success, else error.
 *
 * Working with any type of AFU context.
 */


int ocaccel_global_write64 (struct ocaccel_card* card, uint64_t offset,
                            uint64_t data);
int ocaccel_global_read64 (struct ocaccel_card* card, uint64_t offset,
                           uint64_t* data);

/*
 * MMIO Access functions for actions
 *
 * @card        ocaccel_card device handle.
 * @offset      offset in AFU PP MMIO register space.
 * @data        data to read/write.
 * @return      OCACCEL_OK in case of success, else error.
 *
 * Working with attached action. OCACCEL jobmanager maps the MMIO ara
 * for the action to a specific offset. Use these functions to
 * directly access this range without the need to add the action_base
 * offset.
 */
int ocaccel_action_write32 (struct ocaccel_card* card, uint64_t offset,
                            uint32_t data);
int ocaccel_action_read32 (struct ocaccel_card* card, uint64_t offset,
                           uint32_t* data);

/*
 * Low level action manipulation APIs.
 * TODO: need more description on each function.
 */
int ocaccel_action_wait_interrupt (struct ocaccel_card* card, int* rc, int timeout);
int ocaccel_action_assign_irq (struct ocaccel_card* card, uint32_t action_irq_ea_reg_addr);

/*
 * Get PASID of this action
 *
 * @card        ocaccel_card device handle.
 * @return      PASID ID.
 *
 */
uint32_t ocaccel_action_get_pasid (struct ocaccel_card* card);

/**
 * Get card basic information.
 * @card          Valid OCACCEL card handle
 * @cmd           CMD (see below).
 * @arg           Pointer for GET command or value for SET command
 * @return        0 success
 */
#define GET_CARD_TYPE       1   /* Returns Card type */
#define GET_ACTION_TEMPLATE 2   /* Returns Action template */
#define GET_INFRA_TEMPLATE  3   /* Returns Infrastructure template */
#define GET_KERNEL_NUMBER   4   /* Returns Number of kernels */
#define GET_CAPI_VERSION    5   /* Returns CAPI version. */
#define GET_CARD_NAME       6   /* Get Name of Card  */
#define GET_ACTION_NAME     7   /* Get Name of Action */

int ocaccel_card_ioctl (struct ocaccel_card* card, unsigned int cmd, char* arg);

/**
 * Get the kernel name string.
 * @card          Valid OCACCEL card handle
 * @kernel_id     Kernel ID
 * @arg           Pointer for the name string
 * @return        0 success
 */
int ocaccel_get_kernel_name (struct ocaccel_card* card, int kernel_id, char* arg);

/*
 * Trace helper functions and macros.
 * TODO: need more description on each function.
 *
 */
int ocaccel_lib_trace_enabled (void);
int ocaccel_action_trace_enabled (void);

#define ocaccel_lib_trace(fmt, ...) do { \
        if (ocaccel_lib_trace_enabled()) \
            fprintf(stdout, "OCACCEL LIB:  " fmt, ## __VA_ARGS__); \
    } while (0)

#define ocaccel_action_trace(fmt, ...) do { \
        if (ocaccel_action_trace_enabled()) \
            fprintf(stdout, "OCACCEL ACT:  " fmt, ## __VA_ARGS__); \
    } while (0)

/*
 * Memory allocation helper functions.
 * TODO: need more description on each function.
 *
 */
void* ocaccel_malloc (size_t size);

/* 
 * Get Time in msec 
 * TODO: need more description on each function.
 */
unsigned long ocaccel_tget_ms (void);

/* 
 * Get Time in usec 
 * TODO: need more description on each function.
 */
unsigned long ocaccel_tget_us (void);

/* Action Address map defined by Vivado HLS     */
/* Search the contents in Xilinx document ug902 */
#define OCACCEL_KERNEL_CONTROL             0x00              /* Control signals */
#define OCACCEL_KERNEL_CONTROL_START       0x00000001        /* ap_start (Clear on Handshake) */
#define OCACCEL_KERNEL_CONTROL_DONE        0x00000002        /* ap_done (Clear on Read) */
#define OCACCEL_KERNEL_CONTROL_IDLE        0x00000004        /* ap_idle (Read Only) */
#define OCACCEL_KERNEL_CONTROL_RUN         0x00000008        /* ap_ready (Read Only) */

#define OCACCEL_KERNEL_IRQ_CONTROL         0x04              /* Global Interrupt Enable Register */
#define OCACCEL_KERNEL_IRQ_CONTROL_ON      0x00000001        /* Global Interrupt Enable (Read/Write) */
#define OCACCEL_KERNEL_IRQ_CONTROL_OFF     0x00000000        /* Global Interrupt Disable (Read/Write) */

#define OCACCEL_KERNEL_IRQ_APP             0x08              /* IP Interrupt Enable Register (Read/Write) */
#define OCACCEL_KERNEL_IRQ_APP_DONE        0x00000001        /* Channel 0 (ap_done)*/
#define OCACCEL_KERNEL_IRQ_APP_READY       0x00000002        /* Channel 1 (ap_ready) FIXME: not implemented yet */

#define OCACCEL_KERNEL_IRQ_STATUS          0x0c              /* IP Interrupt Status Register (Read/TOW) */
#define OCACCEL_KERNEL_IRQ_STATUS_DONE     0x00000001        /* Channel 0 (ap_done)*/
#define OCACCEL_KERNEL_IRQ_STATUS_READY    0x00000002        /* Channel 1 (ap_ready) FIXME: not implemented yet*/

#define OCACCEL_KERNEL_TYPE_REG            0x10              /* OCACCEL kernel Type Register */
#define OCACCEL_KERNEL_RELEASE_REG         0x14              /* OCACCEL kernel Release version Register */

#define OCACCEL_KERNEL_IRQ_SRC_LO          0x18              /* OCACCEL kernel interrupt src (low 32bits) (obj_handler) */
#define OCACCEL_KERNEL_IRQ_SRC_HI          0x1C              /* OCACCEL kernel interrupt src (high 32bits) (obj_handler) */
#define OCACCEL_KERNEL_CONTEXT             0x20              /* OCACCEL kernel context register. */

#define OCACCEL_KERNEL_NAME_STR1           0x30              /* OCACCEL kernel name register 1 */
#define OCACCEL_KERNEL_NAME_STR2           0x34              /* OCACCEL kernel name register 2 */
#define OCACCEL_KERNEL_NAME_STR3           0x38              /* OCACCEL kernel name register 3 */
#define OCACCEL_KERNEL_NAME_STR4           0x3C              /* OCACCEL kernel name register 4 */
#define OCACCEL_KERNEL_NAME_STR5           0x40              /* OCACCEL kernel name register 5 */
#define OCACCEL_KERNEL_NAME_STR6           0x44              /* OCACCEL kernel name register 6 */
#define OCACCEL_KERNEL_NAME_STR7           0x48              /* OCACCEL kernel name register 7 */
#define OCACCEL_KERNEL_NAME_STR8           0x4C              /* OCACCEL kernel name register 8 */

#define OCACCEL_JM_CONTROL                 0x24
#define OCACCEL_JM_INIT_ADDR_LO            0x28
#define OCACCEL_JM_INIT_ADDR_HI            0x2C
#define OCACCEL_JM_CMPL_ADDR_LO            0x30
#define OCACCEL_JM_CMPL_ADDR_HI            0x34
#define OCACCEL_BASE_PER_KERNEL            0x00040000
#define OCACCEL_BASE_KERNEL_HELPER         0x00020000
#define OCACCEL_IRQ_HANDLER_BASE           0xFFFFFFFF // TODO: undefined yet

#define OCACCEL_MEMBUS_WIDTH          128                /* bytes */
#define OCACCEL_ROUND_UP(x, width) (((x) + (width) - 1) & ~((width) - 1))

#ifdef __cplusplus
}
#endif

#endif /* __LIBOCACCEL_H__ */
