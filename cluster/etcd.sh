#!/bin/bash

#第1个参数是etcd当前节点名称ETCD_NAME
#第2个参数是etcd当前节点IP地址ETCD_LISTEN_IP
#第3个参数是etcd集群地址ETCD_INITIAL_CLUSTER
#例子：
#sh etcd.sh "node01" "172.16.120.151" "node01=http://172.16.120.151:2380,node02=http://172.16.120.152:2380,node03=http://172.16.120.153:2380"
#sh etcd.sh "node02" "172.16.120.152" "node01=http://172.16.120.151:2380,node02=http://172.16.120.152:2380,node03=http://172.16.120.153:2380"
#sh etcd.sh "node03" "172.16.120.153" "node01=http://172.16.120.151:2380,node02=http://172.16.120.152:2380,node03=http://172.16.120.153:2380"

echo '============================================================'
echo '====================Disable selinux and firewalld...========'
echo '============================================================'
if [ $(getenforce) = "Enabled" ]; then
setenforce 0
fi
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "Disable selinux and firewalld success!"

echo '============================================================'
echo '====================Downland etcd... ======================='
echo '============================================================'
ETCD_VERSION=v3.2.4
echo "etcd version is $ETCD_VERSION"
ETCD_FILE=etcd-$ETCD_VERSION-linux-amd64
echo "etcd zip file is $ETCD_FILE"

if [ ! -f "./$ETCD_FILE.tar.gz" ]; then
  wget https://github.com/coreos/etcd/releases/download/$ETCD_VERSION/$ETCD_FILE.tar.gz
fi


echo '============================================================'
echo '=====================Unzip etcd zip file... ================'
echo '============================================================'
tar xzvf $ETCD_FILE.tar.gz

ETCD_BIN_DIR=/opt/kubernetes/bin
ETCD_CFG_DIR=/opt/kubernetes/cfg
mkdir -p $ETCD_BIN_DIR
mkdir -p $ETCD_CFG_DIR

echo '============================================================'
echo '=====================Install etcd... ======================='
echo '============================================================'
cp $ETCD_FILE/etcd $ETCD_BIN_DIR
cp $ETCD_FILE/etcdctl $ETCD_BIN_DIR
rm -rf $ETCD_FILE

sed -i 's/$PATH:/$PATH:\/opt\/kubernetes\/bin:/g' ~/.bash_profile
#source ~/.bash_profile
exec bash --login

ETCD_DATA_DIR=/var/lib/etcd
mkdir -p ${ETCD_DATA_DIR}


ETCD_NAME=${1:-"default"}
ETCD_LISTEN_IP=${2:-"0.0.0.0"}
ETCD_INITIAL_CLUSTER=${3:-}

echo 'Create /opt/kubernetes/cfg/etcd.conf ...'
cat <<EOF >/opt/kubernetes/cfg/etcd.conf
# [member]
ETCD_NAME="${ETCD_NAME}"
ETCD_DATA_DIR="${ETCD_DATA_DIR}/default.etcd"
#ETCD_SNAPSHOT_COUNTER="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_LISTEN_IP}:2380"
# if you use different ETCD_NAME (e.g. test),
# set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER}"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="k8s-etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_LISTEN_IP}:2379"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#
#[proxy]
#ETCD_PROXY="off"
#
#[security]
#ETCD_CA_FILE=""
#ETCD_CERT_FILE=""
#ETCD_KEY_FILE=""
#ETCD_PEER_CA_FILE=""
#ETCD_PEER_CERT_FILE=""
#ETCD_PEER_KEY_FILE=""
EOF

echo 'Create /usr/lib/systemd/system/etcd.service ...'
cat <<EOF >//usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
WorkingDirectory=${ETCD_DATA_DIR}
EnvironmentFile=-/opt/kubernetes/cfg/etcd.conf
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=\$(nproc) /opt/kubernetes/bin/etcd"
Type=notify

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================start etcd service... ==================='
echo '============================================================'
systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd

echo 'The etcd service is started!'
