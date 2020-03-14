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
 * OCACCEL perf_test Example
 *
 * Demonstration how to get data into the FPGA, process it using a OCACCEL
 * action and move the data out of the FPGA back to host-DRAM.
 */
#include <getopt.h>
#include <string.h>
#include <libocaccel.h>
#include <ocaccel_job_manager.h>
#include <hdl_perf_test_register_layout.h>

template class JobDescriptor<kernel_perf_test>;

static void usage (const char* prog)
{
    printf ("SNAP String Match (Regular Expression Match) Tool.\n");
    printf ("Usage: %s\n"
            "    -h, --help              | Prints usage information\n"
            "    -C, --card <cardno>     | Card to be used for operation\n"
            "    -t, --timeout           | Timeout after N sec (default 1 sec)\n"
            "    -I, --irq               | Enable Action Done Interrupt (default No Interrupts)\n"
            "    -d, --init_rdata <arg>  | Init read data (set in Host mem), low 28 bit should be 0 for wrap mode\n"
            "    -D, --init_wdata <arg>  | Init write data (send by AFU), low 28 bit should be 0 for wrap mode\n"
            "    -n, --rnum <arg>        | Read transaction number\n"
            "    -N, --wnum <arg>        | Write transaction number\n"
            "    -w, --wrap_patt <arg>   | Wrap pattern\n"
            "                            Pattern: [11:8]  wrap len, address range = (wrap len + 1)*4KB\n"
            "                                     [0]     wrap mode, 0 for incr mode, 1 for wrap mode\n"
            "    -c, --test_count <arg>  | Total number of runtime for each run. Can be set to a large number\n" 
            "                            | for performance test so that we can get the average performance of \n"
            "                            |all the runs.\n"
            "    -p, --rpattern <arg>    | Read pattern\n"
            "    -P, --wpattern <arg>    | Write pattern\n"
            "                            Pattern: [20:16] id_range. for example, 3 means [0,1,2,3]\n"
            "                                     [15:8]  Burst length - 1,        =AXI A*LEN\n"
            "                                     [2:0]   Data width in each beat, =AXI A*SIZE\n"
            , prog);
}
/* 
 * Return 0 if buffer is equal, 
 * Return index+1 if not equal
 */
static uint64_t mem_check(uint8_t *src, uint8_t *dest, uint64_t len)
{
    uint64_t i;

    for (i = 0; i < len; i++) {
        if (*src != *dest)
            return i+1;
        src++; dest++;
    }
    return 0;
}

static void mem_init (void* mem_addr, uint32_t init_data, uint64_t total_bytes)
{

    uint8_t * ptr = (uint8_t*) mem_addr;
    uint32_t fill_data = init_data;
    uint64_t cnt = 0;
    do {
        *(ptr   ) = (fill_data      ) & 0xFF;
        *(ptr+1 ) = (fill_data >>8  ) & 0xFF;
        *(ptr+2 ) = (fill_data >>16 ) & 0xFF;
        *(ptr+3 ) = (fill_data >>24 ) & 0xFF;

        cnt += 4;
        fill_data ++;
        ptr += 4;
    } while (cnt < total_bytes);

}

uint32_t addr_lo (void* ptr)
{
    return (uint32_t) (((uint64_t)ptr) & 0xFFFFFFFF);
}


uint32_t addr_hi (void* ptr)
{
    return (uint32_t) ((((uint64_t)ptr) >> 32) & 0xFFFFFFFF);
}

static uint8_t * alloc_mem (uint32_t align, uint64_t bytes)
{
    uint8_t* a;
    uint64_t bytes2 = bytes + align;
    if (posix_memalign ((void**)&a, align, bytes2) != 0) {
        perror ("FAILED: posix_memalign()");
        return NULL;
    }
    return a;
}

