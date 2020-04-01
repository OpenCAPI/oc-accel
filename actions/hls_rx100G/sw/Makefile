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

CXX=g++
#S2OC CPPFLAGS= -I. -I../include -I${SNAP_ROOT}/software/include -I/home/jungfrau/git/pslse/libcxl -I/home/jungfrau/git/pslse/common
CPPFLAGS= -I. -I../include -I${SNAP_ROOT}/software/include -I$(OCSE_ROOT)/libocxl/libocxl -I$(OCSE_ROOT)/common

#S2OC LDFLAGS= -O3 ${SNAP_ROOT}/software/lib/libsnap.a -L/home/jungfrau/git/pslse/libcxl -lm -lcxl -lpthread
LDFLAGS= -O3 ${SNAP_ROOT}/software/lib/libosnap.a -L$(OCSE_ROOT)/libocxl/libocxl -lm -lpthread
# This is solution specific. Check if we can replace this by generics too.

SRCS=snap_rx100G.o

snap_rx100G: $(SRCS)
	$(CXX) $(SRCS) -o snap_rx100G $(JF_LDLIBS) ${LDFLAGS}

snap_rx100G.o: snap_rx100G.cpp

clean:
	rm -f *.o snap_rx100G
 
# If you have the host code outside of the default snap directory structure, 
# change to /path/to/snap/actions/software.mk
# include $(SNAP_ROOT)/actions/software.mk
