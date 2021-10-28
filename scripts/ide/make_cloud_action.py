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
from ocaccel_utils import msg 

def make_cloud_action(log, options = None):
    msg.ok_msg_blue("--------> Make the CLOUD ACTION FPGA image in Partial Reconfiguration mode")
    msg.warn_msg("Building an image might take quite a long time to finish, be patient ... ")
    rc = run_and_poll_with_progress(cmd = "make cloud_action", work_dir = ".", log = log, max_log_len = 120, timeout = options.make_timeout)

    if rc == 0:
        msg.ok_msg("===========================")
        msg.ok_msg("action FPGA image generated")
        msg.ok_msg("===========================")
        msg.ok_msg("Images are available in %s" % pathjoin(options.ocaccel_root, 'hardware', 'build', 'Images'))
    else:
        msg.warn_msg("Failed to make cloud action image , check log in %s" % log)
        msg.warn_msg("Failed to make cloud action image ! Exiting ... ")
        msg.warn_msg("Here are some of the error logs:")
        f = open(log,"r")
        l = f.readlines()
        f.close()
        print "".join(l[-10:])
        msg.fail_msg("End of the error log!")

if __name__ == '__main__':
    make_cloud_action("./make_cloud_action.log")
