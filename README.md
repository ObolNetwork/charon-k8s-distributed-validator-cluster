# Charon Kubernetes Deployment

Run a *simnet* [charon](https://github.com/ObolNetwork/charon) distributed validator cluster using Kubernetes deployment manifests.

> Simnet is a simulation network demonstrating the features available in charon. It uses a mocked beacon-node  
> and a mixture of mock and real (Lighthouse and Teku) validator clients.

## Prerequisites
Ensure you have kubectl and gloud CLI installed and authenticated [Instructions](https://github.com/ObolNetwork/obol-infrastructure/tree/main/environments/development)

## Usage
```sh
git clone git@github.com:ObolNetwork/charon-k8s.git
./deploy.sh <namespace>
```

## View Logs
```sh
kubectl -n <namespace> logs -f deploy/node0
kubectl -n <namespace> logs -f deploy/node1
kubectl -n <namespace> logs -f deploy/node2
kubectl -n <namespace> logs -f deploy/node3
kubectl -n <namespace> logs -f deploy/prometheus
kubectl -n <namespace> logs -f deploy/grafana
```

## Access Prometheus & Grafana
- Open a terminal tab
```sh
kubectl -n <namespace> port-forward deployment/prometheus 9091:9090
```
- Open another terminal tab
```sh
kubectl -n <namespace> port-forward deployment/grafana 3001:3000
```
- Open a browser and access prometheus [http://localhost:9091]
- Open a browser and access grafana [http://localhost:3001]

## Cleanup
```sh
kubectl delete ns <namespace>
```
