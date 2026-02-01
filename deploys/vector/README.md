# Vector

Log collector that ships Kubernetes logs to VictoriaLogs.

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Namespace** | `monitoring` |
| **Release Name** | `vector-k8s-logs` |
| **Chart** | `vector/vector` |
| **Current Version** | `0.50.0` |
| **Role** | Agent (DaemonSet) |

## Prerequisites

```bash
# Add helm repo (if not added)
helm repo add vector https://helm.vector.dev
helm repo update

# Create secret for VictoriaLogs auth
kubectl create secret generic vmauth-token \
  -n monitoring \
  --from-literal=VL_INSTANCE_BEARER_TOKEN=<your-token>
```

## Install

```bash
kubectl config use-context pudink

# Install helm chart
helm upgrade --install vector-k8s-logs vector/vector \
  -n monitoring \
  -f values.yaml \
  --version 0.50.0 \
  --create-namespace
```

## Upgrade

```bash
kubectl config use-context pudink

# Update version in this README, then:
helm upgrade vector-k8s-logs vector/vector \
  -n monitoring \
  -f values.yaml \
  --version <NEW_VERSION>
```

## Rollback

```bash
kubectl config use-context pudink

# List history
helm history vector-k8s-logs -n monitoring

# Rollback to previous
helm rollback vector-k8s-logs -n monitoring

# Rollback to specific revision
helm rollback vector-k8s-logs <REVISION> -n monitoring
```

## Uninstall

```bash
helm uninstall vector-k8s-logs -n monitoring
```

## Observability

### Logs (VictoriaLogs)

```logsql
# Vector logs
{kubernetes.pod_namespace="monitoring", kubernetes.pod_name=~"vector.*"}

# Errors only
{kubernetes.pod_namespace="monitoring", kubernetes.pod_name=~"vector.*"} | filter level:"error"

# Sink issues (sending to VictoriaLogs)
{kubernetes.pod_namespace="monitoring", kubernetes.pod_name=~"vector.*"} | filter "sink" AND ("error" OR "failed")
```

### Metrics

Vector exposes Prometheus metrics on port 9598:
- `vector_component_sent_events_total` - events sent per sink
- `vector_buffer_events` - buffer size
- `vector_component_errors_total` - component errors

### Health Check

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=vector
kubectl logs -n monitoring -l app.kubernetes.io/name=vector --tail=50

# Check Vector API
kubectl exec -n monitoring -it $(kubectl get pod -n monitoring -l app.kubernetes.io/name=vector -o jsonpath='{.items[0].metadata.name}') -- curl -s localhost:8686/health
```

## Configuration

Vector is configured as a DaemonSet Agent that:
1. Collects logs from all pods via `kubernetes_logs` source
2. Transforms logs to extract namespace/pod/container labels
3. Sends logs to VictoriaLogs via HTTP sink with Bearer auth

See `values.yaml` for full configuration.

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
| 2026-02-02 | 0.50.0 | Claude | Update from 0.46.0 |
| 2024-XX-XX | 0.46.0 | - | Initial install |
