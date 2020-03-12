pipeline {
  agent any
  stages {
    stage('Run') {
      steps {
        sh '''
        whoami
        date
        pwd
        . ./scripts/setup_tools.sh
        export XILINX_VIVADO=/var/lib/jenkins/tools/Xilinx/Vivado/2019.2
        export PATH=${XILINX_VIVADO}/bin:$PATH
        . ./scripts/jenkins_sanity_sim.ksh /var/lib/jenkins/jobs/ocse /var/lib/jenkins/jobs/ies_libs/2019.2_19.03.s008
'''
      }
    }

  }
}
