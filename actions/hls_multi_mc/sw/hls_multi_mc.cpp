/*
 * Copyright 2020 International Business Machines
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

/**
 * OCACCEL Multi_mc Example
 *
 * Demonstration how to get data into the FPGA, process it using a OCACCEL
 * action and move the data out of the FPGA back to host-DRAM.
 */
#include <boost/program_options.hpp>
#include <iostream>
#include <libocaccel.h>
#include <ocaccel_job_manager.h>
#include <hls_mc_kernel_register_layout.h>

///////////////////////////////////////////////////////////////////////////////
namespace po = boost::program_options;
template class JobDescriptor<mc_kernel>;

uint32_t addr_lo (void* ptr)
{
    return (uint32_t) (((uint64_t)ptr) & 0xFFFFFFFF);
}


uint32_t addr_hi (void* ptr)
{
    return (uint32_t) ((((uint64_t)ptr) >> 32) & 0xFFFFFFFF);
}
//#define ACTION_TYPE               0x1014300A
///////////////////////////////////////////////////////////////////////////////
// Basic ideas about this program: 
// Create many jobs (-j)
// Ask T2 HW job manager to distribute these jobs to 8 MC kernels
// Each job is doing a memcopy, with various size (-s) or (-r)
//    -s (fixed size): Each job has identical size (128bytes * s)
//    -S (size range): Each job has random size ( <= 128bytes * S)
// Each job allows a delay cycle setting, (-d) or (-D)
//    -d (fixed delay): Each job inserts d-cycles (@200MHz) waiting cycles
//    -D (delay range): Each job inserts random cycles of delay (<= D)

// About data verify: 
//    Check if the copied data is correct. (tgt_buffer should be identical to src_buffer)

// Assumptions: 
//    The number of buffers equals to the number of jobs. These buffers don't overrlop in 
//    host memory.

