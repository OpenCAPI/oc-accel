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
#include <sys/types.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <math.h>
#include <getopt.h>
#include <ctype.h>

#include <libosnap.h>
#include <osnap_tools.h>

#include "hdl_multi_process.h"

/*  defaults */
#define ACTION_WAIT_TIME    50   /* Default in sec */

#define MEGAB       (1024*1024ull)
#define GIGAB       (1024 * MEGAB)

#define VERBOSE0(log, fmt, ...) do {         \
        printf(fmt, ## __VA_ARGS__);    \
        fprintf(log, fmt, ## __VA_ARGS__);    \
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
static void action_write (FILE* log, struct snap_card* h, uint32_t addr, uint32_t data)
{
    int rc;

    rc = snap_action_write32 (h, (uint64_t)addr, data);

    if (0 != rc) {
        VERBOSE0 (log, "Write MMIO 32 Err\n");
    }

    return;
}

static uint32_t action_read (FILE* log, struct snap_card* h, uint32_t addr)
{
    int rc;
    uint32_t data;

    rc = snap_action_read32 (h, (uint64_t)addr, &data);

    if (0 != rc) {
        VERBOSE0 (log, "Read MMIO 32 Err\n");
    }

    return data;
}


static void mem_init (void* mem_addr, uint32_t init_data, uint64_t total_bytes)
{

    uint8_t* ptr = (uint8_t*) mem_addr;
    uint32_t fill_data = init_data;
    uint64_t cnt = 0;

    do {
        * (ptr) = (fill_data) & 0xFF;
        * (ptr + 1) = (fill_data >> 8) & 0xFF;
        * (ptr + 2) = (fill_data >> 16) & 0xFF;
        * (ptr + 3) = (fill_data >> 24) & 0xFF;

        cnt += 4;
        fill_data ++;
        ptr += 4;
    } while (cnt < total_bytes);

}


/*
 * Return 0 if buffer is equal,
 * Return index+1 if not equal
 */
static uint64_t mem_check (uint8_t* src, uint8_t* dest, uint64_t len)
{
    uint64_t i;

    for (i = 0; i < len; i++) {
        if (*src != *dest) {
            return i + 1;
        }

        src++;
        dest++;
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
                              uint64_t* td,
                              FILE* log,
                              int id
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
    //FILE* file_rtt;
    //FILE* file_wtt;
    uint32_t pasid;

    VERBOSE0 (log, " ----- START SNAP_CONTROL ----- \n");
    //snap_action_start ((void*)h);
    action_write(log, h, reg (REG_SNAP_CONTROL, id), 0x00000001);

    pasid = snap_action_get_pasid (h);
    VERBOSE0 (log, "PASID of this process: %u\n", pasid);
    action_write (log, h, reg (REG_SNAP_CONTEXT, id), pasid);

    VERBOSE0 (log, " ----- CONFIG PARAMETERS ----- \n");
    action_write (log, h, reg (REG_USER_MODE, id), wrap_pattern);
    action_write (log, h, reg (REG_SOURCE_ADDRESS_L, id), (uint32_t) (((uint64_t) src_base) & 0xffffffff));
    action_write (log, h, reg (REG_SOURCE_ADDRESS_H, id), (uint32_t) ((((uint64_t) src_base) >> 32) & 0xffffffff));

    action_write (log, h, reg (REG_TARGET_ADDRESS_L, id), (uint32_t) (((uint64_t) tgt_base) & 0xffffffff));
    action_write (log, h, reg (REG_TARGET_ADDRESS_H, id), (uint32_t) ((((uint64_t) tgt_base) >> 32) & 0xffffffff));

    action_write (log, h, reg (REG_INIT_RDATA, id), init_rdata);
    action_write (log, h, reg (REG_INIT_WDATA, id), init_wdata);

    action_write (log, h, reg (REG_RD_PATTERN, id), rpattern);
    action_write (log, h, reg (REG_WR_PATTERN, id), wpattern);

    action_write (log, h, reg (REG_RD_NUMBER, id), rnum);
    action_write (log, h, reg (REG_WR_NUMBER, id), wnum);


    VERBOSE0 (log, " ----- Check if AFU is ready ----- \n");
    cnt = 0;

    do {
        reg_data = action_read (log, h, reg (REG_USER_STATUS, id));

        if ((reg_data & 0x20) > 0) {
            ready = 1;
            VERBOSE0 (log, "AFU has finished cleaning TT RAM. Ready to start AXI transactions.\n");
            break;
        }

        cnt ++;
    } while (cnt < 300);

    if (ready == 0) {
        VERBOSE0 (log, "ERROR: AFU not ready! \n");
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000001);
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000000);

        rc += 0x2;
        return rc;
    }

    VERBOSE0 (log, " ----- Tell AFU to kick off AXI transactions ----- \n");
    action_write (log, h, reg (REG_USER_CONTROL, id), 0x00000001);
    t_start = get_usec();

    cnt = 0;

    do {
        reg_data = action_read (log, h, reg (REG_USER_STATUS, id));

        if ((reg_data & 0x3) == 0x3) {
            both_done = 1;
            VERBOSE0 (log, "AFU has finished all transactions.\n");
            break;
        }

        //if ((reg_data & 0x10) > 0 ){
        //    read_error = 1;
        //    VERBOSE0 (log, "ERROR: AFU meets a read checking error.\n");
        //    break;
        //}
        cnt ++;
    } while (cnt < timeout * 1000); //Use timeout to emulate max allowed MMIO read times

    if ((reg_data & 0x10) > 0) {
        read_error = 1;
        VERBOSE0 (log, "ERROR: AFU meets a read checking error.\n");
    }

    *td = get_usec() - t_start;

    if (read_error) {
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000001);
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000000);
        rc += 0x4;
        return rc;
    }

    if (!both_done) {
        VERBOSE0 (log, "Timeout! Transactions haven't been finished.\n");
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000001);
        action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000000);
        rc += 0x8;
        return rc;
    }


    VERBOSE0 (log, " ----- Dump TT Arrays ----- \n");
    //file_rtt = fopen ("file_rd_cycle", "w");
    //file_wtt = fopen ("file_wr_cycle", "w");

    VERBOSE0 (log, "RTT:\n");
    for (cnt = 0; cnt < ((rnum > 4096) ? 4096 : rnum); cnt++) {
        tt_arid[cnt]   = action_read (log, h, reg (REG_TT_ARID, id));
        tt_rd_cmd[cnt] = action_read (log, h, reg (REG_TT_RD_CMD, id));
        tt_rid[cnt]    = action_read (log, h, reg (REG_TT_RID, id));
        tt_rd_rsp[cnt] = action_read (log, h, reg (REG_TT_RD_RSP, id));
        fprintf (log, "%8d, %16d, %8d, %16d\n", tt_arid[cnt], tt_rd_cmd[cnt], tt_rid[cnt], tt_rd_rsp[cnt]);
    }

    VERBOSE0 (log, "WTT:\n");
    for (cnt = 0; cnt < ((wnum > 4096) ? 4096 : wnum); cnt++) {
        tt_awid[cnt]   = action_read (log, h, reg (REG_TT_AWID, id));
        tt_wr_cmd[cnt] = action_read (log, h, reg (REG_TT_WR_CMD, id));
        tt_bid[cnt]    = action_read (log, h, reg (REG_TT_BID, id));
        tt_wr_rsp[cnt] = action_read (log, h, reg (REG_TT_WR_RSP, id));
        fprintf (log, "%8d, %16d, %8d, %16d\n", tt_awid[cnt], tt_wr_cmd[cnt], tt_bid[cnt], tt_wr_rsp[cnt]);
    }


    VERBOSE0 (log, " ----- Finish dump, release AFU ----- \n");
    action_write (log, h, reg (REG_USER_CONTROL, id), 0x00000002);

    //VERBOSE0 (log, "SNAP Wait for idle\n");
    //rc += snap_action_completed ((void*)h, NULL, timeout);
    //VERBOSE1 ("Card in idle\n");

    action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000001);
    action_write (log, h, reg (REG_SOFT_RESET, id), 0x00000000);

    //fclose (file_rtt);
    //fclose (file_wtt)1;
    return rc; //1 means successful
}

