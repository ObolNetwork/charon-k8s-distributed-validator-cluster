#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit
fi

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.env-$1)
IFS=$OLDIFS

ns=$CLUSTER_NAME

# create the namespace
nsStatus=`kubectl get namespace $ns --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster ($ns) not found, creating a new one."
    kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=$ns

kubectl -n $ns create secret generic cluster-lock --from-file=cluster-lock.json=./.charon/$CLUSTER_NAME/cluster-lock.json --dry-run=client -o yaml | kubectl apply -f -

i=0
while [[ $i -lt "$NODES" ]]
do
    files=""
    for secret in ./.charon/$CLUSTER_NAME/node${i}/validator_keys/*; do
        files="$files --from-file=./.charon/$CLUSTER_NAME/node${i}/validator_keys/$(basename $secret)"
    done
    kubectl -n $ns create secret generic node${i}-validators $files --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n $ns create secret generic node${i}-charon-enr-private-key --from-file=charon-enr-private-key=./.charon/$CLUSTER_NAME/node${i}/charon-enr-private-key --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n $ns create secret generic node${i}-cluster-lock --from-file=cluster-lock.json=./.charon/$CLUSTER_NAME/cluster-lock.json --dry-run=client -o yaml | kubectl apply -f -
    ((i=i+1))
done
