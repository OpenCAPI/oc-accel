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
#include "boost/shared_ptr.hpp"
#include "boost/chrono.hpp"
#include "HardwareManager.h"
#include "WorkerDirtest.h"
#include "ThreadDirtest.h"
#include "JobDirtest.h"
#include "Interface.h"

using namespace boost::chrono;

int start_regex_workers (int num_engines, 
                         int no_chk_offset, 
			 void* patt_src_base,
			 size_t patt_size,
                         void* pkt_src_base, 
                         size_t pkt_size, 
                         size_t stat_size,
                         struct snap_card* dn,
                         struct snap_action* act,
                         snap_action_flag_t attach_flags,
			 float* thread_total_band_width,
			 float* worker_band_width)
{
    //printf ("Running on regex worker\n");

    HardwareManagerPtr hw_mgr =  boost::make_shared<HardwareManager> (0, dn, act, attach_flags, 0, 1000);

    WorkerDirtestPtr worker = boost::make_shared<WorkerDirtest> (hw_mgr, false);
    worker->set_mode (false);

    //printf ("Init hardware\n");
    ERROR_CHECK (hw_mgr->init());
    //printf ("Copy pattern to hardware\n");
    worker->set_patt_src_base (patt_src_base, patt_size);

    //printf ("Create %d job(s) for this worker\n", num_engines);

    // Create threads
    for (int i = 0; i < num_engines; i++) {
        ThreadDirtestPtr thd = boost::make_shared<ThreadDirtest> (i, 1000);

        // Create 1 job for each thread
	JobDirtestPtr job = boost::make_shared<JobDirtest> (0, i, hw_mgr, false);
        job->set_no_chk_offset (no_chk_offset);
        job->set_pkt_src_base (pkt_src_base, pkt_size);
        job->set_stat_dest_base (stat_size);
        job->set_worker (worker);

        thd->add_job (job);

        // Add thread to worker
        worker->add_thread (thd);
    }

    //printf ("Finish setting up jobs.\n");

    do {
        high_resolution_clock::time_point t_end0 = high_resolution_clock::now();
        // Start work, multithreading starts from here
        worker->start();
        // Multithreading ends at here
        *thread_total_band_width = worker->get_sum_band_width();
	//printf ("%0.3f\n", *thread_total_band_width);
        high_resolution_clock::time_point t_end1 = high_resolution_clock::now();
        auto duration1 = duration_cast<microseconds> (t_end1 - t_end0).count();
        // Cleanup objects created for this procedure
        hw_mgr->cleanup();
        worker->cleanup();
        high_resolution_clock::time_point t_end2 = high_resolution_clock::now();
        auto duration2 = duration_cast<microseconds> (t_end2 - t_end1).count();

        //printf ("Work finished after %lu microseconds (us)\n", (uint64_t) duration1);
	printf ("Work ");
	*worker_band_width = print_time (duration1, pkt_size * num_engines);
        printf ("Cleanup finished after %lu microseconds (us)\n", (uint64_t) duration2);

        printf ("Worker done!\n");
    } while (0);

    return 0;

fail:
    return -1;
}

