
# This script is called 'mchp-get-docker.sh'

# Step 1: Run $ . mchp-get-docker.sh docker
# Step 2: Reboot ubuntu machine
# Step 3: Run $ . mchp-get-docker bsp
#
# Reference:
# A: http://mscc-ent-open-source.s3-website-eu-west-1.amazonaws.com/?prefix=public_root/bsp/
#    where you can finde the BSP source (mscc-brsdk-source-2023.03.tar.gz) and
#    the BSP documentation (mscc-brsdk-doc-2023.03.html)
#    E.g. after you have downloaded the source BSP you can say
#    $ tar xzf mscc-brsdk-source-2023.03.tar.gz           # unpacket the tar.gz file
#    $ cd mscc-brsdk-source-2023.03                       # go into the root of the source
#    $ dr ./build build --configs arm_bootloaders_lan966x # run the build.rb script in the
#                                                         # docker environment that has the apripiated tools.
#    Alternative you would say
#    $ ./build.rb build --configs arm_bootloaders_lan966x
#    but then you would need to make sure that the correct build tools is on your
#    ubuntu machine. That is what docker provide.
#
# B: https://github.com/microchip-ung/arm-trusted-firmware
#    This TF-A (ARM trusted firmware) can also be build. See the mchp-get-tfa.sh script.
#

 if [ "$1" == "docker" ]; then

    # (1) --- Install docker (BSP 1.10 Using Docker: https://docs.docker.com/engine/install/ubuntu)
    #
    sudo apt install gnome-terminal
    sudo apt remove docker-desktop
    sudo apt-get install
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg lsb-release
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo docker run hello-world # This check that docker is working. Check the output.

    # (2) --- Install some of our own stuff (Microchip)
    #
    git clone http://github.com/microchip-ung/docker-run
    sudo cp docker-run/dr /usr/local/bin/
    sudo chmod a+x /usr/local/bin/dr 

    # (3) --- Make me member of docker group
    #                         
    sudo usermod -a -G docker `whoami`

    echo "---> REBOOT, so that group can take effect <---"

 elif [ "$1" == "bsp" ]; then

    # (4) --- Download BSP and unpach BSP source
    #
    sudo mkdir -p /opt/mscc
    wget http://mscc-ent-open-source.s3-eu-west-1.amazonaws.com/public_root/bsp/mscc-brsdk-source-2023.03.tar.gz
    tar xzf mscc-brsdk-source-2023.03.tar.gz 
    cd mscc-brsdk-source-2023.03/

    # (5) --- Build LAN966x U-Boot
    dr ./build.rb build --configs arm_bootloaders_lan966x

 else
    echo " mchp-get-docket.sh [docker | bsp]"
    echo "   Step 1:  $ . mchp-get-docker.sh docker"
    echo "   Step 2: Then reboot the machine."
    echo "   Step 3:  $ . mchp-get-docker.sh bsp"
    echo "   the last step will build U-Boot for LAN966x."
 fi

