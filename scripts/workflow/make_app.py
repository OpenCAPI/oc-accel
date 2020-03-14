#!/usr/bin/env python
#
# Copyright 2020 International Business Machines
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
import platform
from os.path import isfile as isfile
from os.path import join as pathjoin
from ocaccel_utils import run_to_stdout
from ocaccel_utils import msg 

def make_app(cmd, options):
    action_sw_path = pathjoin(options.ocaccel_root, 'actions', cmd, 'sw')

    if not isfile(pathjoin(action_sw_path, 'Makefile')):
        msg.fail_msg("No Makefile availabe in %s, not able to compile the application!" % action_sw_path)

    msg.ok_msg("--------> Make application software in %s" % action_sw_path)

    machine = platform.machine()
    if machine == "ppc64le":
        msg.header_msg("Running on ppc64le, the application compiled can be run together with the deployed FPGA card!")
    elif machine == "x86_64":
        msg.header_msg("Running on x86_64, the application compiled can only be run in a simulation session.")
        msg.header_msg("    To start a simulation session, try the following steps:")
        msg.header_msg("    ./run.py config")
        msg.header_msg("    ./run.py model")
        msg.header_msg("    ./run.py sim")
        msg.header_msg("------------------------------------------------------------")
    else:
        msg.warn_msg("Unsupported machine type %s" % machine)
        msg.warn_msg("The supported machine types are:")
        msg.warn_msg("    ppc64le - for deployment")
        msg.warn_msg("    x86_64  - for simulation and bitstream generation")
        msg.fail_msg("Not able to proceed")
 
    rc = run_to_stdout(cmd = "make", work_dir = action_sw_path)

    if rc == 0:
        msg.ok_msg("==============================")
        msg.ok_msg("Application generated")
        msg.ok_msg("=============================")
        msg.ok_msg("apps are available in %s" % action_sw_path)
    else:
        msg.fail_msg("Failed to make application software")

if __name__ == '__main__':
    make_app("./make_app.log")
