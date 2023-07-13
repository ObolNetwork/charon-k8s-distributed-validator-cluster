#!/bin/bash

set -uo pipefail

CLUSTER_NAME_PREFIX="relay-dkg-perf"
NUM_ITERATIONS=100

for ((INDEX = 1; INDEX <= NUM_ITERATIONS; INDEX++)); do
    CLUSTER_NAME="${CLUSTER_NAME_PREFIX}-${INDEX}"
    
    # create the namespace
    nsStatus=$(kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
    if [ -z "$nsStatus" ]; then
        echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
        kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
    fi
    
    # download cluster config
    mkdir -p ./.charon
    gcloud storage cp -r gs://charon-clusters-config/${CLUSTER_NAME_PREFIX}/${CLUSTER_NAME} ./.charon/
    # Calculate the number of nodes
    NODES=$(find ./.charon/${CLUSTER_NAME}/ -type d -name "node*" | wc -l)
    
    # set current namespace
    kubectl config set-context --current --namespace=${CLUSTER_NAME}
    
    i=0
    while [[ $i -lt "$NODES" ]]
    do
        kubectl -n ${CLUSTER_NAME} create secret generic node${i}-charon-enr-private-key --from-file=charon-enr-private-key=./.charon/${CLUSTER_NAME}/node${i}/charon-enr-private-key --dry-run=client -o yaml | kubectl apply -f -
        kubectl -n ${CLUSTER_NAME} create secret generic node${i}-cluster-definition --from-file=cluster-definition.json=./.charon/${CLUSTER_NAME}/cluster-definition.json --dry-run=client -o yaml | kubectl apply -f -
        ((i=i+1))
        #exit loop after first iteration
        # break
    done
    
    # delete cluster config before exit
    rm -rf ./.charon/${CLUSTER_NAME}
    
    echo "Iteration $INDEX completed"
done

echo "Script completed"
