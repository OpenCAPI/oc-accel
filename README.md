# OC-Accel Framework

OpenCAPI Acceleration Framework, abbreviated as OC-Accel, is a framework that helps you implement your FPGA acceleration solutions with OpenCAPI technology.

# Dependencies 
 * on a X86 server:
    * Install Xilinx tools (Vivado) with desired part (used by the card you want to test)
    * Run the Xilinx setup shell with proper license and path settings

# Quick Start
 * Clone OpenCAPI Simulation Engine and Oc-accel framework
 ```console
 git clone git@github.com:OpenCAPI/ocse
 git clone https://github.com/OpenCAPI/oc-accel.git
 cd oc-accel
 make snap_config  ## this uses an opensource Kconfig menu
 ```
 * In the menu: 
    * select a card and an example to test
    * Exit the menu
 * Now run a simulation on X86 with default xsim simulator
  ```console
  make sim     ## (or make sim_tmux if no xterm available)
  ```
 * In the term run 
 ```console
 snap_helloworld_1024 # the default help will propose the simulation example 
 ```
 * Run the proposed test and check it passes ok
 * To generate the flash content run
 ```console
 make image
 ```
 This produces the project.mcs file (it is the full description of the FPGA content) to be loaded in memory of a OC cards plugged in a POWER9 server
 File is located at $OC-ROOT/hardware/build/Images/project.bin
 
# Check on POWER9 OpenCAPI server
* Card is new : need to use Xilinx vivado_lab and JTAG probe to load the fpga
* Card is already programmed with a previous OC binary , use OpenCAPI Utils tools to load the .mcs file
   ```console
   sudo git clone https://github.com/OpenCAPI/oc-accel.git
   ```
   * Follow https://github.com/OpenCAPI/oc-utils.git installation procedure.
   * Flash the card memory
   ```console
   sudo oc-flash-script project.bin
   ```
* Install oc-accel on the POWER server   
```console
git clone https://github.com/OpenCAPI/oc-accel.git
cd oc-accel
make all
## Run a default test when available
./actions/the_example_you_choose/sw/test/hw_test.sh
```
Check results

# Documentation
 <https://opencapi.github.io/oc-accel-doc/>


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
