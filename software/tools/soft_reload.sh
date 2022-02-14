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

###################################################################################################################################
# VARIABLES

Option=""
CardID=""
FullPathScript=`realpath $0`
FullPathDir=`dirname $FullPathScript`

###################################################################################################################################
# FUNCTIONS
#

function usage
{
  echo
  echo "`basename $0` Usage:"
  echo "-------------------------"
  echo
  echo "  + The goal of this script is to set the reload bit of the OpenCAPI card to 1 so that"
  echo "    at next oc-reset the FPGA chip of the card is reloaded from the flash memory"
  echo
  echo "  + The script must be used when the ICAP IP is loaded into the User Space (and not the Configuration Space)"
  echo "    This is the case when addressing the OpenCAPI card from a container (pod) in a cloud (Partial Reconfiguration)"
  echo
  echo
  echo "  -C <Card ID>   : (mandatory) The Position/ID of the card (use 'oc_find-card -v -AALL' to get the card Position/ID)"
  echo "  -h             : (optional) shows this usage info"
  echo
  exit 0
}


###################################################################################################################################
# MAIN
#

#----------------------------------------------------------------------------------------------------------------------------------
# GETOPTS

while getopts ":C:h" Option
do
  case $Option in
    C )
      CardID=$OPTARG
    ;;

    h )
      usage
    ;;

    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;

  esac
done    

if [ -z "$CardID" ]; then
  echo 
  echo "ERROR:"
  echo "------"
  echo "PROVIDING THE POSITION/ID OF THE CARD IS MANDATORY."
  usage
fi

echo "#################################################################################################"
echo "## The sequence below is to set the reload bit to 1 so that                                    ##"
echo "##  at next oc-reset the FPGA is reloaded from the Flash                                       ##"
echo "#################################################################################################"

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## Checking that ICAP is ready for programming                                                 ##"
echo "## (Expected read value is 0x00000005)                                                         ##"
echo
echo "--> snap_peek -C $CardID -w32 0x0F10 -e 0x00000005"

if $FullPathDir/snap_peek -C $CardID -w32 0x0F10 -e 0x00000005; then
  echo
  echo "The ICAP is ready for programming --> Let's continue"
else
  echo
  echo "ERROR: The ICAP is NOT ready for programming."
  echo "Exiting..."
  echo
  exit 2
fi

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## checking that WR fifo is empty (0x3f empty lines)                                           ##"
echo "## (Expected read value is 0x0000003f)                                                         ##"
echo
echo "--> snap_peek -C $CardID -w32 0x0F14 -e 0x0000003f"

if $FullPathDir/snap_peek -C $CardID -w32 0x0F14 -e 0x0000003f; then
  echo
  echo "The WR fifo is empty --> Let's continue"
else
  echo
  echo "ERROR: The WR fifo is NOT empty."
  echo "Exiting..."
  echo
  exit 3
fi

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## Pushing the reload sequence in WR fifo                                                      ##"
echo
echo "--> snap_poke -C $CardID -w32 0x0F00 ..."
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0xFFFFFFFF
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0xAA995566
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x20000000
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x30020001
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x00000000
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x30080001
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x0000000F
$FullPathDir/snap_poke -C $CardID -w32 0x0F00 0x20000000

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## checking that WR fifo is NOT empty (0x37 empty lines)                                       ##"
echo "## (Expected read value is 0x00000037)                                                         ##"
echo
echo "--> snap_peek -C $CardID -w32 0x0F14 -e 0x00000037"

if $FullPathDir/snap_peek -C $CardID -w32 0x0F14 -e 0x00000037; then
  echo
  echo "The WR fifo is not empty anymore (expected 0x37 empty lines) --> Let's continue"
else
  echo
  echo "ERROR: The WR fifo has not been correctly loaded."
  echo "Exiting..."
  echo
  exit 4
fi

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## Flushing the FIFO to set the reload bit to 1                                                ##"
echo
echo "--> snap_poke -C $CardID -w32 0x0F0C 0x00000001"
$FullPathDir/snap_poke -C $CardID -w32 0x0F0C 0x00000001

echo
echo "##---------------------------------------------------------------------------------------------##"
echo "## Registers should not be readable anymore                                                    ##"
echo "## (Expected read value is 0xffffffff)                                                         ##" 
echo
echo "--> snap_peek -C $CardID -w32 0x0F14 -e 0xffffffff"

if $FullPathDir/snap_peek -C $CardID -w32 0x0F14 -e 0xffffffff; then
  echo
  echo "Registers are not readable anymore --> Now, the card should be reloaded at next oc-reset."
  echo
else
  echo
  echo "ERROR: Registers are still readable, which should not be the case anymore."
  echo "Exiting..."
  echo
  exit 5
fi
