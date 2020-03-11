
// For a HDL design, this register layout file needs users' input.
Kernel (kernel_perf_test,
        KERNEL_ARGS (
            reg_user_status,
            reg_user_control,
            reg_user_mode,
            reg_init_rdata,
            reg_init_wdata,
            reg_tt_rd_cmd,
            reg_tt_rd_rsp,
            reg_tt_wr_cmd,
            reg_tt_wr_rsp,
            reg_tt_arid,
            reg_tt_awid,
            reg_tt_rid,
            reg_tt_bid,
            reg_rd_pattern,
            reg_rd_number,
            reg_wr_pattern,
            reg_wr_number,
            reg_source_address_l,
            reg_source_address_h,
            reg_target_address_l,
            reg_target_address_h,
            reg_error_info_l,
            reg_error_info_h,
            reg_soft_reset
        ));

void kernel_perf_test::addKernelParameters()
{
    setKernelParamRegister (PARAM::reg_user_status, 0x30);
    setKernelParamRegister (PARAM::reg_user_control, 0x34);
    setKernelParamRegister (PARAM::reg_user_mode, 0x38);
    setKernelParamRegister (PARAM::reg_init_rdata, 0x3c);         //non-zero init read data
    setKernelParamRegister (PARAM::reg_init_wdata, 0x40);         //non-zero init write data

    setKernelParamRegister (PARAM::reg_tt_rd_cmd, 0x44);          //time trace ram, when arvalid is sent
    setKernelParamRegister (PARAM::reg_tt_rd_rsp, 0x48);          //time trace ram, when rlast is received
    setKernelParamRegister (PARAM::reg_tt_wr_cmd, 0x4c);          //time trace ram, when awvalid is sent
    setKernelParamRegister (PARAM::reg_tt_wr_rsp, 0x50);          //time trace ram, when bvalid is received

    setKernelParamRegister (PARAM::reg_tt_arid, 0x54);            //id trace ram,
    setKernelParamRegister (PARAM::reg_tt_awid, 0x58);            //id trace ram,
    setKernelParamRegister (PARAM::reg_tt_rid, 0x5c);             //id trace ram,
    setKernelParamRegister (PARAM::reg_tt_bid, 0x60);             //id trace ram,

    setKernelParamRegister (PARAM::reg_rd_pattern, 0x64);         //axi read pattern
    setKernelParamRegister (PARAM::reg_rd_number, 0x68);          //how many axi read transactions
    setKernelParamRegister (PARAM::reg_wr_pattern, 0x6c);         //axi write pattern
    setKernelParamRegister (PARAM::reg_wr_number, 0x70);          //how many axi write trasactions

    setKernelParamRegister (PARAM::reg_source_address_l, 0x74);
    setKernelParamRegister (PARAM::reg_source_address_h, 0x78);
    setKernelParamRegister (PARAM::reg_target_address_l, 0x7c);
    setKernelParamRegister (PARAM::reg_target_address_h, 0x80);

    setKernelParamRegister (PARAM::reg_error_info_l, 0x84);
    setKernelParamRegister (PARAM::reg_error_info_h, 0x88);
    setKernelParamRegister (PARAM::reg_soft_reset, 0x8c);
}
