#!/usr/bin/env bash

# You need to have the BSP binary and toolchain installed.
# Documentation can be found at https://microchip-ung.github.io/bsp-doc/bsp/2024.03/index.html



# (1.1) --- Get latest BSP source code, untar it, 
#
wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-source-2024.03.tar.gz
tar xzf mscc-brsdk-source-2024.03.tar.gz

#                                                 and patch it for minor bug.

git clone https://github.com/microchip-ung/misc-scripts
cd mscc-brsdk-source-2024.03
patch -p1 < ../misc-scripts/bsp2024.03.patch


# (1.2) --- Configure and build bbb bootloader
#
make BR2_EXTERNAL=./external O=bbb arm_bootloaders_bbb_defconfig
make BR2_EXTERNAL=./external O=bbb


# (1.3) --- Show the relevant files. It is the bbb.img that is written to the flash.
#           You can see in board/beaglebone/gen-image.rb how it is constructed from the
#           MLO and u-boot.img file.
#
ls -l bbb/images


# (1.4) --- Write the images/bbb.img to sdcard with e.g.
#           $ dd if=images/bbb.img of=/dev/<the-sd-card>
echo "--->Put the bbb.img on a sd card with 'dd if=images/bbb.img of=/dev/<the-sd-card>'"
cd ..

# (1.5) --- With the sdcard in the beaglebone, you can boot from it by holding down the
#           boot button on the flip side of the sdcard when powering on the board.
#
#           You'll need a serial terminal on the board so you can see that is stops in u-boot.
#
#           In u-boot create the following environment variables:         
#
# => setenv ramboot 'bootm start ${loadaddr}#${pcb}; bootm loados ${loadaddr}#${pcb}; bootm ramdisk ${loadaddr}#${pcb}; run set_rootargs; run setup; bootm fdt ${loadaddr}#${pcb}; bootm prep ${loadaddr}#${pcb}; bootm go ${loadaddr}#${pcb}'
# => setenv pcb 'pcb134'
# => setenv bootcmd 'dhcp <TFTP_IP>:<path>/armv7_vsc7558TSN.itb; run ramboot'
# => saveenv
#
# The armv7_vsc7558TSN.itb is build in the next section:


# (2.1) --- Get MESA and prepare a mesa-demo build for VSC7558 running on Beaglebone.
#
wget https://github.com/microchip-ung/mesa/releases/download/v2024.03/mesa-v2024.03.tar.gz
tar xzf mesa-v2024.03.tar.gz
cd mesa-v2024.03
.cmake/create_cmake_project.rb arm my-bbb
cd my-bbb
./cmake .. -DIMG_armv7_vsc7558TSN_fit=ON


# (2.2) --- Build and show the result file
#
make
ls mesa/demo/*.itb


# (2.3) --- Put to image on the tftp server
#
tftppath="/tftpboot/<user>"
if [ -d $tftppath ]; then
    cp mesa/demo/*.itb $tftppath
    echo "--->Image has been copied to tftp server at ${tftppath}"
else
    echo "--->Image not copied to tftp server"
fi
cd ../..

# (3.1) --- At this point you should be able to run the command
#           'run bootcmd' on the Beaglebone (see step 1.5 above) in order to
#           download the itb file and start it

# (3.2) --- When the Beablebone has started the itb image, you can login
#           with username=root and no password.

# (3.3) --- Then start the mesa-demo by running
#             $ export pcb=pcb134
#             $ mesa-demo -s /dev/spidev1.0
#           It should start witout errors.
#           You can now run the
#             $ mesa-cmd
#           to see what commands that can be given. Try e.g.
#             $ mesa-cmd debug chip id
#
#           If you have network on the NPI port, then
#             $ mesa-cmd port state
#           should show that it is up.
