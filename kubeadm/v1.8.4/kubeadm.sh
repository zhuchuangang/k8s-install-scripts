#!/bin/bash

#sh kubeadm.sh 172.16.120.151 master
#sh kubeadm.sh 172.16.120.151 slave


set -o errexit
set -o nounset
set -o pipefail

MASTER_ADDRESS=${1:-"127.0.0.1"}
# NODE_TYPE表示节点类型，取值为master,slave
NODE_TYPE=${2:-"master"}
KUBE_TOKEN=${3:-"863f67.19babbff7bfe8543"}
DOCKER_MIRRORS=${4:-"https://5md0553g.mirror.aliyuncs.com"}
DOCKER_GRAPH=${5:-"/mnt/docker"}

KUBE_VERSION=1.8.4
KUBE_CNI_VERSION=0.5.1
SOCAT_VERSION=1.7.3.2

KUBE_IMAGE_VERSION=v1.8.4
KUBE_PAUSE_VERSION=3.0
ETCD_VERSION=3.0.17
FLANNEL_VERSION=v0.9.1
DNS_VERSION=1.14.5

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


if [ -f "/etc/sysctl.d/k8s.conf" ]; then
 rm -rf /etc/sysctl.d/k8s.conf
fi

# IPv4 iptables 链设置 CNI插件需要
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# 设置swappiness参数为0，linux swap空间为0
cat >> /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF

modprobe br_netfilter

# 生效配置
sysctl -p /etc/sysctl.d/k8s.conf

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

#echo '============================================================'
#echo '====================Add kubernetes yum repo...=============='
#echo '============================================================'
#kubernetes yum源
#if [! -f "/etc/yum.repos.d/kubernetes.repo"]; then
#cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
#[kubernetes]
#name=Kubernetes
#baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
#enabled=1
#gpgcheck=0
#EOF
#fi

#echo "Add kubernetes yum repo success!"

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
echo '====Install kubernetes-cni、kubelet、kubectl、kubeadm...====='
echo '============================================================'
#查看版本
#yum list kubeadm showduplicates
#yum list kubernetes-cni showduplicates
#yum list kubelet showduplicates
#yum list kubectl showduplicates
#安装kubelet
#yum install -y kubernetes-cni-${KUBE_CNI_VERSION}-0.x86_64 kubelet-${KUBE_VERSION}-0.x86_64 kubectl-${KUBE_VERSION}-0.x86_64 kubeadm-${KUBE_VERSION}-0.x86_64
rpm -ivh kubernetes-cni-${KUBE_CNI_VERSION}-1.x86_64.rpm socat-${SOCAT_VERSION}-2.el7.x86_64.rpm kubeadm-${KUBE_VERSION}-0.x86_64.rpm kubectl-${KUBE_VERSION}-0.x86_64.rpm kubelet-${KUBE_VERSION}-0.x86_64.rpm

echo "Install kubernetes success!"

echo '============================================================'
echo '===================Config kubelet...========================'
echo '============================================================'
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "config --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/szss_k8s/pause-amd64:${KUBE_PAUSE_VERSION}"

if [ ! -f "/etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf" ]; then
cat > /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/szss_k8s/pause-amd64:${KUBE_PAUSE_VERSION}"
EOF
fi

echo "Config kubelet success!"

echo '============================================================'
echo '==============Start docker and kubelet services...=========='
echo '============================================================'
systemctl daemon-reload
systemctl enable docker
systemctl enable kubelet
systemctl start docker
systemctl start kubelet
echo "The docker and kubelet services started"

echo '============================================================'
echo '==============pull docker images..=========================='
echo '============================================================'
GCR_URL=gcr.io/google_containers
ALIYUN_URL=registry.cn-hangzhou.aliyuncs.com/szss_k8s

