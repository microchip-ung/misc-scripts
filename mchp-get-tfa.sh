
# This script is called mchp-get-tfa.sh

# Note: The binary BSP need to be installed for this script to work since the
#  u-boot-lan966x_evb_atf.bin in this BSP need to be available. Ths can be done by running:
#   $ wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-arm-2023.06.tar.gz
#   $ tar xzf /mscc-brsdk-arm-2023.06.tar.gz -C /opt/mscc
#
#  Assuming this is in place, lets continue

#
# (1) --- get the ATF / TF-A tool
#
#         You can enable the release you need, if the latest is not what you want.

#RELEASE=mchp_v1.0.5
#RELEASE_=$RELEASE

#RELEASE=mchp_v1.0.6
#RELEASE_=$RELEASE

#RELEASE=2.6-mchp0
#RELEASE_=v$RELEASE

RELEASE=2.8.8-mchp0
RELEASE_=v$RELEASE

wget https://github.com/microchip-ung/arm-trusted-firmware/archive/refs/tags/$RELEASE_.tar.gz
tar xzf $RELEASE_.tar.gz
cd arm-trusted-firmware-$RELEASE


# (2) --- Build the fip image.
# 
dr ./scripts/build.rb -p lan966x_b0


# Note: If you have build your own U-Boot from the source BSP, lets call it u-boot.bin,
#  then copy it to the arm-trusted-firmware-$RELEASE folder and run
#
#   $ dr ./scripts/build.rb -p lan966x_b0 --bl33_blob u-boot.bin
#
#  The reason u-boot.bin need to be in this location is, that docker can not see outside
#  this sub-tree.

# Note: Howto install Docker is described in the BSP documentation 
#  http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-doc-latest.html
#
#  But you can also use the mchp-get-docker.sh which is found in the same location as
#  this file (the one you are reading).
