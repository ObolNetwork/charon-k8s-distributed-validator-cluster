#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit -1
fi

set -uo pipefail

CLUSTER_NAME=$1

gcloud storage cp gs://charon-clusters-config/tokens/tokens.env .
# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./${CLUSTER_NAME}.env)
export $(< ./tokens.env)
IFS=$OLDIFS
rm ./tokens.env

# create the namespace
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
    kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

echo "deploying cluster: ${CLUSTER_NAME}"

# Deploy charon nodes
IFS=','
read -a versions <<< "$CHARON_VERSIONS"
node_index=0
for version in "${versions[@]}"
do
  if [[ $node_index -lt $CHARON_FUZZ_NODES ]]; then
    # For the CHARON_FUZZ_NODES nodes, use charon-fuzzer.yaml
    export NODE_NAME="node$node_index"
    export VC_INDEX="vc$node_index"
    export CHARON_VERSION=$version
    eval "cat <<EOF
$(<./templates/charon-fuzzer.yaml)
EOF
" | kubectl apply -f -
  else
    # For the rest of the nodes, use charon.yaml
    export NODE_NAME="node$node_index"
    export VC_INDEX="vc$node_index"
    export CHARON_VERSION=$version
    eval "cat <<EOF
$(<./templates/charon.yaml)
EOF
" | kubectl apply -f -
  fi
  ((node_index=node_index+1))
done

# Deploy Validator client of required type for each charon node. 
IFS=','
read -a vcs <<< "$VC_TYPES"
node_index=0
for vc in "${vcs[@]}"
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
if [ $vc -eq 0 ]; then
eval "cat <<EOF
$(<./templates/teku-vc.yaml)
EOF
" | kubectl apply -f -
elif [ $vc -eq 1 ]; then
eval "cat <<EOF
$(<./templates/lighthouse-vc.yaml)
EOF
" | kubectl apply -f -
elif [ $vc -eq 2 ]; then
envsubst < ./templates/lodestar-vc.yaml | kubectl apply -f -
elif [ $vc -eq 3 ]; then	
envsubst < ./templates/nimbus-vc.yaml | kubectl apply -f -
fi
((node_index=node_index+1))
done

# deploy prometheus agent
export CLUSTER_NAME="${CLUSTER_NAME}"
export MONITORING_TOKEN="$MONITORING_TOKEN"
eval "cat <<EOF
$(<./templates/prom-agent.yaml)
EOF
" | kubectl apply -f -
