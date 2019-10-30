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
echo "                        action config says ACTION_ROOT is $ACTION_ROOT"
echo "                        action config says FPGACHIP is $FPGACHIP"


if [ "$DDRI_USED" == "TRUE" ]; then
  DDRI_FILTER="\-\- only for DDRI_USED!=TRUE"
else
  DDRI_FILTER="\-\- only for DDRI_USED=TRUE"
fi

if [ "$NVME_USED" == "TRUE" ]; then
  NVME_FILTER="\-\- only for NVME_USED!=TRUE"
else
  NVME_FILTER="\-\- only for NVME_USED=TRUE"
fi

for vhdsource in *.vhd_source; do
    vhdfile=`echo $vhdsource | sed 's/vhd_source$/vhd/'`
    echo -e "\t                        generating $vhdfile"
    grep -v "$DDRI_FILTER" $vhdsource | grep -v "$NVME_FILTER" > $vhdfile
done

if [ ! -d $ACTION_ROOT/ip/action_ip_dir ]; then
	echo "                        Call create_action_ip.tcl to generate IPs"
	vivado -mode batch -source $ACTION_ROOT/ip/create_action_ip.tcl -notrace -nojournal -tclargs $ACTION_ROOT $FPGACHIP
fi
