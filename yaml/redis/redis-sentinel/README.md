#  redis主备
建议将rdb和aof同时开启。rdb默认是开启的，aof默认是关闭的。有关rdb和aof其他详细内容请参考http://blog.csdn.net/guoxingege/article/details/48780745

# 1 主节点redis-master.conf配置详解
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

#主节点密码
masterauth 123456
```
上面配置中通过requirepass设置了密码，我们把集群中所有的节点都设置相同的密码，还通过masterauth设置master节点的密码，当master节点宕机后，在重启变成slave节点，那么它需要去连接新的主节点需要masterauth配置，否则master节点重启后无法加入集群。

其他更多配置请参考
- http://download.redis.io/redis-stable/redis.conf
- https://www.cnblogs.com/kreo/p/4423362.html

**主节点启动1个。**

# 2 从节点redis-slave.conf配置详解
```
requirepass 123456
## 以下为rdb配置
#dbfilename：持久化数据存储在本地的文件
dbfilename dump.rdb

#dir：持久化数据存储在本地的路径，如果是在/redis/redis-3.0.6/src下启动的redis-cli，则数据会存储在当前src目录下
dir /data

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

#指定主节点
slaveof redis-master 6379

#主节点密码
masterauth 123456
```
从节点配置只是比主节点多了一个slaveof redis-master 6379配置，创建redis主服务器，再创建redis从节点，通过redis-server --slaveof redis-master 6379命令指定，表示当前节点服务为redis-master服务的从节点。

如果有多个从节点，需要有多个配置文件，并且配置文件需要可写。

# 3 redis-sentinel.conf配置详解
```
# 当前Sentinel服务运行的端口
port 26379

# Sentinel服务运行时使用的临时文件夹
dir /data

# Sentinel去监视一个名为mymaster的主redis实例，这个主实例的IP地址为redis-master，端口号为6379，而将这个主实例判断为失效至少需要2个Sentinel进程的同意，只要同意Sentinel的数量不达标，自动failover就不会执行
sentinel monitor mymaster redis-master 6379 2

# 指定了Sentinel认为Redis实例已经失效所需的毫秒数。当实例超过该时间没有返回PING，或者直接返回错误，那么Sentinel将这个实例标记为主观下线。只有一个 Sentinel进程将实例标记为主观下线并不一定会引起实例的自动故障迁移：只有在足够数量的Sentinel都将一个实例标记为主观下线之后，实例才会被标记为客观下线，这时自动故障迁移才会执行
sentinel down-after-milliseconds mymaster 30000

# 指定了在执行故障转移时，最多可以有多少个从Redis实例在同步新的主实例，在从Redis实例较多的情况下这个数字越小，同步的时间越长，完成故障转移所需的时间就越长
sentinel parallel-syncs mymaster 1

# 如果在该时间（ms）内未能完成failover操作，则认为该failover失败
sentinel failover-timeout mymaster 180000

# 设置主服务密码
sentinel auth-pass mymaster 123456
```
其他更多配置请参考http://download.redis.io/redis-stable/sentinel.conf

**哨兵节点至少配置2个以上。SENTINEL_QUORUM的数量需要根据哨兵节点的数量而定，一般为哨兵节点数量减1。**


# 4 docker-compose模拟redis集群
```
version: "2"
services:
  redis-master:
    image: redis:4.0.5
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - "/Users/zcg/tmp/redis/redis.conf:/etc/redis.conf"
    command: redis-server /etc/redis.conf
  redis-slave-0:
    image: redis:4.0.5
    restart: always
    ports:
      - "6380:6379"
    volumes:
      - "/Users/zcg/tmp/redis/slave0.conf:/etc/slave0.conf"
    command: redis-server /etc/slave0.conf
    depends_on:
      - redis-master
  redis-slave-1:
    image: redis:4.0.5
    restart: always
    ports:
      - "6381:6379"
    volumes:
      - "/Users/zcg/tmp/redis/slave1.conf:/etc/slave1.conf"
    command: redis-server /etc/slave1.conf
    depends_on:
      - redis-master
  redis-sentinel-0:
    image: redis:4.0.5
    restart: always
    ports:
      - "6390:6379"
    volumes:
      - "/Users/zcg/tmp/redis/sentinel0.conf:/etc/sentinel0.conf"
    command: redis-server /etc/sentinel0.conf --sentinel
    depends_on:
      - redis-master
  redis-sentinel-1:
    image: redis:4.0.5
    restart: always
    ports:
      - "6391:6379"
    volumes:
      - "/Users/zcg/tmp/redis/sentinel1.conf:/etc/sentinel1.conf"
    command: redis-server /etc/sentinel1.conf --sentinel
    depends_on:
      - redis-master
  redis-sentinel-2:
    image: redis:4.0.5
    restart: always
    ports:
      - "6392:6379"
    volumes:
      - "/Users/zcg/tmp/redis/sentinel2.conf:/etc/sentinel2.conf"
    command: redis-server /etc/sentinel2.conf --sentinel
    depends_on:
      - redis-master

