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

#
# Simple tests for example snap actions.
#

verbose=0
snap_card=0
iteration=1
ddr_test=0
duration="NORMAL"

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

FUNC="${SNAP_ROOT}/actions/hdl_example/sw/snap_example"

function test () # $1 = card, $2 = action, $3 = 4k or 64, $4 = min_align, $5 = dma_size
{
	local card=$1
	local action=$2
	local size=$3
	local min_align=$4
	local dma_size=$5
	local block_step=$(($dma_size/64))
	local tests=0

	if [ $block_step -eq "0" ]; then
		block_step=1
	fi
	for align in 4096 2048 1024 512 256 128 64 ; do
		tests=0
		echo -n "Testing Action $action Align $align for (1...128) $size Byte "
		if [ $align -lt $min_align ]; then
			echo "-> Can not Execute"
			continue
		fi
		for (( ln=1; ln<=128; ln+=1 )); do
			if [ $size == 64 ] ; then
				b64=$(($ln*block_step))
				cmd="${FUNC} -a $action -A $align -C ${card} -S 0 -B $b64"
			else
				cmd="${FUNC} -a $action -A $align -C ${card} -S $ln -B 0"
			fi
			eval ${cmd}
			if [ $? -ne 0 ]; then
        			echo "cmd: ${cmd}"
        			echo "failed"
        			exit 1
			fi
			tests=$(($tests+1))
		done
		echo " $tests Test done"
	done
}

function test_sb () # $1 = card, $2=action, $3 = min_align, $4 = dma_size
{
	local card=$1
	local action=$2
	local min_align=$3
	local dma_size=$4
	local block_step=$(($dma_size/64))
	local tests=0

	if [ $block_step -eq "0" ]; then
		block_step=1
	fi

	for align in 4096 2048 1024 512 256 128 64 ; do		# Align
		tests=0
		echo -n "Testing Action $action Align $align  4K=(1..16) 64B=($block_step..$((128*$block_step))) "
		if [ $align -lt $min_align ]; then
			echo " -> Can not Execute"
			continue
		fi
		for s in ` seq 1 16 `; do		# 4 K Blocks
			echo -n "."
			for (( b=$block_step; b<=128*$block_step; b+=$block_step )); do
				cmd="${FUNC} -a $action -A $align -C ${card} -S $s -B $b"
				eval ${cmd}
				if [ $? -ne 0 ]; then
        				echo "cmd: ${cmd}"
        				echo "failed"
        				exit 1
				fi
				tests=$(($tests+1))
			done
		done
		echo " $tests Tests done"
	done
}

function test_bs () # $1 = card, $2 = action, $3 = min_align, $4 = dma_size
{
	local card=$1
	local action=$2
	local min_align=$3
	local dma_size=$4
	local block_step=$(($dma_size/64))
	local tests=0

	if [ $block_step -eq "0" ]; then
		block_step=1
	fi

	for align in 4096 2048 1024 512 256 128 64 ; do		# Align
		tests=0
		echo -n "Testing Action $action Align $align  64B=($block_step..$((128*$block_step))) 4K=(1..16) "
		if [ $align -lt $min_align ]; then
			echo -e "-> Can not Execute"
			continue
		fi
		for (( b=$block_step; b<=64*$block_step; b+=$block_step )); do
			echo -n "."
			for s in ` seq 1 16 `; do	# 4K Blocks
				cmd="${FUNC} -a $action -A $align -C ${card} -S $s -B $b"
				eval ${cmd}
				if [ $? -ne 0 ]; then
        				echo "cmd: ${cmd}"
        				echo "failed"
        				exit 1
				fi
				tests=$(($tests+1))
			done
		done
		echo " $tests Tests done"
	done
}

