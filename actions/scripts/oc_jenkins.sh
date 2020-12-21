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
# Jenkins Test for SNAP
#

# SNAP framework example
function test_10142000
{
	local card=$1
	local accel=$2
	mytest="./actions/hdl_example"

	echo "TEST HDL Example Action on Accel: $accel[$card] ..."
	#mytest/tests/10140000_test.sh -C $card
	$mytest/tests/hw_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_ddr_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_set_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_nvme_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	return 0
}

function test_all_actions() # $1 = card, $2 = accel
{
	local card=$1
	local accel=$2

	RC=0;
	# Get SNAP Action number from Card

	# MY_ACTION=`./software/tools/oc_maint -C $card -m 1`
	# oc_maint -m1 not working for the moment ==> Using the following as a workaround
	MY_ACTION=`./software/tools/oc_maint -C $card -v | grep -A10 -e "-+-" | grep -ve "-+-" | awk '{print $2}'`

	for action in $MY_ACTION ; do
		run_test=1;
		case $action in
		*"10142000") # HDL Example
			cmd="./actions/hdl_example/tests/hw_test.sh"
			#test_10142000 $card $accel
			#RC=$?
			#run_test=0
		;;
		*"10142002") # HDL Single Engine
			cmd="./actions/hdl_single_engine/tests/hw_test.sh"
		;;
		*"1014300b") # HLS Memcopy 1024
			cmd="./actions/hls_memcopy_1024/tests/hw_test.sh"
		;;
		*"1014300c") # HLS HBM Memcopy
			cmd="./actions/hls_hbm_memcopy_1024/tests/hw_test.sh"
		;;
		*"10143008") # HLS Hello World  512 bits wide bus
			cmd="./actions/hls_helloworld_512/tests/hw_test.sh"
		;;
                *"10143009") # HLS Hello World 1024 bits wide bus
                        cmd="./actions/hls_helloworld_1024/tests/hw_test.sh"
                ;;
		*"1014300d") # HLS Image Filter
                        cmd="./actions/hls_image_filter/tests/hw_test.sh"
                ;;
	 	*"10143010") # HLS UDP
                        cmd="./actions/hls_udp_512/tests/hw_test.sh"
                ;;
                *"1014300e") # HLS Memcopy 512
                        cmd="./actions/hls_memcopy_512/tests/hw_test.sh"
                ;;
                *"1014300f") # HLS Decimal multiplication 512
                        cmd="./actions/hls_decimal_mult/tests/hw_test.sh"
                ;; 
		*)
			echo "Error: Action: $action is not valid !"
			run_test=0
		esac

		# Check run_test flag and check if test case is there
		if [ $run_test -eq 1 ]; then
			if [ -f $cmd ]; then
				cmd=$cmd" -C $card -d NORMAL"
				echo "RUN: $cmd on $accel[$card] Start"
				eval ${cmd}
				RC=$?
				echo "RUN: $cmd on $accel[$card] Done RC=$RC"
                        fi
			else
				echo "Error: No Test case found for Action: $action on $accel[$card]"
				echo "       Missing File: $cmd"
				RC=99
		fi
	done
	echo "$0 return code is : RC=$RC"
	return $RC
}

function test_soft()
{
	local accel=$1
	local card=$2

	echo "Testing Software on Accel: $accel[$card] ..."
	./software/tools/oc_maint -C $card -v
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	test_all_actions $card $accel
	return $?
}

