在master节点使用kubectl proxy命令就可以使API server监听在本地的8001端口上：
```bash
kubectl proxy --address='0.0.0.0'  --accept-hosts='^*$'
```
后台执行：
```bash
nohup kubectl proxy --address='0.0.0.0'  --accept-hosts='^*$' >/dev/null 2>&1 &
```

在浏览器访问master节点：http://master-ip:8001/ui


参考：http://blog.csdn.net/cuipengchong/article/details/72459299

