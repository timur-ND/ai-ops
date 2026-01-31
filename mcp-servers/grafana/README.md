# Grafana MCP Server

MCP server for Grafana integration, enabling AI to retrieve metrics, manage dashboards, and check alerts.

## 🔧 Installation

### 1. Create API Token in Grafana

```bash
# Go to Grafana UI: https://grafana.example.com
# Administration -> Service accounts -> Create service account
# Create token with Admin or Viewer role (depending on needs)
```

### 2. Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env and add your credentials
GRAFANA_URL=https://grafana.example.com
GRAFANA_TOKEN=glsa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Pull Docker Image

```bash
# Pull the official Grafana MCP server image
docker pull ghcr.io/grafana/mcp-grafana:latest

# Or use docker-compose
docker-compose pull mcp-grafana
```

## 📝 Configuration

### VS Code

Add to `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "grafana": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "GRAFANA_URL=${env:GRAFANA_URL}",
        "-e",
        "GRAFANA_TOKEN=${env:GRAFANA_TOKEN}",
        "ghcr.io/grafana/mcp-grafana:latest"
      ]
    }
  }
}
```

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "grafana": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "GRAFANA_URL=https://grafana.example.com",
        "-e",
        "GRAFANA_TOKEN=glsa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "ghcr.io/grafana/mcp-grafana:latest"
      ]
    }
  }
}
```

## 🚀 Usage

### Example AI Commands

**Get Metrics:**
```
Show CPU usage for all pods in blog namespace for the last hour
```

**Check Dashboards:**
```
Show Kubernetes Cluster Monitoring dashboard
```

**Check Alerts:**
```
Are there any active alerts for auth service?
```

**Create Dashboard:**
```
Create a dashboard for MySQL cluster monitoring with metrics:
- Connections
- Queries per second
- Replication lag
```

## 📊 Available Capabilities

### Metrics
- Query Prometheus metrics
- Time-based aggregation
- Filter by labels
- Build graphs

### Dashboards
- List all dashboards
- Get specific dashboard
- Create new dashboards
- Update existing ones

### Alerts
- List active alerts
- Alert history
- Alert rule status
- Create/update rules

### Datasources
- List data sources
- Check connections
- Add new sources

## 🔍 Query Examples

### PromQL Queries via AI

```
Query: "Show top 5 pods by memory consumption"

AI will execute PromQL:
topk(5, container_memory_usage_bytes{namespace="blog"})
```

```
Query: "Graph HTTP requests to auth service for today"

AI will execute PromQL:
rate(http_requests_total{service="auth"}[5m])
```

## 🛠 Troubleshooting

### Problem: "Connection refused"

```bash
# Check Grafana availability
curl -H "Authorization: Bearer $GRAFANA_API_KEY" https://grafana.example.com/api/health

# Check environment variable
echo $GRAFANA_API_KEY
```

### Problem: "Unauthorized"

```bash
# Check API key validity
# Create new key in Grafana UI with required permissions
```

### Problem: "No data"

```bash
# Check datasource in Grafana
# Verify metrics are being collected in Prometheus
kubectl get servicemonitors -A
```

## 📚 Useful Links

- [MCP Grafana Server Docs](https://github.com/modelcontextprotocol/servers/tree/main/src/grafana)
- [Grafana HTTP API](https://grafana.com/docs/grafana/latest/developers/http_api/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## 🔐 Security

- Use Service Account tokens instead of Admin API keys
- Limit token permissions to only what's needed (Viewer for read-only)
- Rotate API keys regularly
- Never commit keys to git
