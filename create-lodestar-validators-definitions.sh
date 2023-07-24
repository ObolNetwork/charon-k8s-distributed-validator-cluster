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
gcloud storage cp -r gs://charon-clusters-config/${CLUSTER_NAME} ./.charon/

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.charon/${CLUSTER_NAME}/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# create docker compose file for lodestar validators definitions

# The number of nodes you have
NODES=$(find ./.charon/${CLUSTER_NAME}/ -type d -name "node*" | wc -l)

# Set your network name
NETWORK="goerli"

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
    image: chainsafe/lodestar:v1.9.2
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

gcloud storage cp -R ${definitions_dir} gs://charon-clusters-config/${CLUSTER_NAME}

# delete cluster config before exit
rm -rf ./.charon/${CLUSTER_NAME}
rm -rf ./docker-compose.yml
