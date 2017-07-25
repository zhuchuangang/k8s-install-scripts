#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

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


#TLS证书和密钥
#生成CA证书和私钥
#cfssl print-defaults config > config.json
#cfssl print-defaults csr > csr.json
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

#创建 Kubernetes 证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

#创建 Admin 证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

#创建 Kube-Proxy 证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy

mkdir -p /opt/kubernetes/ssl
cp {ca-key.pem,ca.pem,kubernetes-key.pem,kubernetes.pem,kube-proxy.pem,kube-proxy-key.pem,admin.pem,admin-key.pem} /opt/kubernetes/ssl


BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat <<EOF >./token.csv
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

cp ./token.csv /opt/kubernetes/token.csv
