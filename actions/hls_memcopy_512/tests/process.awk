#! /usr/bin/awk -f

#Process following string
#memcopy of 512 bytes took 18 usec @ 28.444 MiB/sec (from HOST_DRAM to FPGA_BRAM)

BEGIN {
  FS=" "
}
{
#  print $0
  if ($0 ~ "HOST_DRAM to FPGA_BRAM") {
         a1_iter++
         a1_size[a1_iter]=$3
	 a1_usec[a1_iter]=$6
	 a1_bw[a1_iter]=$9
 }
  if ($0 ~ "FPGA_BRAM to HOST_DRAM") {
         a2_iter++
         a2_size[a2_iter]=$3
	 a2_usec[a2_iter]=$6
	 a2_bw[a2_iter]=$9
 }
  if ($0 ~ "HBM or DDR Port 0 to FPGA_BRAM") {
         a3_iter++
         a3_size[a3_iter]=$3
	 a3_usec[a3_iter]=$6
	 a3_bw[a3_iter]=$9
 }
  if ($0 ~ "FPGA_BRAM to HBM or DDR Port 0") {
         a4_iter++
         a4_size[a4_iter]=$3
	 a4_usec[a4_iter]=$6
	 a4_bw[a4_iter]=$9
 }
}
END {
  i=1
  printf "+-------------------------------------------------------------------------------+\n"
  printf "|            OC-Accel hls_memcopy_512  Throughput (MBytes/s)                    |\n"
  printf "+-------------------------------------------------------------------------------+\n"
  printf "+------------LCL stands for DDR or HBM memory according to hardware-------------+\n"
  printf "%12s %16s %16s %16s %16s\n","bytes", "Host->FPGA_RAM", "FPGA_RAM->Host","FPGA(LCL->BRAM)", "FPGA(BRAM->LCL)" 
  printf " -------------------------------------------------------------------------------\n"
  while (i <= a1_iter) {
    printf "%12s %16s %16s %16s %16s\n",a1_size[i], a1_bw[i], a2_bw[i], a3_bw[i], a4_bw[i]
    i++
    }
}
