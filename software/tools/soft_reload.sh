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

echo "##-------------------------------------------------------##"
echo "## This sequence is to set the reload bit to 1 so that   ##"
echo "##  at next oc-reset the FPGA is reloaded from the Flash ##"
echo "##-------------------------------------------------------##"

echo "check that ICAP is ready for programming: Expected read value is 0x00000005"
./snap_peek -C5 -w32 0x0F10
echo "check that WR fifo is empty (3f empty lines) Expected read value is 0x0000003f"
./snap_peek -C5 -w32 0x0F14

echo "Reload sequence pushed in WR fifo"
./snap_poke -C5 -w32 0x0F00 0xFFFFFFFF
./snap_poke -C5 -w32 0x0F00 0xAA995566
./snap_poke -C5 -w32 0x0F00 0x20000000
./snap_poke -C5 -w32 0x0F00 0x30020001
./snap_poke -C5 -w32 0x0F00 0x00000000
./snap_poke -C5 -w32 0x0F00 0x30080001
./snap_poke -C5 -w32 0x0F00 0x0000000F
./snap_poke -C5 -w32 0x0F00 0x20000000

echo "check that WR fifo is NOT empty (37 empty lines) Expected read value is 0x00000037"
./snap_peek -C5 -w32 0x0F14

echo "Flush the FIFO to set the reload bit to 1"
./snap_poke -C5 -w32 0x0F0C 0x00000001

echo "Registers should not be readable anymore: expected 0xffffffff"
./snap_peek -C5 -w32 0x0F14
