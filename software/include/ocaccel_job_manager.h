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
#ifndef __OCACCEL_JOB_MANAGER_H__
#define __OCACCEL_JOB_MANAGER_H__
#include <vector>
#include <utility>
#include <iostream>
#include <memory>
#include <stdio.h>
#include <string.h>
#include "libocaccel.h"

// The kernel register layout to tell the manager which registers to read/write.
// Used in MMIO mode
class KernelRegisterLayout
{
public:
    KernelRegisterLayout()
    {
    }

    uint64_t CTRL()
    {
        return m_ctrl_reg;
    }

    uint64_t GIER()
    {
        return m_gier_reg;
    }

    uint64_t IP_IER()
    {
        return m_ip_ier_reg;
    }

    uint64_t IP_ISR()
    {
        return m_ip_isr_reg;
    }

    uint64_t KERNEL_PARAM (int idx)
    {
        if (idx >= (int) m_kernel_params_regs.size()) {
            printf ("ERROR: invalid kernel parameter index in kernel!\n");
            return ~0;
        }

        return m_kernel_params_regs[idx];
    }

    size_t getNumberOfKernelParams()
    {
        return m_kernel_params_regs.size();
    }

protected:
    virtual void addKernelParameters() = 0;

    std::vector<uint64_t> m_kernel_params_regs;

private:
    // Control and interrupt registers have fixed layout in vivado_hls generated IPs,
    // this can be changed to generated dynamically in the future.
    const uint64_t m_ctrl_reg   = 0x00;
    const uint64_t m_gier_reg   = 0x04;
    const uint64_t m_ip_ier_reg = 0x08;
    const uint64_t m_ip_isr_reg = 0x0C;
};

class JobDescriptorBase
{
public:
    static const int c_job_descriptor_size = 128;
    friend class OcaccelJobManager;

    JobDescriptorBase (uint8_t* in_data)
        : m_data (in_data),
          m_kernel_param_index_in_word (0)
    {
    }

    ~JobDescriptorBase()
    {
    }

    uint32_t getKernelParameterByWord (int idx)
    {
        return * ((uint32_t*) (m_data + c_kernel_param_offset + (idx * 4)));
    }

    uint32_t getKernelParameterByWord()
    {
        return * ((uint32_t*) (m_data + c_kernel_param_offset + (m_kernel_param_index_in_word * 4)));
    }

    void setKernelParameter (int idx, uint32_t in_data)
    {
        * ((uint32_t*) (m_data + c_kernel_param_offset + (idx * 4))) = in_data;
    }

    void setKernelParameter (uint32_t in_data)
    {
        * ((uint32_t*) (m_data + c_kernel_param_offset + (m_kernel_param_index_in_word * 4))) = in_data;
        m_kernel_param_index_in_word++;
    }

    void setKernelParameterByDoubleWord (uint64_t in_data)
    {
        * ((uint32_t*) (m_data + c_kernel_param_offset + (m_kernel_param_index_in_word * 4))) = (uint32_t) (in_data & 0xFFFFFFFF);
        m_kernel_param_index_in_word++;

        * ((uint32_t*) (m_data + c_kernel_param_offset + (m_kernel_param_index_in_word * 4))) = (uint32_t) ((in_data >> 32) & 0xFFFFFFFF);
        m_kernel_param_index_in_word++;
    }

    int getCurrentKernelParamIndex()
    {
        return m_kernel_param_index_in_word;
    }

    bool isValid()
    {
        return (NULL != m_data);
    }

    void dump()
    {
        printf ("==================\n");
        printf ("Address: %p\n", m_data);

        for (int i = 0; i < c_job_descriptor_size / 4; i++) {
            printf ("Word %02d - %08X\n", i, * (((uint32_t*)m_data) + i));
        }

        printf ("==================\n");
    }

    int getJobId()
    {
        return * ((uint32_t*) (m_data + c_job_id_offset));
    }

protected:
    JobDescriptorBase()
        : m_data (NULL),
          m_kernel_param_index_in_word (0)
    {}

    // Size in bytes
    static const int c_header_offset             = 0;
    static const int c_job_control_offset        = 0;
    static const int c_next_adjacent_offset      = 1;
    static const int c_magic_offset              = 2;
    static const int c_job_id_offset             = 4;
    static const int c_kernel_param_offset     = 8;
    static const int c_interrupt_handler_offset  = 112;
    static const int c_next_block_address_offset = 120;

