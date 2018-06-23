# XUEZ Masternode - Run Docker Image

## Adding firewall rules
Open needed ports on your docker host server.
```
ufw logging on
ufw allow 22/tcp
ufw limit 22/tcp
ufw allow 41798/tcp
ufw default deny incoming 
ufw default allow outgoing 
yes | ufw enable
```

## Pull docker image
```
docker pull <repository>/xuez-masternode
```

## Run docker container
```
docker run -p 41798:41798 --name xuez-masternode -e X_IP='X_IP' -e MN_KEY='YOUR_MN_KEY' -v /home/xuez:/home/xuez:rw -d <repository>/xuez-masternode
docker ps
```

## Debbuging within a container (after start.sh execution)
Please execute ```docker run``` without option ```--entrypoint bash``` before you execute this commands:
```
tail -f /home/xuez/.xuez/debug.log

docker ps
docker exec -it xuez-masternode bash
  # you are inside the xuez-masternode container
  root@container# supervisorctl status xuezd
  root@container# cat /var/log/supervisor/supervisord.log
  # Change to xuez user
  root@container# sudo su xuez
  xuez@container# cat /home/xuez/.xuez/debug.log
  xuez@container# xuez-cli getinfo
  xuez@container# xuez-cli getblockcount
  xuez@container# xuez-cli masternode status
```

## Debbuging within a container during run (skip start.sh execution)
```
docker run -p 41798:41798 --name xuez-masternode -e X_IP='X_IP' -e MN_KEY='YOUR_MN_KEY' -v /home/xuez:/home/xuez:rw --entrypoint bash <repository>/xuez-masternode
```

## Stop docker container
```
docker stop xuez-masternode
docker rm xuez-masternode
```
