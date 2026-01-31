# Grafana

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Namespace** | `monitoring` |
| **Release Name** | `grafana` |
| **Chart** | `grafana/grafana` |
| **Current Version** | `8.5.2` |
| **App Version** | `11.2.2` |
| **URL** | `https://grafana.pud.ink` |

## Prerequisites

```bash
# Add helm repo (if not added)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## Install

```bash
kubectl config use-context pudink

helm upgrade --install grafana grafana/grafana \
  -n monitoring \
  -f values.yaml \
  --version 8.5.2 \
  --create-namespace
```

## Upgrade

```bash
kubectl config use-context pudink

# Update version in this README, then:
helm upgrade grafana grafana/grafana \
  -n monitoring \
  -f values.yaml \
  --version <NEW_VERSION>
```

## Rollback

```bash
kubectl config use-context pudink

# List history
helm history grafana -n monitoring

# Rollback to previous
helm rollback grafana -n monitoring

# Rollback to specific revision
helm rollback grafana <REVISION> -n monitoring
```

## Uninstall

```bash
helm uninstall grafana -n monitoring
```

## Observability

### Logs (VictoriaLogs)

```logsql
# All grafana logs
{namespace="monitoring", pod=~"grafana.*"}

# Errors only
{namespace="monitoring", pod=~"grafana.*"} | filter level:"error"

# Authentication issues
{namespace="monitoring", pod=~"grafana.*"} | filter "login" OR "auth"

# Last 30 minutes
{namespace="monitoring", pod=~"grafana.*"} | filter _time:[now-30m, now]
```

### Metrics (Grafana)

- **Dashboard:** Grafana Internals
- **Key metrics:**
  - `grafana_http_request_duration_seconds` - API latency
  - `grafana_alerting_rule_evaluations_total` - alert evaluations
  - `grafana_datasource_request_total` - datasource queries

### Health Check

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Test endpoint
curl -s https://grafana.pud.ink/api/health
```

## Admin Access

```bash
# Get admin password
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
| 2024-XX-XX | 8.5.2 | - | Initial install |
