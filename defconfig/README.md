From the oc-accel directory, you can use 2 ways to configure and use the OC-ACCEL framework.

Option 1 (default): use the Kconfig menu by typing: **make snap_config**
 This will allow you to define a specific configuration which will be saved in the *.snap_config* file
 All commands **make model/sim/image** will use this *.snap_config* file

Option 2: do not use the Kconfig menu but use a specific saved configuration file (automated test -jenkins)
 Build a *.snap_config* file using the Kconfig menu  (see option 1)
 Then move and rename the *.snap_config* file to *CARD.action.defconfig* into the *oc-accel/defconfig* directory.
 Following command can then be executed (from oc-accel installation directory):
   **make CARD.action.defconfig** to set the *.snap_config* with the *CARD.action.defconfig* configuration
 All commands **make model/sim/image** will then use this *.snap_config file*
   
