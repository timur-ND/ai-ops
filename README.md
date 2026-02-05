# /deploy Skill for Claude Code

A GitOps deployment skill for Kubernetes applications with MCP-based verification.

## Features

- Auto-detect folder structure (`deploys/`, `clusters/<cluster>/`, `apps/`)
- Pre-flight checks via Kubernetes MCP
- Create branch & PR automatically
- Helm upgrade with rollout wait
- **SOPS support** for encrypted values files (auto-decrypt/re-encrypt)
- Post-deploy verification via Kubernetes, VictoriaLogs, and Grafana MCP
- Auto-rollback on failure
- PR status comments with metrics (CPU/mem/HTTP)

## Installation

### 1. Copy skill to user directory

```bash
mkdir -p ~/.claude/skills/deploy
cp .claude/skills/deploy/SKILL.md ~/.claude/skills/deploy/
```

### 2. Setup Kubernetes access

Generate a limited kubeconfig for the MCP server:

```bash
# Apply RBAC (read-only cluster-wide, full access to specific namespace)
kubectl apply -f k8s-mcp-rbac.yaml
```

**Single cluster:**
```bash
./generate-kubeconfig.sh
# Output: kubeconfig-ai-ops.yaml (uses current context)
```

**Multiple clusters:**
```bash
./generate-kubeconfig-multi.sh production staging dev
# Output: kubeconfig-ai-ops-multi.yaml (merged config with all contexts)
```

Generated kubeconfig has:
- **Read-only** access to entire cluster (pods, deployments, services, ingresses)
- **Full access** to `monitoring` namespace (for helm operations)

To add more namespaces with full access, edit `k8s-mcp-rbac.yaml`.

### 3. Configure MCP servers

**Option A: Auto-start with Claude Code (recommended)**

Add MCP servers to `~/.claude.json`. Docker containers start automatically when Claude Code launches.

**Option B: Manual start with docker-compose**

If you prefer to manage containers separately:

```bash
docker-compose up -d
```

Then configure Claude to connect to running containers (see `docker-compose.yml`).

---

**For Option A**, create an `.env` file with credentials:

```bash
# ~/.claude/mcp.env

# VictoriaLogs
VL_INSTANCE_ENTRYPOINT=https://victorialogs.example.com
VL_INSTANCE_BEARER_TOKEN=<token>
VL_DEFAULT_TENANT_ID=0:0

# Grafana (Viewer role is sufficient)
GRAFANA_URL=https://grafana.example.com
GRAFANA_SERVICE_ACCOUNT_TOKEN=<token>
```

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "kubernetes": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/path/to/kubeconfig.yaml:/home/nonroot/.kube/config:ro",
        "mcpk8s/server:latest"
      ],
      "env": {}
    },
    "victorialogs": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--env-file", "~/.claude/mcp.env",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
      ],
      "env": {}
    },
    "grafana": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--env-file", "~/.claude/mcp.env",
        "grafana/mcp-grafana",
        "-t", "stdio"
      ],
      "env": {}
    }
  }
}
```

| MCP Server | Purpose | Required |
|------------|---------|----------|
| kubernetes | Pod status, logs, events | Yes |
| victorialogs | Log queries | Optional |
| grafana | Metrics dashboards | Optional |

### 4. App README.md format (optional)

Each app folder should have a `README.md` with deployment metadata. The skill will auto-generate this file if missing, or you can create it manually following this format:

```markdown
## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `my-cluster` |
| **Namespace** | `monitoring` |
| **Release Name** | `my-app` |
| **Chart** | `repo/chart-name` |
| **Current Version** | `1.0.0` |
| **App Version** | `v1.0.0` |

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
```

### 5. SOPS setup (optional)

For encrypted values files (`values.secret.yaml`), configure age key:

```bash
mkdir -p ~/.config/sops/age

# Generate new age key (if needed)
age-keygen -o ~/.config/sops/age/keys.txt

# Or copy existing key
cp /path/to/age/keys.txt ~/.config/sops/age/keys.txt
```

The skill will:
1. Try default SOPS key first
2. Fall back to `SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt`
3. Decrypt before helm upgrade, clean up after

## Usage

```
/deploy <app-name> <version> [context]
```

Examples:
```bash
# Use context from app README
/deploy victorialogs 0.12.0

