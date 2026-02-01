# VMAuth

Auth proxy for VictoriaLogs with Basic Auth and Bearer Token support.

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Namespace** | `monitoring` |
| **Release Name** | `vmauth` |
| **Chart** | `victoriametrics/victoria-metrics-auth` |
| **Current Version** | `0.23.0` |
| **URL** | `https://victorialogs.pud.ink` |

## Authentication

| Type | User | Usage |
|------|------|-------|
| Basic Auth | `admin` | UI access (browser) |
| Bearer Token | - | MCP/API access |

Credentials are stored in `values.secret.yaml` (not in git).

## Prerequisites

```bash
# Add helm repo (if not added)
helm repo add victoriametrics https://victoriametrics.github.io/helm-charts
helm repo update
```

## Install

```bash
kubectl config use-context pudink

# Install helm chart with secret values
helm upgrade --install vmauth victoriametrics/victoria-metrics-auth \
  -n monitoring \
  -f values.yaml \
  -f values.secret.yaml \
  --version 0.23.0

# Apply HTTPRoute (replaces direct VictoriaLogs route)
kubectl apply -f httproute.yaml
```

## Upgrade

```bash
kubectl config use-context pudink

helm upgrade vmauth victoriametrics/victoria-metrics-auth \
  -n monitoring \
  -f values.yaml \
  -f values.secret.yaml \
  --version <NEW_VERSION>
```

## Rollback

```bash
kubectl config use-context pudink

helm history vmauth -n monitoring
helm rollback vmauth -n monitoring
```

## Uninstall

```bash
helm uninstall vmauth -n monitoring
kubectl delete -f httproute.yaml
```

## Architecture

```
                    ┌─────────────────┐
 victorialogs.pud.ink │   Contour       │
        ───────────►│   Gateway       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │     VMAuth      │
                    │  (auth proxy)   │
                    │                 │
                    │ Basic Auth: UI  │
                    │ Bearer: MCP     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  VictoriaLogs   │
                    │   (internal)    │
                    └─────────────────┘
```

## Observability

### Health Check

```bash
# VMAuth health
kubectl get pods -n monitoring -l app=victoria-metrics-auth

# Test with basic auth
curl -u admin:PASSWORD https://victorialogs.pud.ink/health

# Test with bearer token
curl -H "Authorization: Bearer TOKEN" https://victorialogs.pud.ink/health
```

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
| 2026-02-01 | 0.23.0 | AI | Initial install |
