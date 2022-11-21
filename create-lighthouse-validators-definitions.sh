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

ns=$CLUSTER_NAME

# construct the validators definitions yaml file from the charon keys
mkdir .charon/$CLUSTER_NAME-lighthouse-definitions
i=0
INDEX=0
while [[ $i -lt "$NODES" ]]; do
    tee -a .charon/$CLUSTER_NAME-lighthouse-definitions/vc-node-$i.yaml << END
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vc$i-lighthouse
  namespace: $CLUSTER_NAME
data:
  validator_definitions.yml: |
    ---
END
    while [[ $INDEX -lt "$NUM_VALIDATORS" ]]; do
      KEY=$(cat .charon/cluster/node$i/validator_keys/keystore-$INDEX.json | jq -r ".pubkey")
      tee -a .charon/$CLUSTER_NAME-lighthouse-definitions/vc-node-$i.yaml << END
    - enabled: true
      voting_public_key: 0x$KEY
      type: local_keystore
      voting_keystore_path: /data/lighthouse/validator_keys/keystore-$INDEX.json
      voting_keystore_password_path: /data/lighthouse/validator_keys/keystore-$INDEX.txt
      suggested_fee_recipient: 0x9FD17880D4F5aE131D62CE6b48dF7ba7D426a410
END
        ((INDEX=INDEX+1))
    done
    ((i=i+1))
    INDEX=0
done

# create the namespace
nsStatus=`kubectl get namespace $ns --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster ($ns) not found, creating a new one."
    kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=$ns

# create the lighthouse validators definitions configmaps
kubectl apply -f .charon/$CLUSTER_NAME-lighthouse-definitions/
