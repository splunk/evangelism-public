#!/usr/bin/env bash
# ANSWER KEY. Don't run this during the walkthrough.
#
# The point of the demo is to follow the AI-generated action plan in the alert and
# run its kubectl steps yourself. Use this only if you get stuck or want to reset
# the scenario quickly.
#
# This patches the live Deployment. In a real setup, fix the tag in your manifest or
# Helm values too, so the next deploy doesn't bring it back.
set -euo pipefail

kubectl -n k1 set image deploy/ipbo-busybox bb=busybox:1.36
kubectl -n k1 rollout status deploy/ipbo-busybox --timeout=120s
kubectl -n k1 get pods -l app=ipbo-busybox
