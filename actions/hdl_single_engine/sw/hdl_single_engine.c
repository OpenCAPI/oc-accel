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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <math.h>
#include <getopt.h>
#include <ctype.h>

#include <libosnap.h>
#include <libocxl.h>
#include <osnap_tools.h>
#include <osnap_global_regs.h>

#include "hdl_single_engine.h"

/*  defaults */
#define ACTION_WAIT_TIME    50   /* Default in sec */

#define MEGAB       (1024*1024ull)
#define GIGAB       (1024 * MEGAB)

#define VERBOSE0(fmt, ...) do {         \
    printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE1(fmt, ...) do {         \
    if (verbose_level > 0)          \
    printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE2(fmt, ...) do {         \
    if (verbose_level > 1)          \
    printf(fmt, ## __VA_ARGS__);    \
} while (0)


#define VERBOSE3(fmt, ...) do {         \
    if (verbose_level > 2)          \
    printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE4(fmt, ...) do {         \
    if (verbose_level > 3)          \
    printf(fmt, ## __VA_ARGS__);    \
} while (0)

//struct snap_card {
//    void* priv;
//    ocxl_afu_h afu_h;
//    bool master;                    /* True if this is Master Device */
//    int cir;                        /* Context id */
//    ocxl_endian mmio_endian;
//    ocxl_mmio_h mmio_global;
//    ocxl_mmio_h mmio_per_pasid;
//
//    uint32_t action_base;
//    uint16_t vendor_id;
//    uint16_t device_id;
//    snap_action_type_t action_type; /* Action Type for attach */
//    snap_action_flag_t action_flags;
//    uint32_t sat;                   /* Short Action Type */
//    bool start_attach;
//    snap_action_flag_t flags;       /* Flags from Application */
//    uint16_t seq;                   /* Seq Number */
//    int afu_fd;
//
//    struct snap_sim_action* action; /* software simulation mode */
//    size_t errinfo_size;            /* Size of errinfo */
//    void* errinfo;                  /* Err info Buffer */
//    ocxl_event event;               /* Buffer to keep event from IRQ */
//    ocxl_irq_h afu_irq;             /* The IRQ handler. TODO: add support to multi process */ 
//    uint64_t irq_ea;                /* The IRQ EA/obj_handler. TODO: add support to multi process */ 
//    unsigned int attach_timeout_sec;
//    unsigned int queue_length;      /* unused */
//    uint64_t cap_reg;               /* Capability Register */
//    const char* name;               /* Card name */
//};

static const char* version = GIT_VERSION;
static  int verbose_level = 0;

static uint64_t get_usec (void)
{
    struct timeval t;

    gettimeofday (&t, NULL);
    return t.tv_sec * 1000000 + t.tv_usec;
}


static void* alloc_mem (uint32_t align, uint64_t bytes)
{
    void* a;
    uint64_t bytes2 = bytes + align;

    VERBOSE2 ("%s Enter Align: %d Size: %ld\n", __func__, align, bytes);

    if (posix_memalign ((void**)&a, align, bytes2) != 0) {
        perror ("FAILED: posix_memalign()");
        return NULL;
    }

    VERBOSE2 ("%s Exit %p\n", __func__, a);
    return a;
}

static void free_mem (void* a)
{
    VERBOSE2 ("Free Mem %p\n", a);

    if (a) {
        free (a);
    }
}


/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write (struct snap_card* h, uint32_t addr, uint32_t data)
{
    int rc;

    rc = snap_action_write32 (h, (uint64_t)addr, data);

    if (0 != rc) {
        VERBOSE0 ("Write MMIO 32 Err\n");
    }

    return;
}

static uint32_t action_read(struct snap_card* h, uint32_t addr)
{
    int rc;
    uint32_t data;

    rc = snap_action_read32(h, (uint64_t)addr, &data);
    if (0 != rc)
        VERBOSE0("Read MMIO 32 Err\n");
    return data;
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

static int run_single_engine (struct snap_card* h,
        uint32_t timeout,
        void* src_base,
        void* tgt_base,
        uint32_t rnum, uint32_t wnum, 
        uint32_t init_rdata, uint32_t init_wdata,
        uint32_t wrap_pattern,
        uint32_t rpattern, uint32_t wpattern,
        uint64_t *td
        )
{
    int rc         = 0;
    int ready      = 0;
    int read_error = 0;
    int both_done  = 0;
    uint64_t t_start;
    uint32_t cnt;
    uint32_t reg_data;
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

    VERBOSE0 (" ----- START SNAP_CONTROL ----- \n");
    snap_action_start ((void*)h);

    VERBOSE0 (" ----- CONFIG PARAMETERS ----- \n");
    action_write(h, REG_USER_MODE, wrap_pattern);
    action_write(h, REG_SOURCE_ADDRESS_L, (uint32_t) (((uint64_t) src_base) & 0xffffffff));
    action_write(h, REG_SOURCE_ADDRESS_H, (uint32_t) ((((uint64_t) src_base) >> 32) & 0xffffffff));

    action_write(h, REG_TARGET_ADDRESS_L, (uint32_t) (((uint64_t) tgt_base) & 0xffffffff));
    action_write(h, REG_TARGET_ADDRESS_H, (uint32_t) ((((uint64_t) tgt_base) >> 32) & 0xffffffff));

    action_write(h, REG_INIT_RDATA, init_rdata);
    action_write(h, REG_INIT_WDATA, init_wdata);

    action_write(h, REG_RD_PATTERN, rpattern);
    action_write(h, REG_WR_PATTERN, wpattern);

    action_write(h, REG_RD_NUMBER, rnum);
    action_write(h, REG_WR_NUMBER, wnum);


    VERBOSE0 (" ----- Check if AFU is ready ----- \n");
    cnt = 0;
    do { 
        reg_data = action_read(h, REG_USER_STATUS);
        if ((reg_data & 0x20) > 0) {
            ready=1;
            VERBOSE0 ("AFU has finished cleaning TT RAM. Ready to start AXI transactions.\n");
            break;
        }
        cnt ++;
    } while (cnt < 300);

    if(ready == 0) {
        VERBOSE0("ERROR: AFU not ready! \n");
        action_write(h, REG_SOFT_RESET, 0x00000001);
        action_write(h, REG_SOFT_RESET, 0x00000000);

        rc += 0x2;
        return rc;
    }

    VERBOSE0 (" ----- Tell AFU to kick off AXI transactions ----- \n");
    action_write(h, REG_USER_CONTROL, 0x00000001);
    t_start = get_usec();

    cnt = 0;
    do { 
        reg_data = action_read(h, REG_USER_STATUS);
        if ((reg_data & 0x3) == 0x3 ){
            both_done = 1;
            VERBOSE0 ("AFU has finished all transactions.\n");
            break;
        }
        if ((reg_data & 0x10) > 0 ){
            read_error = 1;
            VERBOSE0 ("ERROR: AFU meets a read checking error.\n");
            break;
        }
        cnt ++;
    } while (cnt < timeout * 1000); //Use timeout to emulate max allowed MMIO read times

    *td = get_usec() - t_start;
    VERBOSE0 ("Runtime is: %ld\n", *td);

    //uint64_t mmio_reg_data;

    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_CMD, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx command is:                      %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_RSP, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx response is:                     %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_RTY, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx retry response is:               %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_FAIL, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx fail response is:                %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_XLP, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx translation pending response is: %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_TLX_XLD, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of tlx translation done response is:    %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_AXI_W_CMD, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of axi write commands is:               %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_AXI_W_RSP, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of axi write response is:               %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_AXI_R_CMD, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of axi read commands is:                %16x\n", mmio_reg_data); 
    //ocxl_mmio_read64(h->mmio_global, DEBUG_CNT_AXI_R_RSP, h->mmio_endian, &mmio_reg_data);
    //VERBOSE0 ("Total number of axi read response is:                %16x\n", mmio_reg_data); 

    int exp_data;
    int act_data;
    if(read_error) {
        exp_data=action_read(h,REG_ERROR_INFO_L);	
        act_data=action_read(h,REG_ERROR_INFO_H);	
        action_write(h, REG_SOFT_RESET, 0x00000001);
        action_write(h, REG_SOFT_RESET, 0x00000000);
        VERBOSE0 ("Expected data is:%8x\n",exp_data);
        VERBOSE0 ("Actual data is:%8x\n",act_data);
        rc += 0x4;
        return rc;
    }
    if( !both_done) {
        VERBOSE0 ("Timeout! Transactions haven't been finished.\n");

        action_write(h, REG_SOFT_RESET, 0x00000001);
        action_write(h, REG_SOFT_RESET, 0x00000000);
        rc += 0x8;
        return rc;
    }

    VERBOSE0 (" ----- Dump TT Arrays ----- \n");
    file_rtt = fopen("file_rd_cycle", "w");
    file_wtt = fopen("file_wr_cycle", "w");

    for (cnt = 0; cnt < ((rnum > 4096)? 4096: rnum); cnt++) {
        tt_arid[cnt]   = action_read(h, REG_TT_ARID);
        tt_rd_cmd[cnt] = action_read(h, REG_TT_RD_CMD);
        tt_rid[cnt]    = action_read(h, REG_TT_RID);
        tt_rd_rsp[cnt] = action_read(h, REG_TT_RD_RSP);
        fprintf(file_rtt, "%8d, %16d, %8d, %16d\n", tt_arid[cnt], tt_rd_cmd[cnt], tt_rid[cnt], tt_rd_rsp[cnt]);
    }

    for (cnt = 0; cnt < ((wnum > 4096)? 4096: wnum); cnt++) {
        tt_awid[cnt]   = action_read(h, REG_TT_AWID);
        tt_wr_cmd[cnt] = action_read(h, REG_TT_WR_CMD);
        tt_bid[cnt]    = action_read(h, REG_TT_BID);
        tt_wr_rsp[cnt] = action_read(h, REG_TT_WR_RSP);
        fprintf(file_wtt, "%8d, %16d, %8d, %16d\n", tt_awid[cnt], tt_wr_cmd[cnt], tt_bid[cnt], tt_wr_rsp[cnt]);
    }


    VERBOSE0 (" ----- Finish dump, release AFU ----- \n");
    action_write(h, REG_USER_CONTROL, 0x00000002);

    

    //VERBOSE0 ("SNAP Wait for idle\n");
    //rc += snap_action_completed ((void*)h, NULL, timeout);
    //VERBOSE0 ("Card in idle\n");

    action_write(h, REG_SOFT_RESET, 0x00000001);
    action_write(h, REG_SOFT_RESET, 0x00000000);

    fclose(file_rtt);
    fclose(file_wtt);
    printf("single run exit, rc=%d\n", rc);
    return rc; //0 means successful
}

static struct snap_action* get_action (struct snap_card* handle,
        snap_action_flag_t flags, uint32_t timeout)
{
    struct snap_action* act;

    act = snap_attach_action (handle, ACTION_TYPE_HDL_SINGLE_ENGINE,
            flags, timeout);

    if (NULL == act) {
        VERBOSE0 ("Error: Can not attach Action: %x\n", ACTION_TYPE_HDL_SINGLE_ENGINE);
        VERBOSE0 ("       Try to run snap_main tool\n");
    }

    return act;
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

static void usage (const char* prog)
{
    VERBOSE0 ("SNAP String Match (Regular Expression Match) Tool.\n");
    VERBOSE0 ("Usage: %s\n"
            "    -h, --help              | Prints usage information\n"
            "    -v, --verbose           | Verbose mode\n"
            "    -C, --card <cardno>     | Card to be used for operation\n"
            "    -V, --version           | Print Version\n"
            //              "    -q, --quiet          | quiece output\n"
            "    -t, --timeout           | Timeout after N sec (default 1 sec)\n"
            "    -I, --irq               | Enable Action Done Interrupt (default No Interrupts)\n"
            "    -d, --init_rdata <arg>  | Init read data (set in Host mem), low 28 bit should be 0 for wrap mode\n"
            "    -D, --init_wdata <arg>  | Init write data (send by AFU), low 28 bit should be 0 for wrap mode\n"
            "    -n, --rnum <arg>        | Read transaction number\n"
            "    -N, --wnum <arg>        | Write transaction number\n"
            "    -w, --wrap_pattern <arg>| Wrap pattern\n"
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

int main (int argc, char* argv[])
{
    char device[64];
    struct snap_card* dn;   /* lib snap handle */
    int card_no = 0;
    int cmd;
    int rc = 1;
    uint32_t i;
    uint32_t timeout = ACTION_WAIT_TIME;
    snap_action_flag_t attach_flags = 0;
    struct snap_action* act = NULL;
    void* src_base=NULL;
    void* tgt_base=NULL;
    void* exp_buff=NULL;
    uint32_t wrap_pattern;
    uint32_t init_rdata , init_wdata;
    uint32_t rnum       , wnum;
    uint32_t rpattern   , wpattern;
    uint32_t rsize      , wsize;
    uint32_t rwidth     , wwidth;   //transaction width in bytes
    uint32_t rblen      , wblen;    //burst length
    uint64_t rtotal_bytes, wtotal_bytes;
    uint64_t total_bytes;
    uint32_t size_4KB = 4096;
    uint32_t size_128MB = 134217728;
    FILE * file_target;
    FILE * file_expect;
    uint64_t time_used = 100;
    uint64_t time_used_array[65536];
    uint32_t test_count; // repetition count of a test: for performance test, a test should be repeated for several times and the average performance should be calculated. test_count should be less than 65536
    double average_bandwidth;
    double min_bandwidth;
    double max_bandwidth;
    double variance;
    double bandwidth_array[65536];

    //Default value
    init_rdata = 0x90000000;
    init_wdata = 0xB0000000;
    rnum = 5;
    wnum = 5;
    rpattern = 0x00001F07; //ID < 4, Len=1F, Size=7 
    wpattern = 0x00001F07; //ID < 4, Len=1F, Size=7
    wrap_pattern = 0x00000601;
    test_count = 1;

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "help"       , no_argument       , NULL , 'h' } ,
            { "card"       , required_argument , NULL , 'C' } ,
            { "verbose"    , no_argument       , NULL , 'v' } ,
            { "version"    , no_argument       , NULL , 'V' } ,
            //    { "quiet"      , no_argument       , NULL , 'q' } ,
            { "timeout"    , required_argument , NULL , 't' } ,
            { "irq"        , no_argument       , NULL , 'I' } ,
            { "wrap_mode"  , required_argument , NULL , 'w' } ,
            { "test_count" , required_argument , NULL , 'c' } ,
            { "init_rdata" , required_argument , NULL , 'd' } ,
            { "init_wdata" , required_argument , NULL , 'D' } ,
            { "rnum"       , required_argument , NULL , 'n' } ,
            { "wnum"       , required_argument , NULL , 'N' } ,
            { "rpattern"   , required_argument , NULL , 'p' } ,
            { "wpattern"   , required_argument , NULL , 'P' } ,
            { 0            , no_argument       , NULL , 0   } 
        };
        cmd = getopt_long (argc, argv, "hC:vVt:Iw:c:d:D:n:N:p:P:",
                long_options, &option_index);

        if (cmd == -1) { /* all params processed ? */
            break;
        }

        switch (cmd) {
            case 'v':   /* verbose */
                verbose_level++;
                break;

            case 'V':   /* version */
                VERBOSE0 ("%s\n", version);
                exit (EXIT_SUCCESS);;

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
                attach_flags = SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
                break;

            case 'w':
                wrap_pattern = strtol (optarg, (char**)NULL, 0);
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


    if (rnum == 0 && wnum == 0)
    {
        VERBOSE0 ("Both Read NUMBER and Write NUMBER are zero. Exit.\n");
        return 0;
    }

    //-------------------------------------------------
    // Open Card
    //-------------------------------------------------
    VERBOSE2 ("Open Card: %d\n", card_no);
    if(card_no == 0)
        snprintf(device, sizeof(device)-1, "IBM,oc-snap");
    else
        snprintf(device, sizeof(device)-1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", card_no);

    dn = snap_card_alloc_dev (device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);
    if (NULL == dn) {
        errno = ENODEV;
        VERBOSE0 ("ERROR: snap_card_alloc_dev(%s)\n", device);
        return -1;
    }

    //-------------------------------------------------
    // Attach Action
    //-------------------------------------------------

    //snap_mmio_read64 (dn, SNAP_S_CIR, &cir);
    //VERBOSE0 ("Start of Card Handle: %p Context: %d\n", dn,
    //        (int) (cir & 0x1ff));
    VERBOSE0 ("Start to get action.\n");
    act = get_action (dn, attach_flags, timeout);

    if (NULL == act) {
        goto __exit1;
    }

    //-------------------------------------------------
    // Prepare buffers
    //-------------------------------------------------

    VERBOSE0 ("Prepare source and tgt buffers.\n");

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
    VERBOSE0 ("Print rwidth is: %d, wwidth is: %d\n", rwidth, wwidth);
    VERBOSE0 ("test_count is: %d\n", test_count);

    rblen = 1 + ((rpattern & 0xFF00) >> 8);
    wblen = 1 + ((wpattern & 0xFF00) >> 8);

    rtotal_bytes = (uint64_t)rnum * (uint64_t)rblen * (uint64_t)rwidth;
    wtotal_bytes = (uint64_t)wnum * (uint64_t)wblen * (uint64_t)wwidth;
    VERBOSE0 ("Read total bytes is: %ld\n", rtotal_bytes);
    VERBOSE0 ("Write total bytes is: %ld\n", wtotal_bytes);

    if(wrap_pattern == 0){
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

    VERBOSE0 ("Source address is: %p\n", src_base);
    VERBOSE0 ("Target address is: %p\n", tgt_base);
    VERBOSE0 ("Expbuf address is: %p\n", exp_buff);

    //-------------------------------------------------
    // Start Engine and wait done
    //-------------------------------------------------
    VERBOSE0 ("Start AFU.\n");
   
    for(i=0; i<test_count;i++) {
        rc = run_single_engine (dn, timeout,
                src_base, 
                tgt_base,
                rnum, wnum,
                init_rdata, init_wdata,
                wrap_pattern,
                rpattern, wpattern,
                &time_used
                );
	printf ("rc: %d\n", rc);
        time_used_array[i] = time_used;

        //-------------------------------------------------
        // Checkings
        //-------------------------------------------------
        uint32_t wr_check_len;
        uint32_t wrap_mode;
        uint64_t wr_check_bytes;
        wr_check_len = (wrap_pattern & 0xF00) >> 8;
        wrap_mode = wrap_pattern & 0x1;
        if(wrap_mode == 1) {
            wr_check_bytes = ((uint64_t)wr_check_len + 1) * 4096;
	    if(wr_check_bytes > wtotal_bytes){
		   wr_check_bytes = wtotal_bytes; 
	    }
        } else {
            wr_check_bytes = wtotal_bytes;
        }
        if (rc == 0) {
            VERBOSE0 ("AFU finishes.\n");
            if (wnum != 0) {
                if (mem_check (tgt_base, exp_buff, wr_check_bytes)) {
                    VERBOSE0 ("WRITE Check FAILED!\n");
                    file_target = fopen("dump_target", "w");
                    file_expect = fopen("dump_expect", "w");
                    __hexdump(file_target, tgt_base, wr_check_bytes);
                    __hexdump(file_expect, exp_buff, wr_check_bytes);
                    fclose(file_target);
                    fclose(file_expect);
                    rc += 0x4;
                    break;
                } else {
                    VERBOSE0 ("WRITE Check PASSED!\n");
                }
            }

        } else {
            break; 
        }
    }

    if(wnum == 0) {
        total_bytes = rtotal_bytes;
    } else {
        total_bytes = wtotal_bytes;
    }

    if (rc == 0) {

        get_bandwidth(time_used_array, total_bytes, test_count, bandwidth_array);
        average_bandwidth = get_average(bandwidth_array, test_count);
        min_bandwidth = get_min(bandwidth_array, test_count);
        max_bandwidth = get_max(bandwidth_array, test_count);
        variance = get_variance(bandwidth_array, test_count, average_bandwidth);

        if (wnum == rnum && wpattern == rpattern) //Only measure duplex bandwidth when R and W are same.
        {
            VERBOSE0("Duplex average bandwidth: %ld bytes in %ld usec ( %.3f MB/s )\n",
                    total_bytes, time_used, average_bandwidth);
            VERBOSE0("Duplex bandwidth min, max and variance: %ld bytes in %ld usec ( %.3f MB/s, %.3f MB/s, %.3f )\n",
                    total_bytes, time_used, min_bandwidth, max_bandwidth, variance);
        }

        if (wnum == 0)
        {
            VERBOSE0("Read average bandwidth (Host->FPGA): %ld bytes in %ld usec ( %.3f MB/s )\n",
                    rtotal_bytes, time_used, average_bandwidth);
            VERBOSE0("Read bandwidth min, max and variance: %ld bytes in %ld usec ( %.3f MB/s, %.3f MB/s, %.3f )\n",
                    rtotal_bytes, time_used, min_bandwidth, max_bandwidth, variance);
        }

        if (rnum == 0)
        {
            VERBOSE0("Write average bandwidth (FPGA->Host): %ld bytes in %ld usec ( %.3f MB/s )\n",
                    wtotal_bytes, time_used, average_bandwidth);
            VERBOSE0("Write bandwidth min, max and variance: %ld bytes in %ld usec ( %.3f MB/s, %.3f MB/s, %.3f )\n",
                    wtotal_bytes, time_used, min_bandwidth, max_bandwidth, variance);
        }
    }


    //-------------------------------------------------
    // Detach, Cleanup and Exit
    //-------------------------------------------------
    VERBOSE2 ("Detach action: %p\n", act);
    snap_detach_action (act);

__exit1:
    VERBOSE2 ("Free Card Handle: %p\n", dn);
    snap_card_free (dn);

    free_mem(src_base);
    free_mem(exp_buff);
    free_mem(tgt_base);

    VERBOSE0 ("End of Test rc = 0x%x. \n", rc);
    return rc;
} // main end
