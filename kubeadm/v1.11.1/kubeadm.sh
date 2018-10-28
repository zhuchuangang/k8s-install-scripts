#!/usr/bin/env bash

#set -x
#如果任何语句的执行结果不是true则应该退出,set -o errexit和set -e作用相同
set -e

#id -u显示用户ID,root用户的ID为0
root=$(id -u)
#脚本需要使用root用户执行
if [ "$root" -ne 0 ] ;then
    echo "must run as root"
    exit 1
fi

#
#系统判定
#
linux_os()
{
    cnt=$(cat /etc/centos-release|grep "CentOS"|grep "release 7"|wc -l)
    if [ "$cnt" != "1" ];then
       echo "Only support CentOS 7...  exit"
       exit 1
    fi
}
#
#关闭selinux
#
selinux_disable()
{
    # 关闭selinux
    if [ $(getenforce) = "Enabled" ]; then
    setenforce 0
    fi
    # selinux设置为disabled
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    echo "Selinux disabled success!"
}

#
#关闭防火墙
#
firewalld_stop()
{
    # 关闭防火墙
    systemctl disable firewalld
    systemctl stop firewalld
    echo "Firewall disabled success!"
}

#
#安装docker
#
docker_install()
{
    # dockerproject docker源
    cat > /etc/yum.repos.d/docker.repo <<EOF
[docker-repo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=0
EOF

    #查看docker版本
    #yum list docker-engine showduplicates
    #安装docker
    yum install -y docker-engine-1.12.6-1.el7.centos.x86_64
    echo "Docker installed successfully!"
    #docker存储目录
    if [ ! -n "$DOCKER_GRAPH" ]; then
        export DOCKER_GRAPH="/mnt/docker"
    fi
    #docker加速器
    if [ ! -n "$DOCKER_MIRRORS" ]; then
        export DOCKER_MIRRORS="https://5md0553g.mirror.aliyuncs.com"
    fi
    # 如果/etc/docker目录不存在，就创建目录
    if [ ! -d "/etc/docker" ]; then
     mkdir -p /etc/docker
    fi
    # 配置加速器
    cat > /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": ["${DOCKER_MIRRORS}"],
    "graph":"${DOCKER_GRAPH}"
}
EOF
    echo "Config docker success!"
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
    echo "Docker start successfully!"
}

#
#kubelet kubeadm kubectl kubernetes-cni安装包
#
kube_rpm()
{
    if [ ! -n "$KUBE_VERSION" ]; then
        export KUBE_VERSION="1.9.1"
    fi
    if [ ! -n "$KUBE_CNI_VERSION" ]; then
        export KUBE_CNI_VERSION="0.6.0"
    fi
    if [ ! -n "$SOCAT_VERSION" ]; then
        export SOCAT_VERSION="1.7.3.2"
    fi
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  yum install -y kubelet kubeadm kubectl
  
}

#
#配置docker镜像
#
kube_repository()
{
    if [ ! -n "$ETCD_VERSION" ]; then
        export ETCD_VERSION="3.1.10"
    fi
    if [ ! -n "$PAUSE_VERSION" ]; then
        export PAUSE_VERSION="3.0"
    fi
    if [ ! -n "$FLANNEL_VERSION" ]; then
        export FLANNEL_VERSION="v0.9.1"
    fi

    #KUBE_REPO_PREFIX环境变量已经失效，需要通过MasterConfiguration对象进行设置
    export KUBE_REPO_PREFIX=registry.cn-hangzhou.aliyuncs.com/szss_k8s
}

#
#安装kubernetes的rpm包
#
kube_install()
{
    # Kubernetes 1.8开始要求关闭系统的Swap，如果不关闭，默认配置下kubelet将无法启动。可以通过kubelet的启动参数–fail-swap-on=false更改这个限制。
    # 修改 /etc/fstab 文件，注释掉 SWAP 的自动挂载，使用free -m确认swap已经关闭。
    swapoff -a
    echo "Swap off success!"

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
    echo "Network configuration success!"
    #kubelet kubeadm kubectl kubernetes-cni安装包
    kube_rpm

    kube_repository

    #下载安装包
    if [ ! -f $PWD"/"$RPM_KUBEADM ]; then
        wget $RPM_KUBEADM_URL
    fi
    if [ ! -f $PWD"/"$RPM_KUBECTL ]; then
        wget $RPM_KUBECTL_URL
    fi
    if [ ! -f $PWD"/"$RPM_KUBELET ]; then
        wget $RPM_KUBELET_URL
    fi
    if [ ! -f $PWD"/"$RPM_KUBECNI ]; then
        wget $RPM_KUBECNI_URL
    fi
    if [ ! -f $PWD"/"$RPM_SOCAT ]; then
        wget $RPM_SOCAT_URL
    fi
    rpm -ivh $PWD"/"$RPM_KUBECNI $PWD"/"$RPM_SOCAT $PWD"/"$RPM_KUBEADM $PWD"/"$RPM_KUBECTL $PWD"/"$RPM_KUBELET
    echo "kubelet kubeadm kubectl kubernetes-cni installed successfully!"

    sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    echo "config cgroup-driver=cgroupfs success!"

    export KUBE_PAUSE_IMAGE=${KUBE_REPO_PREFIX}"/pause-amd64:${PAUSE_VERSION}"

    cat > /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--pod-infra-container-image=${KUBE_PAUSE_IMAGE}"
EOF
    echo "config --pod-infra-container-image=${KUBE_PAUSE_IMAGE} success!"

    systemctl daemon-reload
    systemctl enable kubelet
    systemctl start kubelet
    echo "Kubelet installed successfully!"
}


