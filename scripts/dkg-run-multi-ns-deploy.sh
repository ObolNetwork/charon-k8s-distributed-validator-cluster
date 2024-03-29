#!/bin/bash

if [ "$1" = "" ]; then
  echo "Usage: $0 <cluster name to be deployed>"
  exit -1
fi

set -uo pipefail

COPY_FROM_CLUSTER_NAME="charon-dkg-test"
CLUSTER_NAME=$1

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./envs/${COPY_FROM_CLUSTER_NAME}.env)
IFS=$OLDIFS

# Check if the custom P2P relays argument is provided
# if [ "$2" != "" ]; then
#   CHARON_P2P_RELAYS=$2
# fi

# rm ./${COPY_FROM_CLUSTER_NAME}.env

# create the namespace
nsStatus=$(kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "$nsStatus" ]; then
    echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
    kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
fi

# Deploy dkg jobs

node_index=0
total_jobs=${NODES}
for ((i=0; i<total_jobs; i++)); do
  export NODE_NAME="node$node_index"
  echo "Deploying job for node: ${NODE_NAME}"
  eval "cat <<EOF
$(<./templates/charon-dkg-job-map.yaml)
EOF
" | kubectl apply -f - -n ${CLUSTER_NAME} > /dev/null & 
  ((node_index=node_index+1))
done

echo "Jobs deployed for cluster: ${CLUSTER_NAME}"
