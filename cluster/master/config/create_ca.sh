#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


echo '============================================================'
echo '===================Create ssl for kube master node...======='
echo '============================================================'

#安装cfssl
if [ ! -f "/usr/bin/cfssl" ]; then
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
mv cfssl_linux-amd64 /usr/bin/cfssl
fi

if [ ! -f "/usr/bin/cfssljson" ]; then
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
mv cfssljson_linux-amd64 /usr/bin/cfssljson
fi

if [ ! -f "/usr/bin/cfssl-certinfo" ]; then
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x	cfssl-certinfo_linux-amd64
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
fi

echo "Create ca-config.json..."
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}

EOF

#TLS证书和密钥
#生成CA证书和私钥
#cfssl print-defaults config > config.json
#cfssl print-defaults csr > csr.json
echo "Create ca-csr.json..."
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Anhui",
      "L": "Wuhu",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

echo "Create root cert..."
cfssl gencert -initca ca-csr.json | cfssljson -bare ca


#创建 Kubernetes 证书
echo "Create kubernetes cert..."
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "${KUBE_MASTER_IP}",
    "${KUBE_CLUSTER_IP}",
    "${KUBE_MASTER_DNS}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Anhui",
      "L": "Wuhu",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
#创建 Kubernetes 证书
cfssl gencert -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes


##创建 Admin 证书
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
#
##创建 Kube-Proxy 证书
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
#
#mkdir -p /opt/kubernetes/ssl
#cp {ca-key.pem,ca.pem,kubernetes-key.pem,kubernetes.pem,kube-proxy.pem,kube-proxy-key.pem,admin.pem,admin-key.pem} /opt/kubernetes/ssl


mkdir -p /srv/kubernetes
cp {ca-key.pem,ca.pem,kubernetes-key.pem,kubernetes.pem} /opt/kubernetes/ssl
echo "Clean files..."
rm -rf *.pem
rm -rf *.json


