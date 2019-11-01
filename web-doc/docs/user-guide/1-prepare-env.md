This page will introduce the basic environmental requests, tools, and general commands to run OC-Accel flow.

# Prepare Environment

## Basic Tools

Firstly, you need to have an x86 machine for development with [Vivado Tool] and the license.

```
export XILINX_VIVADO=<...path...>/Xilinx/Vivado/<VERSION>
export XILINXD_LICENSE_FILE=<pointer to Xilinx license>
export PATH=$PATH:${XILINX_VIVADO}/bin
```

!!!Note
    OC-Accel works on Vivado 2018.2, 2018.3 and 2019.1

    For AD9H3 and AD9H7 cards with HBM, Vivado version is at least 2018.3

There is a file `setup_tools.ksh` in the root directory for reference. But for the beginning, only Vivado is required.

Make sure you have `gcc`, `make`, `sed`, `awk`, `xterm` and `python` installed.
`setup_tools.ksh`

You may install other simulators to accelerate the speed of simulation. For example, [Cadence xcelium]. See in [co-simulation] for more information.

[co-simulation]: ../6-co-simulation/

[ Vivado Tool ]: https://www.xilinx.com/support/download.html

[ Cadence xcelium ]: https://www.cadence.com/content/cadence-www/global/en_US/home/tools/system-design-and-verification/simulation-and-testbench-verification/xcelium-parallel-simulator.html



## Clone Github Repositories

TODO: Link to update

```
git clone git@github.com:OpenCAPI/oc-accel.git
cd oc-accel
git submodule init
git submodule update

cd ..
git clone git@github.com:OpenCAPI/ocse.git
```

It's better to have `ocse` stay in the same directory parallel to `oc-accel`. That is the default path of `$OCSE_ROOT`. Or you need to assign `$OCSE_ROOT` explicitly in `snap_env.sh`.

# Basic terms
## Option1: All-in-one python script

OC-Accel developed a "all-in-one" Python script to control the workflow. It's convenient to do batch work, or enable your regression verification or continuous integration.


```
cd oc-accel
./ocaccel_workflow.py
```

This script will

* Check environmental variables
* make snap_config
* build model
* start simulation

There are many options provided by `ocaccel_workflow.py`. Check the help messages by

```
./ocaccel_workflow.py --help
```

It helps you to do all kinds of operations in one command line.

## Option2: Traditional "make" steps

If you have used SNAP for CAPI1.0 and CAPI2.0, you can continue to use these "traditional" make steps. Just typing "make" doesn't work. An explicit target is needed. You can find them in `Makefile` file.

```
cd oc-accel
make help
```

```
Main targets for the SNAP Framework make process:
=================================================
* snap_config    Configure SNAP framework
* model          Build simulation model for simulator specified via target snap_config
* sim            Start a simulation
* sim_tmux       Start a simulation in tmux (no xterm window popped up)
* hw_project     Create Vivado project with oc-bip
* image          Build a complete FPGA bitstream after hw_project (takes more than one hour)
* hardware       One step to build FPGA bitstream (Combines targets 'model' and 'image')
* software       Build software libraries and tools for SNAP
* apps           Build the applications for all actions
* clean          Remove all files generated in make process
* clean_config   As target 'clean' plus reset of the configuration
* help           Print this message



The hardware related targets 'model', 'image', 'hardware', 'hw_project' and 'sim'
do only exist on an x86 platform
```



### For simulation

* `make snap_config`
* `make model`
* `make sim`

!!!Note
    After `make model`,  you can continue to run `make image` to generate bitstreams.


In fact, `make model` also creates a Vivado project `framework.xpr` in `hardware/viv_project`. Then it exports the simulation files and compiles them to a simulation model.


### For Image build

* `make snap_config` If it has already been executed, no need to run it again.
* `make hw_project`
* `make image`

!!!Note
    **Use Vivado GUI**:

    After `make hw_project`, you can open project `framework.xpr` in `hardware/viv_project`, and do following **"run Synthesis"**, **"run Implementation"** and **"generate Bitstream"** in Vivado GUI.


## Output files

* The log files during these steps are placed in `hardware/logs`.

* Simulation output files are placed in `hardware/sim/<SIMULATOR>/latest`.

* If you are using `make image` to generate bitstreams, the outputs are in `hardware/build`, including `Images`, `Reports` and `Checkpoints`.

* If you are using Vivado Gui mode to generate bitstream, the outputs are in `hardware/viv_project/framework.runs`, including `synth_1` and `impl_1`, etc.



# Let's go!

Now, let's take an example `hls_helloworld`, and have a look at how it runs step by step. Please continue to read page [Run helloworld].

[Run helloworld]: ../2-run-helloworld/

