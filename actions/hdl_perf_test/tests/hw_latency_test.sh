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

verbose=0
ocaccel_card=0
short=1

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
OCACCEL_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "OCACCEL_ROOT :   ${OCACCEL_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "  test function bridge with hdl_perf_test with different axi_size and different number of axi_id"
    echo "    [-C <card>] card to be used for the test"
    echo "    [-s] choose to run long or short test:"
    echo "         if this argument is not given or given as 1, run shorter test for simulation"
    echo "         if this argument is given as 0, run longer test on card"
    echo
}

while getopts ":C:s:h" opt; do
    case $opt in
        C)  
        ocaccel_card=$OPTARG;
        ;;
        s)  
        short=$OPTARG;
        ;;
        h)
        usage;
        exit 0;
        ;;
        \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
done

export PATH=$PATH:${OCACCEL_ROOT}/software/tools:${ACTION_ROOT}/sw

#### VERSION ##########################################################

ocaccel_maint -C ${ocaccel_card} || exit 1;

#### Run Cmd ##########################################################

function test_perf_latency {
    echo "--------------------------------------------------------------------------------------"
    echo "> Testing rnum $1 wnum $2 size $3 length $4 axi_id_range (0 to $5): "
    local rnum=$1
    local wnum=$2
    local size=$3
    local length=$4
    local idn=$5

    local pattern=$(($(($idn<<16))+$(($length<<8))+$size))

    cmd="hdl_perf_test -C${ocaccel_card} -c 1 -w 0 -n ${rnum} -N ${wnum} -p ${pattern} -P ${pattern} -t 100000 >>  hdl_perf_test_latency.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hdl_perf_test_latency.log"
        exit 1
    fi
    echo "ok"
    if [ $rnum -ne 0 ]; then 
        echo "Calculate read cycle counts"
        ./process_latency.awk file_rd_cycle
    fi	
    if [ $wnum -ne 0 ]; then	
        echo "Calculate write cycle counts"
        ./process_latency.awk file_wr_cycle
    fi	

}

rm -f hdl_perf_test_latency.log
touch hdl_perf_test_latency.log

############## Test small burst length  ##############
test_perf_latency 100000 0 7 0 0
test_perf_latency 0 100000 7 0 0
test_perf_latency 100000 100000 7 0 0

echo "ok"

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
