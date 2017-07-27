set -o errexit
set -o nounset
set -o pipefail

INSTALL_MASTER=${1:-"true"}
KUBE_BIN_DIR=${2:-"/opt/kubernetes/bin"}
KUBE_CFG_DIR=${3:-"/opt/kubernetes/cfg"}
KUBE_LOG_DIR=${4:-"/opt/kubernetes/logs"}
KUBE_VERSION=${5:-"v1.6.7"}

echo '============================================================'
echo '===================Downland kubernetes... =================='
echo '============================================================'

mkdir -p ${KUBE_BIN_DIR}
mkdir -p ${KUBE_CFG_DIR}
mkdir -p ${KUBE_LOG_DIR}

if [ ! -f "./kubernetes.tar.gz" ]; then
echo "downland kubernetes.tar.gz file"
wget https://github.com/kubernetes/kubernetes/releases/download/${KUBE_VERSION}/kubernetes.tar.gz
else
echo "kubernetes.tar.gz file already exists"
fi

if [ ! -d "./kubernetes" ]; then
echo "unzip kubernetes.tar.gz file"
tar zxvf kubernetes.tar.gz
sh ./kubernetes/cluster/get-kube-binaries.sh
tar zxvf ./kubernetes/server/kubernetes-server-linux-amd64.tar.gz
else
echo "kubernetes directory already exists"
fi


echo '============================================================'
echo '===================Install kubernetes... ==================='
echo '============================================================'

if [ ${INSTALL_MASTER} = "true" ]; then
echo "This node is a master node!"
echo "Copy kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet to ${KUBE_BIN_DIR} "
cp ./kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} ${KUBE_BIN_DIR}
else
echo "This node is a slave node!"
echo "Copy kubectl,kube-proxy,kubelet to ${KUBE_BIN_DIR} "
cp ./kubernetes/server/bin/{kubectl,kube-proxy,kubelet} ${KUBE_BIN_DIR}
cp ./kubernetes/cluster/centos/node/bin/{mk-docker-opts.sh,remove-docker0.sh} ${KUBE_BIN_DIR}
fi
