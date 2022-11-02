#!/bin/bash

# override the env vars
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

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

# deploy validator clients
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
if [[ "$node_index" -le "$CLUSTER_SIZE/2" ]] && [[ $MIX_VCS == "true" ]]
then
eval "cat <<EOF
$(<./templates/lighthouse-vc.yaml)
EOF
" | kubectl delete -f -
else
eval "cat <<EOF
$(<./templates/teku-vc.yaml)
EOF
" | kubectl delete -f -
fi
((node_index=node_index+1))
done

# deploy charon nodes
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./templates/charon.yaml)
EOF
" | kubectl delete -f -
((node_index=node_index+1))
done
