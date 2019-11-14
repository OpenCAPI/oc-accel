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

#ifndef WORKERBASE_H_h
#define WORKERBASE_H_h

#include <iostream>
#include <vector>
#include "ThreadBase.h"

class WorkerBase
{
public:
    // Constructor of the worker base
    WorkerBase (HardwareManagerPtr in_hw_mgr);

    // Destructor of the worker base
    ~WorkerBase();

    // Add a thread to the queue
    int add_thread (ThreadPtr in_thread);

    // Delete a thread from the queue
    void delete_thread (int in_thread_id);
    
    // Initialize each thread
    virtual int init() = 0;

    // Start all threads in m_threads
    void start();

    // Check if all threads have done their job
    virtual void check_thread_done() = 0;

    // Check if everything is ready for start threads
    virtual int check_start() = 0;

    // Cleanup necessary resources
    virtual void cleanup() = 0;

protected:
    // Queue of the threads
    std::vector<ThreadPtr> m_threads;

    // Thread to check if threads are done their job
    boost::shared_ptr<boost::thread> m_check_thread;

    // The hardware manager
    HardwareManagerPtr m_hw_mgr;

    // Is job manager enabled
    bool m_job_manager_en;
};

typedef boost::shared_ptr<WorkerBase> WorkerPtr;

#endif
