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
  if ($0 ~ "Read bandwidth min") {
         a1_iter++
         a1_size[a1_iter]=$7
         a1_min[a1_iter]=$13
         a1_max[a1_iter]=$15
         a1_variance[a1_iter]=$17
 }
  if ($0 ~ "Write bandwidth min") {
         a2_iter++
         a2_size[a1_iter]=$7
         a2_min[a1_iter]=$13
         a2_max[a1_iter]=$15
         a2_variance[a1_iter]=$17
 }
  if ($0 ~ "Duplex bandwidth min") {
         a3_iter++
         a3_size[a1_iter]=$7
         a3_min[a1_iter]=$13
         a3_max[a1_iter]=$15
         a3_variance[a1_iter]=$17
 }
}
END {
  i=1 
  printf "+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+\n"
  printf "|            OC-Accel hdl_single_engine Throughput (MBytes/s)                                                                                                                  |\n"
  printf "+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+\n"
  printf "|%11s %17s %17s %17s %17s %17s %17s %17s %17s %17s |\n","Total Bytes", "Read Min", "Read Max", "Read Variance", "Write Min", "Write Max", "Write Variance", "Duplex Min", "Duplex Max", "Duplex Variance" 
  printf "+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+\n"
  while (i <= a1_iter) {
    printf "%12s %17s %17s %17s %17s %17s %17s %17s %17s %17s\n",a1_size[i], a1_min[i], a1_max[i], a1_variance[i], a2_min[i], a2_max[i], a2_variance[i], a3_min[i], a3_max[i], a3_variance[i]
    i++
    }
}


