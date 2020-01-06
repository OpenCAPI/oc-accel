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

#ifndef THREADBASE_H_h
#define THREADBASE_H_h

#include <iostream>
#include <deque>
#include <boost/shared_ptr.hpp>
#include <boost/thread.hpp>
#include "JobBase.h"
#include "HardwareManager.h"

class ThreadBase
{
public:
    // Constructor of thread base
    ThreadBase();
    ThreadBase (int in_id);
    ThreadBase (int in_id, int in_timeout);

    // Destructor of thread base
    virtual ~ThreadBase();

    // Get ID of this thread
    int get_id();

    // Set ID of this thread
    void set_id (int in_id);

    // Add a job to the queue
    int add_job (JobPtr in_job);

    // Delete a job from the queue
    void delete_job (int job_id);

    // Initialize each job in this thread
    virtual int init() = 0;

    // Start the thread, preparing for work
    int start();

    // The main thread of job handling
    void work();

    // Stop the job processing
    int stop();

    // Join the thread
    void join();

    // Work with the jobs
    virtual void work_with_job (JobPtr in_job) = 0;

    // Interrupt the thread execution
    void interrupt();

    // Wait for an interrupt to be invoked
    int wait_interrupt();

    // Get number of remaining jobs
    int get_num_remaining_jobs();

    // The mutex used to sync between threads
    // (each thread would start a thread to work with all the jobs in queue))
    // Make it static to share across all instances of ThreadBase
    static boost::mutex m_global_mutex;

    // Cleanup necessary resources
    virtual void cleanup () = 0;

protected:
    // The queue to hold all jobs of this thread
    std::deque<JobPtr> m_jobs;

    // The pointer to the thread instance
    boost::shared_ptr<boost::thread> m_thread;

    // The mutex used inside an object to sync between different calls within the object
    boost::mutex m_mutex;

    // The condition variable used to sync between different calls within the object
    boost::condition_variable_any m_cond;

    // ID of this thread
    int m_id;

    // The timeout value before waiting an job to finish
    int m_timeout;

    // If this thread has stopped work
    bool m_stopped;

    // Index to indicate the position of current jobs
    int m_current_job_idx;
};

typedef boost::shared_ptr<ThreadBase> ThreadPtr;

#endif
