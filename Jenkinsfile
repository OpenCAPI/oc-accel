pipeline {
  agent any
  stages {
    stage('Run') {
      steps {
        sh '''
        whoami
        date
        pwd
        export XILINX_VIVADO=/var/lib/jenkins/tools/Xilinx/Vivado/2019.2
        export CDS_LEVEL=19.03.008
        export CDS_INST_DIR=/afs/apd.pok.ibm.com/func/vlsi/cte/tools/cds/Xcelium/${CDS_LEVEL}
        export PATH=/opt/rh/devtoolset-8/root/usr/bin/:$PATH
        export XILINXD_LICENSE_FILE=2100@pokwinlic1.pok.ibm.com
        export CDS_LIC_FILE=5295@poklnxlic04.pok.ibm.com:1716@rchlic1.rchland.ibm.com:1716@rchlic2.rchland.ibm.com:1716@rchlic3.rchland.ibm.com:5280@cdsserv1.pok.ibm.com:5280@cdsserv2.pok.ibm.com:5280@cdsserv3.pok.ibm.com:5280@hdlic4.boeblingen.de.ibm.com:5280@hdlic5.boeblingen.de.ibm.com:5280@hdlic6.boeblingen.de.ibm.com:5280@cadlic4.haifa.ibm.com
        export PATH=${CDS_INST_DIR}/tools/bin/64bit:${CDS_INST_DIR}/tools/bin:${XILINX_VIVADO}/bin:$PATH
        export UVM_HOME=$CDS_INST_DIR/tools/methodology/UVM/CDNS-1.2/
        . ./scripts/jenkins_sanity_sim.ksh /var/lib/jenkins/jobs/ocse /var/lib/jenkins/jobs/ies_libs/2019.2_19.03.s008
'''
      }
    }

  }
}
