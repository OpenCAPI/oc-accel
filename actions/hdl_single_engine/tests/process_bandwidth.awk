#! /usr/bin/awk -f

#Process following string
#memcopy of 512 bytes took 18 usec @ 28.444 MiB/sec (from HOST_DRAM to FPGA_BRAM)

BEGIN {
  FS=" "
  a1_iter=0
  a2_iter=0
  a3_iter=0
}
{
#  print $0
  if ($0 ~ "Read average bandwidth") {
         a1_iter++
         a1_size[a1_iter]=$5
         a1_usec[a1_iter]=$8
         a1_bw[a1_iter]=$11
 }
  if ($0 ~ "Write average bandwidth") {
         a2_iter++
         a2_size[a2_iter]=$5
         a2_usec[a2_iter]=$8
         a2_bw[a2_iter]=$11
 }
  if ($0 ~ "Duplex average bandwidth") {
         a3_iter++
         a3_size[a3_iter]=$4
         a3_usec[a3_iter]=$7
         a3_bw[a3_iter]=$10
 }
}
END {
  i=1
  printf "+-------------------------------------------------------------------------------+\n"
  printf "|            OC-Accel hdl_single_engine Throughput (MBytes/s)                   |\n"
  printf "+-------------------------------------------------------------------------------+\n"
  printf "|%11s %17s %17s %17s              |\n","Total Bytes", "Read Bandwidth", "Write Bandwidth","Duplex Bandwidth"
  printf "+-------------------------------------------------------------------------------+\n"
  while (i <= a1_iter) {
    printf " %12s %17s %17s %17s \n",a1_size[i], a1_bw[i], a2_bw[i], a3_bw[i]
    i++
    }
}
