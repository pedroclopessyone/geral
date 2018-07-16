#!/bin/bash

### Install Docker
yum install -y docker
systemctl enable docker && systemctl start docker

#### Add Kubernetes Repo and Install kubeadm, kubelet and kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
#yum install -y kubelet kubeadm kubectl ==> instala a ultima versao dos componentes. atualmente 1.11.0
yum install kubelet-1.10.5 kubeadm-1.10.5 kubectl-1.10.5 -y
systemctl enable kubelet && systemctl start kubelet

### Solve issue regarding traffic being routed incorrectly due to iptables being bypassed
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

### Configure cgroup driver used by kubelet on Master Node
docker info | grep -i cgroup
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
