# XUEZ Masternode - Dockerfile (06-2018)
#
# The Dockerfile will install all required stuff to run a XUEZ Masternode. 
# XUEZ Repo : https://github.com/XUEZ/xuez
# 
# To build a docker image for xuez-masternode from the Dockerfile the xuez.conf is also needed.
# See BUILD_README.md for further steps.

# Use an official Ubuntu runtime as a parent image
FROM ubuntu:16.04

LABEL maintainer="David B. (dalijolijo)"
LABEL version="0.1"

# Make ports available to the world outside this container
# RPCPort = 41798
EXPOSE 41798

USER root

# Change sh to bash
SHELL ["/bin/bash", "-c"]

# Define environment variable
ENV XPWD "xuez"

RUN echo '*** XUEZ Masternode ***'

#
# Creating xuez user
#
RUN echo '*** Creating xuez user ***' && \
    adduser --disabled-password --gecos "" xuez && \
    usermod -a -G sudo,xuez xuez && \
    echo xuez:$XPWD | chpasswd

#
# Running updates and installing required packages
#
#
RUN echo '*** Running updates and installing required packages ***' && \
    apt-get update -y && \
    apt-get dist-upgrade -y && \
    apt-get install -y  apt-utils \
                        autoconf \
                        automake \
                        autotools-dev \
                        bsdmainutils \
                        build-essential \
                        curl \
                        git \
                        libboost-all-dev \
                        libevent-dev \
                        libminiupnpc-dev \
                        libssl-dev \
                        libtool \
                        libzmq5-dev \
                        pkg-config \
                        python-virtualenv \
                        software-properties-common \
                        sudo \
                        supervisor \
                        vim \
                        wget && \
    add-apt-repository -y ppa:bitcoin/bitcoin && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y  libdb4.8-dev \
                        libdb4.8++-dev 
                        
#
# Cloning and Compiling XUEZ Wallet
#
RUN echo '*** Cloning and Compiling XUEZ Wallet ***' && \
    cd && \
    echo "Execute a git clone of XUEZ. Please wait..." && \
    git clone https://github.com/XUEZ/xuez.git && \
    cd xuez && \
    ./autogen.sh && \
    ./configure --disable-dependency-tracking --enable-tests=no --without-gui && \
    make && \
    cd && \
    cd xuez/src && \
    strip xuezd && \
    cp xuezd /usr/local/bin && \
    strip xuez-cli && \
    cp xuez-cli /usr/local/bin && \
    strip xuez-tx && \
    cp xuez-tx /usr/local/bin && \
    chmod 775 /usr/local/bin/xuezd* && \   
    cd && \
    rm -rf xuez

#
# Copy Supervisor Configuration and xuez.conf
#
RUN echo '*** Copy Supervisor Configuration and xuez.conf ***'
COPY *.sv.conf /etc/supervisor/conf.d/
COPY xuez.conf /tmp

#
# Logging outside docker container
#
VOLUME /var/log

#
# Start script
#
RUN echo '*** Copy start script ***'
COPY start.sh /usr/local/bin/start.sh
RUN rm -f /var/log/access.log && mkfifo -m 0666 /var/log/access.log && \
    chmod 755 /usr/local/bin/*

ENV TERM linux
CMD ["/usr/local/bin/start.sh"]