int main (int argc, const char* argv[])
{
    po::options_description desc{"Options"};
    desc.add_options()
    ("help,h"           ,  "Help information")
    ("card_no,c"        ,  po::value<int>()->default_value (0)       ,  "Card number")
    ("irq,I"            ,  "Enable interrupt mode")
    ("job_count,j"      ,  po::value<int>()->default_value (64) ,  "Number of jobs")
    ("fixed_size,s"     ,  po::value<uint32_t>()->default_value (10) ,  "How many 128Bytes transfers for each job")
    ("rand_size_max,S"  ,  po::value<uint32_t>()->default_value (0) ,   "Random number of 128Bytes transfers and this sets the max range")
    ("fixed_delay,d"    ,  po::value<uint32_t>()->default_value (0)  ,  "Inserted delay cycles at 200MHz)")
    ("rand_delay_max,D" ,  po::value<uint32_t>()->default_value (0)  ,  "Random delay cycles at 200MHz and this sets the max range");

    po::variables_map options;
    po::store (parse_command_line (argc, argv, desc), options);
    po::notify (options);

    if (options.count ("help")) {
        std::cout << desc << '\n';
        return 0;
    }

    int  card_no  = options["card_no"].as<int>();
    bool irq_mode = (options.count ("irq") > 0);
    std::cout << "IRQ mode: " << irq_mode << std::endl;

    const uint32_t BYTES_WIDTH = 128; 
    int exit_code = 0;

    int job_count      = options["job_count"].as<int>();
    uint32_t fixed_size     = options["fixed_size"].as<uint32_t>();
    uint32_t rand_size_max  = options["rand_size_max"].as<uint32_t>();
    uint32_t fixed_delay    = options["fixed_delay"].as<uint32_t>();
    uint32_t rand_delay_max = options["rand_delay_max"].as<uint32_t>();

    std::cout << "job_count: "      << job_count      << std::endl;
    std::cout << "fixed_size: "     << fixed_size     << std::endl;
    std::cout << "rand_size_max: "  << rand_size_max  << std::endl;
    std::cout << "fixed_delay: "    << fixed_delay    << std::endl;
    std::cout << "rand_delay_max: " << rand_delay_max << std::endl;


    if (job_count <= 0) {
        printf("ERROR: job_count should be at least 1\n");
        exit_code = -1;
        return exit_code;
    }

    if (fixed_size <=0 && rand_size_max <= 0) {
        printf("ERROR: one of fixed_size and rand_size_max should be >= 1\n");
        exit_code = -1;
        return exit_code;
    }


    //If rand_size_max is set to > 0, use rand_size; otherwise use fixed_size
    //If rand_delay_max is set to > 0, user rand_delay; otherwise use fixed_delay

    uint32_t * params_size = new uint32_t [job_count];  
    uint32_t * params_delay = new uint32_t [job_count];  
    
    for (int i = 0; i < job_count; i++ ) {

        if (rand_size_max > 0) 
            params_size[i] = rand() % (rand_size_max + 1); //[0, rand_size_max]
        else
            params_size[i] = fixed_size;

        if (rand_delay_max > 0)
            params_delay[i] = rand() % (rand_delay_max + 1); //[0, rand_delay_max]
        else
            params_delay[i] = fixed_delay;
    }

    //Allocate memory buffers and initialize them
    uint8_t ** src_buffers = new uint8_t* [job_count];
    uint8_t ** tgt_buffers = new uint8_t* [job_count];
    for (int i = 0; i < job_count; i++) {
        src_buffers[i] = (uint8_t*) ocaccel_malloc(params_size[i] * BYTES_WIDTH);
        //Initialize to a incremental pattern starting from job_id i
        for(uint32_t j = 0; j < params_size[i] * BYTES_WIDTH; j++ ) {
            src_buffers[i][j] = ( i + j ) & 0xFF;
        }

        tgt_buffers[i] = (uint8_t*) ocaccel_malloc(params_size[i] * BYTES_WIDTH);
        //Initialize to zero
        memset(tgt_buffers[i], 0, params_size[i] * BYTES_WIDTH);
    }

    ///////////////////////////////////////////////////////////////////////////
    OcaccelJobManager* job_manager_ptr = OcaccelJobManager::getManager();
    job_manager_ptr->setNumberOfJobDescriptors (job_count);

    // Initialize job manager
    job_manager_ptr->initialize (card_no, "");

    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<mc_kernel> * job_desc_array = new JobDescriptorPtr<mc_kernel> [job_count];
    for (int i = 0; i < job_count; i++) {

        job_desc_array[i] = job_manager_ptr->getJobDescriptorPtr<mc_kernel> (i);

        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::src_V_1> (addr_lo (src_buffers[i]));
        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::src_V_2> (addr_hi (src_buffers[i]));
        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::tgt_V_1> (addr_lo (tgt_buffers[i]));
        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::tgt_V_2> (addr_hi (tgt_buffers[i]));
        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::size> (params_size[i]);
        job_desc_array[i]->setKernelParameter<mc_kernel::PARAM::delay_cycle> (params_delay[i]);
    }


    //TODO
    //Timer start

    // Run a job on the kernel
    if (job_manager_ptr->run()) {
        std::cerr << "Error running jobs" << std::endl;
        return -1;
    }

    std::cout << "Waiting ... " << std::endl;
    while (! (OcaccelJobManager::eStatus::FINISHED == job_manager_ptr->status())) {
    }
    
    //TODO
    //Timer end

    std::cout << "Multi_mc Job finished!" << std::endl;

    // Verify the result
    for (int i = 0 ; i < job_count; i++) {
        for ( uint32_t j = 0; j < params_size[i] * BYTES_WIDTH; j++) {
            if (src_buffers[i][j] != tgt_buffers[i][j]) {
                std::cerr << "Job " << i << ", mismatch at byte ["<< j <<"]"
                          << " -- src: " << src_buffers[i][j]
                          << " -- tgt: " << tgt_buffers[i][j] << std::endl;
                exit_code = EXIT_FAILURE;
                break;
            }
        }
    }

    sleep (1);

    if (ocaccel_action_trace_enabled()) {
        job_manager_ptr->dump();
    }

    if (0 == exit_code) {
        printf ("Data checking OK.\n");
    }

    job_manager_ptr->clear();

    for (int i=0; i < job_count; i++) {
        free (src_buffers[i]);
        free (tgt_buffers[i]);
    }
    delete [] src_buffers;
    delete [] tgt_buffers;
    delete [] params_size;
    delete [] params_delay;
    return exit_code;
}
