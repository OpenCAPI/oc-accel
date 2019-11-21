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
# Finding $SNAP_ROOT
ifndef SNAP_ROOT
# check if we are in sw folder of an action (three directories below snap root)
ifneq ("$(wildcard ../../../../../actions)","")
SNAP_ROOT=$(abspath ../../../../../)
export SNAP_ROOT=$(abspath ../../../../../)
else
$(info You are not building your software from the default directory (/path/to/snap/actions/<action_name>/sw) or specified a wrong $$SNAP_ROOT.)
$(error Please make sure that $$SNAP_ROOT is set up correctly.)
endif
endif

CXX=g++

POSTGRESQL_INCLUDE        = $(shell pg_config --includedir)
POSTGRESQL_INCLUDE_SERVER = $(shell pg_config --includedir-server)
POSTGRESQL_LIB            = $(shell pg_config --libdir)
POSTGRESQL_PKGLIB         = $(shell pg_config --pkglibdir)
POSTGRESQL_SHARELIB       = $(shell pg_config --sharedir)

UTILS                     = ../../../string-match-fpga/utils

INCLUDES                  = -I. -I./ -I../
INCLUDES                 += -I../common/
INCLUDES                 += -I$(UTILS) 
INCLUDES                 += -I$(SNAP_ROOT)/software/include
INCLUDES                 += -I$(POSTGRESQL_INCLUDE_SERVER) -I$(POSTGRESQL_INCLUDE)/internal

EXTRA_CFLGAS             += -Wall -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv
EXTRA_CFLGAS             += -Wno-error -Wno-unused-parameter -Wno-sign-compare
EXTRA_CFLGAS             += -Wno-return-local-addr

CPPFLAGS                 += -O3 $(EXTRA_CFLGAS) $(INCLUDES) -fPIC -D_GNU_SOURCE 
LDFLAGS                  += $(EXTRA_CFLGAS) -fPIC -L$(POSTGRESQL_LIB) -Wl,--as-needed -Wl,-rpath,'$(POSTGRESQL_LIB)',--enable-new-dtags
LDLIBS                   += -locxl -lpthread -losnap -lboost_thread -lboost_system -lboost_chrono

BUILDDIR = ./obj
TOBUILDDIR = $(addprefix $(BUILDDIR)/,$(1))
MKDIR = if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi

MT_CPPSRCS := $(shell find ./mt -name "*.cpp")
MT_CPPOBJS := $(call TOBUILDDIR,$(patsubst %.cpp,%.o,$(MT_CPPSRCS)))
MT_CPPFLAGS := --std=c++11
MT_INCLUDES := -I. -I../ -I./mt -I./mt/base -I./mt/utils -I$(SNAP_ROOT)/software/include
MT_INCLUDES += -I./mt/regex -I./mt/interface
MT_INCLUDES += -I../common/
MT_INCLUDES += -I$(POSTGRESQL_INCLUDE_SERVER) -I$(POSTGRESQL_INCLUDE)/internal
MT_COMPILEFLAGS := -W -Wall -Wno-multichar -Wno-unused-parameter -Wno-unused-function -Werror-implicit-function-declaration
MT_OPTFLAGS := -O3
CPPFLAGS += $(MT_INCLUDES)

PGCAPI_CSRCS := $(shell find . -name "*.c")
PGCAPI_COBJS := $(call TOBUILDDIR,$(patsubst %.c,%.o,$(PGCAPI_CSRCS)))

UTILS_CPPLINKS := ./fregex.cpp ./regex_config.cpp
UTILS_CPPOBJS := $(call TOBUILDDIR,$(patsubst %.cpp,%.o,$(UTILS_CPPLINKS)))

OBJS += $(MT_CPPOBJS)
OBJS += $(PGCAPI_COBJS) 
OBJS += $(UTILS_CPPOBJS) 

all: $(UTILS_CPPLINKS) all_build

# Build multithreading related CPP objs
$(MT_CPPOBJS): $(BUILDDIR)/%.o: %.cpp
	@$(MKDIR)
	$(CXX) $(MT_OPTFLAGS) $(MT_COMPILEFLAGS) $(MT_CPPFLAGS) $(MT_INCLUDES) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@

# Create the symbol link for util srcs
$(UTILS_CPPLINKS): $(UTILS)/fregex.cpp $(UTILS)/regex_config.cpp
	@if [ -L $@ ]; then unlink $@; fi
	$(LINK) -s $(UTILS)/$@ $@

# Build util related CPP objs
$(UTILS_CPPOBJS): $(BUILDDIR)/%.o: %.cpp
	@$(MKDIR)
	$(CXX) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) -DNODEBUG $< -MD -MT $@ -MF $(@:%o=%d) -o $@

# Build PostgreSQL internals and CAPI related C objs
$(PGCAPI_COBJS): $(BUILDDIR)/%.o: %.c
	@$(MKDIR)
	$(CC) -c $(CPPFLAGS) $($(@:.o=)_CPPFLAGS) $< -MD -MT $@ -MF $(@:%o=%d) -o $@ 

projs += pg_capi

# Link all together
pg_capi: $(OBJS)
	$(CXX) $(LDFLAGS) $($(@)_LDFLAGS) $($(@)_objs) $($(@)_libs) -shared -o $@.so $^ $(LDLIBS) 

# Install
psql_install: pg_capi
	sudo ./install.sh $(POSTGRESQL_PKGLIB) $(POSTGRESQL_SHARELIB)/extension

# If you have the host code outside of the default snap directory structure, 
# change to /path/to/snap/actions/software.mk
include $(SNAP_ROOT)/actions/software.mk

clean:
	$(RM) $(projs) $(libs) $(OBJS) *.o *.log *.out *~ *.so
	$(foreach l, $(UTILS_CPPLINKS), $(shell if [ -L $(l) ]; then unlink $(l); fi))
