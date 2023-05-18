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
mkdir -p ./.charon
gcloud storage cp -r gs://charon-clusters-config/${CLUSTER_NAME} ./.charon/

definitions_dir="./.charon/${CLUSTER_NAME}/lighthouse-validators-definitions"

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.charon/${CLUSTER_NAME}/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# create lighthouse validators definitions
mkdir -p .charon/${CLUSTER_NAME}/lighthouse-validators-definitions
i=0
INDEX=0
while [[ $i -lt "$NODES" ]]; do
    tee -a ${definitions_dir}/vc-node-$i.yaml << END
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vc$i-lighthouse
  namespace: ${CLUSTER_NAME}
data:
  validator_definitions.yml: |
    ---
END
    while [[ $INDEX -lt "$NUM_VALIDATORS" ]]; do
      KEY=$(cat ./.charon/${CLUSTER_NAME}/node$i/validator_keys/keystore-$INDEX.json | jq -r ".pubkey")
      tee -a ${definitions_dir}/vc-node-$i.yaml << END
    - enabled: true
      voting_public_key: 0x$KEY
      type: local_keystore
      voting_keystore_path: /data/lighthouse/validator_keys/keystore-$INDEX.json
      voting_keystore_password_path: /data/lighthouse/validator_keys/keystore-$INDEX.txt
      suggested_fee_recipient: 0xf6f9eaE9FF22219B933744049EB89f2f0da77baC
END
        ((INDEX=INDEX+1))
    done
    ((i=i+1))
    INDEX=0
done

gcloud storage cp -R ${definitions_dir} gs://charon-clusters-config/${CLUSTER_NAME}

# delete cluster config before exit
#rm -rf ./.charon/${CLUSTER_NAME}
