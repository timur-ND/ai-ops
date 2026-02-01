# VictoriaLogs

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Namespace** | `monitoring` |
| **Release Name** | `victorialogs` |
| **Chart** | `victoriametrics/victoria-logs-single` |
| **Current Version** | `0.8.3` |
| **App Version** | `1.3.2` |
| **URL** | `https://victorialogs.pud.ink` |

## Prerequisites

```bash
# Add helm repo (if not added)
helm repo add victoriametrics https://victoriametrics.github.io/helm-charts
helm repo update
```

## Install

```bash
kubectl config use-context pudink

# Install helm chart
helm upgrade --install victorialogs victoriametrics/victoria-logs-single \
  -n monitoring \
  -f values.yaml \
  --version 0.8.3 \
  --create-namespace

# Apply HTTPRoute for Gateway API
kubectl apply -f httproute.yaml
```

## Upgrade

```bash
kubectl config use-context pudink

# Update version in this README, then:
helm upgrade victorialogs victoriametrics/victoria-logs-single \
  -n monitoring \
  -f values.yaml \
  --version <NEW_VERSION>

# Re-apply HTTPRoute if service name changed
kubectl apply -f httproute.yaml
```

## Rollback

```bash
kubectl config use-context pudink

# List history
helm history victorialogs -n monitoring

# Rollback to previous
helm rollback victorialogs -n monitoring

# Rollback to specific revision
helm rollback victorialogs <REVISION> -n monitoring
```

## Uninstall

```bash
helm uninstall victorialogs -n monitoring
```

## Observability

### Logs (VictoriaLogs - self)

```logsql
# VictoriaLogs own logs
{namespace="monitoring", pod=~"victorialogs.*"}

# Errors only
{namespace="monitoring", pod=~"victorialogs.*"} | filter level:"error"

# Ingestion issues
{namespace="monitoring", pod=~"victorialogs.*"} | filter "insert" OR "ingest"
```

### Metrics (Grafana)

- **Dashboard:** VictoriaLogs Overview
- **Key metrics:**
  - `vl_rows_ingested_total` - log ingestion rate
  - `vl_storage_size_bytes` - storage usage
  - `vl_http_request_duration_seconds` - query latency

### Health Check

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=victoria-logs-single
kubectl logs -n monitoring -l app.kubernetes.io/name=victoria-logs-single --tail=50

# Test endpoint
curl -s https://victorialogs.pud.ink/health
```

## Log Collection

Logs are collected via FluentBit/Vector DaemonSet. Ensure log collector is running:

```bash
kubectl get pods -n monitoring -l app=fluent-bit
```

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
| 2024-XX-XX | 0.8.3 | - | Initial install |
