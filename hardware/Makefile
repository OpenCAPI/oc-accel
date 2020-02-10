############################################################################
############################################################################
##
## Copyright 2016-2018 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

## Variables required by other scripts.
## This Makefile is contained in the hardware directory.
## So, the root directory is one level above.
##
SHELL=/bin/bash
PLATFORM ?= $(shell uname -i)

export OCACCEL_ROOT=$(abspath ..)
export OCACCEL_HARDWARE_ROOT=$(OCACCEL_ROOT)/hardware
export LOGS_DIR=$(OCACCEL_HARDWARE_ROOT)/logs
export MAKE_TARGET=$(MAKECMDGOALS)
export OCACCEL_CFLAGS

ocaccel_config_cflags = $(OCACCEL_ROOT)/.ocaccel_config.cflags
ocaccel_config_sh     = $(OCACCEL_ROOT)/.ocaccel_config.sh
ocaccel_env_sh        = $(OCACCEL_ROOT)/ocaccel_env.sh

-include $(ocaccel_config_cflags)
-include $(ocaccel_config_sh)
-include $(ocaccel_env_sh)

export ACTION_ROOT=$(OCACCEL_ROOT)/actions/$(ACTION_NAME)
SIMULATOR ?= nosim




## variables just for this Makefile
SETUP_DIR=$(OCACCEL_HARDWARE_ROOT)/setup
SIM_DIR=$(OCACCEL_HARDWARE_ROOT)/sim

BUILD_DIR=$(OCACCEL_HARDWARE_ROOT)/build
IP_REPO_DIR=$(BUILD_DIR)/ip_repo
INTERFACES_DIR=$(BUILD_DIR)/interfaces
VIV_PROJ_DIR=$(BUILD_DIR)/viv_project


OCACCEL_SIMULATORS += xsim xcelium
templog=/dev/null

ifeq ($(UNIT_SIM_USED),TRUE)
sim_top = unit_top
else
sim_top = top_i
endif


#OCACCEL_PREPROCESS_FILES += $(OCACCEL_HARDWARE_ROOT)/oc-bip/sim/src/$(sim_top).sv
OCACCEL_PREPROCESS_FILES += $(OCACCEL_HARDWARE_ROOT)/hdl/common/ocaccel_global_vars.v



#
# FIXME Targets in this Makefile are to be build in the correct order.
#      Parallelization e.g. by using -jN will not work at this point in time
#      due to missing dependencies between the different targets.
#

ifeq ($(PLATFORM),x86_64)

# TODO: the phony list needs updating
.PHONY: all ocaccel_config check_ocaccel_settings check_simulator prepare_logs hw_project image ocse software clean

all: model image

ocaccel_config:
	@$(MAKE) -C $(OCACCEL_ROOT) ocaccel_config

check_ocaccel_settings:
	@if [ -z `which git 2> /dev/null` ]; then \
		echo "                        The OC-Accel framework make process relies on git."; \
		echo "                        Please make sure that you have installed git and"; \
		echo "                        the environment variable PATH points to its executable."; \
		echo "                        If github is really not accessible, remove 'exit -1' here in 'hardware/Makefile' to continue and"; \
		echo "                        (1) Make sure the submodule of 'hardware/oc-accel-bsp' has been copied"; \
		echo "                        (2) Comment git related strings in 'hardware/setup/common_funcs.tcl'"; \
		exit -1; \
	fi
	@cd $(OCACCEL_HARDWARE_ROOT); if [ -z `git describe --all HEAD 2> /dev/null` ]; then \
		echo "                        $(OCACCEL_HARDWARE_ROOT) does not belong to a git repository."; \
		echo "                        Please check out the OCACCEL framework as git clone from https://github.com/OpenCAPI/oc-accel"; \
		echo "                        If github is really not accessible, remove 'exit -1' here in 'hardware/Makefile' to continue and"; \
		echo "                        (1) Make sure the submodule of 'hardware/oc-accel-bsp' has been copied"; \
		echo "                        (2) Comment git related strings in 'hardware/setup/common_funcs.tcl'"; \
		exit -1; \
	fi
	@if [ ! -e "$(ocaccel_config_sh)" ]; then \
		echo "                        Missing ocaccel config setup file \"$(ocaccel_config_sh)\""; \
		echo "                        Please make sure that the ocaccel configuration is prepared by calling 'make ocaccel_config'"; \
		exit -1; \
	fi
	@if [ ! -e "$(ocaccel_env_sh)" ]; then \
		echo "                        Additional ocaccel environment setup file \"$(ocaccel_env_sh)\" doesn't exist."; \
	fi
	@echo "                        =============================="
	@echo "                        hardware/Makefile called with:"
	@echo "                        ACTION_ROOT     = $(ACTION_ROOT)"
	@echo "                        CAPI_VERSION    = $(CAPI_VER)"
	@echo "                        FPGACARD        = $(FPGACARD)"
	@echo "                        FPGACHIP        = $(FPGACHIP)"
	@echo "                        PHY_SPEED       = $(PHY_SPEED)"
	@echo "                        INFRA_TEMPLATE  = $(INFRA_TEMPLATE_SELECTION)"
	@echo "                        ACTION_TEMPLATE = $(ACTION_TEMPLATE_SELECTION)"
	@echo "                        ILA_DEBUG       = $(ILA_DEBUG)"
	@echo "                        FLASH_USED      = $(FLASH_USED)"
	@echo "                        FLASH_INTERFACE = $(FLASH_INTERFACE)"
	@echo "                        FLASH_SIZE      = $(FLASH_SIZE)"
	@if [ `echo "$(ILA_DEBUG)" | tr a-z A-Z` == "TRUE" ]; then \
		echo "                        ILA_SETUP_FILE  = $(ILA_SETUP_FILE)"; \
	fi
	@echo "                        SIMULATOR       = $(SIMULATOR)"
	@echo "                        =============================="