```

启动：
```
docker-compose up -d

Creating redis_redis-master_1 ... 
Creating redis_redis-master_1 ... done
Creating redis_redis-sentinel-2_1 ... 
Creating redis_redis-slave-1_1 ... 
Creating redis_redis-sentinel-0_1 ... 
Creating redis_redis-slave-0_1 ... 
Creating redis_redis-sentinel-1_1 ... 
Creating redis_redis-sentinel-2_1
Creating redis_redis-sentinel-0_1
Creating redis_redis-sentinel-1_1
Creating redis_redis-slave-0_1
Creating redis_redis-sentinel-1_1 ... done
```


查看是否启动成功。
```
docker-compose ps

          Name                        Command               State           Ports         
------------------------------------------------------------------------------------------
redis_redis-master_1       docker-entrypoint.sh redis ...   Up      0.0.0.0:6379->6379/tcp
redis_redis-sentinel-0_1   docker-entrypoint.sh redis ...   Up      0.0.0.0:6390->6379/tcp
redis_redis-sentinel-1_1   docker-entrypoint.sh redis ...   Up      0.0.0.0:6391->6379/tcp
redis_redis-sentinel-2_1   docker-entrypoint.sh redis ...   Up      0.0.0.0:6392->6379/tcp
redis_redis-slave-0_1      docker-entrypoint.sh redis ...   Up      0.0.0.0:6380->6379/tcp
redis_redis-slave-1_1      docker-entrypoint.sh redis ...   Up      0.0.0.0:6381->6379/tcp
```
注意：容器名称会和docker-compose文件所在文件夹名称不同而有所区别，请自行修改。

# 5 查看集群信息
登录主节点：
```
docker exec -it redis_redis-master_1 redis-cli -a 123456
```
查看集群信息:
```
info replication

# Replication
role:master
connected_slaves:2
slave0:ip=172.20.0.6,port=6379,state=online,offset=109319,lag=1
slave1:ip=172.20.0.7,port=6379,state=online,offset=109319,lag=1
master_replid:b0a43214027bab954359b9ffd2642158c25019cd
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:109468
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:109468
```

查看服务信息:
```
info server

# Server
redis_version:4.0.5
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:8862fec03d304152
redis_mode:standalone
os:Linux 4.9.49-moby x86_64
arch_bits:64
multiplexing_api:epoll
atomicvar_api:atomic-builtin
gcc_version:4.9.2
process_id:1
run_id:8ccdeded6b9687cccd6fbeb94371b8b2b2a5dad0
tcp_port:6379
uptime_in_seconds:573
uptime_in_days:0
hz:10
lru_clock:5261207
executable:/data/redis-server
config_file:/etc/redis.conf
```

查看sentinel节点配置：
```
# 当前Sentinel服务运行的端口
port 26379

# Sentinel服务运行时使用的临时文件夹
dir "/data"

# Sentinel去监视一个名为mymaster的主redis实例，这个主实例的IP地址为redis-master，端口号为6379，而将这个主实例判断为失效至少需要$SENTINEL_QUORUM个 Sentinel进程的同意，只要同意Sentinel的数量不达标，自动failover就不会执行
sentinel myid d6ce8ebd50d3c7ee7366753bb7847bb8267b633d

# 指定了Sentinel认为Redis实例已经失效所需的毫秒数。当实例超过该时间没有返回PING，或者直接返回错误，那么Sentinel将这个实例标记为主观下线。只有一个 Sentinel进程将实例标记为主观下线并不一定会引起实例的自动故障迁移：只有在足够数量的Sentinel都将一个实例标记为主观下线之后，实例才会被标记为客观下线，这时自动故障迁移才会执行
sentinel monitor mymaster 172.20.0.2 6379 2

