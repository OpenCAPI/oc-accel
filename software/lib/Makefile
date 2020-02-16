#
# Copyright 2016, 2017 International Business Machines
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

ifndef OCACCEL_ROOT
ifneq ("$(wildcard ../../actions)","")
OCACCEL_ROOT=$(abspath ../../)
else
$(info You probably have defined a wrong $$OCACCEL_ROOT.)
$(error Please make sure that $$OCACCEL_ROOT is set up correctly.)
endif
endif

include ../config.mk

libversion = $(VERSION)
CAPI_VER = opencapi30

CFLAGS += -fPIC -fno-strict-aliasing
CXXFLAGS += -fPIC -D_GNU_SOURCE 

ifeq ($(CAPI_VER),opencapi30)
LDLIBS += -locxl -lpthread
else
LDLIBS += -lcxl -lpthread
endif

ifdef BUILD_SIMCODE
CFLAGS += -D_SIM_
LDFLAGS += -L$(OCSE_PATH)/libocxl -Wl,-rpath,$(OCSE_PATH)/libocxl
LIBS += $(OCSE_PATH)/libocxl/libocxl.so
endif

libnameA = libocaccel
projA = $(libnameA).a \
	$(libnameA).so \
	$(libnameA).so.$(MAJOR_VERSION) \
	$(libnameA).so.$(libversion)

srcA = ocaccel.c
srcCPP = ocaccel_job_manager.cpp

objsA = $(srcA:.c=.o)
objsA += $(srcCPP:.cpp=.o)

projs += $(projA)

all: $(projs)

ifdef BUILD_SIMCODE
$(projs): $(OCSE_PATH)/libocxl/libocxl.so

$(OCSE_PATH)/libocxl/libocxl.so:
	$(MAKE) -C `dirname $@`
endif

### libA
__$(libnameA).o: $(objsA)
	$(LD) $(XLDFLAGS) -r -o $@ $^

$(libnameA).a: __$(libnameA).o
	$(AR) rcs $@ $^

$(libnameA).so:  $(libnameA).so.$(libversion)
	ln -sf $< $@

$(libnameA).so.$(MAJOR_VERSION): $(libnameA).so.$(libversion)
	ln -sf $< $@
# SONAMEA=-Wl,-soname,$(libnameA).so.$(MAJOR_VERSION)

$(libnameA).so.$(libversion): __$(libnameA).o
	$(CC) $(LDFLAGS) -shared  $(SONAMEA) \
		 -o $@ $^ $(libsA) $(LDLIBS)

install: all
	mkdir -p $(LIB_INSTALL_PATH)
	cp -auv $(projA) $(LIB_INSTALL_PATH)

# general things
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@
	$(CC) -MM $(CFLAGS) $< > $*.d

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $($(@:.o=)_CPPFLAGS) $< -MD -MT $@ -MF $(@:%o=%d) -o $@

clean distclean:
	$(RM) *.o *.d $(projs) *.so *.so.* *~

-include $(objsA:.o=.d) $(objsB:.o=.d)
