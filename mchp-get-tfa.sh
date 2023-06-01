
# This script is called mchp-get-tfa.sh

wget https://github.com/microchip-ung/arm-trusted-firmware/archive/refs/tags/mchp_v1.0.3.tar.gz
tar xzf mchp_v1.0.3.tar.gz
cd arm-trusted-firmware-mchp_v1.0.3

# Build the fip image.
# This require the the binary BSP to be installed
#
dr ./script/build.rb -p lan966x_b0

# If you have build your own U-Boot from the source BSP,
# i.e. have run
#
# $ dr ./build.rb build --configs arm_bootloaders_lan966
#
# then the result is in output/build_arm_bootloaders_lan966x/images/u-boot-lan966x_evb_atf.bin
#
# Copy that file to arm-trusted-firmware-mchp_v1.0.3 and run
# $ dr ./script/build.rb -p lan966x_b0 -l u-boot-lan966x_evb_atf.bin
# The file (u-boot-lan966x_evb_atf.bin) has to be in the arm-trusted-firmware-mchp_v1.0.3
# folder, since docker (dr) can not see outside its source tree. You can think of it
# having done a chroot.
