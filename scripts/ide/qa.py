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

# Authors: Gou Peng Fei
# Date:
#

import os
import sys
from ocaccel_utils import msg

choice_str = "Yes(Y/y) No(N/n): "
ask_clean_str = "Do you want to clean the environment before start?"
ask_configure_str = "Do you want to configure the environment?"
ask_make_model_str = "Do you want to make simulation model?"
ask_run_sim_str = "Do you want to run simulation?"
ask_testcase_str = '''What is the testcase you'd like to run?
Hints:
You can:    1) type 'terminal' to have a pop up window and
               you can manually input any testcase in that window.
or you can: 2) type any kind of command line you would like to run as testcase.
               for example, 'snap_example -vv -a 6'
Please type the testcase: 
'''
ask_make_image_str = "Do you want to make FPGA image?"
class QuestionAndAnswer():
    def __init__(self, options):
        self.options = options
        self.qa_table = {
                ask_clean_str      : self.ask_clean,
                ask_configure_str  : self.ask_configure,
                ask_make_model_str : self.ask_make_model,
                ask_run_sim_str    : self.ask_run_sim,
                ask_make_image_str : self.ask_make_image
            }

    def ask(self, question):
        if not self.options.interactive:
            return self.options
        else:
            if not self.qa_table.has_key(question):
                msg.warn_msg("I don't understand your question: '%s', do nothing" % question)
                return self.options

            return self.qa_table[question](question)

    def ask_clean(self, question):
        a = raw_input(" ".join((question,\
                         choice_str)))
        if a.upper() == "Y":
            msg.header_msg("Got Yes! Proceed to clean the environment.")
            self.options.clean = True
            return self.options
        else:
            msg.header_msg("Got No! Skip cleanning the environment.")
            self.options.clean = False
            return self.options

    def ask_configure(self, question):
        a = raw_input(" ".join((question,\
                         choice_str)))
        if a.upper() == "Y":
            if hasattr(self, "cfg"):
                if self.cfg.cfg_existence():
                    msg.header_msg("Configuration existed as below:")
                    self.cfg.print_cfg()
                    a = raw_input(" ".join(("Do you really want to configure again?",\
                                     choice_str)))

            if a.upper() == "Y":
                msg.header_msg("Got Yes! Proceed to configure SNAP.")
                self.options.no_configure = False
                return self.options

        msg.header_msg("Got No! Skip configuring SNAP.")
        self.options.no_configure = True
        return self.options

    def ask_make_model(self, question):
        a = raw_input(" ".join((question,\
                         choice_str)))
        if a.upper() == "Y":
            msg.header_msg("Got Yes! Proceed to make simulation model.")
            self.options.no_make_model = False
            return self.options
        else:
            msg.header_msg("Got No! Skip making simulation model.")
            self.options.no_make_model = True
            return self.options

    def ask_run_sim(self, question):
        if self.options.simulator == "nosim":
            msg.warn_msg("Simulator is chosen as NOSIM, skip running simulation!")
            self.options.no_run_sim = True
            return self.options

        a = raw_input(" ".join((question,\
                         choice_str)))
        if a.upper() == "Y":
            msg.header_msg("Got Yes! Proceed to run simulation.")
            self.options.no_run_sim = False

            a = raw_input(ask_testcase_str)
            if a == "":
                a = "terminal"

            self.options.testcase = a
            msg.header_msg("The testcase to run: %s" % a)
            return self.options
        else:
            msg.header_msg("Got No! Skip running simulation.")
            self.options.no_run_sim = True
            return self.options

    def ask_make_image(self, question):
        a = raw_input(" ".join((question,\
                         choice_str)))
        if a.upper() == "Y":
            msg.header_msg("Got Yes! Proceed to make FPGA image.")
            self.options.make_image = True
            return self.options
        else:
            msg.header_msg("Got No! Skip making FPGA image.")
            self.options.make_image = False
            return self.options


