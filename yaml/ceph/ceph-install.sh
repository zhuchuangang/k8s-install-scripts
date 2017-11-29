#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# NODE_TYPE表示节点类型，取值为master,slave
NODE_TYPE=${1:-"master"}
DOCKER_MIRRORS=${2:-"https://5md0553g.mirror.aliyuncs.com"}
DOCKER_GRAPH=${3:-"/var/lib/docker/"}
CEPH_CFG_DIR=${4:-"/opt/ceph"}

echo '============================================================'
echo '=============Enable selinux and disable firewalld...========'
echo '============================================================'
# 开启selinux
if [ $(getenforce) = "Disabled" ]; then
setenforce 1
fi

# selinux设置为enforcing
sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config

# 关闭防火墙
systemctl disable firewalld
systemctl stop firewalld

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
echo '======================Start ceph monitor...================='
echo '============================================================'

if [-f "/usr/lib/systemd/system/ceph-monitor.service"]; then
    rm -rf /usr/lib/systemd/system/ceph-monitor.service
fi

echo "Create /usr/lib/systemd/system/ceph-monitor.service file"
cat <<EOF >/usr/lib/systemd/system/ceph-monitor.service
[Unit]
Description=ceph monitor
Documentation=https://github.com/ceph/ceph
After=docker.service
Requires=docker.service
[Service]
EnvironmentFile=-${CEPH_CFG_DIR}/config
ExecStart=docker run -d --name=mon --net=host \\
            --restart=always \\
            -v /etc/ceph:/etc/ceph \\
            -v /var/lib/ceph:/var/lib/ceph \\
            -e MON_IP=192.168.0.1 \
            -e CEPH_PUBLIC_NETWORK=192.168.0.0/24 \\
            ceph/daemon:tag-build-master-jewel-centos-7 mon
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo "Rancher server start success!"
fi
