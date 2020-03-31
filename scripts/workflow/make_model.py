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
from os.path import join as pathjoin
from os.path import isfile as isfile
from ocaccel_utils import run_and_wait
from ocaccel_utils import msg 
from vivado import Vivado

def check_rc(rc, log):
    if rc == 0:
        msg.ok_msg("OCACCEL simulation exported")
    else:
        msg.fail_msg("Failed to make simulation model, check log in %s" % log) 

def make_model(options):
    msg.ok_msg_blue("--------> Make the simulation model")

    flag_file = pathjoin('.', '.make_model')
    if isfile(flag_file):
        os.remove(flag_file)

    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'simulation', 'export_%s.tcl' % options.simulator)
    work_dir = pathjoin(options.ocaccel_build_dir, 'hardware', 'sim')
    sim_dir = pathjoin(work_dir, options.simulator)
    sim_top = 'top_wrapper'

    vivado = Vivado('vivado', options)
    vivado.log = pathjoin(vivado.log_dir, 'make_model.log')
    vivado.work_dir = work_dir
    vivado.args  = ' -quiet -mode batch -notrace'
    vivado.args += ' -source ' + tcl
    vivado.args += ' -log %s' % (vivado.log)
    vivado.args += ' -journal %s/make_model.jou' % vivado.log_dir
    vivado.args += ' -tclargs %s' % sim_top

    # export the simulation model
    vivado.run()

    # patch the sim
    patch_sim_log = pathjoin(vivado.log_dir, 'patch_sim.log')
    patch_script = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'simulation', 'patch_sim.sh')
    commands = '%s %s %s' % (patch_script, sim_dir, sim_top + '.sh')
    rc = run_and_wait(cmd = commands, work_dir = work_dir, log = patch_sim_log)
    check_rc(rc, patch_sim_log)

    # make OCSE
    make_ocse_log = pathjoin(vivado.log_dir, 'make_ocse.log')
    rc = run_and_wait(cmd = 'make', work_dir = options.ocse_path, log = make_ocse_log)
    check_rc(rc, make_ocse_log)

    # setup the link to libdpi.so
    os.symlink(pathjoin(options.ocse_path, 'afu_driver', 'src', 'libdpi.so'), pathjoin(sim_dir, 'libdpi.so'))

    # compile the simulation model
    compile_sim_log = pathjoin(vivado.log_dir, 'compile_%s.log' % options.simulator)
    commands = pathjoin(sim_dir, '%s.sh' % sim_top)
    rc = run_and_wait(cmd = commands, work_dir = sim_dir, log = compile_sim_log)
    check_rc(rc, compile_sim_log)

    open(flag_file, 'w')
