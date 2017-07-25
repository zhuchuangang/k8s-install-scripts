#!/bin/bash
#第1个参数是配置文件/opt/kubernetes/cfg/kube-apiserver中KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.0.0.0/24"参数的指定网段的第一个IP
#第2个参数是master地址MASTER_ADDRESS
#第3个参数是etcd服务地址ETCD_SERVERS
#第4个参数是kubernetes集群ip的范围SERVICE_CLUSTER_IP_RANGE
#
#sh kube_master.sh "10.10.10.1" "172.16.120.151" "http://172.16.120.151:2379,http://172.16.120.152:2379,http://172.16.120.153:2379" "10.0.0.0/24"

set -o errexit
set -o nounset
set -o pipefail


echo "################ 1.Create SSL... "
#创建证书存放目录
rm -rf /srv/kubernetes
mkdir /srv/kubernetes

###############生成根证书################
#创建CA私钥
openssl genrsa -out /srv/kubernetes/ca.key 2048
#自签CA
openssl req -x509 -new -nodes -key /srv/kubernetes/ca.key -subj "/CN=3songshu.com" -days 10000 -out /srv/kubernetes/ca.crt
###############生成 API Server 服务端证书和私钥###############

KUBE_CLUSTER_IP=${1:-"10.0.0.1"}
KUBE_MASTER_IP=${2:-}

cat <<EOF >/srv/kubernetes/master_ssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = k8s-node01
IP.1 = ${KUBE_CLUSTER_IP}
IP.2 = ${KUBE_MASTER_IP}
EOF

#生成apiserver私钥
openssl genrsa -out /srv/kubernetes/server.key 2048

#生成签署请求
openssl req -new -key /srv/kubernetes/server.key -subj "/CN=k8s-master" -config /srv/kubernetes/master_ssl.cnf -out /srv/kubernetes/server.csr

#使用自建CA签署
openssl x509 -req -in /srv/kubernetes/server.csr -CA /srv/kubernetes/ca.crt -CAkey /srv/kubernetes/ca.key -CAcreateserial -days 10000 -extensions v3_req -extfile /srv/kubernetes/master_ssl.cnf -out /srv/kubernetes/server.crt

#生成 Controller Manager 与 Scheduler 进程共用的证书和私钥
openssl genrsa -out /srv/kubernetes/cs_client.key 2048

#生成签署请求
openssl req -new -key /srv/kubernetes/cs_client.key -subj "/CN=k8s-master" -out /srv/kubernetes/cs_client.csr

#使用自建CA签署
openssl x509 -req -in /srv/kubernetes/cs_client.csr -CA /srv/kubernetes/ca.crt -CAkey /srv/kubernetes/ca.key -CAcreateserial -out /srv/kubernetes/cs_client.crt -days 10000

cat <<EOF >/opt/kubernetes/cfg/kubeconfig.yaml
apiVersion: v1
kind: Config
users:
- name: controllermanager
  user:
    client-certificate: /srv/kubernetes/cs_client.crt
    client-key: /srv/kubernetes/cs_client.key
clusters:
- name: local
  cluster:
    certificate-authority: /srv/kubernetes/ca.crt
contexts:
- context:
    cluster: local
    user: controllermanager
  name: my-context
current-context: my-context
EOF

echo "################ 2.Downland kubernetes... "
mkdir -p /opt/kubernetes/bin
mkdir -p /opt/kubernetes/cfg

KUBE_VERSION=v1.6.7
if [ ! -f "./kubernetes.tar.gz" ]; then
wget https://github.com/kubernetes/kubernetes/releases/download/$KUBE_VERSION/kubernetes.tar.gz
fi
tar zxvf kubernetes.tar.gz
sh /root/kubernetes/cluster/get-kube-binaries.sh
cd /root/kubernetes/server/
tar zxvf kubernetes-server-linux-amd64.tar.gz

echo "################ 3.Copy kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet to /opt/kubernetes/bin/ "
cd /root/kubernetes/server/kubernetes/server/bin/
cp {kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /opt/kubernetes/bin/

echo "################ 4.install api server... "
MASTER_ADDRESS=${2:-}
ETCD_SERVERS=${3:-}
SERVICE_CLUSTER_IP_RANGE=${4:-"10.0.0.0/24"}

cat <<EOF >/opt/kubernetes/cfg/kube-apiserver
# --logtostderr=true: log to standard error instead of files
KUBE_LOGTOSTDERR="--logtostderr=true"

# --v=0: log level for V logs
KUBE_LOG_LEVEL="--v=4"

# --etcd-servers=[]: List of etcd servers to watch (http://ip:port),
# comma separated. Mutually exclusive with -etcd-config
KUBE_ETCD_SERVERS="--etcd-servers=${ETCD_SERVERS}"

# --insecure-bind-address=127.0.0.1: The IP address on which to serve the --insecure-port.
KUBE_API_ADDRESS="--bind-address=0.0.0.0"

# --insecure-port=8080: The port on which to serve unsecured, unauthenticated access.
KUBE_API_PORT="--secure-port=443"

# --kubelet-port=10250: Kubelet port
NODE_PORT="--kubelet-port=10250"

# --advertise-address=<nil>: The IP address on which to advertise
# the apiserver to members of the cluster.
KUBE_ADVERTISE_ADDR="--advertise-address=${MASTER_ADDRESS}"

# --allow-privileged=false: If true, allow privileged containers.
KUBE_ALLOW_PRIV="--allow-privileged=false"

# --service-cluster-ip-range=<nil>: A CIDR notation IP range from which to assign service cluster IPs.
# This must not overlap with any IP ranges assigned to nodes for pods.
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE}"

