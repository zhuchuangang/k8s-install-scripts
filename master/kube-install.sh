#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

INSTALL_MASTER=${1:-"true"}
KUBE_BIN_DIR=${2:-"/opt/kubernetes/bin"}
KUBE_VERSION=${3:-"v1.6.7"}

echo '============================================================'
echo '===================Downland kubernetes... =================='
echo '============================================================'

mkdir -p ${KUBE_BIN_DIR}
mkdir -p ${KUBE_CFG_DIR}

if [ ! -f "./kubernetes.tar.gz" ]; then
wget https://github.com/kubernetes/kubernetes/releases/download/${KUBE_VERSION}/kubernetes.tar.gz
fi
tar zxvf kubernetes.tar.gz
sh ./kubernetes/cluster/get-kube-binaries.sh
tar zxvf ./kubernetes/server/kubernetes-server-linux-amd64.tar.gz


echo '============================================================'
echo '===================Install kubernetes... ==================='
echo '============================================================'

if [ ${INSTALL_MASTER}=true ]; then
echo "Copy kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet to /opt/kubernetes/bin/ "
cd ./kubernetes/server/bin
cp {kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} ${KUBE_BIN_DIR}
else
echo "Copy kubectl,kube-proxy,kubelet to /opt/kubernetes/bin/ "
cd ./kubernetes/server/bin
cp {kubectl,kube-proxy,kubelet} ${KUBE_BIN_DIR}

fi
