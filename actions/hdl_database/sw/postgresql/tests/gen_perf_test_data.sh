#!/bin/bash

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
