# HLS Action Header (Include)

## Job structure

Under `$ACTION_ROOT/include`, the hardware and software interfaces are defined here by a `job_t` data structure. For example: 

``` C
/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct helloworld_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
} helloworld_job_t;
```
!!!Warning
    You may have to set `__attribute__((packed))` to the above job_t structure. If the complier adds "gaps" in between the structure variables, it may cause errors.

## Action Type and Version

And the `ACTION_TYPE` and `RELEASE_LEVEL`:

``` C
// ------------ MUST READ -----------
// ACTION_TYPE and RELEASE_LEVEL are automatically handled. 
// 1. Define them in header file (here), use HEX 32bits numbers
// 2. They will be extracted by hardware/setup/patch_version.sh
// 3. And put into snap_global_vars.v
// 4. Used by hardware/hls/action_wrapper.v

#define ACTION_TYPE               0x10143008
#define RELEASE_LEVEL             0x00000022

// For oc_maint, Action descriptions are decoded with the help of software/tools/snap_actions.h
// Please modify this file so oc_maint can recognize this action.
// ------------ MUST READ -----------
```


# HLS Action HW Design

Take hls_memcopy_1024 as an example, the top design is `hardware/hdl/hls/action_wrapper.vhd_source` but the HLS developer doesn't need to modify it. That is a common wrapper. 

## hls_action()
HLS developer needs to modify `$ACTION_ROOT/hw/xxx.CPP`, starting from `hls_action()`:

``` C
//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_1024_t *din_gmem,
		snap_membus_1024_t *dout_gmem,
		snap_membus_512_t *d_ddrmem,
		action_reg *act_reg,
		action_RO_config_reg *Action_Config)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512  \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050

	// Host Memory AXI Lite Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

...
```

In Vivado High Level Synthesis, the above C code can be synthesized to have:

* Host Memory AXI Interface
    * din_gmem
    * dout_gmem

* DDR memory Interface
    * d_ddrmem

* AXI Lite Interface
    * Action_Config at offset 0x10
    * act_reg at offset 0x100


## din_gmem and dout_gmem

They represent the whole `2^64` Host memory space. But this memory space is shaped as a **128Bytes width**, **(2^64/128) depth** array. With CAPI/OpenCAPI, the action hardware can directly use EA (effective address, the same pointer in software) to access host memory. 

You will see this shape from the definition of "snap_membus_1024_t".

``` C
snap_membus_1024_t *din_gmem,
snap_membus_1024_t *dout_gmem,
``` 

Because din_gmem and dout_gmem are shaped as 128B width, the EA address needs to be right-shifted by `log2(128) = 7` before being used as din_gmem/dout_gmem's array index. 

``` C
// byte address received need to be aligned with port width
InputIndex = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT_1024;
OutputIndex = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT_1024;
```

Then you can use `memcpy()` or `data = din_gmem[index]` or `dout_gmem[index] = data` to use them.


* din_gmem is for reading data from Host.
* dout_gmem is for writing data to Host.

They should be able to be combined just like **d_ddrmem** but we want to keep the same style as SNAP1/2 for now.

## d_ddrmem
It represents one channel of DDR on FPGA board. In SNAP1/2 and OC-Accel, only one channel (one DDR memory controller) is implemented as an example. 

However, usually the FPGA board provides more than one DDR channel. There are multiple ways to arrange them so it's user-case dependent. 

Some FPGA boards have HBM. The developer can enable it similarly like DDR, which is introduced in [Deep Dive: New board support].

[Deep Dive: New board support]: ../../deep-dive/board-package/

Please be aware of the address range you can use for a single DDR channel. d_ddrmem is shaped as a **64Bytes width**, **(Capacity/64)** depth array. Exceeding the available DDR address range will lead to an unknown error.

## AXI Lite Registers

* The first 16bytes **(0x00 to 0x0F)** are pre-defined by `software/include/osnap_hls_if.h`, the user is not supposed to change that. It controls the **start**, **stop** and **interrupt** of the HLS Action.


* The action_reg has 128bytes **(0x100 to 0x180)**, composed of two segments **Control** and **job Data**, defined in `$ACTION_ROOT/hw/*.H`

``` C
typedef struct {
	CONTROL Control;	/*  16 bytes */
	memcopy_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(memcopy_job_t)];
} action_reg;
```

* Struct CONTROL is also defined in `actions/include/hls_snap*.H`, it defines the **flags** and **return code**.

``` C
typedef struct {
        snapu8_t sat;
        snapu8_t flags;
        snapu16_t seq;
        snapu32_t Retc;
        snapu64_t Reserved;
} CONTROL;
```

* At last, what the developer can really freely define is just **job Data**: 

``` C
memcopy_job_t Data;	/* up to 108 bytes */
```

!!!Note
    If 108 bytes are not enough, please define a small buffer in Host memory as **WED buffer** (Work Element Descriptor), store all of the parameters in this WED buffer, and just put the address pointers of this WED buffer into `xxxx_job_t`. Ask HLS Action to read the content of WED buffer first, then do the following jobs.

The above register layout is also drawn in [Deep Dive: Registers] 

[Deep Dive: Registers]: ../../deep-dive/registers/#action-register-definition

## HLS optimization

Xilinx Document [UG902: Vivado High-Level Synthesis] is an important guide book to understand how to add "directives" to your HLS C/C++ code.

[UG902: Vivado High-Level Synthesis]: https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_1/ug902-vivado-high-level-synthesis.pdf

You can also refer to SNAP1/2 document [How to Optimize HLS Action] to learn how to run standalone testing before OCSE Co-simulation, and how to fully explore UNROLL and PIPELINE directives in HLS. 

[How to Optimize HLS Action]: https://github.com/open-power/snap/blob/master/doc/AN_CAPI_SNAP-How_to_optimize_an_HLS_action.pdf

# HLS Action SW Design

The steps include:

* snap_card_alloc_dev()
* snap_attach_action()
* **Prepare job**: snap_set_job()
* **Main body**: snap_action_sync_execute_job(), which has three steps:
    * snap_action_sync_execute_job_set_regs (action, cjob); //Set action_reg by MMIO
    * snap_action_start(action);
    * snap_action_sync_execute_job_check_completion (action, cjob, timeout_sec);
* **Check Return code**: `cjob.retc`
* snap_detach_action()
* snap_card_free()


The definition of these function calls can be found in `software/lib/osnap.c`. 



