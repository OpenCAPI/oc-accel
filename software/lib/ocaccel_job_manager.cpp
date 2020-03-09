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

    if (eMode::JOB_SCHEDULER != m_mode) {
        ocaccel_lib_trace ("Not running in JOB_SCHEDULER mode, no need to allocate completion buffer.\n");
        return 0;
    }

    m_completion_status_buffer = alignedAllocate (num_descriptors * c_completion_entry_size);

    if (NULL == m_completion_status_buffer) {
        printf ("ERROR: unable to allocate completion buffer!\n");
        return -1;
    }

    memset ((void*)m_completion_status_buffer, 0, num_descriptors * c_completion_entry_size);
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
        size_t allocated_size = c_descriptors_in_a_block * JobDescriptorBase::c_job_descriptor_size;
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

    ocaccel_lib_trace ("blocks allocated %zu\n", m_descriptor_block_pointers.size());
    m_number_of_descriptor_blocks = m_descriptor_block_pointers.size();
    return 0;
}

int OcaccelJobManager::initializeDescriptors()
{
    uint32_t job_descriptor_id = 0; // Starting from 0?

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
            JobDescriptorBase job_descriptor ((uint8_t*) descriptor_block_pointer + desc_idx * JobDescriptorBase::c_job_descriptor_size);

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

            // The kernel parameters will be specified by user.

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

    ocaccel_lib_trace ("Descripto Block @ %p with %d descriptors\n", descriptor_block_pointer, num_descriptors_in_current_block);

    for (int desc_idx = 0; desc_idx < num_descriptors_in_current_block; desc_idx++) {
        JobDescriptorBase job_descriptor ((uint8_t*)descriptor_block_pointer + desc_idx * JobDescriptorBase::c_job_descriptor_size);
        job_descriptor.dump();
    }
}

bool OcaccelJobManager::isAllJobsDone()
{
    if (eMode::JOB_SCHEDULER != m_mode) {
        printf ("ERROR: invalid mode when quering job status!\n");
        return true;
    }

    if (NULL == m_completion_status_buffer) {
        printf ("ERROR: completion buffer is not valid!\n");
        return true;
    }

    for (int i = 0; i < m_number_of_descriptors; i++) {
        if (0x00 == * ((((uint8_t*)m_completion_status_buffer) + i * c_completion_entry_size))) {
            return false;
        }
    }

    return true;
}

int OcaccelJobManager::setupOcaccelCardHandler (int card_no)
{
    struct ocaccel_card* card = NULL;
    char device[128];

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
        fprintf (stderr, "Make sure the card number (usually -C) is provided properly. Otherwise run ocaccel_find_card to check the card availability.\n");
        return -1;
    }

    // TODO: interrupt is not enabled yet.
    if (0) {
        // TODO: OCACCEL_IRQ_HANDLER_BASE is 0xFFFFFFFF.
        ocaccel_action_assign_irq (card, OCACCEL_IRQ_HANDLER_BASE);
    }

    m_ocaccel_card = card;

    return 0;
}

int OcaccelJobManager::checkActionName (const char* action_name)
{
    if (NULL == m_ocaccel_card) {
        printf ("ERROR: the card hasn't been allocated yet!\n");
        return -1;
    }

    char hardware_action_name[33];

    if (ocaccel_card_ioctl (m_ocaccel_card, GET_ACTION_NAME, hardware_action_name)) {
        printf ("ERROR: failed to get action name via ocaccel_card_ioctl!\n");
        return -1;
    }

    if (strcmp (action_name, hardware_action_name)) {
        printf ("ERROR: action name mismatch. Hardware: %s, user specified: %s!\n", hardware_action_name, action_name);
        return -1;
    }

    ocaccel_lib_trace ("--------> action %s found on the card!\n", hardware_action_name);

    return 0;
}

int OcaccelJobManager::setupJobManager()
{
    if (NULL == m_ocaccel_card) {
        printf ("ERROR: the card hasn't been allocated yet!\n");
        return -1;
    }

    char num_of_kernels = 0;

    if (ocaccel_card_ioctl (m_ocaccel_card, GET_KERNEL_NUMBER, &num_of_kernels)) {
        printf ("ERROR: failed to get number of kernels via ocaccel_card_ioctl!\n");
        return -1;
    }

    printf ("--------> %d kernels found on the card!\n", num_of_kernels);
    setNumberOfKernels ((int) num_of_kernels);

    char infra_template = 0;

    if (ocaccel_card_ioctl (m_ocaccel_card, GET_INFRA_TEMPLATE, &infra_template)) {
        printf ("ERROR: failed to get infrastructure template via ocaccel_card_ioctl!\n");
        return -1;
    }

    printf ("--------> Infrastructure template %d found on the card!\n", infra_template);

    if (1 == (int) infra_template) {
        printf ("--------> MMIO mode enabled\n");
        setMMIOMode();
    } else if (2 == (int) infra_template) {
        printf ("--------> Job scheduler mode enabled\n");
        setJobSchedulerMode();
    } else {
        printf ("--------> ERROR: unsupported infrastructure template: %d\n", (int) infra_template);
        return -1;
    }

    return 0;
}

