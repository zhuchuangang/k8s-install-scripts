# 1 rancher server单节点 

**rancher v1.6.11支持kubernetes 1.8版本**

master节点安装完成后，通过8080端口访问rancher管理界面。

master节点执行下面的命令，master节点除了安装docker环境，还安装rancher server：
```bash
sh setup.sh master
```

slave节点执行下面命令，slave节点只安装docker环境：
```bash
sh setup.sh slave
```

# 2 rancher server单节点外部数据库部署

master节点执行下面的命令，master节点除了安装docker环境，还安装mariadb和rancher server：
```bash
sh setup-db.sh master 192.168.0.1
```
> 注意：192.168.0.1为master节点IP

slave节点执行下面命令，slave节点只安装docker环境：
```bash
sh setup-db.sh slave
```

# 3 rancher HA
rancher高可用至少要3个节点。
```bash
sh setup-db.sh master 192.168.0.1 192.168.0.10
```
192.168.0.1为当前节点IP
192.168.0.10为mysql数据库IP

# 4 rancher HA模式添加rancher主节点作为host需要配置负载均衡
使用setup-db.sh构建一个rancher集群，如果需要将rancher主节点添加为host，需要在每个主节点在部署一个nginx用于负载3个主节点，rancher界面添加每个rancher节点之前需要修改主机注册URL，该URL为该主机的IP加本机运行的nginx端口号。
删除添加的主节点时不要点击疏散该节点，这样会导致rancher-server被停止。

添加子节点也可以使用上面的方式，如果在阿里云，可以使用SLB服务对三个主节点做内网负载，但是SLB的地址服务用来添加rancher主节点作为host.
# 5 rancher上部署kubernetes

master节点安装完成后，添加节点时主机连接Rancher API的Base URL请使用内网地址，参考【原生加速中国区Kubernetes安装】https://www.cnrancher.com/kubernetes-installation/ 安装kubernetes。

rancher提供关闭自动安装kubernetes addones的选项，dashboard、dns等组件需要自行安装。

从rancher页面生成kubeconfig配置文件，保存到master节点~/.kube/config文件中，下载kubectl文件到master节点/usr/bin目录，设置文件为可执行文件 chmoc a+x /usr/bin/kubectl。kubectl已经上传到百度网盘 https://pan.baidu.com/s/1jH9dsF0 

参考：

【原生加速中国区Kubernetes安装】https://www.cnrancher.com/kubernetes-installation/

【Installing Rancher Server】http://rancher.com/docs/rancher/latest/en/installing-rancher/installing-server/#multi-nodes

# 6 安装重置
先在rancher界面删除所有节点，再在每个节点执行reset.sh脚步。

# 7 主节点不做pod调度
```bash
kubectl label nodes k8s-master01 node-role.kubernetes.io/master=
kubectl taint nodes k8s-master01 node-role.kubernetes.io/master=:NoSchedule
```

参考：
【rancher server的安装】http://rancher.com/docs/rancher/v1.6/zh/installing-rancher/installing-server/

【rancher server的升级】http://rancher.com/docs/rancher/v1.6/zh/upgrading/
