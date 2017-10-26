# 构建镜像
```bash
cd docker
docker build -t szss/kubernetes-rabbitmq-autocluster:3.6.12 .
```
# 推送到阿里云
```bash
docker tag szss/kubernetes-rabbitmq-autocluster:3.6.12 registry.cn-hangzhou.aliyuncs.com/szss/kubernetes-rabbitmq-autocluster:3.6.12
docker push registry.cn-hangzhou.aliyuncs.com/szss/kubernetes-rabbitmq-autocluster:3.6.12
```

部署：
```bash
echo $(openssl rand -base64 32) > erlang.cookie
kubectl -n default create secret generic erlang.cookie --from-file=erlang.cookie
kubectl create -f ./
```
验证：

```bash
FIRST_POD=$(kubectl get pods -n cat -l 'app=rabbitmq' -o jsonpath='{.items[0].metadata.name }')
kubectl -n default exec -ti $FIRST_POD rabbitmqctl cluster_status
```

参考：
https://github.com/kuberstack/kubernetes-rabbitmq-autocluster

https://segmentfault.com/a/1190000009733119
