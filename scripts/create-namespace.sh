#!/bin/bash

NAMESPACE=registry

if kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "Namespace $NAMESPACE already exists."
else
  echo "Namespace $NAMESPACE does not exist. Creating..."
  kubectl create namespace "$NAMESPACE"
  echo "Namespace $NAMESPACE created."
fi
