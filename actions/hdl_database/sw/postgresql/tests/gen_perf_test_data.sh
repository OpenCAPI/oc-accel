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

array1=(   8K 16K 32K 64K 128K 256K 512K 1M)
array2=(4K 8K 16K 32K 64K 128K 256K 512K)

if [[ ! -d ./perf_test ]];
then
    echo "./perf_test not exist!"
    exit 1;
fi

cp packet.1024.4K.txt ./perf_test/
cd ./perf_test
echo "Generating performance test data"
for ((i=0;i<${#array1[@]};++i));
do
    file_1="packet.1024.${array1[i]}.txt"
    file_2="packet.1024.${array2[i]}.txt"
    touch $file_1
    echo "  -> $file_1"

    if [[ ! -f $file_2 ]];
    then
        echo "$file_2 not exist"
        exit 1
    fi

    cat $file_2 >> $file_1
    cat $file_2 >> $file_1
done

cd ..
exit 0
