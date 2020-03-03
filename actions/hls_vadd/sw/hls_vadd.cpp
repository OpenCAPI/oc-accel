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
    ("help,h", "Help information")
    ("size,s",    po::value<int>()->default_value (4096), "Size")
    ("card_no,c", po::value<int>()->default_value (0), "Card number")
    ("irq,I",  "Enable interrupt mode");

    po::variables_map options;
    po::store (parse_command_line (argc, argv, desc), options);
    po::notify (options);

    if (options.count ("help")) {
        std::cout << desc << '\n';
        return 0;
    }

    int  job_size = options["size"].as<int>();
    bool irq_mode = (options.count ("irq") > 0);
    int  card_no  = options["card_no"].as<int>();
    int  num_job_descriptors = 2;

    std::cout << "Running with job size: " << std::dec << job_size << std::endl;
    std::cout << "IRQ mode: " << irq_mode << std::endl;

    uint32_t* in1_buff     = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* in2_buff     = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* in3_buff     = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* result1_buff = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* result2_buff = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* verify1_buff = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));
    uint32_t* verify2_buff = (uint32_t*) ocaccel_malloc (job_size * sizeof (uint32_t));

    std::cout << "============================" << std::endl;
    std::cout << "in1_buff address     = 0x" << std::hex << (uint64_t) in1_buff << std::endl;
    std::cout << "in2_buff address     = 0x" << std::hex << (uint64_t) in2_buff << std::endl;
    std::cout << "in3_buff address     = 0x" << std::hex << (uint64_t) in3_buff << std::endl;
    std::cout << "result1_buff address = 0x" << std::hex << (uint64_t) result1_buff << std::endl;
    std::cout << "result2_buff address = 0x" << std::hex << (uint64_t) result2_buff << std::endl;
    std::cout << "verify1_buff address = 0x" << std::hex << (uint64_t) verify1_buff << std::endl;
    std::cout << "verify2_buff address = 0x" << std::hex << (uint64_t) verify2_buff << std::endl;
    std::cout << "job_size             = "   << std::dec << job_size << std::endl;
    std::cout << "============================" << std::endl;

    for (int i = 0; i < job_size; i++) {
        in1_buff[i] = i;     //Give a simple number for easier debugging.
        in2_buff[i] = i * 2; //Give a simple number for easier debugging.
        in3_buff[i] = i * 3; //Give a simple number for easier debugging.
        result1_buff[i] = 0; //Wait FPGA to calculate
        result2_buff[i] = 0; //Wait FPGA to calculate
        verify1_buff[i] = in1_buff[i] + in2_buff[i];
        verify2_buff[i] = in1_buff[i] + in3_buff[i];
    }

    OcaccelJobManager* job_manager_ptr = OcaccelJobManager::getManager();
    job_manager_ptr->setNumberOfJobDescriptors (num_job_descriptors);

    // Initialize job manager
    job_manager_ptr->initialize (card_no, "hls_vadd");

    // The data struct provides information of kernel's register layout.
    // This class is auto generated for hls kernels during model build.
    //vaddRegisterLayout kernel_reg_layout;

    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<vadd> job_desc_0 = job_manager_ptr->getJobDescriptorPtr<vadd> (0);
    job_desc_0->setKernelID (0);
    job_desc_0->setKernelParameter<vadd::PARAM::size>    (job_size);
    job_desc_0->setKernelParameter<vadd::PARAM::out_r_1> (addr_lo (result1_buff));
    job_desc_0->setKernelParameter<vadd::PARAM::out_r_2> (addr_hi (result1_buff));
    job_desc_0->setKernelParameter<vadd::PARAM::in1_1>   (addr_lo (in1_buff));
    job_desc_0->setKernelParameter<vadd::PARAM::in1_2>   (addr_hi (in1_buff));
    job_desc_0->setKernelParameter<vadd::PARAM::in2_1>   (addr_lo (in2_buff));
    job_desc_0->setKernelParameter<vadd::PARAM::in2_2>   (addr_hi (in2_buff));

    // Run a job on the kernel
    if (job_manager_ptr->run<vadd> (job_desc_0)) {
        std::cerr << "Error running jobs" << std::endl;
        return -1;
    }

    while (OcaccelJobManager::eStatus::FINISHED != job_manager_ptr->status<vadd> (job_desc_0->getKernel())) {
    }

    std::cout << "Job 0 finished!" << std::endl;

    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<vadd> job_desc_1 = job_manager_ptr->getJobDescriptorPtr<vadd> (1);
    job_desc_1->setKernelID (1);
    job_desc_1->setKernelParameter<vadd::PARAM::size>    (job_size);
    job_desc_1->setKernelParameter<vadd::PARAM::out_r_1> (addr_lo (result2_buff));
    job_desc_1->setKernelParameter<vadd::PARAM::out_r_2> (addr_hi (result2_buff));
    job_desc_1->setKernelParameter<vadd::PARAM::in1_1>   (addr_lo (in1_buff));
    job_desc_1->setKernelParameter<vadd::PARAM::in1_2>   (addr_hi (in1_buff));
    job_desc_1->setKernelParameter<vadd::PARAM::in2_1>   (addr_lo (in3_buff));
    job_desc_1->setKernelParameter<vadd::PARAM::in2_2>   (addr_hi (in3_buff));

    // Run a job on the kernel
    if (job_manager_ptr->run<vadd> (job_desc_1)) {
        std::cerr << "Error running jobs" << std::endl;
        return -1;
    }

    while (OcaccelJobManager::eStatus::FINISHED != job_manager_ptr->status<vadd> (job_desc_1->getKernel())) {
    }

    std::cout << "Job 1 finished!" << std::endl;

    sleep (2);
    job_manager_ptr->dump();

    // Verify
    int exit_code = 0;

    for (int i = 0 ; i < job_size; i++) {
        if (result1_buff[i] != verify1_buff[i]) {
            std::cerr << "Mismatch on result1_buff[" << i << "] -- "
                      << "actual " << result1_buff[i]
                      << " -- expected " << verify1_buff[i] << std::endl;
            exit_code = EXIT_FAILURE;
            break;
        }
    }

    for (int i = 0 ; i < job_size; i++) {
        if (result2_buff[i] != verify2_buff[i]) {
            std::cerr << "Mismatch on result2_buff[" << i << "] -- "
                      << "actual " << result2_buff[i]
                      << " -- expected " << verify2_buff[i] << std::endl;
            exit_code = EXIT_FAILURE;
            break;
        }
    }

    if (0 == exit_code) {
        printf ("Data checking OK.\n");
    }

    job_manager_ptr->clear();

    free (in1_buff);
    free (in2_buff);
    free (in3_buff);
    free (result1_buff);
    free (result2_buff);
    free (verify1_buff);
    free (verify2_buff);
    return exit_code;
}
