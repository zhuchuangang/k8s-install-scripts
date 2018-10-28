# 1 简介
RKE是类似kubeadm、kuberspay的kubernetes安装工具。

项目地址：[https://github.com/rancher/rke](https://github.com/rancher/rke)

# 2 准备工作
CentOS7不能用root用户安装RKE；如果使用普通用户进行RKE安装，要将普通用户（如k8s）加入到docker组，命令：sudo usermod -aG docker k8s 注意：重启系统以后才能生效，只重启Docker服务是不行的！重启后，user01用户也可以直接使用docker run命令。

```bash
# 新建docker用户组
groupadd docker
# 新增用户
useradd k8s
# 用户设置密码
passwd k8s
# 将用户添加到docker用户组
usermod -aG docker k8s
```

使用  sshd  -V 查看sshd版本，如果sshd版本不是6.7以上，请升级sshd。
```plain
wget https://centos-k8s.oss-cn-hangzhou.aliyuncs.com/sshd/sshd-update.sh
chmod a+x sshd-update.sh
sh -i sshd-update.sh
```

# 3 下载RKE
```
# 下载rke
wget https://centos-k8s.oss-cn-hangzhou.aliyuncs.com/rke/0.1.11/rke_linux-amd64
# 修改文件名
mv rke_linux-amd64 rke
# 设置执行权限
chmod a+x rke
# 添加到/usr/bin目录
mv rke /usr/bin
```
# 4 免密登录
ssh-keygen -t rsa 生成密钥对
```
ssh-keygen -t rsa -P ''
```
将~/.ssh/id\_rsa.pub复制到其他所有节点，这样rke到其他所有节点可以免密登录
```
IP=(172.16.120.191
172.16.120.192
172.16.120.193)
for x in ${IP[*]}; do ssh-copy-id -i ~/.ssh/id_rsa.pub $x; done
```
要使用root权限执行上面操作。

# 5 生成cluster.yaml配置文件
通过下面的命令根据提示生成cluster.yaml配货文件：
```
[k8s@kube01 ~]$ rke config
[+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]:
[+] Number of Hosts [1]: 3
[+] SSH Address of host (1) [none]: 172.16.120.191
[+] SSH Port of host (1) [22]:
[+] SSH Private Key Path of host (172.16.120.191) [none]: ~/.ssh/id_rsa
[+] SSH User of host (172.16.120.191) [ubuntu]: k8s
[+] Is host (172.16.120.191) a Control Plane host (y/n)? [y]:
[+] Is host (172.16.120.191) a Worker host (y/n)? [n]: n
[+] Is host (172.16.120.191) an etcd host (y/n)? [n]: n
[+] Override Hostname of host (172.16.120.191) [none]: k8s-master
[+] Internal IP of host (172.16.120.191) [none]:
[+] Docker socket path on host (172.16.120.191) [/var/run/docker.sock]:
[+] SSH Address of host (2) [none]: 172.16.120.192
[+] SSH Port of host (2) [22]:
[+] SSH Private Key Path of host (172.16.120.192) [none]: ~/.ssh/id_rsa
[+] SSH User of host (172.16.120.192) [ubuntu]: k8s
[+] Is host (172.16.120.192) a Control Plane host (y/n)? [y]: n
[+] Is host (172.16.120.192) a Worker host (y/n)? [n]: n
[+] Is host (172.16.120.192) an etcd host (y/n)? [n]: y
[+] Override Hostname of host (172.16.120.192) [none]: k8s-etcd
[+] Internal IP of host (172.16.120.192) [none]:
[+] Docker socket path on host (172.16.120.192) [/var/run/docker.sock]:
[+] SSH Address of host (3) [none]: 172.16.120.193
[+] SSH Port of host (3) [22]:
[+] SSH Private Key Path of host (172.16.120.193) [none]: ~/.ssh/id_rsa
[+] SSH User of host (172.16.120.193) [ubuntu]: k8s
[+] Is host (172.16.120.193) a Control Plane host (y/n)? [y]: n
[+] Is host (172.16.120.193) a Worker host (y/n)? [n]: y
[+] Is host (172.16.120.193) an etcd host (y/n)? [n]: n
[+] Override Hostname of host (172.16.120.193) [none]: k8s-worker
[+] Internal IP of host (172.16.120.193) [none]:
[+] Docker socket path on host (172.16.120.193) [/var/run/docker.sock]:
[+] Network Plugin Type (flannel, calico, weave, canal) [canal]:
[+] Authentication Strategy [x509]:
[+] Authorization Mode (rbac, none) [rbac]:
[+] Kubernetes Docker image [rancher/hyperkube:v1.11.1-rancher1]:
[+] Cluster domain [cluster.local]:
[+] Service Cluster IP Range [10.43.0.0/16]:
[+] Enable PodSecurityPolicy [n]:
[+] Cluster Network CIDR [10.42.0.0/16]:
[+] Cluster DNS Service IP [10.43.0.10]:
[+] Add addon manifest URLs or YAML files [no]:  
```

# 6 安装集群
```
rke up --config cluster.yml
```
安装日志如下：
```
INFO[0000] Building Kubernetes cluster                  
INFO[0000] [dialer] Setup tunnel for host [172.16.120.193]
INFO[0000] [dialer] Setup tunnel for host [172.16.120.192]
INFO[0000] [dialer] Setup tunnel for host [172.16.120.191]
INFO[0000] [network] Deploying port listener containers
INFO[0000] [network] Port listener containers deployed successfully
INFO[0000] [network] Running control plane -> etcd port checks
INFO[0000] [remove/rke-port-checker] Successfully removed container on host [172.16.120.191]
INFO[0001] [network] Successfully started [rke-port-checker] container on host [172.16.120.191]
INFO[0001] [network] Running control plane -> worker port checks
INFO[0001] [network] Successfully started [rke-port-checker] container on host [172.16.120.191]
INFO[0001] [network] Running workers -> control plane port checks
INFO[0001] [network] Successfully started [rke-port-checker] container on host [172.16.120.193]
INFO[0001] [network] Checking KubeAPI port Control Plane hosts
INFO[0001] [network] Removing port listener containers  
INFO[0001] [remove/rke-etcd-port-listener] Successfully removed container on host [172.16.120.192]
INFO[0001] [remove/rke-cp-port-listener] Successfully removed container on host [172.16.120.191]
INFO[0001] [remove/rke-worker-port-listener] Successfully removed container on host [172.16.120.193]
INFO[0001] [network] Port listener containers removed successfully
INFO[0001] [certificates] Attempting to recover certificates from backup on [etcd,controlPlane] hosts
INFO[0004] [certificates] Certificate backup found on [etcd,controlPlane] hosts
INFO[0004] [reconcile] Rebuilding and updating local kube config
INFO[0004] Successfully Deployed local admin kubeconfig at [./kube_config_cluster.yml]
INFO[0004] [reconcile] host [172.16.120.191] is active master on the cluster
INFO[0005] [reconcile] Reconciling cluster state        
INFO[0005] [reconcile] This is newly generated cluster  
INFO[0005] [certificates] Deploying kubernetes certificates to Cluster nodes
INFO[0010] Successfully Deployed local admin kubeconfig at [./kube_config_cluster.yml]
INFO[0010] [certificates] Successfully deployed kubernetes certificates to Cluster nodes
INFO[0010] Pre-pulling kubernetes images                
INFO[0010] Kubernetes images pulled successfully        
INFO[0010] [etcd] Building up etcd plane..              
INFO[0018] [etcd] Successfully updated [etcd] container on host [172.16.120.192]
INFO[0018] [etcd] Successfully started [rke-log-linker] container on host [172.16.120.192]
INFO[0018] [remove/rke-log-linker] Successfully removed container on host [172.16.120.192]
INFO[0018] [etcd] Successfully started etcd plane..     
INFO[0018] [controlplane] Building up Controller Plane..
INFO[0018] [remove/service-sidekick] Successfully removed container on host [172.16.120.191]
INFO[0018] [healthcheck] Start Healthcheck on service [kube-apiserver] on host [172.16.120.191]
INFO[0018] [healthcheck] service [kube-apiserver] on host [172.16.120.191] is healthy
INFO[0019] [controlplane] Successfully started [rke-log-linker] container on host [172.16.120.191]
INFO[0019] [remove/rke-log-linker] Successfully removed container on host [172.16.120.191]
INFO[0019] [healthcheck] Start Healthcheck on service [kube-controller-manager] on host [172.16.120.191]
INFO[0019] [healthcheck] service [kube-controller-manager] on host [172.16.120.191] is healthy
INFO[0019] [controlplane] Successfully started [rke-log-linker] container on host [172.16.120.191]
INFO[0019] [remove/rke-log-linker] Successfully removed container on host [172.16.120.191]
INFO[0019] [healthcheck] Start Healthcheck on service [kube-scheduler] on host [172.16.120.191]
INFO[0019] [healthcheck] service [kube-scheduler] on host [172.16.120.191] is healthy
INFO[0020] [controlplane] Successfully started [rke-log-linker] container on host [172.16.120.191]
INFO[0020] [remove/rke-log-linker] Successfully removed container on host [172.16.120.191]
INFO[0020] [controlplane] Successfully started Controller Plane..
INFO[0020] [authz] Creating rke-job-deployer ServiceAccount
INFO[0022] [authz] rke-job-deployer ServiceAccount created successfully
INFO[0022] [authz] Creating system:node ClusterRoleBinding
INFO[0022] [authz] system:node ClusterRoleBinding created successfully
INFO[0022] [certificates] Save kubernetes certificates as secrets
INFO[0024] [certificates] Successfully saved certificates as kubernetes secret [k8s-certs]
INFO[0024] [state] Saving cluster state to Kubernetes   
INFO[0024] [state] Successfully Saved cluster state to Kubernetes ConfigMap: cluster-state
INFO[0024] [worker] Building up Worker Plane..          
INFO[0024] [remove/service-sidekick] Successfully removed container on host [172.16.120.191]
INFO[0025] [worker] Successfully started [rke-log-linker] container on host [172.16.120.193]
INFO[0025] [remove/rke-log-linker] Successfully removed container on host [172.16.120.193]
INFO[0025] [remove/service-sidekick] Successfully removed container on host [172.16.120.193]
INFO[0025] [worker] Successfully updated [kubelet] container on host [172.16.120.191]
INFO[0025] [worker] Successfully started [rke-log-linker] container on host [172.16.120.192]
INFO[0025] [healthcheck] Start Healthcheck on service [kubelet] on host [172.16.120.191]
INFO[0025] [remove/rke-log-linker] Successfully removed container on host [172.16.120.192]
INFO[0025] [remove/service-sidekick] Successfully removed container on host [172.16.120.192]
INFO[0025] [worker] Successfully updated [kubelet] container on host [172.16.120.193]
INFO[0025] [healthcheck] Start Healthcheck on service [kubelet] on host [172.16.120.193]
INFO[0025] [worker] Successfully updated [kubelet] container on host [172.16.120.192]
INFO[0025] [healthcheck] Start Healthcheck on service [kubelet] on host [172.16.120.192]
INFO[0030] [healthcheck] service [kubelet] on host [172.16.120.191] is healthy
INFO[0030] [healthcheck] service [kubelet] on host [172.16.120.193] is healthy
INFO[0031] [healthcheck] service [kubelet] on host [172.16.120.192] is healthy
INFO[0032] [worker] Successfully started [rke-log-linker] container on host [172.16.120.193]
INFO[0032] [worker] Successfully started [rke-log-linker] container on host [172.16.120.191]
INFO[0032] [worker] Successfully started [rke-log-linker] container on host [172.16.120.192]
INFO[0032] [remove/rke-log-linker] Successfully removed container on host [172.16.120.193]
INFO[0033] [remove/rke-log-linker] Successfully removed container on host [172.16.120.192]
INFO[0033] [remove/rke-log-linker] Successfully removed container on host [172.16.120.191]
INFO[0033] [worker] Successfully started [kube-proxy] container on host [172.16.120.191]
INFO[0033] [healthcheck] Start Healthcheck on service [kube-proxy] on host [172.16.120.191]
INFO[0038] [healthcheck] service [kube-proxy] on host [172.16.120.191] is healthy
INFO[0038] [worker] Successfully started [rke-log-linker] container on host [172.16.120.191]
INFO[0038] [remove/rke-log-linker] Successfully removed container on host [172.16.120.191]
INFO[0043] [worker] Successfully updated [kube-proxy] container on host [172.16.120.193]
INFO[0043] [healthcheck] Start Healthcheck on service [kube-proxy] on host [172.16.120.193]
INFO[0043] [worker] Successfully updated [kube-proxy] container on host [172.16.120.192]
INFO[0043] [healthcheck] Start Healthcheck on service [kube-proxy] on host [172.16.120.192]
INFO[0048] [healthcheck] service [kube-proxy] on host [172.16.120.193] is healthy
INFO[0048] [healthcheck] service [kube-proxy] on host [172.16.120.192] is healthy
INFO[0048] [worker] Successfully started [rke-log-linker] container on host [172.16.120.193]
INFO[0048] [remove/rke-log-linker] Successfully removed container on host [172.16.120.193]
INFO[0048] [worker] Successfully started [rke-log-linker] container on host [172.16.120.192]
INFO[0048] [remove/rke-log-linker] Successfully removed container on host [172.16.120.192]
INFO[0048] [worker] Successfully started Worker Plane..
INFO[0048] [sync] Syncing nodes Labels and Taints       
INFO[0050] [sync] Successfully synced nodes Labels and Taints
INFO[0050] [network] Setting up network plugin: canal   
INFO[0050] [addons] Saving addon ConfigMap to Kubernetes
INFO[0050] [addons] Successfully Saved addon to Kubernetes ConfigMap: rke-network-plugin
INFO[0050] [addons] Executing deploy job..              
INFO[0060] [addons] Setting up KubeDNS                  
INFO[0060] [addons] Saving addon ConfigMap to Kubernetes
INFO[0060] [addons] Successfully Saved addon to Kubernetes ConfigMap: rke-kubedns-addon
INFO[0060] [addons] Executing deploy job..              
INFO[0065] [addons] KubeDNS deployed successfully..     
INFO[0065] [addons] Setting up Metrics Server           
INFO[0065] [addons] Saving addon ConfigMap to Kubernetes
INFO[0065] [addons] Successfully Saved addon to Kubernetes ConfigMap: rke-metrics-addon
INFO[0065] [addons] Executing deploy job..              
INFO[0070] [addons] KubeDNS deployed successfully..     
INFO[0070] [ingress] Setting up nginx ingress controller
INFO[0070] [addons] Saving addon ConfigMap to Kubernetes
INFO[0070] [addons] Successfully Saved addon to Kubernetes ConfigMap: rke-ingress-controller
INFO[0070] [addons] Executing deploy job..              
INFO[0075] [ingress] ingress controller nginx is successfully deployed
INFO[0075] [addons] Setting up user addons              
INFO[0075] [addons] no user addons defined              
INFO[0075] Finished building Kubernetes cluster successfully
```
看到Finished building Kubernetes cluster successfully 表示集群安装成功。

# 7 连接到集群
[https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl)  下载安装包kubectl。
```bash
curl -LO https://centos-k8s.oss-cn-hangzhou.aliyuncs.com/kubectl/v1.11.0/kubectl
chmod a+x kubectl
mv kubectl /usr/bin
```
RKE会在配置文件所在的目录下部署一个本地文件，该文件中包含kube配置信息以连接到新生成的群集。默认情况下，kube配置文件被称为.kube\_config\_cluster.yml。将这个文件复制到你的本地~/.kube/config，就可以在本地使用kubectl了。
```
mkdir .kube
cp kube_config_cluster.yml .kube/config
```
> 需要注意的是，部署的本地kube配置名称是和集群配置文件相关的。例如，如果您使用名为mycluster.yml的配置文件，则本地kube配置将被命名为.kube\_config\_mycluster.yml。

# 8 查看集群信息
```
kubectl clusterinfo
```
显示集群信息：
```
Kubernetes master is running at https://172.16.120.191:6443
KubeDNS is running at https://172.16.120.191:6443/api/v1/namespaces/kube-system/services/kube-dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

# 9 部署dashboard
下载dashboard脚本
```bash
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.0/src/deploy/recommended/kubernetes-dashboard.yaml
```

将镜像修改为 [registry.cn-hangzhou.aliyuncs.com/kubernete/kubernetes-dashboard-amd64:v1.10.0](http://registry.cn-hangzhou.aliyuncs.com/kubernete/kubernetes-dashboard-amd64:v1.10.0)

修改service配置，新增nodePort配置：
```plain
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
```

```bash
kubectl create -f ./kubernetes-dashboard.yaml
```

给dashboard设置admin权限：
```bash
wget https://raw.githubusercontent.com/gh-Devin/kubernetes-dashboard/master/kubernetes-dashboard-admin.rbac.yaml

kubectl create -f ./kubernetes-dashboard-admin.rbac.yaml
```

查询集群IP
```
kubectl get svc -n kube-system -o wide
```
显示结果：
```
NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE       SELECTOR
kube-dns               ClusterIP   10.43.0.10     <none>        53/UDP,53/TCP   1h        k8s-app=kube-dns
kubernetes-dashboard   ClusterIP   10.43.18.244   <none>        443/TCP         10m       k8s-app=kubernetes-dashboard
metrics-server         ClusterIP   10.43.17.12    <none>        443/TCP         1h        k8s-app=metrics-server
```
kubernetes dashboard的集群IP为10.43.18.244,登录集群任意一台机器，在浏览器输入地址打开dashboard：[https://10.43.18.244](https://10.43.18.244) ，或者在任意内网机器使用 https://172.16.120.191:30001 访问dashboard。

获取dashboard的token值
```bash
kubectl get secret -n kube-system|grep kubernetes-dashboard
```
显示结果：
```bash
kubernetes-dashboard-admin-token-vqmnq           kubernetes.io/service-account-token   3         12m
```
查看token:
```bash
kubectl describe secret kubernetes-dashboard-admin-token-vqmnq -n kube-system
```
在显示内容中找到token，复制后，在dashboard中使用token登录。



# 参考

RKE安装培训视频：
[http://www.itdks.com/liveevent/zs/8343/e8a836ead98d416a82abc670e29eaf4e](http://www.itdks.com/liveevent/zs/8343/e8a836ead98d416a82abc670e29eaf4e)

RKE安装文档：
[https://www.cnrancher.com/an-introduction-to-rke/](https://www.cnrancher.com/an-introduction-to-rke/)

[https://rancher.com/docs/rke/v0.1.x/en/installation/](https://rancher.com/docs/rke/v0.1.x/en/installation/)

rke 部署 k8s 实战：
[https://blog.csdn.net/godservant/article/details/80895970](https://blog.csdn.net/godservant/article/details/80895970)

rke安装指南：
[https://segmentfault.com/a/1190000012288926](https://segmentfault.com/a/1190000012288926)

使用Rancher的RKE部署Kubernetes要点:
[http://blog.51cto.com/10321203/2071396](http://blog.51cto.com/10321203/2071396)
