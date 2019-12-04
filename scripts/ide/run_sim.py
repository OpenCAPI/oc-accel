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

import sys
import os
import pprint
import subprocess
import time
import random
import glob
import re
from time import sleep
from shutil import copy as copyfile
from os.path import join as pathjoin
from os.path import isdir as isdir
from os.path import isfile as isfile
from os.path import islink as islink
from os import environ as env

from optparse import OptionParser
from ocaccel_utils import source
from ocaccel_utils import mkdirs
from ocaccel_utils import run_in_background
from ocaccel_utils import run_and_wait
from ocaccel_utils import run_and_poll
from ocaccel_utils import grep_file
from ocaccel_utils import search_file_group_1
from ocaccel_utils import progress_bar
from ocaccel_utils import kill_pid
from ocaccel_utils import msg 

class SimSession:
    def __init__(self, simulator_name = 'xsim', testcase_cmd = 'snap_example', testcase_args = "",\
                 ocse_root = os.path.abspath('../ocse'), ocaccel_root = os.path.abspath('.'),\
                 sim_timeout = 600, unit_sim = False, sv_seed = '1', unit_test = '', uvm_ver = '', wave = True):
        # prepare the environment
        self.simulator_name = simulator_name
        self.testcase_cmd = testcase_cmd
        self.ocse_root = ocse_root
        self.ocaccel_root = ocaccel_root
        self.sim_timeout = sim_timeout
        self.unit_sim = unit_sim
        self.sv_seed = sv_seed
        self.unit_test = unit_test
        self.uvm_ver = uvm_ver
        self.wave = wave

        self.setup_env()
        self.check_root_path()
        self.setup_ld_libraries()

        self.simulator = Simulator(simulator_name, self.ocaccel_root, self.sim_timeout, self.unit_sim, self.sv_seed, self.unit_test, self.uvm_ver, self.wave)
        # No OCSE if in unit sim mode
        if self.unit_sim == False:
            self.ocse = OCSE(ocse_root, self.simulator.simout, self.sim_timeout)
        self.testcase = Testcase(testcase_cmd, self.simulator.simout, testcase_args)

    def run(self):
        msg.ok_msg_blue("--------> Simulation Session")
        self.print_env()
        self.simulator.run()
        if self.unit_sim == False:
            self.ocse.run()
            self.testcase.run()

    def kill_process(self):
        if self.unit_sim == False:
            self.ocse.kill()
        # Simulator will be automatically terminated if OCSE is killed

    def check_root_path(self):
        if not isdir(self.ocaccel_root):
            msg.warn_msg("SNAP_ROOT path: %s is not valid!" % self.ocaccel_root)
            msg.fail_msg("SNAP_ROOT is not valid! Exiting ...")

        if not isdir(self.action_root):
            msg.warn_msg("ACTION_ROOT path: %s is not valid!" % self.action_root)
            msg.fail_msg("ACTION_ROOT is not valid! Exiting ...")

    def setup_env(self):
        if 'SNAP_ROOT' not in env:
            env['SNAP_ROOT'] = self.ocaccel_root

        self.ocaccel_root = env['SNAP_ROOT']

        source(pathjoin(env['SNAP_ROOT'], '.snap_config.sh'))
        source(pathjoin(env['SNAP_ROOT'], 'snap_env.sh'))

        self.action_root = env['ACTION_ROOT']

        env['PATH'] = ":".join((env['PATH'],\
                pathjoin(env['SNAP_ROOT'], 'software', 'tools'),\
                pathjoin(env['ACTION_ROOT'], 'sw')))

        if self.unit_sim == False:
            if not isdir(self.ocse_root):
                print self.ocse_root + " not exist!"
                exit("OCSE ROOT is not valid! Exiting ...")

    def setup_ld_libraries(self):
        if 'LD_LIBRARY_PATH' not in env:
            env['LD_LIBRARY_PATH'] = ''

        if self.unit_sim == False:
            env['LD_LIBRARY_PATH'] = \
                    ":".join((env['LD_LIBRARY_PATH'],\
                              pathjoin(self.ocse_root, 'afu_driver', 'src'),\
                              pathjoin(self.ocse_root, 'libocxl'),\
                              pathjoin(self.ocaccel_root, 'software', 'lib')))
    def print_env(self):
        msg.header_msg("SNAP ROOT\t %s" % self.ocaccel_root)
        msg.header_msg("ACTION ROOT\t %s" % self.action_root)
        self.simulator.print_env()
        if self.unit_sim == False:
            self.ocse.print_env()
            self.testcase.print_env()
        else:
            msg.header_msg("Unit test name\t %s" % self.unit_test)
            msg.header_msg("Unit test seed\t %s" % self.sv_seed)
 