static void get_bandwidth (uint64_t *time_used_array, uint64_t total_bytes, uint32_t test_count, double *bandwidth_array)
{
    uint32_t i;
    uint64_t time;
    uint64_t * ptr_time = (uint64_t*) time_used_array;
    double * ptr_bandwidth = (double*) bandwidth_array;

    for (i=0; i<test_count; i++) {
        time = *ptr_time;
        *ptr_bandwidth = (double)total_bytes / (double)time;
        ptr_time += 1;
        ptr_bandwidth += 1;
    }
}

static double get_average (double *bandwidth_array, uint32_t test_count) 
{
    uint32_t i;
    double sum = 0;
    double average;
    double bandwidth;
    double * ptr_bandwidth = (double*) bandwidth_array;

    for (i=0; i<test_count; i++) {
        bandwidth = *ptr_bandwidth;
        sum = sum + bandwidth;
        ptr_bandwidth += 1;
    }

    average = sum/((double) test_count);
    return average;
}

static double get_min (double *bandwidth_array, uint32_t test_count) {
    uint32_t i;
    double * ptr_bandwidth = (double*) bandwidth_array;
    double min = *ptr_bandwidth;

    for(i=0; i<test_count; i++) {
        if(*ptr_bandwidth < min) {
            min = *ptr_bandwidth;
        }
        ptr_bandwidth += 1;
    }

    return min;
}

static double get_max (double *bandwidth_array, uint32_t test_count) {
    uint32_t i;
    double * ptr_bandwidth = (double*) bandwidth_array;
    double max = *ptr_bandwidth;

    for(i=0; i<test_count; i++) {
        if(*ptr_bandwidth > max) {
            max = *ptr_bandwidth;
        }
        ptr_bandwidth += 1;
    }

    return max;
}

static double get_variance (double *bandwidth_array, uint32_t test_count, double average) 
{
    uint32_t i;
    double variance_sum = 0;
    double variance;
    double bandwidth;
    double * ptr_bandwidth = (double*) bandwidth_array;

    for(i=0; i<test_count; i++) {
        bandwidth = *ptr_bandwidth;
        variance_sum = (bandwidth - average) * (bandwidth - average) + variance_sum;
        ptr_bandwidth += 1;
    }

    variance = variance_sum/((double) test_count);
    //deviation = sqrt(variance);
    return variance;
}

