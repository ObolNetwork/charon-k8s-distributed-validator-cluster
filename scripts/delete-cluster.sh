#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to delete>"
  exit 1
fi

set -uo pipefail

CLUSTER_NAME=$1

# check if the cluster namespace exists
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Cluster (${CLUSTER_NAME}) is not found, please use an existing cluster"
else
  echo "deleting cluster: ${CLUSTER_NAME}"
  kubectl delete deployments --all -n ${CLUSTER_NAME}
  kubectl delete services --all -n ${CLUSTER_NAME}
fi
