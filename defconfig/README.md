From the ocaccel directory, you can use 2 ways to configure and use the OC-ACCEL framework.

Option 1 (default): use the Kconfig menu by typing: make ocaccel_config
 This will allow you to define a specific configuration which will be saved in the .ocaccel_config file
 All commands make model/sim/image will use this .ocaccel_config file

Option 2: do not use the Kconfig menu but use a specific saved configuration file (automated test -jenkins)
 Build a .ocaccel_config file using the Kconfig menu  (see option 1)
 Then move and rename the .ocaccel_config file to CARD.action.defconfig into the ocaccel/defconfig directory
 Following command can then be executed:
   make CARD.action.defconfig to set the .ocaccel_config with the CARD.action.defconfig configuration
 All commands make model/sim/image will then use this .ocaccel_config file
   
