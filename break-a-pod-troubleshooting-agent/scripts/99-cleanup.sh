#!/usr/bin/env bash
# Remove everything this repo created.
#
#   ./scripts/99-cleanup.sh             delete the k1 namespace and the detector
#   ./scripts/99-cleanup.sh --all       also uninstall the collector
#
# Deleting the detector needs REALM and API_TOKEN, and detector/.detector-id
# (written by 01-create-detector.sh). If they're missing, delete it in the UI.
set -euo pipefail

cd "$(dirname "$0")/.."

kubectl delete namespace k1 --ignore-not-found

if [[ -f detector/.detector-id && -n "${REALM:-}" && -n "${API_TOKEN:-}" ]]; then
  detector_id=$(cat detector/.detector-id)
  curl -sS --fail-with-body -X DELETE "https://api.${REALM}.signalfx.com/v2/detector/${detector_id}" \
    -H "X-SF-TOKEN: ${API_TOKEN}"
  rm detector/.detector-id
  echo "Deleted detector ${detector_id}"
else
  echo "Skipped detector: delete \"[Demo] Pending pod status\" in Detectors & SLOs, or set REALM and API_TOKEN."
fi

if [[ "${1:-}" == "--all" ]]; then
  helm uninstall splunk-otel-collector
fi
