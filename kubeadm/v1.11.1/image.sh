#!/bin/bash

#该脚本是将kubernetes相关镜像上传到aliyun

#查看gcr.io镜像
#https://console.cloud.google.com/kubernetes/images/list?location=GLOBAL&project=google-containers
#通过下面的网址查看依赖镜像的版本号：
#https://kubernetes.io/docs/admin/kubeadm/
set -o errexit
set -o nounset
set -o pipefail

KUBE_VERSION=v1.11.1
HYPERKUBE_VERSION=v1.11.1_coreos.0
KUBE_PAUSE_VERSION=3.1
ETCD_VERSION=3.1.17
DNS_VERSION=1.14.10

GCR_URL=gcr.io/google_containers
ALIYUN_URL=registry.cn-hangzhou.aliyuncs.com/szss_k8s

images=(
kube-proxy-amd64:${KUBE_VERSION}
kube-scheduler-amd64:${KUBE_VERSION}
kube-controller-manager-amd64:${KUBE_VERSION}
kube-apiserver-amd64:${KUBE_VERSION}
pause-amd64:${KUBE_PAUSE_VERSION}
etcd-amd64:${ETCD_VERSION}
k8s-dns-sidecar-amd64:${DNS_VERSION}
k8s-dns-kube-dns-amd64:${DNS_VERSION}
k8s-dns-dnsmasq-nanny-amd64:${DNS_VERSION}
)


for imageName in ${images[@]} ; do
  docker pull $GCR_URL/$imageName
  docker tag $GCR_URL/$imageName $ALIYUN_URL/$imageName
done

for imageName in ${images[@]} ; do
  docker push $ALIYUN_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done
