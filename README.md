![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes manifests to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

Please follow the following instructions to deploy a charon cluster to Kubernetes.

# Prerequisites
Ensure having [`docker`](https://docs.docker.com/get-docker/), a functional [`Kubernetes`](https://kubernetes.io/) cluster and [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) installed.

# Deployment Steps
## Cluster Configuration
```sh
cp .env.sample .env
```
Edit the required configruation values in the .env file.

## Generate Validators Keystores
```sh
docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.11.0 create cluster --withdrawal-address="0x000000000000000000000000000000000000dead" --num-validators=1 --nodes 5 --threshold 3 --network=goerli
```

## Create Kubernetes Secrets
```sh
./create-keys.sh
```

## Create Lighthouse validators definitions
```sh
./create-lighthouse-validators-definitions.sh
```

## Deploy Charon
```sh
./deploy.sh
```
