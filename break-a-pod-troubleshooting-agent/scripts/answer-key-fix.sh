#!/usr/bin/env bash
# ANSWER KEY. Don't run this during the walkthrough.
#
# The point of the demo is to follow the AI-generated action plan in the alert and
# run its kubectl steps yourself. Use this only if you get stuck or want to reset
# the scenario quickly.
set -euo pipefail

kubectl -n k1 set image deploy/ipbo-busybox bb=busybox:1.36
kubectl -n k1 rollout status deploy/ipbo-busybox --timeout=120s
kubectl -n k1 get pods -l app=ipbo-busybox
