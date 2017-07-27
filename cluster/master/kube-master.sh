#!/bin/bash

#
#sh kube-master.sh "172.16.120.151" "k8s-node01" "http://172.16.120.151:2379,http://172.16.120.152:2379,http://172.16.120.153:2379"
#
#systemctl stop kube-apiserver
#systemctl stop kube-controller-manager
#systemctl stop kube-scheduler

set -o errexit
set -o nounset
set -o pipefail

#kubernetes安装版本
export KUBE_VERSION=v1.6.7

#kubernetes执行和配置文件目录
export KUBE_BIN_DIR=/opt/kubernetes/bin
export KUBE_CFG_DIR=/opt/kubernetes/cfg
export KUBE_LOG_DIR=/opt/kubernetes/logs

export MASTER_ADDRESS=${1:-}
export MASTER_DNS=${2:-}
export ETCD_SERVERS=${3:-}
export SERVICE_CLUSTER_IP_RANGE=${4:-"10.0.0.0/24"}
export MASTER_CLUSTER_IP=${5:-"10.0.0.1"}

echo '============================================================'
echo '====================Disable selinux and firewalld...========'
echo '============================================================'
if [ $(getenforce) = "Enabled" ]; then
setenforce 0
fi
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config


#创建证书
sh kube-ssl-master.sh ${MASTER_ADDRESS} ${MASTER_DNS} ${MASTER_CLUSTER_IP} ${KUBE_CFG_DIR}

#安装kubernetes
sh kube-install.sh "true" ${KUBE_BIN_DIR} ${KUBE_CFG_DIR} ${KUBE_LOG_DIR} ${KUBE_VERSION}

#配置kube api server，并启动服务
sh kube-apiserver.sh ${MASTER_ADDRESS} ${ETCD_SERVERS} ${SERVICE_CLUSTER_IP_RANGE} ${KUBE_BIN_DIR} ${KUBE_CFG_DIR} ${KUBE_LOG_DIR}

#配置kube controller manager，并启动服务
sh kube-controller-manager.sh ${MASTER_ADDRESS} ${KUBE_BIN_DIR} ${KUBE_CFG_DIR}

#配置kube scheduler，并启动服务
sh kube-scheduler.sh ${MASTER_ADDRESS} ${KUBE_BIN_DIR} ${KUBE_CFG_DIR}
