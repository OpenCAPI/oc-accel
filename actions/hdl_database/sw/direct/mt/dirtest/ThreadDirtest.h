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
#ifndef THREADDIRTEST_H_h
#define THREADDIRTEST_H_h

#include <iostream>
#include <vector>
#include <boost/shared_ptr.hpp>
#include <boost/thread.hpp>
#include "ThreadBase.h"
#include "HardwareManager.h"

class ThreadDirtest : public ThreadBase
{
public:
    // Constructor of thread regex
    ThreadDirtest();
    ThreadDirtest (int in_id);
    ThreadDirtest (int in_id, int in_timeout);

    // Destructor of thread regex
    ~ThreadDirtest();

    // Initialize each jobs in this thread
    virtual int init();

    // Work with the jobs
    virtual void work_with_job (JobPtr in_job);

    float get_band_width();

    // Cleanup
    virtual void cleanup();

private:
    float m_band_width;
};

typedef boost::shared_ptr<ThreadDirtest> ThreadDirtestPtr;

#endif

