#!/usr/bin/env python
#
# Copyright 2019 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import sys
import qa
import random
from os.path import join as pathjoin
from os.path import isfile as isfile
from env_clean import env_clean
from env_check import env_check
from configure import Configuration
from make_model import make_model
from run_sim import SimSession
from make_image import make_image
from optparse import OptionParser
from ocaccel_utils import msg

usage = '''%prog <options>
The wrapper to guide through the whole OC-ACCEL workflow.

Example with commands:
* Run configuration
`%prog config`
* Build the model
`%prog model`
* Run simulation
`%prog sim`
* Build bitstream 
`%prog image`
* Clean the directory
`%prog clean`
* Clean the configuration
`%prog config_clean`

Example with fine command line controls:
* Run the full flow from configuration to simulation:
`%prog --ocse_path <path to ocse root> --simulator xcelium --testcase "ocaccel_example -a 6 -vv"`
* Skip the simulation model build:
`%prog --no_make_model -o <path to ocse root> -s xcelium -t "ocaccel_example -a 6 -vv"`
* Run testcase in an pop-up xterm:
`%prog --no_make_model -o <path to ocse root> -s xcelium -t terminal`
* Clean the environment before running:
`%prog -c --no_make_model -o <path to ocse root> -s xcelium -t terminal`
* Run in interactive mode:
`%prog -i --ocse_path <path to ocse root> --simulator xcelium --testcase "ocaccel_example -a 6 -vv"`
* Run in unit sim model:
`%prog --unit_sim --simulator xcelium`
'''

parser = OptionParser(usage=usage)
parser.add_option("--no_env_check",
                  action="store_true", dest="no_env_check", default=False,
                  help="Don't check the environment settings, default: %default")
parser.add_option("--no_configure",
                  action="store_true", dest="no_configure", default=False,
                  help="Don't configure the actions, default: %default")
parser.add_option("--no_make_model",
                  action="store_true", dest="no_make_model", default=False,
                  help="Don't make simulation model, default: %default")
parser.add_option("--no_run_sim",
                  action="store_true", dest="no_run_sim", default=False,
                  help="Don't run simulation, default: %default")
parser.add_option("-m", "--make_image",
                  action="store_true", dest="make_image", default=False,
                  help="Generate the FPGA image, default: %default")
parser.add_option("-c", "--clean",
                  action="store_true", dest="clean", default=False,
                  help="Clean the directory before running, default: %default")
parser.add_option("-C", "--config_clean",
                  action="store_true", dest="config_clean", default=False,
                  help="Clean the configuration before running, default: %default")
parser.add_option("-q", "--quite",
                  action="store_true", dest="quite", default=False,
                  help="Print less message to the stdout")
parser.add_option("-i", "--interactive",
                  action="store_true", dest="interactive", default=False,
                  help="Don't use the interactive mode during the flow, default: %default")
parser.add_option("-o", "--ocse_path", dest="ocse_path", default=None,
                  help="Path to OCSE root. No default value.", metavar="DIRECTORY")
parser.add_option("-r", "--ocaccel_root", dest="ocaccel_root", default=os.path.abspath("."),
                  help="Path to ocaccel root, default: %default", metavar="DIRECTORY")
parser.add_option("-a", "--action_root", dest="action_root", default=None,
                  help="Path to ACTION root. No default value.", metavar="DIRECTORY")
parser.add_option("-s", "--simulator", dest="simulator", default=None,
                  help="Simulator used for simulation. No default value.", metavar="<nosim, xcelium, xsim>")
parser.add_option("-t", "--testcase", dest="testcase", default="terminal",
                  help="Testcase used for simulation, default: %default", metavar="STRING")
parser.add_option("--simulator_start_timeout", dest="sim_timeout", type="int", default=600,
                  help="How long we will wait for simulator to start (in seconds), default: %default")
parser.add_option("--make_timeout", dest="make_timeout", type="int", default=2592000,
                  help="How long we will wait for make model or make image to finish (in seconds), default: %default")
parser.add_option("--predefined_config", dest="predefined_config", default=None,
                  help="Predefined configurations used for configure phase. No default value.", metavar="check possible values in defconfig/")
parser.add_option("--unit_sim",
                  action="store_true", dest="unit_sim", default=False,
                  help="Run unit simulation for OC-ACCEL bridge test, no OCSE and software, only UVM based testbench included, default: %default")
parser.add_option("--odma",
                  action="store_true", dest="odma", default=False,
                  help="Use ODMA instead of TLX-AXI bridge. This flag only works in unit_sim mode, i.e., running odma in unit sim env. For general ODMA"
                  "enablement, please specify it in the configuration window. default: %default")
parser.add_option("--odma_mode", dest="odma_mode", default="mm_1024",
                  help="ODMA data path transfer type. default: %default.", metavar="<mm_1024, mm_512, st_1024, st_512>")
parser.add_option("--sv_seed", dest="sv_seed", default=str(random.randint(0, 0xffffffff)),
                  help="Seed used for system verilog, default: random", metavar="STRING")
parser.add_option("--unit_test", dest="unit_test", default="bfm_test_read_4k_write_4k",
                  help="Testcase used for unit_sim simulation, default: %default", metavar="STRING")
parser.add_option("--uvm_ver", dest="uvm_ver", default="UVM_LOW",
                  help="UVM_VERBOSITY for unit_sim simulation, default: %default", metavar="STRING")
parser.add_option("--no_wave",
                  action="store_true", dest="no_wave", default=False,
                  help="Don't dump waveform for simulation. default: %default")
(options, leftovers) = parser.parse_args()

