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

#include "ocaccel_job_descriptor.h"

// An helper function provides interface for users to manipulate descriptors
class JobDescriptor
{
public:
    JobDescriptor(void* in_data)
        : m_data(in_data)
    {
    }

    void setHeader(uint32_t in_data)
    {
        *((uint32_t*)(m_data + c_header_offset)) = in_data;
    }

    void setJobId(uint32_t in_data)
    {
        *((uint32_t*)(m_data + c_job_id_offset)) = in_data;
    }

    void setPayload(uint32_t in_data, int idx)
    {
        *((uint32_t*)(m_data + c_payload_offset + (idx * 4))) = in_data;
    }

    void setInterruptHandler(uint64_t in_data)
    {
        *((uint64_t*)(m_data + c_interrupt_handler_offset)) = in_data;
    }

    void setNextAddress(uint64_t in_data)
    {
        *((uint64_t*)(m_data + c_next_address_offset)) = in_data;
    }

    bool isValid()
    {
        return (NULL != m_data);
    }

    void dump()
    {
        printf("==========");

        for (int i = 0; i < c_job_descritpor_size / 4; i++) {
            printf("0X%08X\n", *(((uint32_t*)m_data) + i));
        }

        printf("==========");
    }

private:
    JobDescriptor()
        : m_data(NULL)
    {}

    // Size in bytes
    static const int c_job_descritpor_size      = 128;
    static const int c_header_offset            = 0;
    static const int c_job_control_offset       = 0;
    static const int c_next_adjacent_offset     = 1;
    static const int c_magic_offset             = 2;
    static const int c_job_id_offset            = 4;
    static const int c_payload_offset           = 8;
    static const int c_interrupt_handler_offset = 112;
    static const int c_next_address_offset      = 120;

    // The pointer to the descriptor
    void* m_data;
};

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
    static OcaccelJobManager & getManager()
    {
        static OcaccelJobManager job_Manager;
        return job_Manager;
    }

    // Remove copy functions to avoid extra instance
    // C++11 required
    OcaccelJobManager(OcaccelJobManager const &) = delete;
    void operator = (OcaccelJobManager const &) = delete;

    // Constants
    static const int c_descriptors_in_a_block = 32;

    // Destructor
    ~OcaccelJobManager()
    {
        // Destroy allocated descriptors here
    }

    // Status definition
    enum class eStatus {
        EMPTY = 0,
        INITIALIZED,
        RUNNING,
        FINISHED,
        NUM_STATUS
    };

private:
    // Private constructor to avoid extra instance
    OcaccelJobManager() :
        m_current_descriptor(NULL),
        m_current_descriptor_block(NULL),
        m_status(eStatus::EMPTY)
    {}

    // Allocate aligned memory buffer
    void* alignedAllocate(size_t size);

    // Initialize a job descritpor
    int initializeDescriptorBlock();

public:
    // Allocate memory space for descriptors
    int allocateDescriptors(int num_descriptors);

    // Get the descritpor at the given index
    JobDescriptor* getJobDescriptor(int idx);

    // Start process the manager
    int start();

    // Clear all descriptors in the manager
    int clear();

    // Query the status of the Manager
    eStatus status();

private:
    // The pointer of the current descriptor in tail of the Manager
    void* m_current_descriptor;

    // The pointer of the current desciptor block in tail of the Manager
    void* m_current_descriptor_block;

    // The array to store all descritpor block pointers
    // First  -> pointer to the descriptor block
    // Second -> number of descriptors in this block
    std::vector<std::pair<void*, int>> m_descriptor_block_pointers;

    // The pointer of the completion queue
    volatile void* m_completion_status_buffer;

    // Number of descriptors
    int m_number_of_descriptors;

    // Number of descriptor blocks
    int m_number_of_descriptor_blocks;

    // The current status of the manager
    eStatus m_status;

}

#endif //__OCACCEL_JOB_MANAGER_H__
