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
echo "                        action config says ACTION_ROOT is $ACTION_ROOT"
echo "                        action config says FPGACHIP is $FPGACHIP"
echo "                        action config says there are $NUM_OF_NVDLA_KERNELS kernels used in this action"
echo "                        action config says $NVDLA_CONFIG is used for regex engine configuration"

HDL_PP=$ACTION_ROOT/../../scripts/utils/hdl_pp/

if [ -L ./engines/nvdla ]; then
    unlink ./engines/nvdla
fi

if [ -L ./engines/include ]; then
    unlink ./engines/include
fi

if [ -L ./engines/vlibs ]; then
    unlink ./engines/vlibs
fi

if [ -L ./engines/fifos ]; then
    unlink ./engines/fifos
fi

if [ -L ./engines/defs ]; then
    unlink ./engines/defs
fi

if [ -L ./engines/ram_fpga ]; then
    unlink ./engines/ram_fpga
fi

#if [ -L ../ip/engines/fpga_ip ]; then
#    unlink ../ip/engines/fpga_ip
#fi

#if [ -L ./ram_wrapper ]; then
#    unlink ./ram_wrapper
#fi

if [ ! -d ../nvdla-capi ]; then
    echo "WARNING!!! Please use 'git submodule init' to initialize nvdla hardware IP."
    exit -1
elif [ ! -d ../nvdla-capi/outdir/$NVDLA_CONFIG ]; then
    cd ../nvdla-capi/
    if [ -f tree.make ]; then
        rm tree.make
    fi
    #make USE_NV_ENV=1 NV_PROJ=$NVDLA_CONFIG NV_FPGA_CHIP=$FPGACHIP
    make USE_VM_ENV=1 VM_USE_DESIGNWARE=0 VM_PROJ=$NVDLA_CONFIG VM_PYTHON=/usr/bin/python VM_CPP=/usr/bin/cpp VM_GCC=/usr/bin/gcc VM_CXX=/usr/bin/g++
    ./tools/bin/tmake -clean -build vmod
    if [ $? -ne 0 ]; then
        echo "ERROR while making NVDLA-CAPI hardware."
        exit -1
    fi
    cd ../hw
else
    echo "NVDLA hardware is ready for use."
fi

if [ ! -d ./engines ]; then
    mkdir engines
fi

cd engines

ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/nvdla               nvdla
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/include             include
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/vlibs               vlibs
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fifos               fifos
#ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fpga_ip/ram_wrapper ram_wrapper
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/rams/fpga/model     ram_fpga
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/spec/defs                defs

cd ../../

if [ ! -d ./ip/engines ]; then
    mkdir -p ./ip/engines
fi

cd ip/engines

#ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fpga_ip             fpga_ip

cd ../../hw/

if [ ! -f engines/defs/project.vh ]; then
    echo "Cannot find engines/defs/project.vh"
    exit -1;
fi

echo "                        Generating defs.h"
if [ ! -f ./defs.h ]; then
    touch defs.h
else
    rm defs.h
fi
# Generate number of kernel configurations
echo "#define NUM_KERNELS ${NUM_OF_NVDLA_KERNELS}" >> defs.h

# Generate NVDLA_CONFIG
if [ $NVDLA_CONFIG == nv_small ]; then
    nvdla_config_value=1
elif [ $NVDLA_CONFIG == nv_large ]; then
    nvdla_config_value=2
else
    nvdla_config_value=4
fi
echo "#define NVDLA_CONFIG ${nvdla_config_value}" >> defs.h

for i in $(find -name \*.v_source); do
    vfile=`echo $i | sed 's/v_source$/vinter/'`
    touch $vfile
    cat $i > $vfile
    echo -e "\t                        generating $vfile"
    dbb_data_width=`sed -n -e 's/\`define NVDLA_PRIMARY_MEMIF_WIDTH //p' engines/defs/project.vh`
    dbb_addr_width=`sed -n -e 's/\`define NVDLA_MEM_ADDRESS_WIDTH //p' engines/defs/project.vh`
    sram_data_width=`sed -n -e 's/\`define NVDLA_SECONDARY_MEMIF_WIDTH //p' engines/defs/project.vh`
    sram_addr_width=`sed -n -e 's/\`define NVDLA_MEM_ADDRESS_WIDTH //p' engines/defs/project.vh`
    dbb_data_width_log2=`sed -n -e 's/\`define NVDLA_PRIMARY_MEMIF_WIDTH_LOG2 //p' engines/defs/project.vh`
    sram_data_width_log2=`sed -n -e 's/\`define NVDLA_SECONDARY_MEMIF_WIDTH_LOG2 //p' engines/defs/project.vh`
    sed -i "s/#NVDLA_DBB_DATA_WIDTH/$dbb_data_width/g" $vfile
    sed -i "s/#NVDLA_DBB_ADDR_WIDTH/$dbb_addr_width/g" $vfile
    sed -i "s/#NVDLA_SRAM_DATA_WIDTH/$sram_data_width/g" $vfile
    sed -i "s/#NVDLA_SRAM_ADDR_WIDTH/$sram_addr_width/g" $vfile
    sed -i "s/#NVDLA_PRIMARY_MEMIF_WIDTH_LOG2/$dbb_data_width_log2/g" $vfile
    sed -i "s/#NVDLA_SECONDARY_MEMIF_WIDTH_LOG2/$sram_data_width_log2/g" $vfile

    if [ $dbb_addr_width -eq 64 ]; then
        sed -i '/#ifdef NVDLA_DBB_ADDR_WIDTH < 64/,/#endif/d' $vfile
    else
        sed -i '/#ifdef NVDLA_DBB_ADDR_WIDTH < 64/d' $vfile
    fi

    if [ $sram_data_width ]; then
        sed -i '/#ifdef SRAM/d' $vfile
    else
        sed -i '/#ifdef SRAM/,/#endif/d' $vfile
    fi
    sed -i '/#endif/d' $vfile

    vcp=${vfile%.vinter}.vcp
    v=${vfile%.vinter}.v
    echo "                        Processing $vfile"
    $HDL_PP/vcp -i $vfile -o $vcp -imacros ./defs.h 2>> defs.log

    if [ ! $? ]; then
        echo "!! ERROR processing $vcp"
        exit -1
    fi

    perl -I $HDL_PP/plugins -Meperl $HDL_PP/eperl -o $v $vcp 2>> defs.log

    if [ ! $? ]; then
        echo "!! ERROR processing $v"
        exit -1
    fi

done

# Create IP for the framework
if [ ! -d $ACTION_ROOT/ip/framework/framework_ip_prj ]; then
    echo "                        Call create_framework_ip.tcl to generate framework IPs"
    vivado -mode batch -source $ACTION_ROOT/ip/tcl/create_framework_ip.tcl -notrace -nojournal -tclargs $ACTION_ROOT $FPGACHIP $NUM_OF_NVDLA_KERNELS $dbb_data_width $sram_data_width >> framework_fpga_ip_gen.log

    if [ ! $? ]; then
        echo "!! ERROR generating framework IPs."
        exit -1;
    fi
fi
