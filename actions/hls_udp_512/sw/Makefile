#
# Copyright 2020 International Business Machines
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
# toplevel SNAP bitstream.
#
# FIXME Pass part_number and other parameters from toplevel
#      build-system as required.
#

# Finding $SNAP_ROOT
ifndef SNAP_ROOT
# check if we are in sw folder of an action (three directories below snap root)
#S2OC ifneq ("$(wildcard ../../../ActionTypes.md)","")
ifneq ("$(wildcard ../../../actions)","")
SNAP_ROOT=$(abspath ../../../)
else
$(info You are not building your software from the default directory (/path/to/snap/actions/<action_name>/sw) or specified a wrong $$SNAP_ROOT.)
$(error Please make sure that $$SNAP_ROOT is set up correctly.)
endif
endif

#CXX=g++
# This is solution specific. Check if we can replace this by generics too.

#SRCS=oc-accel_udp.o

#oc-accel_udp: $(SRCS)
#	$(CXX) $(SRCS) -o oc-accel_udp $(JF_LDLIBS) ${LDFLAGS}

#oc-accel_udp.o: oc-accel_udp.c

#clean:
#	rm -f *.o oc-accel_udp

#oc-accel_udp_objs = sw_action_udp.o
oc-accel_udp: ${oc-accel_udp_objs}

projs += oc-accel_udp


# If you have the host code outside of the default snap directory structure, 
# change to /path/to/snap/actions/software.mk
include $(SNAP_ROOT)/actions/software.mk
