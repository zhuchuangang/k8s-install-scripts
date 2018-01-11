FROM redis:4.0.6

COPY redis-master.conf /redis-master/redis.conf
COPY redis-slave.conf /redis-slave/redis.conf
COPY run.sh /run.sh

RUN chmod a+x /run.sh

VOLUME /data

CMD [ "/run.sh" ]

ENTRYPOINT [ "bash", "-c" ]