class Simulator:
    def __init__(self, simulator = 'xsim', ocaccel_root = '.', sim_timeout = 60, unit_sim = False, sv_seed = '1', unit_test = '', uvm_ver = '', wave = True):
        self.simulator = simulator
        self.timeout = sim_timeout
        self.ocaccel_root = ocaccel_root
        self.unit_sim = unit_sim
        self.sv_seed = sv_seed
        self.unit_test = unit_test
        self.uvm_ver = uvm_ver        
        self.wave = wave
        self.simout = None
        self.simulator_pid = None
        self.setup()

    def run(self):
        self.run_simulator()
        if self.unit_sim == False:
            self.get_host_shim()

    def check_simout(self):
        if not isdir(self.simout):
            msg.warn_msg("SIMOUT path: %s is not valid!" % self.simout)
            msg.fail_msg("SIMOUT is not valid! Exiting ...")

    def setup_simout(self):
        timestamp = str(int(round(time.time() * 1000)))
        seed = str(random.randint(0, 0xffffffff))
        self.simout = pathjoin(self.ocaccel_root,\
                               "hardware", "sim", self.simulator,\
                               timestamp + "." + seed)
        if self.unit_sim == True:
            self.simout = ".".join((self.simout, self.unit_test))

        mkdirs(self.simout)
        self.check_simout()

        msg.header_msg("Simulation run dir: %s" % self.simout)

        # In unit sim mode, simulation jobs might be submitted via LSF to run in parallel,
        # don't create the symbol link `latest` to avoid conflict.
        if self.unit_sim == False:
            latest = pathjoin(self.ocaccel_root,\
                                   "hardware", "sim", self.simulator,\
                                   "latest")
            if islink(latest):
                os.unlink(latest)

            os.symlink(self.simout, latest)

        # Generate a flag in simout for simulation status
        open(pathjoin(self.simout, '.RUNNING'), 'a').close()

    def prepare_sim_files(self):
        self.check_simout()
        tcl_pattern = "xs*.tcl"

        if self.simulator == "xcelium":
            tcl_pattern = "nc*.tcl"

        tcl_sources = glob.glob(pathjoin(self.ocaccel_root,\
                                         "hardware", "sim", tcl_pattern))
        for file in tcl_sources:
            copyfile(file, self.simout)

        if self.simulator == "xcelium":
            os.symlink(pathjoin(self.ocaccel_root, "hardware", "sim",\
                                self.simulator, "xcelium"),\
                       pathjoin(self.simout, "xcelium"))
            os.symlink(pathjoin(self.ocaccel_root, "hardware", "sim",\
                                self.simulator, "xcelium.d"),\
                       pathjoin(self.simout, "xcelium.d"))
            os.symlink(pathjoin(self.ocaccel_root, "hardware", "sim",\
                                self.simulator, "xcelium_lib"),\
                       pathjoin(self.simout, "xcelium_lib"))
            os.symlink(pathjoin(self.ocaccel_root, "hardware", "sim",\
                                "nvme"),\
                       pathjoin(self.simout, "nvme"))
        elif self.simulator == "xsim":
            os.symlink(pathjoin(self.ocaccel_root, "hardware", "sim",\
                                self.simulator, "xsim.dir"),\
                       pathjoin(self.simout, "xsim.dir"))

    def setup(self):
        msg.header_msg("Setup simulation for %s " % self.simulator)
        self.setup_simout()
        self.prepare_sim_files()

    def print_env(self):
        msg.header_msg("SIMULATOR\t %s" % self.simulator)
        msg.header_msg("SIMOUT PATH\t %s" % self.simout)

    def check_unit_sim_result(self, sim_log):
        uvm_error = search_file_group_1(sim_log, "UVM_ERROR\s*:\s*(\d*)")
        uvm_fatal = search_file_group_1(sim_log, "UVM_FATAL\s*:\s*(\d*)")

        if uvm_error is None or uvm_fatal is None:
            msg.warn_msg("No UVM_ERROR or UVM_FATAL line found!")
            return False

        msg.warn_msg("--------> UVM_ERROR : %s" % uvm_error)
        msg.warn_msg("--------> UVM_FATAL : %s" % uvm_fatal)

        if uvm_error != '0' or uvm_fatal != '0':
            return False

        return True
        
    def run_simulator(self):
        if self.simulator == "xcelium":
            sim_cmd  = "xrun"
            sim_init = "-xminitialize x"
            sim_args = "-batch +model_data+. -64bit"
            if self.wave:
                sim_args += " -input ncaet.tcl"
            sim_args += " -input ncrun.tcl -r"
            unit_args = "".join(("+UVM_TESTNAME=", self.unit_test, " -seed ", self.sv_seed, " +UVM_VERBOSITY=", self.uvm_ver, " -coverage a -covfile ", self.ocaccel_root, "/hardware/setup/cov.ccf", " -covoverwrite -covtest ", self.unit_test))
            if self.unit_sim == False:
                sim_top  = "work.top"
            else:
                sim_top  = "work.unit_top"
            self.sim_log  = pathjoin(self.simout, "sim.log")

            if self.unit_sim == False:
                self.simulator_pid =\
                        run_in_background(cmd = " ".join((sim_cmd, sim_init, sim_args, sim_top)),\
                          work_dir = self.simout,\
                          log = self.sim_log)
                if int(self.simulator_pid) > 0:
                    msg.header_msg("Simulator running on process ID %s" % self.simulator_pid)
                else:
                    msg.fail_msg("Failed to run simulator! Exiting ... ")
            else:
                try:
                    rc = run_and_poll(cmd = " ".join((sim_cmd, sim_init, sim_args, sim_top, unit_args)),\
                                      work_dir = self.simout,\
                                      log = self.sim_log)
                    unit_sim_passed = self.check_unit_sim_result(self.sim_log)

                    os.remove(pathjoin(self.simout, '.RUNNING'))
                    if not unit_sim_passed:
                        msg.warn_msg("============")
                        msg.warn_msg("Test FAILED!")
                        msg.warn_msg("============")
                        # Generate a flag in simout for simulation status
                        open(pathjoin(self.simout, '.FAILED'), 'a').close()
                        msg.fail_msg("UVM check failed, please check log in %s" % (self.sim_log))
                    else:
                        msg.ok_msg("============")
                        msg.ok_msg("Test PASSED!")
                        msg.ok_msg("============")
                        # Generate a flag in simout for simulation status
                        open(pathjoin(self.simout, '.PASSED'), 'a').close()
                        msg.ok_msg("UVM check passed, please check log in %s" % (self.sim_log))
                except:
                    if isfile(pathjoin(self.simout, '.RUNNING')):
                        os.remove(pathjoin(self.simout, '.RUNNING'))
                    open(pathjoin(self.simout, '.FAILED'), 'a').close()
                    msg.fail_msg("An error occured, please check log in %s" % (self.sim_log))

        elif self.simulator == "xsim":
            sim_cmd  = "xsim"
            sim_init = ""

            sim_args = ""
            if self.wave:
                sim_args += "-t xsaet.tcl" 
            sim_args += " -t xsrun.tcl"
            sim_top  = "top"
            self.sim_log  = pathjoin(self.simout, "sim.log")

            self.simulator_pid =\
                    run_in_background(cmd = " ".join((sim_cmd, sim_init, sim_args, sim_top)),\
                      work_dir = self.simout,\
                      log = self.sim_log)
            if int(self.simulator_pid) > 0:
                msg.header_msg("Simulator running on process ID %s" % self.simulator_pid)
            else:
                msg.fail_msg("Failed to run simulator! Exiting ... ")
        else:
            msg.fail_msg("%s is not supported" % self.simulator)

    def get_host_shim(self):
        sim_host_shim = pathjoin(self.simout, "shim_host.dat")
        sim_host_shim_line = None
        msg.header_msg("Waiting for simulator running!")
        progress_bar_size = 30
        for i in range(self.timeout):
            sleep(1)
            progress_bar(i, self.timeout, progress_bar_size)
            sim_host_shim_line = grep_file(self.sim_log, "waiting for connection")
            if sim_host_shim_line is not None:
                break

        if sim_host_shim_line is None:
            msg.fail_msg("Timeout waiting for simulator to startup! Exiting ...")

        progress_bar(self.timeout - 1, self.timeout, progress_bar_size, True)
        host_shim = re.search("waiting for connection on (.*$)", sim_host_shim_line).group(1)
        with open(sim_host_shim, 'w+') as outfile:
            outfile.write("tlx0," + host_shim)
        msg.header_msg(" Simulator running successfully on socket: %s" % host_shim)

