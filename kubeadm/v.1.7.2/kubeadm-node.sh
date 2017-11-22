#!/bin/bash

#sh kubeadm-node.sh 172.16.120.151

set -o errexit
set -o nounset
set -o pipefail

MASTER_ADDRESS=${1:-"127.0.0.1"}
KUBE_TOKEN=${2:-"863f67.19babbff7bfe8543"}
DOCKER_MIRRORS=${3:-"https://5md0553g.mirror.aliyuncs.com"}
KUBE_VERSION=1.7.2
KUBE_PAUSE_VERSION=3.0
KUBE_CNI_VERSION=0.5.1
ETCD_VERSION=3.0.17

echo '============================================================'
echo '====================Disable selinux and firewalld...========'
echo '============================================================'
if [ $(getenforce) = "Enabled" ]; then
setenforce 0
fi
systemctl disable firewalld
systemctl stop firewalld

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

cat >> /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf

echo "Disable selinux and firewalld success!"

echo '============================================================'
echo '====================Add docker yum repo...=================='
echo '============================================================'
#docker yum源
cat >> /etc/yum.repos.d/docker.repo <<EOF
[docker-repo]
name=Docker Repository
baseurl=http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7
enabled=1
gpgcheck=0
EOF
echo "Add docker yum repo success!"

echo '============================================================'
echo '====================Add kubernetes yum repo...=============='
echo '============================================================'
#kubernetes yum源
cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF
echo "Add kubernetes yum repo success!"

echo '============================================================'
echo '====================Install docker...======================='
echo '============================================================'
#查看docker版本
#yum list docker-engine showduplicates
#安装docker
yum install -y docker-engine-1.12.6-1.el7.centos.x86_64

echo "Install docker success!"

echo '============================================================'
echo '====================Config docker...========================'
echo '============================================================'
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["${DOCKER_MIRRORS}"]
}
EOF
echo "Config docker success!"

echo '============================================================'
echo '====Install kubernetes-cni、kubelet、kubectl、kubeadm...====='
echo '============================================================'
#查看版本
#yum list kubeadm showduplicates
#yum list kubernetes-cni showduplicates
#yum list kubelet showduplicates
#yum list kubectl showduplicates
#安装kubelet
yum install -y kubernetes-cni-${KUBE_CNI_VERSION}-0.x86_64 kubelet-${KUBE_VERSION}-0.x86_64 kubectl-${KUBE_VERSION}-0.x86_64 kubeadm-${KUBE_VERSION}-0.x86_64

echo "Install kubernetes success!"

echo '============================================================'
echo '===================Config kubelet...========================'
echo '============================================================'
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "config --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/szss_k8s/pause-amd64:${KUBE_PAUSE_VERSION}"
cat > /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/szss_k8s/pause-amd64:${KUBE_PAUSE_VERSION}"
EOF

echo "Config kubelet success!"

echo '============================================================'
echo '==============Start docker and kubelet services...=========='
echo '============================================================'
systemctl enable docker
systemctl enable kubelet
systemctl start docker
systemctl start kubelet
echo "The docker and kubelet services started"

echo '============================================================'
echo '==============Join kubernetes cluster...===================='
echo '============================================================'
export KUBE_REPO_PREFIX="registry.cn-hangzhou.aliyuncs.com/szss_k8s"
export KUBE_ETCD_IMAGE="registry.cn-hangzhou.aliyuncs.com/szss_k8s/etcd-amd64:${ETCD_VERSION}"
kubeadm join --token ${KUBE_TOKEN} ${MASTER_ADDRESS}:6443 --skip-preflight-checks
echo "Join kubernetes cluster success!"

