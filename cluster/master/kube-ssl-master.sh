#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


KUBE_MASTER_IP=${1:-}
KUBE_MASTER_DNS=${2:-}
KUBE_CLUSTER_IP=${3:-"10.0.0.1"}
KUBE_CFG_DIR=${4:-"/opt/kubernetes/cfg"}


echo '============================================================'
echo '===================Create ssl for kube master node...======='
echo '============================================================'

#创建证书存放目录
rm -rf /srv/kubernetes
mkdir /srv/kubernetes

###############生成根证书################
#创建CA私钥
openssl genrsa -out /srv/kubernetes/ca.key 2048
#自签CA
openssl req -x509 -new -nodes -key /srv/kubernetes/ca.key -subj "/CN=kubernetes/O=k8s/OU=System" -days 10000 -out /srv/kubernetes/ca.crt
###############生成 API Server 服务端证书和私钥###############

cat <<EOF >/srv/kubernetes/master_ssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = ${KUBE_MASTER_DNS}
IP.1 = ${KUBE_CLUSTER_IP}
IP.2 = ${KUBE_MASTER_IP}
EOF

#生成apiserver私钥
echo "Create kubernetes api server ssl key..."
openssl genrsa -out /srv/kubernetes/server.key 2048

#生成签署请求
openssl req -new -key /srv/kubernetes/server.key -subj "/CN=kubernetes/O=k8s/OU=System" -config /srv/kubernetes/master_ssl.cnf -out /srv/kubernetes/server.csr

#使用自建CA签署
openssl x509 -req -in /srv/kubernetes/server.csr -CA /srv/kubernetes/ca.crt -CAkey /srv/kubernetes/ca.key -CAcreateserial -days 10000 -extensions v3_req -extfile /srv/kubernetes/master_ssl.cnf -out /srv/kubernetes/server.crt

#生成 Controller Manager 与 Scheduler 进程共用的证书和私钥
echo "Create kubernetes controller manager and scheduler server ssl key..."
openssl genrsa -out /srv/kubernetes/cs_client.key 2048

#生成签署请求
openssl req -new -key /srv/kubernetes/cs_client.key -subj "/CN=admin/O=system:masters/OU=System" -out /srv/kubernetes/cs_client.csr

#使用自建CA签署
openssl x509 -req -in /srv/kubernetes/cs_client.csr -CA /srv/kubernetes/ca.crt -CAkey /srv/kubernetes/ca.key -CAcreateserial -out /srv/kubernetes/cs_client.crt -days 10000
