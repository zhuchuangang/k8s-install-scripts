#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


MASTER_ADDRESS=${1:-"127.0.0.1"}
ETCD_SERVERS=${2:-"http://127.0.0.1:2379"}
SERVICE_CLUSTER_IP_RANGE=${3:-"10.0.0.0/24"}
KUBE_BIN_DIR=${4:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${5:-"/opt/kubernetes/cfg"}

echo '============================================================'
echo '===================Config kube-apiserver... ================'
echo '============================================================'
echo "Create ${KUBE_CFG_DIR}/kubeconfig.yaml"
cat <<EOF >${KUBE_CFG_DIR}/kubeconfig.yaml
apiVersion: v1
kind: Config
users:
- name: controllermanager
  user:
    client-certificate: /srv/kubernetes/cs_client.crt
    client-key: /srv/kubernetes/cs_client.key
clusters:
- name: local
  cluster:
    certificate-authority: /srv/kubernetes/ca.crt
contexts:
- context:
    cluster: local
    user: controllermanager
  name: my-context
current-context: my-context
EOF



#公共配置该配置文件同时被kube-apiserver、kube-controller-manager、kube-scheduler、kubelet、kube-proxy使用
echo "Create ${KUBE_CFG_DIR}/config file"
cat <<EOF >${KUBE_CFG_DIR}/config
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=https://${MASTER_ADDRESS}:443"
EOF


#kube-apiserver配置
echo "Create ${KUBE_CFG_DIR}/kube-apiserver file"
cat <<EOF >${KUBE_CFG_DIR}/kube-apiserver
#
# kubernetes system config
#
# The following values are used to configure the kube-apiserver

# --etcd-servers=[]: List of etcd servers to watch (http://ip:port),
# comma separated. Mutually exclusive with -etcd-config
KUBE_ETCD_SERVERS="--etcd-servers=${ETCD_SERVERS}"

# --insecure-bind-address=127.0.0.1: The IP address on which to serve the --insecure-port.
KUBE_API_ADDRESS="--bind-address=0.0.0.0"

# --insecure-port=8080: The port on which to serve unsecured, unauthenticated access.
KUBE_API_PORT="--secure-port=443"

# --kubelet-port=10250: Kubelet port
NODE_PORT="--kubelet-port=10250"

# --advertise-address=<nil>: The IP address on which to advertise
# the apiserver to members of the cluster.
KUBE_ADVERTISE_ADDR="--advertise-address=${MASTER_ADDRESS}"

# --service-cluster-ip-range=<nil>: A CIDR notation IP range from which to assign service cluster IPs.
# This must not overlap with any IP ranges assigned to nodes for pods.
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE}"

# --admission-control="AlwaysAdmit": Ordered list of plug-ins
# to do admission control of resources into cluster.
# Comma-delimited list of:
#   LimitRanger, AlwaysDeny, SecurityContextDeny, NamespaceExists,
#   NamespaceLifecycle, NamespaceAutoProvision, AlwaysAdmit,
#   ServiceAccount, DefaultStorageClass, DefaultTolerationSeconds, ResourceQuota
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

# --client-ca-file="": If set, any request presenting a client certificate signed
# by one of the authorities in the client-ca-file is authenticated with an identity
# corresponding to the CommonName of the client certificate.
KUBE_API_CLIENT_CA_FILE="--client-ca-file=/srv/kubernetes/ca.crt"

# --tls-cert-file="": File containing x509 Certificate for HTTPS.  (CA cert, if any,
# concatenated after server cert). If HTTPS serving is enabled, and --tls-cert-file
# and --tls-private-key-file are not provided, a self-signed certificate and key are
# generated for the public address and saved to /var/run/kubernetes.
KUBE_API_TLS_CERT_FILE="--tls-cert-file=/srv/kubernetes/server.crt"

# --tls-private-key-file="": File containing x509 private key matching --tls-cert-file.
KUBE_API_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/srv/kubernetes/server.key"

# Add your own!
KUBE_API_ARGS=""
EOF

echo "Create /usr/lib/systemd/system/kube-apiserver.service file"
cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
After=etcd.service

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-apiserver
ExecStart=${KUBE_BIN_DIR}/kube-apiserver  \
	    \${KUBE_LOGTOSTDERR}         \
        \${KUBE_LOG_LEVEL}           \
        \${KUBE_ETCD_SERVERS}        \
        \${KUBE_API_ADDRESS}         \
        \${KUBE_API_PORT}            \
        \${NODE_PORT}                \
        \${KUBE_ADVERTISE_ADDR}      \
        \${KUBE_ALLOW_PRIV}          \
        \${KUBE_SERVICE_ADDRESSES}   \
        \${KUBE_ADMISSION_CONTROL}   \
        \${KUBE_API_CLIENT_CA_FILE}  \
        \${KUBE_API_TLS_CERT_FILE}   \
        \${KUBE_API_TLS_PRIVATE_KEY_FILE} \
        \${KUBE_API_ARGS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start kube-apiserver... ================='
echo '============================================================'
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver

echo "Start kube-apiserver success!"