function test_hard()
{
	local accel=$1
	local card=$2
	local IMAGE=$3
	local IMAGE2=$4

	echo "`date` UPDATING Start"
	echo "         Accel: $accel[$card] Image: $IMAGE"
	pushd ../oc-utils > /dev/null
	if [ $? -ne 0 ]; then
		echo "Error: Can not start oc-flash-script.sh"
		exit 1
	fi

	try_to_flash=0
	while [ 1 ]; do
		wait_flag=0
		if [[ $accel != "OC-AD9V3" ]] && [[ $accel != "OC-AD9H3" ]] && [[ $accel != "OC-AD9H7" ]]; then
		     echo "executing non SPI case : sudo ./oc-flash-script.sh -f -C $card -f $IMAGE"
		sudo ./oc-flash-script.sh -f -C $card -f $IMAGE
		else 
                     echo "executing SPI case : sudo ./oc-flash-script.sh -f -C $card $IMAGE $IMAGE2"
                     sudo ./oc-flash-script.sh -f -C $card $IMAGE $IMAGE2
	        fi
		RC=$?
		if [ $RC -eq 0 ]; then
			break
		fi
		if [ $RC -eq 99 ]; then
			# I do get Busy from oc_flash tool if the flash lock is in use
			# Wait again or exit for Flashing
			# Flashing takes about 90 to 100 sec
			try_to_flash=$((try_to_flash+1))
			if [ $try_to_flash -gt 20 ]; then
				echo "`date` ERROR: Timeout While Waiting to Flash Accel: $accel[$card]"
				popd > /dev/null
				return $RC
			fi
			echo "`date`         ($try_to_flash of 20) Wait: Other oc-flash-script.sh in progress"
			wait_flag=1
			sleep 10
		else
			echo "`date` ERROR: I was not able to Flash Image: $IMAGE on Accel: $accel[$card]"
			popd > /dev/null
			mv $IMAGE $IMAGE.fault_flash
			return $RC
		fi
	done

	popd > /dev/null
	echo "`date` UPDATING done for $accel[$card]"
	if [ $wait_flag -eq 1 ]; then
		echo "Delay some time because of pending Flash"
		sleep 15          # Allow other test to Flash
		echo "`date` Testing Accel: $accel[$card]"
	fi
        sleep 5          # Allow some time to recover cards

	./software/tools/snap_peek -C $card 0x0 -d2
	RC=$?
	if [ $RC -ne 0 ]; then
		echo "moving $IMAGE to $IMAGE.fault_peek"
		mv $IMAGE $IMAGE.fault_peek
		return $RC
	fi
	echo "CONFIG Accel: $accel[$card] ..."
	./software/tools/oc_maint -C $card -v
	RC=$?
	if [ $RC -ne 0 ]; then
		echo "moving $IMAGE to $IMAGE.fault_config"
		mv $IMAGE $IMAGE.fault_config
		return $RC
	fi
	test_all_actions $card $accel
	RC=$?
	if [ $RC -eq 0 ]; then
		echo "moving $IMAGE to $IMAGE.good"
		mv $IMAGE $IMAGE.good
	else
		echo "moving $IMAGE to $IMAGE.fault_test"
		mv $IMAGE $IMAGE.fault_test
	fi
	return $RC
}

function usage() {
	echo "Usage: $PROGRAM -D [] -A [] -F [] -f []"
	echo "    [-D <Target Dir>]"
	echo "    [-A <OC-AD9V3>     : Select AlphaData OC-AD9V3 Card"
	echo "    [-A <OC-AD9H3>     : Select AlphaData OC-AD9H3 Card"
	echo "    [-A <OC-AD9H7>     : Select AlphaData OC-AD9H7 Card"
	echo "    [-A <OC-BW250SOC>  : Select AlphaData OC-BW250SOC Card"
	echo "        <ALL>    : Select ALL Cards"
	echo "    [-F <Image>  : Set Image file for Accelerator -A"
	echo "    [-f <Image>  : Set SPI secondary Image file for Accelerator -A"
	echo "                   -A ALL is not valid if -F is used"
	echo "    [-C <0,1,2,3]: Select Card 0,1,2 or 3"
	echo "        Select the Card# for test."
	echo "    [-h] Print this help"
	echo "    Option -D must be set"
	echo "    following combinations can happen"
	echo "    1.) Option -A [OC-AD9V3, OC-AD9H3, OC-AD9H7, OC-BW250SOC] and -F is set"
	echo "        for Card in all Accelerators (-A)"
	echo "           => Image will be flashed on Card (using oc-flash-script and reset routines)"
	echo "           => and Software Test will then run on Card"
	echo "    2.) Option -A [OC-AD9V3, OC-AD9H3, OC-AD9H7, OC-BW250SOC]"
	echo "        for Card in all given Accelerators (-A)"
	echo "           => Software Test will run on Card (using current FPGA content)"
	echo "    3.) Option -A ALL"
	echo "        for each Card and for all Accelerators"
	echo "           => Software Test will run on Accelerator and Card"
}

