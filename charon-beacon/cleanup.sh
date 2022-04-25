#!/bin/bash

usage() { echo "Usage: $0 <namespace>" 1>&2; exit 1; }

if [[ -z $1 ]]; then
  usage
  exit 1;
fi

ns=$1

# verify that the namespace exists
nsStatus=`kubectl get namespace $1 --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Namespace (${ns}) not found, please choose an existing namespace"
    exit 1;
fi

# set the current namespace
echo ">>> set the current namespace:"
kubectl config set-context --current --namespace=${ns}

# delete the monitoring stack
echo ">>> delete the monitoring stack:"
kubectl delete -f monitoring

# delete the charon nodes
echo ">>> delete the charon nodes:"
kubectl delete -f nodes

# delete the charon bootnode
echo ">>> delete the charon bootnode:"
kubectl delete -f bootnode

# delete the charon volumes
echo ">>> delete the charon volumes:"
kubectl delete pvc --all

# delete the current namespace
echo ">>> delete the current namespace:"
kubectl delete ns ${ns}
