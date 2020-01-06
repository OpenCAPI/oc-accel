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
`ifndef _TL_CFG_OBJ_SV
`define _TL_CFG_OBJ_SV

`define MAX_TEMPLATE_NUM    12

class tl_cfg_obj extends uvm_object;

    typedef enum int{
        OPENCAPI_3_0,
        OPENCAPI_3_1,
        OPENCAPI_4_0
    } t_OCAPI_VERSION;

    typedef enum int{
        UNIT_SIM,
        CHIP_SIM
    } t_SIM_MODE;

    typedef enum int{
        DEVICE_CLASS,
        MEMORY_CLASS
    } t_OCAPI_PROFILE;

    typedef enum int{
        C0M0,
        C0M1,
        C1M0,
        C1M1
    } t_AFU_TYPE;

    typedef enum int{
        PAGE_SIZE_4K,
        PAGE_SIZE_64K
    } t_PAGE_SIZE;

    typedef enum int{
        PIN_FLIT_ERR,
        BAD_DATA_IN_CNTL_FLIT,
        BAD_DATA_IN_DATA_FLIT,
        RESP_CODE_RTY_REQ,
        RESP_CODE_VALID_RTY_PENDING,
        RESP_CODE_INTRP_PENDING,
        RESP_CODE_DATA_ERR,
        RESP_CODE_UNSUPPORT_LENGTH,
        RESP_CODE_BAD_OBJECT_HANDLE,
        RESP_CODE_FAILED,
        RESP_CODE_VALID_RND,
        RESP_CODE_ALL_RND,
        NONE
    } t_ERR_TYPE;

    t_SIM_MODE         sim_mode;                                //Unit(TL+MC) sim or OCMB chip sim
    t_AFU_TYPE         afu_type;                                //AFU type, for OCMB is C0M1
    t_OCAPI_PROFILE    ocapi_profile;                           //OpenCAPI profile, for OCMB is memory
    t_OCAPI_VERSION    ocapi_version;                           //OpenCAPI spec version
    t_PAGE_SIZE        page_size_mode;                          //Host ATC page size
    bit                cfg_enterprise_mode;                     //(~fuse_enterprise_dis) & mmio_enterprise_mode
    bit                half_dimm_mode;                          //OCMB memory topology
    bit                low_latency_mode;                        //Read response is sent back 3 flits prior to the corresonding data
    bit [63:0]         config_space_base;                       //AFU config space base address
    bit [63:0]         config_space_size;                       //AFU config space size
    bit [63:0]         sysmem_space_base;                       //AFU system memory space base address
    bit [63:0]         sysmem_space_size;                       //AFU system memory space size
    bit [63:0]         mmio_space_base;                         //AFU mmio space base address
    bit [63:0]         mmio_space_size;                         //AFU mmio space size
    bit [63:0]         mscc_space_lower[18];                    //MSCC space lower, RAM+ROM+REG
    bit [63:0]         mscc_space_upper[18];                    //MSCC space upper, RAM+ROM+REG   
    bit [63:0]         mscc_space_valid[18];                    //MSCC space total required size.
    bit [63:0]         mscc_space_hole[18][$];                  //MSCC space hole address.
    bit [63:0]         ibm_space_lower;                         //IBM address space lower
    bit [63:0]         ibm_space_upper;                         //IBM address space upper
    bit [7:0]          data_pattern[32];                        //data_pattern used by pad_mem
    bit [71:0]         data_pattern_xmeta;                      //xmeta associated with data_pattern 
    bit [7:0]          mad;                                     //Memory access directive
    int                tl_vc_credit_count[4];                   //TL VC maximum credit count
    int                tlx_vc_credit_count[4];                  //TLx VC maximum credit count
    int                tl_data_credit_count[4];                 //TL DCP maximum credit count
    int                tlx_data_credit_count[4];                //TLx DCP maximum credit count
    int                dl_credit_count;                         //DL Data maximum credit count
    int                actag_table_size;                        //Host acTag entry count
    bit [11:0]         actag_base;                              //First acTag AFU allowed to use
    bit [11:0]         actag_length;                            //Number of consecutive acTags AFU allowed to use
    bit [19:0]         pasid_base;                              //First PASID AFU allowed to use
    bit [4 :0]         pasid_length;                            //Number of consecutive PASID AFU allowed to use
    bit [15:0]         bdf;                                     //AFU bus device function
    bit                tl_transmit_template[`MAX_TEMPLATE_NUM]; //TL supported transmit template bit map 
    bit                tl_receive_template[`MAX_TEMPLATE_NUM];  //TL supported receive template bit map
    int                tl_transmit_rate[`MAX_TEMPLATE_NUM];     //TL transmit rate per template 
    int                tl_receive_rate[`MAX_TEMPLATE_NUM];      //TL receive rate per template
    int                host_back_off_timer;                     //Timer in clock cycle for host back-off event
    int                host_receive_resp_timer;                 //Timer for host to receive AFU response
    bit                metadata_enable;                         //MetaData enable
    bit                afu_send_cmd_enable;                     //AFU allow to send commands
    bit                bfm_send_resp_enable;                    //Host allow to send responses
    int                driver_cmd_buffer_size;                  //Command buffer size in TL driver
    int                driver_last_nop_timer;                   //Timer for TL driver to send nop control flit last
    bit                null_flit_enable;                        //TL driver enable to insert null control flit during rate
    bit                invalid_data_enable;                     //TL driver enable to always send invalid data in control flit
    bit                inject_err_enable;                       //Inject error enable
    t_ERR_TYPE         inject_err_type;                         //Inject error type
    bit                pin_flit_err_rand_enable;                //TL driver enable to assert dl_tl_flit_error randomly without CRC error
    bit                crit_ow_first_enable;                    //critical ow was returned first
    bit                credits_check_enable;                    //check DL and TL/TLx credits at end of test 
    bit                consume_tl_credits_disable;              //disable BFM consume TL credits
    bit                intrp_resp_ocmb_enable;                  //Interrupt handler for ocmb to access FIR MMIO registers enable
    bit                intrp_resp_wait_fir_clear;               //BFM sends out intrp_resp after all FIR MMIO registers read/write finished
    bit                intrp_resp_immd;                         //BFM sends out intrp_resp after intrp_req received immediately
    bit                intrp_resp_bad_afutag_enable;            //BFM sends out intrp_resp with bad AFU Tag enable
    bit                intrp_resp_bad_afutag_rnd;               //Randomize bad AFU tag in the intrp_resp
    bit [15:0]         intrp_resp_bad_afutag;                   //BFM sends out intrp_resp with bad AFU Tag
    int                intrp_resp_num;                          //Number of the intrp_resp
    bit                intrp_resp_last_good;                    //Last intrp_resp is good, all previous resps are bad
    bit                intrp_resp_all_good;                     //All intrp_resp are good
    int                wr_resp_num_1_weight;                    //Weight of sending out 1 resp for one write host memory cmd
    int                wr_resp_num_2_weight;                    //Weight of sending out 2 resp for one write host memory cmd
    int                wr_resp_num_3_weight;                    //Weight of sending out 3 resp for one write host memory cmd
    int                wr_resp_num_4_weight;                    //Weight of sending out 4 resp for one write host memory cmd
    int                rd_resp_num_1_weight;                    //Weight of sending out 1 resp for one read host memory cmd
    int                rd_resp_num_2_weight;                    //Weight of sending out 2 resp for one read host memory cmd
    int                rd_resp_num_3_weight;                    //Weight of sending out 3 resp for one read host memory cmd
    int                rd_resp_num_4_weight;                    //Weight of sending out 4 resp for one read host memory cmd
    int                wr_fail_percent;                         //Percentage of write fail response: 0-100
    int                rd_fail_percent;                         //Percentage of read fail response: 0-100
    int                resp_rty_weight;                         //Weight of write/read fail response for resp code rty_req
    int                resp_xlate_weight;                       //Weight of write/read fail response for resp code xlate_pending
    int                resp_derror_weight;                      //Weight of write/read fail response for resp code derror
    int                resp_failed_weight;                      //Weight of write/read fail response for resp code failed
    int                resp_reserved_weight;                    //Weight of write/read fail response for resp code reserved
    int                xlate_done_cmp_weight;                   //Weight of xlate done for resp code completed
    int                xlate_done_rty_weight;                   //Weight of xlate done for resp code rty_req
    int                xlate_done_aerror_weight;                //Weight of xlate done for resp code addr error
    int                xlate_done_reserved_weight;              //Weight of xlate done for resp code reserved
    bit                split_reorder_enable;                    //Enable reorder multiple resp(different dpart) for one memory write/read cmd
    bit                resp_reorder_enable;                     //Enable sending memory write/read response out-of-order
    int                resp_delay_cycle;                        //Clock cycles to delay sending memory write/read response(not precise) when reorder not enabled
    bit                resp_reorder_window_cycle;               //Clock cycles of window to collect memory write/read resp when reorder enabled
    bit                tx_tmpl_priority[`MAX_TEMPLATE_NUM];     //TL transmit template priority bit map 
    bit                tx_tmpl_priority_enable;                 //TL transmit template priority bit enable

    `uvm_object_utils_begin(tl_cfg_obj)
        `uvm_field_enum         (t_SIM_MODE,        sim_mode,           UVM_ALL_ON)
        `uvm_field_enum         (t_AFU_TYPE,        afu_type,           UVM_ALL_ON)
        `uvm_field_enum         (t_OCAPI_PROFILE,   ocapi_profile,      UVM_ALL_ON)
        `uvm_field_enum         (t_PAGE_SIZE,       page_size_mode,     UVM_ALL_ON)
        `uvm_field_enum         (t_OCAPI_VERSION,   ocapi_version,      UVM_ALL_ON)
        `uvm_field_int          (cfg_enterprise_mode,                   UVM_ALL_ON)
        `uvm_field_int          (half_dimm_mode,                        UVM_ALL_ON)
        `uvm_field_int          (low_latency_mode,                      UVM_ALL_ON)
        `uvm_field_int          (config_space_base,                     UVM_ALL_ON)
        `uvm_field_int          (config_space_size,                     UVM_ALL_ON)
        `uvm_field_int          (sysmem_space_base,                     UVM_ALL_ON)
        `uvm_field_int          (sysmem_space_size,                     UVM_ALL_ON)
        `uvm_field_int          (mmio_space_base,                       UVM_ALL_ON)
        `uvm_field_int          (mmio_space_size,                       UVM_ALL_ON)
        `uvm_field_sarray_int   (mscc_space_lower,                      UVM_ALL_ON)
        `uvm_field_sarray_int   (mscc_space_upper,                      UVM_ALL_ON)
        `uvm_field_sarray_int   (mscc_space_valid,                      UVM_ALL_ON)
        `uvm_field_int          (ibm_space_lower,                       UVM_ALL_ON)
        `uvm_field_int          (ibm_space_upper,                       UVM_ALL_ON)
        `uvm_field_sarray_int   (data_pattern,                          UVM_ALL_ON)
        `uvm_field_int          (data_pattern_xmeta,                    UVM_ALL_ON)        
        `uvm_field_int          (mad,                                   UVM_ALL_ON)
        `uvm_field_sarray_int   (tl_vc_credit_count,                    UVM_ALL_ON|UVM_DEC)
        `uvm_field_sarray_int   (tlx_vc_credit_count,                   UVM_ALL_ON|UVM_DEC)
        `uvm_field_sarray_int   (tl_data_credit_count,                  UVM_ALL_ON|UVM_DEC)
        `uvm_field_sarray_int   (tlx_data_credit_count,                 UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (dl_credit_count,                       UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (actag_table_size,                      UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (actag_base,                            UVM_ALL_ON)
        `uvm_field_int          (actag_length,                          UVM_ALL_ON)
        `uvm_field_int          (pasid_base,                            UVM_ALL_ON)
        `uvm_field_int          (pasid_length,                          UVM_ALL_ON)
        `uvm_field_int          (bdf,                                   UVM_ALL_ON)
        `uvm_field_sarray_int   (tl_transmit_template,                  UVM_ALL_ON)
        `uvm_field_sarray_int   (tl_receive_template,                   UVM_ALL_ON)
        `uvm_field_sarray_int   (tl_transmit_rate,                      UVM_ALL_ON|UVM_DEC)
        `uvm_field_sarray_int   (tl_receive_rate,                       UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (host_back_off_timer,                   UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (host_receive_resp_timer,               UVM_ALL_ON|UVM_DEC)
        `uvm_field_int          (metadata_enable,                       UVM_ALL_ON)
        `uvm_field_int          (afu_send_cmd_enable,                   UVM_ALL_ON)
        `uvm_field_int          (bfm_send_resp_enable,                  UVM_ALL_ON)
        `uvm_field_int          (driver_cmd_buffer_size,                UVM_ALL_ON)
        `uvm_field_int          (driver_last_nop_timer,                 UVM_ALL_ON)
        `uvm_field_int          (null_flit_enable,                      UVM_ALL_ON)
        `uvm_field_int          (invalid_data_enable,                   UVM_ALL_ON)
        `uvm_field_int          (inject_err_enable,                     UVM_ALL_ON)
        `uvm_field_enum         (t_ERR_TYPE,        inject_err_type,    UVM_ALL_ON)
        `uvm_field_int          (pin_flit_err_rand_enable,              UVM_ALL_ON)
        `uvm_field_int          (crit_ow_first_enable,                  UVM_ALL_ON)
        `uvm_field_int          (credits_check_enable,                  UVM_ALL_ON)
        `uvm_field_int          (consume_tl_credits_disable,            UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_ocmb_enable,                UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_wait_fir_clear,             UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_immd,                       UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_bad_afutag_enable,          UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_bad_afutag_rnd,             UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_bad_afutag,                 UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_num,                        UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_last_good,                  UVM_ALL_ON)
        `uvm_field_int          (intrp_resp_all_good,                   UVM_ALL_ON)
        `uvm_field_int          (wr_resp_num_1_weight,                  UVM_ALL_ON)
        `uvm_field_int          (wr_resp_num_2_weight,                  UVM_ALL_ON)
        `uvm_field_int          (wr_resp_num_3_weight,                  UVM_ALL_ON)
        `uvm_field_int          (wr_resp_num_4_weight,                  UVM_ALL_ON)
        `uvm_field_int          (rd_resp_num_1_weight,                  UVM_ALL_ON)
        `uvm_field_int          (rd_resp_num_2_weight,                  UVM_ALL_ON)
        `uvm_field_int          (rd_resp_num_3_weight,                  UVM_ALL_ON)
        `uvm_field_int          (rd_resp_num_4_weight,                  UVM_ALL_ON)
        `uvm_field_int          (wr_fail_percent,                       UVM_ALL_ON)
        `uvm_field_int          (rd_fail_percent,                       UVM_ALL_ON)
        `uvm_field_int          (resp_rty_weight,                       UVM_ALL_ON)
        `uvm_field_int          (resp_xlate_weight,                     UVM_ALL_ON)
        `uvm_field_int          (resp_derror_weight,                    UVM_ALL_ON)
        `uvm_field_int          (resp_failed_weight,                    UVM_ALL_ON)
        `uvm_field_int          (resp_reserved_weight,                  UVM_ALL_ON)
        `uvm_field_int          (xlate_done_cmp_weight,                 UVM_ALL_ON)
        `uvm_field_int          (xlate_done_rty_weight,                 UVM_ALL_ON)
        `uvm_field_int          (xlate_done_aerror_weight,              UVM_ALL_ON)
        `uvm_field_int          (xlate_done_reserved_weight,            UVM_ALL_ON)
        `uvm_field_int          (split_reorder_enable,                  UVM_ALL_ON)
        `uvm_field_int          (resp_reorder_enable,                   UVM_ALL_ON)
        `uvm_field_int          (resp_delay_cycle,                      UVM_ALL_ON)
        `uvm_field_int          (resp_reorder_window_cycle,             UVM_ALL_ON)
        `uvm_field_sarray_int   (tx_tmpl_priority,                      UVM_ALL_ON)
        `uvm_field_int          (tx_tmpl_priority_enable,               UVM_ALL_ON)

    `uvm_object_utils_end

    function new(string name="tl_cfg_obj");
        super.new(name);
        default_config();
    endfunction: new

    function void default_config();
        sim_mode = UNIT_SIM;
        afu_type = C0M1;
        ocapi_profile = MEMORY_CLASS;
        ocapi_version = OPENCAPI_3_0;
        cfg_enterprise_mode = 1;
        half_dimm_mode      = 0;
        low_latency_mode    = 1;
        config_space_base = 64'h0000_0001_0000_0000;
        config_space_size = 64'h0000_0001_0000_0000;
        mmio_space_base   = 64'h0000_0008_0000_0000;
        mmio_space_size   = 64'h0000_0004_0000_0000;
        sysmem_space_base = 64'h0000_0000_0000_0000;
        sysmem_space_size = 64'h0000_0001_0000_0000;
        ibm_space_lower   = 64'h0000_0000_0000_0000;
        ibm_space_upper   = 64'h0000_0000_ffff_ffff;
        foreach(data_pattern[i])
            data_pattern[i]=0;
        data_pattern_xmeta = 72'd0;
        mad = 8'h00;
        tl_vc_credit_count[0] = 128;
        tl_vc_credit_count[1] = 64;
        tl_vc_credit_count[2] = 0;
        tl_vc_credit_count[3] = 0;
        tlx_vc_credit_count[0] = 64;
        tlx_vc_credit_count[1] = 0;
        tlx_vc_credit_count[2] = 0;
        tlx_vc_credit_count[3] = 128;
        tl_data_credit_count[0] = 256;
        tl_data_credit_count[1] = 128;
        tl_data_credit_count[2] = 0;
        tl_data_credit_count[3] = 0;
        tlx_data_credit_count[0] = 128;
        tlx_data_credit_count[1] = 0;
        tlx_data_credit_count[2] = 0;
        tlx_data_credit_count[3] = 256;
        dl_credit_count = 32;
        tl_transmit_template = {1,1,0,0,1,0,0,1,0,0,1,0};
        tl_receive_template = {1,1,0,0,0,1,0,0,0,1,0,1};
        tl_transmit_rate = {`MAX_TEMPLATE_NUM{0}};
        tl_receive_rate = {`MAX_TEMPLATE_NUM{0}};
        host_back_off_timer = 5;
        host_receive_resp_timer = 20000;
        metadata_enable = 0;
        afu_send_cmd_enable = 1;
        bfm_send_resp_enable = 1;
        driver_cmd_buffer_size = 32;
        driver_last_nop_timer = 0;
        inject_err_enable = 0;
        inject_err_type = NONE;
        invalid_data_enable = 0;
        null_flit_enable = 1;
        pin_flit_err_rand_enable = 0;
        crit_ow_first_enable = 1 ;
        actag_base = 0;
        actag_length = 64;
        pasid_base = 0;
        pasid_length = 9;
        bdf = 1;       
        credits_check_enable = 1;
        consume_tl_credits_disable = 0;
        intrp_resp_ocmb_enable = 0;
        intrp_resp_wait_fir_clear = 0;
        intrp_resp_immd = 1;
        intrp_resp_bad_afutag_enable = 0;
        intrp_resp_bad_afutag_rnd = 1;
        intrp_resp_bad_afutag = 0;
        intrp_resp_num = 1;
        intrp_resp_last_good = 0;
        intrp_resp_all_good = 1;
        wr_resp_num_1_weight = 100;
        wr_resp_num_2_weight = 0;
        wr_resp_num_3_weight = 0;
        wr_resp_num_4_weight = 0;
        rd_resp_num_1_weight = 100;
        rd_resp_num_2_weight = 0;
        rd_resp_num_3_weight = 0;
        rd_resp_num_4_weight = 0;
        wr_fail_percent = 0;
        rd_fail_percent = 0;
        resp_rty_weight = 100;
        resp_xlate_weight = 0;
        resp_derror_weight = 0;
        resp_failed_weight = 0;
        resp_reserved_weight = 0;
        xlate_done_cmp_weight = 100;
        xlate_done_rty_weight = 0;
        xlate_done_aerror_weight = 0;
        xlate_done_reserved_weight = 0;
        split_reorder_enable = 0;
        resp_reorder_enable = 0;
        resp_delay_cycle = 0;
        resp_reorder_window_cycle = 0;
        tx_tmpl_priority = {0,1,0,0,0,0,0,0,0,0,0,0};
        tx_tmpl_priority_enable = 1;
    endfunction: default_config

endclass: tl_cfg_obj

`endif

