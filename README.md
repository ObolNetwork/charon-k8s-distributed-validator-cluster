![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Charon with K8s</h1>

This repository contains the Kubernetes deployment manifests for a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster. It deploys the Kubernetes manifests to Google Kubernetes Engine [GKE](https://cloud.google.com/kubernetes-engine)

# Charon Cluster Deployments on Kubernetes
You can deploy the charon cluster using the following alternatives:
- [Deployment using Mocked Beacon Node (simnet)](#deployment-using-mocked-beacon-node-simnet)
- [Deployment using Real Beacon Node](#real-beacon-node-deployment)

### Project Status
It is still early days for the Obol Network and everything is under active development. It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

### Note about GKE
The manifests in this repo target deployments to GKE. To deploy to another Kubernetes platform, you should modify the following manifests:
- Charon PV - charon-k8s/charon-beacon/bootnode/charon-pv.yaml You need to change the storage class to the proper type that works with your Kubernetes.
- Kiln (optional) - in case you deploy Kiln testnet using the manifests in this repo, you should modify the service manifest kiln-testnet/local-charts/teku-api-service/templates/service.yaml.
## Deployment using Mocked Beacon Node (simnet)
This deployment uses a mocked beacon node to avoid the complexities of depositing stake and waiting for validator activation. It uses custom configuration for slots and epoch timing (1s per slot, 16 slots per epoch). It assigns attestation duties to the simnet 
distributed validator on the first slot of every epoch.

The default cluster consists of 4 charon nodes using a mixture of validator clients:
- node0: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node1: [Teku](https://github.com/ConsenSys/teku)
- node2: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node3: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)

### Prerequisites
Ensure you have the following tools installed before proceeding:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Deploy the cluster
Creates a **simnet** cluster with 4 nodes (n=4) and threshold of 3 (t=3) for signature reconstruction.
```sh
export NAMESPACE=<namespace>
git clone git@github.com:ObolNetwork/charon-k8s.git
cd charon-k8s/charon-simnet
./deploy.sh $NAMESPACE
```

### View deployments logs
View charon nodes logs and validate the deployment:
```sh
kubectl config set-context --current --namespace=$NAMESPACE
kubectl logs -f deploy/node0
kubectl logs -f deploy/node1
kubectl logs -f deploy/node2
kubectl logs -f deploy/node3
kubectl logs -f deploy/prometheus
kubectl logs -f deploy/grafana
```

### Monitoring
The deployment includes monitoring stack (Prometheus and Grafana), both can be accessed as the following:

#### Access Prometheus
```sh
kubectl -n <namespace> port-forward deployment/prometheus 9091:9090
```
Access local [prometheus](http://localhost:9091)

#### Access Grafana
```sh
kubectl -n <namespace> port-forward deployment/grafana 3001:3000
```
Access local [grafana](http://localhost:3001)

### Cleanup
Delete the deployed cluster resouces:
```sh
cd charon-k8s/charon-cluster
./cleanup.sh $NAMESPACE
```

## Real Beacon Node Deployment
This deployment enables you to use a real beancon node endpoint with the charon cluster.

The default cluster consists of 4 charon nodes using a mixture of validator clients:
- node0: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node1: [Teku](https://github.com/ConsenSys/teku) - This node uses a real Teku beacon node end point.
- node2: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node3: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)

### Prerequisites
Ensure you have the following tools installed before proceeding:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [`helm`](https://helm.sh/)
- [`helmsman`](https://github.com/Praqma/helmsman)
- [`helm-diff`](https://github.com/databus23/helm-diff)

### Copy Validator Keys
This step assumes that you have a running validator client node. You will need to copy the keystore and password files for this VC, then charon will be able to split and use them to start the charon cluster nodes.
```
mkdir split_keys
cp path/to/existing/keys/keystore-*.json split_keys/keystore.json
cp path/to/passwords/keystore-*.txt split_keys/keystore.txt
# Each keystore-*.json requires a keystore-*.txt file containing the password.
```
> Remember: Do not connect to main net! 

> Remember: Please make sure any existing validator has been shut down for at least 2 finalised epochs before starting the charon cluster, otherwise slashing could occur.

### Deploy the cluster
Creates a cluster with 4 nodes (n=4) and threshold of 3 (t=3) for signature reconstruction.

```
# Add your beacon node endpoint to the charon configMap
export CHARON_BEACON_NODE_ENDPOINT=<beacon_node_endpoint>
echo "\tCHARON_BEACON_NODE_ENDPOINT: \"t$CHARON_BEACON_NODE_ENDPOINT\"" >> charon-k8s/charon-beacon/bootnode/charon-config.yaml
```

```
# Deploy the cluster
export NAMESPACE=<namespace>
git clone git@github.com:ObolNetwork/charon-k8s.git
cd charon-k8s/charon-beacon
./deploy.sh $NAMESPACE
```

### View deployments logs
View charon nodes logs and validate the deployment:
```sh
kubectl config set-context --current --namespace=$NAMESPACE
kubectl logs -f deploy/node0
kubectl logs -f deploy/node1
kubectl logs -f deploy/node2
kubectl logs -f deploy/node3
kubectl logs -f deploy/prometheus
kubectl logs -f deploy/grafana
```

### Monitoring
The deployment includes monitoring stack (Prometheus and Grafana), both can be accessed as the following:

#### Access Prometheus
```sh
kubectl -n <namespace> port-forward deployment/prometheus 9091:9090
```
Access local [prometheus](http://localhost:9091)

#### Access Grafana
```sh
kubectl -n <namespace> port-forward deployment/grafana 3001:3000
```
Access local [grafana](http://localhost:3001)

### Cleanup
Delete the deployed cluster resouces:
```sh
cd charon-k8s/charon-beacon
./cleanup.sh $NAMESPACE
```

## Optional: Deploy Kiln testnet
Deploy Kiln testnet with Geth and Teku nodes:
```sh
git clone git@github.com:ObolNetwork/charon-k8s.git
cd charon-k8s/kiln-testnet
./deploy.sh
```
> This Kiln testnet deployment is based on the [Public Kiln Testnet Tooling](https://github.com/skylenet/ethereum-k8s-testnets/tree/master/public-merge-kiln)

### View deployments logs
Ensure deployment is successful, and validate kiln geth and teku logs:
```sh
kubectl config set-context --current --namespace=kiln
kubectl logs -f geth-0
kubectl logs -f teku-0
```
### Cleanup
Once done, you can delete kiln deployment:
```sh
cd charon-k8s/kiln-testnet
./cleanup.sh
```
