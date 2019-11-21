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

if [[ -z $2 ]]; then
    echo "PG lib extension path should be provided as the second command line argument!"
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
extension_path=$2

# Copying the .so to pg udf install path
echo "Copying pg_capi.so to $install_path"
/usr/bin/install -c -m 755  pg_capi.so $install_path
echo "Copying pg_capi.control to $extension_path"
/usr/bin/install -c -m 644 ./pg_capi.control $extension_path

# Grant CAPI device permission to user *postgres*
setfacl -m u:postgres:rw /dev/ocxl/IBM\,oc-snap\.0007\:00\:00\.1\.0
# Enable CAPI-SNAP card
#../../../../../software/tools/snap_maint -vv

if [[ $? != 0 ]]; then
    echo "SNAP maint failed, please check the card status!"
    exit 1
fi

exit 0
