#!/bin/bash

#example:
#sh kube-node.sh "172.16.120.152" "172.16.120.151" "root" "123456" "http://172.16.120.151:2379,http://172.16.120.152:2379,http://172.16.120.153:2379"
#sh kube-node.sh "172.16.120.153" "172.16.120.151" "root" "123456" "http://172.16.120.151:2379,http://172.16.120.152:2379,http://172.16.120.153:2379"
#
#systemctl stop kubelet
#systemctl stop kube-proxy
#systemctl stop flannel
#systemctl stop docker
#

set -o errexit
set -o nounset
set -o pipefail

#kubernetes安装版本
export KUBE_VERSION=v1.6.7
export FLANNEL_VERSION=v0.7.1

#kubernetes执行和配置文件目录
export KUBE_BIN_DIR=/opt/kubernetes/bin
export KUBE_CFG_DIR=/opt/kubernetes/cfg
export KUBE_LOG_DIR=/opt/kubernetes/logs


export NODE_ADDRESS=${1:-}
export MASTER_ADDRESS=${2:-}
export MASTER_USER=${3:-}
export MASTER_PASSWORD=${4:-}
export ETCD_SERVERS=${5:-}
export FLANNEL_NET=${6:-"172.18.0.0/16"}
export DOCKER_OPTS=${7:-"--registry-mirror=https://5md0553g.mirror.aliyuncs.com"}
export KUBELET_POD_INFRA_CONTAINER=${8:-"hub.c.163.com/k8s163/pause-amd64:3.0"}
export DNS_SERVER_IP=${9:-"10.0.0.10"}

echo '============================================================'
echo '====================Disable selinux and firewalld...========'
echo '============================================================'
if [ $(getenforce) = "Enabled" ]; then
setenforce 0
fi
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "Disable selinux and firewalld success!"

#创建证书
sh kube-ssl-node.sh ${NODE_ADDRESS} ${MASTER_ADDRESS} ${MASTER_USER} ${MASTER_PASSWORD}

#安装kubernetes
sh kube-install.sh "false" ${KUBE_BIN_DIR} ${KUBE_CFG_DIR} ${KUBE_LOG_DIR} ${KUBE_VERSION}

#安装顺序为 flannel docker kubelet kube-proxy
#安装和配置flannel
sh flannel.sh ${ETCD_SERVERS} ${MASTER_ADDRESS} ${MASTER_USER} ${MASTER_PASSWORD} ${FLANNEL_NET} ${FLANNEL_VERSION} ${KUBE_BIN_DIR} ${KUBE_CFG_DIR}

#安装和配置docker
sh docker.sh ${DOCKER_OPTS}

#配置kube api server，并启动服务
sh kubelet.sh ${MASTER_ADDRESS} ${NODE_ADDRESS} ${KUBELET_POD_INFRA_CONTAINER} ${DNS_SERVER_IP} "cluster.local" ${KUBE_BIN_DIR} ${KUBE_CFG_DIR}

#配置kube controller manager，并启动服务
sh kube-proxy.sh ${NODE_ADDRESS} ${MASTER_ADDRESS} ${KUBE_BIN_DIR} ${KUBE_CFG_DIR}