static struct snap_action* get_action (FILE* log, struct snap_card* handle,
                                       snap_action_flag_t flags, uint32_t timeout)
{
    struct snap_action* act;

    act = snap_attach_action (handle, ACTION_TYPE_HDL_MULTI_PROCESS,
                              flags, timeout);

    if (NULL == act) {
        VERBOSE0 (log, "Error: Can not attach Action: %x\n", ACTION_TYPE_HDL_MULTI_PROCESS);
        VERBOSE0 (log, "       Try to run snap_main tool\n");
    }

    return act;
}

static void usage (FILE* log, const char* prog)
{
    VERBOSE0 (log, "SNAP String Match (Regular Expression Match) Tool.\n");
    VERBOSE0 (log, "Usage: %s\n"
             "    -h, --help              | Prints usage information\n"
             "    -v, --verbose           | Verbose mode\n"
             "    -C, --card <cardno>     | Card to be used for operation\n"
             "    -V, --version           | Print Version\n"
             //              "    -q, --quiet          | quiece output\n"
             "    -t, --timeout           | Timeout after N sec (default 1 sec)\n"
             "    -I, --irq               | Enable Action Done Interrupt (default No Interrupts)\n"
             "    -d, --init_rdata <arg>  | Init read data (set in Host mem)\n"
             "    -D, --init_wdata <arg>  | Init write data (send by AFU)\n"
             "    -n, --rnum <arg>        | Read transaction number\n"
             "    -N, --wnum <arg>        | Write transaction number\n"
             "    -w, --wrap_pattern <arg>| Wrap pattern\n"
             "                            Pattern: [11:8]  wrap len, address range = (wrap len + 1)*4KB\n"
             "                                     [0]     wrap mode, 0 for incr mode, 1 for wrap mode\n"
             "    -p, --rpattern <arg>    | Read pattern\n"
             "    -P, --wpattern <arg>    | Write pattern\n"
             "                            Pattern: [20:16] id_range. for example, 3 means [0,1,2,3]\n"
             "                                     [15:8]  Burst length - 1,        =AXI A*LEN\n"
             "                                     [2:0]   Data width in each beat, =AXI A*SIZE\n"
             , prog);
}

