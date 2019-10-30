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
import platform
from os.path import join as pathjoin
from os.path import isdir as isdir
from os.path import isfile as isfile
from ocaccel_utils import which
from ocaccel_utils import SystemCMD
from ocaccel_utils import msg

def env_check(options):
    assert sys.version_info >= (2, 6)

    msg.ok_msg_blue("--------> Environment Check") 
    
    gcc    = SystemCMD("gcc")
    gcc    . check(existence_critical=True, minimum_version = "4.4.6")
    
    if not options.no_make_model or not options.no_run_sim or options.make_image:
        vivado = SystemCMD("vivado")
        xterm  = SystemCMD("xterm")
        vivado . check(existence_critical=True, minimum_version = "2018.2")
        xterm  . check(existence_critical=True)

    if options.simulator.lower() == "xcelium":
        xrun   = SystemCMD("xrun")
        xrun   . check(existence_critical=True)
    elif options.simulator.lower() == "vcs":
        vcs    = SystemCMD("vcs")
        vcs    . check(existence_critical=True)
    elif options.simulator.lower() == "nosim":
        pass
    elif options.simulator.lower() == "xsim":
        # xsim is bundled with vivado, no need to check
        pass
    else:
        msg.fail_msg("%s is an unknown simulator! Exiting ... " % options.simulator)

    if options.no_run_sim == False or options.no_make_model == False:
        if options.simulator.lower() != "nosim" and options.unit_sim != True:
            if isdir(pathjoin(options.ocse_root, "ocse")) and\
               isdir(pathjoin(options.ocse_root, "afu_driver")) and\
               isdir(pathjoin(options.ocse_root, "libocxl")):
                msg.ok_msg_blue("OCSE path %s is valid" % options.ocse_root)
            else:
                msg.fail_msg("OCSE path %s is not valid! Exiting ... " % options.ocse_root)

    if isdir(pathjoin(options.ocaccel_root, "actions")) and\
       isdir(pathjoin(options.ocaccel_root, "hardware")) and\
       isdir(pathjoin(options.ocaccel_root, "software")):
        msg.ok_msg_blue("SNAP ROOT %s is valid" % options.ocaccel_root)
    else:
        msg.fail_msg("SNAP ROOT %s is not valid! Exiting ... " % options.ocaccel_root)

    msg.ok_msg("Environment check PASSED")
