#!/usr/bin/env bash
# Deploy an image tag that doesn't exist and watch the pod fail to pull it.
set -euo pipefail

cd "$(dirname "$0")/.."

kubectl apply -f k8s/bad-deployment.yaml

echo
echo "Watching pods in k1. Expect ErrImagePull, then ImagePullBackOff. Ctrl+C to stop."
kubectl -n k1 get pods -l app=ipbo-busybox -w
