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

SNAP_ROOT=`pwd`
. ./setup_tools.ksh

export IES_LIBS=$IESL
echo "Setting IES_LIBS to ${IES_LIBS}"

./ocaccel_workflow.py -c --simulator xcelium --unit_sim --unit_test bfm_test_rd_wr_10_size7_randlen_randid_rand_resp
if [ $? -ne 0 ]; then
    echo "UVM check FAILED for bridge mode!"
    exit 1
fi

./ocaccel_workflow.py -c --simulator xcelium --unit_sim --odma --unit_test odma_test_chnl4_list2to4_block2to4_dsc1to64_mixdrt_less4k
if [ $? -ne 0 ]; then
    echo "UVM check FAILED for odma mode!"
    exit 1
fi

echo "UVM check PASSED for both bridge mode and odma mode!"
exit 0
