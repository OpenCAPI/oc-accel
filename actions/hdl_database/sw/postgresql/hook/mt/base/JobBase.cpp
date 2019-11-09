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
#include "JobBase.h"

JobBase::JobBase()
    : m_id (0),
      m_thread_id (0),
      m_status (UNKNOWN),
      m_hw_mgr (NULL),
      m_debug (false)
{
}

JobBase::JobBase (int in_id, int in_thread_id)
    : m_id (in_id),
      m_thread_id (in_thread_id),
      m_status (UNKNOWN),
      m_hw_mgr (NULL),
      m_debug (false)
{
}

JobBase::JobBase (int in_id, int in_thread_id, HardwareManagerPtr in_hw_mgr)
    : m_id (in_id),
      m_thread_id (in_thread_id),
      m_status (UNKNOWN),
      m_hw_mgr (in_hw_mgr),
      m_debug (false)
{
}

JobBase::JobBase (int in_id, int in_thread_id, HardwareManagerPtr in_hw_mgr, bool in_debug)
    : m_id (in_id),
      m_thread_id (in_thread_id),
      m_status (UNKNOWN),
      m_hw_mgr (in_hw_mgr),
      m_debug (in_debug)
{
}

JobBase::~JobBase()
{
}

int JobBase::get_thread_id()
{
    return m_thread_id;
}

int JobBase::get_id()
{
    return m_id;
}

void JobBase::fail()
{
    m_status = FAIL;
}

void JobBase::done()
{
    m_status = DONE;
}

HardwareManagerPtr JobBase::get_hw_mgr()
{
    return m_hw_mgr;
}

void JobBase::logging (boost::format & in_fmt)
{
    if (m_debug) {
        std::cout << boost::format ("THREAD[%d] - JOB[%d]: ") % m_thread_id % m_id
                  << in_fmt << std::endl;
    }
}
