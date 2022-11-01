![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes templates to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

# Project status
It is still early days for the Obol Network and everything is under active development. It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

Please follow the following instructions to deploy a charon devnet to Kubernetes.

# Prerequisites
- Ensure having a functional k8s cluster:
    - To run a local cluster, install and start [Minikube](https://minikube.sigs.k8s.io/docs/start).
- Ensure that you have [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Kubernetes 1.20+ - This is the earliest version of Kubernetes tested. Charts may work with earlier versions but it is untested.
- Kubernetes Persistent Volume provisioner support in the underlying infrastructure.

# Create Keystores
Validators keystores should be generated before hand using charon CLI. For example this command will generate the required keystores for a charon cluster with 4 nodes and 1 validators.
```sh
charon create cluster --num-validators=1 --withdrawal-address=0x9FD17880D4F5aE131D62CE6b48dF7ba7D426a410 --network=kiln
```
Make sure the generataed .charon directory is located beside the `create-keys.sh` script, then execute it to populate the keys into k8s secrets:
```sh
./create-keys.sh
```

# Configure
Prepare an environment variable file:
```sh
cp .env.sample .env
```
Add the required configruation values to the .env file.

# Deploy
Deploy a charon cluster:

```sh
./deploy.sh
```

# Cleanup
Delete a charon cluster:
```sh
./cleanup.sh
```

# Enhancements
- Create public helm charts to deploy charon bootnode and nodes

