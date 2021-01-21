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
size=10

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "SNAP_ROOT :   ${SNAP_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  sudo ./hw_test.sh"
    echo "  For basic memcopy functions. Use hw_throughput_test.sh for bandwidth."
    echo "    [-C <card>] card to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-N ] not use interrupt"
    echo "    [-d SHORT/NORMAL/LONG] run tests (default is NORMAL, change to SHORT for simulation)"
    echo
}

while getopts ":C:t:d:Nh" opt; do
    case $opt in
    C)
    snap_card=$OPTARG;
    ;;
    t)
    export SNAP_TRACE=$OPTARG;
    ;;
    d)
    duration=$OPTARG;
    echo "test duration :    $duration"
    ;;
    N)
    noirq=" -N ";
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
#    oc_maint -C ${snap_card} -v || exit 1;
#    snap_peek -C ${snap_card} 0x0 || exit 1;
#    snap_peek -C ${snap_card} 0x8 || exit 1;
    echo
fi

#### MEMCOPY ##########################################################

function test_memcopy {
    local size=$1
    local noirq=$2

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    if [ ! -f "${ACTION_ROOT}/sw/snap_memcopy" ]; then
       echo "ERROR: please compile 'snap_memcopy' before execution (or run 'make apps')"
       exit 1
    fi

    echo -n "Doing snap_memcopy ${size} bytes from host mem to host mem through FPGA buffer ... "
    cmd="snap_memcopy -C${snap_card} ${noirq} -X -t 720   \
        -i ${size}_A.bin    \
        -o ${size}_A.out >>    \
        snap_memcopy.log 2>&1"
    echo ${cmd} >> snap_memcopy.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check snap_memcopy.log"
        exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff ${size}_A.bin ${size}_A.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "failed"
        echo "  ${size}_A.bin ${size}_A.out are different!"
        exit 1
    fi
    echo "ok"

}



################  Test Begins #####################
rm -f snap_memcopy.log
touch snap_memcopy.log

if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<128; size*=2 )); do
    test_memcopy ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<65536; size*=2 )); do
    test_memcopy ${size}
    done
fi

if [ "$duration" = "LONG" ]; then
    for (( size=64; size<268435457; size*=2 )); do
    test_memcopy ${size}
    done
fi

echo
grep "memcopy of" snap_memcopy.log
echo

#### MEMCOPY to and from CARD LOCAL MEMORY (DDR or HBM) #####

function test_memcopy_with_local_mem {
    local size=$1

    dd if=/dev/urandom of=${size}_B.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing snap_memcopy host mem to ddr (aligned) ${size} bytes ... "
    cmd="snap_memcopy -C${snap_card}  ${noirq}  -t 720 \
        -i ${size}_B.bin    \
        -d 0x0 -D LCL_MEM0 >>  \
        snap_memcopy_with_ddr.log 2>&1"
    echo ${cmd} >> snap_memcopy_with_ddr.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, check snap_memcopy_with_ddr.log"
        exit 1
    fi
    
    echo -n "Doing snap_memcopy from ddr to host mem (aligned) ${size} bytes ... "
    cmd="snap_memcopy -C${snap_card}   ${noirq} -t 720 \
        -o ${size}_B.out    \
        -a 0x0 -A LCL_MEM0 -s ${size} >>  \
        snap_memcopy_with_ddr.log 2>&1"
    echo ${cmd} >> snap_memcopy_with_ddr.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failedi, check snap_memcopy_with_ddr.log"
        exit 1
    fi
    echo "ok"
    
    echo -n "Check results ... "
    diff ${size}_B.bin ${size}_B.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "failed"
        echo "  ${size}_B.bin ${size}_B.out are different!"
        exit 1
    fi
    echo "ok"

}


################ TEST Begins ##################
rm -f snap_memcopy_with_ddr.log
touch snap_memcopy_with_ddr.log

if [ "$duration" = "SHORT" ]; then
    echo "    Mem module test is not run in SHORT case"
#    for (( size=64; size<128; size*=2 )); do
#    test_memcopy_with_local_mem ${size}
#    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<65536; size*=2 )); do
    test_memcopy_with_local_mem ${size}
    done
fi

if [ "$duration" = "LONG" ]; then
    for (( size=64; size<268435457; size*=2 )); do
    test_memcopy_with_local_mem ${size}
    done
fi

echo
grep "memcopy of" snap_memcopy_with_ddr.log
echo

