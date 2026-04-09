# Upgrading the Splunk Java Agent to Enable Secure Application

This guide walks through upgrading a Java application from the standard Splunk OTel Java Agent (APM-only) to the CSA variant that enables Secure Application in Splunk Observability Cloud.

## Background

Secure Application provides real-time vulnerability detection by scanning runtime libraries in your Java application. It is delivered as a drop-in replacement agent JAR — you do not need to change your application code.

| Agent JAR | What it does |
|---|---|
| `splunk-otel-javaagent` | APM only — traces, metrics, profiling |
| `splunk-otel-javaagent-csa` | APM + Secure Application — adds runtime library vulnerability scanning |

Both are published to Maven Central under `com.splunk` and share the same version numbers.

## Prerequisites

- A Java application already instrumented with `splunk-otel-javaagent`
- A Splunk OTel Collector forwarding to Splunk Observability Cloud
- A Splunk Observability Cloud access token with `ingest` scope
- A **Secure Application license** (add-on SKU on top of your Splunk APM subscription — contact your Splunk account team to enable)
- Docker (if using the containerized setup in this repo)

## Step 1: Replace the agent JAR

Swap the download URL from the standard agent to the CSA agent. The version stays the same.

**Before (standard agent):**
```
splunk-otel-javaagent-2.25.1.jar
```
Download: `https://repo1.maven.org/maven2/com/splunk/splunk-otel-javaagent/2.25.1/splunk-otel-javaagent-2.25.1.jar`

**After (CSA agent):**
```
splunk-otel-javaagent-csa-2.25.1.jar
```
Download: `https://repo1.maven.org/maven2/com/splunk/splunk-otel-javaagent-csa/2.25.1/splunk-otel-javaagent-csa-2.25.1.jar`

The `-javaagent` flag in your startup command does not change — it still points to the agent JAR file path. No additional JVM flags are required.

## Step 2: Update the OTel Collector to forward security events

The CSA agent reports security data using the OpenTelemetry protocol. Under the hood, it uses the OTLP logs transport — but this has nothing to do with Splunk Platform log ingestion or Log Observer. No log-related licensing or infrastructure is required.

The collector's `signalfx` exporter (the same one you already use for metrics) converts these security events and sends them to Splunk Observability Cloud. You just need to add it to the collector's `logs` pipeline:

**Before:**
```yaml
logs:
  receivers: [otlp]
  processors: [memory_limiter, batch, resourcedetection]
  exporters: [debug]
```

**After:**
```yaml
logs:
  receivers: [otlp]
  processors: [memory_limiter, batch, resourcedetection]
  exporters: [signalfx, debug]
```

If you're already using the `signalfx` exporter for metrics or traces, no new exporter definition is needed — just reference the existing one in the `logs` pipeline.

## Step 3: Rebuild and deploy

```bash
docker compose down
docker compose up -d --build
```

## Step 4: Verify

### Confirm security events are flowing

Check collector logs for security events:

```bash
docker compose logs otel-collector | grep "secureapp"
```

You should see log records with:
```
InstrumentationScope secureapp 1.59.0
SeverityText: Security
```

### Confirm no export errors

```bash
docker compose logs otel-collector | grep -iE "error|fail|drop" | grep -v health
```

This should return empty — no errors.

### Confirm data in Splunk Observability Cloud

- **APM:** Navigate to APM > Services and find your service name
- **Secure Application:** Navigate to Application Security > Vulnerabilities to see detected library vulnerabilities

## What changed (summary)

| Component | Before | After |
|---|---|---|
| Agent JAR | `splunk-otel-javaagent-2.25.1.jar` | `splunk-otel-javaagent-csa-2.25.1.jar` |
| JVM flags | No changes | No changes |
| Collector `logs` pipeline | Not forwarding to Splunk | `signalfx` exporter added |
| Application code | No changes | No changes |

## Running this demo

> **Note:** Running this demo requires a Secure Application license, which is an add-on SKU on top of your Splunk APM subscription. Contact your Splunk account team to enable it.

```bash
# 1. Clone and configure
cp .env.example .env
# Edit .env with your SPLUNK_ACCESS_TOKEN and SPLUNK_REALM

# 2. Start
docker compose up -d --build

# 3. Play the game at http://localhost:8080

# 4. Check security events
docker compose logs otel-collector | grep "secureapp"
```
