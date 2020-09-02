# OC-Accel Framework

OpenCAPI Acceleration Framework, abbreviated as OC-Accel, is a framework that helps you implement your FPGA acceleration solutions with OpenCAPI technology.

# Quick Start
 * Dependencies 
 * Install Xilinx tools with desired part (used by the card you want to test)
 * Run the Xilinx setup shell with proper license and path settings
 * Clone OpenCAPI Simulation Engine and Oc-accel framework
 ```console
 git clone git@github.com:OpenCAPI/ocse
 git clone https://github.com/OpenCAPI/oc-accel.git
 cd oc-accel
 make snap_config
 ```
 * In the menu :
 * Select hls_helloworld example
 * exit
 * run make sim (or make sim_tmux)
 * in the xterm run 
 ```console
 snap_helloworld_1024
 ```
 to get the application help
 * copy paste simulation case : 
 ```console
echo Clean possible temporary old files 
echo Prepare the text to process
echo "Hello world_1024. This is my first CAPI SNAP experience. It's real fun." > /tmp/t1

echo Run the application + hardware action
snap_helloworld_1024 -i /tmp/t1 -o /tmp/t2
echo Display input file: && cat /tmp/t1
echo Display output file from FPGA executed action -UPPER CASE expected-: && cat /tmp/t2
```

 * check test passes ok
 * to generate the flash content run
 ```console
 make image
 ```
 This produces the project.mcs file to be loaded in memory of a OC cards plugged in a POWER9 server
 File is located at $OC-ROOT/hardware/build/Images/project.mcs
 
# Check on POWER9 OpenCAPI server
* Card is new : need to use Xilinx vivado_lab and JTAG probe to load the fpga
* Card is already programmed with a previous OC binary , use OpenCAPI Utils tools to load the .mcs file https://github.com/OpenCAPI/oc-utils.git

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