static int memcopy (int argc, char* argv[], int id)
{
    char device[64];
    struct snap_card* dn;   /* lib snap handle */
    int card_no = 0;
    int cmd;
    int rc = 1;
    int i;
    uint32_t timeout = ACTION_WAIT_TIME;
    snap_action_flag_t attach_flags = 0;
    struct snap_action* act = NULL;
    void* src_base = NULL;
    void* tgt_base = NULL;
    void* exp_buff = NULL;
    uint32_t wrap_pattern;
    uint32_t init_rdata, init_wdata;
    uint32_t rnum, wnum;
    uint32_t rpattern, wpattern;
    uint32_t rsize, wsize;
    uint32_t rwidth, wwidth;        //transaction width in bytes
    uint32_t rblen, wblen;          //burst length
    uint64_t rtotal_bytes, wtotal_bytes;
    FILE* file_target;
    FILE* file_expect;
    uint64_t time_used = 100;
    pid_t pid;
    FILE* log;
    char file_name[256];

    pid = getpid();
    sprintf (file_name, "proc_%d_%d.log", id, pid);
    log = fopen (file_name, "w");

    //Default value
    //init_rdata = 0x900D0000;
    //init_wdata = 0xBeeF0000;
    init_rdata = id * 1024;
    init_wdata = id * 1024;
    rnum = 1;
    wnum = 1;
    rpattern = 0x00001F07; //ID < 4, Len=1F, Size=7
    wpattern = 0x00001F07; //ID < 4, Len=1F, Size=7
    wrap_pattern = 0x00000000;

    if (NULL == log) {
        VERBOSE0 (log, "Unable to open log file handler\n");
        return -1;
    }

    VERBOSE0 (log, "Process %d running ... \n", pid);

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "help", no_argument, NULL, 'h' },
            { "card", required_argument, NULL, 'C' },
            { "verbose", no_argument, NULL, 'v' },
            { "version", no_argument, NULL, 'V' },
            //    { "quiet"      , no_argument       , NULL , 'q' } ,
            { "timeout", required_argument, NULL, 't' },
            { "irq", no_argument, NULL, 'I' },
            { "wrap_mode", required_argument, NULL, 'w' },
            { "init_rdata", required_argument, NULL, 'd' },
            { "init_wdata", required_argument, NULL, 'D' },
            { "rnum", required_argument, NULL, 'n' },
            { "wnum", required_argument, NULL, 'N' },
            { "rpattern", required_argument, NULL, 'p' },
            { "wpattern", required_argument, NULL, 'P' },
            { 0, no_argument, NULL, 0   }
        };
        cmd = getopt_long (argc, argv, "hC:vVt:Iw:d:D:n:N:p:P:",
                           long_options, &option_index);

        if (cmd == -1) { /* all params processed ? */
            break;
        }

        switch (cmd) {
        case 'v':   /* verbose */
            verbose_level++;
            break;

        case 'V':   /* version */
            VERBOSE0 (log, "%s\n", version);
            exit (EXIT_SUCCESS);;

        case 'h':   /* help */
            usage (log, argv[0]);
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
            usage (log, argv[0]);
            exit (EXIT_FAILURE);
        }

    }  // while(1)


    if (rnum == 0 && wnum == 0) {
        VERBOSE0 (log, "Both Read NUMBER and Write NUMBER are zero. Exit.\n");
        return 0;
    }

    //-------------------------------------------------
    // Open Card
    //-------------------------------------------------
    VERBOSE2 ("Open Card: %d\n", card_no);

    if (card_no == 0) {
        snprintf (device, sizeof (device) - 1, "IBM,oc-snap");
    } else {
        snprintf (device, sizeof (device) - 1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", card_no);
    }

    dn = snap_card_alloc_dev (device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

    if (NULL == dn) {
        errno = ENODEV;
        VERBOSE0 (log, "ERROR: snap_card_alloc_dev(%s)\n", device);
        return -1;
    }

    //-------------------------------------------------
    // Attach Action
    //-------------------------------------------------

    VERBOSE0 (log, "Start to get action.\n");
    act = get_action (log, dn, attach_flags, timeout);
    if (NULL == act) {
        goto __exit1;
    }

    //-------------------------------------------------
    // Prepare buffers
    //-------------------------------------------------

    VERBOSE0 (log, "Prepare source and tgt buffers.\n");

    rsize = (rpattern & 0x7);
    wsize = (wpattern & 0x7);

    rwidth = 1;
    wwidth = 1;

    for (i = 0; i < (int) rsize; i++) {
        rwidth = rwidth * 2;
    }

    for (i = 0; i < (int) wsize; i++) {
        wwidth = wwidth * 2;
    }

    VERBOSE0 (log, "Print rwidth is: %d, wwidth is: %d\n", rwidth, wwidth);

    rblen = 1 + ((rpattern & 0xFF00) >> 8);
    wblen = 1 + ((wpattern & 0xFF00) >> 8);

    rtotal_bytes = (uint64_t)rnum * (uint64_t)rblen * (uint64_t)rwidth;
    wtotal_bytes = (uint64_t)wnum * (uint64_t)wblen * (uint64_t)wwidth;

    //src_base  = alloc_mem(rwidth, rtotal_bytes);
    //tgt_base = alloc_mem (wwidth, wtotal_bytes);
    src_base  = alloc_mem (134217728, rtotal_bytes); // src address must be 4KB alignment
    tgt_base = alloc_mem (134217728, wtotal_bytes); // targer address must be 4KB alignment
    exp_buff  = alloc_mem (134217728, wtotal_bytes);

    VERBOSE0 (log, "Source address is: %p\n", src_base);
    VERBOSE0 (log, "Target address is: %p\n", tgt_base);

    mem_init (src_base, init_rdata, rtotal_bytes);
    mem_init (exp_buff, init_wdata, wtotal_bytes);
    memset (tgt_base, 0, wtotal_bytes);

    //-------------------------------------------------
    // Start Engine and wait done
    //-------------------------------------------------
    VERBOSE0 (log, "Start AFU.\n");
    rc = run_single_engine (dn, timeout,
                            src_base,
                            tgt_base,
                            rnum, wnum,
                            init_rdata, init_wdata,
                            wrap_pattern,
                            rpattern, wpattern,
                            &time_used,
                            log,
                            id
                           );

    //-------------------------------------------------
    // Checkings
    //-------------------------------------------------
    uint32_t wr_check_len;
    uint32_t wrap_mode;
    uint64_t wr_check_bytes;
    wr_check_len = (wrap_pattern & 0xF00) >> 8;
    wrap_mode = wrap_pattern & 0x1;

    if (wrap_mode == 1) {
        wr_check_bytes = ((uint64_t)wr_check_len + 1) * 4096;
    } else {
        wr_check_bytes = wtotal_bytes;
    }

    if (rc == 1) {
        VERBOSE0 (log, "AFU finishes.\n");

        if (wnum != 0) {
            if (mem_check (tgt_base, exp_buff, wr_check_bytes)) {
                VERBOSE0 (log, "WRITE Check FAILED!\n");
                sprintf (file_name, "proc_%d_%d_target.log", id, pid);
                file_target = fopen (file_name, "w");
                sprintf (file_name, "proc_%d_%d_expect.log", id, pid);
                file_expect = fopen (file_name, "w");
                __hexdump (file_target, tgt_base, wr_check_bytes);
                __hexdump (file_expect, exp_buff, wr_check_bytes);
                fclose (file_target);
                fclose (file_expect);
                rc += 0x4;
            } else {
                VERBOSE0 (log, "WRITE Check PASSED!\n");
            }
        }

        if (wnum == rnum && wpattern == rpattern) { //Only measure duplex bandwidth when R and W are same.
            VERBOSE0 (log, "Duplex bandwidth: %ld bytes in %ld usec ( %.3f MB/s )\n",
                     wtotal_bytes, time_used, (double)wtotal_bytes / (double)time_used);
        }

        if (wnum == 0) {
            VERBOSE0 (log, "Read bandwidth (Host->FPGA): %ld bytes in %ld usec ( %.3f MB/s )\n",
                     rtotal_bytes, time_used, (double)rtotal_bytes / (double)time_used);
        }

        if (rnum == 0) {
            VERBOSE0 (log, "Write bandwidth (FPGA->Host): %ld bytes in %ld usec ( %.3f MB/s )\n",
                     wtotal_bytes, time_used, (double)wtotal_bytes / (double)time_used);
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

    free_mem (src_base);
    free_mem (exp_buff);
    free_mem (tgt_base);

    if (rc != 0) {
        VERBOSE0 (log, "End of Test rc = 0x%x. \n", rc);
    }

    fclose (log);

    return rc;
}

int main (int argc, char* argv[])
{
    int num_processes = 4;
    int rc = 0;
    int failing = -1;
    pid_t pid;
    int i, j;

    for (i = 0; i < num_processes; i++) {
        if (!fork()) {
            exit (memcopy (argc, argv, i));
        }
    }

    for (i = 0; i < num_processes; i++) {
        pid = wait (&j);

        if (pid && j) {
            rc++;

            if (failing == -1) {
                failing = pid;
            }
        }
    }

    if (rc) {
        fprintf (stderr, "%d test(s) failed. Check Process %d, maybe others\n", rc, failing);
    } else {
        printf ("Test successful\n");
    }

    return rc;
}

