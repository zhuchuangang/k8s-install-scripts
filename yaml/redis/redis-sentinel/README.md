# 1 redis主备
建议将rdb和aof同时开启。rdb默认是开启的，aof默认是关闭的。有关rdb和aof其他详细内容请参考http://blog.csdn.net/guoxingege/article/details/48780745

## 1.1 redis.conf配置详解
```
requirepass 123456

## 以下为rdb配置
#dbfilename：持久化数据存储在本地的文件
dbfilename dump.rdb

#dir：持久化数据存储在本地的路径，如果是在/redis/redis-3.0.6/src下启动的redis-cli，则数据会存储在当前src目录下
dir ./

##snapshot触发的时机，save <seconds> <changes>  
##如下为900秒后，至少有一个变更操作，才会snapshot  
##对于此值的设置，需要谨慎，评估系统的变更操作密集程度  
##可以通过“save “””来关闭snapshot功能  
#save时间，以下分别表示更改了1个key时间隔900s进行持久化存储；更改了10个key300s进行存储；更改10000个key60s进行存储。
save 900 1
save 300 10
save 60 10000

##当snapshot时出现错误无法继续时，是否阻塞客户端“变更操作”，“错误”可能因为磁盘已满/磁盘故障/OS级别异常等  
stop-writes-on-bgsave-error yes 

##是否启用rdb文件压缩，默认为“yes”，压缩往往意味着“额外的cpu消耗”，同时也意味这较小的文件尺寸以及较短的网络传输时间  
rdbcompression yes

##以下为aof配置
##此选项为aof功能的开关，默认为“no”，可以通过“yes”来开启aof功能  
##只有在“yes”下，aof重写/文件同步等特性才会生效  
appendonly yes  

##指定aof文件名称  
appendfilename appendonly.aof  

##指定aof操作中文件同步策略，有三个合法值：always everysec no,默认为everysec  
appendfsync everysec  

##在aof-rewrite期间，appendfsync是否暂缓文件同步，"no"表示“不暂缓”，“yes”表示“暂缓”，默认为“no”
no-appendfsync-on-rewrite no  

##aof文件rewrite触发的最小文件尺寸(mb,gb),只有大于此aof文件大于此尺寸是才会触发rewrite，默认“64mb”，建议“512mb”  
auto-aof-rewrite-min-size 64mb  

##相对于“上一次”rewrite，本次rewrite触发时aof文件应该增长的百分比。  
##每一次rewrite之后，redis都会记录下此时“新aof”文件的大小(例如A)，那么当aof文件增长到A*(1 + p)之后  
##触发下一次rewrite，每一次aof记录的添加，都会检测当前aof文件的尺寸。  
auto-aof-rewrite-percentage 100  
```
其他更多配置请参考
- http://download.redis.io/redis-stable/redis.conf
- https://www.cnblogs.com/kreo/p/4423362.html

## 1.2 启动主服务器
```bash
docker run -d -p 6379:6379 \
--name=redis-master \
-v redis.conf:/etc/redis.conf
redis:4.0.5 \
redis-server /etc/redis.conf
```
**主节点启动1个。**

## 1.3 启动从服务器
```
docker run -d -p 6380:6379 \
--name=redis-slave \
--link=redis-master \
-v redis.conf:/etc/redis.conf
redis:4.0.5 \
redis-server /etc/redis.conf --slaveof redis-master 6379
```
**从节点至少启动1个。**

创建redis主服务器，再创建redis从节点，通过redis-server --slaveof redis-master 6379命令指定，表示当前节点服务为redis-master服务的从节点。

## 1.4 测试
当在redis主节点上操作数据时，从节点会同步主节点数据。


# 2 创建redis-sentinel镜像

