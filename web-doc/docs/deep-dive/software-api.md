# OC-Accel Software

## Environment Variables

To debug libsnap functionality or associated actions, there are currently some environment variables available:

- ***SNAP_TRACE***: 
    - 0x1 General libsnap trace
    - 0x2 Enable register read/write trace
    - 0x4 Enable simulation specific trace
    - 0x8 Enable action traces. 
    - For example, use `SNAP_TRACE=0xF` to enable all above.
    - Applications might use more bits above those defined here.


## Tools
* snap_maint: Currently it just prints information. 
* snap_peek: debug tools to read MMIO registers.
* snap_poke: debug tools to write MMIO registers.


## APIs

Refer to: 

* include/libosnap.h
* lib/osnap.c
