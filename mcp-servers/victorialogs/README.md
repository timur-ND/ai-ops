# VictoriaLogs MCP Server

MCP server for VictoriaLogs integration, enabling AI to search and analyze logs from Kubernetes cluster.

## 📦 Installation

### 1. Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env and add your credentials
VICTORIALOGS_URL=https://victorialogs.pud.ink
VICTORIALOGS_TOKEN=your-token-here
VICTORIALOGS_ACCOUNT_ID=0
```

### 2. Pull Docker Image

```bash
# Pull the official VictoriaLogs MCP server image
docker pull ghcr.io/victoriametrics-community/mcp-victorialogs:latest

# Or use docker-compose
docker-compose pull mcp-victorialogs
```

### 3. Configure VictoriaLogs Access

```bash
# Port-forward for local access (if needed)
kubectl port-forward -n monitoring svc/victorialogs 9428:9428

# Or use ingress
# URL will be: https://victorialogs.pud.ink
```

## 🔧 Configuration

### VS Code

Add to `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "victorialogs": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "VICTORIALOGS_ADDR=${env:VICTORIALOGS_URL}",
        "-e",
        "VICTORIALOGS_ACCOUNT_ID=${env:VICTORIALOGS_ACCOUNT_ID}",
        "-e",
        "VICTORIALOGS_TOKEN=${env:VICTORIALOGS_TOKEN}",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
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
    "victorialogs": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "VICTORIALOGS_ADDR=https://victorialogs.pud.ink",
        "-e",
        "VICTORIALOGS_ACCOUNT_ID=0",
        "-e",
        "VICTORIALOGS_TOKEN=your-token-here",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
      ]
    }
  }
}
```

## 🚀 Usage

### Example AI Commands

**Search Errors:**
```
Show all errors in blog namespace from the last hour
```

**Search by Service:**
```
Show auth service logs containing "authentication failed"
```

**Aggregate Logs:**
```
How many 5xx errors did api service have in the last 24 hours?
```

**Analyze Crash:**
```
Show logs from pod blog-deployment-xxx before its restart
```

## 📊 LogsQL Queries

VictoriaLogs uses LogsQL for log search.

### Basic Operators

```logsql
# Search by namespace
{namespace="blog"}

# Search by pod
{namespace="blog", pod=~"blog-.*"}

# Search text in logs
{namespace="blog"} | filter "error"

# Filter by level
{namespace="blog"} | filter level:"error"

# Time range
{namespace="blog"} | filter _time:[now-1h, now]
```

### Query Examples

```logsql
# All errors from last hour
{namespace="blog"} | filter level:"error" | filter _time:[now-1h, now]

# HTTP 5xx errors
{namespace="blog"} | filter status:~"5.."

# Count errors by service
{namespace="blog"} | stats count() by service

# Top error sources
{namespace="blog"} | filter level:"error" | stats count() by pod | sort by count desc | limit 10
```

## 🛠 Creating Simple MCP Server

If ready-made MCP server is not available, you can create your own:

```javascript
// mcp-servers/victorialogs/server.js
const { MCPServer } = require('@modelcontextprotocol/sdk');
const axios = require('axios');

const VICTORIALOGS_URL = process.env.VICTORIALOGS_URL;

const server = new MCPServer({
  name: 'victorialogs',
  version: '1.0.0',
});

// Tool for searching logs
server.addTool({
  name: 'search_logs',
  description: 'Search logs in VictoriaLogs using LogsQL',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'LogsQL query',
      },
      limit: {
        type: 'number',
        description: 'Maximum number of results',
        default: 100,
      },
    },
    required: ['query'],
  },
  handler: async ({ query, limit = 100 }) => {
    const response = await axios.get(`${VICTORIALOGS_URL}/select/logsql/query`, {
      params: { query, limit },
    });
    return response.data;
  },
});

// Tool for log aggregation
server.addTool({
  name: 'aggregate_logs',
  description: 'Aggregate logs by fields',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'LogsQL query with stats',
      },
    },
    required: ['query'],
  },
  handler: async ({ query }) => {
    const response = await axios.get(`${VICTORIALOGS_URL}/select/logsql/query`, {
      params: { query },
    });
    return response.data;
  },
});

server.start();
```

## 📝 package.json for Server

```json
{
  "name": "victorialogs-mcp-server",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.1.0",
    "axios": "^1.6.0"
  }
}
```

## 🔍 Useful Queries

### Deployment Monitoring

```logsql
# Logs from new pod after deployment
{namespace="blog", pod=~"blog-deployment-.*"} | filter _time:[now-5m, now]
```

### Problem Diagnostics

```logsql
# Errors before pod restart
{namespace="blog", pod="blog-deployment-abc"} | filter level:"error" | filter _time:[now-1h, now]
```

### Statistics

```logsql
# Error count by namespace
{cluster="prod"} | filter level:"error" | stats count() by namespace
```

## 🛠 Troubleshooting

### Problem: "Connection timeout"

```bash
# Check VictoriaLogs availability
curl http://victorialogs.monitoring.svc.cluster.local:9428/health

# Or via port-forward
kubectl port-forward -n monitoring svc/victorialogs 9428:9428
curl http://localhost:9428/health
```

### Problem: "No logs found"

```bash
# Check that logs are being collected
kubectl logs -n monitoring deployment/fluent-bit

# Check that VictoriaLogs is receiving data
curl 'http://localhost:9428/select/logsql/query?query={namespace="blog"}&limit=10'
```

## 📚 Useful Links

- [VictoriaLogs Documentation](https://docs.victoriametrics.com/victorialogs/)
- [LogsQL Syntax](https://docs.victoriametrics.com/victorialogs/logsql/)
- [VictoriaLogs API](https://docs.victoriametrics.com/victorialogs/querying/)

## 🔐 Security

- Use BasicAuth or tokens for API access
- Restrict VictoriaLogs access via Network Policies
- Store credentials in Kubernetes Secrets
- Don't expose VictoriaLogs publicly without authentication
