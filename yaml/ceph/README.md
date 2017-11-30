# ceph部署环境

|主机名称|内网IP|
|---|---|
|node01|192.168.0.1|
|node02|192.168.0.2|
|node03|192.168.0.3|

时间同步,如果不设置可能会造成集群时间偏移，导致集群健康状况为warn。
```bash
systemctl enable chronyd --now 
chronyc waitsync
```
> 注意：如果不进行时间同步，后续会出现"Monitor clock skew detected"异常

虚机开启selinux：
```bash
vi /etc/selinux/config
```
设置：
```bash
SELINUX=enforcing
```

设置目录权限：
```bash
mkdir -p /etc/ceph
mkdir -p /var/lib/ceph
chcon -Rt svirt_sandbox_file_t /etc/ceph
chcon -Rt svirt_sandbox_file_t /var/lib/ceph
```

如果系统只有一个数据盘，并且数据盘已经分区，需要对数据盘进行分区删除，并进行格式化处理。
格式化命令如下：
```bash
mkfs.xfs /dev/vdb
```
> 推荐部署生产系统时使用xfs文件系统，如果使用ext4,需要添加额外配置。具体内容参考：http://docs.ceph.org.cn/rados/configuration/filesystem-recommendations/

下面我们采用docker进行安装，ceph/daemon的版本为tag-build-master-jewel-centos-7。

# node01启动monitor
启动monitor：
```bash
docker run -d --name=mon --net=host \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph:/var/lib/ceph \
-e MON_IP=192.168.0.1 \
-e CEPH_PUBLIC_NETWORK=192.168.0.0/24 \
ceph/daemon:tag-build-master-jewel-centos-7 mon
```
可用选项列表：
- MON_IP：是你运行Docker的主机IP地址
- MON_NAME：是你的monitor名称（默认：$(hostname)）
- CEPH_PUBLIC_NETWORK：是你运行Docker的主机CIDR
- CEPH_CLUSTER_NETWORK：是你运行Docker的主机的第二块网卡的CIDR，用于OSD复制流量


查看ceph状态：
```bash
docker exec b3cc55582498 ceph -s
```
执行结果：
```bash
# docker exec b3cc55582498 ceph -s
    cluster 05527e2d-5d80-4c85-8d35-7dcddafa197e
     health HEALTH_ERR
            no osds
     monmap e1: 1 mons at {iZbp1isotv99f45cg37lxgZ=192.168.0.1:6789/0}
            election epoch 3, quorum 0 iZbp1isotv99f45cg37lxgZ
     osdmap e1: 0 osds: 0 up, 0 in
            flags sortbitwise,require_jewel_osds
      pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
            0 kB used, 0 kB / 0 kB avail
                  64 creating
```

# 拷贝node01配置文件到其他机器
```bash
scp -r /etc/ceph/ceph* root@192.168.0.2:/etc/ceph/
scp -r /var/lib/ceph/bootstrap-* root@192.168.0.2:/var/lib/ceph/

scp -r /etc/ceph/ceph* root@192.168.0.3:/etc/ceph/
scp -r /var/lib/ceph/bootstrap-* root@192.168.0.3:/var/lib/ceph/
```

# 其他节点启动monitor
在node02上执行：
```bash
docker run -d --name=mon --net=host \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph:/var/lib/ceph \
-e MON_IP=192.168.0.2 \
-e CEPH_PUBLIC_NETWORK=192.168.0.0/24 \
ceph/daemon:tag-build-master-jewel-centos-7 mon
```
在node03上执行：
```bash
docker run -d --name=mon --net=host \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph:/var/lib/ceph \
-e MON_IP=192.168.0.3 \
-e CEPH_PUBLIC_NETWORK=192.168.0.0/24 \
ceph/daemon:tag-build-master-jewel-centos-7 mon
```

查看ceph状态：
```bash
docker exec b3cc55582498 ceph -s
```

执行结果：
```bash
#docker exec b3cc55582498 ceph -s
    cluster 230a93b6-3876-4d69-bffe-c0c054c49653
     health HEALTH_ERR
            no osds
     monmap e3: 3 mons at {iZbp1isotv99f45cg37lxfZ=192.168.0.1:6789/0,iZbp1isotv99f45cg37lxiZ=192.168.0.2:6789/0,iZbp1isotv99f45cg37lxjZ=192.168.0.3:6789/0}
            election epoch 6, quorum 0,1,2 iZbp1isotv99f45cg37lxjZ,iZbp1isotv99f45cg37lxfZ,iZbp1isotv99f45cg37lxiZ
     osdmap e1: 0 osds: 0 up, 0 in
            flags sortbitwise,require_jewel_osds
      pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
            0 kB used, 0 kB / 0 kB avail
                  64 creating
```

