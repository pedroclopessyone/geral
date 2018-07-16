#!/bin/bash

echo "export PEER_NAME=$(hostname)" >> /root/.bashrc
echo "export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')" >> /root/.bashrc
source /root/.bashrc

ssh-keygen -t rsa -b 4096 -C pedro.clopes@syone.com
ssh-copy-id root@192.168.122.20
