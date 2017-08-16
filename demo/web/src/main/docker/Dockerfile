#使用daocloud的java8镜像
FROM java:8
#镜像创建人
MAINTAINER sxt i_sxtian@3songshu.com
#附加卷
VOLUME /tmp
#添加jar包
ADD web*.jar app.jar
#修改jar包日期
RUN bash -c "touch app.jar"
#并指定端口号
EXPOSE 8080
#环境变量
ENV TZ Asia/Shanghai
#设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#运行脚步
ENTRYPOINT java -jar /app.jar -Djava.security.egd=file:/dev/./urandom
