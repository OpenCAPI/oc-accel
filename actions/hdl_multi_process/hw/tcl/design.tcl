set action_hw $::env(ACTION_ROOT)/hw
set action_ip_dir $::env(ACTION_ROOT)/ip

add_files -scan_for_includes -norecurse $action_hw/framework

# Framework and Regex IP
foreach ip_xci [exec find $action_ip_dir -name *.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        importing IP $ip_name (in framework)"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}