# 在所有节点部署osd
````bash
docker run -d --name=osd1 --net=host \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-v /dev/:/dev/ --privileged=true \
-e OSD_FORCE_ZAP=1 \
-e OSD_DEVICE=/dev/vdb \
ceph/daemon:tag-build-master-jewel-centos-7 osd_ceph_disk
````
可选配置：
- OSD_DEVICE是OSD设备，如：/dev/sdb
- OSD_JOURNAL是用于存储OSD日志的设备，如：/dev/sdz
- HOSTNAME是运行OSD容器主机的主机名（默认：$(hostname)）
- **OSD_FORCE_ZAP将强制指定设备内容zapping（默认值：0，1是开启）**
- OSD_JOURNAL_SIZE是OSD日志大小（默认值：100）

> 注意：**OSD_FORCE_ZAP设置为1时，重启osd的docker容器，osd进程会重新创建一个新的osd。**

查看ceph状态：
```bash
docker exec b3cc55582498 ceph -s
```
执行结果：
```bash
# docker exec b3cc55582498 ceph -s
    cluster 230a93b6-3876-4d69-bffe-c0c054c49653
     health HEALTH_ERR
            37 pgs are stuck inactive for more than 300 seconds
            27 pgs degraded
            3 pgs peering
            37 pgs stuck inactive
            64 pgs stuck unclean
            27 pgs undersized
     monmap e3: 3 mons at {iZbp1isotv99f45cg37lxfZ=192.168.0.1:6789/0,iZbp1isotv99f45cg37lxiZ=192.168.0.2:6789/0,iZbp1isotv99f45cg37lxjZ=192.168.0.3:6789/0}
            election epoch 6, quorum 0,1,2 iZbp1isotv99f45cg37lxjZ,iZbp1isotv99f45cg37lxfZ,iZbp1isotv99f45cg37lxiZ
     osdmap e10: 3 osds: 3 up, 3 in
            flags sortbitwise,require_jewel_osds
      pgmap v11: 64 pgs, 1 pools, 0 bytes data, 0 objects
            35320 kB used, 699 GB / 699 GB avail
                  34 creating
                  27 active+undersized+degraded
                   3 creating+peering
```


# 在node01部署mds
```bash
docker run -d --name=mds --net=host \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-e CEPHFS_CREATE=1 \
ceph/daemon:tag-build-master-jewel-centos-7 mds

```

可用选项列表：
- MDS_NAME：是元数据服务的名称（默认：mds-$(hostname)）
- CEPHFS_CREATE：会为元数据服务创建一个文件系统（默认值：0，1是启用）
- CEPHFS_NAME：是元数据文件系统的名称（默认：cephfs）
- CEPHFS_DATA_POOL：是元数据服务的数据池名称（默认：cephfs_data）
- CEPHFS_DATA_POOL_PG：是数据池placement group的数量（默认值：8）
- CEPHFS_DATA_POOL：是元数据服务的元数据池名称（默认：cephfs_metadata）
- CEPHFS_METADATA_POOL_PG：是元数据池placement group的数量（默认值：8）



查看ceph状态：
```bash
docker exec b3cc55582498 ceph -s
```
执行结果：
```bash
# docker exec b3cc55582498 ceph -s
    cluster 230a93b6-3876-4d69-bffe-c0c054c49653
     health HEALTH_WARN
            4 pgs peering
     monmap e3: 3 mons at {iZbp1isotv99f45cg37lxfZ=10.135.204.114:6789/0,iZbp1isotv99f45cg37lxiZ=10.135.204.132:6789/0,iZbp1isotv99f45cg37lxjZ=10.135.204.107:6789/0}
            election epoch 6, quorum 0,1,2 iZbp1isotv99f45cg37lxjZ,iZbp1isotv99f45cg37lxfZ,iZbp1isotv99f45cg37lxiZ
      fsmap e4: 1/1/1 up {0=iZbp1isotv99f45cg37lxjZ=up:creating}
     osdmap e13: 3 osds: 3 up, 3 in
            flags sortbitwise,require_jewel_osds
      pgmap v20: 80 pgs, 3 pools, 0 bytes data, 0 objects
            100 MB used, 2098 GB / 2098 GB avail
                  64 active+clean
                  12 creating
                   4 creating+peering
```

# 在node01部署gateway
```bash
docker run -d --name=rgw -p 80:80 \
--restart=always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
ceph/daemon:tag-build-master-jewel-centos-7 rgw
```
可用选项列表：
- RGW_REMOTE_CGI：指定是否使用Rados Gateway嵌入的Web服务（默认值：0，1是不使用）
- RGW_REMOTE_CGI_HOST：指定运行CGI进程的远程主机
- RGW_REMOTE_CGI_PORT：运行CGI进程的远程主机端口
- RGW_CIVETWEB_PORT：是civetweb的监听端口（默认：80）
- RGW_NAME：是Rados Gateway实例名称（默认：$(hostname)）



