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
from os.path import isdir as isdir
from ocaccel_utils import run_and_wait
from ocaccel_utils import msg 
from ocaccel_utils import SystemCMD
from os import environ as env

class Vivado(SystemCMD):
    def __init__(self, exe, options = None):
        super(Vivado, self).__init__(exe)
        self.args = ''

        self.log_dir  = pathjoin(options.ocaccel_build_dir, 'hardware', 'logs')
        self.work_dir = pathjoin(options.ocaccel_build_dir, 'hardware', 'output')

        self.log = pathjoin(self.log_dir, 'default.log')

    def run(self):
        try: 
            os.makedirs(self.work_dir)
        except OSError:
            if not isdir(self.work_dir):
                raise
        try: 
            os.makedirs(self.log_dir)
        except OSError:
            if not isdir(self.log_dir):
                raise

        commands = ' '.join([self.cmd, self.args])
        msg.ok_msg_blue("--------> Running Vivado")
        msg.ok_msg_blue("--------> Work directory: %s" % self.work_dir)
        msg.ok_msg_blue("--------> Command: %s" % commands)
        rc = run_and_wait(cmd = commands, work_dir = self.work_dir, log = self.log)

        if rc == 0:
            msg.ok_msg("=========================")
            msg.ok_msg("Vivado runs successfully!")
            msg.ok_msg("=========================")
        else:
            msg.warn_msg("====================")
            msg.warn_msg("Vivado runs failed!")
            msg.warn_msg("====================")
            msg.fail_msg("ERROR LOG: %s" % self.log)

def run_vivado(name, tcl, options):
    flag_file = pathjoin('.', '.' + name)
    if isfile(flag_file):
        os.remove(flag_file)

    vivado = Vivado('vivado', options)
    vivado.log = pathjoin(vivado.log_dir, '%s.log' % name)

    vivado.args  = ' -quiet -mode batch -notrace'
    vivado.args += ' -source ' + tcl
    vivado.args += ' -log %s' % (vivado.log)
    vivado.args += ' -journal %s/%s.jou' % (vivado.log_dir, name)

    vivado.run()
    open(flag_file, 'w')

def run_vivado_hls(name, tcl, options):
    flag_file = pathjoin('.', '.' + name)
    if isfile(flag_file):
        os.remove(flag_file)

    vivado_hls = Vivado('vivado_hls', options)
    vivado_hls.work_dir = pathjoin(options.ocaccel_build_dir, 'hardware', 'output', 'hls')
    vivado_hls.log      = pathjoin(vivado_hls.log_dir, '%s.log' % name)

    vivado_hls.args = ' -f ' + tcl

    vivado_hls.run()
    open(flag_file, 'w')

def define_interfaces(options):
    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'common', 'define_interfaces.tcl')
    run_vivado('define_interfaces', tcl, options)

def package_hostside(options):
    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'package_hostside', 'package_hostside_ips.tcl')
    run_vivado('package_hostside', tcl, options)

def package_infrastructure(options):
    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'package_infrastructure', 'package_infrastructure_ips.tcl')
    run_vivado('package_infrastructure', tcl, options)

def package_kernel_helper(options):
    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'package_action', 'helper', 'package_kernel_helper.tcl')
    run_vivado('package_kernel_helper', tcl, options)

def action_hw(options):
    if 'KERNELS' in env:
        kernels = env['KERNELS']
    else:
        msg.fail_msg("KERNELS is not set in environment variable!!")

    for k in sorted(set(kernels.split(',')), key = str):
        msg.force_msg("Processing %s" % k)
        tcl = pathjoin(options.action_root, 'hw', 'hls', 'run_%s_script.tcl' % k)
        run_vivado_hls('action_hw', tcl, options)

def top_project(options):
    if 'INFRA_TEMPLATE_SELECTION' in env:
        infra_template = env['INFRA_TEMPLATE_SELECTION']
    else:
        msg.fail_msg("INFRA_TEMPLATE_SELECTION is not set in environment variable!!")

    tcl = pathjoin(options.ocaccel_root, 'hardware', 'setup', 'create_framework', 'create_top_%s.tcl' % infra_template)
    run_vivado('top_project', tcl, options)

make_hw_project = {
    'define_interfaces'      : define_interfaces,
    'package_hostside'       : package_hostside,
    'package_infrastructure' : package_infrastructure,
    'package_kernel_helper'  : package_kernel_helper,
    'action_hw'              : action_hw,
    'top_project'            : top_project
}
