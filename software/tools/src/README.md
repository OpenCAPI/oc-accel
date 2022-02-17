# Flash-Image

To compile on target system:

./flsh_compile
./img_reload_compile

To run on target system for card with SPIx8 memory:
./flsh_main <primary bin file> <secondary bin file> <pci device>


Example with capi2 bitstream:
./flsh_main --image_file1 capi2_alphadata_9v3__xcvu3p-ffvc1517-2-i_psl_v1_99_afp__vivado_2017_4_20180214_1243_pslrev000B_user_primary.bin --image_file2 capi2_alphadata_9v3__xcvu3p-ffvc1517-2-i_psl_v1_99_afp__vivado_2017_4_20180214_1243_pslrev000B_user_secondary.bin --devicebdf 0006:00:00.0 --startaddr 0x01000000

Example reload factory location:
./img_reload --image_location factory --devicebdf 0000:01:00.0 > reload_log &
