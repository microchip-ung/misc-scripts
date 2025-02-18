#
# Build U-Boot/ATF for lan969x rev A.
#
# This script use docker as in 'dr make ...'. If you do not want to use docker, all
# the right tools need to be installed on your build machine.
#
# Docker can be installed by following the BSP documentation in https://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp
# or you can get a script:
#  $ git clone https:/github.com/microchip-ung/misc-scripts
# and run the mscp-get-docker.sh script. Instructions are in the script.
#



R=2024.12          # BSP release number
T=v2.8.17-mchp1    # ATF release tag



# (1) --- Start by getting the packages we need:
#          - The BSP source code in order to be able to build U-Boot
#          - The DDR tool in order to be able to build a DDR configuration
#          - The ATF tool in order to be able to generate a fip image with the U-Boot and DDR configuration
#
#         These 3 packages are only retrived if they do not appear to exist already.

# (1.1) --- Get the BSP source for 2024.12 (as defined with 'P') if it does not exist.
#
if [ ! -d mscc-brsdk-source-$R ]; then
    wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-source-$R.tar.gz
    tar xzf mscc-brsdk-source-$R.tar.gz
fi

# (1.2) --- Get ddr tool
#
if [ ! -d ddr-umctl ]; then
    git clone https://github.com/microchip-ung/ddr-umctl
    cd ddr-umctl
    # There is only a main branch. git checkout xxx
    cd ..
fi

# (1.3) --- Get Trusted Firmware for ARM (ATF)
#
if [ ! -d arm-trusted-firmware ]; then
    git clone https://github.com/microchip-ung/arm-trusted-firmware
    cd arm-trusted-firmware
    git checkout $T
    cd ..
fi


# Documentation: -In section (A) the U-Boot is build. This end up with a .bin file that we will use. Other files are also generated,
#                but since we intend to build our own ddr configuration is step (B) we will need the .bin file. It will first be used in
#                step (C) as one of the inputs to the ATF tool.
#                -In section (B) the DDR configuration is build. The result is the file 'my-lan969x-ddr.dtsi', which contain the entire DDR parameter
#                configurations. This .dtsi file needs to be copied into the atf source tree an have a specific name in order to replace the verision
#                used for the LAN969x laguna board.
#                -In section (C) the build U-Boot (from section (A)) and the ddr configuration (from section (B)) are build into a .fip file that can be
#                programed to e.g. the NOR flash.

# The AA, BB, CC variables are put in, so that you have a easy way to trailer the build. If e.g. you have build U-Boot as in section (A) and
# do not need for it to be done again, then you can turn that off. Similar with the other sections.



AA="default"
# AA="rebuild"
# AA="disable"

# (A) --- Build U-Boot part
#
if [ "$AA" = "default" ]; then

    cd mscc-brsdk-source-$R

    # (A.1) --- The defconfig in the 3rd argument is in external/configs/
    #         But only if 'myuboot' does not already exist.
    #
    if [ ! -d myuboot ]; then
	dr make  BR2_EXTERNAL=./external  O=myuboot  arm64_bootloaders_defconfig
    fi
    
    # (A.2) --- Build 
    #
    dr make  BR2_EXTERNAL=./external  O=myuboot
    cd ..

    # When done the result is in myuboot/images. There are :
    #
    #    lan969x_a0-release.fip
    #    lan969x_a0_signed-release.fip
    #    lan969x_lm_sram_emmc-release.fip
    #    lan969x_lm_sram_emmc-release.gpt
    #    lan969x_lm_sram_nor-release.img
    #    u-boot-mchp_lan969x.bin
    #    u-boot-mchp_lan969x_signed.bin
    #    u-boot-mchp_lan969x_sram.bin
    #
    # plus some that related to SparX5, which is not relevant in the context of LAN969x
    #
    # The .fip images can be used on the Microchip EVBs, but has the DDR configuration that apply th these boards.
    #
    # If we want to provide aonther DDR configuration, then  We have to take the second, i.e., u-boot-mchp_lan966x_evb.bin and run it
    # through the ATF (ARM Trusted Firmware) tool ourselves. https://github.com/microchip-ung/arm-trusted-firmware
    # 
