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
import re
import os.path
import sys

from os.path import isdir as isdir
from os.path import isfile as isfile
from os.path import join as pathjoin
from os import environ as env
from shutil import copyfile
from ocaccel_utils import source
from ocaccel_utils import run_to_stdout
from ocaccel_utils import run_and_wait
from ocaccel_utils import msg
from ocaccel_utils import sed_file
from ocaccel_utils import search_file_group_1
from ocaccel_utils import append_file
from ocaccel_utils import install

try:
    from kconfiglib import Kconfig, split_expr, expr_value, expr_str, BOOL, \
            TRISTATE, TRI_TO_STR, AND
    from menuconfig import menuconfig
except ImportError:
    install('kconfiglib')

class Configuration:
    def __init__(self, options):
        self.ocaccel_root = options.ocaccel_root
        self.action_root = options.action_root
        self.simulator = options.simulator
        self.options = options
        self.config_file = pathjoin(self.ocaccel_root, 'scripts', 'Kconfig')
        self.user_config = '.config'
        self.kconf = Kconfig(self.config_file)
        self.log = None

    def setup_cfg(self):
        self.kconf.load_config(self.user_config)
        if 'SIMULATOR' in self.kconf.syms:
            self.options.simulator = self.kconf.syms['SIMULATOR'].user_value

        if 'ACTION_NAME' in self.kconf.syms:
            self.options.action_root = pathjoin(self.options.ocaccel_root,
                                                'actions',
                                                self.kconf.syms['ACTION_NAME'].user_value)
            env['ACTION_ROOT'] = self.options.action_root

        self.export_env()

    def export_env(self):
        for sym in self.kconf.unique_defined_syms:
            env[str(sym.name)] = str(sym.user_value)

    def update_cfg(self):
        pass

    def print_cfg(self):
        pass
   
    def make_config(self):
        pass

    def configure(self):
        msg.ok_msg_blue("--------> Configuration") 

        os.environ['MENUCONFIG_STYLE'] = "default selection=fg:white,bg:red"
        menuconfig(self.kconf)
