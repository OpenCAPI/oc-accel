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

# This script is NOT needed if you follow the "make" process.
# However, in some cases, you need these variables get set explicitly. 

DIR="$(cd "$(dirname $BASH_SOURCE)" && pwd)"

export OCACCEL_ROOT=${DIR}/..
[ -f "${OCACCEL_ROOT}/.ocaccel_config.sh" ] && . ${OCACCEL_ROOT}/.ocaccel_config.sh
export ACTION_ROOT=$OCACCEL_ROOT/actions/$ACTION_NAME
export OCACCEL_HARDWARE_ROOT=$OCACCEL_ROOT/hardware
export PATH=$PATH:$OCACCEL_ROOT/software/tools
[ -n "$ACTION_ROOT" ] &&  export PATH=$PATH:$ACTION_ROOT/sw
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OCACCEL_ROOT/software/lib