# 指定了在执行故障转移时，最多可以有多少个从Redis实例在同步新的主实例，在从Redis实例较多的情况下这个数字越小，同步的时间越长，完成故障转移所需的时间就越长
sentinel auth-pass mymaster 123456

# 如果在该时间（ms）内未能完成failover操作，则认为该failover失败
sentinel config-epoch mymaster 0

# 设置主服务密码
sentinel leader-epoch mymaster 0
# Generated by CONFIG REWRITE
sentinel known-slave mymaster 172.20.0.7 6379
sentinel known-slave mymaster 172.20.0.3 6379
sentinel known-sentinel mymaster 172.20.0.5 26379 11a6d1da70ccb930fdec76fa1c65d63be6058e38
sentinel known-sentinel mymaster 172.20.0.4 26379 32750823ca32d4dd1059d93fe122f2ca104fb4a9
sentinel current-epoch 0
```
我们发现sentinel节点配置被修改，并去追加了多个配置，主要包含从节点的IP和sentinel节点的IP，自身的ip没有包含在配置中。master主机名被替换为了IP。

slave节点配置中，slaveof redis-master 6379中的主机名被替换成IP。

此处的IP为docker容器的IP。

# 6 测试

## 6.1 主从节点数据同步测试
在redis主节点上操作数据时，从节点会同步主节点数据。

下面开始验证：

1.首先在master节点新建key为a=1
```
docker exec -it redis_redis-master_1 redis-cli -a 123456
set a 1
```
2.在slave节点查看数据是否同步
```
docker exec -it redis_redis-slave-0_1 redis-cli -a 123456
get a

docker exec -it redis_redis-slave-1_1 redis-cli -a 123456
get a
```

## 6.2 从节点为只读节点
```
docker exec -it redis_redis-slave-0_1 redis-cli -a 123456
127.0.0.1:6379> set b 1
(error) READONLY You can't write against a read only slave.
```
从节点无法写入数据。

## 6.3 删除master节点
删除master节点，2个从节点中有一个节点变成主节点，另一节点为从节点机，并且这两个节点数据是同步的。

1.删除master节点
```
docker-compose stop redis-master
docker-compose rm redis-master
```

2.等待30秒后，sentinel节点判断master节点客观下线，会在slave节点中重新选举一个主节点。下面是sentinel节点变更的配置。由下面的配置可以看出，172.20.0.2为原主节点IP，现在为slave节点。原来的slave节点172.20.0.7变为主节点。
```
# 当前Sentinel服务运行的端口
port 26379

# Sentinel服务运行时使用的临时文件夹
dir "/data"

# Sentinel去监视一个名为mymaster的主redis实例，这个主实例的IP地址为redis-master，端口号为6379，而将这个主实例判断为失效至少需要$SENTINEL_QUORUM个 Sentinel进程的同意，只要同意Sentinel的数量不达标，自动failover就不会执行
sentinel myid 32750823ca32d4dd1059d93fe122f2ca104fb4a9

# 指定了Sentinel认为Redis实例已经失效所需的毫秒数。当实例超过该时间没有返回PING，或者直接返回错误，那么Sentinel将这个实例标记为主观下线。只有一个 Sentinel进程将实例标记为主观下线并不一定会引起实例的自动故障迁移：只有在足够数量的Sentinel都将一个实例标记为主观下线之后，实例才会被标记为客观下线，这时自动故障迁移才会执行
sentinel monitor mymaster 172.20.0.7 6379 2

# 指定了在执行故障转移时，最多可以有多少个从Redis实例在同步新的主实例，在从Redis实例较多的情况下这个数字越小，同步的时间越长，完成故障转移所需的时间就越长
sentinel auth-pass mymaster 123456

# 如果在该时间（ms）内未能完成failover操作，则认为该failover失败
sentinel config-epoch mymaster 1

# 设置主服务密码
sentinel leader-epoch mymaster 1
# Generated by CONFIG REWRITE
sentinel known-slave mymaster 172.20.0.3 6379
sentinel known-slave mymaster 172.20.0.2 6379
sentinel known-sentinel mymaster 172.20.0.6 26379 d6ce8ebd50d3c7ee7366753bb7847bb8267b633d
sentinel known-sentinel mymaster 172.20.0.5 26379 11a6d1da70ccb930fdec76fa1c65d63be6058e38
sentinel current-epoch 1
```
3.在新的主机点写入数据
```
docker exec -it redis_redis-slave-1_1 redis-cli -a 123456
set b 2
```

4.查看从节点数据是否同步
```
docker exec -it redis_redis-slave-0_1 redis-cli -a 123456
get b
```

## 6.4 重启原来的master节点
当原来的master节点重启并加入集群，作为从节点。通过info replication命令，获取集群信息。
```
info replication

