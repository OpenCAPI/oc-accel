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

void* OcaccelJobManager::alignedAllocate(size_t size)
{
    void* a;
    size_t size2 = size + 64;

    if (posix_memalign((void**)&a, 4096, size2) != 0) {
        return NULL;
    }

    return a;
}

int OcaccelJobManager::allocateDescriptors(int num_descriptors)
{
    if (eStatus::EMPTY != m_status) {
        printf("ERROR: unable to allocate descriptors, job manager is not empty!\n");
        return -1;
    }

    int num_blocks_to_be_allocated = (num_descriptors / c_descriptors_in_a_block + 1);

    for (int i = 0; i < num_blocks_to_be_allocated; i++) {
        // Always allocate a buffer with a maximum number of descriptors
        size_t allocated_size = c_descriptors_in_a_block * JobDescriptor::c_job_descritpor_size;
        void* allocated_block = alignedAllocate(allocated_size);

        if (NULL == allocated_block) {
            printf("ERROR: unable to allocate descriptor blocks!\n");
            return -1;
        }

        int num_descriptors_in_current_block = c_descriptors_in_a_block;

        if ((num_blocks_to_be_allocated - 1) == i) {
            // for the last descriptor block, make sure the number of descriptors are correctly set
            num_descriptors_in_current_block = num_descriptors % c_descriptors_in_a_block;
        }

        memset(allocated_block, 0, allocated_size);
        m_descriptor_block_pointers.push_back(std::make_pair<allocated_block, num_descriptors_in_current_block>);
    }

    return 0;
}

int OcaccelJobManager::initializeDescriptorBlock()
{
    for () {
    }
}
