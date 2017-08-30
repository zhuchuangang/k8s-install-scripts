[TOC]

# 0 环境

环境：

主机名 | IP
---|---
k8s-node01 | 172.16.120.151
k8s-node02 | 172.16.120.152
k8s-node03 | 172.16.120.153
ansible-client| 

==mac os x固定vware虚拟机IP
```sudo vi /Library/Preferences/VMware\ Fusion/vmnet8/dhcpd.conf```
在文件末尾添加==
```
host CentOS01{
    hardware ethernet 00:0C:29:15:5C:F1;
    fixed-address 172.16.120.151;
}
host CentOS02{
    hardware ethernet 00:0C:29:D1:C4:9A;
    fixed-address 172.16.120.152;
}
host CentOS03{
    hardware ethernet 00:0C:29:C2:A6:93;
    fixed-address 172.16.120.153;
}
```
- centos01为固定ip虚拟机的名称
- hardware ethernet 硬件地址
- fixed-address 固定ip地址

ip地址取值范围必须在hdcpd.conf给定的范围内,配置完成后重启vware。

设置主机名：
```
hostnamectl --static set-hostname  k8s-node01
hostnamectl --static set-hostname  k8s-node02
hostnamectl --static set-hostname  k8s-node03
```

关闭防火墙：
```
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

由于kubespay安装方式会检测docker是否安装，如果没有安装会安装docker，但是使用的源是https://yum.dockerproject.org/repo/main/centos/7，速度会比较慢，建议提前安装好。


使用阿里云yum镜像,docker安装速度快
```
#docker yum源
cat >> /etc/yum.repos.d/docker.repo <<EOF
[docker-repo]
name=Docker Repository
baseurl=http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7
enabled=1
gpgcheck=0
EOF
```
同时配置好阿里云加速器
```
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://5md0553g.mirror.aliyuncs.com"]
}
EOF
```
手动安装docker:
```
#查看docker版本
yum list docker-engine –showduplicates
#安装docker
yum install -y docker-engine-1.13.1-1.el7.centos.x86_64
```


# 1 安装 ansible
在ansible的控制服务器ansible-client上安装ansible。
```
# 安装 python 及 epel
yum install -y epel-release python-pip python34 python34-pip
# 安装 ansible(必须先安装 epel 源再安装 ansible)
yum install -y ansible
```
托管节点python的版本需要大于2.5。

ansible不支持windows，其他系统的安装方式可以查阅ansible官方网站。

Ansible中文权威指南：
http://ansible-tran.readthedocs.io/en/latest/

# 2 设置免密登录
在ansible-client执行 ssh-keygen -t rsa 生成密钥对
```
ssh-keygen -t rsa -P ''
```
将~/.ssh/id_rsa.pub复制到其他所有节点，这样ansible-client到其他所有节点可以免密登录
```
IP=(172.16.120.151 172.16.120.152 172.16.120.153)
for x in ${IP[*]}; do ssh-copy-id -i ~/.ssh/id_rsa.pub $x; done
```
要使用root权限执行上面操作。
# 3 下载kuberspay源码
可以从主分支下载：
```
git clone https://github.com/kubernetes-incubator/kubespray.git
```
也可以下载发布版本：
```
wget https://github.com/kubernetes-incubator/kubespray/archive/v2.1.2.tar.gz
```
本文采用v2.1.2 发布版本安装。

# 4 将grc.io和quay.io的镜像上传到阿里云
kuberspay涉及到的镜像。
```
quay.io/coreos/hyperkube:v1.7.3_coreos.0
quay.io/coreos/etcd:v3.2.4
quay.io/calico/ctl:v1.4.0
quay.io/calico/node:v2.4.1
quay.io/calico/cni:v1.10.0
quay.io/kube-policy-controller:v0.7.0
quay.io/calico/routereflector:v0.3.0
quay.io/coreos/flannel:v0.8.0
quay.io/coreos/flannel-cni:v0.2.0
quay.io/l23network/k8s-netchecker-agent:v1.0
quay.io/l23network/k8s-netchecker-server:v1.0
weaveworks/weave-kube:2.0.1
weaveworks/weave-npc:2.0.1
gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3
gcr.io/google_containers/cluster-proportional-autoscaler-amd64:1.1.1
gcr.io/google_containers/fluentd-elasticsearch:1.22
gcr.io/google_containers/kibana:v4.6.1
gcr.io/google_containers/elasticsearch:v2.4.1
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.2
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.2
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.2
gcr.io/google_containers/pause-amd64:3.0
gcr.io/kubernetes-helm/tiller:v2.2.2
gcr.io/google_containers/heapster-grafana-amd64:v4.4.1
gcr.io/google_containers/heapster-amd64:v1.4.0
gcr.io/google_containers/heapster-influxdb-amd64:v1.1.1
gcr.io/google_containers/nginx-ingress-controller:0.9.0-beta.11
gcr.io/google_containers/defaultbackend:1.3
```

通过grc.io的到阿里云：
```
#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

