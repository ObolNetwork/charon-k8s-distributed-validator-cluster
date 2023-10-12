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
export $(< ./${CLUSTER_NAME}.env)
IFS=$OLDIFS

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

i=0
while [[ $i -lt "$NODES" ]]
do
    kubectl -n ${CLUSTER_NAME} create secret generic node${i}-web3signer-keystore --from-file=keystore.yaml=./utils/go-utils/web3signerHex/${CLUSTER_NAME}-node${i}.yaml --dry-run=client -o yaml | kubectl apply -f -
    ((i=i+1))
done

