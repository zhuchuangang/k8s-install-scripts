#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


KUBE_NODE_ADDRESS=${1:-}
KUBE_MASTER_ADDRESS=${2:-}
KUBE_MASTER_USER=${3:-"root"}
KUBE_MASTER_PASSWORD=${4:-"123456"}
KUBE_CFG_DIR=${5:-"/opt/kubernetes/cfg"}

export KUBE_API_SERVER="https://${KUBE_MASTER_ADDRESS}:6443"

echo '============================================================'
echo '===================Create ssl for kube node...=============='
echo '============================================================'

#创建证书存放目录
rm -rf /srv/kubernetes
mkdir /srv/kubernetes

###############生成node端证书################
#openssl genrsa -out /srv/kubernetes/kubelet_client.key 2048

#openssl req -new -key /srv/kubernetes/kubelet_client.key -subj "/CN=${KUBE_NODE_ADDRESS}" -out /srv/kubernetes/kubelet_client.csr

#从master节点获取根证书
yum install -y expect

expect -c "spawn scp ${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS}:/srv/kubernetes/ca.* /srv/kubernetes/
set timeout 3
expect \"${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS} password：\"
exec sleep 2
send \"${KUBE_MASTER_PASSWORD}\r\"
interact"

expect -c "spawn scp ${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS}:/srv/kubernetes/token_auth_file.csv /srv/kubernetes/
set timeout 3
expect \"${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS} password：\"
exec sleep 2
send \"${KUBE_MASTER_PASSWORD}\r\"
interact"

#openssl x509 -req -in /srv/kubernetes/kubelet_client.csr -CA /srv/kubernetes/ca.crt -CAkey /srv/kubernetes/ca.key -CAcreateserial -out /srv/kubernetes/kubelet_client.crt -days 10000

BOOTSTRAP_TOKEN=$(sed -n '1,1p' ${KUBE_CFG_DIR}/token_auth_file.csv)
BOOTSTRAP_TOKEN=${BOOTSTRAP_TOKEN:0:32}

rm -rf ${KUBE_CFG_DIR}/token_auth_file.csv

echo "Create ${KUBE_CFG_DIR}/bootstrap.kubeconfig..."
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/srv/kubernetes/ca.crt \
  --embed-certs=true \
  --server=${KUBE_API_SERVER} \
  --kubeconfig=${KUBE_CFG_DIR}/bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=${KUBE_CFG_DIR}/bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=${KUBE_CFG_DIR}/bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=${KUBE_CFG_DIR}/bootstrap.kubeconfig
