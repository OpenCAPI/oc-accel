#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------
#set false path between async clock area.
#This file is only used when action clock frequency != 200MHz
#for 9H7
set_false_path -from [get_clocks oc0_clock_afu] -to [get_clocks clk_out1_user_clock_gen]
set_false_path -from [get_clocks clk_out1_user_clock_gen] -to [get_clocks oc0_clock_afu]
#for 9H3
set_false_path -from [get_clocks clock_afu] -to [get_clocks clk_out1_user_clock_gen]
set_false_path -from [get_clocks clk_out1_user_clock_gen] -to [get_clocks clock_afu]
