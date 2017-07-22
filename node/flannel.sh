#!/bin/bash

ETCD_SERVERS=${1:-"http://8.8.8.18:2379"}
KUBE_MASTER_ADDRESS=${2:-}
KUBE_MASTER_USER=${3:-"root"}
KUBE_MASTER_PASSWORD=${4:-"123456"}
FLANNEL_NET=${5:-"172.18.0.0/16"}
FLANNEL_VERSION=${6:-"v0.7.1"}
KUBE_BIN_DIR=${7:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${8:-"/opt/kubernetes/cfg"}


echo '============================================================'
echo '===================Install flannel ========================='
echo '============================================================'
FLANNEL_FILE_NAME="flannel-${FLANNEL_VERSION}-linux-amd64.tar.gz"

if [ ! -f "./$FLANNEL_FILE_NAME" ]; then
wget -c https://github.com/coreos/flannel/releases/download/${FLANNEL_VERSION}/${FLANNEL_FILE_NAME}
fi
tar zxvf ${FLANNEL_FILE_NAME}
cp flanneld ${KUBE_BIN_DIR}

echo '============================================================'
echo '===================Config flannel =========================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/flannel file"
cat <<EOF >${KUBE_CFG_DIR}/flannel
FLANNEL_ETCD="-etcd-endpoints=${ETCD_SERVERS}"
FLANNEL_ETCD_KEY="-etcd-prefix=/coreos.com/network"
EOF

echo "Create /usr/lib/systemd/system/flannel.service file"
cat <<EOF >/usr/lib/systemd/system/flannel.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
Before=docker.service

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/flannel
ExecStartPre=${KUBE_BIN_DIR}/remove-docker0.sh
ExecStart=${KUBE_BIN_DIR}/flanneld --ip-masq \${FLANNEL_ETCD} \${FLANNEL_ETCD_KEY}
ExecStartPost=${KUBE_BIN_DIR}/mk-docker-opts.sh -d /run/flannel/docker

Type=notify

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF


echo '============================================================'
echo '===================Store FLANNEL_NET to etcd ==============='
echo '============================================================'
# Store FLANNEL_NET to etcd.
if [ ! -f "$KUBE_BIN_DIR/etcdctl" ]; then
yum install -y expect

echo "Copy etcdctl from master node!"
expect -c "spawn scp ${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS}:${KUBE_BIN_DIR}/etcdctl ${KUBE_BIN_DIR}
set timeout 3
expect \"${KUBE_MASTER_USER}@${KUBE_MASTER_ADDRESS} password：\"
exec sleep 2
send \"${KUBE_MASTER_PASSWORD}\r\"
interact"
fi

attempt=0
while true; do
  ${KUBE_BIN_DIR}/etcdctl --no-sync -C ${ETCD_SERVERS} \
    get /coreos.com/network/config >/dev/null 2>&1
  if [[ "$?" == 0 ]]; then
    break
  else
    if (( attempt > 600 )); then
      echo "timeout for waiting network config" > ~/kube/err.log
      exit 2
    fi

    ${KUBE_BIN_DIR}/etcdctl --no-sync -C ${ETCD_SERVERS} \
      mk /coreos.com/network/config "{\"Network\":\"${FLANNEL_NET}\"}" >/dev/null 2>&1
    attempt=$((attempt+1))
    sleep 3
    echo "Store FLANNEL_NET to etcd success!"
  fi
done
wait

echo '============================================================'
echo '===================Start flannel... ========================'
echo '============================================================'
systemctl daemon-reload
systemctl enable flannel
systemctl restart flannel

echo "Start flannel success!"
