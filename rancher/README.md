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


参考：

【原生加速中国区Kubernetes安装】https://www.cnrancher.com/kubernetes-installation/

【Installing Rancher Server】http://rancher.com/docs/rancher/latest/en/installing-rancher/installing-server/#multi-nodes

