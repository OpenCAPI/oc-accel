#!/bin/bash
##
## Copyright 2019 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
set -e

echo "                     arg1=$1 arg2=$2"
#NAME="${2}"
NAME="${2%.*}"
echo "                     patch $NAME for $SIMULATOR"
coveragefile=$(dirname `readlink -f $0`)"/cov.ccf"
#pslfile=$(dirname `readlink -f $0`)"/bridge.psl"
case $SIMULATOR in
    "xsim")
        sed -i "s/  simulate/# simulate/g"                   $1/$2 # run up to elaboration, skip execution
        sed -i "s/-log elaborate.log/-log elaborate.log -sv_lib libdpi -sv_root ./g" $1/$2
        ;;
    "xcelium")
        if [[ $HBM_USED == 'TRUE' ]]; then  # HBM enabled
            if [[ $UNIT_SIM_USED == 'TRUE' ]]; then
                sed -i "s%93 -relax%93 -sv -elaborate -notimingchecks -smartorder -relax +libext+.vlib+.v+.sv+.svh -define UNIT_SIM_USED -uvm -uvmhome \$UVM_HOME -uvmnocdnsextra +UVM_VERBOSITY=UVM_LOW +UVM_TESTNAME=action_tb_base_test +WORK_MODE=CROSS_CHECK +UVM_OBJECTION_TRACE +uvm_set_config_int=*,auto_dump_surface,1 +UVM_MAX_QUIT_COUNT=1,NO -assert -coverage a -covoverwrite -covfile $coveragefile -coverage functional -snapshot work%gI"         $1/$2 # run irun up to elaboration, skip execution    
            else
                sed -i "s/93 -relax/93 -sv -elaborate -notimingchecks -smartorder -relax +libext+.vlib+.v+.sv+.svh -timescale 1ns\/1ns -snapshot work/gI"         $1/$2 # run irun up to elaboration, skip execution
            fi
        else  # no HBM
            if [[ $UNIT_SIM_USED == 'TRUE' ]]; then
                sed -i "s%93 -relax%93 -sv -elaborate -smartorder -relax +libext+.vlib+.v+.sv+.svh -define UNIT_SIM_USED -uvm -uvmhome \$UVM_HOME -uvmnocdnsextra +UVM_VERBOSITY=UVM_LOW +UVM_TESTNAME=action_tb_base_test +WORK_MODE=CROSS_CHECK +UVM_OBJECTION_TRACE +uvm_set_config_int=*,auto_dump_surface,1 +UVM_MAX_QUIT_COUNT=1,NO -assert -coverage a -covoverwrite -covfile $coveragefile -coverage functional -snapshot work%gI"         $1/$2 # run irun up to elaboration, skip execution    
            else
               sed -i "s/93 -relax/93 -sv -elaborate -smartorder -relax +libext+.vlib+.v+.sv+.svh -timescale 1ns\/1ns -snapshot work/gI"         $1/$2 # run irun up to elaboration, skip execution
            fi
        fi
        #sed -i "s/xil_defaultlib/work/gI"  $1/$2 # build top in work library
        #if [ -f $1/run.f ]; then
        #    perl -i.ori -pe 'BEGIN{undef $/;} s/(^-makelib.*\n.*glbl.v.*\n.*endlib)//mg' $1/run.f; # remove glbl.v from compile list
        #    perl -i.ori -pe 'BEGIN{undef $/;} s/(^-endlib.*\n^-makelib xcelium_lib\/.* \\\n)//mg' $1/run.f; # merge everything to one lib
        #    perl -i.ori -pe 'BEGIN{undef $/;} s/^-makelib xcelium_lib\/xil_defaultlib/-makelib xcelium_lib\/work/mg' $1/run.f; # set lib name to work in run.f
        #fi
        ;;
    *) echo "unknown simulator=$SIMULATOR, terminating";;
esac