# Replication
role:master
connected_slaves:2
slave0:ip=172.20.0.3,port=6379,state=online,offset=1765725,lag=1
slave1:ip=172.20.0.2,port=6379,state=online,offset=1765725,lag=0
master_replid:6808b9f54664300c3667d541cfa515f87c64fed3
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:1765725
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1486268
repl_backlog_histlen:279458
```
可以发现原来的master节点已经加入集群。进入原来的master节点发现数据全部同步完成。

# 7 kubernetes脚本

redis sentinel集群的kubernetes脚本从下面地址查看：
https://github.com/zhuchuangang/k8s-install-scripts/tree/master/yaml/redis/redis-sentinel

## 7.1 Dockerfile
Dockerfile添加redis主节点和从节点的配置以及run.sh脚本。

主节点和从节点配置内容和说明请参考redis-master.conf和redis-slave.conf配置文件。

## 7.2 启动临时主节点
```
kubectl create -f ./redis-master-pod.yaml
```
临时主节点pod包含2个容器，其中一个为主节点容器，另外一个为哨兵节点容器。

通过环境变量来表示节点类型，如果容器是主节点，那么run.sh脚本直接启动服务。

如果容器是哨兵节点，那么run.sh脚本会尝试连接redis-sentinel服务，通过REDIS_SENTINEL_SERVICE_HOST环境变量连接，
来获取集群中主节点的IP,而临时主节点pod中的哨兵节点容器启动时，我们还没有创建redis-sentinel服务，所以当前临时主节点
pod中启动的容器只有主节点容器，而且在同一个pod中的容器可以使用localhost进行通信，所以哨兵节点容器我们可以通过localhost
或者使用pod的hostname进行来连接主节点容器，并动态生成sentinel的配置，并启动哨兵节点容器。到这里主节点pod中的2个容器
都已经启动完毕。

## 7.3 启动哨兵节点
```
kubectl create -f ./redis-sentinel-svc.yaml
kubectl create -f ./redis-sentinel-deploy.yaml
```
上面我已经提到哨兵节点启动前会从哨兵节点获取master节点地址，我们先创建redis-sentinel服务，
由于主节点pod的标签和redis-sentinel服务的标签选择器一致，并且主节点pod包含哨兵节点，所以redis-sentinel服务创建后，
服务是有效的，可以访问的，之后我们在创建redis-sentinel的deploy，启动哨兵节点后，会通过redis-sentinel服务获取当前
主节点IP,并动态生成sentinel配置，并启动哨兵节点。

## 7.5 启动从节点
```
kubectl create -f ./redis-slave-statefulset.yaml
```
启动从节点也需要通过redis-sentinel服务获取主节点IP，并生成相关配置，启动服务。

## 7.6 删除临时主节点
```
kubectl delete -f ./redis-master-pod.yaml
```
经过上面的步骤集群已经基本搭建完成，但是还有最后一步需要处理，删除临时主节点。

删除临时主节点的原因是，主节点pod被kill之后，pod会被重新创建，pod的ip也发生变化，对于整个集群而言这新pod并不是原来的主节点
pod，而且这个新主节点并没有加入集群，而是孤立的可写节点，这是因为run.sh脚本中启动主机的脚本决定的，为了避免这个情况的出现，所以
最后一步是需要删除主节点。

和主机部署不同，主机的ip一般固定，而kubernetes的pod在被kill之后，新的pod的ip一般都会和原来不同，也是因为这个原因促使我们需要
完成最后一步，删除临时主节点。

## 7.7 完整执行步骤
```
kubectl create -f ./redis-master-pod.yaml
kubectl create -f ./redis-sentinel-svc.yaml
kubectl create -f ./redis-sentinel-deploy.yaml
kubectl create -f ./redis-slave-statefulset.yaml
kubectl create -f ./redis-slave-svc.yaml
kubectl delete -f ./redis-master-pod.yaml
```

参考：

【使用Docker Compose部署基于Sentinel的高可用Redis集群】https://yq.aliyun.com/articles/57953

【redis持久化】http://blog.csdn.net/guoxingege/article/details/48780745

 https://github.com/kubernetes/examples/tree/master/staging/storage/redis