# --admission-control="AlwaysAdmit": Ordered list of plug-ins
# to do admission control of resources into cluster.
# Comma-delimited list of:
#   LimitRanger, AlwaysDeny, SecurityContextDeny, NamespaceExists,
#   NamespaceLifecycle, NamespaceAutoProvision, AlwaysAdmit,
#   ServiceAccount, DefaultStorageClass, DefaultTolerationSeconds, ResourceQuota
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

# --client-ca-file="": If set, any request presenting a client certificate signed
# by one of the authorities in the client-ca-file is authenticated with an identity
# corresponding to the CommonName of the client certificate.
KUBE_API_CLIENT_CA_FILE="--client-ca-file=/srv/kubernetes/ca.crt"

# --tls-cert-file="": File containing x509 Certificate for HTTPS.  (CA cert, if any,
# concatenated after server cert). If HTTPS serving is enabled, and --tls-cert-file
# and --tls-private-key-file are not provided, a self-signed certificate and key are
# generated for the public address and saved to /var/run/kubernetes.
KUBE_API_TLS_CERT_FILE="--tls-cert-file=/srv/kubernetes/server.crt"

# --tls-private-key-file="": File containing x509 private key matching --tls-cert-file.
KUBE_API_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/srv/kubernetes/server.key"
EOF

KUBE_APISERVER_OPTS="   \${KUBE_LOGTOSTDERR}         \\
                        \${KUBE_LOG_LEVEL}           \\
                        \${KUBE_ETCD_SERVERS}        \\
                        \${KUBE_API_ADDRESS}         \\
                        \${KUBE_API_PORT}            \\
                        \${NODE_PORT}                \\
                        \${KUBE_ADVERTISE_ADDR}      \\
                        \${KUBE_ALLOW_PRIV}          \\
                        \${KUBE_SERVICE_ADDRESSES}   \\
                        \${KUBE_ADMISSION_CONTROL}   \\
                        \${KUBE_API_CLIENT_CA_FILE}  \\
                        \${KUBE_API_TLS_CERT_FILE}   \\
                        \${KUBE_API_TLS_PRIVATE_KEY_FILE}"

cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=etcd.service
Wants=etcd.service

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver ${KUBE_APISERVER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver



echo "################ 5.install controller manager... "
cat <<EOF >/opt/kubernetes/cfg/kube-controller-manager
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
KUBE_MASTER="--master=https://${MASTER_ADDRESS}:443"

# --root-ca-file="": If set, this root certificate authority will be included in
# service account's token secret. This must be a valid PEM-encoded CA bundle.
KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE="--root-ca-file=/srv/kubernetes/ca.crt"

# --service-account-private-key-file="": Filename containing a PEM-encoded private
# RSA key used to sign service account tokens.
KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE="--service-account-private-key-file=/srv/kubernetes/server.key"

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=false"

KUBE_CONFIG="--kubeconfig=/opt/kubernetes/cfg/kubeconfig.yaml"
EOF

KUBE_CONTROLLER_MANAGER_OPTS="  \${KUBE_LOGTOSTDERR} \\
                                \${KUBE_LOG_LEVEL}   \\
                                \${KUBE_MASTER}      \\
                                \${KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE} \\
                                \${KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE} \\
                                \${KUBE_CONFIG} \\
                                \${KUBE_LEADER_ELECT}"

cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager ${KUBE_CONTROLLER_MANAGER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager


echo "################ 6.install scheduler... "

cat <<EOF >/opt/kubernetes/cfg/kube-scheduler
###
# kubernetes scheduler config

# --logtostderr=true: log to standard error instead of files
KUBE_LOGTOSTDERR="--logtostderr=true"

# --v=0: log level for V logs
KUBE_LOG_LEVEL="--v=4"

KUBE_MASTER="--master=https://${MASTER_ADDRESS}:443"

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=true"

# Add your own!
KUBE_SCHEDULER_ARGS="--kubeconfig=/opt/kubernetes/cfg/kubeconfig.yaml"

EOF

KUBE_SCHEDULER_OPTS="   \${KUBE_LOGTOSTDERR}     \\
                        \${KUBE_LOG_LEVEL}       \\
                        \${KUBE_MASTER}          \\
                        \${KUBE_LEADER_ELECT}    \\
                        \${KUBE_SCHEDULER_ARGS}"

cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-scheduler
ExecStart=/opt/kubernetes/bin/kube-scheduler ${KUBE_SCHEDULER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl restart kube-scheduler
