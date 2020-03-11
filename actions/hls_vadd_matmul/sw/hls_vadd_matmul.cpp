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
#include <hls_matmul_register_layout.h>

namespace po = boost::program_options;
#define ACTION_TYPE               0x10143009
template class JobDescriptor<vadd>;
template class JobDescriptor<matmul>;

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
    ("matmul_size,ms", po::value<int>()->default_value (16), "Size of matrix used for matrix multiplication")
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
    const int  matmul_size = options["matmul_size"].as<int>();
    bool irq_mode = (options.count ("irq") > 0);
    int  card_no  = options["card_no"].as<int>();
    int exit_code = 0;

    const int num_vadd_job_descriptors = 2;
    const int num_matmul_job_descriptors = 2;

    std::cout << "IRQ mode: " << irq_mode << std::endl;

    uint32_t* vadd_in1     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_in2     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_out     = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    uint32_t* vadd_verify  = (uint32_t*) ocaccel_malloc (vadd_size * sizeof (uint32_t));
    int* matmul_in1        = (int*) ocaccel_malloc (matmul_size * matmul_size * sizeof (int));
    int* matmul_in2        = (int*) ocaccel_malloc (matmul_size * matmul_size * sizeof (int));
    int* matmul_out        = (int*) ocaccel_malloc (matmul_size * matmul_size * sizeof (int));
    int* matmul_verify     = (int*) ocaccel_malloc (matmul_size * matmul_size * sizeof (int));

    std::cout << "============================" << std::endl;
    std::cout << "vadd_in1    address    = 0x"  << std::hex << (uint64_t) vadd_in1 << std::endl;
    std::cout << "vadd_in2    address    = 0x"  << std::hex << (uint64_t) vadd_in2 << std::endl;
    std::cout << "vadd_out    address    = 0x"  << std::hex << (uint64_t) vadd_out << std::endl;
    std::cout << "vadd_verify address    = 0x"  << std::hex << (uint64_t) vadd_verify << std::endl;
    std::cout << "vadd_size              = "    << std::dec << vadd_size << std::endl;
    std::cout << "============================" << std::endl;

    std::cout << "============================" << std::endl;
    std::cout << "matmul_in1    address  = 0x" << std::hex << (uint64_t) matmul_in1 << std::endl;
    std::cout << "matmul_in2    address  = 0x" << std::hex << (uint64_t) matmul_in2 << std::endl;
    std::cout << "matmul_out    address  = 0x" << std::hex << (uint64_t) matmul_out << std::endl;
    std::cout << "matmul_verify address  = 0x" << std::hex << (uint64_t) matmul_verify << std::endl;
    std::cout << "matmul_size            = "   << std::dec << matmul_size << std::endl;
    std::cout << "============================" << std::endl;

    // vadd input initialization and verify calculation
    for (int i = 0; i < vadd_size; i++) {
        vadd_in1[i] = i;
        vadd_in2[i] = i * 2;
        vadd_out[i] = 0;
        vadd_verify[i] = vadd_in1[i] + vadd_in2[i];
    }

    // matmul input initialization and verify calculation
    for (int row = 0; row < matmul_size; row++) {
        for (int col = 0; col < matmul_size; col++) {
            matmul_in1[row * matmul_size + col] = row;
            matmul_in2[row * matmul_size + col] = col;
            matmul_out[row * matmul_size + col] = 0;
            matmul_verify[row * matmul_size + col] = 0;
        }
    }

    for (int k = 0; k < matmul_size; k++) {
        for (int j = 0; j < matmul_size; j++) {
            for (int i = 0; i < matmul_size; i++) {
                matmul_verify[k * matmul_size + j] += matmul_in1[k * matmul_size + i] * matmul_in2[i * matmul_size + j];
            }
        }
    }

    OcaccelJobManager* job_manager_ptr = OcaccelJobManager::getManager();
    job_manager_ptr->setNumberOfJobDescriptors (num_vadd_job_descriptors + num_matmul_job_descriptors);

    // Initialize job manager
    job_manager_ptr->initialize (card_no, "hls_vadd_matmul");

    for (int i = 0; i < num_vadd_job_descriptors; i++) {
        // Get a job descriptor and configure it with kernel parameters
        JobDescriptorPtr<vadd> job_desc = job_manager_ptr->getJobDescriptorPtr<vadd> (i);
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

        if (! (job_manager_ptr->waitAllDone<vadd> (job_desc, 100))) {
            std::cerr << "Timeout waiting for jobs done" << std::endl;
            return -1;
        }

        std::cout << "Vadd Job" << i << " finished!" << std::endl;

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

        if (EXIT_FAILURE == exit_code) {
            goto __ERROR;
        }
    }

    for (int i = 0; i < num_matmul_job_descriptors; i++) {
        // Get a job descriptor and configure it with kernel parameters
        JobDescriptorPtr<matmul> job_desc = job_manager_ptr->getJobDescriptorPtr<matmul> (i + num_vadd_job_descriptors);
        job_desc->setKernelParameter<matmul::PARAM::size> (matmul_size);
        job_desc->setKernelParameter<matmul::PARAM::out_r_1> (addr_lo (matmul_out));
        job_desc->setKernelParameter<matmul::PARAM::out_r_2> (addr_hi (matmul_out));
        job_desc->setKernelParameter<matmul::PARAM::in1_1> (addr_lo (matmul_in1));
        job_desc->setKernelParameter<matmul::PARAM::in1_2> (addr_hi (matmul_in1));
        job_desc->setKernelParameter<matmul::PARAM::in2_1> (addr_lo (matmul_in2));
        job_desc->setKernelParameter<matmul::PARAM::in2_2> (addr_hi (matmul_in2));

        // Run a job on the kernel
        if (job_manager_ptr->run<matmul> (job_desc)) {
            std::cerr << "Error running jobs" << std::endl;
            return -1;
        }

        if (! (job_manager_ptr->waitAllDone<matmul> (job_desc, 500))) {
            std::cerr << "Timeout waiting for jobs done" << std::endl;
            return -1;
        }

        std::cout << "Matmul Job" << i << " finished!" << std::endl;

        for (int row = 0; row < matmul_size; row++) {
            for (int col = 0; col < matmul_size; col++) {
                if (matmul_out[row * matmul_size + col] != matmul_verify[row * matmul_size + col]) {
                    std::cerr << "Mismatch on matmul_out[" << row << "]" << "[" << col << "] -- "
                              << "actual " << matmul_out[row * matmul_size + col]
                              << " -- expected " << matmul_verify[row * matmul_size + col] << std::endl;
                    exit_code = EXIT_FAILURE;
                }
            }
        }

        if (EXIT_FAILURE == exit_code) {
            goto __ERROR;
        }
    }

    sleep (1);
    job_manager_ptr->dump();

    if (0 == exit_code) {
        printf ("Data checking OK.\n");
    }

__ERROR:
    job_manager_ptr->clear();

    free (vadd_in1);
    free (vadd_in2);
    free (vadd_out);
    free (vadd_verify);
    return exit_code;
}