#
# Main starts here
#
# Note: use bash option "set -f" when passing wildcards before
#       starting this script.
#
# -------------------------------------------------------
#VERSION=1.0 # creation for OC-AD9V3, OC-AD9H3, OC-AD9H7 cards
VERSION=1.1 # addition of OC-BW350SOC card
# --------------------------------------------------------
PROGRAM=$0
BINFILE=""
BINFILE2=""
accel="ALL"
CARD="-1"   # Select all Cards in System

echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< OC-JENKINS TEST>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "oc_jenkins.sh version : $VERSION"
echo "`date` Test Starts On `hostname`"
echo "Arg#='$#'"
for i in "$@"
do
 echo "param'=$i"
done
echo ""

while getopts "D:A:F:f:C:h" opt; do
	case $opt in
	D)
		TARGET_DIR=$OPTARG;
		;;
	A)
		accel=$OPTARG;
		if [[ $accel != "OC-AD9V3"    ]] &&
		   [[ $accel != "OC-AD9H3"    ]] &&
		   [[ $accel != "OC-AD9H7"    ]] &&
		   [[ $accel != "OC-BW250SOC" ]] &&
		   [[ $accel != "ALL"         ]]; then
			echo "Error:  Option -A $OPTARG is not valid !" >&2
			echo "Expect: [OC-AD9V3, OC-AD9H3, OC-AD9H7, OCBW250SOC or ALL]" >&2
			exit 1
		fi
		;;
	F)
		BINFILE=$OPTARG;
		;;
	f)
                BINFILE2=$OPTARG;
                ;;	
	C)
		CARD=$OPTARG;
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

MY_DIR=`basename $PWD`
echo "Testing in  : $MY_DIR"
echo "Using Accel : $accel"
echo "Using Card# : $CARD"
echo "Using Image : $BINFILE"
if [[ $accel == "OC-AD9V3" ]] || [[ $accel == "OC-AD9H3" ]] || [[ $accel == "OC-AD9H7" ]]; then
echo "Using sec Image : $BINFILE2"
fi

if [[ $TARGET_DIR != $MY_DIR ]] ; then
	echo "Target Dir:  $TARGET_DIR"
	echo "Current Dir: $MY_DIR"
	echo "Error: Target and Current Dir must match. Please fix with -D Option"
	exit 1;
fi
echo "Source PATH and LD_LIBRARY_PATH"
. ./snap_path.sh

