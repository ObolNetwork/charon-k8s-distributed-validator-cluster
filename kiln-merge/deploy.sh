export ETH_CLIENTS_AUTH_JWT=7baaef68c175c4528419b5d8a54a2ce53b119e29efc3b4c2d8b12ec3190fde2e

helmsman -f kiln.yaml --show-diff --apply

helmsman --no-banner -f kiln.yaml --destroy
kubectl -n kiln delete pvc --all

curl http://34.72.238.199/eth/v1/config/spec | jq .
