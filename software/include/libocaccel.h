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
#include <ocaccel_types.h>

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
struct ocaccel_action;
struct ocaccel_queue;

typedef uint32_t ocaccel_action_type_t; /* long action type identifies the action */

/**********************************************************************
 * OCACCEL Job Definition
 *********************************************************************/

/**
 * OCACCEL Job description
 *
 * The input interface struct is passed to the hardware action. The hardware
 * action processes the job an returns results either in memory or using the
 * output interface struct.
 *
 * @retc       execution status. Check this to determine if job execution
 *             was sucessfull
 * @win_addr   input address of interface struct
 * @win_size   input size (use extension ptr if larger than 96 bytes)
 * @wout_addr  output address of output interface struct
 * @wout_addr  output size (maximum 96 bytes)
 */
typedef struct ocaccel_job {
    uint32_t retc;                        /* Write to 0x104, Read from 0x184 */
    uint64_t win_addr;                /* rw writing to MMIO 0x110 */
    uint32_t win_size;                /* Number of bytes to Write */
    uint64_t wout_addr;                /* wr read from MMIO 0x190 */
    uint32_t wout_size;                /* Number of Bytes to Read */
}* ocaccel_job_t;

/**
 * ocaccel_job_set - helper function to more easily setup the job request.
 *
 * @win_addr   input address of specific job
 * @win_size   input size (use extension ptr if larger than 96 bytes)
 * @wout_addr  output address of specific job
 * @wout_addr  output size (maximum 96 bytes)
 */
static inline void ocaccel_job_set (struct ocaccel_job* djob,
                                 void* win_addr, uint32_t win_size,
                                 void* wout_addr, uint32_t wout_size)
{
    djob->retc = 0x0;
    djob->win_addr  = (unsigned long)win_addr;
    djob->win_size  = win_size;
    djob->wout_addr = (unsigned long)wout_addr;
    djob->wout_size = wout_size;
}


/******************************************************************************
 * OCACCEL Card Access
 *****************************************************************************/

#define OCACCEL_VENDOR_ID_ANY        0xffff
#define OCACCEL_DEVICE_ID_ANY        0xffff
#define OCACCEL_VENDOR_ID_IBM        0x1014
#define OCACCEL_DEVICE_ID_OCACCEL       0x0632 /* Assigned for OCACCEL framework  */

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
 * Settings for action attachement and Action completion.
 *
 * @OCACCEL_ACTION_DONE_IRQ  Enables Action Done Interrupt.
 *
 * @OCACCEL_ATTACH_IRQ       Use interrupt to determine if action got attached
 *                        from Job Manager.
 */
typedef enum ocaccel_action_flag  {
    OCACCEL_ACTION_DONE_IRQ = 0x01,   /* Enable Action Done Interrupt */
    OCACCEL_ATTACH_IRQ = 0x10000      /* Enable Attach IRQ from Job Manager */
} ocaccel_action_flag_t;

/******************************************************************************
 * OCACCEL Action Access
 *****************************************************************************/

/*
 * Attach an action to the card handle. If this is done a job can be
 * send ot the action.
 *
 * @card          ocaccel_card device handle.
 * @action_type   long OCACCEL action type. This is a unique value identifying the
 *                OCACCEL action. See software/tools/ocaccel_actions.h for exising ids.
 * @action_flags  Define special behavior, e.g. if interrupts should be used or
 *                polling for completion of a job.
 * @attach_timeout_sec Timeout for action attachement. Select larger value if
 *                multiple users compete for the action resource.
 * @return        OCACCEL_OK, else error.
 *
 * Only works with slave contexts
 */
struct ocaccel_action* ocaccel_attach_action (struct ocaccel_card* card,
                                        ocaccel_action_type_t action_type,
                                        ocaccel_action_flag_t action_flags,
                                        int attach_timeout_sec);

/*
 * Detach action from card handle.
 *
 * @action        ocaccel_action handle.
 * @return        OCACCEL_OK, else error.
 *
 * Only works with slave contexts.
 */
int ocaccel_detach_action (struct ocaccel_action* action);

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
 * Manual access to job passing and action control functions. Normal
 * usage should be using the execute_job functions. If those are not
 * sufficient, consider using the following low-level functions.
 */
int ocaccel_action_start (struct ocaccel_action* action);
int ocaccel_action_stop (struct ocaccel_action* action);
int ocaccel_action_is_idle (struct ocaccel_action* action, int* rc);
int ocaccel_action_completed (struct ocaccel_action* action, int* rc,
                           int timeout_sec);
