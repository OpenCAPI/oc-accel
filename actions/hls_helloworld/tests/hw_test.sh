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
duration="NORMAL"

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
OCACCEL_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "OCACCEL_ROOT :   ${OCACCEL_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  hw_test.sh"
    echo "    [-C <card>] card to be used for the test"
#    echo "    [-t <trace_level>]"
#    echo "    [-duration SHORT/NORMAL/LONG] run tests"
    echo
}

while getopts ":C:t:d:h" opt; do
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

####iHELLOWORLD ##########################################################

function test_helloworld {
    cmd="echo \"Hello world. This is my first CAPI OCACCEL experience. It's real fun.\" > tin"
    echo "cmd: ${cmd}"
    eval ${cmd}
    cmd="echo \"HELLO WORLD. THIS IS MY FIRST CAPI OCACCEL EXPERIENCE. IT'S REAL FUN.\" > tCAP"
    echo "cmd: ${cmd}"
    eval ${cmd}
    echo -n "Doing ocaccel_helloworld "
    cmd="ocaccel_helloworld -C${ocaccel_card} -i tin -o tout >> ocaccel_helloworld.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat ocaccel_helloworld.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff tout tCAP 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "                 TEST FAILED !"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "       Out and expected files are different!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	exit 1
    fi
    echo "ok"

}

rm -f ocaccel_helloworld.log
touch ocaccel_helloworld.log

# Whatever duration is, we run the test
# duration is used to run short test in simulation for example
# helloworld is short by nature, so we can ignore duration setting
# if [ "$duration" = "NORMAL" ]; then
  test_helloworld 
#  fi

rm -f *.bin *.bin *.out
echo "------------------------------------------------------"
echo "Test OK"
echo "------------------------------------------------------"
exit 0
