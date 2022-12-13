![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes manifests to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

Please follow the following instructions to deploy a charon cluster to Kubernetes.

# Prerequisites
Ensure having [`docker`](https://docs.docker.com/get-docker/), a functional [`Kubernetes`](https://kubernetes.io/) cluster and [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) installed.

# Deployment Steps
## Cluster Configuration
```sh
cp .env.sample <cluster_name>.env
```
Edit the required configruation values in the .env file.

## Generate Validators Keystores
```sh
docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.12.0 create cluster --withdrawal-address="0x000000000000000000000000000000000000dead" --num-validators=1 --nodes=5 --threshold=3 --network=goerli
# rename cluster director to the <cluster_name>
mv .charon/cluster .charon/<cluster_name>
```

## Upload Cluster Config to GCS
```sh
gcloud storage -m cp -R .charon/<cluster_name> gs://charon-clusters-config
gcloud storage cp gs://charon-clusters-config/<cluster_name>/<cluster_name>.env .
```

## Generate Lighthouse validators definitions
```sh
./generate-lighthouse-validators-definitions.sh <cluster-name>
```

## Create Kubernetes Secrets
```sh
./create-k8s-secrets.sh <cluster-name>
```

## Deploy Charon Cluster
```sh
./deploy.sh <cluster-name>
```

## Deploy Charon Canary Cluster
```sh
./canary-deploy.sh <cluster-name>
```
