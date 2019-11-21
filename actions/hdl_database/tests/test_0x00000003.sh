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
ROOT=../../../
if [ ! -z $SNAP_ROOT ]; then
    ROOT=$SNAP_ROOT
fi

echo $ROOT

#$ROOT/software/tools/snap_maint -vv

echo $ROOT/actions/hdl_database/tests/$1

if [[ ! -z $1 ]]; then
    cp $ROOT/actions/hdl_database/tests/$1 packet.txt
fi

cp $ROOT/actions/hdl_database/tests/pattern.txt pattern.txt
#$ROOT/actions/hdl_database/sw/direct/db_direct -f -t 10 $*
$ROOT/actions/hdl_database/sw/direct/one_thread_direct -f -t 10 $*