int main (int argc, char* argv[])
{
    //-------------------------------------------------------------------------
    // Program parameters
    //-------------------------------------------------------------------------
    int cmd;
    int exit_code = 0;

    int  timeout             = 200; 
    bool enable_irq          = 0;
    int  card_no             = 0;
    uint32_t init_rdata      = 0x90000000;
    uint32_t init_wdata      = 0xB0000000;
    uint32_t rnum            = 5;
    uint32_t wnum            = 5;
    uint32_t rpattern        = 0x00001F07;
    uint32_t wpattern        = 0x00001F07;
    uint32_t wrap_patt       = 0x00000601;
    uint32_t test_count      = 1;

    uint64_t * time_used_array = NULL; 
    double * bandwidth_array = NULL;

    uint32_t wr_check_len;
    uint32_t wrap_mode;
    uint64_t wr_check_bytes;

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "help"       , no_argument       , NULL , 'h' } ,
            { "card"       , required_argument , NULL , 'C' } ,
            { "timeout"    , required_argument , NULL , 't' } ,
            { "irq"        , no_argument       , NULL , 'I' } ,
            { "wrap_patt"  , required_argument , NULL , 'w' } ,
            { "test_count" , required_argument , NULL , 'c' } ,
            { "init_rdata" , required_argument , NULL , 'd' } ,
            { "init_wdata" , required_argument , NULL , 'D' } ,
            { "rnum"       , required_argument , NULL , 'n' } ,
            { "wnum"       , required_argument , NULL , 'N' } ,
            { "rpattern"   , required_argument , NULL , 'p' } ,
            { "wpattern"   , required_argument , NULL , 'P' } ,
            { 0            , no_argument       , NULL , 0   } 
        };
        cmd = getopt_long (argc, argv, "hC:t:Iw:c:d:D:n:N:p:P:",
                long_options, &option_index);

        if (cmd == -1) { /* all params processed ? */
            break;
        }

        switch (cmd) {
            case 'h':   /* help */
                usage (argv[0]);
                exit (EXIT_SUCCESS);;

            case 'C':   /* card */
                card_no = strtol (optarg, (char**)NULL, 0);
                break;

            case 't':
                timeout = strtol (optarg, (char**)NULL, 0); /* in sec */
                break;

            case 'I':      /* irq */
                enable_irq = 1;
                break;

            case 'w':
                wrap_patt = strtol (optarg, (char**)NULL, 0);
                break;

            case 'c':
                test_count = strtol (optarg, (char**)NULL, 0);
                break;

            case 'd':
                init_rdata = strtol (optarg, (char**)NULL, 0);
                break;

            case 'D':
                init_wdata = strtol (optarg, (char**)NULL, 0);
                break;

            case 'n':
                rnum = strtol (optarg, (char**)NULL, 0);
                break;

            case 'N':
                wnum = strtol (optarg, (char**)NULL, 0);
                break;

            case 'p':
                rpattern = strtol (optarg, (char**)NULL, 0);
                break;

            case 'P':
                wpattern = strtol (optarg, (char**)NULL, 0);
                break;

            default:
                usage (argv[0]);
                exit (EXIT_FAILURE);
        }

    }  // while(1)
    printf("Parameter got: init_rdata = 0x%x\n",init_rdata);
    printf("Parameter got: init_wdata = 0x%x\n",init_wdata);
    printf("Parameter got: rnum       = %d\n"  ,rnum);
    printf("Parameter got: wnum       = %d\n"  ,wnum);
    printf("Parameter got: rpattern   = 0x%x\n",rpattern );
    printf("Parameter got: wpattern   = 0x%x\n",wpattern );
    printf("Parameter got: wrap_patt  = 0x%x\n",wrap_patt);
    printf("Parameter got: test_count = %d\n"  ,test_count);
    printf("IRQ mode: %d\n", enable_irq);

    //Checking parameters
    if (0 == rnum && 0 == wnum) {
        printf("Both Read Number and Write Number are zero. Exit.\n");
        exit_code = -1;
        return exit_code;
    }
    
    //-------------------------------------------------------------------------
    // Allocate Memory buffers
    //-------------------------------------------------------------------------
    uint32_t i;
    uint32_t rsize      , wsize;    //AXI Size field, used to calculate r/w width
    uint32_t rwidth     , wwidth;   //transaction width in bytes
    uint32_t rblen      , wblen;    //burst length
    uint64_t rtotal_bytes, wtotal_bytes;
    uint32_t size_4KB = 4096;
    uint32_t size_128MB = 134217728;

    rsize = (rpattern & 0x7);
    wsize = (wpattern & 0x7);



    rwidth = 1;
    wwidth = 1;

    for(i=0; i<rsize; i++) {
        rwidth = rwidth*2;
    }
    for(i=0; i<wsize; i++) {
        wwidth = wwidth*2;
    }

    rblen = 1 + ((rpattern & 0xFF00) >> 8);
    wblen = 1 + ((wpattern & 0xFF00) >> 8);

    rtotal_bytes = (uint64_t)rnum * (uint64_t)rblen * (uint64_t)rwidth;
    wtotal_bytes = (uint64_t)wnum * (uint64_t)wblen * (uint64_t)wwidth;

    printf("Parse pattern. Read: num = %d, bytes-width = %d, burst len = %d, total bytes = %ld\n",
            rnum, rwidth, rblen, rtotal_bytes);
    printf("Parse pattern. Write:num = %d, bytes-width = %d, burst len = %d, total bytes = %ld\n",
            wnum, wwidth, wblen, wtotal_bytes);

    if (rsize < 2 || wsize < 2) {
        printf("Doesn't support AXI transfers narrower than 4 bytes\n");
        exit_code = -1;
        return exit_code;
    }

    if ((rblen * rwidth) < 128 || (wblen * wwidth) < 128) {
        printf("Doesn't support transfer bytes less than 128B\n");
        exit_code = -1;
        return exit_code;
    }


    uint8_t* src_base=NULL;
    uint8_t* tgt_base=NULL;
    uint8_t* exp_buff=NULL;

    if(wrap_patt == 0){
        src_base = alloc_mem (size_4KB, rtotal_bytes);
        tgt_base = alloc_mem (size_4KB, wtotal_bytes);
        exp_buff = alloc_mem (size_4KB, wtotal_bytes);
        mem_init (src_base, init_rdata, rtotal_bytes);
        mem_init (exp_buff, init_wdata, wtotal_bytes);
        memset (tgt_base, 0, wtotal_bytes);
    } else {
        src_base  = alloc_mem(size_128MB, size_128MB); // src address must be 128MB alignment
        tgt_base = alloc_mem (size_128MB, size_128MB); // targer address must be 128MB alignment
        exp_buff  = alloc_mem(size_128MB, size_128MB);
        mem_init (src_base, init_rdata, size_128MB);
        mem_init (exp_buff, init_wdata, size_128MB);
        memset (tgt_base, 0, size_128MB);
    } 
    

    printf("Source address      (for AFU reads)  starts at 0x%p\n", src_base);
    printf("Destination address (for AFU writes) starts at 0x%p\n", tgt_base);
    printf("Expected data buff (for Write-check) statts at 0x%p\n", exp_buff);



    //-------------------------------------------------------------------------
    // Prepare Job descriptors
    //-------------------------------------------------------------------------
    int  num_job_descriptors = 2;
    //We have only 1 kernel, and two types of job descriptors.
    // Descriptor 0: Clear the Time Trace RAM
    // Descriptor 1: Kick off the AFU read-write tests. It will be run many times.


    OcaccelJobManager* job_manager_ptr = OcaccelJobManager::getManager();
    job_manager_ptr->setNumberOfJobDescriptors (num_job_descriptors);

    // Initialize job manager (including opening the FPGA device)
    job_manager_ptr->initialize (card_no, "hdl_perf_test");

    // The data struct provides information of kernel's register layout.
    // "perf_test" is a class defined in the "register layout" header file.

    // ------------------------------------------------------------
    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<kernel_perf_test> job_desc_0 = job_manager_ptr->getJobDescriptorPtr<kernel_perf_test> (0);
    // job_desc_0->scheduleToKernel(0);
    
    // Descriptor 0 only needs to set a working mode register. Nothing else is needed.
    const uint32_t CLEAR_TT_RAM = 0x80000000; 
    job_desc_0->setKernelParameter<kernel_perf_test::PARAM::reg_user_mode>    (CLEAR_TT_RAM);


    // ------------------------------------------------------------
    // Get a job descriptor and configure it with kernel parameters
    JobDescriptorPtr<kernel_perf_test> job_desc_1 = job_manager_ptr->getJobDescriptorPtr<kernel_perf_test> (1);
    // job_desc_1->scheduleToKernel(0);
    
    // Descriptor 1 needs to set various parameters
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_user_mode>    (wrap_patt);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_source_address_l> (addr_lo (src_base));
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_source_address_h> (addr_hi (src_base));
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_target_address_l> (addr_lo (tgt_base));
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_target_address_h> (addr_hi (tgt_base));
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_init_rdata>   (init_rdata);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_init_wdata>   (init_wdata);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_rd_pattern>   (rpattern);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_wr_pattern>   (wpattern);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_rd_number>    (rnum);
    job_desc_1->setKernelParameter<kernel_perf_test::PARAM::reg_wr_number>    (wnum);


    //-------------------------------------------------------------------------
    // Run Jobs
    //-------------------------------------------------------------------------


    // Run a job on the kernel
    if (job_manager_ptr->run<kernel_perf_test> (job_desc_0)) {
        printf("Error running jobs\n");
        exit_code = -1;
        goto cleanup;
    }

    if (job_manager_ptr->waitAllDone (job_desc_0, timeout))
        printf("Job 0 (Clear Time Trace RAM) finished!\n");
    else {
        printf("Job 0 (Clear Time Trace RAM) timeout (t = %d)\n", timeout);
        exit_code = -1;
        goto cleanup;
    }



    // Run a job on the kernel
    // We record the time in use to calculate bandwidth
    time_used_array = new uint64_t [test_count];
    bandwidth_array = new  double [test_count];
        
    if (NULL == time_used_array) {
        printf("Failed to create time_used_array\n");
        exit_code = -1;
        goto cleanup;
    }
    if (NULL == bandwidth_array) {
        printf("Failed to create bandwidth_array\n");
        exit_code = -1;
        goto cleanup;
    }
    
    uint64_t stime, etime;
    uint32_t user_status;

    for (i = 0; i < test_count; i ++ ) {
        printf("Read-Write Transactions Start. ( %d of %d )\n", i+1, test_count);
        
        //Kick off Start
        stime = ocaccel_tget_us();
        if (job_manager_ptr->run<kernel_perf_test> (job_desc_1)) {
            printf("Error running jobs\n");
            exit_code = -1;
            goto cleanup;
        }

        //Wait for done
        if (job_manager_ptr->waitAllDone (job_desc_1, timeout)) {
            etime = ocaccel_tget_us();
            time_used_array[i] = etime - stime;
            printf("Read-Write Transactions Finished. ( %d of %d )\n", i+1, test_count);
        }
        else {
            printf("Read-Write Transactions ( %d of %d ) Timeout! (t = %d)\n", i+1, test_count, timeout);
            exit_code = -1;
            goto cleanup;
        }



        // Check done status
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_user_status)   , &(user_status));
        if ((user_status & 0xFFFC) != 0) {
            printf( "read data error = %d, read resp error = %d, write resp error = %d\n",
                    (user_status & 0x10)>>4, (user_status & 0x8)>>3, (user_status & 0x4)>>2 );
            printf( "Transaction Error Detected.\n");
            printf( "Soft rest!\n");
            job_manager_ptr->actionWrite32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_soft_reset)   , 1);

        } else {
            printf("Finished normally. No errors detected.\n");
        }


    }

    sleep (1);
    //job_manager_ptr->dump();

    //-------------------------------------------------------------------------
    // Dump Time Trace Array
    // An example to show how to directly access the Action Kernel registers
    //-------------------------------------------------------------------------


    uint32_t tt_rd_cmd[4096];
    uint32_t tt_rd_rsp[4096];
    uint32_t tt_wr_cmd[4096];
    uint32_t tt_wr_rsp[4096];
    uint32_t tt_arid[4096];
    uint32_t tt_awid[4096];
    uint32_t tt_rid[4096];
    uint32_t tt_bid[4096];
    FILE * file_rtt;
    FILE * file_wtt;

    file_rtt = fopen("file_rd_cycle", "w");
    file_wtt = fopen("file_wr_cycle", "w");
    uint32_t cnt;

    for (cnt = 0; cnt < ((rnum > 4096)? 4096: rnum); cnt++) {

        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_arid)   , &(tt_arid[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_rd_cmd) , &(tt_rd_cmd[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_rid)    , &(tt_rid[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_rd_rsp) , &(tt_rd_rsp[cnt]));

        fprintf(file_rtt, "%8d, %16d, %8d, %16d\n", tt_arid[cnt], tt_rd_cmd[cnt], tt_rid[cnt], tt_rd_rsp[cnt]);
    }

    for (cnt = 0; cnt < ((wnum > 4096)? 4096: wnum); cnt++) {
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_awid)   , &(tt_awid[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_wr_cmd) , &(tt_wr_cmd[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_bid)    , &(tt_bid[cnt]));
        job_manager_ptr->actionRead32 (job_desc_1->getScheduledKernelID(), job_desc_1->getKernel()->KERNEL_PARAM ((int) kernel_perf_test::PARAM::reg_tt_wr_rsp) , &(tt_wr_rsp[cnt]));
        fprintf(file_wtt, "%8d, %16d, %8d, %16d\n", tt_awid[cnt], tt_wr_cmd[cnt], tt_bid[cnt], tt_wr_rsp[cnt]);
    }

    fclose(file_rtt);
    fclose(file_wtt); 

    //--
    //-------------------------------------------------------------------------
    // Verify
    //-------------------------------------------------------------------------
    wr_check_len = ((wrap_patt & 0xF00) >> 8);
    wrap_mode = wrap_patt & 0x1;
    if(wrap_mode == 1) {
        wr_check_bytes = ((uint64_t)wr_check_len + 1) * 4096;
        if(wr_check_bytes > wtotal_bytes){
              wr_check_bytes = wtotal_bytes; 
        }
    } else {
        wr_check_bytes = wtotal_bytes;
    }


    printf("Check data written back to host memory\n");
    if (wnum != 0) {
        if (mem_check (tgt_base, exp_buff, wr_check_bytes)) {
            printf("Write Data Checking Failed! \n");
            //TODO： Dump File 
         //   file_target = fopen("dump_target", "w");
         //   file_expect = fopen("dump_expect", "w");
         //   __hexdump(file_target, tgt_base, wr_check_bytes);
         //   __hexdump(file_expect, exp_buff, wr_check_bytes);
         //   fclose(file_target);
         //   fclose(file_expect);
            exit_code = -1;
            goto cleanup;
        } else {
            printf("WRITE Check PASSED!\n");
        }
    }
    
    //-------------------------------------------------------------------------
    // Print Bandwidth Statistics
    // Only for three cases:
    // wnum = 0: print Read bandwidth
    // rnum = 0: print Write bandwidth
    // wnum = rnum: print duplex bandwidth
    //-------------------------------------------------------------------------

    uint64_t total_bytes;
    double average_bandwidth;
    double min_bandwidth;
    double max_bandwidth;
    double variance;

    if(wnum == 0) {
        total_bytes = rtotal_bytes;
    } else {
        total_bytes = wtotal_bytes;
    }

    get_bandwidth(time_used_array, total_bytes, test_count, bandwidth_array);
    average_bandwidth = get_average(bandwidth_array, test_count);
    min_bandwidth = get_min(bandwidth_array, test_count);
    max_bandwidth = get_max(bandwidth_array, test_count);
    variance = get_variance(bandwidth_array, test_count, average_bandwidth);

    if (wnum == rnum && wpattern == rpattern) //Only measure duplex bandwidth when R and W are same.
    {
        printf("Duplex average bandwidth: %ld bytes  ( %.3f MB/s )\n",
                total_bytes,  average_bandwidth);
        printf("Duplex bandwidth min, max and variance: %ld bytes ( %.3f MB/s, %.3f MB/s, %.3f )\n",
                total_bytes,  min_bandwidth, max_bandwidth, variance);
    }

    if (wnum == 0)
    {
        printf("Read average bandwidth (Host->FPGA): %ld bytes ( %.3f MB/s )\n",
                rtotal_bytes,  average_bandwidth);
        printf("Read bandwidth min, max and variance: %ld bytes ( %.3f MB/s, %.3f MB/s, %.3f )\n",
                rtotal_bytes,  min_bandwidth, max_bandwidth, variance);
    }

    if (rnum == 0)
    {
        printf("Write average bandwidth (FPGA->Host): %ld bytes ( %.3f MB/s )\n",
                wtotal_bytes,  average_bandwidth);
        printf("Write bandwidth min, max and variance: %ld bytes ( %.3f MB/s, %.3f MB/s, %.3f MB/s )\n",
                wtotal_bytes,  min_bandwidth, max_bandwidth, variance);
    }



cleanup:
    job_manager_ptr->clear();

    if (time_used_array) 
        delete time_used_array;
    if (bandwidth_array)
        delete bandwidth_array;

    if (src_base)
        free (src_base);
    if (tgt_base)
        free (tgt_base);
    if (exp_buff)
        free (exp_buff);

    return exit_code;
}
