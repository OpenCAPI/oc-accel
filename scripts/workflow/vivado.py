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
from ocaccel_utils import SystemCMD
from os import environ as env

class Vivado(SystemCMD):
    def __init__(self, args = '-h'):
        super(Vivado, self).__init__('vivado')
        self.args = args

        if 'OCACCEL_HARDWARE_ROOT' not in env:
            msg.fail_msg("OCACCEL_HARDWARE_ROOT is not set in env variables!")
    
        if 'OCACCEL_HARDWARE_BUILD_DIR' not in env:
            msg.fail_msg("OCACCEL_HARDWARE_BUILD_DIR is not set in env variables!")

        self.log_dir  = pathjoin(env['OCACCEL_HARDWARE_BUILD_DIR'], 'logs')
        self.work_dir = pathjoin(env['OCACCEL_HARDWARE_BUILD_DIR'])
        self.tcl_root = pathjoin(env['OCACCEL_HARDWARE_ROOT'], 'setup')

    def run(self):
        commands = ' '.join([self.cmd, self.args])
        msg.ok_msg_blue("--------> Running Vivado")
        msg.ok_msg_blue("--------> Work directory: %s" % self.work_dir)
        msg.ok_msg_blue("--------> Command: %s" % commands)
        rc = run_and_wait(cmd = commands, work_dir = self.work_dir, log = '/dev/null')

        if rc == 0:
            msg.ok_msg("=========================")
            msg.ok_msg("Vivado runs successfully!")
            msg.ok_msg("=========================")
        else:
            msg.warn_msg("====================")
            msg.warn_msg("Vivado runs failed!")
            msg.fail_msg("====================")

def run_vivado(name, tcl):
    flag_file = pathjoin('.', '.' + name)
    if isfile(flag_file):
        os.remove(flag_file)

    vivado = Vivado()

    vivado.args  = ' -quiet -mode batch -notrace'
    vivado.args += ' -source ' + pathjoin(vivado.tcl_root, tcl)
    vivado.args += ' -log %s/%s.log' % (vivado.log_dir, name)
    vivado.args += ' -journal %s/%s.jou' % (vivado.log_dir, name)

    vivado.run()
    open(flag_file, 'w')

def define_interfaces(config):
    run_vivado('define_interfaces', 'common/define_interfaces.tcl')

def package_hostside(config):
    run_vivado('package_hostside', 'package_hostside/package_hostside_ips.tcl')

def package_infrastructure(config):
    run_vivado('package_infrastructure', 'package_infrastructure/package_infrastructure_ips.tcl')

def top_project(config):
    run_vivado('top_project', 'create_framework/create_top_%s.tcl' % infra_template)

make_hw_project = {
    'define_interfaces'      : define_interfaces,
    'package_hostside'       : package_hostside,
    'package_infrastructure' : package_infrastructure,
    'top_project'            : top_project
}

