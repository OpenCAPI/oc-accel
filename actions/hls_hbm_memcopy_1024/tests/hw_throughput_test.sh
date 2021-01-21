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
duration="SHORT"

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
    echo "    [-C <card>] card number to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-N ] No Interrupt and poll done bit"
    echo "    [-d SHORT/NORMAL/LONG/INCR] 256 / 256KB / 256MB / INCR transfer tests"
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
    #oc_maint -C ${snap_card} -v || exit 1;
#    snap_peek -C ${snap_card} 0x0 || exit 1;
#    snap_peek -C ${snap_card} 0x8 || exit 1;
#    echo
fi

#### MEMCOPY ##########################################################

function test_memcopy {
echo "---------------- Testing size $1: --------------"
local size=$1
if [ ${size} -gt 1073741824 ]; then
    blk_count=$((${size}/1073741824))
    echo "$blk_count"
        unit_name="GB"
        echo "Creating a" $blk_count "GBytes file ... takes several minutes or so ..."
        dd if=/dev/urandom of=temp_A.bin count=${blk_count} bs=1G 2> dd.log
elif [ ${size} -gt 1048576 ]; then
    blk_count=$((${size}/1048576))
        unit_name="MB"
        echo "Creating a" $blk_count "MBytes file ... takes a minute or so ..."
        dd if=/dev/urandom of=temp_A.bin count=${blk_count} bs=1M 2> dd.log
elif [ ${size} -gt 1024 ]; then
    blk_count=$((${size}/1024))
        unit_name="KB"
        echo "Creating a" $blk_count "KBytes file ... "
        dd if=/dev/urandom of=temp_A.bin count=${blk_count} bs=1K 2> dd.log
else
        blk_count=$size
        unit_name="B"
        echo "Creating a" $blk_count "Bytes file ... "
        dd if=/dev/urandom of=temp_A.bin count=${blk_count} bs=1 2> dd.log
fi

#    echo "Doing snap_hbm_memcopy benchmarking with" ${size} "bytes transfers ... "

    if [ ! -f "${ACTION_ROOT}/sw/snap_hbm_memcopy" ]; then
       echo "ERROR: please compile 'snap_hbm_memcopy' before execution (or run 'make apps')"
       exit 1
    fi

    echo -n "Read from Host Memory to FPGA ... "
    cmd="snap_hbm_memcopy -C${snap_card} ${noirq}     \
        -i temp_A.bin    >>    \
        hbm_memcopy_throughput.log 2>&1"
    echo ${cmd} >> hbm_memcopy_throughput.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hbm_memcopy_throughput.log"
        exit 1
    fi
    echo "ok"

    echo -n "Write from FPGA to Host Memory ... "
    cmd="snap_hbm_memcopy -C${snap_card} ${noirq}    \
        -o temp_A.out        \
        -s ${size}     >>    \
        hbm_memcopy_throughput.log 2>&1"
    echo ${cmd} >> hbm_memcopy_throughput.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hbm_memcopy_throughput.log"
        exit 1
    fi
    echo "ok"

    if [ ${size} -gt 268435456 ]; then
      echo "Skipping test greater than 256MB with HBM"
    else
      echo -n "Read from HBM Memory to FPGA ... "
      cmd="snap_hbm_memcopy -C${snap_card}     ${noirq}\
        -A HBM_P0 -a 0x0    \
        -s ${size}     >>    \
        hbm_memcopy_throughput.log 2>&1"
      echo ${cmd} >> hbm_memcopy_throughput.log
      eval ${cmd}
      if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hbm_memcopy_throughput.log"
        exit 1
      fi
      echo "ok"
  
      echo -n "Write from FPGA to Card DDR Memory ... "
      cmd="snap_hbm_memcopy -C${snap_card}     ${noirq}\
        -D HBM_P0 -d 0x0    \
        -s ${size}     >>    \
        hbm_memcopy_throughput.log 2>&1"
      echo ${cmd} >> hbm_memcopy_throughput.log
      eval ${cmd}
      if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check hbm_memcopy_throughput.log"
        exit 1
      fi
      echo "ok"
    fi
}

rm -f hbm_memcopy_throughput.log
touch hbm_memcopy_throughput.log

if [ "$duration" = "SHORT" ]; then
    size=256
    test_memcopy ${size}
fi
if [ "$duration" = "NORMAL" ]; then
    size=262144
    test_memcopy ${size}
fi
if [ "$duration" = "LONG" ]; then
    size=268435456
    test_memcopy ${size}
fi

#echo
#echo "READ/WRITE Performance Results"
#grep "memcopy of" hbm_memcopy_throughput.log
#echo

############## INCR Also do some awk processing ##############
if [ "$duration" = "INCR" ]; then
    size=512
    exp=9
  # -lt 31 means 1GB
  # -lt 32 means 2GB
  # -lt 33 means 4GB
  # -lt 34 means 8GB
    while [ $exp -lt 31 ]
    do
        test_memcopy ${size}
        exp=$(($exp + 1))
        size=$(($size * 2))
    done
fi
#Print build date and version
echo
echo -n "Git Version: "
snap_peek -C ${snap_card} 0x0 || exit 1;
echo -n "Build Date:  "
snap_peek -C ${snap_card} 0x8 || exit 1;
${ACTION_ROOT}/tests/process.awk hbm_memcopy_throughput.log

echo "ok"

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
