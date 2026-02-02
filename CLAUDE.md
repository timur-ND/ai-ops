# AI-Ops Project Instructions

This repository contains Kubernetes deployment configurations for the `pudink` cluster.

## MCP Servers Available

- **kubernetes** - Query and manage K8s resources
- **victorialogs** - Query logs stored in VictoriaLogs
- **grafana** - Query dashboards and metrics

## Repository Structure

```
deploys/
├── vector/        # Log collector (DaemonSet)
├── victorialogs/  # Log storage
└── vmauth/        # Auth proxy for VictoriaLogs
```

Each deploy folder contains:
- `README.md` - Version info, install/upgrade commands, observability queries
- `values.yaml` - Helm values
- Optional: `httproute.yaml`, `values.secret.yaml`

## Skills

### /deploy

Upgrade an application to a new version with GitOps workflow and MCP verification.

```
/deploy <app-name> <version>
```

Features:
- Auto-detect folder structure (`deploys/`, `clusters/<cluster>/`, `apps/`)
- Pre-flight checks via K8s MCP
- Create branch & PR
- Helm upgrade with rollout wait
- Verify via K8s MCP, VictoriaLogs MCP, Grafana MCP
- Auto-rollback on failure
- PR status comments with metrics (CPU/mem/HTTP)

See `.claude/skills/deploy/SKILL.md` for full workflow.

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

## Conventions

1. **README versions** - Always update README.md with new version after upgrade
2. **Version History** - Add entry to Version History table in README
3. **PR workflow** - Create branch, PR, verify, comment status
4. **Helm releases** - Use `helm upgrade --install` for idempotent deploys

---

## Setup for Other Repositories

To use `/deploy` skill in other repositories, install it at user level:

### 1. Copy skill to user directory

```bash
mkdir -p ~/.claude/skills/deploy
cp .claude/skills/deploy/SKILL.md ~/.claude/skills/deploy/
```

### 2. Configure MCP servers (user level)

Create `.env` file with credentials:

```bash
# ~/.claude/mcp.env (or project-specific .env)

# Kubernetes - needs kubeconfig file
KUBECONFIG=/path/to/kubeconfig.yaml

# VictoriaLogs
VL_INSTANCE_ENTRYPOINT=https://victorialogs.example.com
VL_INSTANCE_BEARER_TOKEN=<token>
VL_DEFAULT_TENANT_ID=0:0

# Grafana (Viewer role is sufficient)
GRAFANA_URL=https://grafana.example.com
GRAFANA_SERVICE_ACCOUNT_TOKEN=<token>
```

Add MCP servers:

```bash
# Kubernetes MCP
claude mcp add kubernetes -s user -- docker run -i --rm \
  -v /path/to/kubeconfig.yaml:/home/nonroot/.kube/config:ro \
  mcpk8s/server:latest

# VictoriaLogs MCP
claude mcp add victorialogs -s user -- docker run -i --rm \
  --env-file /path/to/.env \
  ghcr.io/victoriametrics-community/mcp-victorialogs:latest

# Grafana MCP
claude mcp add grafana -s user -- docker run -i --rm \
  --env-file /path/to/.env \
  grafana/mcp-grafana -t stdio
```

### 3. Create app README.md

Each app folder must follow this structure:

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

### 4. Supported folder structures

```
# Single cluster (this repo style)
deploys/<app-name>/

# Multi-cluster GitOps
clusters/<cluster-name>/<app-name>/

# ArgoCD style
apps/<app-name>/
```
