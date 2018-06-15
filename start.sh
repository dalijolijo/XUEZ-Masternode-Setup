#!/bin/bash
set -u

BOOTSTRAP='bootstrap.tar.gz'

#
# Set passwd of xuez user
#
echo xuez:${XPWD} | chpasswd

#
# Downloading xuez.conf
#
cd /tmp/
wget https://raw.githubusercontent.com/dalijolijo/XUEZ-Masternode-Setup/master/xuez.conf -O /tmp/xuez.conf
chown xuez:xuez /tmp/xuez.conf

#
# Set rpcuser, rpcpassword and masternode genkey
#
printf "** Set rpcuser, rpcpassword and masternode genkey ***\n"
mkdir -p /home/xuez/.xuez/
chown -R xuez:xuez /home/xuez/
sudo -u xuez cp /tmp/xuez.conf /home/xuez/.xuez/
sed -i "s/^\(rpcuser=\).*/rpcuser=xuezmasternode${XPWD}/" /home/xuez/.xuez/xuez.conf
sed -i "s/^\(rpcpassword=\).*/rpcpassword=${XPWD}/" /home/xuez/.xuez/xuez.conf
sed -i "s/^\(externalip=\).*/externalip=${XIP}/" /home/xuez/.xuez/xuez.conf 
sed -i "s/^\(masternodeprivkey=\).*/masternodeprivkey=${MN_KEY}/" /home/xuez/.xuez/xuez.conf

#
# Check if RPC Server config to be load 
#
if [[ $MN_KEY =~ "NOT_NEEDED" ]]; then
        sed -i "s/^\(masternode=\).*/masternode=0/" /home/xuez/.xuez/xuez.conf
        sed -i "s/^\(listen=\).*/listen=0/" /home/xuez/.xuez/xuez.conf
fi

#
# Downloading bootstrap file (not yet available)
# Generate it with: 
# 1) Go to blocks folder (e.g. /home/xuez/.xuez/blocks
# 2) Execute after sync: #cat blk000*.dat > bootstrap.dat
#
#printf "** Downloading bootstrap file ***\n"
#cd /home/xuez/.xuez/
#if [ ! -d /home/xuez/.xuez/blocks ] && [ "$(curl -Is https://xuezcoin.com/${BOOTSTRAP} | head -n 1 | tr -d '\r\n')" = "HTTP/1.1 200 OK" ] ; then \
#        sudo -u xuez wget https://xuezcoin.com/${BOOTSTRAP}; \
#        sudo -u xuez tar -xvzf ${BOOTSTRAP}; \
#        sudo -u xuez rm ${BOOTSTRAP}; \
#fi

#
# Starting XUEZ Service
#
# Hint: docker not supported systemd, use of supervisord
printf "*** Starting XUEZ Service ***\n"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
