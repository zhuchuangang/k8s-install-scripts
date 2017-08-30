脚步已经在kubespray 2.1.2版本测试通过。

在需要收集日志的节点上打上beta.kubernetes.io/fluentd-ds-ready=true的标签。
```bash
kubectl label nodes <node-name> beta.kubernetes.io/fluentd-ds-ready=true
```

参考：
https://my.oschina.net/newlife111/blog/714574


http://tonybai.com/2017/03/03/implement-kubernetes-cluster-level-logging-with-fluentd-and-elasticsearch-stack/
