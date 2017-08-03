[TOC]

# 搭建docker私有仓库harbor



# 1 安装docker-compose
使用docker-compose安装harbor。

安装epel。epel是centos等衍生发行版，用来弥补centos内容更新有时比较滞后或是一些扩展的源没有。
```bash
yum -y install epel-release
```

安装pip。pip 是一个Python包管理工具。
```bash
yum install -y python-pip
```

对安装好的pip进行升级。
```bash
pip install --upgrade pip
```

升级python。
```bash
yum upgrade -y python*
```

centos 7下使用pip安装docker-compse。
```bash
pip install docker-compose
```

验证：
```bash
docker-compose --version
```

# 2 使用docker compose安装harbor
下载在线安装包harbor-online-installer-v1.1.2.tgz
```bash
wget https://github.com/vmware/harbor/releases/download/v1.1.2/harbor-online-installer-v1.1.2.tgz
```

解压
```bash
tar xvf harbor-online-installer-v1.1.2.tgz
```

配置
```bash
vi harbor/barbor.cfg
```
修改内容如下：
```bash
hostname=192.168.10.10
```
hostname设置运行主机的IP，或者是域名。其他配置可以进行更改，或使用默认配置，登录页面后部分参数可在页面修改。


安装
```bash
sh harbor/install.sh
```
安装成功后，通过之前在harbor.cfg配置的hostname即可以访问到前端了，默认登陆用户名密码是admin/Harbor12345

# 3 参考

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7

http://blog.csdn.net/yulei_qq/article/details/52984334

http://blog.csdn.net/yulei_qq/article/details/52985550
