
// ---- AUTO GENERATED! DO NOT EDIT! ----
class vadd: public KernelRegisterLayout
{
public:
    vadd() : KernelRegisterLayout()
    {
        setKernelParamNumber (PARAM::PARAM_NUM);
        addKernelParameters(); 
    }; 
    enum class PARAM : int {
        in1_1,
        in1_2,
        in2_1,
        in2_2,
        out_r_1,
        out_r_2,
        size,
        PARAM_NUM
    };

protected:
    void setKernelParamNumber (PARAM num)
    {
        m_kernel_params_regs.resize (static_cast<int> (num), 0);
    }
    void setKernelParamRegister (PARAM reg, uint64_t offset)
    {
        m_kernel_params_regs[static_cast<int> (reg)] = offset;
    }

    virtual void addKernelParameters ()
    {
        setKernelParamRegister (PARAM::in1_1, 0x10);
        setKernelParamRegister (PARAM::in1_2, 0x14);
        setKernelParamRegister (PARAM::in2_1, 0x1c);
        setKernelParamRegister (PARAM::in2_2, 0x20);
        setKernelParamRegister (PARAM::out_r_1, 0x28);
        setKernelParamRegister (PARAM::out_r_2, 0x2c);
        setKernelParamRegister (PARAM::size, 0x34);
    }
}; /* register_layout */
