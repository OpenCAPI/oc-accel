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

cwd=`pwd`
capi_postgres=/home/postgres/capi

if [[ -z $1 ]]; then
    echo "PG lib install path should be provided as the first command line argument!"
    exit 1
fi

if [[ -L ${capi_postgres} ]]; then
    unlink ${capi_postgres}
fi

ln -s $cwd ${capi_postgres} 

if [[ ! -d ${capi_postgres} ]]; then
    echo "${capi_postgres} is not a valid path!"
    exit 1;
fi

install_path=$1

# Copying the .so to pg udf install path
echo "Copying psql_regex_capi.so to $install_path"
cp psql_regex_capi.so $install_path

# Grant CAPI device permission to user *postgres*
setfacl -m u:postgres:rw /dev/cxl/afu0.0s
setfacl -m u:postgres:rw /dev/cxl/afu0.0m
# Enable CAPI-SNAP card
../../../../software/tools/snap_maint -vv

if [[ $? != 0 ]]; then
    echo "SNAP maint failed, please check the card status!"
    exit 1
fi

# generate tests for performance test
if [[ ! -d ./tests/perf_test ]]; then
    mkdir -p ./tests/perf_test
    cd tests
    ./gen_perf_test_data.sh
fi

exit 0