check_simulator:
	@if [ "$(SIMULATOR)" != "irun" ] && [ "$(SIMULATOR)" != "xsim" ] && [ "$(SIMULATOR)" != "questa" ] && [ "$(SIMULATOR)" != "xcelium" ] && [ "$(SIMULATOR)" != "modelsim" ] && [ "$(SIMULATOR)" != "nosim" ]; then \
		echo "                        unknown simulator=$SIMULATOR"; \
		exit -1; \
	fi

prepare_logs:
	@echo -e "[PREPARE LOGS.....] start `date +"%T %a %b %d %Y"`";
	@mkdir -p $(LOGS_DIR);

prepare_project: check_ocaccel_settings prepare_logs
	@echo -e "[PREPARE PROJECT.....] start `date +"%T %a %b %d %Y"`";
	@mkdir -p $(BUILD_DIR);
	@mkdir -p $(INTERFACES_DIR);
	@mkdir -p $(IP_REPO_DIR);
	@mkdir -p $(BUILD_DIR)/Reports;
	@mkdir -p $(BUILD_DIR)/Images;
	@mkdir -p $(BUILD_DIR)/Checkpoints;
	@if [ ! -e $(OCACCEL_HARDWARE_ROOT)/oc-accel-bsp/README.md ]; then \
		cd $(OCACCEL_ROOT); \
		git submodule update --init --recursive hardware/oc-accel-bsp; \
	fi;
	@echo "write_cfgmem -force -format bin -size $(FLASH_SIZE) -interface $(FLASH_INTERFACE) -loadbit \"up 0x0 $(OCACCEL_HARDWARE_ROOT)/viv_project/fpga_top.runs/impl_1/fpga_top.bit\" $(OCACCEL_HARDWARE_ROOT)/viv_project/fpga_top.runs/impl_1/$(CAPI_VER)_fpga_top_$(PHY_SPEED)_`date +%H%M_%b_%d`" > $(OCACCEL_HARDWARE_ROOT)/setup/ocaccel_bitstream_post.tcl;
	@echo -e "[PREPARE PROJECT.....] done  `date +"%T %a %b %d %Y"`";

################################# Preprocess files  #######################
# covert v_source files to v
# may not needed anymore
ocaccel_preprocess_start: prepare_project
	@echo -e "[OCACCEL PREPROCESS.....] start `date +"%T %a %b %d %Y"`";

$(OCACCEL_PREPROCESS_FILES):
	@if [ -e "$(ocaccel_config_cflags)" ]; then \
		echo -e "                        generating $(notdir $@)"; \
	else \
		echo -e "                        Need to run \"make ocaccel_config\" first"; exit -1; \
	fi
	@$(CC) -E -xc $(OCACCEL_CFLAGS) $@_source 2> $(LOGS_DIR)/$(notdir $@)_pp.log > $@_tmp;
	@if [ $$? -ne 0 ]; then \
		$(RM) $@_tmp; \
		echo -e "                        Error: please look into $(LOGS_DIR)/$(notdir $@)_pp.log"; exit -1; \
	fi
	@grep -v "^#" $@_tmp > $@
	@$(RM) $@_tmp



