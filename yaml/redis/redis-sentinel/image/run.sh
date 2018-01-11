#!/bin/bash

# Copyright 2014 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function launchmaster() {
  if [[ ! -e /data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /data
  fi
  if [[ -n ${PASSWORD} ]]; then
    echo "requirepass ${PASSWORD}" >> /redis-master/redis.conf
    echo "masterauth ${PASSWORD}" >> /redis-master/redis.conf
  fi
  redis-server /redis-master/redis.conf --protected-mode no
}

function launchsentinel() {
  while true; do
    # SENTINEL命令参考：http://doc.redisfans.com/topic/sentinel.html
    master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      master=$(hostname -i)
    fi

    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  mkdir /redis-sentinel
  sentinel_conf=/redis-sentinel/sentinel.conf

  echo "sentinel monitor mymaster ${master} 6379 2" > ${sentinel_conf}
  echo "sentinel down-after-milliseconds mymaster 30000" >> ${sentinel_conf}
  echo "sentinel failover-timeout mymaster 180000" >> ${sentinel_conf}
  echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}
  echo "min-slaves-to-write 1" >> ${sentinel_conf}
  echo "min-slaves-max-lag 10" >> ${sentinel_conf}
  echo "bind 0.0.0.0" >> ${sentinel_conf}
  if [[ -n ${PASSWORD} ]]; then
    echo "sentinel auth-pass mymaster ${PASSWORD}" >> ${sentinel_conf}
  fi
  redis-sentinel ${sentinel_conf} --protected-mode no
}

function launchslave() {
  if [[ ! -e /data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /data
  fi
  while true; do
    master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      echo "Failed to find master."
      sleep 60
      exit 1
    fi
    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done
  sed -i "s/%master-ip%/${master}/" /redis-slave/redis.conf
  sed -i "s/%master-port%/6379/" /redis-slave/redis.conf
  if [[ -n ${PASSWORD} ]]; then
    echo "requirepass ${PASSWORD}" >> /redis-slave/redis.conf
    echo "masterauth ${PASSWORD}" >> /redis-slave/redis.conf
  fi
  redis-server /redis-slave/redis.conf --protected-mode no
}


if [[ "${MASTER}" == "true" ]]; then
  launchmaster
  exit 0
fi

if [[ "${SENTINEL}" == "true" ]]; then
  launchsentinel
  exit 0
fi

launchslave
