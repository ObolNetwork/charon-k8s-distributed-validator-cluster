#!/bin/bash

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to restart>"
  exit
fi

CLUSTER_NAME=$1

# restart cluster
echo "restarting cluster: ${CLUSTER_NAME}"
kubectl delete --all pods --namespace=${CLUSTER_NAME}
