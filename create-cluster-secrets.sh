#!/bin/bash

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit
fi

CLUSTER_NAME=$1

# download cluster config
gcloud storage cp gs://charon-clusters-config/${CLUSTER_NAME}/${CLUSTER_NAME}.env .

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./${CLUSTER_NAME}.env)
IFS=$OLDIFS

# delete cluster env vars file
rm ./${CLUSTER_NAME}.env

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
    files=""
    for secret in ./.charon/${CLUSTER_NAME}/node${i}/validator_keys/*; do
        files="$files --from-file=./.charon/${CLUSTER_NAME}/node${i}/validator_keys/$(basename $secret)"
    done
    kubectl -n ${CLUSTER_NAME} create secret generic node${i}-validators $files --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n ${CLUSTER_NAME} create secret generic node${i}-charon-enr-private-key --from-file=charon-enr-private-key=./.charon/${CLUSTER_NAME}/node${i}/charon-enr-private-key --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n ${CLUSTER_NAME} create configmap node${i}-cluster-lock --from-file=cluster-lock.json=./.charon/${CLUSTER_NAME}/cluster-lock.json --dry-run=client -o yaml | kubectl apply -f -
    ((i=i+1))
done

# create the lighthouse validators definitions configmaps
kubectl apply -f ./.charon/${CLUSTER_NAME}/lighthouse-validators-definitions/

# delete cluster config before exit
rm -rf ./.charon/${CLUSTER_NAME}
