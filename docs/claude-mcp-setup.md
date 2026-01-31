# Claude Desktop MCP Setup Guide

This guide explains how to configure MCP servers in Claude Desktop for AI-driven infrastructure management.

## Prerequisites

- Claude Desktop installed
- Node.js 18+ installed
- Access to Grafana and VictoriaLogs instances
- Valid Grafana API key

## Installation Steps

### 1. Locate Claude Desktop Config

The configuration file location:

```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

### 2. Create or Edit Config

```bash
# Create config directory if it doesn't exist
mkdir -p ~/Library/Application\ Support/Claude

# Edit config file
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### 3. Add MCP Servers Configuration

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.pud.ink",
        "GRAFANA_API_KEY": "glsa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    },
    "victorialogs": {
      "command": "node",
      "args": ["/Users/timur-nd/repos/ai-ops/mcp-servers/victorialogs/server.js"],
      "env": {
        "VICTORIALOGS_URL": "https://victorialogs.pud.ink"
      }
    }
  }
}
```

**Important:** Replace paths and API keys with your actual values.

### 4. Restart Claude Desktop

Quit and restart Claude Desktop application for changes to take effect.

## Verify Configuration

### Check Server Status

In Claude Desktop, type:

```
Are the MCP servers connected?
```

Claude should report status of Grafana and VictoriaLogs servers.

### Test Grafana Connection

```
Show me CPU metrics for blog namespace
```

### Test VictoriaLogs Connection

```
Search for errors in auth service logs
```

## Usage Examples

### Deployment Management

```
Deploy version 2.1.0 of blog service and monitor the rollout
```

Claude will:
1. Execute deployment
2. Monitor logs via VictoriaLogs
3. Check metrics via Grafana
4. Report status

### Log Analysis

```
Show all 5xx errors from the last hour across all services
```

```
Why did blog-deployment-abc pod restart?
```

### Metrics Query

```
Show top 5 pods by memory usage
```

```
Create a graph of HTTP request rate for auth service
```

### Troubleshooting

```
Diagnose why auth service is slow
```

Claude will check metrics, logs, and generate diagnostic report.

## Advanced Configuration

### Using Environment Variables

Instead of hardcoding API keys, use environment variables:

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.pud.ink",
        "GRAFANA_API_KEY": "${GRAFANA_API_KEY}"
      }
    }
  }
}
```

Set environment variable:

```bash
# Add to ~/.zshrc
export GRAFANA_API_KEY="glsa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Reload shell
source ~/.zshrc
```

### Multiple Environments

Configure different environments:

```json
{
  "mcpServers": {
    "grafana-prod": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana-prod.pud.ink",
        "GRAFANA_API_KEY": "prod-key"
      }
    },
    "grafana-staging": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana-staging.pud.ink",
        "GRAFANA_API_KEY": "staging-key"
      }
    }
  }
}
```

## Troubleshooting

### MCP Servers Not Appearing

1. Check config file syntax (must be valid JSON)
2. Verify file path is correct
3. Check Node.js is installed: `node --version`
4. Restart Claude Desktop completely

### Connection Errors

```bash
# Test Grafana connection manually
curl -H "Authorization: Bearer YOUR_API_KEY" https://grafana.pud.ink/api/health

# Test VictoriaLogs
curl https://victorialogs.pud.ink/health
```

### Permission Issues

```bash
# Fix npm global permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Add to ~/.zshrc
export PATH=~/.npm-global/bin:$PATH
```

### Debug Mode

Enable logging to see what's happening:

1. Quit Claude Desktop
2. Run from terminal with debug flag:

```bash
/Applications/Claude.app/Contents/MacOS/Claude --enable-logging --v=1
```

3. Check logs in:
```bash
~/Library/Application Support/Claude/logs/
```

## Security Best Practices

1. **Protect Config File**
```bash
chmod 600 ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

2. **Use Service Accounts** - Create dedicated service accounts in Grafana with minimal permissions

3. **Rotate Keys** - Update API keys regularly

4. **Audit Access** - Monitor API key usage in Grafana

## Common Workflows

### Daily Monitoring

```
Give me a summary of system health for the last 24 hours
```

### Incident Response

```
There's an outage in blog namespace. Diagnose the issue and suggest fixes.
```

### Deployment Verification

```
I deployed blog v2.0. Check if it's healthy and performing well.
```

### Rollback

```
Blog v2.0 has issues. Rollback to previous stable version.
```

## Next Steps

- [VS Code Setup](vscode-mcp-setup.md)
- [API Reference](api-reference.md)
- [Troubleshooting Guide](troubleshooting.md)
