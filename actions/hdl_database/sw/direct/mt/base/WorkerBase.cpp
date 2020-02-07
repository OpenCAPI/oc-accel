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

#include "boost/make_shared.hpp"
#include "WorkerBase.h"
#include "constants.h"

WorkerBase::WorkerBase (HardwareManagerPtr in_hw_mgr)
    : m_check_thread (NULL),
      m_hw_mgr (in_hw_mgr),
      m_job_manager_en (false)
{
}

WorkerBase::~WorkerBase()
{
    m_threads.clear();
}

int WorkerBase::add_thread (ThreadPtr in_thread)
{
    m_threads.push_back (in_thread);

    return m_threads.size() - 1;
}

void WorkerBase::delete_thread (int in_thread_id)
{
    if (in_thread_id >= (int)m_threads.size()) {
        return;
    }

    m_threads.erase (m_threads.begin() + in_thread_id);
}

void WorkerBase::start()
{
    //printf("worker start!\n");
    if (check_start()) {
        printf ("Unable to start worker because check_start failed.");
        return;
    }

    for (int i = 0; i < (int)m_threads.size(); i++) {
        m_threads[i]->start();
    }

    //m_check_thread = boost::make_shared<boost::thread> (&WorkerBase::check_thread_done, this);

    for (int i = 0; i < (int)m_threads.size(); i++) {
        m_threads[i]->join();
    }

    //m_check_thread->join();
}
