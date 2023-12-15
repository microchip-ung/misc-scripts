
# (1) --- Checkout the ddr tool code, if it does not already exist.
#
if [ ! -e ddr-umctl ]; then
    git clone https://github.com/microchip-ung/ddr-umctl.git
fi

# (2) --- Build DDR configuration file for LAN966x
#
DDR_CONFIG_NEW=my-lan966x_ddr_config.c

cd ddr-umctl
./scripts/gen_cfg.rb -f source configs/profiles/lan966x.yaml > $DDR_CONFIG_NEW
cd ..

# (3) --- Connect to the arm-trusted-firmware-xxxx folser, that
#         mch-get-tfa.sh has created. You may need to adjust
#         $RELEASE below, the that it match arm-trusted-firmware-$RELEASE
#
RELEASE=2.8.8-mchp0

if [ ! -e arm-trusted-firmware-$RELEASE ]; then

    echo "The folder arm-trusted-firmware-$RELEASE does not exist."
    echo "So the builded configuration is not compared with an existing one."

else 

    
    DDR_PATH_ORG=arm-trusted-firmware-$RELEASE/plat/microchip/lan966x/common

    DDR_CONFIG_ORG=$DDR_PATH_ORG/lan966x_ddr_config.c
    
    # (4) --- Check the difference between 
    diff  ddr-umctl/$DDR_CONFIG_NEW  $DDR_CONFIG_ORG
    
    if [ "false" = "true" ]; then
	
	# (5) --- If you think my-lan966x_ddr_config.c is ok, then replace the lan966x_ddr_config.c with it
	cp  ddr-umctl/$DDR_CONFIG_NEW  $DDR_CONFIG_ORG
	
	# (6) --- Runstep (2) again
	cd sw-arm-trusted-firmware-$RELEASE
	dr ./script/build.rb -p lan966x_b0

    fi

    
fi
