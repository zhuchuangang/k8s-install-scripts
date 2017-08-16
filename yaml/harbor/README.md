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
下载在线安装包harbor-online-installer-v1.1.2.tgz：
```bash
wget https://github.com/vmware/harbor/releases/download/v1.1.2/harbor-online-installer-v1.1.2.tgz
```

解压：
```bash
tar xvf harbor-online-installer-v1.1.2.tgz
```

docker-compose.yaml文件nginx端口号修改：
```yaml
  proxy:
    image: vmware/nginx:1.11.5-patched
    container_name: nginx
    restart: always
    volumes:
      - ./common/config/nginx:/etc/nginx:z
    networks:
      - harbor
    ports:
      - 80:80
```
如将80端端口修改8080，配置如下：
```yaml
  proxy:
    image: vmware/nginx:1.11.5-patched
    container_name: nginx
    restart: always
    volumes:
      - ./common/config/nginx:/etc/nginx:z
    networks:
      - harbor
    ports:
      - 8080:80
```


配置主机名称：
```bash
vi harbor/barbor.cfg
```
修改内容如下：
```bash
hostname=172.16.120.153:8080
```
hostname设置运行主机的IP，或者是域名。其他配置可以进行更改，或使用默认配置，登录页面后部分参数可在页面修改。

安装:
```bash
sh harbor/install.sh
```
安装成功后，通过之前在harbor.cfg配置的hostname即可以访问到前端了，默认登陆用户名密码是admin/Harbor12345


# 3 客户端配置
因为docker客户端默认采用https访问docker registry，而我们默认安装的Harbor并没有启用https。 可以在Docker客户端所在的机器修改/etc/docker/daemon.json：
```json
{
    "insecure-registries": ["172.16.120.153:8080"]
}
```
配置非安全的docker registry。

# 4 客户端推送镜像

```bash
docker login -u admin -p Harbor12345 172.16.120.153:8090
Login Succeeded

docker pull nginx
docker tag nginx 172.16.120.153:8080/library/nginx

docker push 172.16.120.153:8080/library/nginx
```

# 5 配置https访问
## 5.1 SAN 证书扩展域名配置
默认的OpenSSL生成的签名请求只适用于生成时填写的域名，即Common Name填的是哪个域名，证书就只能应用于哪个域名，
但是一般内网都是以IP方式部署，所以需要添加SAN(Subject Alternative Name)扩展信息，以支持多域名和IP。

完整的配置文件如下：
```
[ req ]
distinguished_name      = req_distinguished_name
req_extensions = v3_req # The extensions to add to a certificate request
[ v3_req ]

# Extensions to add to a certificate request

basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
IP.1=172.16.120.153
DNS.1=*.3songshu.com
```

## 5.2 创建CA及自签名
```bash
rm -rf ~/crt
mkdir ~/crt
# 创建私钥
openssl genrsa -out ~/crt/ca.key 2048
openssl req -x509 -new -nodes -key ~/crt/ca.key -days 10000 -out ~/crt/ca.crt -subj "/CN=harbor"
# 生成带有 SAN 的证书请求
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ~/crt/server.key -out ~/crt/server.csr -subj "/C=CN/ST=Anhui/L=Wuhu/O=organization/OU=IT/CN=harbor/emailAddress=example@example.com"
# 签名带有 SAN 的证书
openssl x509 -req -in ~/crt/server.csr -CA ~/crt/ca.crt -CAkey ~/crt/ca.key -CAcreateserial -out ~/crt/server.crt -days 365 -extensions v3_req -extfile openssl.cnf
```
根据harbor/barbor.cfg中有关证书的内容，将证书复制到server.crt和server.key复制到/data/cert文件夹下：
```bash
mkdir -p /data/cert
cp ~/crt/{server.crt,server.key} /data/cert
```

## 5.3 配置证书
```bash
vi harbor/barbor.cfg
```

```
# 访问UI与token/notification服务的协议，默认为http。
# 如果在nginx中开启了ssl，可以设置为https
ui_url_protocol = https
```
重新安装。

## 5.4 配置docker客户端
如果使用的自签证书，需要配置docker客户端。
```bash
# 如果如下目录不存在，请创建，如果有域名请按此格式依次创建
mkdir -p /etc/docker/certs.d/172.16.120.153:8080
# mkdir -p /etc/docker/certs.d/[IP2]
# mkdir -p /etc/docker/certs.d/[example1.com] 
# 如果端口为443，则不需要指定。如果为自定义端口，请指定端口
# /etc/docker/certs.d/yourdomain.com:port

# 将ca根证书依次复制到上述创建的目录中
cp ca.crt /etc/docker/certs.d/172.16.120.153:8080/
```
重启docker，到此，harbor https已经可以使用。

# 4 参考
http://blog.frognew.com/2017/06/install-harbor.html

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7

http://blog.csdn.net/yulei_qq/article/details/52984334

http://blog.csdn.net/yulei_qq/article/details/52985550

http://blog.csdn.net/shenshouer/article/details/53390581

https://github.com/vmware/harbor/issues/2452
