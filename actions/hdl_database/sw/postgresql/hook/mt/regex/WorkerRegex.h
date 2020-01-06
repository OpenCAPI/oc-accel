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

#ifndef WORKERREGEX_H_h
#define WORKERREGEX_H_h

#include <iostream>
#include "WorkerBase.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "pg_capi_internal.h"
#ifdef __cplusplus
}
#endif

class WorkerRegex : public WorkerBase
{
public:
    // Constructor of the worker base
    WorkerRegex (HardwareManagerPtr in_hw_mgr,
                 Relation in_relation,
                 int in_attr_id,
                 bool in_debug);

    // Destructor of the worker base
    ~WorkerRegex();

    // Initialize each thread in this worker
    virtual int init();

    // Check if all threads have done their job
    virtual void check_thread_done();

    // Check if everything is ready for start threads
    virtual int check_start();

    // Set if we are going to use interrupt or polling
    void set_mode (bool in_interrupt);

    // Compile the regex pattern
    int regex_compile (const char* in_patt);

    // Get the pattern buffer pointer
    void* get_pattern_buffer();

    // Get the size of the pattern buffer
    size_t get_pattern_buffer_size();

    // Get pionter to the relation
    Relation get_relation();

    // Get the attribute ID to be scanned
    int get_attr_id();

    // Get the number of buffers (blocks) for different thread
    int get_num_blks_per_thread (int in_thread_id, int* out_start_blk_id);

    // Get the number of tuples for different thread
    // TODO: assume tuples are evenly distributed across buffers
    size_t get_num_tuples_per_thread (int in_thread_id);

    // Clean up any threads created for this worker
    virtual void cleanup();

    // Read all buffers of this relation
    void read_buffers();

    // Release all buffers of this relation
    void release_buffers();

    // A container to hold all buffer pointers of this relation,
    // make it public so it can be referenced with minimum cost.
    Buffer* m_buffers;

private:
    // Use interrupt or poll to check thread done?
    bool m_interrupt;

    // Pointer to regex pattern buffer
    void* m_patt_src_base;

    // Size of the regex pattern buffer
    size_t m_patt_size;

    // The relation of this work
    Relation m_relation;

    // The attribute ID to be scanned
    int m_attr_id;

    // Total number of buffers (blocks) in the relation
    int m_num_blks;

    // Total number of tuples in the relation
    size_t m_num_tuples;
};

typedef boost::shared_ptr<WorkerRegex> WorkerRegexPtr;

#endif
