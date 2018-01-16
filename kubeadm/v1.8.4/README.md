kubernetes v1.8.4阿里云yum源没有同步，现在已经分享到baidu网盘https://pan.baidu.com/s/1c1VAeli,
下载kubectl、kubeadm、kubelet、kubernetes-cni、socat。和kubeadm.sh或者kubeadm-reset.sh脚本放在同一目录下。

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
chmod a+x kubeadm.sh
chmod a+x kubeadm-reset.sh
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

# 5.静态pod
kubeadm安装的所有组件都是以静态pod的形式通过kubelet启动的。
有关静态pod的内容请查阅https://kubernetes.io/cn/docs/tasks/administer-cluster/static-pod/

# 6.异常处理
如果机器重启之后，集群启动失败，kubelet启动报错，可使用
```bash
cat /var/log/messages
```
命令查看是否是因为swap没有关闭，造成启动失败。如果是因为swap没有关闭，可注释/etc/fstab中和swap相关的配置，再重启主机，集群可正常启动。



参考：

https://www.kubernetes.org.cn/2906.html


https://blog.frognew.com/2017/09/kubeadm-install-kubernetes-1.8.html
