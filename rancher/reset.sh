#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
if [ -d "/var/etcd/backups" ]; then
rm -rf /var/etcd/backups
fi
if [ -d "/mnt/data/rancher-mariadb" ]; then
rm -rf /mnt/data/rancher-mariadb
fi

