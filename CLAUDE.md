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

### 2. Configure MCP servers

Add MCP servers to `~/.claude.json` under the `mcpServers` key. Docker containers start automatically when Claude Code launches.

Create an `.env` file with credentials:

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
        "--env-file", "/path/to/.env",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
      ],
      "env": {}
    },
    "grafana": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--env-file", "/path/to/.env",
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

### 3. Create app README.md

Each app folder must have a `README.md` with deployment metadata:

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

### 4. SOPS setup (optional)

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
/deploy <app-name> <version>
```

Example:
```
/deploy victorialogs 0.12.0
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

## Workflow

See `.claude/skills/deploy/SKILL.md` for the full workflow documentation.
