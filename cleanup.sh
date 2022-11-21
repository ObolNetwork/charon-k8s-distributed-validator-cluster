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

# check if the cluster namespace exists
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Cluster (${CLUSTER_NAME}) is not found, please use an existing cluster"
    exit 1;
fi

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

echo "deleting cluster: ${CLUSTER_NAME}"

# delete validator clients
node_index=0
while [[ $node_index -lt "$NODES" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
if [[ "$node_index" -le "$NODES/2" ]] && [[ $MIX_VCS == "true" ]]
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

# delete charon nodes
node_index=0
while [[ $node_index -lt "$NODES" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
export CHARON_VERSION=$CHARON_LATEST_REL
eval "cat <<EOF
$(<./templates/charon.yaml)
EOF
" | kubectl delete -f -
((node_index=node_index+1))
done
