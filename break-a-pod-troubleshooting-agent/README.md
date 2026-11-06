# Break a Kubernetes pod on purpose

A reproducible scenario for the AI troubleshooting agent and remediation plan in
Splunk Observability Cloud. You deploy an image tag that doesn't exist, a detector
fires on the pending pod, and the agent works out the likely root cause. Then you
follow the remediation plan and apply the fix yourself.

**The agent identifies the cause. You apply the fix.** Nothing in this repo or in
the product changes your cluster for you.

## What you need

- A Kubernetes cluster you can break (kind, minikube, k3d, or a managed cluster) and cluster-admin access
- `kubectl`, `helm` (a currently supported Helm 3 release), `curl`, and `jq`
- A Splunk Observability Cloud org in a non-Government realm, with the AI troubleshooting agent available
- An Observability Cloud **access token** (ingest) and a **user API access token** (to create the detector)
- Pod logs and Kubernetes events searchable from Observability Cloud: a Splunk platform deployment connected through
  Log Observer Connect, and a HEC endpoint and token for the collector to send to it. The agent reads these as evidence
  (for this scenario, the registry's "manifest not found" error), so map their cluster, namespace, pod and container
  fields to the entity index as described in the docs below.

## Run it

The quickest way is the all-in-one script. It asks for your realm and tokens
(secrets are hidden and not saved), checks them, then installs the collector,
breaks the pod, waits for `k8s.pod.phase` to arrive, and creates the detector:

```bash
./scripts/run-demo.sh
```

Use an org access token with **Ingest** scope for the access token. An API-only
token can't send data.

Or run the steps yourself. Create the detector after the pod is broken and its
metric is arriving; a detector created before its metric exists can take
several minutes to start evaluating it.

```bash
export REALM=us1
export ACCESS_TOKEN=...      # ingest token
export API_TOKEN=...         # user API access token
export HEC_URL=https://<your-splunk-host>:443/services/collector
export HEC_TOKEN=...

./scripts/00-install-collector.sh   # 1. Splunk OTel Collector via Helm
./scripts/02-break-pod.sh           # 2. Deploy busybox:1.00-sfx and watch it fail (Ctrl+C after ImagePullBackOff)
./scripts/01-create-detector.sh     # 3. "[Demo] Pending pod status" detector (k8s.pod.phase < 2)
```

Then, in Splunk Observability Cloud:

4. Go to **Alerts** and open the **[Demo] Pending pod status** alert. If your org is
   opted in by default, select **Run root cause analysis**.
5. Watch the investigation stream in the AI Assistant. It can take several minutes.
6. Read the primary root cause on **Overview**, then check **Evidence** to see what the agent used.
7. Ask the AI Assistant follow-up questions without leaving the alert, for example:
   - Are other services seeing the same errors?
   - How often has this detector fired before?
8. On **Root Cause Analysis**, select **View AI-generated action plan**. Run each
   kubectl step in your terminal, paste the output back, and submit. Apply the fix
   the plan gives you, then run its verification step.

Stuck? `scripts/answer-key-fix.sh` has the fix. Try the action plan first.

## Clean up

```bash
./scripts/99-cleanup.sh         # remove namespace k1 and the detector
./scripts/99-cleanup.sh --all   # also uninstall the collector
```

## Files

| Path | What it is |
|---|---|
| `scripts/run-demo.sh` | All-in-one: prompts for tokens, installs the collector, breaks the pod, creates the detector |
| `helm/values.yaml` | Collector values: cluster name, environment, logs and Kubernetes events |
| `helm/values-local.yaml` | Added automatically on minikube, kind and k3d (self-signed kubelet certificates) |
| `detector/pending-pod.signalflow` | Detector program: `k8s.pod.phase < 2` in namespace `k1` for 1 minute |
| `k8s/bad-deployment.yaml` | Namespace `k1` and deployment `ipbo-busybox` with a nonexistent image tag |
| `scripts/` | Install, create detector, break, answer key, cleanup |

## Docs

- [AI troubleshooting agent and remediation plan in Splunk Observability Cloud](https://help.splunk.com/en/splunk-observability-cloud/create-alerts-detectors-and-service-level-objectives/create-alerts-and-detectors/ai-troubleshooting-agent-and-remediation-plan)
- [Install the Collector for Kubernetes using Helm](https://help.splunk.com/en/splunk-observability-cloud/manage-data/splunk-distribution-of-the-opentelemetry-collector/get-started-with-the-splunk-distribution-of-the-opentelemetry-collector/collector-for-kubernetes/install-with-helm)
- [Set up Log Observer Connect for Splunk Cloud Platform](https://help.splunk.com/en/splunk-observability-cloud/manage-data/view-splunk-platform-logs/set-up-log-observer-connect-for-splunk-cloud-platform)
- [Set up Log Observer Connect for Splunk Enterprise](https://help.splunk.com/en/splunk-observability-cloud/manage-data/view-splunk-platform-logs/set-up-log-observer-connect-for-splunk-enterprise)
- [Entity index mappings](https://help.splunk.com/en/splunk-observability-cloud/manage-data/view-splunk-platform-logs/entity-index-mappings)
- [View alert details](https://help.splunk.com/en/splunk-observability-cloud/create-alerts-detectors-and-service-level-objectives/create-alerts-and-detectors/view-alert-details)
