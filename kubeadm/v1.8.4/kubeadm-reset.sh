#!/bin/bash
kubeadm reset
ifconfig cni0 down
ip link delete cni0
ifconfig flannel.1 down
ip link delete flannel.1
rm -rf /var/lib/cni/
# 删除rpm安装包
rpm -e --nodeps kubeadm-1.8.4-0
rpm -e --nodeps kubectl-1.8.4-0
rpm -e --nodeps kubelet-1.8.4-0
rpm -e --nodeps kubernetes-cni-0.5.1-1
rpm -e --nodeps socat-1.7.3.2-2.el7
# 卸载docker
#yum remove -y docker-engine-1.12.6-1.el7.centos.x86_64