查看ceph状态：
```bash
docker exec b3cc55582498 ceph -s
```
执行结果：
```bash
# docker exec b3cc55582498 ceph -s
    cluster 230a93b6-3876-4d69-bffe-c0c054c49653
     health HEALTH_OK
     monmap e3: 3 mons at {iZbp1isotv99f45cg37lxfZ=10.135.204.114:6789/0,iZbp1isotv99f45cg37lxiZ=10.135.204.132:6789/0,iZbp1isotv99f45cg37lxjZ=10.135.204.107:6789/0}
            election epoch 6, quorum 0,1,2 iZbp1isotv99f45cg37lxjZ,iZbp1isotv99f45cg37lxfZ,iZbp1isotv99f45cg37lxiZ
      fsmap e5: 1/1/1 up {0=iZbp1isotv99f45cg37lxjZ=up:active}
     osdmap e14: 3 osds: 3 up, 3 in
            flags sortbitwise,require_jewel_osds
      pgmap v26: 88 pgs, 4 pools, 2068 bytes data, 20 objects
            101 MB used, 2098 GB / 2098 GB avail
                  80 active+clean
                   8 creating
```


# secret
获取ceph集群中/etc/ceph/ceph.client.admin.keyring文件中的key值，创建包含这个key的base64编码值的secret对象。


比如：key为AQDDJ/1ZV8vTBRAA6W8j8797bGO0KV4OXRxGag==，将这个值base64编码：
```bash
echo "AQDDJ/1ZV8vTBRAA6W8j8797bGO0KV4OXRxGag==" | base64
```
得到的值是QVFEREovMVpWOHZUQlJBQTZXOGo4Nzk3YkdPMEtWNE9YUnhHYWc9PQo=，那么secret对象创建如下：
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
data:
  key: QVFEREovMVpWOHZUQlJBQTZXOGo4Nzk3YkdPMEtWNE9YUnhHYWc9PQo=
```

# 目录挂载
获取ceph集群中/etc/ceph/ceph.client.admin.keyring文件中的key值，创建包含这个key的base64编码值的secret对象。


运行命令先进行手动挂载分布式存储的根目录，并在被挂载的目录下新建pod中需要的挂载文件目录
```bash
mkdir /root/cephfs
mount -t ceph 10.80.220.88:6789:/ /root/cephfs -o name=admin,secret=AQA+1RxagI3dBxAArb5LX5mSEFWBGnEhEhafXA==
mkdir /root/cephfs/nginx/data
```

卸载文件目录
```bash
umount /root/cephfs
```
> 注意：1、若不进行手动的根目录挂载，则创建pod时不能指定分布式存储的目录，只能使用默认的根目录。更多内容请参考http://docs.ceph.org.cn/cephfs/kernel/
> 
> 2、如果需要开机自动挂载，请参考http://docs.ceph.org.cn/cephfs/fstab/

pod对象创建如下：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cephfs2
spec:
  containers:
  - name: cephfs-rw
    image: nginx
    volumeMounts:
    - mountPath: "/mnt/cephfs"
      name: cephfs
  volumes:
  - name: cephfs
    cephfs:
      monitors:
      - 10.80.115.231:6789
      - 10.80.220.88:6789
      - 10.80.223.204:6789
      user: admin
      path: /nginx/data
      secretRef:
        name: ceph-secret
      readOnly: false
```

# 删除osd
```bash
#将该osd的集群标记为out
docker exec -it b1d3442605cb ceph osd out osd.x
#将该osd从Ceph crush中移除
docker exec -it b1d3442605cb ceph osd crush remove osd.x
#从集群中完全删除该osd的记录
docker exec -it b1d3442605cb ceph osd rm osd.x
#删除该osd的认证信息，否则该osd的编号不会释放
docker exec -it b1d3442605cb ceph auth del osd.x
```
> 注意：服务器重启后出现废弃的osd时，需要用上面的命令删除该废弃的osd

# 参考
https://judexzhu.gitbooks.io/ceph-docker-deployment/content/Ceph-Docker%20Deployment.html

http://www.jianshu.com/p/f08ed7287416

https://v.qq.com/x/page/h0191o7rpfe.html

http://blog.csdn.net/heivy/article/details/50617385

【用 FSTAB 挂载】http://docs.ceph.org.cn/cephfs/fstab/

【用内核驱动挂载 CEPH 文件系统】http://docs.ceph.org.cn/cephfs/kernel/

【删除osd】http://www.jianshu.com/p/a104d156f120

【Ceph性能优化总结】http://xiaoquqi.github.io/blog/2015/06/28/ceph-performance-optimization-summary/