# Override context (deploy to staging instead)
/deploy victorialogs 0.12.0 staging
```

## Supported Folder Structures

```
# Single cluster
deploys/
├── vector/
├── victorialogs/
└── vmauth/

# Multi-cluster GitOps
clusters/
├── production/
│   ├── vector/
│   └── victorialogs/
└── staging/
    ├── vector/
    └── victorialogs/

# ArgoCD style
apps/
├── base/
└── overlays/
    ├── prod/
    └── staging/
```

Each app folder contains:
- `README.md` - Version info, install/upgrade commands
- `values.yaml` - Helm values
- Optional: `httproute.yaml`, `values.secret.yaml` (SOPS encrypted)

## LogsQL Reference

Query logs using VictoriaLogs MCP:

```logsql
# By namespace and pod
{kubernetes.pod_namespace="monitoring", kubernetes.pod_name=~"vector.*"}

# Filter by level
... | filter level:"error"

# Search text
... | filter "connection refused"
```

## Grafana MCP

The skill searches for dashboards matching these patterns to collect post-deploy metrics:

| Pattern | Purpose |
|---------|---------|
| `*ingress*`, `*contour*` | HTTP traffic (request rate, status codes, latency) |
| `*pod*`, `*deployment*` | Resource usage (CPU, memory) |
| `*namespace*` | Namespace-level overview |
| `<app-name>` | App-specific dashboards |

Prometheus queries used:
```promql
# CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="X", pod=~"app.*"}[5m])) by (pod)

# Memory usage
sum(container_memory_working_set_bytes{namespace="X", pod=~"app.*"}) by (pod)

# HTTP request rate by status
sum(rate(envoy_cluster_upstream_rq_total{envoy_cluster_name=~".*app.*"}[5m])) by (envoy_response_code_class)
```

## Kubernetes MCP

The skill uses Kubernetes MCP for pre-flight checks and post-deploy verification:

**Pre-flight (before upgrade):**
- List pods/deployments to verify app exists
- Get current image version for rollback reference
- Check pod health status

**Post-deploy (after upgrade):**
- Verify new image version is running
- Check pod status (Running, Ready, Restarts)
- Get pod logs (last 100 lines) for errors
- List events for warnings

## Multi-Cluster Setup

For managing deployments across multiple Kubernetes clusters.

### 1. Apply RBAC to each cluster

```bash
# For each cluster context
kubectl apply -f k8s-mcp-rbac.yaml --context production
kubectl apply -f k8s-mcp-rbac.yaml --context staging
kubectl apply -f k8s-mcp-rbac.yaml --context dev
```

### 2. Generate merged kubeconfig

**Option A: Single cluster (simple)**
```bash
./generate-kubeconfig.sh production
# Output: kubeconfig-ai-ops.yaml
```

**Option B: Multiple clusters (merged)**
```bash
./generate-kubeconfig-multi.sh production staging dev
# Output: kubeconfig-ai-ops-multi.yaml
```

The merged kubeconfig contains all clusters with their original context names. Each context has:
- **Read-only** access to entire cluster
- **Full access** to `monitoring` namespace

### 3. Configure MCP with merged kubeconfig

Update `~/.claude.json` to use the merged kubeconfig:

```json
{
  "mcpServers": {
    "kubernetes": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/path/to/kubeconfig-ai-ops-multi.yaml:/home/nonroot/.kube/config:ro",
        "mcpk8s/server:latest"
      ],
      "env": {}
    }
  }
}
```

### 4. App README context

For multi-cluster repos, each app's README specifies which cluster to deploy to:

```markdown
## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `production` |  <!-- Must match context in kubeconfig -->
| **Namespace** | `monitoring` |
```

The skill validates that the context exists before deploying.

### RBAC Permissions

| Scope | Access Level | Resources |
|-------|--------------|-----------|
| Cluster-wide | Read-only | pods, deployments, services, ingresses, events, httproutes |
| `monitoring` namespace | Full | All resources (for helm operations) |

To add more namespaces with full access, edit `k8s-mcp-rbac.yaml`:

```yaml
# Add RoleBinding for each namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ai-ops-full-access
  namespace: my-other-namespace  # Add namespace here
...
```

## Workflow

See `.claude/skills/deploy/SKILL.md` for the full workflow documentation.
