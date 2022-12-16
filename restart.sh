#!/bin/bash

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to restart>"
  exit
fi

CLUSTER_NAME=$1

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

echo "deploy cluster: ${CLUSTER_NAME}"

# restart cluster
kubectl delete --all pods --namespace=${CLUSTER_NAME}