class OCSE:
    def __init__(self, ocse_root = os.path.abspath('../ocse'), simout = '.', timeout = 300):
        self.ocse_root = ocse_root
        self.simout = simout
        self.timeout = timeout
        self.ocse_pid = None
        self.setup()

    def print_env(self):
        msg.header_msg("OCSE_ROOT\t %s" % self.ocse_root)

    def run(self):
        self.run_ocse()
        self.get_ocse_server_dat()
        
    def prepare_ocse_parms(self):
        copyfile(pathjoin(self.ocse_root, "ocse", "ocse.parms"),\
                 pathjoin(self.simout))

    def setup(self):
        self.prepare_ocse_parms()

    def kill(self):
        if self.ocse_pid is None:
            return
        pid = int(self.ocse_pid)
        msg.warn_msg("Killing OCSE pid %d" % pid)
        kill_pid(pid)

    def run_ocse(self):
        self.ocse_log = pathjoin(self.simout, "ocse.log")
        ocse_cmd = pathjoin(self.ocse_root, "ocse", "ocse")

        self.ocse_pid =\
                run_in_background(cmd = ocse_cmd, work_dir = self.simout, log = self.ocse_log)
        if int(self.ocse_pid) > 0:
            msg.header_msg("OCSE running with pid %s" % self.ocse_pid)
        else:
            msg.fail_msg("Failed to run OCSE! Exiting ... ")

    def get_ocse_server_dat(self):
        ocse_server_dat_file = pathjoin(self.simout, "ocse_server.dat")
        ocse_server_dat_line = None
        progress_bar_size = 30
        for i in range(self.timeout):
            sleep(1)
            progress_bar(i, self.timeout, progress_bar_size)
            ocse_server_dat_line = grep_file(self.ocse_log, "listening on")
            if ocse_server_dat_line is not None:
                break

        if ocse_server_dat_line is None:
            msg.fail_msg("Timeout waiting for OCSE to startup! Exiting ...")

        progress_bar(self.timeout - 1, self.timeout, progress_bar_size, True)
        ocse_server_dat = re.search("listening on (.*$)", ocse_server_dat_line).group(1)
        with open(ocse_server_dat_file, 'w+') as outfile:
            outfile.write(ocse_server_dat)
        msg.header_msg(" OCSE listening on socket: %s" % ocse_server_dat)

