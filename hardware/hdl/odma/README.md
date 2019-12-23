# OC-ACCEL ODMA Introduction
OpenCAPI ACCEL DMA subsystem is a high-performance direct memory access data mover between host OpenCAPI interface and accelerator AXI interface. 
This DMA engine is developed based on OpenCAPI 3.0 and AXI4 specification and is working under OC-ACCEL framework. In the OC-ACCEL framework,there are two modes to perform data transfer:
* ODMA mode: The core can be configured with either an AXI (memory mapped) interface or with an AXI streaming interface to connect to accelerator action RTL logic. The DMA supports up to four upstream and downstream channels, and an optional descriptor bypass to manage descriptors from the FPGA fabric.
* Bridge mode: When configured as a bridge, received OpenCAPI packets are converted to AXI traffic and received AXI traffic is converted to OpenCAPI traffic. The bridge functionality is ideal for accelerator action needing a quick and easy way to access host memory.

This directory contains all the DMA mode files.
