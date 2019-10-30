# Enable a new FPGA card to OC-Accel

Create a folder in `hardware/oc-bip/board_support_packages/<NEW_CARD>`

Call the `make` process under `hardware/oc-bip/<NEW_CARD>`

Add the CARD_TYPE, and other specific IPs in OC-Accel `hardware/setup`

Modify the related CARD_TYPE related information in `software`

Add the card choice in Kconfig Menu `scripts/Kconfig`

TODO: More details to be put down.

