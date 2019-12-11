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

#ifndef JobRegex_H_h
#define JobRegex_H_h

#include <iostream>
#include "JobBase.h"
#include "WorkerRegex.h"

class JobRegex : public JobBase
{
public:
    enum eStatus {
        DONE = 0,
        FAIL,
        NUM_STATUS
    };

    // Constructor of the job base
    JobRegex();
    JobRegex (int in_id, int in_thread_id);
    JobRegex (int in_id, int in_thread_id, HardwareManagerPtr in_hw_mgr);
    JobRegex (int in_id, int in_thread_id, HardwareManagerPtr in_hw_mgr, bool in_debug);

    // Destructor of the job base
    ~JobRegex();

    // Run this job
    virtual int run();

    // Set pointer to worker
    void set_worker (WorkerRegexPtr in_worker);

    // Get pointer to worker
    WorkerRegexPtr get_worker();

    // Initialize the job
    virtual int init();

    // Prepare the packet buffer
    int packet();

    // Perform the regex scan
    int scan();

    // Get the result
    int result();

    // Cleanup allocated memories
    virtual void cleanup();

    // Allocate packet buffer and stat buffer
    int allocate_packet_buffer ();

    // Set the job descriptor
    void set_job_desc (CAPIRegexJobDescriptor* in_job_desc);

private:
    // Pointer to worker for adding job descriptors
    WorkerRegexPtr m_worker;

    // The Job descritpor which contains all information for a regex job
    CAPIRegexJobDescriptor* m_job_desc;

    // Internal functions to handle relation buffers
    //void* capi_regex_pkt_psql_internal (Relation rel,
    int capi_regex_pkt_psql_internal (Relation rel,
                                        int attr_id,
                                        int start_blk_id,
                                        int num_blks,
                                        void* pkt_src_base,
                                        size_t* size,
                                        size_t* size_wo_hw_hdr,
                                        size_t* num_pkt,
                                        int64_t* t_pkt_cpy);

    // Handle the packet preparation
    int capi_regex_pkt_psql (CAPIRegexJobDescriptor* job_desc,
                             Relation rel, int attr_id);

    // Aligned variant of palloc0
    void* aligned_palloc0 (size_t in_size);

    // An array to hold all allocated pointers,
    // need this array to remember which pionter needs to be freed.
    std::vector<void*> m_allocated_ptrs;

};

typedef boost::shared_ptr<JobRegex> JobRegexPtr;

#endif