    void setHeader (uint32_t in_data)
    {
        * ((uint32_t*) (m_data + c_header_offset)) = in_data;
    }

    void setJobControl (uint8_t in_data)
    {
        * ((uint8_t*) (m_data + c_job_control_offset)) = in_data;
    }

    void setNextAdjacent (uint8_t in_data)
    {
        * ((uint8_t*) (m_data + c_next_adjacent_offset)) = in_data;
    }

    void setMagic (uint16_t in_data)
    {
        * ((uint16_t*) (m_data + c_magic_offset)) = in_data;
    }

    void setJobId (uint32_t in_data)
    {
        * ((uint32_t*) (m_data + c_job_id_offset)) = in_data;
    }

    void setInterruptHandler (uint64_t in_data)
    {
        * ((uint64_t*) (m_data + c_interrupt_handler_offset)) = in_data;
    }

    void setNextBlockAddress (uint64_t in_data)
    {
        * ((uint64_t*) (m_data + c_next_block_address_offset)) = in_data;
    }

    // The pointer to the descriptor
    uint8_t* m_data;

    // Current word idx for kernel parameter (in 4 bytes)
    int m_kernel_param_index_in_word;
};

// An helper function provides interface for users to manipulate descriptors
template <class K>
class JobDescriptor : public JobDescriptorBase
{
public:
    JobDescriptor (uint8_t* in_data)
        : JobDescriptorBase (in_data)
    {
        m_kernel = new K;
    }

    ~JobDescriptor()
    {
        delete m_kernel;
    }

    template <typename K::PARAM R>
    void setKernelParameter (uint32_t in_data)
    {
        * ((uint32_t*) (m_data + c_kernel_param_offset + (static_cast<int> (R) * 4))) = in_data;
    }

    K* getKernel()
    {
        return m_kernel;
    }

    void setKernelID (int idx)
    {
        * ((uint8_t*) (m_data + c_kernel_id_offset)) = idx;
    }

    int getKernelID()
    {
        return * ((uint8_t*) (m_data + c_kernel_id_offset));
    }

private:
    static const int c_kernel_id_offset          = 108;

    JobDescriptor()
        : JobDescriptorBase()
    {}

    // The struct to hold the kernel register layout information
    K* m_kernel;
};

template <typename K>
using JobDescriptorPtr = std::shared_ptr<JobDescriptor<K> >;

// Job Manager to manage interaction with the Manager in oc-accel hardware when job-manager is enabled.
// Use Singleton design pattern to ensure this object only has 1 instance across the whole application.
//
// About Singleton:
// https://stackoverflow.com/questions/1008019/c-singleton-design-pattern
// https://en.wikipedia.org/wiki/Singleton_pattern
class OcaccelJobManager
{
public:
    // The get method to the instance.
    // Usage of this function:
    // OcaccelJobManager& job_Manager_1 = OcaccelJobManager::getManager();
    // OcaccelJobManager& job_Manager_2 = OcaccelJobManager::getManager();
    // <job_Manager_1 is the same as job_Manager_2>
    // <use job_Manager_1/2 anywhere you want>
    static OcaccelJobManager* getManager()
    {
        static OcaccelJobManager job_Manager;
        return &job_Manager;
    }

    // Remove copy functions to avoid extra instance
    // C++11 required
    OcaccelJobManager (OcaccelJobManager const &) = delete;
    void operator = (OcaccelJobManager const &) = delete;

    // Constants
    static const int c_descriptors_in_a_block  = 32;
    static const int c_completion_entry_size   = 128;
    static const uint64_t REG_JM_CONTROL       = 0x24;
    static const uint64_t REG_JM_INIT_ADDR_LO  = 0x28;
    static const uint64_t REG_JM_INIT_ADDR_HI  = 0x2C;
    static const uint64_t REG_JM_CMPL_ADDR_LO  = 0x30;
    static const uint64_t REG_JM_CMPL_ADDR_HI  = 0x34;
    static const uint64_t REG_BASE_PER_KERNEL  = 0x00040000;
    static const uint64_t REG_IRQ_HANDLER_BASE = 0xFFFFFFFF; // TODO: undefined yet

    // Destructor
    ~OcaccelJobManager()
    {
    }

    // Status definition
    enum class eStatus {
        EMPTY = 0,
        INITIALIZED,
        RUNNING,
        FINISHED,
        NUM_STATUS
    };

