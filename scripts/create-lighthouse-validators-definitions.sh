#!/bin/bash

################################################################################
# This a utility to generate lighthouse validators definitions as k8s configmaps
################################################################################

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit
fi

CLUSTER_NAME=$1

# download cluster config
mkdir -p ./.charon/${CLUSTER_NAME}
# gcloud storage cp -r gs://charon-clusters-config/${CLUSTER_NAME} ./.charon/
aws s3 cp --recursive s3://charon-clusters-config/${CLUSTER_NAME} ./.charon/${CLUSTER_NAME}

definitions_dir="./.charon/${CLUSTER_NAME}/lighthouse-validators-definitions"

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./envs/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# create lighthouse validators definitions
mkdir -p .charon/${CLUSTER_NAME}/lighthouse-validators-definitions
i=0
INDEX=0
while [[ $i -lt "$NODES" ]]; do
    node_file="${definitions_dir}/vc-node-$i.yaml"
    echo "---" > $node_file

    while [[ $INDEX -lt "$NUM_VALIDATORS" ]]; do
      KEY=$(cat ./.charon/${CLUSTER_NAME}/node$i/validator_keys/keystore-$INDEX.json | jq -r ".pubkey")

      cat <<END >> $node_file
- enabled: true
  voting_public_key: 0x$KEY
  type: local_keystore
  voting_keystore_path: /data/lighthouse/validator_keys/keystore-$INDEX.json
  voting_keystore_password_path: /data/lighthouse/validator_keys/keystore-$INDEX.txt
  suggested_fee_recipient: ${PROPOSER_DEFAULT_FEE_RECIPIENT}
END
      ((INDEX=INDEX+1))
    done

    ((i=i+1))
    INDEX=0
done

# gcloud storage cp -R ${definitions_dir} gs://charon-clusters-config/${CLUSTER_NAME}
aws s3 cp --recursive ${definitions_dir} s3://charon-clusters-config/${CLUSTER_NAME}/lighthouse-validators-definitions

# delete cluster config before exit
rm -rf ./.charon/${CLUSTER_NAME}
