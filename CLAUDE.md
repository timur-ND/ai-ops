# AI-Ops Project Instructions

This repository contains Kubernetes deployment configurations for the `pudink` cluster.

## MCP Servers Available

- **kubernetes** - Query and manage K8s resources
- **victorialogs** - Query logs stored in VictoriaLogs

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

Upgrade an application to a new version with full verification workflow.

```
/deploy <app-name> <version>
```

See `.claude/commands/deploy.md` for full workflow.

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
