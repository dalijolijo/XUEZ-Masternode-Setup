#!/bin/bash
set -u

DOCKER_REPO="dalijolijo"
CONFIG="/home/xuez/.xuez/xuez.conf"
CONTAINER_NAME="xuez-masternode"
RPC_PORT="41798"
WEB="github.com/dalijolijo/XUEZ-Masternode-Setup/blob/master" # without "https://" and without the last "/" (only HTTPS accepted)
BOOTSTRAP="bootstrap.tar.gz"

#
# Check if xuez.conf already exist. Set xuez user pwd
#
clear
REUSE="No"
printf "\nDOCKER SETUP FOR XUEZ MASTERNODE\n"
printf "\nSetup Config file"
printf "\n-----------------"
if [ -f "$CONFIG" ]
then
        printf "\nFound $CONFIG on your system.\n"
        printf "\nDo you want to re-use this existing config file?\n" 
        printf "Enter [Y]es or [N]o and Hit [ENTER]: "
        read REUSE
fi

if [[ $REUSE =~ "N" ]] || [[ $REUSE =~ "n" ]]; then
        printf "\nFound the following IP-addresses on this Server:\n"
	hostname -I
	printf "\nEnter the IP-address of your XUEZ Masternode Server and Hit [ENTER]: "
        read XIP
	printf "Enter new Password for [xuez] user and Hit [ENTER]: "
        read XPWD
        printf "Enter your XUEZ Masternode genkey respond and Hit [ENTER]: "
        read MN_KEY
else
        source $CONFIG
	XIP=$(echo $externalip)
        XPWD=$(echo $rpcpassword)
        MN_KEY=$(echo $masternodeprivkey)
fi

#
# Check distro version for further configurations
#
printf "\nDocker Host Operating System"
printf "\n----------------------------\n"
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
printf "Found installed $OS $VER\n"

#
# Setup Firewall, install further packages...
#
printf "\nSetup Firewall"
printf "\n--------------\n"

# Configuration for Fedora
if [[ $OS =~ "Fedora" ]] || [[ $OS =~ "fedora" ]] || [[ $OS =~ "CentOS" ]] || [[ $OS =~ "centos" ]]; then
    FIREWALLD=0

    # Check if firewalld is installed
    which firewalld >/dev/null
    if [ $? -eq 0 ]; then
        printf "Found firewall 'firewalld' on your system.\n"
        printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
        printf "\nDo you want to start automated firewall setup?\n"
        printf "Enter [Y]es or [N]o and Hit [ENTER]: "
        read FIRECONF
        
        if [[ $FIRECONF =~ "Y" ]] || [[ $FIRECONF =~ "y" ]]; then

            # Firewall settings
            printf "\nSetup firewall...\n"
            firewall-cmd --permanent --zone=public --add-port=22/tcp
            firewall-cmd --permanent --zone=public --add-port=${RPC_PORT}/tcp
            firewall-cmd --reload
	fi
        FIREWALLD=1
    fi

    if [ $FIREWALLD -ne 1 ]; then
    
        # Check if ufw is installed
        which ufw >/dev/null
        if [ $? -ne 0 ]; then
            if [[ $OS =~ "CentOS" ]] || [[ $OS =~ "centos" ]]; then
                printf "Missing firewall (firewalld) on your system.\n"
                printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
                printf "\nDo you want to install firewall (firewalld) and execute automated firewall setup?\n"
                printf "Enter [Y]es or [N]o and Hit [ENTER]: "
                read FIRECONF
                
                if [[ $FIRECONF =~ "Y" ]] || [[ $FIRECONF =~ "y" ]]; then
                    #Installation of ufw, if not installed yet
                    which ufw >/dev/null
                    if [ $? -ne 0 ];then
                        sudo yum install -y firewalld firewall-config
                        systemctl start firewalld.service
                        systemctl enable firewalld.service
                    fi

                    # Firewall settings
                    printf "\nSetup firewall...\n"
                    firewall-cmd --permanent --zone=public --add-port=22/tcp
                    firewall-cmd --permanent --zone=public --add-port=${RPC_PORT}/tcp
                    firewall-cmd --reload
                fi
            else
                printf "Missing firewall (ufw) on your system.\n"
                printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
                printf "\nDo you want to install firewall (ufw) and execute automated firewall setup?\n"
                printf "Enter [Y]es or [N]o and Hit [ENTER]: "
                read FIRECONF
            fi
        else
            printf "Found firewall 'ufw' on your system.\n"
            printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
            printf "\nDo you want to start automated firewall setup?\n"
            printf "Enter [Y]es or [N]o and Hit [ENTER]: "
            read FIRECONF
        fi

        if [[ $FIRECONF =~ "Y" ]] || [[ $FIRECONF =~ "y" ]]; then
            #Installation of ufw, if not installed yet
            which ufw >/dev/null
            if [ $? -ne 0 ];then
               sudo yum install -y ufw
            fi

            # Firewall settings
            printf "\nSetup firewall...\n"
            ufw logging on
            ufw allow 22/tcp
            ufw limit 22/tcp
            ufw allow ${RPC_PORT}/tcp
            # if other services run on other ports, they will be blocked!
            #ufw default deny incoming
            ufw default allow outgoing
            yes | ufw enable
        fi
    fi

    # Installation further package
    printf "\nPackages Setup"
    printf "\n--------------\n"
    printf "Install further packages...\n"
    sudo yum install -y ca-certificates \
                        curl

    # Start and activate docker
    systemctl start docker.service
    systemctl enable docker.service

