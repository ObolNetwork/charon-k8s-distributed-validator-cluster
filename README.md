# Charon Cluster Deployment

Run a *simnet* [charon](https://github.com/ObolNetwork/charon) distributed validator cluster using Kubernetes deployment manifests.

> Simnet is a simulation network demonstrating the features available in charon. It uses a mocked beacon-node  
> and a mixture of mock and real (Lighthouse and Teku) validator clients.

## Prerequisites
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`terraform`](https://www.terraform.io/)
- [`doctl`](https://github.com/digitalocean/doctl)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [`helm`](https://helm.sh/)
- [`helmsman`](https://github.com/Praqma/helmsman)
- [`helm-diff`](https://github.com/databus23/helm-diff)

## Deploy Kiln Testnet
```sh
git clone git@github.com:ObolNetwork/charon-k8s.git
./kiln-testnet/deploy.sh
```

## View Kiln Logs
```sh
kubectl config set-context --current --namespace=kiln
kubectl logs -f geth-0
kubectl logs -f teku-0
```

## Copy Validator Keys

```
mkdir split_keys
cp path/to/existing/keys/keystore-*.json split_keys/keystore.json
cp path/to/passwords/keystore-*.txt split_keys/keystore-password.txt
# Each keystore-*.json requires a keystore-*.txt file containing the password.
make split-existing-keys
make up
```
> Remember: Do not connect to main net! 
> Remember: Please make sure any existing validator has been shut down for
> at least 2 finalised epochs before starting the charon cluster,
> otherwise slashing could occur.

## Deploy Charon Cluster
```sh
./charon-cluster/deploy.sh <namespace>
```

## View Charon Logs
```sh
kubectl config set-context --current --namespace=<namespace>
kubectl logs -f deploy/node0
kubectl logs -f deploy/node1
kubectl logs -f deploy/node2
kubectl logs -f deploy/node3
kubectl logs -f deploy/prometheus
kubectl logs -f deploy/grafana
```

## Access Prometheus & Grafana
- Open a terminal tab, then port forward the prometheus deployment to your local:
```sh
kubectl -n <namespace> port-forward deployment/prometheus 9091:9090
```
- Local access [prometheus](http://localhost:9091)

- Open a terminal tab, then port forward the grafana deployment to your local:
```sh
kubectl -n <namespace> port-forward deployment/grafana 3001:3000
```
- Local access [grafana](http://localhost:3001)

## Cleanup
```sh
./charon-cluster/cleanup.sh <namespace>
./kiln-testnet/cleanup.sh
```