function test_rnd () # $1 = card, $2 = action, $3 = min_align, $4 = dma_size
{
	local card=$1
	local action=$2
	local min_align=$3
	local dma_size=$4
	local block_step=$(($dma_size/64))
	local tests=0

	if [ $block_step -eq "0" ]; then
		block_step=1
	fi

	for align in 4096 1024 2048 512 256 128 64 ; do
		tests=0
		echo -n "Testing Action $action Align $align 1000 x 64B=random 4K=random "
		if [ $align -lt $min_align ]; then
			echo -e "-> Can not Execute"
			continue
		fi
		for n in ` seq 1 1000 `; do
			local size=$(( $RANDOM % 64 ))
			local block=$(( $RANDOM*$block_step % 64 ))
			if [ $size = 0 ] && [ $block = 0 ] ; then
				block=$block_step	
			fi
			cmd="${FUNC} -a $action -A $align -C ${card} -S $size -B $block"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
			tests=$(($tests+1))
		done
		echo " $tests Tests done"
	done
}

function usage() {
	echo "SNAP Example Action 10140000 Basic Test's"
	echo "Usage:"
	echo "  $PROGRAM"
	echo "    [-C <card>]        card to be used for the test"
	echo "    [-t <trace_level>]"
	echo "    [-i <iteration>]"
	echo "    [-D] Perform DDR test"
        echo "    [-d] use SHORT for simulation case or NORMAL for hardware test case"
}

#
# Main start here
#
PROGRAM=$0

while getopts "C:t:i:d:hD" opt; do
	case $opt in
	C)
	snap_card=$OPTARG;
	;;
	t)
	SNAP_TRACE=$OPTARG;
	;;
	i)
	iteration=$OPTARG;
	;;
	d)
	duration=$OPTARG;
	;;
	D)
	ddr_test=1;
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

MIN_ALIGN=1
MIN_BLOCK=1
echo -n " (Align: $MIN_ALIGN Min Block: $MIN_BLOCK) "
if [ "$duration" = "SHORT" ] ; then   # Simulation test case
	timeoutsim=120
	endsimu=20
else
	echo ">>> To avoid timeout, -d SHORT should be used for simulation <<<"
	timeoutsim=2	# hardware test case
	endsimu=60
fi

if [ ! -f "${FUNC}" ]; then
        echo "ERROR: please compile 'snap_example' before execution (or run 'make apps')"
        exit 1
fi

for ((iter=1;iter <= iteration;iter++))
{
	echo "Iteration $iter of $iteration on CARD[$snap_card]"
	echo "Testing Action 1 from 20  msec to 10*$endsimu msec in 10*$endsimu msec steps"
        echo "timeoutsim = $timeoutsim"
	cmd="${FUNC} -a 1 -C${snap_card} -e $endsimu -t $timeoutsim"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi

	if [ "$duration" = "SHORT" ]; then 
		echo "# Tests with interrupts or sb bs and rnd are not evaluated in SHORT mode"
	else
	       	
	echo "Testing Action 1 from 20 msec to 10*$endsimu msec in 10*$endsimu msec steps with Interrupts"
	cmd="${FUNC} -a 1 -C${snap_card} -e $endsimu -t $timeoutsim -I"
	eval ${cmd}
		if [ $? -ne 0 ]; then
			echo "cmd: ${cmd}"
			echo "failed"
		exit 1
		fi
		
		test    $snap_card 2 4k $MIN_ALIGN $MIN_BLOCK
		test    $snap_card 2 64 $MIN_ALIGN $MIN_BLOCK
		test_sb $snap_card 2    $MIN_ALIGN $MIN_BLOCK
		test_bs $snap_card 2    $MIN_ALIGN $MIN_BLOCK
		test_rnd $snap_card 2   $MIN_ALIGN $MIN_BLOCK
	fi

	# Check SDRAM
	if [ $ddr_test -eq 1 ]; then
		test     $snap_card 6 4k $MIN_ALIGN $MIN_BLOCK
		test     $snap_card 6 64 $MIN_ALIGN $MIN_BLOCK
		test_sb  $snap_card 6    $MIN_ALIGN $MIN_BLOCK
		test_bs  $snap_card 6    $MIN_ALIGN $MIN_BLOCK
		test_rnd $snap_card 6    $MIN_ALIGN $MIN_BLOCK
	fi
}
echo "---------->>>> Exit Good <<<<<<--------------"
exit 0
