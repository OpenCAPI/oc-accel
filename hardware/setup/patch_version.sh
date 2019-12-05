#!/bin/bash
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
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

#Patch card info and sdram_size
if [ "$FPGACARD" == "AD9V3" ]; then
  CARD_TYPE="31"
elif [ "$FPGACARD" == "AD9H3" ]; then
  CARD_TYPE="32"
elif [ "$FPGACARD" == "AD9H7" ]; then
  CARD_TYPE="33"
fi

SRC="define CARD_TYPE 8'h.*"
DST="define CARD_TYPE 8'h${CARD_TYPE}"
sed -i "s/$SRC/$DST/" $1/$2

#Patch HLS Action type and Release version
#Be very careful, look for string ACTION_TYPE and RELEASE_LEVEL in $ACTION_ROOT
if [ "$HLS_SUPPORT" == "TRUE" ]; then
   HLS_ACTION_TYPE=`find $ACTION_ROOT -name *.[hH] | xargs grep "#define\s\+ACTION_TYPE" | cut -d "x" -f 2`
   HLS_RELEASE_LEVEL=`find $ACTION_ROOT -name *.[hH] | xargs grep "#define\s\+RELEASE_LEVEL" | cut -d "x" -f 2`
   echo "ACTION_TYPE is $HLS_ACTION_TYPE, RELEASE_LEVEL is $HLS_RELEASE_LEVEL"

   SRC="define HLS_ACTION_TYPE 32'h.*"
   DST="define HLS_ACTION_TYPE 32'h${HLS_ACTION_TYPE}"
   sed -i "s/$SRC/$DST/" $1/$2

   SRC="define HLS_RELEASE_LEVEL 32'h.*"
   DST="define HLS_RELEASE_LEVEL 32'h${HLS_RELEASE_LEVEL}"
   sed -i "s/$SRC/$DST/" $1/$2
fi

#Calculate 
echo "oc_$SNAP_RELEASE_$SNAP_BUILD_DATE" >.bitstream_name.txt
