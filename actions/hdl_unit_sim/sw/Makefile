#
# Copyright 2017 International Business Machines
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

#
# Generate HDL version of the HLS sources
#
# The generated HDL depends on the chip which is used and
# therefore must match what is being used to build the
# toplevel OCACCEL bitstream.
#
# FIXME Pass part_number and other parameters from toplevel
#      build-system as required.
#

# This is solution specific. Check if we can replace this by generics too.

# Finding $OCACCEL_ROOT
ifndef OCACCEL_ROOT
# check if we are in sw folder of an action (three directories below ocaccel root)
ifneq ("$(wildcard ../../../actions)","")
OCACCEL_ROOT=$(abspath ../../../)
else
$(info You are not building your software from the default directory (/path/to/ocaccel/actions/<action_name>/sw) or specified a wrong $$OCACCEL_ROOT.)
$(error Please make sure that $$OCACCEL_ROOT is set up correctly.)
endif
endif

CPPFLAGS+= -g
CXX=gcc

all: all_build

#config:
#	./action_config.sh

#something_else.o: something_else.cpp
#	$(CXX) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) $< -o $@
#
#hdl_unit_sim_objs += something_else.o
hdl_unit_sim: $(hdl_unit_sim_objs)

projs += hdl_unit_sim

#hdl_unit_sim: hdl_unit_sim.o something_else.o
hdl_unit_sim: hdl_unit_sim.o
	$(CXX) $(LDFLAGS) $($(@)_LDFLAGS) $@.o $($(@)_objs) $($(@)_libs) $(LDLIBS) -o $@

# If you have the host code outside of the default ocaccel directory structure, 
# change to /path/to/ocaccel/actions/software.mk
include $(OCACCEL_ROOT)/actions/software.mk