ocaccel_preprocess_execute: $(OCACCEL_PREPROCESS_FILES)
	@echo -e "[OCACCEL PREPROCESS.....] done  `date +"%T %a %b %d %Y"`";

ocaccel_preprocess: ocaccel_preprocess_start
	@$(MAKE) -s ocaccel_preprocess_execute

###############################################################################

action_hw: prepare_logs
	@echo -e "[CONFIG ACTION HW....] start `date +"%T %a %b %d %Y"`";
	@if [ ! -d "$(ACTION_ROOT)" ]; then \
		echo "                        Error: Path to ACTION_ROOT is not defined properly"; exit -1; \
	fi
	@echo "Calling make -C $(ACTION_ROOT) hw" > $(LOGS_DIR)/action_make.log
	@$(MAKE) -C $(ACTION_ROOT) hw >> $(LOGS_DIR)/action_make.log;
	@if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
	fi
	@if [ "$(HLS_SUPPORT)" == "TRUE" ]; then \
	        echo "Calling make -C $(ACTION_ROOT)/hw vhdl" >> $(LOGS_DIR)/action_make.log; \
		$(MAKE) -kC $(ACTION_ROOT)/hw vhdl >> $(LOGS_DIR)/action_make.log; \
		if [ $$? -ne 0 ]; then \
			echo -e "                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
		fi; \
	fi
	@echo -e "[CONFIG ACTION HW....] done  `date +"%T %a %b %d %Y"`";

###############################################################################
# Build the vivado project
define_interface:
	@echo -e "[DEFINE INTERFACE....] start `date +"%T %a %b %d %Y"`";
	@cd $(BUILD_DIR)  &&  vivado -quiet -mode batch -source $(SETUP_DIR)/common/define_interfaces.tcl -notrace -log $(LOGS_DIR)/define_interfaces.log  -journal $(LOGS_DIR)/define_interfaces.jou > $(templog) 
	@echo -e "[DEFINE INTERFACE....] done  `date +"%T %a %b %d %Y"`";

package_hostside:
	@echo -e "[PACKAGE HOSTSIDE....] start `date +"%T %a %b %d %Y"`";
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/package_hostside/package_hostside_ips.tcl -notrace -log $(LOGS_DIR)/package_hostside_ips.log -journal $(LOGS_DIR)/package_hostside_ips.jou > $(templog)
	@echo -e "[PACKAGE HOSTSIDE....] done  `date +"%T %a %b %d %Y"`";

package_infrastructure:
	@echo -e "[PACKAGE INFRA.......] start `date +"%T %a %b %d %Y"`";
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/package_infrastructure/package_infrastructure_ips.tcl -notrace -log $(LOGS_DIR)/package_infrastructure_ips.log -journal $(LOGS_DIR)/package_infrastructure_ips.jou > $(templog)
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/package_infrastructure/bd_infra_template_$(INFRA_TEMPLATE_SELECTION).tcl -notrace -log $(LOGS_DIR)/bd_infra_template_$(INFRA_TEMPLATE_SELECTION).log -journal $(LOGS_DIR)/bd_infra_template_$(INFRA_TEMPLATE_SELECTION).jou > $(templog)
	@echo -e "[PACKAGE INFRA.......] done  `date +"%T %a %b %d %Y"`";

package_action:
	@echo -e "[PACKAGE ACTION......] start `date +"%T %a %b %d %Y"`";
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/package_action/package_action_wrapper.tcl -notrace -log $(LOGS_DIR)/package_action_wrapper.log -journal $(LOGS_DIR)/package_action_wrapper.jou > $(templog)
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/package_action/bd_action_template_$(ACTION_TEMPLATE_SELECTION).tcl -notrace -log $(LOGS_DIR)/bd_action_template_$(ACTION_TEMPLATE_SELECTION).log -journal $(LOGS_DIR)/bd_action_template_$(ACTION_TEMPLATE_SELECTION).jou > $(templog)
	@echo -e "[PACKAGE ACTION......] done  `date +"%T %a %b %d %Y"`";

top_project:
	@echo -e "[CREATE TOP PROJECT..] start `date +"%T %a %b %d %Y"`";
	@cd $(BUILD_DIR)  &&  vivado -quiet -mode batch -source $(SETUP_DIR)/create_framework/create_top.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou > $(templog)
	@echo -e "[CREATE TOP PROJECT..] done  `date +"%T %a %b %d %Y"`"

