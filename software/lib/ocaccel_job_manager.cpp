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
#include "ocaccel_job_manager.h"
#include "ocaccel_tools.h"
#include <math.h>
#include <algorithm>

void* OcaccelJobManager::alignedAllocate (size_t size)
{
    void* a;
    size_t size2 = size + 64;

    if (posix_memalign ((void**)&a, 4096, size2) != 0) {
        return NULL;
    }

    return a;
}

int OcaccelJobManager::allocateCompletionBuffer (int num_descriptors)
{
    if (eStatus::EMPTY != m_status) {
        printf ("ERROR: unable to allocate completion buffer, job manager is not empty!\n");
        return -1;
    }

    m_completion_status_buffer = alignedAllocate (num_descriptors * c_completion_entry_size);

    if (NULL == m_completion_status_buffer) {
        printf ("ERROR: unable to allocate completion buffer!\n");
        return -1;
    }

    return 0;
}

int OcaccelJobManager::allocateDescriptors (int num_descriptors)
{
    if (eStatus::EMPTY != m_status) {
        printf ("ERROR: unable to allocate descriptors, job manager is not empty!\n");
        return -1;
    }

    int descriptors_remained = num_descriptors;
    while (descriptors_remained > 0) {
        // Always allocate a buffer with a maximum number of descriptors
        size_t allocated_size = c_descriptors_in_a_block * JobDescriptor::c_job_descriptor_size;
        void* allocated_block = alignedAllocate (allocated_size);

        if (NULL == allocated_block) {
            printf ("ERROR: unable to allocate descriptor blocks!\n");
            return -1;
        }

        int num_descriptors_in_current_block = (descriptors_remained > c_descriptors_in_a_block) ? c_descriptors_in_a_block : descriptors_remained;

        memset (allocated_block, 0, allocated_size);
        m_descriptor_block_pointers.push_back (std::make_pair (allocated_block, num_descriptors_in_current_block));

        descriptors_remained -= num_descriptors_in_current_block;
    }

    printf ("blocks allocated %zu\n", m_descriptor_block_pointers.size());
    m_number_of_descriptor_blocks = m_descriptor_block_pointers.size();
    return 0;
}

int OcaccelJobManager::initializeDescriptors()
{
    uint32_t job_descriptor_id = 1;

    for (size_t block_idx = 0; block_idx < m_descriptor_block_pointers.size(); block_idx++) {
        void* descriptor_block_pointer = m_descriptor_block_pointers[block_idx].first;
        int num_descriptors_in_current_block = m_descriptor_block_pointers[block_idx].second;
        uint8_t num_descriptors_in_next_block = 1;
        void* next_descriptor_block_pointer = NULL;

        if (block_idx < m_descriptor_block_pointers.size() - 1) {
            num_descriptors_in_next_block = (uint8_t) (m_descriptor_block_pointers[block_idx + 1].second);
            next_descriptor_block_pointer = m_descriptor_block_pointers[block_idx + 1].first;
        }

        for (int desc_idx = 0; desc_idx < num_descriptors_in_current_block; desc_idx++) {
            JobDescriptor job_descriptor ((uint8_t*) descriptor_block_pointer + desc_idx * JobDescriptor::c_job_descriptor_size);

            //Bit7: Enable interrupt. Default Value: 0
            //Bit6: Write Completion Info back. Default Value: 1
            //Bit0: Write 1 to start the process
            job_descriptor.setJobControl (0x41);

            // The next_adjcent
            job_descriptor.setNextAdjacent (num_descriptors_in_next_block - 1);

            // The magic
            job_descriptor.setMagic (0x20F8);

            // The job descriptor id
            job_descriptor.setJobId (job_descriptor_id);

            // The user parameters will be specified by user.

            // The IRQ handler is not enabled yet

            // The address to next descriptor block
            job_descriptor.setNextBlockAddress ((uint64_t) (next_descriptor_block_pointer));

            job_descriptor_id++;
        }
    }

    return 0;
}

void OcaccelJobManager::freeDescriptorBlock (tDescriptorBlock descriptor_block)
{
    free (descriptor_block.first);
}

void OcaccelJobManager::dumpDescriptorBlock (tDescriptorBlock descriptor_block)
{
    void* descriptor_block_pointer = descriptor_block.first;
    int num_descriptors_in_current_block = descriptor_block.second;

    printf ("Descripto Block @ %p with %d descriptors\n", descriptor_block_pointer, num_descriptors_in_current_block);

    for (int desc_idx = 0; desc_idx < num_descriptors_in_current_block; desc_idx++) {
        JobDescriptor job_descriptor ((uint8_t*)descriptor_block_pointer + desc_idx * JobDescriptor::c_job_descriptor_size);
        job_descriptor.dump();
    }
}

bool OcaccelJobManager::isAllJobsDone()
{
    if (NULL == m_completion_status_buffer) {
        printf ("ERROR: completion buffer is not valid!\n");
        return true;
    }

    for (int i = 0; i < m_number_of_descriptors; i++) {
        if (0 == * ((((uint8_t*)m_completion_status_buffer) + i * c_completion_entry_size))) {
            return false;
        }
    }

    return true;
}

