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
# This script is typically called by hardware/Makefile and takes as arguments the location of a variable file and the file name
# to update its default parameters.
# Typically file is created with $(SNAP_HARDWARE_ROOT)/hardware/setup/create_framework.tcl
# path is hdl/core
# and file is snap_global_vars.v
set -e
NAME=`basename $2`


#Patch build date and git version
SNAP_BUILD_DATE=`date "+%Y_%m%d_%H%M"`
SNAP_RELEASE=`git describe --tags --always --match v[0-9]*.[0-9]*.[0-9]* | sed 's/.*\([0-9a-fA-F][0-9a-fA-F]\)\([0-9a-fA-F][0-9a-fA-F]\)\([0-9a-fA-F][0-9a-fA-F]\).*/\1 \2 \3/' | awk '{printf("%02X_%02X_%02X\n",$1,$2,$3)}'`
GIT_DIST=`git describe --tags --always --match v[0-9]*.[0-9]*.[0-9]* | awk '{printf("%s-0\n",$1)}' | sed 's/.*\.[0-9][0-9]*-\([0-9][0-9]*\).*/\1/' | awk '{printf("%02X\n",$1)}'`
if [ ! -z `echo $GIT_DIST | sed 's/[0-9A-F][0-9A-F]//'` ]; then GIT_DIST="FF"; fi
GIT_SHA=`git log -1 --format="%H" | cut -c 1-4 | sed y/abcdef/ABCDEF/`"_"`git log -1 --format="%H" | cut -c 5-8 | sed y/abcdef/ABCDEF/`
SRC="define IMP_VERSION_DAT 64'h.*"
DST="define IMP_VERSION_DAT 64'h${SNAP_RELEASE}${GIT_DIST}_${GIT_SHA}"
sed -i "s/$SRC/$DST/" $1/$2 
SRC="define BUILD_DATE_DAT 64'h.*"
DST="define BUILD_DATE_DAT 64'h0000_${SNAP_BUILD_DATE}"
sed -i "s/$SRC/$DST/" $1/$2

# Manually Patching with USERCODE if required
if [ -z $FPGACARD ]; then
  SRC="define USERCODE 64'h.*"
  # usercode should be less than 64 bit long
  #usercode=`echo 0123456789ABCDEF`
  DST="define USERCODE 64'h${USERCODE}"
  sed -i "s/$SRC/$DST/" $1/$2
fi

#Patch card info and sdram_size
# SDRAM_SIZE="2000" stand for 8GB of SDRAM - 0 for IBM but will be overwritten later by HBM_AXI_IF_NB
if [ "$FPGACARD" == "AD9V3" ]; then
  CARD_TYPE="31"
  #8GB of SDRAM
  SDRAM_SIZE="2000"
elif [ "$FPGACARD" == "AD9H3" ]; then
  CARD_TYPE="32"
  SDRAM_SIZE="0"
elif [ "$FPGACARD" == "AD9H335" ]; then
  CARD_TYPE="35"
  SDRAM_SIZE="0"
elif [ "$FPGACARD" == "AD9H7" ]; then
  CARD_TYPE="33"
  SDRAM_SIZE="0"
elif [ "$FPGACARD" == "BW250SOC" ]; then
  CARD_TYPE="34"
  #8GB of SDRAM
  SDRAM_SIZE="2000"
fi

SRC="define CARD_TYPE 8'h.*"
DST="define CARD_TYPE 8'h${CARD_TYPE}"
sed -i "s/$SRC/$DST/" $1/$2

#Patch HLS Action type and Release version
#Be very careful, look for string ACTION_TYPE and RELEASE_LEVEL in $ACTION_ROOT
if [ "$HLS_SUPPORT" == "TRUE" ]; then
   HLS_ACTION_TYPE=`find $ACTION_ROOT -name *.[hH] | xargs grep "#define\s\+ACTION_TYPE" | awk -F"0x" '{print $2}'`
   HLS_RELEASE_LEVEL=`find $ACTION_ROOT -name *.[hH] | xargs grep "#define\s\+RELEASE_LEVEL" | awk -F"0x" '{print $2}'`
   echo "                        ACTION_TYPE is $HLS_ACTION_TYPE, RELEASE_LEVEL is $HLS_RELEASE_LEVEL"

   SRC="define HLS_ACTION_TYPE 32'h.*"
   DST="define HLS_ACTION_TYPE 32'h${HLS_ACTION_TYPE}"
   sed -i "s/$SRC/$DST/" $1/$2

   SRC="define HLS_RELEASE_LEVEL 32'h.*"
   DST="define HLS_RELEASE_LEVEL 32'h${HLS_RELEASE_LEVEL}"
   sed -i "s/$SRC/$DST/" $1/$2

   if [ "$HBM_USED" == "TRUE" ]; then
      #Here we use for the HBM the SDRAM_SIZE as the number of AXI interfaces
      SDRAM_SIZE_DEC=`find $ACTION_ROOT -name *.[cC]* | xargs grep "#define\s\+HBM_AXI_IF_NB" | awk '{print $NF}'`
      printf -v SDRAM_SIZE "%x" "$SDRAM_SIZE_DEC"
      ACTION_NAME=`find $ACTION_ROOT -name *.[cC]* | xargs grep "#define\s\+HBM_AXI_IF_NB" | cut -d':' -f1 |awk -F"actions" '{print $2}'`
      if [ -z $SDRAM_SIZE_DEC ]; then
         echo "   -------------------------------------------------------------------------------------------------"
         echo "   -- WARNING : Impossible to check coherency of HBM AXI interfaces numbers between action and chip.           "
         echo "   --           Please define the variable HBM_AXI_IF_NB in oc-accel/actions/hls_youraction/hw/xxx.cpp file "
         echo "   -------------------------------------------------------------------------------------------------"
      elif [ $SDRAM_SIZE_DEC != $HBM_AXI_IF_NUM ]; then
         echo "   ---------------------------------------------------------------------------------------------"
         echo "   -- ERROR : HBM AXI interfaces defined in $ACTION_NAME (=$SDRAM_SIZE_DEC)"
         echo "   --         is different than the one specified in the Kconfig menu (=$HBM_AXI_IF_NUM)!!"
         echo "   --         Please correct one or the other to keep coherency."
         echo "   ---------------------------------------------------------------------------------------------"
         exit 1
      else
         echo "                        HBM AXI interfaces defined in HLS action is $SDRAM_SIZE_DEC (as in chip wrapper)"
      fi
   fi
      
   SRC="define SDRAM_SIZE 16'h.*"
   DST="define SDRAM_SIZE 16'h${SDRAM_SIZE}"
   sed -i "s/$SRC/$DST/" $1/$2

fi
#Calculate 
echo "oc_$SNAP_RELEASE_$SNAP_BUILD_DATE" >.bitstream_name.txt
