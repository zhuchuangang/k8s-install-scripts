1~2台centos 7虚机

| 虚机名称        | IP            |
| ------------- |:-------------:|
| master        | 172.16.120.191|
| node01        | 172.16.120.192|


下载kubeadm.sh脚本，设置脚本有可执行权限
```bash
chmod a+x kubeadm.sh
```

在主节点执行下面的命令：
```bash
sh kubeadm.sh --node-type master --master-address 172.16.120.191
```

在从节点执行下面的命令：
```bash
sh kubeadm.sh --node-type node --master-address 172.16.120.191
```

安装重置：
```bash
sh kubeadm.sh reset
```
