rancher上部署heapster，如果直接使用kubernetes的默认脚本，会出现下面的错误：
```bash
https://kubernetes.default/api/v1/nodes: x509: certificate is valid for 10.43.0.1, kubernetes.default.svc.cluster.local, kubernetes, kubernetes.kubernetes, kubernetes.kubernetes.rancher.internal, not kubernetes.default
```
出现上面错误的原因是rancher生成证书的时候，没有添加kubernetes.default这个dns名称，选取以上任何一种都是可以的。

下面需要修改heapster的source参数，内容为 --source=kubernetes:https://kubernetes.kubernetes:6443?inClusterConfig=true&insecure=true，详细配置如下：
```bash
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: heapster
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: heapster
    spec:
      serviceAccountName: heapster
      containers:
      - name: heapster
        image: registry.cn-hangzhou.aliyuncs.com/google-containers/heapster-amd64:v1.4.2
        imagePullPolicy: IfNotPresent
        command:
        - /heapster
        - --source=kubernetes:https://kubernetes.kubernetes:6443?inClusterConfig=true&insecure=true
        - --sink=influxdb:http://monitoring-influxdb.kube-system.svc:8086
```

由于rancher对kubernetes的接口重新进行了封装，rancher上是无法通过apiserver的方式访问grafana的，所以我们把grafana通过nodePort的方式对外提供服务。

安装完成后，如果kubernetes dashboard中没有显示cpu和内存信息，重新安装dashboard即可。

参考：
kubernetes安装heapster、influxdb及grafana:
http://www.jianshu.com/p/60069089c981