images=(
kube-apiserver-amd64:${KUBE_IMAGE_VERSION}
kube-scheduler-amd64:${KUBE_IMAGE_VERSION}
kube-controller-manager-amd64:${KUBE_IMAGE_VERSION}
kube-proxy-amd64:${KUBE_IMAGE_VERSION}
etcd-amd64:${ETCD_VERSION}
k8s-dns-sidecar-amd64:${DNS_VERSION}
k8s-dns-kube-dns-amd64:${DNS_VERSION}
k8s-dns-dnsmasq-nanny-amd64:${DNS_VERSION}
)

for imageName in ${images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $GCR_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done

echo "The kubernetes docker images pull success!"

#=========================master begin===================================
if [ "$NODE_TYPE" = 'master' ]; then
echo '============================================================'
echo '==============kubeadm init=================================='
echo '============================================================'

echo "init kubernetes master..."
#export KUBE_HYPERKUBE_IMAGE="registry.cn-hangzhou.aliyuncs.com/szss_quay_io/coreos-hyperkube:${HYPERKUBE_VERSION}"
export KUBE_ETCD_IMAGE="registry.cn-hangzhou.aliyuncs.com/szss_k8s/etcd-amd64:${ETCD_VERSION}"
export KUBE_REPO_PREFIX="registry.cn-hangzhou.aliyuncs.com/szss_k8s"

#--token指定token,token的格式为<6 character string>.<16 character string>，指定token后可以通过cat /etc/kubernetes/pki/tokens.csv查看
#--token-ttl=0 token-ttl表示token过期时间，0表示永远不过期
#--pod-network-cidr指定IP段需要和kube-flannel.yml文件中配置的一致
#--service-cidr表示service VIP
#--pod-network-cidr表示pod网络的IP
# 其他更多参数请通过kubeadm init --help查看
# 参考：https://kubernetes.io/docs/reference/generated/kubeadm/
kubeadm init --apiserver-advertise-address=${MASTER_ADDRESS} \
--kubernetes-version=v${KUBE_VERSION} \
--token=${KUBE_TOKEN} \
--token-ttl=0 \
service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16 \
--skip-preflight-checks

#查看token的命令
echo "you can use this order to query the token: kubeadm token list"

echo '============================================================'
echo '=====================Config admin...========================'
echo '============================================================'
# $HOME/.kube目录不存在就创建
if [ ! -d "$HOME/.kube" ]; then
    mkdir -p $HOME/.kube
fi

# $HOME/.kube/config文件存在就删除
if [ -f "$HOME/.kube/config" ]; then
  rm -rf $HOME/.kube/config
fi

cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
echo "Config admin success!"


echo '============================================================'
echo '==============Create flannel service...====================='
echo '============================================================'
if [ -f "$HOME/kube-flannel.yml" ]; then
  rm -rf $HOME/kube-flannel.yml
fi
wget -P $HOME/ https://raw.githubusercontent.com/coreos/flannel/${FLANNEL_VERSION}/Documentation/kube-flannel.yml
sed -i 's/quay.io\/coreos\/flannel/registry.cn-hangzhou.aliyuncs.com\/szss_k8s\/flannel/g' $HOME/kube-flannel.yml
kubectl --namespace kube-system apply -f $HOME/kube-flannel.yml
echo "Flannel created!"

fi
#=========================master end===================================


#=========================slave begin===================================
if [ "$NODE_TYPE" = 'slave' ]; then
echo '============================================================'
echo '==============Join kubernetes cluster...===================='
echo '============================================================'
export KUBE_REPO_PREFIX="registry.cn-hangzhou.aliyuncs.com/szss_k8s"
export KUBE_ETCD_IMAGE="registry.cn-hangzhou.aliyuncs.com/szss_k8s/etcd-amd64:${ETCD_VERSION}"
kubeadm join --token ${KUBE_TOKEN} ${MASTER_ADDRESS}:6443 --skip-preflight-checks
echo "Join kubernetes cluster success!"
fi
#=========================slave end===================================

