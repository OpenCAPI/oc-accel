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

OCACCEL_ROOT ?= $(abspath ../..)

include ../config.mk


LDLIBS += -locaccel -locxl -lpthread
LDFLAGS += -Wl,-rpath,$(OCACCEL_ROOT)/software/lib
libs += $(OCACCEL_ROOT)/software/lib/libocaccel.so

ifdef BUILD_SIMCODE
CFLAGS += -D_SIM_
LDFLAGS += -L$(OCSE_ROOT)/libocxl -Wl,-rpath,$(OCSE_ROOT)/libocxl
LIBS += $(OCSE_ROOT)/libocxl/libocxl.so
endif

ocaccel_peek_objs = force_cpu.o
ocaccel_poke_objs = force_cpu.o

projs = ocaccel_peek ocaccel_poke simple_reg_access ocaccel_maint
objs = force_cpu.o $(projs:=.o)
hfiles = force_cpu.h  ocaccel_fw_example.h

all: $(projs)

$(projs): $(objs)

$(objs): ocaccel_actions.h $(libs)

$(libs):
	$(MAKE) -C $(shell dirname $@)

### Deactivate existing implicit rule
%: %.c
%: %.sh

### Generic rule to build a tool
%: %.o
	$(CC) $(LDFLAGS) $($(@)_LDFLAGS) $@.o $($(@)_objs) $($(@)_libs) $(LDLIBS) -o $@

%.o: %.c $(hfiles)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

install: all
	@mkdir -p $(DESTDIR)/bin
	for f in $(projs) ; do					\
		echo "installing $(DESTDIR)/bin/$$f ...";	\
		install -D -m 755 $$f -T $(DESTDIR)/bin/$$f;	\
	done

uninstall:
	@for f in $(projs) ; do					\
		echo "removing $(DESTDIR)/bin/$$f ...";		\
		$(RM) $(DESTDIR)/bin/$$f;			\
	done

clean distclean:
	$(RM) $(objs) $(projs) *.o *~
