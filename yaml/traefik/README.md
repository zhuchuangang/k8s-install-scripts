# 1 权限
kubernetes 1.6之后有rbac的权限控制，需要先执行traefik-rbac.yaml文件。

# 2 部署Daemon Set
traefik在官方文档 https://docs.traefik.io/user-guide/kubernetes/ 中有2中部署方式，分别是daemon set和deployment。这里我们选择daemon set。
部署脚本是traefik-ds.yaml文件中。

***traefik镜像默认会绑定主机8080端口，所以master节点上如果部署了traefik会发生端口冲突。在traefik-ds.yaml中- --web.address=:8081配置修改默认绑定的8080端口，避免端口冲突。***

# 3 部署ingress
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-ingress
spec:
  rules:
  - host: registry.test.com
    http:
      paths:
      - path: /registry-peer01
        backend:
          serviceName: registry-peer01
          servicePort: 8761
      - path: /registry-peer02
        backend:
          serviceName: registry-peer02
          servicePort: 8761
      - path: /registry-peer03
        backend:
          serviceName: registry-peer03
          servicePort: 8761
```
我们绑定registry.test.com，用来访问3个服务，后端服务只需要指定服务名和服务端口号即可。


如果域名是已经注册过的，那么域名需要映射到traefik运行的任何一个节点的外面IP。

如果没有注册的域名，并且需要外网访问，那么在需要在客户端上配置主机名映射到traefik运行的任何一个节点的外网IP。配置方法如下：
```bash
echo "10.10.0.10 registry.test.com" | sudo tee -a /etc/hosts
```

如果需要内网访问，那么在需要内网客户端机器上配置主机名映射到traefik运行的任何一个节点的内网IP。配置方法如下：
```bash
echo "192.168.0.10 registry.test.com" | sudo tee -a /etc/hosts
```

# 4 部署UI
traefik的控制台web ui外部映射执行ui.yaml配置文件即可。


官方文档：
https://docs.traefik.io/user-guide/kubernetes/

参考：
https://mritd.me/2016/12/06/try-traefik-on-kubernetes/

https证书配置：
https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948