    enum class eMode {
        MMIO = 0,
        JOB_SCHEDULER,
        NUM_MODES
    };

private:
    // Private constructor to avoid extra instance
    OcaccelJobManager() :
        m_completion_status_buffer (NULL),
        m_number_of_descriptor_blocks (0),
        m_number_of_descriptors (0),
        m_number_of_kernels (0),
        m_ocaccel_card (NULL),
        m_ocaccel_action (NULL),
        m_status (eStatus::EMPTY),
        m_mode (eMode::JOB_SCHEDULER)
    {
        m_descriptor_block_pointers.clear();
        m_active_kernel_mask.clear();
    }

    // Descriptor block is a pair of the pointer and the number of descriptors in this block
    typedef std::pair<void*, int> tDescriptorBlock;

    // Allocate aligned memory buffer
    void* alignedAllocate (size_t size);

    // Allocate completion buffers
    int allocateCompletionBuffer (int num_descriptors);

    // Allocate memory space for descriptors
    int allocateDescriptors (int num_descriptors);

    // Initialize a job descriptor
    int initializeDescriptors();

    // Release the space of descriptor block
    void freeDescriptorBlock (tDescriptorBlock descriptor_block);

    // Dump the content of a descriptor block
    void dumpDescriptorBlock (tDescriptorBlock descriptor_block);

    // Check the completion queue to determine if all jobs are done, for JOB_SCHEDULER mode
    bool isAllJobsDone();

    // Check if all jobs done in MMIO mode
    template <typename K>
    bool isAllJobsDone (K* reg_layout)
    {
        if (eMode::MMIO != m_mode) {
            printf ("ERROR: invalid mode when quering job status!\n");
            return true;
        }

        for (int kernel_idx = 0; kernel_idx < m_number_of_kernels; kernel_idx++) {
            if (m_active_kernel_mask[kernel_idx]) {
                uint32_t reg_data;
                uint64_t reg_addr = reg_layout->CTRL();

                if (actionRead32 (kernel_idx, reg_addr, &reg_data)) {
                    printf ("ERROR: failed to read the CTRL register for kernel %d\n", kernel_idx);
                    return true;
                }

                if (0 == (reg_data & 0x2)) {
                    return false;
                }

                // Jobs done on the kernel, mark it as inactive
                m_active_kernel_mask[kernel_idx] = false;
            }
        }

        return true;
    }

    // Setup the ocaccel_card handler
    int setupOcaccelCardHandler (int card_no, uint32_t ACTION_TYPE);

    // Run in the job scheduler mode
    int runJobScheduler();

    // Run in the MMIO mode
    //int runMMIO (KernelRegisterLayout* reg_layout);

    // Configure 1 job descriptor to kernel in MMIO mode
    template <typename K>
    int configureJob (JobDescriptorPtr<K> job_ptr)
    {
        int kernel_idx = job_ptr->getKernelID();
        K* reg_layout = job_ptr->getKernel();

        if (m_active_kernel_mask[kernel_idx]) {
            printf ("ERROR: kernel %d is already active when trying to configure.!\n", kernel_idx);
            return -1;
        }

        // Configure the kernel parameters
        for (int reg_idx = 0; reg_idx < (int) reg_layout->getNumberOfKernelParams(); reg_idx++) {
            uint64_t kernel_param_addr = reg_layout->KERNEL_PARAM (reg_idx);
            uint32_t kernel_param_value = job_ptr->getKernelParameterByWord (reg_idx);

            if (actionWrite32 (kernel_idx, kernel_param_addr, kernel_param_value)) {
                printf ("ERROR: failed to perform action write during MMIO run!\n");
                return -1;
            }
        }

        m_active_kernel_mask[kernel_idx] = true;

        return 0;
    }

    // Start an kernel in MMIO mode
    template <typename K>
    int startKernel (int kernel_idx, K* reg_layout)
    {
        uint64_t ctrl_addr = reg_layout->CTRL();

        // start the kernel
        // TODO: bit 0 is the bit to start, hard coded, need to get it in a more flexible way
        if (actionWrite32 (kernel_idx, ctrl_addr, 0x1)) {
            printf ("ERROR: failed to start kernel %d!\n", kernel_idx);
            return -1;
        }

        return 0;
    }

    // Write action register per kernel basis
    int actionWrite32 (int kernel_idx, uint64_t addr, uint32_t in_data);

