#!/bin/bash
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
$ROOT/actions/hdl_database/sw/direct/multi_process_test -f -t 10 $*
