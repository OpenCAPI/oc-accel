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

export SNAP_ROOT=$(abspath ..)
export SNAP_HARDWARE_ROOT=$(SNAP_ROOT)/hardware
export LOGS_DIR=$(SNAP_HARDWARE_ROOT)/logs
export MAKE_TARGET=$(MAKECMDGOALS)
export SNAP_CFLAGS

snap_config_cflags = $(SNAP_ROOT)/.snap_config.cflags
snap_config_sh     = $(SNAP_ROOT)/.snap_config.sh
snap_env_sh        = $(SNAP_ROOT)/snap_env.sh

-include $(snap_config_cflags)
-include $(snap_config_sh)
-include $(snap_env_sh)

SIMULATOR ?= nosim

#small case -- not used
#FPGA_CARD := $(shell echo $(FPGACARD) | tr '[:upper:]' '[:lower:]')

FPGACARD_LOWER = $(shell echo $(FPGACARD) | tr A-Z a-z)

#OPENCAPI_BSP_IP_DONE=$(SNAP_HARDWAR_ROOT)/oc-bip/build/.create_ip_done
#OPENCAPI_BSP_IP_UNIT_SIM_DONE=$(SNAP_HARDWAR_ROOT)/oc-bip/build/.create_ip_unit_sim_done

export DCP_ROOT ?= $(SNAP_ROOT)/dcp

# luyong says: Remove it again when PRFLOW enabled again. 
# It should come from Kconfig
USE_PRFLOW ?= FALSE
export IGNORE_CHECK_PSL ?= $(USE_PRFLOW)

## variables just for this Makefile
SETUP_DIR=$(SNAP_HARDWARE_ROOT)/setup
BUILD_DIR=$(SNAP_HARDWARE_ROOT)/build
SIM_DIR=$(SNAP_HARDWARE_ROOT)/sim
SNAP_HDL_CORE=$(SNAP_HARDWARE_ROOT)/hdl/core
SNAP_HDL_OC=$(SNAP_HARDWARE_ROOT)/hdl/oc
SNAP_HDL_HLS=$(SNAP_HARDWARE_ROOT)/hdl/hls
SNAP_SIM_CORE=$(SIM_DIR)/core

SNAP_SIMULATORS += irun xsim questa modelsim xcelium
SNAP_MODELS += .model_irun .model_xsim

#SNAP_PP_FILES_VHD = $(SNAP_HDL_HLS)/action_wrapper.vhd

SNAP_PP_FILES_VHD += $(SNAP_HDL_CORE)/snap_global_vars.v

ifeq ($(UNIT_SIM_USED),TRUE)
sim_top = unit_top
else
sim_top = top
endif
#SNAP_PP_FILES_VHD += $(SNAP_HARDWARE_ROOT)/oc-bip/sim/src/$(sim_top).sv

SNAP_TMP_FILES =  $(SIM_DIR)/README.txt

SNAP_ACTION_DCP=$(DCP_ROOT)/user_action_synth.dcp
SNAP_BASE_DCP=$(DCP_ROOT)/snap_static_region_bb.dcp

#
# FIXME Targets in this Makefile are to be build in the correct order.
#      Parallelization e.g. by using -jN will not work at this point in time
#      due to missing dependencies between the different targets.
#

ifeq ($(PLATFORM),x86_64)

.PHONY: all snap_config check_snap_settings check_simulator prepare_project snap_preprocess_start snap_preprocess_execute snap_preprocess patch_version action_hw create_hls_ip create_project hw_project_start hw_project .hw_project_done sim_project .sim_project_done config image cloud_enable cloud_base cloud_action cloud_merge ocse software app model xsim irun nosim sim clean

all: model image

snap_config:
	@$(MAKE) -C $(SNAP_ROOT) snap_config

