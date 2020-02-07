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

#include <boost/chrono.hpp>
#include "WorkerDirtest.h"
#include "ThreadDirtest.h"
#include "constants.h"

WorkerDirtest::WorkerDirtest (HardwareManagerPtr in_hw_mgr, /* Relation in_relation, int in_attr_id, */ bool in_debug)
    : WorkerBase (in_hw_mgr),
      m_interrupt (true),
      m_patt_src_base (NULL),
      m_patt_size (0)
{
    //printf("create dirtest worker\n");
    m_job_manager_en = false;
}

WorkerDirtest::~WorkerDirtest()
{
}

void WorkerDirtest::set_mode (bool in_interrupt)
{
    m_interrupt = in_interrupt;
}

int WorkerDirtest::init()
{
    //printf("init worker\n");
    for (size_t i = 0; i < m_threads.size(); i++) {
        if (m_threads[i]->init()) {
            return -1;
        }
    }

    return 0;
}

void WorkerDirtest::check_thread_done()
{
    //printf("worker checking thread done\n");
    if (m_interrupt) {
        printf ("Interrupt mode is not supported yet!");
    } else {
        do {
            bool all_done = true;

            for (int i = 0; i < (int)m_threads.size(); i++) {
                if (0 == m_threads[i]->get_num_remaining_jobs()) {
                    m_threads[i]->stop();
                } else {
                    all_done = false;
                }
            }

            if (all_done) {
                printf ("Worker -- All jobs done");
                break;
            }

            boost::this_thread::interruption_point();
        } while (1);
    }
}

int WorkerDirtest::check_start()
{
    //printf("worker check start\n");
    if (NULL == m_patt_src_base || 0 == m_patt_size) {
        printf ("ERROR: Invalid pattern buffer");
        return -1;
    }

    return 0;
}

void WorkerDirtest::set_patt_src_base (void* in_patt_src_base, size_t in_patt_size)
{
    m_patt_size = in_patt_size;
    m_patt_src_base = alloc_mem (64, m_patt_size);
    memcpy (m_patt_src_base, in_patt_src_base, m_patt_size);
}

void* WorkerDirtest::get_pattern_buffer()
{
    return m_patt_src_base;
}

size_t WorkerDirtest::get_pattern_buffer_size()
{
    return m_patt_size;
}

float WorkerDirtest::get_sum_band_width()
{
    float sum_band_width = 0;
    for (size_t i = 0; i < m_threads.size(); i++) {
        sum_band_width += boost::dynamic_pointer_cast<ThreadDirtest> (m_threads[i]) ->get_band_width();
    }
    return sum_band_width;
}

void WorkerDirtest::cleanup()
{
    //printf("clean up worker\n");
    free_mem (m_patt_src_base);
    // release_buffers();

    for (size_t i = 0; i < m_threads.size(); i++) {
        m_threads[i]->cleanup();
    }

    m_threads.clear();
}

