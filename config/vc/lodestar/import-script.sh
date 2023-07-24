#!/bin/sh

for f in /validator_keys/keystore-*.json; do
    echo "Importing key ${f}"

    # Import keystore with password.
    node /usr/app/packages/cli/bin/lodestar validator import \
        --dataDir="/opt/data" \
        --network="$NETWORK" \
        --importKeystores="$f" \
        --importKeystoresPassword="${f//json/txt}"
done

echo "Imported all keys"