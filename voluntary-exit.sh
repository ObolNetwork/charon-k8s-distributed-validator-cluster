#!/bin/bash

set -uo pipefail

# override the env vars
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

# create the namespace
nsStatus=`kubectl get namespace $CLUSTER_NAME --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster ($CLUSTER_NAME) not found, creating a new one."
    kubectl create namespace $CLUSTER_NAME --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=$CLUSTER_NAME

echo "deploy cluster: ${CLUSTER_NAME}"

# deploy charon nodes
node_index=0
while [[ $node_index -lt "$NODES" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
export CHARON_VERSION=$CHARON_LATEST_REL
eval "cat <<EOF
$(<./templates/charon.yaml)
EOF
" | kubectl apply -f -
((node_index=node_index+1))
done

# deploy validator clients
node_index=0
while [[ $node_index -lt "$NODES" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
if [[ "$node_index" -le "$NODES/2" ]] && [[ $MIX_VCS == "true" ]]
then
eval "cat <<EOF
$(<./templates/teku-vc-exit.yaml)
EOF
" | kubectl apply -f -
else
eval "cat <<EOF
$(<./templates/teku-vc-exit.yaml)
EOF
" | kubectl apply -f -
fi
((node_index=node_index+1))
done

# deploy prometheus agent
export CLUSTER_NAME="$CLUSTER_NAME"
export MONITORING_TOKEN="$MONITORING_TOKEN"
eval "cat <<EOF
$(<./templates/prom-agent.yaml)
EOF
" | kubectl apply -f -