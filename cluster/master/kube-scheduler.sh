#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


MASTER_ADDRESS=${1:-"127.0.0.1"}
KUBE_BIN_DIR=${2:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${3:-"/opt/kubernetes/cfg"}
KUBE_LOG_DIR=${6:-"/opt/kubernetes/logs"}


echo '============================================================'
echo '===================Config kube-scheduler...================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-scheduler file"
cat <<EOF >${KUBE_CFG_DIR}/kube-scheduler
###
# kubernetes scheduler config

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=true"

#log dir
KUBE_LOG_DIR="--log-dir=${KUBE_LOG_DIR}"

# Add your own!
KUBE_SCHEDULER_ARGS="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"

EOF

echo "Create ${KUBE_CFG_DIR}/kube-scheduler.service file"
cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-scheduler
ExecStart=${KUBE_BIN_DIR}/kube-scheduler         \\
                        \${KUBE_LOGTOSTDERR}     \\
                        \${KUBE_LOG_LEVEL}       \\
                        \${KUBE_MASTER}          \\
                        \${KUBE_LEADER_ELECT}    \\
                        \${KUBE_LOG_DIR}         \\
                        \${KUBE_SCHEDULER_ARGS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start kube-scheduler... ================='
echo '============================================================'

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl restart kube-scheduler

echo "Start kube-scheduler success!"
