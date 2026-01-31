# Prometheus

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Namespace** | `monitoring` |
| **Release Name** | `prometheus` |
| **Chart** | `prometheus-community/prometheus` |
| **Current Version** | `25.27.0` |
| **App Version** | `2.54.1` |

## Prerequisites

```bash
# Add helm repo (if not added)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Install

```bash
kubectl config use-context pudink

helm upgrade --install prometheus prometheus-community/prometheus \
  -n monitoring \
  -f values.yaml \
  --version 25.27.0 \
  --create-namespace
```

## Upgrade

```bash
kubectl config use-context pudink

# Update version in this README, then:
helm upgrade prometheus prometheus-community/prometheus \
  -n monitoring \
  -f values.yaml \
  --version <NEW_VERSION>
```

## Rollback

```bash
kubectl config use-context pudink

# List history
helm history prometheus -n monitoring

# Rollback to previous
helm rollback prometheus -n monitoring

# Rollback to specific revision
helm rollback prometheus <REVISION> -n monitoring
```

## Uninstall

```bash
helm uninstall prometheus -n monitoring
```

## Observability

### Logs (VictoriaLogs)

```logsql
# All prometheus logs
{namespace="monitoring", pod=~"prometheus-server.*"}

# Errors only
{namespace="monitoring", pod=~"prometheus-server.*"} | filter level:"error"

# Last 30 minutes
{namespace="monitoring", pod=~"prometheus-server.*"} | filter _time:[now-30m, now]
```

### Metrics (Grafana)

- **Dashboard:** Prometheus Overview
- **Key metrics:**
  - `prometheus_tsdb_head_samples_appended_total` - ingestion rate
  - `prometheus_tsdb_head_series` - active series count
  - `up{job="prometheus"}` - prometheus health

### Health Check

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50
```

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
| 2024-XX-XX | 25.27.0 | - | Initial install |