#
#启动主节点
#
kube_master_up(){
    #关闭selinux
    selinux_disable
    #关闭防火墙
    firewalld_stop
    #安装docker
    docker_install
    #安装RPM包
    kube_install

    if [ ! -n "$KUBE_TOKEN" ]; then
        export KUBE_TOKEN="863f67.19babbff7bfe8543"
    fi
    # 其他更多参数请通过kubeadm init --help查看
    # 参考：https://kubernetes.io/docs/reference/generated/kubeadm/
    export KUBE_ETCD_IMAGE=${KUBE_REPO_PREFIX}"/etcd-amd64:${ETCD_VERSION}"

    # 如果使用etcd集群，请使用etcd.endpoints配置
    cat > /etc/kubernetes/kubeadm.conf <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v${KUBE_VERSION}
api:
    advertiseAddress: ${MASTER_ADDRESS}
etcd:
    image: ${KUBE_ETCD_IMAGE}
networking:
    serviceSubnet: 10.96.0.0/12
    podSubnet: 10.244.0.0/16
imageRepository: ${KUBE_REPO_PREFIX}
tokenTTL: 0s
token: ${KUBE_TOKEN}
EOF

    kubeadm init --config /etc/kubernetes/kubeadm.conf --skip-preflight-checks

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

    if [ -f "$HOME/kube-flannel.yml" ]; then
        rm -rf $HOME/kube-flannel.yml
    fi
    wget -P $HOME/ https://raw.githubusercontent.com/coreos/flannel/${FLANNEL_VERSION}/Documentation/kube-flannel.yml
    sed -i 's/quay.io\/coreos\/flannel/registry.cn-hangzhou.aliyuncs.com\/szss_k8s\/flannel/g' $HOME/kube-flannel.yml
    kubectl --namespace kube-system apply -f $HOME/kube-flannel.yml
    echo "Flannel installed successfully!"
}

#
#启动子节点
#
kube_slave_up()
{
    #关闭selinux
    selinux_disable
    #关闭防火墙
    firewalld_stop
    #安装docker
    docker_install
    #安装RPM包
    kube_install

    if [ ! -n "$KUBE_TOKEN" ]; then
        export KUBE_TOKEN="863f67.19babbff7bfe8543"
    fi

    kubeadm join --token ${KUBE_TOKEN} \
    --discovery-token-unsafe-skip-ca-verification \
    --skip-preflight-checks \
    ${MASTER_ADDRESS}:6443
    echo "Join kubernetes cluster success!"
}

#
# 重置集群
#
kube_reset()
{
    kubeadm reset

    rm -rf /var/lib/cni /etc/cni/ /run/flannel/subnet.env /etc/kubernetes/kubeadm.conf

    # 删除rpm安装包
    yum remove -y kubectl kubeadm kubelet kubernetes-cni socat

    #ifconfig cni0 down
    ip link delete cni0
    #ifconfig flannel.1 down
    ip link delete flannel.1
}


kube_help()
{
    echo "usage: $0 --node-type master --master-address 127.0.0.1 --token xxxx"
    echo "       $0 --node-type node --master-address 127.0.0.1 --token xxxx"
    echo "       $0 reset     reset the kubernetes cluster,include all data!"
    echo "       unkown command $0 $@"
}


main()
{
    #系统检测
    linux_os
    #$# 查看这个程式的参数个数
    while [[ $# -gt 0 ]]
    do
        #获取第一个参数
        key="$1"

        case $key in
            #主节点IP
            --master-address)
                export MASTER_ADDRESS=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #获取docker存储路径
            --docker-graph)
                export DOCKER_GRAPH=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #获取docker加速器地址
            --docker-mirrors)
                export DOCKER_MIRRORS=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #获取节点类型
            -n|--node-type)
                export NODE_TYPE=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #获取kubeadm的token
            -t|--token)
                export KUBE_TOKEN=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #重置集群
            r|reset)
                kube_reset
                exit 1
            ;;
            #获取kubeadm的token
            -h|--help)
                kube_help
                exit 1
            ;;
            *)
                # unknown option
                echo "unkonw option [$key]"
            ;;
        esac
        shift
    done

    if [ "" == "$MASTER_ADDRESS" -o "" == "$NODE_TYPE" ];then
        if [ "$NODE_TYPE" != "down" ];then
            echo "--master-address and --node-type must be provided!"
            exit 1
        fi
    fi

 case $NODE_TYPE in
    "m" | "master" )
        kube_master_up
        ;;
    "n" | "node" )
        kube_slave_up
        ;;
    *)
        kube_help
        ;;
 esac
}

main $@
