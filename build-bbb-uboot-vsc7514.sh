#!/usr/bin/env bash

# You need to have the BSP binary and toolchain installed.
# Documentation can be found at https://microchip-ung.github.io/bsp-doc/bsp/2024.03/index.html

# (1.0) --- If we have already build the bbb.img, then we will not do it again.
#
if [ ! -e mscc-brsdk-source-2024.03/bbb/images/bbb.img ]; then
     
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

# (1.5) --- One way to get the image on the SDCard is to boot the BBB the normal way into debian
#           The username is "debian" and password "temppwd".
#           Then board must be on your network, and you can find its IP address by running 'ip addr show'
#           Then on you build machine run 'scp bbb.img debian@<BBB-IP>:' where <BBB-IP> is the IP address
#           you just found of the BBB.
#           Then login in the terminal on the BBB and run 'sudo dd if=bbb.img of=/dev/mmcblk0'

# (1.6) --- With the sdcard in the beaglebone, you can boot from it by holding down the
#           boot button (s2) on the flip side of the sdcard when powering on the board.
#
#           You'll need a serial terminal on the board so you can see that is stops in u-boot.
#
#           In u-boot create the following environment variables:         
#
# => setenv ramboot 'bootm start ${loadaddr}#${pcb}; bootm loados ${loadaddr}#${pcb}; bootm ramdisk ${loadaddr}#${pcb}; run set_rootargs; run setup; bootm fdt ${loadaddr}#${pcb}; bootm prep ${loadaddr}#${pcb}; bootm go ${loadaddr}#${pcb}'
# => setenv pcb 'pcb134'
# => setenv bootcmd 'dhcp <TFTP_IP>:<path>/armv7_vsc7514.itb; run ramboot'
# => saveenv
#
# The armv7_vsc7514 is build in the next section:
else
    echo "bbb.img alreadfy exist so skipping that part"
fi


# (2.1) --- Get MESA and prepare a mesa-demo build for VSC7514 running on Beaglebone.
#
if [ ! -d mesa-v2024.03 ]; then
    wget https://github.com/microchip-ung/mesa/releases/download/v2024.03/mesa-v2024.03.tar.gz
    tar xzf mesa-v2024.03.tar.gz
else
    echo "Folder mesa-v2024.03 already exist, so assuming we can use that"
fi

cd mesa-v2024.03
.cmake/create_cmake_project.rb arm my-vsc7514_bbb
cd my-vsc7514_bbb
./cmake .. -DIMG_armv7_vsc7514_fit=ON


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
#             $ mesa-demo -s /dev/spidev1.0
#           It should start witout errors.
#           You can now run the
#             $ mesa-cmd
#           to see what commands that can be given. Try e.g.
#             $ mesa-cmd debug chip id
#
#           If you have network on a port, then
#             $ mesa-cmd port state
#           should show that it is up.
