# AI-Ops

AI-driven infrastructure deployment and monitoring for Kubernetes.

## Structure

```
ai-ops/
├── deploys/                    # Helm deployments
│   ├── prometheus/
│   │   ├── README.md           # Install/upgrade/rollback instructions
│   │   └── values.yaml         # Helm values
│   ├── grafana/
│   │   ├── README.md
│   │   └── values.yaml
│   └── victorialogs/
│       ├── README.md
│       └── values.yaml
│
├── docker-compose.yml          # MCP servers
├── .env.example                # Environment variables template
└── README.md
```

## Workflow

1. **Request:** User asks to deploy/update a service
2. **Branch:** AI creates a feature branch
3. **Deploy:** AI runs helm install/upgrade
4. **Verify:** AI checks logs (VictoriaLogs) and metrics (Grafana)
5. **PR:** AI creates PR with deployment status
6. **Review:** Human reviews and merges
7. **Done:** AI merges if approved

## MCP Servers

This repo uses MCP (Model Context Protocol) servers for AI integration:

| Server | Purpose |
|--------|---------|
| `mcp-grafana` | Query metrics, dashboards, alerts |
| `mcp-victorialogs` | Search and analyze logs |
| `mcp-kubernetes` | Kubernetes operations (kubectl) |

### Setup

```bash
# Copy environment file
cp .env.example .env

# Edit with your credentials
nano .env

# Start MCP servers
docker-compose up -d
```

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "grafana": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-grafana", "/app/mcp-grafana"]
    },
    "victorialogs": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-victorialogs", "/mcp-victorialogs"]
    },
    "kubernetes": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-kubernetes", "/mcp-k8s"]
    }
  }
}
```

## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `pudink` |
| **Gateway** | Contour |
| **TLS** | Wildcard `*.pud.ink` |
| **Monitoring NS** | `monitoring` |

## Example Commands

```
# Deploy new version
"Deploy prometheus version 25.28.0"

# Check status
"Show prometheus pod status and recent logs"

# Rollback
"Rollback grafana to previous version"

# Investigate
"Check why prometheus is using high memory"
```

## Adding New Service

1. Create folder in `deploys/<service-name>/`
2. Add `README.md` with cluster info and commands
3. Add `values.yaml` with helm values
4. Commit and push

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GRAFANA_URL` | Grafana URL |
| `GRAFANA_TOKEN` | Grafana API token |
| `VICTORIALOGS_URL` | VictoriaLogs URL |
| `VICTORIALOGS_TOKEN` | VictoriaLogs token |
| `VICTORIALOGS_ACCOUNT_ID` | VictoriaLogs account (default: 0) |