check_snap_settings:
	@if [ -z `which git 2> /dev/null` ]; then \
		echo "                        The SNAP framework make process relies on git."; \
		echo "                        Please make sure that you have installed git and that"; \
		echo "                        the environment variable PATH points to its executable."; \
		exit -1; \
	fi
	@cd $(SNAP_HARDWARE_ROOT); if [ -z `git describe --all HEAD 2> /dev/null` ]; then \
		echo "                        $(SNAP_HARDWARE_ROOT) does not belong to a git repository."; \
		echo "                        Please check out the SNAP framework as git clone from git@github.com:open-power/snap.git"; \
		exit -1; \
	fi
	@if [ ! -e "$(snap_config_sh)" ]; then \
		echo "                        Missing snap config setup file \"$(snap_config_sh)\""; \
		echo "                        Please make sure that the snap configuration is prepared by calling 'make snap_config'"; \
		exit -1; \
	fi
	@if [ ! -e "$(snap_env_sh)" ]; then \
		echo "                        Missing snap environment setup file \"$(snap_env_sh)\""; \
		echo "                        Please make sure that the snap environment is prepared by calling 'make snap_config'"; \
		exit -1; \
	fi
	@source $(SNAP_ROOT)/snap_env $(ignore_action_root);
	@echo "                        =============================="
	@echo "                        hardware/Makefile called with:"
	@echo "                        ACTION_ROOT     = $(ACTION_ROOT)"
	@echo "                        FPGACARD        = $(FPGACARD)"
	@echo "                        FPGACHIP        = $(FPGACHIP)"
	@echo "                        PHY_SPEED       = $(PHY_SPEED)"
	@echo "                        NUM_OF_ACTIONS  = $(NUM_OF_ACTIONS)"
	@echo "                        HLS_SUPPORT     = $(HLS_SUPPORT)"
	@echo "                        BRAM_USED       = $(BRAM_USED)"
	@echo "                        SDRAM_USED      = $(SDRAM_USED)"
	@echo "                        NVME_USED       = $(NVME_USED)"
	@echo "                        ILA_DEBUG       = $(ILA_DEBUG)"
	@echo "                        FLASH_USED      = $(FLASH_USED)"
	@echo "                        FLASH_INTERFACE = $(FLASH_INTERFACE)"
	@echo "                        FLASH_SIZE      = $(FLASH_SIZE)"
	@if [ `echo "$(ILA_DEBUG)" | tr a-z A-Z` == "TRUE" ]; then \
		echo "                        ILA_SETUP_FILE  = $(ILA_SETUP_FILE)"; \
	fi
	@echo "                        SIMULATOR       = $(SIMULATOR)"
	@echo "                        USE_PRFLOW      = $(USE_PRFLOW)"
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` == "TRUE" ]; then \
		echo "                        CLOUD_USER_FLOW = $(CLOUD_USER_FLOW)"; \
		echo "                        DCP_ROOT        = $(DCP_ROOT)"; \
	fi
	@echo "                        =============================="


check_simulator:
	@if [ "$(SIMULATOR)" != "irun" ] && [ "$(SIMULATOR)" != "xsim" ] && [ "$(SIMULATOR)" != "questa" ] && [ "$(SIMULATOR)" != "xcelium" ] && [ "$(SIMULATOR)" != "modelsim" ] && [ "$(SIMULATOR)" != "nosim" ]; then \
		echo "                        unknown simulator=$SIMULATOR"; \
		exit -1; \
	fi

prepare_logs:
	@mkdir -p $(LOGS_DIR);

prepare_project: check_snap_settings prepare_logs
	@echo -e "[PREPARE PROJECT.....] start `date +"%T %a %b %d %Y"`";
	@mkdir -p $(BUILD_DIR);
	@mkdir -p $(BUILD_DIR)/Reports;
	@mkdir -p $(BUILD_DIR)/Images;
	@mkdir -p $(BUILD_DIR)/Checkpoints;
	@if [ ! -e $(SNAP_HARDWARE_ROOT)/oc-bip/README.md ]; then \
		cd $(SNAP_ROOT); \
		git submodule update --init --recursive hardware/oc-bip; \
	fi;
	@echo "write_cfgmem -force -format bin -size $(FLASH_SIZE) -interface $(FLASH_INTERFACE) -loadbit \"up 0x0 $(SNAP_HARDWARE_ROOT)/viv_project/framework.runs/impl_1/oc_fpga_top.bit\" $(SNAP_HARDWARE_ROOT)/viv_project/framework.runs/impl_1/oc_fpga_top_$(PHY_SPEED)_`date +%H%M_%b_%d`" > $(SNAP_HARDWARE_ROOT)/setup/snap_bitstream_post.tcl;
	@echo -e "[PREPARE PROJECT.....] done  `date +"%T %a %b %d %Y"`";

snap_preprocess_start: prepare_project
	@echo -e "[SNAP PREPROCESS.....] start `date +"%T %a %b %d %Y"`";

$(SNAP_PP_FILES_VHD):
	@if [ -e "$(snap_config_cflags)" ]; then \
		echo -e "                        generating $(notdir $@)"; \
	else \
		echo -e "                        Need to run \"make snap_config\" first"; exit -1; \
	fi
	@$(CC) -E -xc $(SNAP_CFLAGS) $@_source 2> $(LOGS_DIR)/$(notdir $@)_pp.log > $@_tmp;
	@if [ $$? -ne 0 ]; then \
		$(RM) $@_tmp; \
		echo -e "                        Error: please look into $(LOGS_DIR)/$(notdir $@)_pp.log"; exit -1; \
	fi
	@grep -v "^#" $@_tmp > $@
	@$(RM) $@_tmp


%.vhd: %.vhd_source

snap_preprocess_execute: $(SNAP_PP_FILES_VHD)
	@echo -e "[SNAP PREPROCESS.....] done  `date +"%T %a %b %d %Y"`";

snap_preprocess: snap_preprocess_start
	@$(MAKE) -s snap_preprocess_execute

patch_version:
	@echo -e "                        patching SNAP version and build date registers"; \
	$(SNAP_HARDWARE_ROOT)/setup/patch_version.sh $(SNAP_HDL_CORE) snap_global_vars.v


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

.create_snap_ip_done:
	@cd $(BUILD_DIR)  &&  vivado -quiet -mode batch -source $(SETUP_DIR)/create_snap_ip.tcl        -notrace -log $(LOGS_DIR)/create_snap_ip.log         -journal $(LOGS_DIR)/create_snap_ip.jou
	@touch .create_snap_ip_done


create_hls_ip:
	@cd $(BUILD_DIR) &&  vivado -quiet -mode batch -source $(SETUP_DIR)/create_hls_ip.tcl -notrace -log $(LOGS_DIR)/create_hls_ip.log -journal $(LOGS_DIR)/create_hls_ip.jou

create_project: snap_preprocess
	@echo -e "[CREATE PROJECT......] start `date +"%T %a %b %d %Y"`";
	@echo -e "                        using `vivado -version |grep Vivado`"
	@echo -e "                        CAPI_VER=$(CAPI_VER)"
	@$(MAKE) -s .create_snap_ip_done
	@$(MAKE) -s create_hls_ip
	@$(MAKE) -s patch_version
	@cd $(BUILD_DIR)  &&  vivado -quiet -mode batch -source $(SETUP_DIR)/create_framework.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou
	@echo -e "[CREATE PROJECT......] done  `date +"%T %a %b %d %Y"`"

hw_project_start:
	@echo -e "[HW PROJECT..........] start `date +"%T %a %b %d %Y"`"

#The difference between sim_project and hw_project is:
#sim_project doesn't require oc_bsp_wrap
#hw_project requires it. So user can run synthesis and implementation in vivado GUI
sim_project: hw_project_start action_hw
	@$(MAKE) -s create_project
	@touch .sim_project_done
	@echo -e "[HW PROJECT (for sim)] done  `date +"%T %a %b %d %Y"`"


#hw_project: hw_project_start action_hw  $(OPENCAPI_BSP_IP_DONE)
hw_project: hw_project_start action_hw
	@$(MAKE) -s create_project
	@touch .hw_project_done
	@touch .sim_project_done
	@echo -e "[HW PROJECT (full)...] done  `date +"%T %a %b %d %Y"`"

.sim_project_done:
	$(MAKE) -s sim_project

.hw_project_done:
	$(MAKE) -s hw_project

# Adding target 'config' for backward compatibility
config: hw_project

## Adding OpenCAPI board support package ip if required
#$(OPENCAPI_BSP_IP_DONE):
##	@echo -e "[CHECK TLx/DLx.......] start `date +"%T %a %b %d %Y"`";
##	@if [ ! -e $(SNAP_HARDWARE_ROOT)/oc-bip/tlx/ibm.*.zip ] || [ ! -e $(SNAP_HARDWARE_ROOT)/oc-bip/dlx/ibm.*.zip ]; then \
##		echo "ERROR: Please download TLX and DLX IP zip packages from WEBLINK (TBD)"; \
##		echo "  Put ibm.com_OpenCAPI_OC3_TLX_<VERSION>.zip to hardware/oc-bip/tlx"; \
##		echo "  Put ibm.com_OpenCAPI_OC3_DLX_<VERSION>.zip to hardware/oc-bip/dlx"; \
##		exit -1; \
##	fi;
##	@echo -e "[CHECK TLx/DLx.......] done `date +"%T %a %b %d %Y"`";
#	@$(MAKE) -C $(SNAP_HARDWARE_ROOT)/oc-bip $(FPGACARD_LOWER);

## Adding OpenCAPI board support package ip for unit sim if required
#$(OPENCAPI_BSP_IP_UNIT_SIM_DONE):
##	@echo -e "[CHECK TLx.......] start `date +"%T %a %b %d %Y"`";
##	@if [ ! -e $(SNAP_HARDWARE_ROOT)/oc-bip/tlx/ibm.*.zip ]; then \
##		echo "ERROR: Please download TLX zip packages from WEBLINK (TBD)"; \
##		echo "  Put ibm.com_OpenCAPI_OC3_TLX_<VERSION>.zip to hardware/oc-bip/tlx"; \
##		exit -1; \
##	fi;
##	@echo -e "[CHECK TLx.......] done `date +"%T %a %b %d %Y"`";
#	@$(MAKE) -C $(SNAP_HARDWARE_ROOT)/oc-bip unit_sim;

image:
	$(MAKE) .hw_project_done
	@echo -e "[BUILD IMAGE.........] start `date +"%T %a %b %d %Y"`\n"
ifeq ($(USE_PRFLOW),TRUE)
	snap-cloud-build ${SNAP_ROOT}/snap_env.sh
else
	@echo "A complete FPGA bitstream build got kicked off.";
	@echo "This might take more than an hour depending on the machine used";
	@echo "The process may be terminated by pressing <CTRL>-C at any time.";
	@echo "After termination it can be restarted later."; echo
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source $(SETUP_DIR)/snap_build.tcl -notrace -log $(LOGS_DIR)/snap_build.log -journal $(LOGS_DIR)/snap_build.jou
	@$(RM) -r .bitstream_name.txt
endif
	@echo -e "Generating ltx file for ILA debug."
	@cd $(BUILD_DIR) && vivado -mode batch -source $(SETUP_DIR)/gen_probe_ltx.tcl -notrace  -log $(LOGS_DIR)/gen_probe_ltx.log         -journal $(LOGS_DIR)/gen_probe_ltx.jou
	@echo -e "Generation of ltx file done."
	@mv $(BUILD_DIR)/probe.ltx $(BUILD_DIR)/Images
	@echo -e "Moved ltx file into Image."
	@echo -e "[BUILD IMAGE.........] done  `date +"%T %a %b %d %Y"`"

allow_%:
	@if [ "$(USE_PRFLOW)" != "TRUE" ]; then \
		echo; echo "Error: Makefile target $* is only allowed for PR flow!"; exit -1; \
	elif [ "$(CLOUD_USER_FLOW)" == "TRUE" ] && [ "$*" == "cloud_base" ]; then \
		echo; echo "Error: Makefile target $* is not allowed for cloud user flow!"; exit -1; \
	fi

cloud_enable: allow_cloud_action
	@echo -e "[ENABLE CLOUD FLOW...] start `date +"%T %a %b %d %Y"e`"
	@$(MAKE) -s patch_version
	@cd $(BUILD_DIR) && env CLOUD_RUN= vivado -quiet -mode batch -source $(SETUP_DIR)/snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/cloud_action.log -journal $(LOGS_DIR)/cloud_action.jou
	@echo -e "[ENABLE CLOUD FLOW...] done  `date +"%T %a %b %d %Y"`"

cloud_base: allow_cloud_base .hw_project_done
	@echo -e "[BUILD CLOUD BASE....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -s patch_version
	@cd $(BUILD_DIR) && env CLOUD_RUN=BASE vivado -quiet -mode batch -source $(SETUP_DIR)/snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/snap_cloud_build.log -journal $(LOGS_DIR)/snap_cloud_build.jou
	@echo -e "[BUILD CLOUD BASE....] done  `date +"%T %a %b %d %Y"`"

$(SNAP_ACTION_DCP):
	@echo -e "                        Need to run cloud_action first"
	@exit -1

$(SNAP_BASE_DCP):
	@echo -e "                        Need to run cloud_base first"
	@exit -1

cloud_action: allow_cloud_action .hw_project_done
	@echo -e "[CLOUD ACTION SYNTH..] start `date +"%T %a %b %d %Y"e`"
	@$(MAKE) -s patch_version
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && env CLOUD_RUN=ACTION vivado -quiet -mode batch -source $(SETUP_DIR)/snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/cloud_action.log -journal $(LOGS_DIR)/cloud_action.jou
	@echo -e "[CLOUD ACTION SYNTH..] done  `date +"%T %a %b %d %Y"`"

cloud_merge: allow_cloud_merge $(SNAP_BASE_DCP) $(SNAP_ACTION_DCP)
	@ignore_action_root=ignore_action_root $(MAKE) prepare_project
	@echo -e "[CLOUD MERGE ........] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source $(SETUP_DIR)/snap_cloud_merge.tcl -notrace -log $(LOGS_DIR)/snap_cloud_merge.log -journal $(LOGS_DIR)/snap_cloud_merge.jou
	@echo -e "[CLOUD MERGE ........] done  `date +"%T %a %b %d %Y"`"

ocse: prepare_logs
	@echo -e "[COMPILE OCSE .......] start `date +"%T %a %b %d %Y"`"
	@$(SNAP_ROOT)/check_ocse.sh > $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(OCSE_ROOT) >> $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then echo -e "                        Error: please look into $(LOGS_DIR)/compile_ocse.log"; exit -1; fi
	@echo -e "[COMPILE OCSE .......] done  `date +"%T %a %b %d %Y"`"

software: ocse
	@echo -e "[COMPILE SOFTWARE....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(SNAP_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1; \
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
$(SNAP_SIMULATORS):  .sim_project_done
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
$(SNAP_SIMULATORS):  .sim_project_done app
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

$(SNAP_MODELS):
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
	@echo; echo "\nSNAP hardware builds are possible on x86 platform only\n"; echo;

all model sim image: wrong_platform
endif

.PHONY: clean
clean:
	@echo -e "[CLEAN ENVIRONMENT...] start `date +"%T %a %b %d %Y"`"
	@$(RM)    .hw_project_done .sim_project_done .create_snap_ip_done 
	@$(RM) -r $(SNAP_PP_FILES_VHD)                   \
	          $(SNAP_TMP_FILES)                      \
	          $(SNAP_MODELS)                         \
	          *build
	@$(RM) $(SNAP_ROOT)/hardware/hdl/core/*_tmp
	@echo -e "                        vivado project" 1>/dev/null 2>/dev/null; 
	@$(RM) -r viv_project*
	@echo -e "                        IPs" 1>/dev/null 2>/dev/null;
	@$(RM) -r ip
	@echo -e "                        sim files" 1>/dev/null 2>/dev/null;
	@$(RM) -r sim/ies sim/xsim sim/modelsim sim/questa sim/xcelium 
	@echo -e "                        log files" 1>/dev/null 2>/dev/null;
	@$(RM) -r logs
	@echo -e "                        action / application" 1>/dev/null 2>/dev/null;
	@$(RM) $(ACTION_ROOT)/hw/vhdl
	@if [ -e "$(ACTION_ROOT)/Makefile" ]; then	    \
		$(MAKE) -C $(ACTION_ROOT) $@ > /dev/null;   \
		if [ $$? -ne 0 ]; then                      \
			echo -e "                        Error: [make "$@"] failed for action/application in $(ACTION_ROOT)"; exit -1; \
		fi                                          \
	fi
	@echo -e "[CLEAN ENVIRONMENT...] done  `date +"%T %a %b %d %Y"`" 1>/dev/null 2>/dev/null
