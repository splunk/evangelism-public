#!/usr/bin/env bash
# Run the whole scenario from one place.
#
# Asks once for the realm and tokens (secrets are read silently and kept only in
# this process), then installs the collector, creates the detector, breaks the
# pod, and waits for ImagePullBackOff. When you're done in Observability Cloud,
# the menu can rerun the scenario without logs or clean everything up.
#
# Any of REALM, ACCESS_TOKEN, API_TOKEN, HEC_URL, HEC_TOKEN already in the
# environment are used instead of prompting.
set -euo pipefail

cd "$(dirname "$0")/.."

EXPECTED_CONTEXT="${EXPECTED_CONTEXT:-break-a-pod-demo}"

ask() { # ask VAR "Prompt" [default]
  local var=$1 prompt=$2 default=${3:-}
  if [[ -z "${!var:-}" ]]; then
    local reply
    read -r -p "${prompt}${default:+ [${default}]}: " reply
    printf -v "$var" '%s' "${reply:-$default}"
  fi
  export "${var?}"
}

ask_secret() { # ask_secret VAR "Prompt" [optional]
  local var=$1 prompt=$2 optional=${3:-}
  if [[ -z "${!var:-}" ]]; then
    local reply
    read -r -s -p "${prompt}: " reply
    echo
    if [[ -z "$reply" && -z "$optional" ]]; then
      echo "  ${var} is required."
      ask_secret "$var" "$prompt"
      return
    fi
    printf -v "$var" '%s' "$reply"
  fi
  export "${var?}"
}

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

check_context() {
  local ctx
  ctx=$(kubectl config current-context)
  if [[ "$ctx" != "$EXPECTED_CONTEXT" ]]; then
    echo "kubectl context is '${ctx}', expected '${EXPECTED_CONTEXT}'. Refusing to touch it."
    echo "Switch with: kubectl config use-context ${EXPECTED_CONTEXT}  (or set EXPECTED_CONTEXT)"
    exit 1
  fi
}

check_api_token() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://api.${REALM}.signalfx.com/v2/detector?limit=1" \
    -H "X-SF-TOKEN: ${API_TOKEN}")
  if [[ "$code" != "200" ]]; then
    echo "API token check against realm ${REALM} returned HTTP ${code}. Check REALM and API_TOKEN."
    exit 1
  fi
}

check_access_token() {
  local code
  while true; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "https://ingest.${REALM}.signalfx.com/v2/datapoint" \
      -H "Content-Type: application/json" -H "X-SF-TOKEN: ${ACCESS_TOKEN}" -d '{}')
    [[ "$code" == "200" ]] && { echo "Access token check passed."; return; }
    echo "Access token check against ingest.${REALM} returned HTTP ${code}."
    if [[ ${#ACCESS_TOKEN} -le 12 ]]; then
      echo "That looks like a token ID (${#ACCESS_TOKEN} characters). Open the token, select Show Token, then Copy."
    else
      echo "Use an org access token with Ingest scope (Settings > Access Tokens > token name > Show Token > Copy),"
      echo "from the same org as your API token."
    fi
    ACCESS_TOKEN=
    ask_secret ACCESS_TOKEN "Access token (ingest), try again"
  done
}

check_hec() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${HEC_URL}" \
    -H "Authorization: Splunk ${HEC_TOKEN}" \
    -d "{\"event\":\"break-a-pod-demo HEC check\",\"index\":\"${HEC_INDEX}\",\"sourcetype\":\"break-a-pod-demo\"}")
  case "$code" in
    200) echo "HEC check passed (test event sent to index ${HEC_INDEX})." ;;
    000) echo "Couldn't reach ${HEC_URL} (connection or TLS error). Check the URL and port."; exit 1 ;;
    *)   echo "HEC check returned HTTP ${code}. Check the HEC token, and that it's allowed to write to index ${HEC_INDEX}."; exit 1 ;;
  esac
}

install_collector() {
  step "Installing the collector${NO_LOGS:+ (metrics only, no logs)}"
  ./scripts/00-install-collector.sh
}

