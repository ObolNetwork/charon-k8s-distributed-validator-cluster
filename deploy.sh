#!/bin/bash

# override the env vars with the needed env vars for the *-deployment.yaml files
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

deploy_manifest () {
eval "cat <<EOF
$(<$1)
EOF
" | kubectl apply -f -
}

# create the namespace
nsStatus=`kubectl get namespace $CLUSTER_NAME --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster ($CLUSTER_NAME) not found, creating a new one."
    kubectl create namespace $CLUSTER_NAME --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=$CLUSTER_NAME

# create vc keystore secrets
echo $KEY_STORE >> keystore.json
echo $KEY_STORE_PASSWORD >> keystore.txt
kubectl create secret generic keystore --from-file=keystore=./keystore.json --from-file=password=./keystore.txt 2>/dev/null && rm keystore*

# deploy bootnode
eval "cat <<EOF
$(<./manifests/cluster/bootnode.yaml)
EOF
" | kubectl apply -f -
sleep 15

# deploy nodes
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./manifests/cluster/node.yaml)
EOF
" | kubectl apply -f -
((node_index=node_index+1))
sleep 15
done

# deploy monitoring
ingresses_dir="./manifests/monitoring"
for manifest in "$ingresses_dir"/* 
do
  deploy_manifest "$manifest"
done

# deploy ingresses
ingresses_dir="./manifests/ingresses"
if [ "$DEPLOY_INGRESS" = true ]; then
  for manifest in "$ingresses_dir"/*
  do
    deploy_manifest "$manifest"
  done
fi
