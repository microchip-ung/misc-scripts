# misc-scripts
mchp-get-docker.sh is a script that install the docker tools on your linux / Ubuntu machine. This is described in the bsp documentation, http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-doc-latest.html but it is a long tedious task. The instructions are in the file.

mchp-get-tfa.sh is a script, that build the boot code for LAN966x revision B and NOT revision A, which does not support secure boot. Instructions are in the file.

mchp-get-ddr-tool.sh is a script, that get the ddr tool and build an exist configuration for lan966x. If the mchp-get-tfa.sh has be run previously
so that the folder arm-trusted-firmware-$RELEASE exist, then the builded DDR configuration is compared with the one delivered
in arm-trusted-firmwaere-$RELEASE to demonstrate that you can build the same thing.

As an exercise it is suggested to run the scripts in the order:
```
 $ mchp-get-docker.sh
 $ mchp-get-tfa.sh
 $ mchp-get-ddr-tool.sh
```
from the same folder.

build-uboot-2023.06-lan966x.sh can build U-Boot and wrap it into ATF (arm trusted firmware) in order to generate an image tha can be programmed to the NOR flash, and that LAN966x revision B (that has secure boot) can read. This script also need the bsp2023.06.patch to fix an error in the BSP source (but thats a minor complication. This will be fixed in later releases.). The instructions are in the script.

build-uboot-2023.06-lan966x-wo-buildroot.sh can build U-Boot and wrap it into ATF (arm trusted firmware) without using buildroot. This is the way to go, if you are doing development on uboot.