test_done=0
if [[ $accel != "ALL" ]]; then
	if [[ $BINFILE != "" ]]; then
		echo "Flash and test Accel: $accel Card: $CARD using: $BINFILE"
		for IMAGE in `ls -tr $BINFILE 2>/dev/null`; do
			if [ ! -f $IMAGE ]; then
				echo "Error: Can not locate: $BINFILE"
				exit 1
			fi
			echo "---> Test Image# $test_done File: $IMAGE on $accel Card: $CARD"
			if [ $CARD -eq "-1" ]; then
				# Get all Cards in this System for Accel type i have to test
				MY_CARDS=`./software/tools/oc_find_card -A $accel`
				if [ $? -eq 0 ]; then
					echo "Error: Can not find $accel Card in `hostname` !"
					exit 1;
				fi
				for card in $MY_CARDS ; do
					if [[ $accel != "OC-AD9V3" ]] && [[ $accel != "OC-AD9H3" ]] && [[ $accel != "OC-AD9H7" ]]; then
						test_hard $accel $card $BINFILE
					else
						test_hard $accel $card $BINFILE $BINFILE2
					fi
					if [ $? -ne 0 ]; then
						exit 1
					fi
					test_done=$((test_done +1))
				done
			else
				# -C Option was set.
				# Make sure i did get the correct values for -A and -C
				# -t3 for detecting only OPENCAPI (CAPI3.0) card result
				accel_to_use=`./software/tools/oc_find_card -C $CARD -t3`
                                echo "accel_to_use=$accel_to_use"
                                echo "accel       =$accel"
                                echo "CARD        =$CARD"
				if [ "$accel_to_use" == "$accel" ]; then
	                                if [[ $accel != "OC-AD9V3" ]] && [[ $accel != "OC-AD9H3" ]] && [[ $accel != "OC-AD9H7" ]]; then
						test_hard $accel $CARD $BINFILE
					else
						test_hard $accel $CARD $BINFILE $BINFILE2
					fi
					if [ $? -ne 0 ]; then
						exit 1
					fi
					test_done=$((test_done +1))
				else
					echo "Error: OpenCAPI Card: $CARD is not Accel Type: $accel"
					echo "       OpenCAPI Card: $CARD Accel Type is : $accel_to_use"
                                        echo ""
					exit 1
				fi
			fi
		done
		if [ $test_done -eq 0 ]; then
			echo "Error: Test of Image: $IMAGE failed !"
			echo "       File: $BINFILE not found"
			exit 1
		fi
		echo "`date` Image Test on Accel: $accel was executed $test_done time(s)"
		exit 0
	fi

	# at this level no binary file has been provided, still in the -ALL case
	# Run Software Test on one Type of Card
	echo "Test Software on: $accel Card: $CARD"
	if [ $CARD -eq "-1" ]; then
		# I will use all Cards if Card is set to -1
		MY_CARDS=`./software/tools/oc_find_card -A $accel`
		if [ $? -eq 0 ]; then
			echo "Error: Can not find Accel: $accel"
			exit 1;
		fi
		# MY_CARDS is a list of cards from type accel e.g: 0 1
		echo "Testing on  $accel[$MY_CARDS]"
		for card in $MY_CARDS ; do
			test_soft $accel $card
			if [ $? -ne 0 ]; then
				exit 1
			fi
			test_done=$((test_done + 1))
		done
	else
		# -C Option was set:
		# Make sure i did get the correct values for Card and Accel (-C and -A)
		# -t3 for detecting only OPENCAPI (CAPI3.0) card result
		accel_to_use=`./software/tools/oc_find_card -C $CARD -t3`
                echo "accel_to_use=$accel_to_use"
                echo "accel       =$accel"
                echo "CARD        =$CARD"
		if [ "$accel_to_use" == "$accel" ]; then
			test_soft $accel $CARD
			if [ $? -ne 0 ]; then
				exit 1
			fi
			test_done=$((test_done +1))
		else
			echo "Error: OpenCAPI Card: $CARD is not Accel Type: $accel"
			echo "       OpenCAPI Card: $CARD Accel Type is : $accel_to_use"
			exit 1
		fi
	fi

	if [ $test_done -eq 0 ]; then
		echo "Error: Software Test on Accel: $accel[$card] failed"
		exit 1
	fi
	echo "Software Test on Accel: $accel was executed on $test_done Cards"
	exit 0
fi

# At this level we should have a ALL cards  test case
# Run Software Test on ALL Cards

# if we ask for ALL cards, this is not compatible with providing a BIN file
if [[ $BINFILE != "" ]]; then
	# Error: I can not use the same BINFILE for ALL cards
	echo "Error: Option -A $accel and -F $BINFILE is not valid"
	exit 1
fi

echo "Test Software on: $accel"
MY_CARDS=`./software/tools/oc_find_card -A ALL`
if [ $? -eq 0 ]; then
	echo "Error: No Accelerator Cards found."
	exit 1;
fi
echo "Found Accel#: [$MY_CARDS]"
for card in $MY_CARDS ; do
	accel=`./software/tools/oc_find_card -C $card -t3`
	if [ $? -eq 0 ]; then
		echo "Can not find valid Accelerator for Card# $card"
		continue
	fi
	# oc_find_card also detects GZIP cards, i will skip this cards
	if [[ $accel != "OC-AD9V3" ]]  && [[ $accel != "OC-AD9H3" ]] && [[ $accel != "OC-AD9H7" ]]  && [[ $accel != "OC-BW250SOC" ]]; then
		echo "Invalid Accelerator $accel for Card $card, skip"
		continue
	fi
	test_soft $accel $card
	if [ $? -ne 0 ]; then
		exit 1
	fi
	test_done=$((test_done + 1))
done
# Check if test was run at least one time, set RC to bad if
# test did not find
# any valid card
if [ $test_done -eq 0 ]; then
	echo "Error: Software Test did not detect any card for test"
	exit 1
fi
echo "`date` Software Test was executed $test_done times"
exit 0
