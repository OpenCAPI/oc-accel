#!/bin/bash

if [[ -z $1 ]]; then
    OCSE_ROOT=../ocse
else
    OCSE_ROOT=$1
fi

if [[ -z $2 ]]; then
    IESL=${HOME}/vol0/xcelium_lib
else
    IESL=$2
fi

export IES_LIBS=$IESL
echo "Setting IES_LIBS to ${IES_LIBS}"

./run.py -C
./run.py --ocse $OCSE_ROOT --predefined_config OC-AD9V3.hls_vadd_matmul.defconfig -s xcelium -t "hls_vadd_matmul"
if [ $? -ne 0 ]; then
    echo "hls_vadd_matmul failed!"
    exit 1
fi

./run.py -C
./run.py --ocse $OCSE_ROOT --predefined_config OC-AD9V3.hdl_perf_test.defconfig -s xcelium -t "hdl_perf_test"
if [ $? -ne 0 ]; then
    echo "hdl_perf_test failed!"
    exit 1
fi

echo "All tests PASSED!"
exit 0
