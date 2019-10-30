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
    echo "  test throughput of oc-accel bridge mode widh hdl_single_engine:"
    echo "    Throughput is tested under wrap mode to eliminate the affect of cache miss/tlb miss to throughput"
    echo "    Throughput is tested for read/write/duplex with testing size from 32KB to 8GB"
    echo "    Each test will be run for 100 times and the average bandwidth, min/max/variance of bandwidth will be given"
    echo "    [-C <card>] card to be used for the test"
    echo
}

while getopts ":C:h" opt; do
    case $opt in
        C)  
        snap_card=$OPTARG;
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
    echo "---------------- Testing size $1 (bytes): --------------"
    local num=$(($1/4096))

    echo "num: ${num}*4KB"

    echo -n "Read from Host Memory to FPGA ... "
    cmd="hdl_single_engine -C${snap_card} -c 100 -w 0x00000601 -n ${num} -N 0 -p 0x00001F07 -t 100000  >> hdl_single_engine.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hdl_single_engine.log"
        exit 1
    fi
    echo "ok"

    echo -n "Write from FPGA to Host Memory ... "
    cmd="hdl_single_engine -C${snap_card} -c 100 -w 0x00000601 -n 0 -N ${num} -P 0x00001F07 -t 100000  >> hdl_single_engine.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hdl_single_engine.log"
        exit 1
    fi
    echo "ok"

    echo -n "Read and Write Duplex ... "
    cmd="hdl_single_engine -C${snap_card} -c 100 -w 0x00000601 -n ${num} -N ${num} -p 0x00001F07 -P 0x00001F07 -t 100000 >>  hdl_single_engine.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hdl_single_engine.log"
        exit 1
    fi
    echo "ok"

}

rm -f hdl_single_engine.log
touch hdl_single_engine.log

############## INCR Also do some awk processing ##############
#size=4096
size=131072
#exp=0
exp=5
while [ $exp -lt 22 ]
do
        echo "size: ${size}Bytes"
        test_single_engine ${size}
        exp=$(($exp + 1))
        size=$(($size * 2))
done

./process_bandwidth.awk hdl_single_engine.log
./process_variance.awk hdl_single_engine.log

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
