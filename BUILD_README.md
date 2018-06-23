# XUEZ Masternode - Build Docker Image

The Dockerfile will install all required stuff to run a XUEZ Masternode.

## Requirements
- Linux Ubuntu 16.04 LTS
- Running as docker host server (package docker-ce installed)
```
sudo curl -sSL https://get.docker.com | sh
```

## Needed files
- Dockerfile
- xuez.conf
- xuez.sv.conf
- start.sh

## Allocating 2GB Swapfile
Create a swapfile to speed up the building process. Recommended if not enough RAM available on your docker host server.
```
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## Build docker image
```
docker build -t xuez-masternode .
```

## Push docker image to hub.docker
```
docker tag xuez-masternode <repository>/xuez-masternode
docker login -u <repository> -p"<PWD>"
docker push <repository>/xuez-masternode:<tag>
```