int ocaccel_action_wait_interrupt (struct ocaccel_action* action, int* rc, int timeout);
int ocaccel_action_assign_irq (struct ocaccel_action* action, uint32_t action_irq_ea_reg_addr);

/**
 * Synchronous way to send a job away.  First step : set registers
 * This function writes through MMIO interface the registers
 * to the action / in the FPGA internal memory
 *
 * @action      handle to streaming framework queue
 * @cjob        streaming framework job
 *   @cjob->win_addr   input address of specific job
 *   @cjob->win_size   input size (use extension ptr if larger than 112 bytes)
 *   @cjob->wout_addr  output address of specific job
 *   @cjob->wout_addr  output size (maximum 112 bytes)
 * @return      OCACCEL_OK in case of success, else error.
 */
int ocaccel_action_sync_execute_job_set_regs (struct ocaccel_action* action,
        struct ocaccel_job* cjob);

/**
 * Synchronous way to send a job away.  Last step : check completion
 * This function check the completion of the action, manage the IRQ
 * if needed, and read all action registers through MMIO interface
 *
 * @action      handle to streaming framework queue
 * @cjob        streaming framework job
 * @cjob->win_addr   input address of specific job
 *   @cjob->win_size   input size (use extension ptr if larger than 112 bytes)
 *   @cjob->wout_addr  output address of specific job
 *   @cjob->wout_addr  output size (maximum 112 bytes)
 * timeout_sec  timeout used if polling mode
 * @return      OCACCEL_OK in case of success, else error.
 */
int ocaccel_action_sync_execute_job_check_completion (struct ocaccel_action* action,
        struct ocaccel_job* cjob,
        unsigned int timeout_sec);

/**
 * Synchronous way to send a job away. Blocks until job is done.
 *  * These 3 steps can be called separately from the application
 *   * BUT manage carefully the action timeout
 * 1rst step: write Action registers into the FPGA
 * 2nd  step: start the Action
 *      step: processing - exchange data
 * 3rd  step: check completion and manage IRQ if needed
 *
 * @action      handle to streaming framework queue
 * @cjob        streaming framework job
 * @cjob->win_addr   input address of specific job
 *   @cjob->win_size   input size (use extension ptr if larger than 112 bytes)
 *   @cjob->wout_addr  output address of specific job
 *   @cjob->wout_addr  output size (maximum 112 bytes)
 * timeout_sec  timeout used if polling mode
 * @return      OCACCEL_OK in case of success, else error.
 */
int ocaccel_action_sync_execute_job (struct ocaccel_action* action,
                                  struct ocaccel_job* cjob,
                                  unsigned int timeout_sec);

#if 0 /* FIXME Discuss how this must be done correctly */
/**
 * Allow the action to use interrupts to signal results back to the
 * application. If an irq happens libocaccel will call the interrupt
 * handler function if it got registered with ocaccel_action_register_irq.
 */
typedef int (*ocaccel_action_irq_t) (struct ocaccel_action* action, int irq);

int ocaccel_action_register_irq (struct ocaccel_action* action,
                              ocaccel_action_irq_t* irq_handler,
                              int irq);

int ocaccel_action_enable_irq (struct ocaccel_action* action, int irq);
int ocaccel_action_disable_irq (struct ocaccel_action* action, int irq);
int ocaccel_action_free_irq (struct ocaccel_action* action, int irq);

#endif /* IRQ_SUPPORT */

/**
 * Get a or set ocaccel lib option.
 * @card          Valid OCACCEL card handle
 * @cmd           CMD (see below).
 * @parm          Pointer for GET command or value for SET command
 * @return        0 success
 */
#define GET_CARD_TYPE       1   /* Returns Card type */
#define GET_NVME_ENABLED    2   /* Returns 1 if NVME is enabled */
#define GET_SDRAM_SIZE      3   /* Get Size in MB of Card  sdram */
#define GET_DMA_ALIGN       4   /* Get DMA alignement */
#define GET_DMA_MIN_SIZE    5   /* Get DMA Minimum Size  */
#define GET_CARD_NAME       6   /* Get Name of Card  */
#define SET_SDRAM_SIZE      103 /* Set SD Ram size in MB */

int ocaccel_card_ioctl (struct ocaccel_card* card, unsigned int cmd, unsigned long parm);

/*
 * Get PASID of this action
 *
 * @card        ocaccel_card device handle.
 * @return      PASID ID.
 *
 */
uint32_t ocaccel_action_get_pasid(struct ocaccel_card *card);

#ifdef __cplusplus
}
#endif

#endif /* __LIBOCACCEL_H__ */
