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

# This is solution specific. Check if we can replace this by generics too.

# Finding $SNAP_ROOT
ifndef SNAP_ROOT
# check if we are in sw folder of an action (three directories below snap root)
ifneq ("$(wildcard ../../../../actions)","")
SNAP_ROOT=$(abspath ../../../../)
else
$(info You are not building your software from the default directory (/path/to/snap/actions/<action_name>/sw) or specified a wrong $$SNAP_ROOT.)
$(error Please make sure that $$SNAP_ROOT is set up correctly.)
endif
endif

#CPPFLAGS+= -g
#include $(SNAP_ROOT)/snap_env.sh

CXX=g++

UTILS                     = ../../string-match-fpga/utils

INCLUDES                  = -I. -I./ -I../
#INCLUDES                 += -I$(UTILS) 
INCLUDES                 += -I$(SNAP_ROOT)/software/include
#INCLUDES                 += -I$(POSTGRESQL_INCLUDE_SERVER) -I$(POSTGRESQL_INCLUDE)/internal

EXTRA_CFLGAS             += -Wall -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv
EXTRA_CFLGAS             += -Wno-error -Wno-unused-parameter -Wno-sign-compare
EXTRA_CFLGAS             += -Wno-return-local-addr

CPPFLAGS                 += -O3 $(EXTRA_CFLGAS) $(INCLUDES) -fPIC -D_GNU_SOURCE 
LDFLAGS                  += $(EXTRA_CFLGAS) -fPIC -Wl,--as-needed -Wl,-rpath,--enable-new-dtags
LDLIBS                   += -locxl -lpthread -losnap -lboost_thread -lboost_system -lboost_chrono

BUILDDIR = ./obj
TOBUILDDIR = $(addprefix $(BUILDDIR)/,$(1))
MKDIR = if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi

MT_CPPSRCS := $(shell find ./mt -name "*.cpp")
MT_CPPOBJS := $(call TOBUILDDIR,$(patsubst %.cpp,%.o,$(MT_CPPSRCS)))
MT_CPPFLAGS := --std=c++11
MT_INCLUDES := -I. -I../ -I./mt -I./mt/base -I./mt/utils -I$(SNAP_ROOT)/software/include
MT_INCLUDES += -I./mt/dirtest -I./mt/interface
MT_COMPILEFLAGS := -W -Wall -Wno-multichar -Wno-unused-parameter -Wno-unused-function
MT_OPTFLAGS := -O3
CPPFLAGS += $(MT_INCLUDES)

#DBDIRECT_CSRCS := db_direct.c
DBDIRECT_CSRCS := one_thread_direct.c
DBDIRECT_COBJS := $(call TOBUILDDIR,$(patsubst %.c,%.o,$(DBDIRECT_CSRCS)))

UTILS_CPPLINKS := fregex.cpp regex_config.cpp
UTILS_CPPOBJS := $(call TOBUILDDIR,$(patsubst %.cpp,%.o,$(UTILS_CPPLINKS)))

UTILS_CLINKS := re_match.c
UTILS_COBJS := $(call TOBUILDDIR,$(patsubst %.c,%.o,$(UTILS_CLINKS)))

UTILS_HLINKS := re_match.h fregex.h regex_config.h

REGEXREF_CPPSRCS := regex_ref.cpp
REGEXREF_CPPOBJS := $(call TOBUILDDIR,$(patsubst %.cpp,%.o,$(REGEXREF_CPPSRCS)))

OBJS += $(MT_CPPOBJS)
OBJS += $(DBDIRECT_COBJS) 
OBJS += $(UTILS_CPPOBJS) 
OBJS += $(UTILS_COBJS)
OBJS += $(REGEXREF_CPPOBJS)

all: $(UTILS_CPPLINKS) $(UTILS_CLINKS) $(UTILS_HLINKS) all_build

#config:
#	./action_config.sh

# Build multithreading related CPP objs
$(MT_CPPOBJS): $(BUILDDIR)/%.o: %.cpp
	@$(MKDIR)
	$(CXX) $(MT_OPTFLAGS) $(MT_COMPILEFLAGS) $(MT_CPPFLAGS) $(MT_INCLUDES) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@ $(LDLIBS)

# Create the symbol link for util srcs
$(UTILS_CPPLINKS): $(UTILS)/fregex.cpp $(UTILS)/regex_config.cpp
	@if [ -L $@ ]; then unlink $@; fi
	$(LINK) -s $(UTILS)/$@ $@

$(UTILS_HLINKS): %.h :
	@if [ -L $@ ]; then unlink $@; fi
	$(LINK) -s $(UTILS)/$@ $@

# Build util related CPP objs
$(UTILS_CPPOBJS): $(BUILDDIR)/%.o: %.cpp 
	@$(MKDIR)
	$(CXX) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) -DNODEBUG $< -MD -MT $@ -MF $(@:%o=%d) -o $@

$(UTILS_CLINKS): $(UTILS)/re_match.c
	@if [ -L $@ ]; then unlink $@; fi
	$(LINK) -s $(UTILS)/$@ $@

$(UTILS_COBJS): $(BUILDDIR)/%.o: %.c 
	@$(MKDIR)
	$(CXX) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) $< -MD -MT $@ -MF $(@:%o=%d) -o $@

# Build regex_ref obj
$(REGEXREF_CPPOBJS): $(BUILDDIR)/%.o: %.cpp
	@$(MKDIR)
	$(CXX) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) $< -MD -MT $@ -MF $(@:%o=%d) -o $@

# Build CAPI related C objs
$(DBDIRECT_COBJS): $(BUILDDIR)/%.o: %.c
	@$(MKDIR)
	$(CC) -c -std=c99 $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) $< -MD -MT $@ -MF $(@:%o=%d) -o $@ 

#projs += db_direct
projs += one_thread_direct

# Link all together
#db_direct: $(OBJS)
one_thread_direct: $(OBJS)
	$(CXX) $(LDFLAGS) $($(@)_LDFLAGS) $($(@)_objs) $($(@)_libs) $^ -o $@ $(LDLIBS) 

# If you have the host code outside of the default snap directory structure, 
# change to /path/to/snap/actions/software.mk
include $(SNAP_ROOT)/actions/software.mk

clean:
	$(RM) $(projs) $(libs) $(OBJS) *.o *.log *.out *~ 
	$(foreach l, $(UTILS_CPPLINKS), $(shell if [ -L $(l) ]; then unlink $(l); fi))
	$(foreach l, $(UTILS_CLINKS), $(shell if [ -L $(l) ]; then unlink $(l); fi))
	$(foreach l, $(UTILS_HLINKS), $(shell if [ -L $(l) ]; then unlink $(l); fi))