hw_project: ocaccel_preprocess action_hw define_interface package_hostside package_infrastructure package_action top_project
	@echo -e "                        using `vivado -version |grep Vivado`"
	@echo -e "                        CAPI_VER=$(CAPI_VER)"


###############################################################################
# sim_project


###############################################################################
image: hw_project
	@echo -e "[BUILD IMAGE.........] start `date +"%T %a %b %d %Y"`\n"
	@echo "A complete FPGA bitstream build got kicked off.";
	@echo "This might take more than an hour depending on the machine used";
	@echo "The process may be terminated by pressing <CTRL>-C at any time.";
	@echo "After termination it can be restarted later."; echo
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source $(SETUP_DIR)/build_image/ocaccel_build.tcl -notrace -log $(LOGS_DIR)/ocaccel_build.log -journal $(LOGS_DIR)/ocaccel_build.jou
#	@$(RM) -r .bitstream_name.txt
#	@echo -e "Generating ltx file for ILA debug."
#	@cd $(BUILD_DIR) && vivado -mode batch -source $(SETUP_DIR)/gen_probe_ltx.tcl -notrace  -log $(LOGS_DIR)/gen_probe_ltx.log         -journal $(LOGS_DIR)/gen_probe_ltx.jou
#	@echo -e "Generation of ltx file done."
#	@mv $(BUILD_DIR)/probe.ltx $(BUILD_DIR)/Images
#	@echo -e "Moved ltx file into Image."
	@echo -e "[BUILD IMAGE.........] done  `date +"%T %a %b %d %Y"`"


ocse: prepare_logs
	@echo -e "[COMPILE OCSE .......] start `date +"%T %a %b %d %Y"`"
	@$(OCACCEL_ROOT)/check_ocse.sh > $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(OCSE_ROOT) >> $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then echo -e "                        Error: please look into $(LOGS_DIR)/compile_ocse.log"; exit -1; fi
	@echo -e "[COMPILE OCSE .......] done  `date +"%T %a %b %d %Y"`"

software: ocse
	@echo -e "[COMPILE SOFTWARE....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(OCACCEL_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_sw.log";  \
	fi
	@echo -e "[COMPILE SOFTWARE....] done  `date +"%T %a %b %d %Y"`"

app: software
	@echo -e "[COMPILE APPLICATION.] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(ACTION_ROOT)/sw        >> $(LOGS_DIR)/compile_sw.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_sw.log";  \
	fi
	@echo -e "[COMPILE APPLICATION.] done  `date +"%T %a %b %d %Y"`"

nosim:
	@echo -e "[BUILD $@ MODEL....] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        Info: Not building a simulation model, since SIMULATOR is set to \"nosim\"";
	@echo -e "[BUILD $@ MODEL....] done  `date +"%T %a %b %d %Y"`"

ifeq ($(UNIT_SIM_USED),TRUE)
$(OCACCEL_SIMULATORS):  .sim_project_done
	@if [ "$(SIMULATOR)" != "$@" ]; then \
		echo; echo "Error: Makefile target $@ called with SIMULATOR set to \"$(SIMULATOR)\""; \
		exit -1; \
	fi
	@echo -e "[BUILD $@ MODEL....] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        export_simulation";
	@cd $(SIM_DIR) && vivado -quiet -mode batch -source $(SETUP_DIR)/export_$@.tcl -notrace -log $(LOGS_DIR)/compile_$@.log -journal $(LOGS_DIR)/compile_$@.jou
	@echo -e "                        patch simulation";
	@$(SETUP_DIR)/patch_sim.sh $(SIM_DIR)/$(subst irun,ies,$@) $(sim_top).sh >> $(LOGS_DIR)/compile_$@.log 2>&1
	@echo -e "                        link to libdpi";
	@cd $(SIM_DIR)/$(subst irun,ies,$@) && ln -sf $(OCSE_ROOT)/afu_driver/src/libdpi.so;
	@echo -e "                        build $@ model";
	@cd $(SIM_DIR)/$(subst irun,ies,$@); \
		./$(sim_top).sh >> $(LOGS_DIR)/compile_$@.log 2>&1; \
		if [ $$? -ne 0 ]; then \
			echo -e "                        Error: please look into $(LOGS_DIR)/compile_$@.log"; exit -1; \
		fi
	@touch .model_$@
	@echo -e "[BUILD $@ MODEL....] done  `date +"%T %a %b %d %Y"`"

