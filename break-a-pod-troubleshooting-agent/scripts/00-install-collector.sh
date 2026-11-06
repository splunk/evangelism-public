#!/usr/bin/env bash
# Install the Splunk OTel Collector into the current kubectl context with Helm.
#
# Required environment variables:
#   REALM          Splunk Observability Cloud realm, for example us1
#   ACCESS_TOKEN   Observability Cloud access token with ingest scope
#   HEC_URL        Splunk platform HEC endpoint, for example https://<host>:443/services/collector
#   HEC_TOKEN      Splunk platform HEC token
# Optional:
#   HEC_INDEX      Index for pod logs (default: value in helm/values.yaml)
#   NO_LOGS=1      Install without sending logs, for the "what the agent can't see" comparison
set -euo pipefail

cd "$(dirname "$0")/.."

: "${REALM:?Set REALM}"
: "${ACCESS_TOKEN:?Set ACCESS_TOKEN}"

helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart >/dev/null 2>&1 || true
helm repo update splunk-otel-collector-chart

args=(
  --values helm/values.yaml
  --set "splunkObservability.realm=${REALM}"
  --set "splunkObservability.accessToken=${ACCESS_TOKEN}"
)

node_labels=$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels}' 2>/dev/null || true)
if [[ "$node_labels" == *minikube.k8s.io* || "$node_labels" == *k3s.io* || "$(kubectl config current-context)" == kind-* ]]; then
  echo "Local cluster detected: adding helm/values-local.yaml"
  args+=(--values helm/values-local.yaml)
fi

if [[ "${NO_LOGS:-0}" == "1" ]]; then
  # With no HEC endpoint set, the chart skips the Splunk platform exporter entirely.
  echo "NO_LOGS=1: installing without the Splunk platform log pipeline"
else
  : "${HEC_URL:?Set HEC_URL (or NO_LOGS=1)}"
  : "${HEC_TOKEN:?Set HEC_TOKEN (or NO_LOGS=1)}"
  args+=(
    --set "splunkPlatform.endpoint=${HEC_URL}"
    --set "splunkPlatform.token=${HEC_TOKEN}"
  )
  if [[ -n "${HEC_INDEX:-}" ]]; then
    args+=(--set "splunkPlatform.index=${HEC_INDEX}")
  fi
fi

helm upgrade --install splunk-otel-collector "${args[@]}" \
  splunk-otel-collector-chart/splunk-otel-collector

# Token changes only update the chart's Secret, which running pods don't reload.
kubectl rollout restart daemonset/splunk-otel-collector-agent deployment/splunk-otel-collector-k8s-cluster-receiver

echo
echo "Waiting for collector pods..."
kubectl rollout status daemonset -l app=splunk-otel-collector --timeout=180s || true
kubectl get pods -l app=splunk-otel-collector