    // Read action register per kernel basis
    int actionRead32 (int kernel_idx, uint64_t addr, uint32_t* out_data);

public:
    // Get the descriptor at the given index
    template <typename K>
    JobDescriptorPtr<K> getJobDescriptorPtr (int idx)
    {
        if (m_number_of_descriptors <= idx) {
            printf ("ERROR: out of index when gettting job descriptors!\n");
            printf ("ERROR: idx %d, m_number_of_descriptors %d!\n", idx, m_number_of_descriptors);
            return std::make_shared<JobDescriptor<K> > ((uint8_t*)NULL);
        }

        int block_idx = idx / c_descriptors_in_a_block;
        int desc_idx = idx % c_descriptors_in_a_block;
        void* descriptor_block_pointer = m_descriptor_block_pointers[block_idx].first;
        return std::make_shared<JobDescriptor<K> > ((uint8_t*) descriptor_block_pointer + desc_idx * JobDescriptorBase::c_job_descriptor_size);
    }

    // Set the number of job descriptors
    void setNumberOfJobDescriptors (int num_job_descriptors)
    {
        m_number_of_descriptors = num_job_descriptors;
    }

    // Initialize the manager for a run
    int initialize (uint32_t ACTION_TYPE);

    // Initialize the manager for a run
    int initialize (int card_no, uint32_t ACTION_TYPE);

    // Start process the manager in JOB_SCHEDULER mode
    int run();

    // Start process the manager in MMIO mode
    //int run (KernelRegisterLayout* reg_layout);

    // Run in the MMIO mode with 1 job descriptor
    template <typename K>
    int run (JobDescriptorPtr<K> job_ptr)
    {
        if (eMode::MMIO != m_mode) {
            printf ("ERROR: incorrect mode when trying to run MMIO!\n");
            return -1;
        }

        K* reg_layout = job_ptr->getKernel();

        if (NULL == reg_layout) {
            printf ("ERROR: incorrect pointer to kernel register layout!\n");
            return -1;
        }

        printf ("----> Configuring job[%d] to kernel %d in MMIO mode.\n", job_ptr->getJobId(), job_ptr->getKernelID());

        if (configureJob<K> (job_ptr)) {
            printf ("ERROR: failed to configure a job descriptor to kernel!\n");
            return -1;
        }

        if (startKernel<K> (job_ptr->getKernelID(), reg_layout)) {
            printf ("ERROR: failed to start kernel!\n");
            return -1;
        }

        m_status = eStatus::RUNNING;

        return 0;
    }

    // Clear all descriptors in the manager
    void clear();

    // Query the status of the Manager
    eStatus status();

    // Query the status of the Manager
    template <typename K>
    eStatus status (K* reg_layout)
    {
        if (eStatus::RUNNING == m_status) {
            if (isAllJobsDone (reg_layout)) {
                m_status = eStatus::FINISHED;
            }
        }

        return m_status;
    }

    // Dump all descriptors
    void dump();

    // Enable job scheduler mode (the job scheduler in the hardware)
    void setJobSchedulerMode()
    {
        m_mode = eMode::JOB_SCHEDULER;
    }

    // Enable the MMIO mode (jobs are configured via MMIO)
    void setMMIOMode()
    {
        m_mode = eMode::MMIO;
    }

    // Set the number of kernels in hardware
    void setNumberOfKernels (int num)
    {
        m_number_of_kernels = num;
        m_active_kernel_mask.resize (num, false);
    }

private:
    // The array to store all descriptor block pointers
    // First  -> pointer to the descriptor block
    // Second -> number of descriptors in this block
    std::vector<tDescriptorBlock> m_descriptor_block_pointers;

    // The pointer of the completion queue
    volatile void* m_completion_status_buffer;

    // Number of descriptors
    int m_number_of_descriptors;

    // Number of descriptor blocks
    int m_number_of_descriptor_blocks;

    // Number of kernels in current card
    int m_number_of_kernels;

    // OCACCEL card handler
    ocaccel_card* m_ocaccel_card;
    ocaccel_action* m_ocaccel_action;

    // The current status of the manager
    eStatus m_status;

    // The current mode of the manager
    eMode m_mode;

    // The currently active kernels
    std::vector<bool> m_active_kernel_mask;
};

#endif //__OCACCEL_JOB_MANAGER_H__
