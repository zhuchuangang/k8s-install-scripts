# 1 环境

1~2台centos 7虚机

| 虚机名称        | IP            |
| ------------- |:-------------:|
| master        | 172.16.120.151|
| node01        | 172.16.120.152|

# 2 master节点安装
```bash
sh kubeadm-master.sh 172.16.120.151
```

# 3 node节点安装
```bash
sh kubeadm-node.sh 172.16.120.151
```
