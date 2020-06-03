# HLS_MMULT EXAMPLE

* Provides a simple base allowing to discover AC-ACCEL
* C code is changing characters case of a user phrase
  * code can be executed on the CPU (will perform matrix multiplication in CPU)
  * code can be simulated (will perform matrix multiplication in simulation)
  * code can then run in hardware when the FPGA is programmed (will perform matrix multiplication in hardware)
* The example code uses the copy mechanism to get/put the data from/to system host memory

