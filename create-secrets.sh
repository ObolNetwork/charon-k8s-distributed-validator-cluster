#!/bin/bash

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

ns=$CLUSTER_NAME
i=0
kubectl -n $ns create secret generic cluster-lock --from-file=cluster-lock.json=./.charon/cluster/cluster-lock.json
while [[ $i -lt "$CLUSTER_SIZE" ]]
do
    kubectl -n $ns create secret generic node${i}-keystore --from-file=keystore-0.json=./.charon/cluster/node${i}/validator_keys/keystore-0.json
    kubectl -n $ns create secret generic node${i}-password --from-file=keystore-0.txt=./.charon/cluster/node${i}/validator_keys/keystore-0.txt
    kubectl -n $ns create secret generic node${i}-charon-enr-private-key --from-file=charon-enr-private-key=./.charon/cluster/node${i}/charon-enr-private-key
    ((i=i+1))
done
