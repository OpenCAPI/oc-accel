#!/bin/bash

DEFCONF="AD9V3.hdl_example.SDRAM.defconfig"

if [[ ! -z $1 ]]; then
    DEFCONF=$1
fi

. ./setup_tools.ksh

./ocaccel_workflow.py -c --simulator=nosim --no_make_model --no_run_sim --predefined_config $DEFCONF --make_image

if [[ $? -eq 0 ]]; then
    echo "Make image PASSED"
    exit 0
fi

echo "Make image FAILED"
exit 1 
