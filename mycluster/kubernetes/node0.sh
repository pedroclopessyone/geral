#!/bin/bash

mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd

cat >ca-config.json <<EOF
{
   "signing": {
       "default": {
           "expiry": "43800h"
       },
       "profiles": {
           "server": {
               "expiry": "43800h",
               "usages": [
                   "signing",
                   "key encipherment",
                   "server auth",
                   "client auth"
               ]
           },
           "client": {
               "expiry": "43800h",
               "usages": [
                   "signing",
                   "key encipherment",
                   "client auth"
               ]
           },
           "peer": {
               "expiry": "43800h",
               "usages": [
                   "signing",
                   "key encipherment",
                   "server auth",
                   "client auth"
               ]
           }
       }
   }
}
EOF

cat >ca-csr.json <<EOF
{
   "CN": "etcd",
   "key": {
       "algo": "rsa",
       "size": 2048
   }
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

cat >client.json <<EOF
{
 "CN": "client",
 "key": {
     "algo": "ecdsa",
     "size": 256
 }
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

echo "export PEER_NAME=$(hostname)" >> /root/.bashrc
echo "export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')" >> /root/.bashrc
source /root/.bashrc


cat >config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v1.10.5
api:
  advertiseAddress: 192.168.122.19
  controlPlaneEndpoint: 192.168.122.19
etcd:
  endpoints:
  - https://192.168.122.20:2379
  - https://192.168.122.21:2379
  - https://192.168.122.22:2379
  caFile: /etc/kubernetes/pki/etcd/ca.pem
  certFile: /etc/kubernetes/pki/etcd/client.pem
  keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  podSubnet: 10.244.0.0/16
apiServerCertSANs:
- 192.168.122.19
- $PRIVATE_IP
apiServerExtraArgs:
  endpoint-reconciler-type: lease
EOF

kubeadm init --config=config.yaml
