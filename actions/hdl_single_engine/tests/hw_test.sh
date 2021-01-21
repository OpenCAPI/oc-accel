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
snap_card=0
duration="NORMAL"

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "SNAP_ROOT :   ${SNAP_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "  test function bridge with hdl_single_engine with different axi_size and different number of axi_id"
    echo "    [-C <card>] card to be used for the test"
    echo "    [-d] choose duration NORMAL(default) or SHORT test:"
    echo "         if this argument is NORMAL (default), run normal test (used for hardware test)"
    echo "         if this argument is SHORT           , run short (used for simulation)"
    echo
}

while getopts ":C:d:h" opt; do
    case $opt in
        C)  
        snap_card=$OPTARG;
        ;;
        d)  
        duration=$OPTARG;
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

export PATH=$PATH:${SNAP_ROOT}/software/tools:${ACTION_ROOT}/sw

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
        echo "Get CARD VERSION"
        #snap_maint -C ${snap_card} -v || exit 1;
#       snap_peek -C ${snap_card} 0x0 || exit 1;
#       snap_peek -C ${snap_card} 0x8 || exit 1;
#       echo
fi

#### MEMCOPY ##########################################################

function test_single_engine {
    echo "---------------- Testing burst num $1 size $2 length $3 id num $4: --------------"
    local num=$1
    local size=$2
    local length=$3
    local idn=$4

    local pattern=$(($(($idn<<16))+$(($length<<8))+$size))

    if [ ! -f "${ACTION_ROOT}/sw/hdl_single_engine" ]; then
       echo "ERROR: please compile 'hdl_single_engine' before execution (or run 'make apps')"
       exit 1
    fi

    echo -n "Read and Write Duplex ... "
    cmd="hdl_single_engine -C${snap_card} -c 1 -w 0 -n ${num} -N ${num} -p ${pattern} -P ${pattern} -t 100000 >>  hdl_single_engine_general_test.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hdl_single_engine_general_test.log"
        exit 1
    fi
    echo "ok"

}

rm -f hdl_single_engine_general_test.log
touch hdl_single_engine_general_test.log

############## Test axi_size(2-7) and axi_id_num(0-15) ##############
exp=0
while [ $exp -lt 16 ]
do
    if [ "$duration" = "NORMAL" ]; then
        echo "Run long test, preferred to run on card"
        test_single_engine 10000 2 255 ${exp}
        test_single_engine 10000 3 255 ${exp}
        test_single_engine 10000 4 255 ${exp}
        test_single_engine 10000 5 127 ${exp}
        test_single_engine 10000 6 63  ${exp}
        test_single_engine 10000 7 31  ${exp}
    fi
    exp=$(($exp + 1))
done

if [ "$duration" = "SHORT" ]; then
    echo "Run short test, preferred to run for simulation"
    test_single_engine 5 2 255 ${exp} 
fi

##Print build date and version
#echo
#echo -n "Git Version: "
##snap_peek -C ${snap_card} 0x0 || exit 1;
#echo -n "Build Date:  "
##snap_peek -C ${snap_card} 0x8 || exit 1;

echo "ok"

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