if options.ocse_path is not None:
    options.ocse_path = os.path.abspath(options.ocse_path)
options.ocaccel_root = os.path.abspath(options.ocaccel_root)
if options.action_root is not None:
    options.action_root = os.path.abspath(options.action_root)
if options.simulator is not None:
    options.simulator = options.simulator.lower()
if options.odma_mode is not None:
    options.odma_mode = options.odma_mode.lower()
# Unit sim has a dedicated config file, not configurable by user
if options.unit_sim == True:
    if options.odma == True:
        if options.odma_mode.lower() == "mm_1024":
            options.predefined_config = "hdl_unit_sim.odma.defconfig"
        elif options.odma_mode.lower() == "mm_512":
            options.predefined_config = "hdl_unit_sim.odma_mm_512.defconfig"
        elif options.odma_mode.lower() == "st_512":
            options.predefined_config = "hdl_unit_sim.odma_st_512.defconfig"
        elif options.odma_mode.lower() == "st_1024":
            options.predefined_config = "hdl_unit_sim.odma_st_1024.defconfig"
        else:
            options.predefined_config = "hdl_unit_sim.odma.defconfig"
    else:
        options.predefined_config = "hdl_unit_sim.bridge.defconfig"

logs_path = pathjoin(options.ocaccel_root, 'hardware', 'logs')
try: 
    os.makedirs(logs_path)
except OSError:
    if not os.path.isdir(logs_path):
        raise

ocaccel_workflow_log            = pathjoin(logs_path, "ocaccel_workflow.log")
ocaccel_workflow_make_model_log = pathjoin(logs_path, "ocaccel_workflow.make_model.log")
ocaccel_workflow_make_image_log = pathjoin(logs_path, "ocaccel_workflow.make_image.log")

cmd = ""
if len(leftovers) > 0:
    cmd = leftovers[0]

if cmd != "":
    msg.ok_msg_blue('''--------> Running with COMMAND * %s * O(n_n)O~''' % cmd)
    # Embedded combination of options
    if cmd == 'config':
        options.no_configure = False
        options.no_make_model = True
        options.no_run_sim = True
        options.make_image = False
    elif cmd == 'model':
        options.no_configure = True
        options.no_make_model = False
        options.no_run_sim = True
        options.make_image = False
    elif cmd == 'sim':
        options.no_configure = True
        options.no_make_model = True
        options.no_run_sim = False
        options.make_image = False
    elif cmd == 'image':
        options.no_configure = True
        options.no_make_model = True
        options.no_run_sim = True
        options.make_image = True
    elif cmd == 'clean':
        options.no_configure = True
        options.no_make_model = True
        options.no_run_sim = True
        options.make_image = False
        options.clean = True
        options.config_clean = False
        options.no_env_check = True
    elif cmd == 'config_clean':
        options.no_configure = True
        options.no_make_model = True
        options.no_run_sim = True
        options.make_image = False
        options.clean = True
        options.config_clean = True
        options.no_env_check = True
    else:
        msg.fail_msg ("Invalid command %s" % cmd)
        exit(1)

if __name__ == '__main__':
    msg.ok_msg_blue("--------> WELCOME to IBM OpenCAPI Acceleration Framework")
    question_and_answer = qa.QuestionAndAnswer(options)

    question_and_answer.ask(qa.ask_clean_str)
    if options.clean or options.config_clean:
        env_clean(options, ocaccel_workflow_log)
        exit(0)

    cfg = Configuration(options)
    cfg.log = ocaccel_workflow_log
    question_and_answer.cfg = cfg
    question_and_answer.ask(qa.ask_configure_str)
    if not options.no_configure:
        cfg.configure()

    if not isfile(pathjoin(options.ocaccel_root, '.ocaccel_config')):
        msg.warn_msg("No configuration files (.ocaccel_config) found, need to do configure first!")
        cfg.configure()

    # In unit sim mode, all configurations are handled automatically, no need to update the cfg
    if not options.unit_sim:
        cfg.update_cfg()

    if not options.no_env_check:
        env_check(options)

    question_and_answer.ask(qa.ask_make_model_str)
    if not options.no_make_model and options.simulator.lower() != "nosim":
        make_model(ocaccel_workflow_make_model_log, options, options.make_timeout)

    question_and_answer.ask(qa.ask_run_sim_str)
    if not options.no_run_sim and options.simulator.lower() != "nosim":
        testcase_cmdline = options.testcase.split(" ")
        testcase_cmd = None
        testcase_args = None
        if len(testcase_cmdline) > 1:
            testcase_cmd = testcase_cmdline[0]
            testcase_args = " ".join(testcase_cmdline[1:])
        elif len(testcase_cmdline) == 1:
            testcase_cmd = testcase_cmdline[0]
            testcase_args = " "
        else:
            testcase_cmd = "terminal"
            testcase_args = " "

        sim = SimSession(simulator_name = options.simulator,\
                         testcase_cmd = testcase_cmd,\
                         testcase_args = testcase_args,\
                         ocse_path = options.ocse_path,\
                         ocaccel_root = options.ocaccel_root,\
                         sim_timeout = options.sim_timeout,\
                         unit_sim = options.unit_sim,\
                         sv_seed = options.sv_seed,\
                         unit_test = options.unit_test,\
                         uvm_ver = options.uvm_ver,\
                         wave = not options.no_wave
                        )
        import atexit
        atexit.register(sim.kill_process)

        sim.run()

    question_and_answer.ask(qa.ask_make_image_str)
    if options.make_image:
        make_image(ocaccel_workflow_make_image_log, options)
