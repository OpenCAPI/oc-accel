# Hardware (FPGA) Design Description

## General description ##
* Heart of the action is collect_data routine with DATAFLOW region, composed of three tasks: 
    * Decode Ethernet packets
    * Apply corrections
    * Write to memory

## Input and output
* Action register
* Memory regions

## Internal memory
* HBM2
* UltraRAM buffer

