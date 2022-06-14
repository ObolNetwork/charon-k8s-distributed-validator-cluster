#!/bin/bash

# override the env vars with the needed env vars for the *-deployment.yaml files
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

delete_manifest () {
eval "cat <<EOF
$(<$1)
EOF
" | kubectl delete -f -
}

# check if the cluster namespace exists
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Cluster (${CLUSTER_NAME}) is not found, please use an existing cluster"
    exit 1;
fi

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

# delete charon manifests
manifests_dir="./manifests"
for manifest in "$manifests_dir"/*
do
  delete_manifest "$manifest"
done

# delete ingresses
ingresses_dir="./manifests/ingresses"
if [ "$DEPLOY_INGRESS" = true ]; then
  for manifest in "$ingresses_dir"/*
  do
    delete_manifest "$manifest"
  done
fi

# delete charon shared pv/pvc
eval "cat <<EOF
$(<./manifests/shared-pv/shared-pv.yaml)
EOF
" | kubectl delete -f -

# delete charon cluster namespace
kubectl delete ns ${CLUSTER_NAME}