fi


# (A.3) --- Rebuild U-Boot part
#           If U-Boot has been build already as in step (A), and you has changed some source code of it
#           or have run menuconfig, as in: 'dr make  BR2_EXTERNAL=./external  O=myuboot  mscc-muboot-menuconfig'
#           then U-Boot need to be rebuild.
#           Changing the source or running menuconfig is done outside this script in the file tree created in (A).
#           Then you can disbale the (A) section and enable the (A.1) section to make sure everything is build consistently.
#
if [ "$AA" = "rebuild" ]; then
    dr make  BR2_EXTERNAL=./external  O=myuboot  mscc-muboot-rebuild
    dr make  BR2_EXTERNAL=./external  O=myuboot
fi



BB="default"
# BB="disable"

# (B) --- Build ddr configuration
#
if [ "$BB" = "default" ]; then

    # (B.1) --- Select which DDR profile to use
    #
    P=lan969x_evb_ddr4.yaml

    cd ddr-umctl
    ./scripts/gen_cfg.rb -f devicetree configs/profiles/$P > my-lan969x-ddr.dtsi
    ./scripts/gen_cfg.rb -f YAML configs/profiles/$P > my-lan969x-ddr.yaml

    # (Note) ---
    # /plat/microchip/lan969x/lan969x_a0/fdts/lan969x_a0_tb_fw_config.dts
    # this dts file include the plat/microchip/lan969x/fdts/lan969x-ddr.dtsi
    #

    cd ..
    A=arm-trusted-firmware/plat/microchip/lan969x/fdts

    # (B.2) --- Make a backup of the original lan969x-ddr.dtsi if not already
    #           We do not really need to do that, but maybe it is nice to have
    #           the original for comparison
    #
    if [ ! -e $A/lan969x-ddr.dtsi.bk ]; then
	cp $A/lan969x-ddr.dtsi $A/lan969x-ddr.dtsi.bk
    fi

    cp ddr-umctl/my-lan969x-ddr.dtsi $A/lan969x-ddr.dtsi
fi



CC="default"
# CC="disable"

# (C) --- ATF
#
if [ "$CC" = "default" ]; then

    # (C.1) --- prepear tne ATF build:
    #         1) Copy the U-Boot build in step A to the root of arm-trusted-firmware.
    #            If docker is used, it cant access files outside it root.
    #         2) Copy the ddr dts configuration build in step B to certain folder for
    #            ATF to use it.

    # (C.2) --- U-Boot copy
    #
    F=u-boot-mchp_lan969x.bin
    cp mscc-brsdk-source-$R/myuboot/images/$F arm-trusted-firmware/

    # (C.3) --- ddr dts copy
    #
    A=arm-trusted-firmware/plat/microchip/lan969x/fdts

    # --- Make a backup of the original lan969x-ddr.dtsi if not already
    #     We do not really need to do that, but maybe it is nice to have
    #     the original for comparison
    #
    if [ ! -e $A/lan969x-ddr.dtsi.bk ]; then
	cp $A/lan969x-ddr.dtsi $A/lan969x-ddr.dtsi.bk
    fi

    cp ddr-umctl/my-lan969x-ddr.dtsi $A/lan969x-ddr.dtsi

    # (C.4) --- Build ATF
    #
    cd arm-trusted-firmware
    dr ./scripts/build.rb  -p lan969x_a0  --bl33-blob $F
    cd ..

    # (C.5) --- Copy the result to root.
    #         There are other files in arm-trusted-firmware/build/lan966x_b0/debug/
    #         that may be useful to you, so take a look.
    #
    cp arm-trusted-firmware/build/lan969x_a0/debug/fip.bin .

    echo "------> The result is the fip.bin in the current directory <------"
    ls -l fip.bin
fi
