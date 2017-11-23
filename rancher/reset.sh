#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