else
$(OCACCEL_SIMULATORS):  .sim_project_done app
	@if [ "$(SIMULATOR)" != "$@" ]; then \
		echo; echo "Error: Makefile target $@ called with SIMULATOR set to \"$(SIMULATOR)\""; \
		exit -1; \
	fi
	@echo -e "[BUILD $@ MODEL....] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        export_simulation";
	@cd $(SIM_DIR) && vivado -quiet -mode batch -source $(SETUP_DIR)/export_$@.tcl -notrace -log $(LOGS_DIR)/compile_$@.log -journal $(LOGS_DIR)/compile_$@.jou
	@echo -e "                        patch simulation";
	@$(SETUP_DIR)/patch_sim.sh $(SIM_DIR)/$(subst irun,ies,$@) $(sim_top).sh >> $(LOGS_DIR)/compile_$@.log 2>&1
	@echo -e "                        link to libdpi";
	@cd $(SIM_DIR)/$(subst irun,ies,$@) && ln -sf $(OCSE_ROOT)/afu_driver/src/libdpi.so;
	@echo -e "                        build $@ model";
	@cd $(SIM_DIR)/$(subst irun,ies,$@); \
		./$(sim_top).sh >> $(LOGS_DIR)/compile_$@.log 2>&1; \
		if [ $$? -ne 0 ]; then \
			echo -e "                        Error: please look into $(LOGS_DIR)/compile_$@.log"; exit -1; \
		fi
	@touch .model_$@
	@echo -e "[BUILD $@ MODEL....] done  `date +"%T %a %b %d %Y"`"
endif

$(OCACCEL_MODELS):
	@$(MAKE) -s $(subst .model_,,$@)

ifeq ($(UNIT_SIM_USED),TRUE)
model: check_simulator 
	@$(MAKE) -s $(SIMULATOR)

else
model: check_simulator
	@$(MAKE) -s $(SIMULATOR)

endif

unit_sim: check_simulator
	@$(MAKE) -s $(SIMULATOR)

sim: check_simulator
	@$(MAKE) -s .model_$(SIMULATOR)
	@echo -e "[SIMULATION........] start `date +"%T %a %b %d %Y"`"
	@echo "                        SIMULATOR is set to $(SIMULATOR)"
	@if [ "$(SIMULATOR)" != "nosim" ]; then cd sim; ./run_sim; fi
	@echo -e "[SIMULATION........] done  `date +"%T %a %b %d %Y"`"
	@echo " To display traces, execute: ./display_traces"

sim_tmux:
	@tmux new-session "$(MAKE) -s sim"

else #noteq ($(PLATFORM),x86_64)
.PHONY: wrong_platform all model sim image

wrong_platform:
	@echo; echo "\nOCACCEL hardware builds are possible on x86 platform only\n"; echo;

all model sim image: wrong_platform
endif

.PHONY: clean

clean:
	@echo -e "[CLEAN ENVIRONMENT...] start `date +"%T %a %b %d %Y"`"
	@$(RM) -r $(OCACCEL_PREPROCESS_FILES)                   \
	          $(OCACCEL_MODELS)                         \
	          *build
	@$(RM) $(OCACCEL_ROOT)/hardware/hdl/common/*_tmp
	@$(RM) $(OCACCEL_ROOT)/hardware/setup/build_image/bitstream_date.txt
	@echo -e "                        vivado project"; 
	@$(RM) -r $(VIV_PROJ_DIR)*
	@echo -e "                        IPs";
	@$(RM) -r $(IP_REPO_DIR)
	@echo -e "                        interface definitions";
	@$(RM) -r $(INTERFACES_DIR)
	@echo -e "                        sim files";
	@$(RM) -r sim/ies sim/xsim sim/modelsim sim/questa sim/xcelium 
	@echo -e "                        log files";
	@$(RM) -r logs
	@echo -e "                        action / application";
	@if [ -e "$(ACTION_ROOT)/Makefile" ]; then          \
		$(MAKE) -C $(ACTION_ROOT) $@ > /dev/null;   \
		if [ $$? -ne 0 ]; then                      \
			echo -e "                        Error: [make "$@"] failed for action/application in $(ACTION_ROOT)"; exit -1; \
		fi                                          \
	fi
	@echo -e "[CLEAN ENVIRONMENT...] done  `date +"%T %a %b %d %Y"`"
