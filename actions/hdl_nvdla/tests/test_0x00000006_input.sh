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
sudo ../../../software/tools/snap_maint -vv

if [[ -z $1 ]]; then
    PIC=./pics/poodle.jpg
else
    PIC=$1
fi

sudo LD_LIBRARY_PATH=/usr/local/lib64/:$LD_LIBRARY_PATH \
	../sw/snap_nvdla \
	--normalize 1.0 \
	--mean 104.00698793,116.66876762,122.67891434 \
	--rawdump \
	--loadable ./sw_regression/flatbufs/kmd/NN/NN_L0_1_large_fbuf_with_input_210656.bin \
	--image $1
