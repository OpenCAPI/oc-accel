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
duration="SHORT"
size=10

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
OCACCEL_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "OCACCEL_ROOT :   ${OCACCEL_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  sudo ./hw_test.sh"
    echo "  For basic memcopy functions. Use hw_throughput_test.sh for bandwidth."
    echo "    [-C <card>] card to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-N ] not use interrupt"
    echo "    [-duration SHORT/NORMAL] run tests (default is SHORT, which is also good for simulation)"
    echo
}

while getopts ":C:t:d:Nh" opt; do
    case $opt in
    C)
    ocaccel_card=$OPTARG;
    ;;
    t)
    export OCACCEL_TRACE=$OPTARG;
    ;;
    d)
    duration=$OPTARG;
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

export PATH=$PATH:${OCACCEL_ROOT}/software/tools:${ACTION_ROOT}/sw

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$OCACCEL_CONFIG" ]; then
    echo "Get CARD VERSION"
    oc_maint -C ${ocaccel_card} -v || exit 1;
    ocaccel_peek -C ${ocaccel_card} 0x0 || exit 1;
    ocaccel_peek -C ${ocaccel_card} 0x8 || exit 1;
    echo
fi

#### MEMCOPY ##########################################################

function test_memcopy {
    local size=$1
    local noirq=$2

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing ocaccel_memcopy ${size} bytes ... "
    cmd="ocaccel_memcopy -C${ocaccel_card} ${noirq} -X    \
        -i ${size}_A.bin    \
        -o ${size}_A.out >>    \
        ocaccel_memcopy.log 2>&1"
    echo ${cmd} >> ocaccel_memcopy.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check ocaccel_memcopy.log"
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
rm -f ocaccel_memcopy.log
touch ocaccel_memcopy.log

if [ "$duration" = "SHORT" ]; then

    for (( size=64; size<=512; size*=2 )); do
    test_memcopy ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<65536; size*=2 )); do
    test_memcopy ${size}
    done
fi

echo
echo "Print time: (small size doesn't represent performance)"
grep "memcopy of" ocaccel_memcopy.log
echo

#### MEMCOPY to and from CARD DDR #############

function test_memcopy_with_ddr {
    local size=$1

    dd if=/dev/urandom of=${size}_B.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing ocaccel_memcopy to ddr (aligned) ${size} bytes ... "
    cmd="ocaccel_memcopy -C${ocaccel_card}  ${noirq}  \
        -i ${size}_B.bin    \
        -d 0x0 -D CARD_DRAM >>  \
        ocaccel_memcopy_with_ddr.log 2>&1"
    echo ${cmd} >> ocaccel_memcopy_with_ddr.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, check ocaccel_memcopy_with_ddr.log"
        exit 1
    fi
    
    echo -n "Doing ocaccel_memcopy from ddr (aligned) ${size} bytes ... "
    cmd="ocaccel_memcopy -C${ocaccel_card}   ${noirq} \
        -o ${size}_B.out    \
        -a 0x0 -A CARD_DRAM -s ${size} >>  \
        ocaccel_memcopy_with_ddr.log 2>&1"
    echo ${cmd} >> ocaccel_memcopy_with_ddr.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failedi, check ocaccel_memcopy_with_ddr.log"
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
rm -f ocaccel_memcopy_with_ddr.log
touch ocaccel_memcopy_with_ddr.log

if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<512; size*=2 )); do
    test_memcopy_with_ddr ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<65536; size*=2 )); do
    test_memcopy_with_ddr ${size}
    done
fi

echo
echo "Print time: (small size doesn't represent performance)"
grep "memcopy of" ocaccel_memcopy_with_ddr.log
echo

