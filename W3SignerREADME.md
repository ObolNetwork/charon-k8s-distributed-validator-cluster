![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Web3Signer Setup with Hashicorp Vault</h1>

Please follow the following instructions to deploy and use a web3signer.

# Prerequisites
## Cluster Configuration - We assume you already have this ready from the README.md
## Install Vault
```sh
kubectl create namespace vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace
```
## Unseal Vault
Initially, the Vault is sealed. To unseal it, you need to run the following commands:
```sh
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          84s
vault-agent-injector-8585bb47bf-p45gc   1/1     Running   0          84s
```
To get the unseal key and root token, run the following commands:
```sh
kubectl exec -ti vault-0 -n vault -- vault operator init
```
Copy the tokens and keys to a safe place. You will need them later.
Now you need to unseal the vault. To do so, run the following command 3 times with 3 different keys:
```sh
kubectl exec -ti vault-0 -n vault -- vault operator unseal
```
Now the vault is unsealed and ready to use.

## Test Login
Port forward the vault pod to your local machine:
```sh
nohup kubectl port-forward vault-0 8200:8200 -n vault > /dev/null 2>&1 &
export VAULT_ADDR=http://127.0.0.1:8200
```

## Upload Keys to Vault
Navigate to the `./utils/go-utils/web3signerHex` directory and run the following commands:
```sh
cat >> .env
VAULT_TOKEN="enter the token you had saved earlier"
CTRL+D
```
Now run the following command to upload the keys to the vault:
Note: You need to run this command for each ```charon``` node (assuming you have the CDVC or CDVN node folders)
```sh
go run main.go ./<cluster-name>/node0/validator_keys <cluster-name>-node0
go run main.go ./<cluster-name>/node1/validator_keys <cluster-name>-node1
... and likewise for the other nodes
```
When complete, it displays the following message(s):
```sh
Private key uploaded to Vault successfully
YAML data saved to node0.yaml
```
Now you can check the vault to see if the keys are uploaded successfully


# Deployment Steps

## Create Kubernetes Web3Signer Secrets with the Vault yaml filed returned from previous step
Navigate to Project root folder
```sh
./scripts/create-web3signer-secrets.sh <cluster-name>
```
If successful, it displays the following message, you should see the secret
```sh
kubectl get secrets -n <cluster-name>
``` 
example
```sh
node0-web3signer-keystore
node1-web3signer-keystore
etc
```

## Deploy Charon Cluster
```sh
./deploy-cluster-with-charon-tag.sh <cluster-name> <commit-sha>
```