## 2.1 sentinel.conf配置详解
```
# 当前Sentinel服务运行的端口
port 26379

# Sentinel服务运行时使用的临时文件夹
dir /tmp

# Sentinel去监视一个名为mymaster的主redis实例，这个主实例的IP地址为redis-master，端口号为6379，而将这个主实例判断为失效至少需要$SENTINEL_QUORUM个 Sentinel进程的同意，只要同意Sentinel的数量不达标，自动failover就不会执行
sentinel monitor mymaster redis-master 6379 $SENTINEL_QUORUM

#指定了Sentinel认为Redis实例已经失效所需的毫秒数。当实例超过该时间没有返回PING，或者直接返回错误，那么Sentinel将这个实例标记为主观下线。只有一个 Sentinel进程将实例标记为主观下线并不一定会引起实例的自动故障迁移：只有在足够数量的Sentinel都将一个实例标记为主观下线之后，实例才会被标记为客观下线，这时自动故障迁移才会执行
sentinel down-after-milliseconds mymaster $SENTINEL_DOWN_AFTER

# 指定了在执行故障转移时，最多可以有多少个从Redis实例在同步新的主实例，在从Redis实例较多的情况下这个数字越小，同步的时间越长，完成故障转移所需的时间就越长
sentinel parallel-syncs mymaster 1

# 如果在该时间（ms）内未能完成failover操作，则认为该failover失败
sentinel failover-timeout mymaster $SENTINEL_FAILOVER

# 设置主服务密码
sentinel auth-pass mymaster $PASSWORD
```
其他更多配置请参考http://download.redis.io/redis-stable/sentinel.conf


## 2.2 启动sentinel服务
```
docker run -d -p 6379:6379 \
--name=redis-master \
-v redis.conf:/etc/sentinel.conf
redis:4.0.5 \
redis-server /etc/sentinel.conf --sentinel
```
**哨兵节点至少配置2个以上。SENTINEL_QUORUM的数量需要根据哨兵节点的数量而定，一般为哨兵节点数量减1。**


## 2.3 kubernetes配置要点
### 2.3.1 使用StatefulSet进行部署
要定义一个服务(Service)为无头服务(Headless Service)，需要把Service定义中的ClusterIP配置项设置为空: spec.clusterIP:None。
和普通Service相比，Headless Service没有ClusterIP(所以没有负载均衡),它会给一个集群内部的每个成员提供一个唯一的DNS域名来
作为每个成员的网络标识，集群内部成员之间使用域名通信。无头服务管理的域名是如下的格式：$(service_name).$(k8s_namespace).svc.cluster.local。

如果本实例脚本中的redis-master服务可以通过redis-master-0、redis-master-0.default、redis-master-0.default.svc.cluster.local等dns名称访问。

### 2.3.2 非亲和调度
```bash
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - redis-master
                        - redis-slave
                topologyKey: kubernetes.io/hostname
```
上面的配置表示，如果配置了该调度配置的pod，不能和它的label,key=app,且值为redis-master/redis-salve的pod部署在同一台机器或拓扑内。

### 2.3.3 存储
该脚本需要配合storage-class目录下的脚本使用，storage-class创建了一个阿里云nas存储类。

### 2.3.4 测试
集群运行起来之后，进入redis-sentinel容器，执行下面的命令，获取sentinel集群信息：
```bash
redis-cli -p 26379 info Sentinel
```
执行结果如下：
```bash
# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=mymaster,status=ok,address=10.42.25.251:6379,slaves=2,sentinels=3
```
此时master节点的ip为10.42.25.251。

然后删除redis-master的pod节点，随后kubernetes会重新启动一个新的redis-master的pod节点，稍等片刻后，在redis-sentinel容器，执行下面的命令，获取sentinel集群信息：
```bash
redis-cli -p 26379 info Sentinel
```
执行结果如下：
```bash
# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=mymaster,status=ok,address=10.42.78.28:6379,slaves=2,sentinels=3
```
此时的master节点已经发生变化，ip为10.42.78.28，其中一个slave节点晋升为master节点。


参考：

【使用Docker Compose部署基于Sentinel的高可用Redis集群】https://yq.aliyun.com/articles/57953

【redis持久化】http://blog.csdn.net/guoxingege/article/details/48780745