create_detector() {
  # Reuse the saved detector only if it exists in the org these tokens belong to.
  if [[ -f detector/.detector-id ]]; then
    local id code
    id=$(cat detector/.detector-id)
    code=$(curl -s -o /dev/null -w '%{http_code}' "https://api.${REALM}.signalfx.com/v2/detector/${id}" \
      -H "X-SF-TOKEN: ${API_TOKEN}")
    if [[ "$code" == "200" ]]; then
      step "Detector already exists (${id}), skipping"
      return
    fi
    echo "Saved detector ${id} isn't in this org (HTTP ${code}); creating a new one."
    rm detector/.detector-id
  fi
  step "Creating the [Demo] Pending pod status detector"
  ./scripts/01-create-detector.sh
}

break_pod() {
  step "Deploying busybox:1.00-sfx (an image tag that doesn't exist)"
  kubectl apply -f k8s/bad-deployment.yaml
  echo "Waiting for ImagePullBackOff..."
  for _ in $(seq 1 60); do
    reason=$(kubectl -n k1 get pods -l app=ipbo-busybox \
      -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)
    if [[ "$reason" == "ImagePullBackOff" || "$reason" == "ErrImagePull" ]]; then
      kubectl -n k1 get pods -l app=ipbo-busybox
      break
    fi
    sleep 2
  done
  echo
  echo "The detector fires after the pod has been Pending for about a minute."
  echo "Alerts: https://app.${REALM}.signalfx.com/#/alerts"
}

wait_for_metric() {
  step "Waiting for k8s.pod.phase to reach Observability Cloud"
  for _ in $(seq 1 30); do
    count=$(curl -s -G "https://api.${REALM}.signalfx.com/v2/metrictimeseries" \
      -H "X-SF-TOKEN: ${API_TOKEN}" \
      --data-urlencode 'query=sf_metric:k8s.pod.phase AND k8s.cluster.name:break-a-pod-demo AND k8s.namespace.name:k1' \
      | jq -r '.count // 0')
    if [[ "${count}" -gt 0 ]]; then
      echo "Found ${count} time series."
      return
    fi
    sleep 10
  done
  echo "k8s.pod.phase hasn't shown up after 5 minutes. Check the collector logs for export errors:"
  echo "  kubectl logs deployment/splunk-otel-collector-k8s-cluster-receiver | grep -i error"
  exit 1
}

cleanup() {
  step "Cleaning up"
  ./scripts/99-cleanup.sh "$@"
}

menu() {
  while true; do
    echo
    echo "Scenario is running. When you're done in Observability Cloud:"
    echo "  n) Rerun without logs (reinstall collector metrics-only, recreate detector, break again)"
    echo "  r) Rerun with logs"
    echo "  c) Clean up namespace and detector (keep collector)"
    echo "  a) Clean up everything, including the collector"
    echo "  q) Quit and leave everything running"
    read -r -p "> " choice
    case "$choice" in
      n) cleanup; NO_LOGS=1 install_collector; break_pod; wait_for_metric; create_detector ;;
      r) cleanup
         if [[ -z "${HEC_URL:-}" ]]; then ask HEC_URL "HEC URL"; ask_secret HEC_TOKEN "HEC token"; fi
         NO_LOGS= install_collector; break_pod; wait_for_metric; create_detector ;;
      c) cleanup ;;
      a) cleanup --all; exit 0 ;;
      q) exit 0 ;;
      *) echo "Choose n, r, c, a or q." ;;
    esac
  done
}

check_context

echo "Splunk Observability Cloud settings. Secrets are hidden as you type and aren't saved."
ask REALM "Realm" "us1"
ask_secret ACCESS_TOKEN "Access token (ingest)"
ask_secret API_TOKEN "User API access token"
echo "HEC for pod logs. Leave the URL blank to run without logs."
ask HEC_URL "HEC URL (https://<host>:443/services/collector)"
if [[ -n "$HEC_URL" ]]; then
  ask_secret HEC_TOKEN "HEC token"
  ask HEC_INDEX "Splunk index for pod logs and Kubernetes events (must be searchable by your logs connection)" "main"
  unset NO_LOGS
  check_hec
else
  export NO_LOGS=1
fi

check_api_token
check_access_token
install_collector
break_pod
# Create the detector only after k8s.pod.phase is flowing for the broken pod.
# A detector created before its metric exists can sit for several minutes
# without evaluating the new time series.
wait_for_metric
create_detector
menu
