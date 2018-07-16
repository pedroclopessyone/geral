#!/bin/bash
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca-key.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/client.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/client-key.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca-config.json .

### run this set of commands on all masters, including master0
cfssl print-defaults csr > config.json
sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer
###################################
