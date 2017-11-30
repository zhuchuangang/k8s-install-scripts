#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# NODE_TYPE表示节点类型，取值为master,slave
NODE_TYPE=${1:-"master"}
MASTER_ADDRESS=${2:-"127.0.0.1"}
MYSQL_ADDRESS=${3:-"127.0.0.1"}
DOCKER_MIRRORS=${4:-"https://5md0553g.mirror.aliyuncs.com"}
DOCKER_GRAPH=${5:-"/mnt/docker"}

RANCHER_VERSION=v1.6.11

echo '============================================================'
echo '====================Disable selinux and firewalld...========'
echo '============================================================'
# 关闭selinux
if [ $(getenforce) = "Enabled" ]; then
setenforce 0
fi

# 关闭防火墙
systemctl disable firewalld
systemctl stop firewalld

# selinux设置为disabled
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Kubernetes 1.8开始要求关闭系统的Swap，如果不关闭，默认配置下kubelet将无法启动。可以通过kubelet的启动参数–fail-swap-on=false更改这个限制。
# 修改 /etc/fstab 文件，注释掉 SWAP 的自动挂载，使用free -m确认swap已经关闭。
swapoff -a

echo "Disable selinux and firewalld success!"

echo '============================================================'
echo '====================Add docker yum repo...=================='
echo '============================================================'
#aliyun docker yum源
#cat >> /etc/yum.repos.d/docker.repo <<EOF
# [docker-repo]
# name=Docker Repository
# baseurl=http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7
# enabled=1
# gpgcheck=0
# EOF

# dockerproject docker源
if [ ! -f "/etc/yum.repos.d/docker.repo" ]; then
cat >> /etc/yum.repos.d/docker.repo <<EOF
[docker-repo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=0
EOF
fi
echo "Add docker yum repo success!"

echo '============================================================'
echo '====================Install docker...======================='
echo '============================================================'
#查看docker版本
#yum list docker-engine showduplicates
#安装docker
yum install -y docker-engine-1.12.6-1.el7.centos.x86_64

echo "Install docker success!"

echo '============================================================'
echo '====================Config docker...========================'
echo '============================================================'
# 如果/etc/docker目录不存在，就创建目录
if [ ! -d "/etc/docker" ]; then
 mkdir -p /etc/docker
fi

# 配置加速器
if [ -f "/etc/docker/daemon.json" ]; then
 rm -rf /etc/docker/daemon.json
fi

cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["${DOCKER_MIRRORS}"],
  "graph":"${DOCKER_GRAPH}"
}
EOF

echo "Config docker success!"

echo '============================================================'
echo '==============Start docker ...=============================='
echo '============================================================'
systemctl daemon-reload
systemctl enable docker
systemctl start docker
echo "The docker services started!"


# master节点启动rancher server，slave节点只安装docker环境
if [ "$NODE_TYPE" = 'master' ]; then

echo '============================================================'
echo '====================Start rancher server...================='
echo '============================================================'

docker run -d --restart always \
--name rancher-server \
-p 8080:8080 \
-p 9345:9345 \
rancher/server:${RANCHER_VERSION} \
--db-host ${MYSQL_ADDRESS} \
--db-port 3306 \
--db-user cattle \
--db-pass cattle \
--db-name cattle \
--advertise-address ${MASTER_ADDRESS}

echo "Rancher server start success!"
fi