kubednsautoscaler_version=1.1.1
dns_version=1.14.2
kube_pause_version=3.0
dashboard_version=v1.6.3
fluentd_es_version=1.22
kibana_version=v4.6.1
elasticsearch_version=v2.4.1
heapster_version=v1.4.0
heapster_grafana_version=v4.4.1
heapster_influxdb_version=v1.1.1
nginx_ingress_version=0.9.0-beta.11
defaultbackend_version=1.3

GCR_URL=gcr.io/google_containers
ALIYUN_URL=registry.cn-hangzhou.aliyuncs.com/szss_k8s

images=(
cluster-proportional-autoscaler-amd64:${kubednsautoscaler_version}
k8s-dns-sidecar-amd64:${dns_version}
k8s-dns-kube-dns-amd64:${dns_version}
k8s-dns-dnsmasq-nanny-amd64:${dns_version}
pause-amd64:${kube_pause_version}
kubernetes-dashboard-amd64:${dashboard_version}
fluentd-elasticsearch:${fluentd_es_version}
kibana:${kibana_version}
elasticsearch:${elasticsearch_version}
fluentd-elasticsearch:${fluentd_es_version}
kibana:${kibana_version}
heapster-amd64:${heapster_version}
heapster-grafana-amd64:${heapster_grafana_version}
heapster-influxdb-amd64:${heapster_influxdb_version}
nginx-ingress-controller:${nginx_ingress_version}
defaultbackend:${defaultbackend_version}
)

for imageName in ${images[@]} ; do
  docker pull $GCR_URL/$imageName
  docker tag $GCR_URL/$imageName $ALIYUN_URL/$imageName
  docker push $ALIYUN_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done
```

通过quay.io的镜像到阿里云：
```
QUAY_URL=quay.io
ALIYUN_URL=registry.cn-hangzhou.aliyuncs.com/szss_quay_io

# master分支
#images=(
#coreos/hyperkube:v1.7.3_coreos.0
#coreos/etcd:v3.2.4
#coreos/flannel:v0.8.0
#coreos/flannel-cni:v0.2.0
#calico/kube-policy-controller:v0.7.0
#calico/ctl:v1.4.0
#calico/node:v2.4.1
#calico/cni:v1.10.0
#calico/routereflector:v0.3.0
#l23network/k8s-netchecker-agent:v1.0
#l23network/k8s-netchecker-server:v1.0
#)
# kuberspay v2.1.2版本
images=(
coreos/hyperkube:v1.6.7_coreos.0
coreos/etcd:v3.2.4
coreos/flannel:v0.8.0
coreos/flannel-cni:v0.2.0
calico/kube-policy-controller:v0.5.4
calico/ctl:v1.1.3
calico/node:v1.1.3
calico/cni:v1.8.0
calico/routereflector:v0.3.0
l23network/k8s-netchecker-agent:v1.0
l23network/k8s-netchecker-server:v1.0
)

