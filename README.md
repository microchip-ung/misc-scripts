# misc-scripts
mchp-get-docker.sh is a script that install the docker tools on your linux / Ubuntu machine. This is described in the bsp documentation, http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-doc-latest.html but it is a long tedious task. The instructions are in the file.

mchp-get-tfa.sh is a script, that build the boot code for LAN966x revision B and NOT revision A, which does not support secure boot. Instructions are in the file.

build-uboot-2023.06-lan966x.sh can build U-Boot and wrap it into ATF (arm trusted firmware) in order to generate an image tha can be programmed to the NOR flash, and that LAN966x revision B (that has secure boot) can read. This script also need the bsp2023.06.patch to fix an error in the BSP source (but thats a minor complication. This will be fixed in later releases.). The instructions are in the script.