JobDescriptor OcaccelJobManager::getJobDescriptor (int idx)
{
    if (m_number_of_descriptors <= idx) {
        printf ("ERROR: out of index when gettting job descriptors!\n");
        printf ("ERROR: idx %d, m_number_of_descriptors %d!\n", idx, m_number_of_descriptors);
        JobDescriptor job_descriptor(NULL);
        return job_descriptor;
    }

    int block_idx = idx / c_descriptors_in_a_block;
    int desc_idx = idx % c_descriptors_in_a_block;
    void* descriptor_block_pointer = m_descriptor_block_pointers[block_idx].first;
    JobDescriptor job_descriptor ((uint8_t*) descriptor_block_pointer + desc_idx * JobDescriptor::c_job_descriptor_size);

    return job_descriptor;
}

void OcaccelJobManager::setNumberOfDescriptors (int num_descriptors)
{
    m_number_of_descriptors = num_descriptors;
}

void OcaccelJobManager::setOcaccelCardHandler (ocaccel_card* card)
{
    m_ocaccel_card = card;
}

int OcaccelJobManager::initialize()
{
    if (0 == m_number_of_descriptors) {
        printf ("ERROR: please set the number of job descriptors to a valid number!\n");
        return -1;
    }

    if (NULL == m_ocaccel_card) {
        printf ("ERROR: please set the ocaccel card handler!\n");
        return -1;
    }

    if (allocateCompletionBuffer (m_number_of_descriptors)) {
        printf ("ERROR: error running allocateCompletionBuffer!\n");
        return -1;
    }

    if (allocateDescriptors (m_number_of_descriptors)) {
        printf ("ERROR: error running allocateDescriptor!\n");
        return -1;
    }

    if (initializeDescriptors()) {
        printf ("ERROR: error running initializeDescriptors!\n");
        return -1;
    }

    m_status = eStatus::INITIALIZED;

    return 0;
}

int OcaccelJobManager::run()
{
    if (eStatus::INITIALIZED != m_status) {
        printf ("ERROR: job manager is not initialized before kicking off a run!\n");
        return -1;
    }

    if (m_descriptor_block_pointers.size() <= 0) {
        printf ("ERROR: job manager must have at least 1 job descriptor block to run!\n");
        return -1;
    }

    void* descriptor_start_address = m_descriptor_block_pointers[0].first;
    int num_descriptors_of_first_block = m_descriptor_block_pointers[0].second;

    uint32_t descriptor_start_address_lo  = (uint32_t) (((uint64_t) descriptor_start_address) & 0xFFFFFFFF);
    uint32_t descriptor_start_address_hi  = (uint32_t) ((((uint64_t) descriptor_start_address) >> 32) & 0xFFFFFFFF);
    uint32_t completion_buffer_address_lo = (uint32_t) (((uint64_t) m_completion_status_buffer) & 0xFFFFFFFF);
    uint32_t completion_buffer_address_hi = (uint32_t) ((((uint64_t) m_completion_status_buffer) >> 32) & 0xFFFFFFFF);

    printf ("Descriptor Start Address: %p\n", descriptor_start_address);
    printf ("Completion Buffer Address: %p\n", m_completion_status_buffer);

    // Setup the descriptor base address
    if (ocaccel_action_write32 (m_ocaccel_card, REG_JM_INIT_ADDR_LO, descriptor_start_address_lo)) {
        printf ("ERROR: failed to set job descriptor start address!\n");
        return -1;
    }

    if (ocaccel_action_write32 (m_ocaccel_card, REG_JM_INIT_ADDR_HI, descriptor_start_address_hi)) {
        printf ("ERROR: failed to set job descriptor start address!\n");
        return -1;
    }

    // Setup the completion buffer address
    if (ocaccel_action_write32 (m_ocaccel_card, REG_JM_CMPL_ADDR_LO, completion_buffer_address_lo)) {
        printf ("ERROR: failed to set completion buffer address!\n");
        return -1;
    }

    if (ocaccel_action_write32 (m_ocaccel_card, REG_JM_CMPL_ADDR_HI, completion_buffer_address_hi)) {
        printf ("ERROR: failed to set completion buffer address!\n");
        return -1;
    }

    uint32_t jm_control_word = (uint32_t) (num_descriptors_of_first_block - 1) << 8;
    jm_control_word |= 0x1;

    printf ("Job Manager Control Word: %#x\n", jm_control_word);

    if (ocaccel_action_write32 (m_ocaccel_card, REG_JM_CONTROL, jm_control_word)) {
        printf ("ERROR: failed to set job manager control register!\n");
        return -1;
    }

    m_status = eStatus::RUNNING;
    return 0;
}

void OcaccelJobManager::clear()
{
    std::for_each (m_descriptor_block_pointers.begin(), m_descriptor_block_pointers.end(),
            [this] (tDescriptorBlock& i) { freeDescriptorBlock(i); });
    m_status = eStatus::EMPTY;
}

OcaccelJobManager::eStatus OcaccelJobManager::status()
{
    if (eStatus::RUNNING == m_status) {
        if (isAllJobsDone()) {
            m_status = eStatus::FINISHED;
        }
    }

    return m_status;
}

void OcaccelJobManager::dump()
{
    std::for_each (m_descriptor_block_pointers.begin(), m_descriptor_block_pointers.end(),
            [this] (tDescriptorBlock& i) { dumpDescriptorBlock(i); });
    printf ("Content of descriptors\n");
    __hexdump (stdout, m_descriptor_block_pointers[0].first, m_number_of_descriptors * JobDescriptor::c_job_descriptor_size);
    printf ("\nContent of completion buffer\n");
    __hexdump (stdout, (void*) m_completion_status_buffer, m_number_of_descriptors * c_completion_entry_size);
}
