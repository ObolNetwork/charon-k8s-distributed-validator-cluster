
#!/bin/bash
# set -uo pipefail
CLUSTER_NAME_PREFIX="relay-dkg-perf"

COPY_FROM_CLUSTER_NAME="charon-dkg-test"

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./envs/charon-dkg-test.env)
IFS=$OLDIFS

INDEX=0
for ((i = 1; i <= 10; i++)); do
docker run -it --rm -v "$PWD:/opt/charon" obolnetwork/charon:${CHARON_VERSION} create cluster --fee-recipient-addresses="0xBc7c960C1097ef1Af0FD32407701465f3c03e407" --nodes=${NODES} --network=${NETWORK} --withdrawal-addresses="0xBc7c960C1097ef1Af0FD32407701465f3c03e407" --name=test --num-validators=${NUM_VALIDATORS}
# Set the path to the cluster-lock.json file
cluster_lock_file="node0/cluster-lock.json"

# Check if the cluster-lock.json file exists
if [ ! -f "$cluster_lock_file" ]; then
  echo "Error: cluster-lock.json file not found in node0 folder."
  exit 1
fi

# Use jq to extract the "enr" fields from the cluster-lock.json file
enrs_list=$(jq -r '.cluster_definition.operators[].enr' "$cluster_lock_file")

# Join the ENRs into a comma-separated list within double quotes
enrs_list_formatted="${enrs_list//$'\n'/\",\"}"

# Set the operator ENRs
operator_enrs="--operator-enrs=\"$enrs_list_formatted\""

# Run the Create DKG command with the generated ENRs
docker run -it --rm -v "$PWD:/opt/charon" obolnetwork/charon:${CHARON_VERSION} create dkg --fee-recipient-addresses="0xBc7c960C1097ef1Af0FD32407701465f3c03e407" --name=test --network=${NETWORK} --num-validators=1 --withdrawal-addresses="0xBc7c960C1097ef1Af0FD32407701465f3c03e407" $operator_enrs

# Delete everything except charon-enr-private-key in each node* folder, push the definition file
for folder in node*; do
  if [ -d "$folder" ]; then
    # Remove all files and subdirectories except charon-enr-private-key
    find "$folder" -mindepth 1 -maxdepth 1 ! -name "charon-enr-private-key" -exec rm -rf {} \;
    
    # Copy .charon/cluster-definition.json into each folder
    cp .charon/cluster-definition.json "$folder/cluster-definition.json"
  fi
done


CLUSTER_NAME="${CLUSTER_NAME_PREFIX}-${i}"
# create the namespace
nsStatus=$(kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "$nsStatus" ]; then
    echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
    kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
fi

j=0
while [[ $j -lt "$NODES" ]]
do
    kubectl -n ${CLUSTER_NAME} create configmap node${j}-charon-dkg-config --from-file=node${j} --dry-run=client -o yaml | kubectl apply -f -
    ((j=j+1))
done

# Remove node* folders
rm -rf node* .charon

done