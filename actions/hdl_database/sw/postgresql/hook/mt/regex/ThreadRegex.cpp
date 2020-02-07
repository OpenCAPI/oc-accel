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

#include <malloc.h>
#include "ThreadRegex.h"
#include "JobRegex.h"

ThreadRegex::ThreadRegex()
    : ThreadBase (0, 600)
{
}

ThreadRegex::ThreadRegex (int in_id)
    : ThreadBase (in_id)
{
}

ThreadRegex::ThreadRegex (int in_id, int in_timeout)
    : ThreadBase (in_id, in_timeout)
{
}

ThreadRegex::~ThreadRegex()
{
    elog (DEBUG5, "ThreadRegex destroyed!");
}

int ThreadRegex::init()
{
    for (size_t i = 0; i < m_jobs.size(); i++) {
        if (m_jobs[i]->init()) {
            return -1;
        }
    }

    return 0;
}

void ThreadRegex::work_with_job (JobPtr in_job)
{
    JobRegexPtr job = boost::dynamic_pointer_cast<JobRegex> (in_job);

    if (NULL == job) {
        elog (ERROR, "Failed to get pointer to JobRegex");
        return;
    }

    do {
        if (0 != job->run()) {
            elog (ERROR, "Failed to run the JobRegex");
            return;
        }
    } while (0);

    return;
}

void ThreadRegex::cleanup()
{
    for (size_t i = 0; i < m_jobs.size(); i++) {
        m_jobs[i]->cleanup();
    }

    m_jobs.clear();
}

