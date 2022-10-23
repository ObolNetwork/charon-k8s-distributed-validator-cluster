#!/bin/bash

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

# create the namespace
nsStatus=`kubectl get namespace $CLUSTER_NAME --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster ($CLUSTER_NAME) not found, creating a new one."
    kubectl create namespace $CLUSTER_NAME --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=$CLUSTER_NAME

# deploy charon nodes
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./templates/charon.yaml)
EOF
" | kubectl apply -f -
((node_index=node_index+1))
done

# deploy validator clients
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./templates/teku-vc.yaml)
EOF
" | kubectl apply -f -
((node_index=node_index+1))
done
