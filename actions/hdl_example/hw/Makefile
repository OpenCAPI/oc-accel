#
# Copyright 2017, International Business Machines
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

vhd_srcs=$(wildcard *.vhd_source)
vhd_files=$(vhd_srcs:.vhd_source=.vhd)

.PHONY: all config clean vhdl

all: config

config:
	$(info Call action_config.sh (creating action IPs))
	./action_config.sh

clean:
#	$(info Also clean up action ip project...)
	@$(RM) $(ACTION_ROOT)/ip/*.log
	@$(RM) $(ACTION_ROOT)/hw/*.log
	@$(RM) $(ACTION_ROOT)/ip/*.jou
	@$(RM) -fr $(ACTION_ROOT)/ip/action_ip_prj
	@$(RM) -fr $(ACTION_ROOT)/ip/ip_user_files
	@$(RM) $(vhd_files)

vhdl:

#
# FIXME Consider moving the functionality from action_config.sh into
#      this Makefile. This also allows to define a proper clean rule
#      such that the directory gets properly cleaned up and git status
#      shows not the generated files.
#
