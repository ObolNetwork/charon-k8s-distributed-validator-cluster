![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes manifests to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

# Project Status
It is still early days for the Obol Network and everything is under active development. It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

# Charon Cluster Deployment
The cluster consists of 4 charon nodes, 1 mock validator, 3 Teku validators, and 1 beacon node:
- node0: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node1: [Teku](https://github.com/ConsenSys/teku)
- node2: [Teku](https://github.com/ConsenSys/teku)
- node3: [Teku](https://github.com/ConsenSys/teku)

Please follow the following instructions to deploy a charon devnet to Kubernetes.

## Prerequisites
- Ensure having a functional k8s cluster: You can deploy a local k8s cluster using [Minikube](https://minikube.sigs.k8s.io/docs/start, or using a public cloud provider such as (GKE, EKS, AKS, or DOKS).
- Ensure that you have [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Kubernetes 1.20+ - This is the earliest version of Kubernetes tested. Charts may work with earlier versions but it is untested.
- Kubernetes Persistent Volume provisioner support in the underlying infrastructure.

## Copy Validator Keys
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
> Remember: Do not connect to main net! 

> Remember: Please make sure any existing validator has been shut down for at least 2 finalised epochs before starting the charon cluster, otherwise slashing could occur.

## Deploy the cluster
Creates a default cluster with 4 nodes (n=4) and threshold of 3 (t=3) for signature reconstruction.

```
# Deploy the cluster
cd charon-k8s
export NS=<namespace>
export BN=<beacon-node-endpoint>

# For example:
# export NS="charon3"
# export BN="https://sdfsdfdsfwper8923423:sfskldfjkds8924723@eth2-beacon-prater.infura.io/"

./deploy $NS $BN
```

## View deployments logs
View charon nodes logs and validate the deployment:
```sh
kubectl config set-context --current --namespace=$NAMESPACE

kubectl logs -f deploy/nodeN (node0, node1, ..., nodeN)

kubectl logs -f deploy/vcN-teku (vc1-teku, vc2-teku, ..., vcN-teku)
```

## Monitoring
The deployment includes monitoring stack (Prometheus and Grafana), and they can be accessed as the following:

### Prometheus
```sh
kubectl -n <namespace> port-forward deployment/prometheus 9091:9090
```
[Local prometheus URL](http://localhost:9091)

### Grafana
```sh
kubectl -n <namespace> port-forward deployment/grafana 3001:3000
```
[Local grafana URL](http://localhost:3001)

# Delete Cluster Resources
Delete the deployed cluster resouces:
```sh
export NS=<namespace>
./cleanup.sh $NS
```
