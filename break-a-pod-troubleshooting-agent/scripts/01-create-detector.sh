#!/usr/bin/env bash
# Create the "[Demo] Pending pod status" detector through the Observability Cloud API.
#
# The detector alerts when k8s.pod.phase < 2 for any pod in namespace k1 of the
# break-a-pod-demo cluster. k8s.pod.phase reports 1 for Pending and 2 for Running.
#
# Required environment variables:
#   REALM       Splunk Observability Cloud realm, for example us1
#   API_TOKEN   A user API access token (or an org token with API scope) that can create detectors
#
# Prefer the UI? Create a custom detector on k8s.pod.phase, filter on
# k8s.cluster.name=break-a-pod-demo and k8s.namespace.name=k1, and alert when the
# value is below 2. Paste detector/pending-pod.signalflow into the SignalFlow editor
# if you want it identical.
set -euo pipefail

cd "$(dirname "$0")/.."

: "${REALM:?Set REALM}"
: "${API_TOKEN:?Set API_TOKEN}"
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

body=$(jq -n --rawfile program detector/pending-pod.signalflow '{
  name: "[Demo] Pending pod status",
  description: "Fires when a pod in namespace k1 stays below Running (k8s.pod.phase < 2) for 1 minute.",
  programText: $program,
  rules: [{
    detectLabel: "Pending pod status",
    severity: "Critical",
    notifications: []
  }]
}')

response=$(curl -sS --fail-with-body -X POST "https://api.${REALM}.signalfx.com/v2/detector" \
  -H "Content-Type: application/json" \
  -H "X-SF-TOKEN: ${API_TOKEN}" \
  -d "${body}")

detector_id=$(jq -r '.id' <<<"${response}")
echo "${detector_id}" > detector/.detector-id
echo "Created detector ${detector_id}"
echo "https://app.${REALM}.signalfx.com/#/detector/v2/${detector_id}/edit"
