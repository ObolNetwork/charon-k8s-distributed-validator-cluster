![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes manifests to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

# Project status
It is still early days for the Obol Network and everything is under active development. It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

# Charon cluster deployment
The cluster consists of 4 charon nodes (node0-3) and 4 Teku validators:
- vc0-teku: [Teku](https://github.com/ConsenSys/teku)
- vc1-teku: [Teku](https://github.com/ConsenSys/teku)
- vc2-teku: [Teku](https://github.com/ConsenSys/teku)
- vc3-teku: [Teku](https://github.com/ConsenSys/teku)

Please follow the following instructions to deploy a charon devnet to Kubernetes.

## Prerequisites
- Ensure having a functional k8s cluster:
    - To run a local cluster, install and start [Minikube](https://minikube.sigs.k8s.io/docs/start).
- Ensure that you have [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Kubernetes 1.20+ - This is the earliest version of Kubernetes tested. Charts may work with earlier versions but it is untested.
- Kubernetes Persistent Volume provisioner support in the underlying infrastructure.
- If you want to deploy the public ingresses for grafana and prometheus, your Kubernetes cluster should have [nginx-ingress](https://kubernetes.github.io/ingress-nginx/), [external-dns](https://github.com/kubernetes-sigs/external-dns), and [cert-manager](https://cert-manager.io/docs/) deployed and functioning.

## Copy validator keys
This step assumes that you have an active validator client keys. 

Checkout charon-k8s repository:
```
git clone git@github.com:ObolNetwork/charon-k8s.git
```

Copy the keystore and password files as the following:
```
# Each keystore-*.json requires a keystore-*.txt file containing the password.

cd charon-k8s
mkdir split_keys

cp path/to/existing/keys/keystore-*.json split_keys/keystore.json

cp path/to/passwords/keystore-*.txt split_keys/keystore.txt
```
> Remember: Do not connect to mainnet! 

> Remember: Please make sure any existing validator has been shut down for at least 2 finalised epochs before starting the charon cluster, otherwise slashing could occur.

## Configure
Prepare an environment variable file (requires at minimum an Infura API endpoint for your chosen chain)
```sh
cp .env.sample .env
```

## Deploy
Creates a default cluster with 3 nodes (n=3) and threshold of 2 (t=2) for signature reconstruction.

```sh
./deploy.sh
```

## Cleanup
Delete the deployed cluster resouces:
```sh
./cleanup.sh
```
