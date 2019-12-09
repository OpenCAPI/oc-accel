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
subdirs += framework

v_srcs=$(wildcard *.v_source)
v_files=$(v_srcs:.v_source=.v)

.PHONY: all config clean vhdl

all: config

config:
	./action_config.sh

clean:
	@$(RM) $(v_files)
	-@$(RM) -rf ../nvdla-capi/outdir
	@for dir in $(subdirs); do	\
		if [ -d $$dir -a -f $$dir/Makefile ]; then	\
			$(MAKE) -C $$dir $@ || exit 1;		\
		fi						\
	done


vhdl:

#
# FIXME Consider moving the functionality from action_config.sh into
#      this Makefile. This also allows to define a proper clean rule
#      such that the directory gets properly cleaned up and git status
#      shows not the generated files.
#
