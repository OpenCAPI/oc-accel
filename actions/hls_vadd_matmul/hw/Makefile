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
# Generate HDL from HLS sources
#

SHELL=/bin/bash
# Finding $OCACCEL_ROOT

ifndef OCACCEL_ROOT
# check if we are in hw folder of an action (three directories below ocaccel root)
ifneq ("$(wildcard ../../../actions)","")
OCACCEL_ROOT=$(abspath ../../../)
else
$(info You are not building your software from the default directory (/path/to/oc-accel/actions/<action_name>/sw) or specified a wrong $$OCACCEL_ROOT.)
$(error Please make sure that $$OCACCEL_ROOT is set up correctly.)
endif
endif

export OCACCEL_HARDWARE_ROOT=$(OCACCEL_ROOT)/hardware
export LOGS_DIR=$(OCACCEL_HARDWARE_ROOT)/logs

ocaccel_config_cflags = $(OCACCEL_ROOT)/.ocaccel_config.cflags
ocaccel_config_sh     = $(OCACCEL_ROOT)/.ocaccel_config.sh

-include $(ocaccel_config_cflags)
-include $(ocaccel_config_sh)
export ACTION_ROOT = $(OCACCEL_ROOT)/actions/$(ACTION_NAME)
SOLUTION_NAMES = $(KERNELS)

#> $(OCACCEL_ROOT)/hardware/logs/action_make.log
all: 
	@cd $(ACTION_ROOT)/hw/hls; for i in $$(echo $(SOLUTION_NAMES) | tr ',' '\n' | sort -u | tr '\n' ' '); do\
	    echo "Running vivado hls for $${i}"; \
	    vivado_hls -f run_$${i}_script.tcl; \
	    if [ $$? -ne 0 ]; then \
	        echo -e "ERROR: failed to run hls for $$i"; \
		exit -1; \
	    fi \
	done

clean:
	@rm -f $(ACTION_ROOT)/hw/hls/vivado_hls.log
	@rm -fr $(ACTION_ROOT)/hw/hls/*_$(FPGACHIP)
	@rm -f $(ACTION_ROOT)/hw/syn_verilog_link
