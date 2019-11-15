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
