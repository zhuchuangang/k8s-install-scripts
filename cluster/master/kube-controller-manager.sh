#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


MASTER_ADDRESS=${1:-"127.0.0.1"}
KUBE_BIN_DIR=${2:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${3:-"/opt/kubernetes/cfg"}

echo '============================================================'
echo '===================Config kube-controller-manager...========'
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-controller-manager file"
cat <<EOF >/opt/kubernetes/cfg/kube-controller-manager
# --root-ca-file="": If set, this root certificate authority will be included in
# service account's token secret. This must be a valid PEM-encoded CA bundle.
KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE="--root-ca-file=/srv/kubernetes/ca.crt"

# --service-account-private-key-file="": Filename containing a PEM-encoded private
# RSA key used to sign service account tokens.
KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE="--service-account-private-key-file=/srv/kubernetes/server.key"

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=true"

KUBE_CONFIG="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"
EOF


echo "Create /usr/lib/systemd/system/kube-controller-manager.service file"
cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-controller-manager

ExecStart=${KUBE_BIN_DIR}/kube-controller-manager \
                                \${KUBE_LOGTOSTDERR} \
                                \${KUBE_LOG_LEVEL}   \
                                \${KUBE_MASTER}      \
                                \${KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE} \
                                \${KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE} \
                                \${KUBE_CONFIG} \
                                \${KUBE_LEADER_ELECT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start kube-controller-manager... ========'
echo '============================================================'

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager

echo "Start kube-controller-manager success!"

