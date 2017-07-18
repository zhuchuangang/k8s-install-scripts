#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

KUBE_DOCKER_OPTS=${1:-""}
KUBE_CFG_DIR=${2:-"/opt/kubernetes/cfg"}

echo '============================================================'
echo '===================Install docker =========================='
echo '============================================================'

yum install -y yum-utils

yum-config-manager \
    --add-repo \
    https://docs.docker.com/v1.13/engine/installation/linux/repo_files/centos/docker.repo

yum makecache fast

yum list docker-engine.x86_64  --showduplicates |sort -r

yum install -y docker-engine-1.12.6

echo '============================================================'
echo '===================Config docker ==========================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/docker file"
cat <<EOF >${KUBE_CFG_DIR}/docker
#--selinux-enabled=false
DOCKER_OPTS="${KUBE_DOCKER_OPTS}"
EOF

echo "Create /usr/lib/systemd/system/docker.service file"
cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target flannel.service
Requires=flannel.service

[Service]
Type=notify
EnvironmentFile=-/run/flannel/docker
EnvironmentFile=-${KUBE_CFG_DIR}/docker
ExecStart=/usr/bin/dockerd \${DOCKER_OPT_BIP} \${DOCKER_OPT_MTU} \${DOCKER_OPTS}
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start docker... ========================='
echo '============================================================'

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

echo "Start docker success!"
