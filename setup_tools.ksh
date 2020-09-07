#!/bin/bash
# TOOLSPATH is supposed to contain the path to your tools
if [ ! -z $TOOLPATH ]; then
    export XILINX_VIVADO=$TOOLPATH/tools/xilinx/<20xx.x.x/Vivado/20xx.x
    export CDS_LEVEL=XX.YY.ZZZ
    export CDS_INST_DIR=$TOOLPATH/tools/cds/Xcelium/${CDS_LEVEL}
else
    export XILINX_VIVADO=/tools/Xilinx/Vivado/20XX.Y
    export CDS_INST_DIR=/tools/cadence/installs/XCELIUMXXXX.YYY
fi

export XILINXD_LICENSE_FILE=2100@<your-licence-server>

export CDS_LIC_FILE=<your-port>@<your-licence-server>

export PATH=${CDS_INST_DIR}/tools/bin/64bit:${CDS_INST_DIR}/tools/bin:${XILINX_VIVADO}/bin:$PATH

export UVM_HOME=$CDS_INST_DIR/tools/methodology/UVM/CDNS-X.ZY/

# Please don't commit the IES_LIBS settings if you set it to your own directory ... 
# Set IES_LIBS manually every time you source setup.ksh ...
unset  IES_LIBS
echo "Set up completed."

if [ -z $IES_LIBS ]; then
    echo "Please set IES_LIBS to the ies lib path by the following command:"
    echo "export IES_LIBS=<your ies path>"
fi
