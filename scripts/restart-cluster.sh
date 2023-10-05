#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to restart>"
  exit 1
fi

set -uo pipefail

CLUSTER_NAME=$1
echo "restarting cluster: ${CLUSTER_NAME}"
kubectl delete --all pods --namespace=${CLUSTER_NAME}
