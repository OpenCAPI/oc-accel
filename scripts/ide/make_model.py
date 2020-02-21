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
from ocaccel_utils import run_and_poll_with_progress
from ocaccel_utils import run_to_stdout
from ocaccel_utils import msg 

def make_model(log, options, timeout = 2592000):
    msg.ok_msg_blue("--------> Make the simulation model")
    if options.quite:
        rc = run_and_poll_with_progress(cmd = "make -s %s" % options.simulator, work_dir = pathjoin(options.ocaccel_root, 'hardware'), log = log, max_log_len = 150, timeout = timeout)
    else:
        rc = run_to_stdout(cmd = "make -s %s" % options.simulator, work_dir = pathjoin(options.ocaccel_root, 'hardware'))

    if rc == 0:
        msg.ok_msg("OCACCEL simulation model generated")
    else:
        msg.warn_msg("Failed to make simulation model, check log in %s" % log)
        msg.fail_msg("Failed to make simulation model! Exiting ... ")

if __name__ == '__main__':
    make_model("./make_model.log")