class Testcase:
    def __init__(self, cmd = 'snap_example', simout = '.', args = ""):
        self.cmd = cmd
        self.args = args
        self.simout = simout

    def print_env(self):
        msg.header_msg("Testcase cmd:\t %s" % self.cmd)
        msg.header_msg("Testcase args:\t %s" % self.args)

    def run(self):
        msg.ok_msg_blue("--------> Running testcase %s" % self.cmd)
        self.test_log = pathjoin(self.simout, self.cmd + ".log")
        rc = None 
        if self.cmd == "terminal":
            cmd = "xterm -title \"testcase window, look at log in \"" + self.test_log
            rc = run_and_wait(cmd = cmd, work_dir = self.simout, log = self.test_log)
        else:
            cmd = " ".join((self.cmd, self.args))
            rc = run_and_poll(cmd = cmd, work_dir = self.simout, log = self.test_log)

        if rc != 0:
            msg.warn_msg("============")
            msg.warn_msg("Test FAILED!")
            msg.warn_msg("============")
            msg.fail_msg("Testcase returned %d, please check log in %s" % (rc, self.test_log))
        else:
            if self.cmd == "terminal":
                msg.ok_msg("================================================")
                msg.ok_msg("An xterm (terminal) is chosen to run, ")
                msg.ok_msg("please refer to the results of commands")
                msg.ok_msg("you've ran in the terminal for testcase status.")
                msg.ok_msg(" To display traces, execute: ./display_traces")
                msg.ok_msg("================================================")
            else:
                msg.ok_msg("============")
                msg.ok_msg("Test PASSED!")
                msg.ok_msg("============")
                msg.ok_msg("Testcase returned %d, please check log in %s" % (rc, self.test_log))

if __name__ == '__main__':
    usage = '''%prog <options>
    Run simulator with a specified application (testcase).'''
    parser = OptionParser(usage=usage)
    parser.add_option("-s", "--simulator",
                      dest="simulator", default='xsim',
                      help="The simulator for this simulation, default %default")
    parser.add_option("-t", "--testcase",
                      dest="testcase", default='snap_example',
                      help="The testcase for this simulation, default %default")
    parser.add_option("-r", "--testcase_args",
                      dest="testcase_args", default=' ',
                      help="The testcase arguments for this simulation, default %default")
    parser.add_option("-o", "--ocse", dest="ocse", default="../ocse",
                      help="Path to OCSE root", metavar="FILE")
    
    (options, args) = parser.parse_args()

    sim = SimSession(options.simulator, options.testcase, options.testcase_args, options.ocse)
    sim.run()
    sim.kill_process()
