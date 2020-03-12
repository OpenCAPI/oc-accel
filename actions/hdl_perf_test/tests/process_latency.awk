#! /usr/bin/awk -f


BEGIN {
  FS=","
  iter=0
  sum=0
  min=1000000
  max=0
}
{
#  print $0
         iter++
	 diff[iter]=$4-$2
	 if (diff[iter] <= min) {
		 min = diff[iter]
	 }
	 if (diff[iter] >= max) {
		 max = diff[iter]
	 }
	 sum=sum+diff[iter]
}
END {
  i=1
  printf " Average cycles from command valid to response valid: %s (%s ns)\n", sum/iter, sum/iter*5 
  printf " %s records: Cycle count Min %s, Max %s\n", iter, min, max
  printf "-------------------------------------------------------------\n"
}
