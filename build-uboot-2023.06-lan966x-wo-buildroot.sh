#
# Build U-Boot/ATF for lan966x rev B. without buildroot.
# This is the way to go if you are doing development on uboot.
#
# This script use docker as in 'dr make ...'. If you do not want to use docker, all
# the right tools need to be installed on your build machine.
#
# Docker can be installed by following the BSP documentation in https://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp
# or you can get a script:
#  $ git clone https:/github.com/microchip-ung/misc-scripts
# and run the mscp-get-docker.sh script. Instructions are in the script.
#

P=2023.06

# (1) --- Get the BSP source for 2023.06 (as defined with 'P') if it does not exist.
#
if [ ! -d mscc-brsdk-source-$P ]; then
#    wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-source-$P.tar.gz
    tar xzf mscc-brsdk-source-$P.tar.gz
fi

cd mscc-brsdk-source-$P

MAKE="make ARCH=arm \
     CROSS_COMPILE=/opt/mscc/mscc-brsdk-arm-2023.06/arm-cortex_a8-linux-gnu/xstax/release/x86_64-linux/usr/bin/arm-linux-"


# (2) --- The defconfig in the 3rd argument is in external/configs/
#
cd dl/mscc-muboot
tar xzf mscc-muboot-45c55b669bab99b99d09a223612029b35c98d08e-br1.tar.gz
cd mscc-muboot-45c55b669bab99b99d09a223612029b35c98d08e
$MAKE mchp_lan966x_evb_defconfig
$MAKE

# (3) --- Go back
#
cd ../../../..

# (4) --- Checkout revision 1.0.4 of ATF if the arm-trusted-firmware folder does not exist.
#
if [ ! -d arm-trusted-firmware ]; then
    git clone https://github.com/microchip-ung/arm-trusted-firmware
    cd arm-trusted-firmware
    git checkout mchp_v1.0.4
    cd ..
fi


# (5) --- Copy U-Boot to the root of arm-trusted-firmware.
#         If docker is used, it cant access files outside it root.
#
cp mscc-brsdk-source-$P/dl/mscc-muboot/mscc-muboot-45c55b669bab99b99d09a223612029b35c98d08e/u-boot.bin arm-trusted-firmware/

cd arm-trusted-firmware

dr ./scripts/build.rb  -p lan966x_b0  --bl33-blob u-boot.bin
cd ..

# (6) --- Copy the result to root.
#         There are other files in arm-trusted-firmware/build/lan966x_b0/debug/
#         that may be useful to you, so take a look.
cp arm-trusted-firmware/build/lan966x_b0/debug/fip.bin .


