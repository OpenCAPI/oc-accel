# OC-Accel Framework

OpenCAPI Acceleration Framework, abbreviated as OC-Accel, is a framework that helps you implement your FPGA acceleration solutions with OpenCAPI technology.

# Documentation
 <https://opencapi.github.io/oc-accel-doc/>

# Dependencies 
 * On a X86 server:
    * Install Xilinx tools (Check <https://opencapi.github.io/oc-accel-doc/#dependencies>) with the desired fpga family (used by the card you want to test).
    * set XILINX_ROOT and XILINXD_LICENSE_FILE accordingly and source Xilinx setting shell: 
    ```console
    export XILINX_ROOT=/opt/Xilinx/xxxx.y   # setup your xilinx tools install dir. eg xxxx.y = 2020.1
    export XILINXD_LICENSE_FILE=2100@xxxxx.com	# Vivado license
    . $XILINX_ROOT/settings64.sh
    ```
 * On a POWER9 server:
   * Install lib-ocxl on server:
     ```console
     sudo apt-get install libocxl-dev # for Ubuntu
     sudo yum install libocxl-devel   # for RHEL
     ```

# Quick Start, Step 1: Simulate and Build FPGA on x86:
 * Clone OpenCAPI Simulation Engine and OC-Accel framework
   ```console
   git clone https://github.com/OpenCAPI/ocse.git
   git clone https://github.com/OpenCAPI/oc-accel.git
   cd oc-accel
   make snap_config  ## this uses an opensource Kconfig menu
   ```
 * In the menu: 
    * Select a card and an example (eg: hls_helloworld_1024) to test (use space bar)
    * Exit the menu
 * Now run a simulation on X86 with default xsim simulator
   ```console
   make sim     ## (or make sim_tmux if no xterm available)
   ```
 * In the terminal run:(stay in the current default directory) 
   ```console
   snap_helloworld_1024 # the default help will propose the simulation example 
   ```
 * Run the proposed test and check it passes ok
 * To generate the flash content run:
   ```console
   make image
   ```
 This produces a .bin file (it is the full description of the FPGA content) to be loaded in memory of the chosen OC card plugged in a POWER9 server.
 File is located in ~/oc-accel/hardware/build/Images/

# Quick Start, Step 2: Program and Test on POWER9 server:
* Card flash programming:
     * Card is new : Check card supplier procedure. Some allow PCIe flash programming, other require JTAG probe.
     * Card is already programmed with a previous OC binary:
        * Transfer the .bin file into the POWER server by any mean (scp, ftp, ...)
        * Use OpenCAPI Utils tools to load the oc_date_XX_hls_helloworld_1024_YY_OC-card_YY.bin file.
           ```console
           sudo git clone https://github.com/OpenCAPI/oc-utils.git
           sudo make install # default installation
           ```
        * Flash the card memory.
          ```console
          sudo oc-flash-script oc_date_XX_hls_helloworld_1024_YY_OC-card_YY.bin
          ```
* Install oc-accel on the POWER server and compile code:
  ```console
  git clone https://github.com/OpenCAPI/oc-accel.git
  cd oc-accel
  make all
  ```
* Run the default test:
  ```console
  ./actions/hls_helloworld_1024/tests/hw_test.sh
  ```
* Check results

# Contributing
This is an open-source project. We greatly appreciate your contributions and collaboration.
Before contributing to this project, please read and agree to the rules in
* [CONTRIBUTING.md](CONTRIBUTING.md)

To simplify the sign-off, you may want to create a ".gitconfig" file in you home by executing:
```
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```
Then, for every commit, use `git commit -s` to add the "Signed-off by ..." message.

By default the git repository is read-only. Users can fork the snap repository, make the changes there and issue a pull request.
Even members with write access to this repository can't commit directly into the protected master branch. To contribute changes, please create a branch, make the changes there and issue a pull request.

Pull requests to merge into the master branch must be reviewed before they will be merged.