# Configuration for Ubuntu/Debian/Mint
elif [[ $OS =~ "Ubuntu" ]] || [[ $OS =~ "ubuntu" ]] || [[ $OS =~ "Debian" ]] || [[ $OS =~ "debian" ]] || [[ $OS =~ "Mint" ]] || [[ $OS =~ "mint" ]]; then
    
    # Check if firewall ufw is installed
    which ufw >/dev/null
    if [ $? -ne 0 ];then
        printf "Missing firewall (ufw) on your system.\n"
        printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
        printf "\nDo you want to install firewall (ufw) and execute automated firewall setup?\n"
        printf "Enter [Y]es or [N]o and Hit [ENTER]: "
        read FIRECONF
    else
        printf "Found firewall 'ufw' on your system.\n"
        printf "Automated firewall setup will open the following ports: 22 and ${RPC_PORT}\n"
        printf "\nDo you want to start automated firewall setup?\n"
        printf "Enter [Y]es or [N]o and Hit [ENTER]: "
        read FIRECONF
    fi

    if [[ $FIRECONF =~ "Y" ]] || [[ $FIRECONF =~ "y" ]]; then
        # Installation of ufw, if not installed yet
        which ufw >/dev/null
        if [ $? -ne 0 ];then
           apt-get update
           sudo apt-get install -y ufw
        fi

        # Firewall settings
        printf "\nSetup firewall...\n"
        ufw logging on
        ufw allow 22/tcp
        ufw limit 22/tcp
        ufw allow ${RPC_PORT}/tcp
        # if other services run on other ports, they will be blocked!
        #ufw default deny incoming
        ufw default allow outgoing
        yes | ufw enable
    fi

    # Installation further package
    printf "\nPackages Setup"
    printf "\n--------------\n"
    printf "Install further packages...\n"
    apt-get update
    sudo apt-get install -y apt-transport-https \
                            ca-certificates \
                            curl \
                            software-properties-common
else
    printf "Automated firewall setup for $OS ($VER) not supported!\n"
    printf "Please open firewall ports 22 and ${RPC_PORT} manually.\n"
fi

#
# Pull docker images and run the docker container
#
printf "\nStart Docker container"
printf "\n----------------------\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -eq 0 ];then
    printf "Conflict! The container name \'${CONTAINER_NAME}\' is already in use.\n"
    printf "\nDo you want to stop the running container to start the new one?\n"
    printf "Enter [Y]es or [N]o and Hit [ENTER]: "
    read STOP

    if [[ $STOP =~ "Y" ]] || [[ $STOP =~ "y" ]]; then
        docker stop ${CONTAINER_NAME}
    else
	printf "\nDocker Setup Result"
        printf "\n----------------------\n"
        printf "Canceled the Docker Setup without starting XUEZ Masternode Docker Container.\n\n"
	exit 1
    fi
fi
docker rm ${CONTAINER_NAME} >/dev/null
docker pull ${DOCKER_REPO}/xuez-masternode
docker run -p ${RPC_PORT}:${RPC_PORT} --name ${CONTAINER_NAME} -e XIP="${XIP}" -e XPWD="${XPWD}" -e MN_KEY="${MN_KEY}" -e WEB="${WEB}" -e BOOTSTRAP="${BOOTSTRAP}" -v /home/xuez:/home/xuez:rw -d ${DOCKER_REPO}/xuez-masternode

#
# Show result and give user instructions
#
clear
printf "\nDocker Setup Result"
printf "\n----------------------\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -ne 0 ];then
    printf "Sorry! Something went wrong. :(\n"
else
    printf "GREAT! Your XUEZ Masternode Docker Container is running now! :)\n"
    printf "\nShow your running docker container \'${CONTAINER_NAME}\' with 'docker ps'\n"
    sudo docker ps | grep ${CONTAINER_NAME}
    printf "\nJump inside the docker container with 'docker exec -it ${CONTAINER_NAME} bash'\n"
    printf "HAVE FUN!\n\n"
fi
