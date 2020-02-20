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
ocaccel_env_sh        = $(OCACCEL_ROOT)/ocaccel_env.sh

-include $(ocaccel_config_cflags)
-include $(ocaccel_config_sh)
-include $(ocaccel_env_sh)
export ACTION_ROOT = $(OCACCEL_ROOT)/actions/$(ACTION_NAME)
##################################################################################
#### Please adjust bellowing together with run_hls_script.tcl
hls_build_dir = $(ACTION_ROOT)/hw/hls/$(ACTION_NAME)_$(FPGACHIP)
solution_name = vadd
##################################################################################
#### Please adjust bellowing together with run_hls_script.tcl

#> $(OCACCEL_ROOT)/hardware/logs/action_make.log
all: 
	@cd $(ACTION_ROOT)/hw/hls ; \
	vivado_hls -f run_hls_script.tcl 
	@ln -s $(hls_build_dir)/$(solution_name)/syn/verilog $(ACTION_ROOT)/hw/syn_verilog_link 

clean:
	@rm $(ACTION_ROOT)/hw/hls/vivado_hls.log
	@rm -fr $(hls_build_dir)
	@rm -f $(ACTION_ROOT)/hw/syn_verilog_link
# If you have the action code outside of the default ocaccel directory structure, 
# change to /path/to/ocaccel/actions/hls.mk
