#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


NODE_ADDRESS=${1:-"8.8.8.20"}
MASTER_ADDRESS=${2:-"8.8.8.18"}
KUBE_BIN_DIR=${3:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${4:-"/opt/kubernetes/cfg"}

echo '============================================================'
echo '===================Config kube-proxy... ===================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-proxy file"
cat <<EOF >${KUBE_CFG_DIR}/kube-proxy
# --hostname-override="": If non-empty, will use this string as identification instead of the actual hostname.
NODE_HOSTNAME="--hostname-override=${NODE_ADDRESS}"

# Add your own!
KUBE_PROXY_ARGS="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"
EOF

echo "Create /usr/lib/systemd/system/kube-proxy.service file"
cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-proxy
ExecStart=${KUBE_BIN_DIR}/kube-proxy     \
                    \${KUBE_LOGTOSTDERR} \
                    \${KUBE_LOG_LEVEL}   \
                    \${NODE_HOSTNAME}    \
                    \${KUBE_MASTER}      \
                    \${KUBE_PROXY_ARGS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "============================================================"
echo "===================Start kube-proxy... ====================="
echo "============================================================"

systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy

echo "Start kube proxy success!"
