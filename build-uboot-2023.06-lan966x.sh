#
# Build U-Boot/ATF for lan966x rev B.
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
    wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-source-$P.tar.gz
    tar xzf mscc-brsdk-source-$P.tar.gz
    cd mscc-brsdk-source-$P
    patch -p1 < ../bsp2023.06.patch # Fix of an error in gen-uboot.rb
    cd ..
fi

cd mscc-brsdk-source-$P


# (2) --- The defconfig in the 3rd argument is in external/configs/
#
dr make  BR2_EXTERNAL=./external  O=output/myuboot  arm_bootloaders_lan966x_defconfig


# (3) --- Build 
#
dr make  BR2_EXTERNAL=./external  O=output/myuboot
cd ..

# When done the result is in output/myuboot/images. There are :
#   lan966x_b0-release-bl2normal-auth.fip
#   u-boot-mchp_lan966x_evb.bin
#   u-boot-mchp_lan966x_svb.bin
#
# It is in principle the first we need, but there is another bug in 2023.06,
# so it does not work.
# We have to take the second, i.e., u-boot-mchp_lan966x_evb.bin and run it
# through the ATF (ARM Trusted Firmware) tool ourselves. https://github.com/microchip-ung/arm-trusted-firmware
# 


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
cp mscc-brsdk-source-$P/output/myuboot/images/u-boot-mchp_lan966x_evb.bin arm-trusted-firmware/
cd arm-trusted-firmware
dr ./scripts/build.rb  -p lan966x_b0  --bl33-blob u-boot-mchp_lan966x_evb.bin
cd ..


# (6) --- Copy the result to root.
#         There are other files in arm-trusted-firmware/build/lan966x_b0/debug/
#         that may be useful to you, so take a look.
cp arm-trusted-firmware/build/lan966x_b0/debug/fip.bin .

