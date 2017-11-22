kubernetes v1.8.4阿里云yum源没有同步，现在已经分享到baidu网盘https://pan.baidu.com/s/1c1VAeli,
下载kubectl、kubeadm、kubelet、kubernetes-cni、socat。和kubeadm-master.sh或者kubeadm-node.sh脚本放在同一目录下。

# 1 环境

1~2台centos 7虚机

| 虚机名称        | IP            |
| ------------- |:-------------:|
| master        | 172.16.120.151|
| node01        | 172.16.120.152|


修改主机名
```bash
hostnamectl --static set-hostname  master
hostnamectl --static set-hostname  node01
```

kubeadm-master.sh和kubeadm-node.sh脚本采用kubeadm进行安装，采用国内镜像，安装简单快速。

```bash
chmod a+x kubeadm-master.sh
chmod a+x kubeadm-node.sh
```


# 2 master节点安装
```bash
sh kubeadm.sh 172.16.120.151 master
```

# 3 node节点安装
```bash
sh kubeadm.sh 172.16.120.151 slave
```

# 4.重置脚本
kubeadm-reset.sh为重置脚本


参考：https://www.kubernetes.org.cn/2906.html
