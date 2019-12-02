#!/bin/bash
#
# Copyright 2016, International Business Machines
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
###############################################################################
set -e

echo "                     arg1=$1 arg2=$2"
# NAME=`basename $2`
NAME="${2%.*}"
echo "                     patch $NAME for $SIMULATOR"
case $SIMULATOR in
  "xsim")
    sed -i "s/  simulate/# simulate/g"                   $1/$2 # run up to elaboration, skip execution
    sed -i "s/-log elaborate.log/-log elaborate.log -sv_lib libdpi -sv_root ./g" $1/$2
    ;;
  "irun")
    sed -i "s/93 -relax/93 -elaborate -relax/gI"         $1/$2 # run irun up to elaboration, skip execution
    sed -i "s/-top xil_defaultlib.top/-top work.$NAME/gI"  $1/$2 # build top in work library
    if [[ "$NVME_USED" == "TRUE" && -n "$DENALI" ]]; then :
      echo "                     patch $irun include denali files for NVMe"
      perl -i.ori -pe 'use Env qw(DENALI);s/(glbl.v)/$1 \\\n       +incdir+"${DENALI}\/ddvapi\/verilog"/mg' $1/$2 # add denali include directory
      perl -i.ori -pe 'use Env qw(DENALI);s/(-namemap_mixgen)/$1 -disable_sem2009 -loadpli1 ${DENALI}\/verilog\/libdenpli.so:den_PLIPtr/mg' $1/$2 # add denali .so
    fi
    if [ -f ${SNAP_HARDWARE_ROOT}/sim/ies/run.f ]; then
      perl -i.ori -pe 'BEGIN{undef $/;} s/(^-makelib.*\n.*glbl.v.*\n.*endlib)//mg' ${SNAP_HARDWARE_ROOT}/sim/ies/run.f; # remove glbl.v from compile list
    fi
    ;;
  "xcelium")
    if [[ $UNIT_SIM_USED == 'TRUE' ]]; then
      sed -i "s/93 -relax/93 -sv -elaborate -smartorder -relax +libext+.vlib+.v+.sv+.svh -define UNIT_SIM_USED -seed 666 -uvm -uvmhome \$UVM_HOME -uvmnocdnsextra +UVM_VERBOSITY=UVM_LOW +UVM_TESTNAME=action_tb_base_test +WORK_MODE=CROSS_CHECK +UVM_OBJECTION_TRACE +uvm_set_config_int=*,auto_dump_surface,1 +UVM_MAX_QUIT_COUNT=1,NO/gI"         $1/$2 # run irun up to elaboration, skip execution    
    else
      sed -i "s/93 -relax/93 -sv -elaborate -smartorder -relax +libext+.vlib+.v+.sv+.svh -timescale 1ns\/1ns/gI"         $1/$2 # run irun up to elaboration, skip execution
    fi
    sed -i "s/-top xil_defaultlib.top/-top work.$NAME/gI"  $1/$2 # build top in work library
    if [[ "$NVME_USED" == "TRUE" && -n "$DENALI" ]]; then :
      echo "                     patch $irun include denali files for NVMe"
      perl -i.ori -pe 'use Env qw(DENALI);s/(glbl.v)/$1 \\\n       +incdir+"${DENALI}\/ddvapi\/verilog"/mg' $1/$2 # add denali include directory
      perl -i.ori -pe 'use Env qw(DENALI);s/(-namemap_mixgen)/$1 -disable_sem2009 -loadpli1 ${DENALI}\/verilog\/libdenpli.so:den_PLIPtr/mg' $1/$2 # add denali .so
    fi
    if [ -f ${SNAP_HARDWARE_ROOT}/sim/xcelium/run.f ]; then
      perl -i.ori -pe 'BEGIN{undef $/;} s/(^-makelib.*\n.*glbl.v.*\n.*endlib)//mg' ${SNAP_HARDWARE_ROOT}/sim/xcelium/run.f; # remove glbl.v from compile list
      perl -i.ori -pe 'BEGIN{undef $/;} s/(^-endlib.*\n^-makelib xcelium_lib\/.* \\\n)//mg' ${SNAP_HARDWARE_ROOT}/sim/xcelium/run.f; # merge everything to one lib
      perl -i.ori -pe 'BEGIN{undef $/;} s/^-makelib xcelium_lib\/xil_defaultlib/-makelib xcelium_lib\/work/mg' ${SNAP_HARDWARE_ROOT}/sim/xcelium/run.f; # set lib name to work in run.f
    fi
    ;;
  "questa"|"modelsim")
    sed -i "s/  simulate/# simulate/g"                   $1/$2 # run up to elaboration, skip execution
    ;;
  *) echo "unknown simulator=$SIMULATOR, terminating";;
esac
