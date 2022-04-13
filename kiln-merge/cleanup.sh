#!/bin/bash

helmsman --no-banner -f kiln.yaml --destroy
kubectl -n kiln delete pvc --all
