# Migrate from SNAP1.0/2.0

## Data width change
The AXI data port width of OC-Accel is 1024bit. But the actions developed in SNAP (CAPI1.0/2.0) use 512b. 

Please select 512b in Kconfig Menu. Then a dwidth_converter will be inserted automatically.

![dwidtch-convertor] (pictures/9-dwidth-converter.svg)

All of the AXI4 features in SNAP are supported by OC-Accel, and it has added more. Read [OC-Accel AXI4 feature list] for more details. 

[OC-Accel AXI4 feature list]: ../../deep-dive/hardware-logic/

## Clock frequency

The default clock frequency in SNAP (CAPI1.0/2.0) was **250MHz**. There was no asynchronous logic between capi2-bsp, snap_core and action_wrapper so the frequency had to be adjusted together. 

The default clock frequency for **action_wrapper** in OC-Accel is **200MHz**. Asynchronous clocks have been designed for oc-bip, snap_core and action_wrapper so the clock frequency can be adjusted more flexibly for each part. See [Clock domains]. 

[Clock Domains]: ../../deep-dive/hardware-logic/#diagram-and-clock-domain


## Library name

| SNAP (CAPI1.0/2.0) | OC-Accel (OpenCAPI3.0)|
| ----    | ---- |
| libcxl  | libocxl | 
| libsnap | libosnap |


## Included headers 

| SNAP (CAPI1.0/2.0) | OC-Accel (OpenCAPI3.0) |
| --- | --- |
| snap_types.h | osnap_types.h | 
| snap_tools.h | osnap_tools.h |
| snap_queue.h | osnap_queue.h | 
| snap_internal.h | osnap_internal.h| 
| snap_hls_if.h | osnap_hls_if.h |
| snap_m_regs.h | osnap_global_regs.h| 
| snap_s_regs.h | N/A |
| snap_regs.h | N/A |
| libsnap.h | libosnap.h | 


There is a big change of the Register Map. OC-Accel has simplified and enlarged the Register Layout. 

* [SNAP1/2 Register map] 
* [OC-Accel Register map]

[SNAP1/2 Register map]: https://github.com/open-power/snap/blob/master/hardware/doc/SNAP-Registers.md

[OC-Accel Register map]: ../../deep-dive/registers/

## API changes
| SNAP (CAPI1.0/2.0) | OC-Accel (OpenCAPI3.0) |
| --- | --- |
| snap_mmio_read32() | snap_action_read32() |
| snap_mmio_write32() | snap_action_write32() |
| snap_mmio_read64() | snap_global_read64()|
| snap_mmio_write64()| snap_global_write64() |

The API changes also reflect the Register map changes. 

## SNAP_CONFIG=CPU discarded

In SNAP (CAPI1.0/2.0), it has implemented a group of function pointers for CPU to emulate the FPGA action, aka "software action". It is enabled when setting `SNAP_CONFIG=CPU`: 
``` C
/* Software version of the lowlevel functions */
static struct snap_funcs software_funcs = {
	.card_alloc_dev = sw_card_alloc_dev,
	.attach_action = sw_attach_action, /* attach Action */
	.detach_action = sw_detach_action, /* detach Action */
	.mmio_write32 = sw_mmio_write32,
	.mmio_read32 = sw_mmio_read32,
	.mmio_write64 = sw_mmio_write64,
	.mmio_read64 = sw_mmio_read64,
	.card_free = sw_card_free,
	.card_ioctl = sw_card_ioctl,
};
```
**These functions have been deleted.** The original purpose of `SNAP_CONFIG=CPU` is to provide a way to fall back to software execution when FPGA is not available. However, this actually can be easily done by higher level of application control, for example: 

```
if (!snap_card_alloc_dev()) //Failed to open FPGA card
    call_original_software_function
```

So there is no need to rewrite the original software function at all.

The corresponding concept is `SNAP_CONFIG=FPGA` and it becomes the ONLY working mode in OC-Accel. So the variable `SNAP_CONFIG` has been deleted.



