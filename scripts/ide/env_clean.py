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
from ocaccel_utils import run_and_wait
from ocaccel_utils import msg

def env_clean(log):
    msg.ok_msg_blue("--------> Clean the environment") 
    rc = run_and_wait(cmd = "make clean", work_dir = ".", log = log)
    if rc == 0:
        msg.ok_msg("Environment clean DONE")
    else:
        msg.fail_msg("Error running 'make clean'! Exiting ...")

    rc = run_and_wait(cmd = "make clean_config", work_dir = ".", log = log)
    if rc == 0:
        msg.ok_msg("Configuration clean DONE")
    else:
        msg.fail_msg("Error running 'make clean_config'! Exiting ...")

if __name__ == '__main__':
    env_clean('./snap_workflow.log')

