# kibana和elasticsearch访问地址
由于rancher对kubernetes的接口重新进行了封装，rancher上是无法通过apiserver的方式访问kibana和elasticsearch的，所以我们把kibana和elasticsearch通过nodePort的方式对外提供服务。

# 开启节点日志收集
脚步已经在kubespray 2.1.2版本测试通过。

在需要收集日志的节点上打上beta.kubernetes.io/fluentd-ds-ready=true的标签。
```bash
kubectl label nodes <node-name> beta.kubernetes.io/fluentd-ds-ready=true
```
# 注意事项
fluentd的sepc.template.spec.volumes.hostPath配置的路径必须和sepc.template.spec.containers.volumeMounts.mountPath配置的路径一致。更多内容请参考：https://github.com/kubernetes/minikube/issues/876


参考：
https://my.oschina.net/newlife111/blog/714574


http://tonybai.com/2017/03/03/implement-kubernetes-cluster-level-logging-with-fluentd-and-elasticsearch-stack/
