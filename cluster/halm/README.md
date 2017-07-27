# 1 halm
Helm是用来管理Kubernetes预先配置的Kubernetes资源的包。

# 2 安装和初始化
```
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.5.1-linux-amd64.tar.gz
rm -rf linux-amd64
tar zxvf helm-v2.5.1-linux-amd64.tar.gz
rm -f /opt/kubernetes/bin/helm
cp linux-amd64/helm /opt/kubernetes/bin/helm
cd ~
rm -rf ~/.helm
helm init --tiller-image=sapcc/tiller:v2.5.1 --kube-context my-context
```
# 3 验证
helm客户端要能与运行在k8s容器里的tiller正常通信

```
helm version
helm search
```

# 4 添加fabric8库
```
helm repo add fabric8 https://fabric8.io/helm
helm search fabric8
```


# 5.其他
删除tiller
```
kubectl --namespace=kube-system delete deployment tiller-deploy
```

参考：http://blog.csdn.net/wzp1986/article/details/71910335?utm_source=itdadao&utm_medium=referral

