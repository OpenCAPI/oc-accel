#!/bin/bash

if [ ! -z $CTEPATH ]; then
    export XILINX_VIVADO=$CTEPATH/tools/xilinx/2018.3.1/Vivado/2018.3
    export CDS_LEVEL=18.03.010
    export CDS_INST_DIR=$CTEPATH/tools/cds/Xcelium/${CDS_LEVEL}
else
    export XILINX_VIVADO=/tools/Xilinx/Vivado/2019.1
    export CDS_INST_DIR=/tools/cadence/installs/XCELIUM1903.008
fi

export XILINXD_LICENSE_FILE=2100@pokwinlic1.pok.ibm.com

export CDS_LIC_FILE=5295@poklnxlic04.pok.ibm.com:\
1716@rchlic1.rchland.ibm.com:\
1716@rchlic2.rchland.ibm.com:\
1716@rchlic3.rchland.ibm.com:\
5280@cdsserv1.pok.ibm.com:\
5280@cdsserv2.pok.ibm.com:\
5280@cdsserv3.pok.ibm.com:\
5280@hdlic4.boeblingen.de.ibm.com:\
5280@hdlic5.boeblingen.de.ibm.com:\
5280@hdlic6.boeblingen.de.ibm.com:\
5280@cadlic4.haifa.ibm.com

export PATH=${CDS_INST_DIR}/tools/bin/64bit:${CDS_INST_DIR}/tools/bin:${XILINX_VIVADO}/bin:$PATH

export UVM_HOME=$CDS_INST_DIR/tools/methodology/UVM/CDNS-1.2/

# Please don't commit the IES_LIBS settings if you set it to your own directory ... 
# Set IES_LIBS manually every time you source setup.ksh ...
unset  IES_LIBS
echo "Set up completed."

if [ -z $IES_LIBS ]; then
    echo "Please set IES_LIBS to the ies lib path by the following command:"
    echo "export IES_LIBS=<your ies path>"
fi
