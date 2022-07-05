#!/bin/bash

# override the env vars with the needed env vars for the *-deployment.yaml files
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

# check if the cluster namespace exists
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Cluster (${CLUSTER_NAME}) is not found, please use an existing cluster"
    exit 1;
fi

# delete cluster namespace
kubectl delete ns ${CLUSTER_NAME}
