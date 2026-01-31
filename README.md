# AI-Ops: AI-Driven Infrastructure Management

Automated deployment and monitoring system using MCP servers and AI assistants.

## 📁 Project Structure

```
ai-ops/
├── mcp-servers/           # MCP servers for AI integration
│   ├── grafana/          # Grafana MCP server
│   └── victorialogs/     # VictoriaLogs MCP server
├── helm-charts/          # Helm charts for service deployment
│   ├── grafana/          # Grafana + Prometheus stack
│   └── victorialogs/     # VictoriaLogs for log aggregation
├── scripts/              # Automation and utility scripts
└── docs/                 # Documentation
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Install Docker (if not already installed)
brew install docker

# Install Helm (if not already installed)
brew install helm

# Add Helm repositories
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add victoriametrics https://victoriametrics.github.io/helm-charts
helm repo update
```

### 2. Deploy Grafana

```bash
# Create namespace
kubectl create namespace monitoring

# Deploy Grafana
./scripts/deploy-grafana.sh

# Check status
kubectl get pods -n monitoring
```

### 3. Deploy VictoriaLogs

```bash
# Deploy VictoriaLogs
./scripts/deploy-victorialogs.sh

# Check status
kubectl get pods -n monitoring
```

### 4. Configure MCP Servers

```bash
# Copy and edit environment variables
cp .env.example .env
nano .env  # Add your Grafana and VictoriaLogs credentials

# Pull MCP server Docker images
docker pull ghcr.io/grafana/mcp-grafana:latest
docker pull ghcr.io/victoriametrics-community/mcp-victorialogs:latest

# For VS Code - add to settings.json
# See docs/vscode-mcp-setup.md

# For Claude Desktop - add to config
# See docs/claude-mcp-setup.md
```

## 🤖 Usage with AI

After configuring MCP servers, you can interact with AI using commands like:

**Example commands:**

- "Deploy version 2.0 of blog service"
- "Show logs for auth service from the last hour"
- "Check CPU metrics for all pods"
- "Rollback blog service to previous version"
- "Show errors in blog namespace"

## 📊 MCP Servers

### Grafana MCP Server
- **Purpose**: Retrieve metrics, dashboards, alerts
- **Config**: `mcp-servers/grafana/config.json`
- **Capabilities**:
  - Query metrics and graphs
  - Create/update dashboards
  - Check alerts
  - Export data

### VictoriaLogs MCP Server
- **Purpose**: Search and analyze logs
- **Config**: `mcp-servers/victorialogs/config.json`
- **Capabilities**:
  - Search logs by labels
  - Aggregate logs
  - Analyze errors
  - Generate reports

## 🛠 Automation Scripts

### Deployment
- `scripts/deploy-grafana.sh` - Deploy Grafana
- `scripts/deploy-victorialogs.sh` - Deploy VictoriaLogs
- `scripts/deploy-service.sh <name> <version>` - Deploy service

### Monitoring
- `scripts/check-health.sh` - Check health of all services
- `scripts/get-logs.sh <service> <namespace>` - Get logs
- `scripts/get-metrics.sh <service>` - Get metrics

### Management
- `scripts/rollback.sh <service> <revision>` - Rollback version
- `scripts/scale.sh <service> <replicas>` - Scale service
- `scripts/restart.sh <service>` - Restart service

## 📝 AI Workflow

### Standard Deployment

1. AI receives deployment command
2. Runs `scripts/deploy-service.sh`
3. Monitors logs via VictoriaLogs MCP
4. Checks metrics via Grafana MCP
5. If issues detected - performs rollback and writes report

### Problem Diagnostics

1. AI receives alert or check command
2. Queries metrics via Grafana MCP
3. Analyzes logs via VictoriaLogs MCP
4. Generates problem report
5. Suggests solution

## 🔧 Configuration

### Grafana
- **URL**: configured in `helm-charts/grafana/values.yaml`
- **Datasources**: Prometheus, Loki, VictoriaLogs
- **Dashboards**: auto-imported from `helm-charts/grafana/dashboards/`

### VictoriaLogs
- **URL**: configured in `helm-charts/victorialogs/values.yaml`
- **Retention**: 30 days by default
- **Storage**: uses PVC

## 📚 Documentation

- [VS Code MCP Setup](docs/vscode-mcp-setup.md)
- [Claude Desktop MCP Setup](docs/claude-mcp-setup.md)
- [API Reference](docs/api-reference.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🔐 Security

- All secrets stored in Kubernetes Secrets
- MCP servers use tokens for authorization
- TLS certificates managed via cert-manager

## 📈 System Monitoring

- Grafana dashboard for AI-Ops monitoring: `ai-ops-dashboard.json`
- Alerts for MCP server failures
- All operation logs in VictoriaLogs

## 🤝 Contributing

When adding new services:
1. Create Helm chart in `helm-charts/`
2. Add deployment script in `scripts/`
3. Update documentation
4. Configure monitoring and logging

## 📄 License

MIT
