#!/bin/bash
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
