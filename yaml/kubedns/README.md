下载kubernetes安装包https://github.com/kubernetes/kubernetes/releases/download/v1.6.7/kubernetes.tar.gz，
在kubernetes/cluster/addons/dns目录下有kubedns的安装脚本。

# 1.kubedns-cm.yaml和kubedns-sa.yaml
kubedns-cm.yaml和kubedns-sa.yaml不需要进行修改,直接使用。

# 2.kubedns-svc.yaml
kubedns-svc.yaml有三种类型的模板文件，我们使用kubedns-svc.yaml.sed文件来生成kubedns-svc.yaml文件，替换$DNS_SERVER_IP为指定IP，我们这里使用10.0.0.10。
```
cp kubedns-svc.yaml.sed kubedns-svc.yaml
sed -i 's/$DNS_SERVER_IP/10.0.0.10/g' kubedns-svc.yaml
```

# 3.kubedns-controller.yaml
kubedns-controller.yaml有三种类型的模板文件，我们使用kubedns-controller.yaml.sed文件来生成kubedns-controller.yaml文件，替换$DNS_DOMAIN为cluster.local.。
```
cp kubedns-controller.yaml.sed kubedns-controller.yaml
sed -i 's/$DNS_DOMAIN/cluster.local./g' kubedns-controller.yaml
```
由于gcr.io进行下载问题，对kubedns-controller.yaml使用的docker镜像进行了替换，
- gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4镜像改为registry.cn-hangzhou.aliyuncs.com/szss_k8s/k8s-dns-kube-dns-amd64:1.14.5
- gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4镜像改为registry.cn-hangzhou.aliyuncs.com/szss_k8s/k8s-dns-dnsmasq-nanny-amd64:1.14.5
- gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4镜像改为registry.cn-hangzhou.aliyuncs.com/szss_k8s/k8s-dns-sidecar-amd64:1.14.5


# 4.启动kubedns服务
```
kubectl create -f kubedns-cm.yaml
kubectl create -f kubedns-sa.yaml
kubectl create -f kubedns-svc.yaml
kubectl create -f kubedns-controller.yaml
```
>注意：需要配置kubelet的启动参数--cluster-dns=10.0.0.10  --cluster-domain=cluster.local

# 5.验证
创建pod,pod-busybox.yaml
```
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - image: busybox
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
    name: busybox
  restartPolicy: Always
```

登录busybox容器内部
```
kubectl exec -it busybox -- /bin/sh
```

输入命令认证
```
nslookup kubernetes
```
输出结果为：
```
Server:    10.0.0.10
Address 1: 10.0.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local
```
