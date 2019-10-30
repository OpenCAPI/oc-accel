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
echo "                        action config says ACTION_ROOT is $ACTION_ROOT"
echo "                        action config says FPGACHIP is $FPGACHIP"
echo "                        action config says there are $NUM_OF_MULTI_PROCESS_ENGINES engines used in this action"

ENGINE_DESIGN=engines/memcopy
HDL_PP=$ACTION_ROOT/../../scripts/utils/hdl_pp/

if [ ! -d $ENGINE_DESIGN ]; then
    echo "$ENGINE_DESIGN is invalid"
    exit 1
fi

if [ -z $NUM_OF_MULTI_PROCESS_ENGINES ]; then
    echo "No number of multi process engines specified, check your snap_config!"
    exit 1
fi

echo "                        Generating defs.h"
if [ ! -f ./defs.h ]; then
    touch defs.h
else
    rm defs.h
fi
# Generate number of kernel configurations
echo "#define NUM_ENGINES ${NUM_OF_MULTI_PROCESS_ENGINES}" >> defs.h

# Preprocess configurable verilogs
for i in $(find -name \*.v_source); do
    vcp=${i%.v_source}.vcp
    v=${i%.v_source}.v
    echo "                        Processing $i"
    $HDL_PP/vcp -i $i -o $vcp -imacros ./defs.h 2>> defs.log

    if [ ! $? ]; then
        echo "!! ERROR processing $vcp"
        exit -1
    fi

    perl -I $HDL_PP/plugins -Meperl $HDL_PP/eperl -o $v $vcp 2>> defs.log

    if [ ! $? ]; then
        echo "!! ERROR processing $v"
        exit -1
    fi
done                         

# Create IP for the framework
if [ ! -d $ACTION_ROOT/ip/framework/framework_ip_prj ]; then
    echo "                        Call create_framework_ip.tcl to generate framework IPs"
    vivado -mode batch -source $ACTION_ROOT/ip/tcl/create_framework_ip.tcl -notrace -nojournal -tclargs $ACTION_ROOT $FPGACHIP $NUM_OF_MULTI_PROCESS_ENGINES >> framework_fpga_ip_gen.log

    if [ ! $? ]; then
        echo "!! ERROR generating framework IPs."
        exit -1;
    fi
fi
