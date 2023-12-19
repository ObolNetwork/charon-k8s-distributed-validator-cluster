#!/bin/bash

################################################################################
# This a utility to generate lodestar validators definitions as k8s configmaps
################################################################################

set -uo pipefail

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit
fi

CLUSTER_NAME=$1

# create lodestar validators definitions dir
lodestar_dir="./config/vc/lodestar"
definitions_dir="./.charon/${CLUSTER_NAME}/lodestar-validators-definitions"

# download cluster config
# mkdir -p ./.charon
mkdir -p ${definitions_dir}

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./envs/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# create docker compose file for lodestar validators definitions
chmod +x ${lodestar_dir}/import-script.sh

# Create the main part of the Docker Compose file
cat << EOF > docker-compose.yml
version: '3'
services:
EOF

# Loop to generate services for each node
for ((i = 0; i < NODES; i++)); do
    cat << EOF >> docker-compose.yml
  lodestar-node$i:
    image: chainsafe/lodestar:${LODESTAR_VERSION}
    entrypoint: /opt/scripts/import-script.sh
    volumes:
      - ${definitions_dir}/node$i:/opt/data
      - ./.charon/${CLUSTER_NAME}/node$i/validator_keys:/validator_keys  # Mount validator_keys for each node
      - ${lodestar_dir}/import-script.sh:/opt/scripts/import-script.sh
    environment:
      NETWORK: ${NETWORK}
    restart: no
EOF
done

# Run the Docker Compose stack in the background
docker-compose up

# gcloud storage cp -R ${definitions_dir} gs://charon-clusters-config/${CLUSTER_NAME}
aws s3 cp --recursive ${definitions_dir} s3://charon-clusters-config/${CLUSTER_NAME}

# delete cluster config before exit
rm -rf ./.charon/${CLUSTER_NAME}
rm -rf ./docker-compose.yml
