FROM rabbitmq:3.6.12-management

ENV RABBITMQ_USE_LONGNAME=true \
    AUTOCLUSTER_LOG_LEVEL=debug \
    AUTOCLUSTER_CLEANUP=true \
    CLEANUP_INTERVAL=60 \
    CLEANUP_WARN_ONLY=false \
    AUTOCLUSTER_TYPE=k8s \
    LANG=en_US.UTF-8

ADD plugins/*.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.12/plugins/
RUN rabbitmq-plugins enable --offline autocluster
