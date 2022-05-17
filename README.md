![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">CharonxK8s</h1>

This repository contains Kubernetes manifests to deploy a [charon](https://github.com/ObolNetwork/charon) cluster.

# Project Status
It is still early days for the Obol Network and everything is under active development. It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

# Charon Cluster Deployment
The cluster consists of 3 charon nodes, 3 Teku validators:
- node0: [Teku](https://github.com/ConsenSys/teku)
- node1: [Teku](https://github.com/ConsenSys/teku)
- node2: [Teku](https://github.com/ConsenSys/teku)

Please follow the following instructions to deploy a charon devnet to Kubernetes.

## Prerequisites
- Ensure having a functional k8s cluster:
    - To run a local cluster, install and start [Minikube](https://minikube.sigs.k8s.io/docs/start).
- Ensure that you have [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Kubernetes 1.20+ - This is the earliest version of Kubernetes tested. Charts may work with earlier versions but it is untested.
- Kubernetes Persistent Volume provisioner support in the underlying infrastructure.
- If you want to deploy the public ingresses for grafana and prometheus, your Kubernetes cluster should have [nginx-ingress](https://kubernetes.github.io/ingress-nginx/), [external-dns](https://github.com/kubernetes-sigs/external-dns), and [cert-manager](https://cert-manager.io/docs/) deployed and functional.

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
> Remember: Do not connect to mainnet! 

> Remember: Please make sure any existing validator has been shut down for at least 2 finalised epochs before starting the charon cluster, otherwise slashing could occur.

## Deploy the cluster
Creates a default cluster with 4 nodes (n=4) and threshold of 3 (t=3) for signature reconstruction.

```
# Deploy charon cluster
cd charon-k8s
export CN=<cluster-name>
export BN=<beacon-node-endpoint>
./deploy $CN $BN

# Optional: to deploy ingress and public dns for monitoring
export CN=<cluster-name>
export DNSNAME=<dns-name>
./deploy-ingress $CN $DNSNAME
example:
export CN="charon"
export DNSNAME="gcp.obol.tech"
./deploy-ingress $CN $DNSNAME
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
export CN=<cluster-name>
./cleanup.sh $CN
```
