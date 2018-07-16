#!/bin/bash

echo "export PEER_NAME=$(hostname)" >> /root/.bashrc
echo "export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')" >> /root/.bashrc
source /root/.bashrc

ssh-keygen -t rsa -b 4096 -C pedro.clopes@syone.com
ssh-copy-id root@192.168.122.20

mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca-key.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/client.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/client-key.pem .
scp root@kub-master-01.syone.com:/etc/kubernetes/pki/etcd/ca-config.json .

cfssl print-defaults csr > config.json
sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer

export ETCD_VERSION="v3.1.12"
curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/


touch /etc/etcd.env
echo "PEER_NAME=${PEER_NAME}" >> /etc/etcd.env
echo "PRIVATE_IP=${PRIVATE_IP}" >> /etc/etcd.env

cat >/etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
EnvironmentFile=/etc/etcd.env
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name $(hostname) --data-dir /var/lib/etcd --listen-client-urls https://$PRIVATE_IP:2379 --advertise-client-urls https://$PRIVATE_IP:2379 --listen-peer-urls https://$PRIVATE_IP:2380 --initial-advertise-peer-urls https://$PRIVATE_IP:2380 --cert-file=/etc/kubernetes/pki/etcd/server.pem --key-file=/etc/kubernetes/pki/etcd/server-key.pem --client-cert-auth --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem --peer-cert-file=/etc/kubernetes/pki/etcd/peer.pem --peer-key-file=/etc/kubernetes/pki/etcd/peer-key.pem --peer-client-cert-auth --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem --initial-cluster kub-master-01.syone.com=https://kub-master-01.syone.com:2380,kub-master-02.syone.com=https://kub-master-02.syone.com:2380,kub-master-03.syone.com=https://kub-master-03.syone.com:2380 --initial-cluster-token my-etcd-token --initial-cluster-state new

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd

yum -y install keepalived
systemctl enable keepalived
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.original

if [[ "$PEER_NAME" == "kub-master-01.syone.com" ]]; then
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
 router_id LVS_DEVEL
}

vrrp_script check_apiserver {
 script "/etc/keepalived/check_apiserver.sh"
 interval 3
 weight -2
 fall 10
 rise 2
}

vrrp_instance VI_1 {
   state MASTER
   interface eth0
   virtual_router_id 51
   priority 101
   authentication {
       auth_type PASS
       auth_pass 4be37dc3b4c90194d1600c483e10ad1d
   }
   virtual_ipaddress {
       192.168.122.19
   }
   track_script {
       check_apiserver
   }
}
EOF

else
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
 router_id LVS_DEVEL
}

vrrp_script check_apiserver {
 script "/etc/keepalived/check_apiserver.sh"
 interval 3
 weight -2
 fall 10
 rise 2
}

vrrp_instance VI_1 {
   state BACKUP
   interface eth0
   virtual_router_id 51
   priority 100
   authentication {
       auth_type PASS
       auth_pass 4be37dc3b4c90194d1600c483e10ad1d
   }
   virtual_ipaddress {
       192.168.122.19
   }
   track_script {
       check_apiserver
   }
}
EOF

fi

cat >/etc/keepalived/check_apiserver.sh <<EOF
errorExit() {
   echo "*** $*" 1>&2
   exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 192.168.122.19; then
   curl --silent --max-time 2 --insecure https://192.168.122.19:6443/ -o /dev/null || errorExit "Error GET https://192.168.122.19:6443/"
fi
EOF

systemctl restart keepalived
systemctl status keepalived

scp root@kub-master-0.syone.com:/etc/kubernetes/pki/* /etc/kubernetes/pki
rm /etc/kubernetes/pki/apiserver*
