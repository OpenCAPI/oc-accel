// ---- AUTO GENERATED! DO NOT EDIT! ----
Kernel(vadd, KERNEL_ARGS(in1_1,in1_2,in2_1,in2_2,out_r_1,out_r_2,size));
void vadd::addKernelParameters ()
    {
        setKernelParamRegister (PARAM::in1_1, 0x10);
        setKernelParamRegister (PARAM::in1_2, 0x14);
        setKernelParamRegister (PARAM::in2_1, 0x1c);
        setKernelParamRegister (PARAM::in2_2, 0x20);
        setKernelParamRegister (PARAM::out_r_1, 0x28);
        setKernelParamRegister (PARAM::out_r_2, 0x2c);
        setKernelParamRegister (PARAM::size, 0x34);
    }
