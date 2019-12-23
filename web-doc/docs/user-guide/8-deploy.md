# Deploy to Power Server

## Program FPGA

There are two ways to program FPGA: 
* Program Flash
* Program FPGA chip

### Program Flash

This is the default way to program FPGA. 

* Log on to Power9 server, 

``` 
$ git clone https://github.com/OpenCAPI/oc-utils/
$ make
$ sudo make install
```

* Copy the generated `hardware/build/Images/*.bin` from the development machine to Power9 server, and execute: 

```
sudo ./oc-flash-script.sh <file.bin>
```
 or for SPIx8 flash interface, two bin files should be provided. Usually it takes about 5 minutes.

```
$ sudo ./oc-flash-script.sh <file_primary.bin> <file_secondary.bin>
```

* If the script hints that the card is in use, that may mean the previous flashing wasn't done properly, and at this time the lock file is needed to be deleted manually.

```
$ rm -rf "/var/cxl/capi-flash-script.lock"
```

* Reload the Image. Then the new image should take effect.
```
sudo ./oc-reload.sh
```

!!!Note: 
    For some systems when the firmware hasn't been upgraded well, it may requires a reboot. 
```
sudo reboot now
```

At any time, you can check the card status by:
```
$ ls /dev/ocxl
IBM,oc-snap.0007:00:00.1.0
```


### Program FPGA chip

Not like "programming flash" which permanently stores FPGA image into the flash on the FPGA board, programming FPGA chip is a temporal method and mainly used for debugging purpose. It uses ***.bit** file and the programmed image will be lost if the server is powered off. 

Prepare a laptop/desktop machine and install **Vivado Lab**. Use USB cable to connect it to the FPGA board's USB-JTAG debugging port. Then in Vivado Lab, right click the FPGA device name and select "program device..." and provide the ***.bit** file. It only takes 10~20 seconds to complete.


Then Reset the card by:
```
cd oc-utils
sudo ./oc-reset.sh
```
Then the new image should show up. Note, this is a temporal programming. You still need to program the flash to permanently store your image.  

## Install libocxl

See [https://github.com/OpenCAPI/libocxl/]

[https://github.com/OpenCAPI/libocxl/]: https://github.com/OpenCAPI/libocxl/


## Compile OC-Accel software and actions

```
$ git clone https://github.com/<MY_NAME>/oc-accel
$ make apps
```

You can check the FPGA image version, name and build date/time by 

```
$ cd software/tools
$ sudo ./oc_maint -vvv
```

```
[main] Enter
[snap_open] Enter: IBM,oc-snap
[snap_open] Exit 0x141730670
[snap_version] Enter
SNAP Card Id: 0x31 Name: AD9V3. NVME disabled, 0 MB DRAM available. (Align: 1 Min_DMA: 1)
SNAP FPGA Release: v0.2.0 Distance: 255 GIT: 0x12fb0b24
SNAP FPGA Build (Y/M/D): 2019/09/13 Time (H:M): 11:24
[snap_version] Exit
[snap_action_info] Enter
   Short |  Action Type |   Level   | Action Name
   ------+--------------+-----------+------------
     0     0x10140002     0x00000002  IBM hdl_single_engine in Verilog (1024b)
[snap_action_info] Exit rc: 0
[main] Exit rc: 0
[snap_close] Enter
[snap_close] Exit 0
```

# Run Application

```
$ cd actions/<my_new_action>/sw
$ sudo ./<app_name>
```

!!!Note
    Whenever calling the FPGA card, `sudo` is needed.

