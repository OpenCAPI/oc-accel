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
    echo "    [-d SHORT/NORMAL] run tests (default is SHORT, which is also good for simulation)"
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
#    oc_maint -C ${snap_card} -v || exit 1;
#    snap_peek -C ${snap_card} 0x0 || exit 1;
#    snap_peek -C ${snap_card} 0x8 || exit 1;
#    snap_peek 0x0030 |grep 30|cut -c22-23
    echo
#Print build date and version
echo
echo -n "Git Version: "
snap_peek -C ${snap_card} 0x0 || exit 1;
echo -n "Build Date:  "
snap_peek -C ${snap_card} 0x8 || exit 1;

snap_peek -C ${snap_card} 0x30 || exit 1;
echo -n "Type of the card: "
card_type=`snap_peek -C ${snap_card} 0x30 |grep 30|cut -c26-27|| exit 1;`
#echo $card_type
if [ $card_type -eq "31" ]; then
   echo "AD9V3 card"
elif [ $card_type -eq "32" ]; then
   echo "AD9H3 card"
elif [ $card_type -eq "35" ]; then
   echo "AD9H335 card"
elif [ $card_type -eq "33" ]; then
   echo "AD9H7 card"
elif [ $card_type -eq "34" ]; then
   echo "BW250SOC card"
else
   echo  $card_type " (unknown card number)"
fi

#for HBM cards
if [ $card_type -eq "32" ] || [ $card_type -eq "33" ] || [ $card_type -eq "35" ]; then
  echo -n "HBM card detected"
  echo -n "Number of AXI HBM IF: "
  hbm_if_num_hexa=`snap_peek -C ${snap_card} 0x30 |grep 30|cut -c22-23 || exit 1;`
  hbm_if_num=$(printf '%#x' "0x$hbm_if_num_hexa")
  printf "%d\n" $hbm_if_num
  if [ $hbm_if_num == 0 ]; then
     echo "ERROR: Almost 1 HBM is necessary for tests"
     exit 1;
  fi
fi

fi
#### MEMCOPY ##########################################################

function test_memcopy {
    local size=$1
    local noirq=$2

    if [ ! -f "${ACTION_ROOT}/sw/snap_hbm_memcopy" ]; then
       echo "ERROR: please compile 'snap_hbm_memcopy' before execution (or run 'make apps')"
       exit 1
    fi

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing snap_hbm_memcopy ${size} bytes ... "
    cmd="snap_hbm_memcopy -C${snap_card} ${noirq} -X    \
        -i ${size}_A.bin    \
        -o ${size}_A.out >>    \
        snap_hbm_memcopy.log 2>&1"
    echo ${cmd} >> snap_hbm_memcopy.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, please check snap_hbm_memcopy.log"
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
rm -f snap_hbm_memcopy.log
touch snap_hbm_memcopy.log

echo "-----------------------------------------------------"
echo "Running simple host memory test in \"$duration\" mode..."
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
echo
echo
echo "Summary of execution times"
echo "NOTE : In simulation reported times are greater compared to POWER actual operation"
grep "memcopy of" snap_hbm_memcopy.log
echo
echo "End of simple host memory test in \"$duration\" mode."
echo "----------------------------------------------------"

#### MEMCOPY to and from HBM #############

function test_memcopy_with_hbm {
    local size=$1
    if [ ! -f "${ACTION_ROOT}/sw/snap_hbm_memcopy" ]; then
       echo "ERROR: please compile 'snap_hbm_memcopy' before execution (or run 'make apps')"
       exit 1
    fi

    dd if=/dev/urandom of=${size}_B.bin count=1 bs=${size} 2> dd.log

    echo "Doing snap_hbm_memcopy from HOST memory to hbm_p0 (aligned) ${size} bytes ... "
    cmd="snap_hbm_memcopy -C${snap_card}  ${noirq}  \
        -i ${size}_B.bin    \
        -d 0x0 -D HBM_P0 >>  \
        snap_memcopy_with_hbm.log 2>&1"
    echo ${cmd} >> snap_memcopy_with_hbm.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, check snap_memcopy_with_hbm.log"
        exit 1
    fi

    for (( i=0, j=1; i < hbm_if_num-1; i++, j++ ))
    do
       echo "Doing snap_hbm_memcopy from hbm_p$i to hbm_p$j (aligned) ${size} bytes ... "
       cmd="snap_hbm_memcopy -C${snap_card}   ${noirq} \
           -a 0x0 -A HBM_P$i   \
           -d 0x0 -D HBM_P$j -s ${size} >>  \
           snap_memcopy_with_hbm.log 2>&1"
       echo ${cmd} >> snap_memcopy_with_hbm.log
       eval ${cmd}
       if [ $? -ne 0 ]; then
           echo "cmd: ${cmd}"
           echo "failed, check snap_memcopy_with_hbm.log"
           exit 1
       fi
    done

    last_hbm="$i"
    echo "Doing snap_hbm_memcopy from hbm_p$last_hbm to HOST memory (aligned) ${size} bytes ... "
    cmd="snap_hbm_memcopy -C${snap_card}   ${noirq} \
        -a 0x0 -A HBM_P$last_hbm -s ${size}  \
        -o ${size}_B.out   >> \
        snap_memcopy_with_hbm.log 2>&1"
    echo ${cmd} >> snap_memcopy_with_hbm.log
    eval ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd: ${cmd}"
        echo "failed, check snap_memcopy_with_hbm.log"
        exit 1
    fi
    echo "ok"

    echo "Check results ... "
    diff ${size}_B.bin ${size}_B.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "failed"
        echo "  ${size}_B.bin ${size}_B.out are different!"
        exit 1
    fi
    echo "ok"

}


################ TEST Begins ##################
rm -f snap_memcopy_with_hbm.log
touch snap_memcopy_with_hbm.log
echo
echo "----------------------------------------------------"
echo "Running HBM tests in \"$duration\" mode..."
if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<512; size*=2 )); do
    test_memcopy_with_hbm ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<65536; size*=2 )); do
    test_memcopy_with_hbm ${size}
    done
fi

echo
echo
echo "Summary of execution times"
echo "NOTE, in simulation reported times are greater compared to POWER actual operation"
grep "memcopy of" snap_memcopy_with_hbm.log
echo
echo
echo "End of HBM memory test in \"$duration\" mode."
echo "----------------------------------------------------"