for imageName in ${images[@]} ; do
  docker pull $QUAY_URL/$imageName
  docker tag $QUAY_URL/$imageName $ALIYUN_URL/${imageName/\//-}
  docker push $ALIYUN_URL/${imageName/\//-}
  docker rmi $ALIYUN_URL/${imageName/\//-}
done
```

# 5 镜像替换
在kuberspay源码源代码中搜索包含 gcr.io/google_containers 和 quay.io 镜像的文件，并替换为我们之前已经上传到阿里云的进行，替换脚步如下：

```
grc_image_files=(
./kubespray/extra_playbooks/roles/dnsmasq/templates/dnsmasq-autoscaler.yml
./kubespray/extra_playbooks/roles/download/defaults/main.yml
./kubespray/extra_playbooks/roles/kubernetes-apps/ansible/defaults/main.yml
./kubespray/roles/download/defaults/main.yml
./kubespray/roles/dnsmasq/templates/dnsmasq-autoscaler.yml
./kubespray/roles/kubernetes-apps/ansible/defaults/main.yml
)

for file in ${grc_image_files[@]} ; do
    sed -i 's/gcr.io\/google_containers/registry.cn-hangzhou.aliyuncs.com\/szss_k8s/g' $file
done

quay_image_files=(
./kubespray/extra_playbooks/roles/download/defaults/main.yml
./kubespray/roles/download/defaults/main.yml
)

for file in ${quay_image_files[@]} ; do
    sed -i 's/quay.io\/coreos\//registry.cn-hangzhou.aliyuncs.com\/szss_quay_io\/coreos-/g' $file
    sed -i 's/quay.io\/calico\//registry.cn-hangzhou.aliyuncs.com\/szss_quay_io\/calico-/g' $file
    sed -i 's/quay.io\/l23network\//registry.cn-hangzhou.aliyuncs.com\/szss_quay_io\/l23network-/g' $file
done
```
如果在mac os x执行脚本，需要在sed -i 后面添加一个空字符串，例如sed -i '' 's/a/b/g' file

# 6 配置文件内容
可以对basic_auth的密码进行修改，网络插件默认calico，可替换成weave或flannel，还可以配置是否安装helm和efk。

下面的的配置为kuberspay 2.1.2的配置。
```
$vi ~/kubespray/inventory/group_vars/k8s-cluster.yml

# Kubernetes configuration dirs and system namespace.
# Those are where all the additional config stuff goes
# the kubernetes normally puts in /srv/kubernets.
# This puts them in a sane location and namespace.
# Editting those values will almost surely break something.
kube_config_dir: /etc/kubernetes
kube_script_dir: "{{ bin_dir }}/kubernetes-scripts"
kube_manifest_dir: "{{ kube_config_dir }}/manifests"
system_namespace: kube-system

# Logging directory (sysvinit systems)
kube_log_dir: "/var/log/kubernetes"

# This is where all the cert scripts and certs will be located
kube_cert_dir: "{{ kube_config_dir }}/ssl"

# This is where all of the bearer tokens will be stored
kube_token_dir: "{{ kube_config_dir }}/tokens"

# This is where to save basic auth file
kube_users_dir: "{{ kube_config_dir }}/users"

kube_api_anonymous_auth: false

## Change this to use another Kubernetes version, e.g. a current beta release
kube_version: v1.6.7

# Where the binaries will be downloaded.
# Note: ensure that you've enough disk space (about 1G)
local_release_dir: "/tmp/releases"
# Random shifts for retrying failed ops like pushing/downloading
retry_stagger: 5

# This is the group that the cert creation scripts chgrp the
# cert files to. Not really changable...
kube_cert_group: kube-cert

# Cluster Loglevel configuration
kube_log_level: 2

# Users to create for basic auth in Kubernetes API via HTTP
# Optionally add groups for user
kube_api_pwd: "changeme"
kube_users:
  kube:
    pass: "{{kube_api_pwd}}"
    role: admin
  root:
    pass: "{{kube_api_pwd}}"
    role: admin
    # groups:
    #   - system:masters



## It is possible to activate / deactivate selected authentication methods (basic auth, static token auth)
#kube_oidc_auth: false
#kube_basic_auth: false
#kube_token_auth: false


## Variables for OpenID Connect Configuration https://kubernetes.io/docs/admin/authentication/
## To use OpenID you have to deploy additional an OpenID Provider (e.g Dex, Keycloak, ...)

# kube_oidc_url: https:// ...
# kube_oidc_client_id: kubernetes
## Optional settings for OIDC
# kube_oidc_ca_file: {{ kube_cert_dir }}/ca.pem
# kube_oidc_username_claim: sub
# kube_oidc_groups_claim: groups


# Choose network plugin (calico, weave or flannel)
# Can also be set to 'cloud', which lets the cloud provider setup appropriate routing
kube_network_plugin: calico

# weave's network password for encryption
# if null then no network encryption
# you can use --extra-vars to pass the password in command line
weave_password: EnterPasswordHere

# Weave uses consensus mode by default
# Enabling seed mode allow to dynamically add or remove hosts
# https://www.weave.works/docs/net/latest/ipam/
weave_mode_seed: false

# This two variable are automatically changed by the weave's role, do not manually change these values
# To reset values :
# weave_seed: uninitialized
# weave_peers: uninitialized
weave_seed: uninitialized
weave_peers: uninitialized

# Enable kubernetes network policies
enable_network_policy: false

# Kubernetes internal network for services, unused block of space.
kube_service_addresses: 10.233.0.0/18

# internal network. When used, it will assign IP
# addresses from this range to individual pods.
# This network must be unused in your network infrastructure!
kube_pods_subnet: 10.233.64.0/18

# internal network node size allocation (optional). This is the size allocated
# to each node on your network.  With these defaults you should have
# room for 4096 nodes with 254 pods per node.
kube_network_node_prefix: 24

# The port the API Server will be listening on.
kube_apiserver_ip: "{{ kube_service_addresses|ipaddr('net')|ipaddr(1)|ipaddr('address') }}"
kube_apiserver_port: 6443 # (https)
kube_apiserver_insecure_port: 8080 # (http)

# DNS configuration.
# Kubernetes cluster name, also will be used as DNS domain
cluster_name: cluster.local
# Subdomains of DNS domain to be resolved via /etc/resolv.conf for hostnet pods
ndots: 2
# Can be dnsmasq_kubedns, kubedns or none
dns_mode: kubedns
# Can be docker_dns, host_resolvconf or none
resolvconf_mode: docker_dns
# Deploy netchecker app to verify DNS resolve as an HTTP service
deploy_netchecker: false
# Ip address of the kubernetes skydns service
skydns_server: "{{ kube_service_addresses|ipaddr('net')|ipaddr(3)|ipaddr('address') }}"
dns_server: "{{ kube_service_addresses|ipaddr('net')|ipaddr(2)|ipaddr('address') }}"
dns_domain: "{{ cluster_name }}"

# Path used to store Docker data
docker_daemon_graph: "/var/lib/docker"

## A string of extra options to pass to the docker daemon.
## This string should be exactly as you wish it to appear.
## An obvious use case is allowing insecure-registry access
## to self hosted registries like so:

docker_options: "--insecure-registry={{ kube_service_addresses }} --graph={{ docker_daemon_graph }}  {{ docker_log_opts }}"
docker_bin_dir: "/usr/bin"

# Settings for containerized control plane (etcd/kubelet/secrets)
etcd_deployment_type: docker
kubelet_deployment_type: docker
cert_management: script
vault_deployment_type: docker

# K8s image pull policy (imagePullPolicy)
k8s_image_pull_policy: IfNotPresent

# Monitoring apps for k8s
efk_enabled: false

# Helm deployment
helm_enabled: false

# dnsmasq
# dnsmasq_upstream_dns_servers:
#  - /resolvethiszone.with/10.0.4.250
#  - 8.8.8.8

#  Enable creation of QoS cgroup hierarchy, if true top level QoS and pod cgroups are created. (default true)
# kubelet_cgroups_per_qos: true

# A comma separated list of levels of node allocatable enforcement to be enforced by kubelet.
# Acceptible options are 'pods', 'system-reserved', 'kube-reserved' and ''. Default is "".
# kubelet_enforce_node_allocatable: pods

```

# 7 生成集群配置
```
yum install -y python-pip python34 python34-pip
```


```
# 定义集群IP
IP=(
172.16.120.151
172.16.120.152
172.16.120.153
)
# 利用kubespray自带的python脚本生成配置
CONFIG_FILE=./kubespray/inventory/inventory.cfg python3 ./kubespray/contrib/inventory_builder/inventory.py ${IP[*]}

```
集群配置如下：
```
$cat ./kubespray/inventory/inventory.cfg 
[all]
node1 	 ansible_host=172.16.120.151 ip=172.16.120.151
node2 	 ansible_host=172.16.120.152 ip=172.16.120.152
node3 	 ansible_host=172.16.120.153 ip=172.16.120.153

[kube-master]
node1 	 
node2 	 

[kube-node]
node1 	 
node2 	 
node3 	 

[etcd]
node1 	 
node2 	 
node3 	 

[k8s-cluster:children]
kube-node 	 
kube-master 	 

[calico-rr]

[vault]
node1 	 
node2 	 
node3
```


# 8 安装集群
```
cd kubespray
ansible-playbook -i inventory/inventory.cfg cluster.yml -b -v --private-key=~/.ssh/id_rsa
```

# 9 troubles shooting
错误1：在安装过程中报错：
```
fatal: [node1]: FAILED! => {"failed": true, "msg": "The ipaddr filter requires python-netaddr be installed on the ansible controller"}
```
需要安装 python-netaddr，安装命令pip install netaddr。


错误2：在安装过程中报错：
```
{"failed": true, "msg": "The conditional check '{%- set certs = {'sync': False} -%}\n{% if gen_node_certs[inventory_hostname] or\n  (not etcdcert_node.results[0].stat.exists|default(False)) or\n    (not etcdcert_node.results[1].stat.exists|default(False)) or\n      (etcdcert_node.results[1].stat.checksum|default('') != etcdcert_master.files|selectattr(\"path\", \"equalto\", etcdcert_node.results[1].stat.path)|map(attribute=\"checksum\")|first|default('')) -%}\n        {%- set _ = certs.update({'sync': True}) -%}\n{% endif %}\n{{ certs.sync }}' failed. The error was: no test named 'equalto'\n\nThe error appears to have been in '/root/kubespray/roles/etcd/tasks/check_certs.yml': line 57, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: \"Check_certs | Set 'sync_certs' to true\"\n  ^ here\n"}
```
升级Jinja2到2.8版本，参考https://github.com/kubernetes-incubator/kubespray/issues/1190， 安装命令pip install --upgrade Jinja2



# 10 安装失败清理
```
rm -rf /etc/kubernetes/
rm -rf /var/lib/kubelet
rm -rf /var/lib/etcd
rm -rf /usr/local/bin/kubectl
rm -rf /etc/systemd/system/calico-node.service
rm -rf /etc/systemd/system/kubelet.service
systemctl stop etcd.service
systemctl disable etcd.service
systemctl stop calico-node.service
systemctl disable calico-node.service
docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
service docker restart
```

# 11 参考
使用kuberspay无坑安装生产级Kubernetes集群: http://www.wisely.top/2017/07/01/no-problem-kubernetes-kuberspay/

使用kuberspay快速部署kubernetes高可用集群： https://mritd.me/2017/03/03/set-up-kubernetes-ha-cluster-by-kargo/

kargo 集群扩展及细粒度配置： https://mritd.me/2017/03/10/kargo-cluster-expansion-and-fine-grained-configuration/

kubespray容器化部署kubernetes高可用集群：
https://kevinguo.me/2017/07/06/kubespray-deploy-kubernetes-1/

使用kargo 安装kubernetes 1.5.3 高可用环境
http://www.jianshu.com/p/ffbfdea089d5