int OcaccelJobManager::actionWrite32 (int kernel_idx, uint64_t addr, uint32_t in_data)
{
    if (kernel_idx >= m_number_of_kernels) {
        printf ("ERROR: invalid kernel index!");
        return -1;
    }

    uint64_t reg_offset = (OCACCEL_BASE_PER_KERNEL * kernel_idx) + addr;

    if (ocaccel_action_write32 (m_ocaccel_card, reg_offset, in_data)) {
        printf ("ERROR: failed to write reg %#lX!\n", reg_offset);
        return -1;
    }

    return 0;
}

int OcaccelJobManager::actionRead32 (int kernel_idx, uint64_t addr, uint32_t* out_data)
{
    if (kernel_idx >= m_number_of_kernels) {
        printf ("ERROR: invalid kernel index!");
        return -1;
    }

    uint64_t reg_offset = (OCACCEL_BASE_PER_KERNEL * kernel_idx) + addr;

    if (ocaccel_action_read32 (m_ocaccel_card, reg_offset, out_data)) {
        printf ("ERROR: failed to read reg %#lX!\n", reg_offset);
        return -1;
    }

    return 0;
}

int OcaccelJobManager::initialize (const char* action_name)
{
    // By default, use card number 0
    return initialize (0, action_name);
}

int OcaccelJobManager::initialize (int card_no, const char* action_name)
{
    if (0 == m_number_of_descriptors) {
        printf ("ERROR: please set the number of job descriptors to a valid number!\n");
        return -1;
    }

    if (setupOcaccelCardHandler (card_no)) {
        printf ("ERROR: please set the ocaccel card handler!\n");
        return -1;
    }

    if (checkActionName (action_name)) {
        printf ("ERROR: action name mismatch!\n");
        return -1;
    }

    if (setupJobManager()) {
        printf ("ERROR: failed to setup job manager!\n");
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
    if (0 == m_number_of_kernels) {
        printf ("ERROR: no kernels in the card!\n");
        return -1;
    }

    if (eStatus::INITIALIZED != m_status) {
        printf ("ERROR: job manager is not initialized before kicking off a run!\n");
        return -1;
    }

    if (m_descriptor_block_pointers.size() <= 0) {
        printf ("ERROR: job manager must have at least 1 job descriptor block to run!\n");
        return -1;
    }

    return runJobScheduler();
}

//int OcaccelJobManager::run (KernelRegisterLayout* reg_layout)
//{
//    if (0 == m_number_of_kernels) {
//        printf ("ERROR: no kernels in the card!\n");
//        return -1;
//    }
//
//    if (eStatus::INITIALIZED != m_status) {
//        printf ("ERROR: job manager is not initialized before kicking off a run!\n");
//        return -1;
//    }
//
//    if (m_descriptor_block_pointers.size() <= 0) {
//        printf ("ERROR: job manager must have at least 1 job descriptor block to run!\n");
//        return -1;
//    }
//
//    return runMMIO (reg_layout);
//}

//int OcaccelJobManager::runMMIO (KernelRegisterLayout* reg_layout)
//{
//    if (eMode::MMIO != m_mode) {
//        printf ("ERROR: incorrect mode when trying to run MMIO!\n");
//        return -1;
//    }
//
//    if (NULL == reg_layout) {
//        printf ("ERROR: incorrect pointer to kernel register layout!\n");
//        return -1;
//    }
//
//    for (size_t block_idx = 0; block_idx < m_descriptor_block_pointers.size(); block_idx++) {
//        void* descriptor_block_pointer = m_descriptor_block_pointers[block_idx].first;
//        int num_descriptors_in_current_block = m_descriptor_block_pointers[block_idx].second;
//        uint8_t num_descriptors_in_next_block = 1;
//        void* next_descriptor_block_pointer = NULL;
//
//        if (block_idx < m_descriptor_block_pointers.size() - 1) {
//            num_descriptors_in_next_block = (uint8_t) (m_descriptor_block_pointers[block_idx + 1].second);
//            next_descriptor_block_pointer = m_descriptor_block_pointers[block_idx + 1].first;
//        }
//
//        for (int desc_idx = 0; desc_idx < num_descriptors_in_current_block; desc_idx++) {
//            JobDescriptorPtr<K> job_ptr = std::make_shared<JobDescriptor<K> > ((uint8_t*) descriptor_block_pointer + desc_idx * JobDescriptor::c_job_descriptor_size);
//            printf ("----> Configuring job[%zu][%d] to kernel %d in MMIO mode.\n", block_idx, desc_idx, job_ptr->getKernelID());
//            configureJob (job_ptr, reg_layout);
//        }
//    }
//
//    // Start all active kernels
//    for (int kernel_idx = 0; kernel_idx < m_number_of_kernels; kernel_idx++) {
//        if (m_active_kernel_mask[kernel_idx]) {
//            if (startKernel (kernel_idx, reg_layout)) {
//                printf ("WARNING: failed to start kernel %d!\n", kernel_idx);
//            }
//        }
//    }
//
//    m_status = eStatus::RUNNING;
//    return 0;
//}

int OcaccelJobManager::runJobScheduler()
{
    if (eMode::JOB_SCHEDULER != m_mode) {
        printf ("ERROR: incorrect mode when trying to run job scheduler!\n");
        return -1;
    }

    void* descriptor_start_address = m_descriptor_block_pointers[0].first;
    int num_descriptors_of_first_block = m_descriptor_block_pointers[0].second;

    uint32_t descriptor_start_address_lo  = (uint32_t) (((uint64_t) descriptor_start_address) & 0xFFFFFFFF);
    uint32_t descriptor_start_address_hi  = (uint32_t) ((((uint64_t) descriptor_start_address) >> 32) & 0xFFFFFFFF);
    uint32_t completion_buffer_address_lo = (uint32_t) (((uint64_t) m_completion_status_buffer) & 0xFFFFFFFF);
    uint32_t completion_buffer_address_hi = (uint32_t) ((((uint64_t) m_completion_status_buffer) >> 32) & 0xFFFFFFFF);

    ocaccel_lib_trace ("Descriptor Start Address: %p\n", descriptor_start_address);
    ocaccel_lib_trace ("Completion Buffer Address: %p\n", m_completion_status_buffer);

    // Setup the descriptor base address
    if (ocaccel_action_write32 (m_ocaccel_card, OCACCEL_JM_INIT_ADDR_LO, descriptor_start_address_lo)) {
        printf ("ERROR: failed to set job descriptor start address!\n");
        return -1;
    }

    if (ocaccel_action_write32 (m_ocaccel_card, OCACCEL_JM_INIT_ADDR_HI, descriptor_start_address_hi)) {
        printf ("ERROR: failed to set job descriptor start address!\n");
        return -1;
    }

    // Setup the completion buffer address
    if (ocaccel_action_write32 (m_ocaccel_card, OCACCEL_JM_CMPL_ADDR_LO, completion_buffer_address_lo)) {
        printf ("ERROR: failed to set completion buffer address!\n");
        return -1;
    }

    if (ocaccel_action_write32 (m_ocaccel_card, OCACCEL_JM_CMPL_ADDR_HI, completion_buffer_address_hi)) {
        printf ("ERROR: failed to set completion buffer address!\n");
        return -1;
    }

    uint32_t jm_control_word = (uint32_t) (num_descriptors_of_first_block - 1) << 8;
    jm_control_word |= 0x1;

    ocaccel_lib_trace ("Job Manager Control Word: %#x\n", jm_control_word);

    if (ocaccel_action_write32 (m_ocaccel_card, OCACCEL_JM_CONTROL, jm_control_word)) {
        printf ("ERROR: failed to set job manager control register!\n");
        return -1;
    }

    m_status = eStatus::RUNNING;
    return 0;
}

int OcaccelJobManager::discoverKernelInstancesInHardware (const std::string kernel_name, std::vector<int>& instances)
{
    if (eStatus::INITIALIZED > m_status) {
        printf ("WARNING: Job manager is not initialized when trying to discover kernel instances."
                " No kernel instance is found for %s!\n.", kernel_name.c_str());
        return -1;
    }

    char hw_kernel_name[33];

    for (int i = 0; i < m_number_of_kernels; i++) {
        if (ocaccel_get_kernel_name (m_ocaccel_card, i, hw_kernel_name)) {
            printf ("ERROR: failed to get kernel name from hardware!\n");
            return -1;
        }

        if (kernel_name == std::string(hw_kernel_name)) {
            ocaccel_lib_trace ("Kernel %d discovered as %s\n", i, hw_kernel_name);
            instances.push_back(i);
        }
    }

    return 0;
}

void OcaccelJobManager::clear()
{
    std::for_each (m_descriptor_block_pointers.begin(), m_descriptor_block_pointers.end(),
    [this] (tDescriptorBlock & i) {
        freeDescriptorBlock (i);
    });

    if (NULL != m_completion_status_buffer) {
        free ((void*)m_completion_status_buffer);
    }

    if (NULL != m_ocaccel_card) {
        ocaccel_card_free (m_ocaccel_card);
    }

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
    [this] (tDescriptorBlock & i) {
        dumpDescriptorBlock (i);
    });
}
