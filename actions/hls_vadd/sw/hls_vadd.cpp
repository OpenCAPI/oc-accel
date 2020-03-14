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
 * OCACCEL Vadd Example
 *
 * Demonstration how to get data into the FPGA, process it using a OCACCEL
 * action and move the data out of the FPGA back to host-DRAM.
 */
#include <boost/program_options.hpp>
#include <iostream>
#include <libocaccel.h>
#include <ocaccel_job_manager.h>
#include <hls_vadd_register_layout.h>

namespace po = boost::program_options;
#define ACTION_TYPE               0x10143009
template class JobDescriptor<vadd>;

uint32_t addr_lo (void* ptr)
{
    return (uint32_t) (((uint64_t)ptr) & 0xFFFFFFFF);
}


uint32_t addr_hi (void* ptr)
{
    return (uint32_t) ((((uint64_t)ptr) >> 32) & 0xFFFFFFFF);
}

int main (int argc, const char* argv[])
{
    po::options_description desc{"Options"};
    desc.add_options()
    ("help,h",         "Help information")
    ("vadd_size,vs",   po::value<int>()->default_value (4096), "Size of the vector used for vector add")
    ("card_no,c",      po::value<int>()->default_value (0), "Card number")
    ("irq,I",          "Enable interrupt mode");

    po::variables_map options;
    po::store (parse_command_line (argc, argv, desc), options);
    po::notify (options);

    if (options.count ("help")) {
        std::cout << desc << '\n';
        return 0;
    }

    const int  vadd_size = options["vadd_size"].as<int>();
    bool irq_mode = (options.count ("irq") > 0);
    int  card_no  = options["card_no"].as<int>();
    int exit_code = 0;

    std::cout << "IRQ mode: " << irq_mode << std::endl;

    uint32_t* vadd_in1     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_in2     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_out     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_verify  = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));

    std::cout << "============================" << std::endl;
    std::cout << "vadd_in1    address    = 0x"  << std::hex << (uint64_t) vadd_in1 << std::endl;
    std::cout << "vadd_in2    address    = 0x"  << std::hex << (uint64_t) vadd_in2 << std::endl;
    std::cout << "vadd_out    address    = 0x"  << std::hex << (uint64_t) vadd_out << std::endl;
    std::cout << "vadd_verify address    = 0x"  << std::hex << (uint64_t) vadd_verify << std::endl;
    std::cout << "vadd_size              = "    << std::dec << vadd_size << std::endl;
    std::cout << "============================" << std::endl;

    // vadd input initialization and verify calculation
    for (int i = 0; i < vadd_size; i++) {
        vadd_in1[i] = i;
        vadd_in2[i] = i * 2;
        vadd_out[i] = 0;
        vadd_verify[i] = vadd_in1[i] + vadd_in2[i];
    }

    OcaccelJobManager* job_manager_ptr = OcaccelJobManager::getManager();
    job_manager_ptr->setNumberOfJobDescriptors (1);

    // Initialize job manager
    job_manager_ptr->initialize (card_no, "hls_vadd");

    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<vadd> job_desc = job_manager_ptr->getJobDescriptorPtr<vadd> (0);
    job_desc->setKernelParameter<vadd::PARAM::size> (vadd_size);
    job_desc->setKernelParameter<vadd::PARAM::out_r_1> (addr_lo (vadd_out));
    job_desc->setKernelParameter<vadd::PARAM::out_r_2> (addr_hi (vadd_out));
    job_desc->setKernelParameter<vadd::PARAM::in1_1> (addr_lo (vadd_in1));
    job_desc->setKernelParameter<vadd::PARAM::in1_2> (addr_hi (vadd_in1));
    job_desc->setKernelParameter<vadd::PARAM::in2_1> (addr_lo (vadd_in2));
    job_desc->setKernelParameter<vadd::PARAM::in2_2> (addr_hi (vadd_in2));


    // Run a job on the kernel
    if (job_manager_ptr->run<vadd> (job_desc)) {
        std::cerr << "Error running jobs" << std::endl;
        return -1;
    }

    std::cout << "Waiting ... " << std::endl;
    if (! (job_manager_ptr->waitAllDone<vadd> (job_desc))) {
        std::cerr << "Timeout waiting for jobs done" << std::endl;
        return -1;
    }

    std::cout << "Vadd Job finished!" << std::endl;

    // Verify the result
    for (int i = 0 ; i < vadd_size; i++) {
        if (vadd_out[i] != vadd_verify[i]) {
            std::cerr << "Mismatch on vadd_out[" << i << "] -- "
                      << "actual " << vadd_out[i]
                      << " -- expected " << vadd_verify[i] << std::endl;
            exit_code = EXIT_FAILURE;
            break;
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

    free (vadd_in1);
    free (vadd_in2);
    free (vadd_out);
    free (vadd_verify);
    return exit_code;
}
