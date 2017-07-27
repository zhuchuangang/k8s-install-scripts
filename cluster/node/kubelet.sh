#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

MASTER_ADDRESS=${1:-""}
NODE_ADDRESS=${2:-""}
KUBELET_POD_INFRA_CONTAINER=${3:-"hub.c.163.com/k8s163/pause-amd64:3.0"}
DNS_SERVER_IP=${4:-"10.0.0.10"}
DNS_DOMAIN=${5:-"cluster.local"}
KUBE_BIN_DIR=${6:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${7:-"/opt/kubernetes/cfg"}

echo '============================================================'
echo '===================Config kubelet... ======================='
echo '============================================================'
echo "Create ${KUBE_CFG_DIR}/kubeconfig.yaml"
cat <<EOF >${KUBE_CFG_DIR}/kubeconfig.yaml
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    client-certificate: /srv/kubernetes/kubelet_client.crt
    client-key: /srv/kubernetes/kubelet_client.key
clusters:
- name: local
  cluster:
    certificate-authority: /srv/kubernetes/ca.crt
contexts:
- context:
    cluster: local
    user: kubelet
  name: my-context
current-context: my-context
EOF



if [ ! -f ".${KUBE_CFG_DIR}/config" ]; then
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
KUBE_MASTER="--master=https://${MASTER_ADDRESS}:6443"
EOF
fi

echo "Create ${KUBE_CFG_DIR}/kubelet file"
cat <<EOF >${KUBE_CFG_DIR}/kubelet

# --address=0.0.0.0: The IP address for the Kubelet to serve on (set to 0.0.0.0 for all interfaces)
NODE_ADDRESS="--address=${NODE_ADDRESS}"

# --port=10250: The port for the Kubelet to serve on. Note that "kubectl logs" will not work if you set this flag.
NODE_PORT="--port=10250"

# --hostname-override="": If non-empty, will use this string as identification instead of the actual hostname.
NODE_HOSTNAME="--hostname-override=${NODE_ADDRESS}"

# --api-servers=[]: List of Kubernetes API servers for publishing events,
# and reading pods and services. (ip:port), comma separated.
KUBELET_API_SERVER="--api-servers=https://${MASTER_ADDRESS}:6443"

# DNS info
KUBELET_DNS_IP="--cluster-dns=${DNS_SERVER_IP}"
KUBELET_DNS_DOMAIN="--cluster-domain=${DNS_DOMAIN}"

#kubelet pod infra container
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=${KUBELET_POD_INFRA_CONTAINER}"

# Add your own!
KUBELET_ARGS="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"

EOF


echo "Create /usr/lib/systemd/system/kubelet.service file"
cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kubelet
ExecStart=${KUBE_BIN_DIR}/kubelet \
                    \${KUBE_LOGTOSTDERR}     \
                    \${KUBE_LOG_LEVEL}       \
                    \${NODE_ADDRESS}         \
                    \${NODE_PORT}            \
                    \${NODE_HOSTNAME}        \
                    \${KUBELET_API_SERVER}   \
                    \${KUBE_ALLOW_PRIV}      \
                    \${KUBELET_DNS_IP}       \
                    \${KUBELET_DNS_DOMAIN}   \
                    \${KUBELET_POD_INFRA_CONTAINER}   \
                    \${KUBELET_ARGS}

Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF



echo '============================================================'
echo '===================Start kubelet... ========================'
echo '============================================================'

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet

echo "Start kubelet success!"
