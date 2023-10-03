#!/bin/bash

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit
fi

CLUSTER_NAME=$1

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ../envs/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# create the namespace
nsStatus=$(kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "$nsStatus" ]; then
    echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
    kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
fi

# download cluster config
mkdir -p ./.charon
gcloud storage cp -r gs://charon-clusters-config/${CLUSTER_NAME} ./.charon/

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

i=0
while [[ $i -lt "$NODES" ]]
do
    kubectl -n ${CLUSTER_NAME} create secret generic node${i}-charon-enr-private-key --from-file=charon-enr-private-key=./.charon/${CLUSTER_NAME}/node${i}/charon-enr-private-key --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n ${CLUSTER_NAME} create secret generic node${i}-cluster-definition --from-file=cluster-definition.json=./.charon/${CLUSTER_NAME}/cluster-definition.json --dry-run=client -o yaml | kubectl apply -f -
    ((i=i+1))
done

# delete cluster config before exit
rm -rf ./.charon/${CLUSTER_NAME}
