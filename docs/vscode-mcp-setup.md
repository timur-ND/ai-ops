# VS Code MCP Setup Guide

This guide explains how to configure MCP servers in VS Code for AI-driven infrastructure management.

## Prerequisites

- VS Code installed
- Node.js 18+ installed
- Access to Grafana and VictoriaLogs instances

## Installation Steps

### 1. Install MCP Extension

```bash
# Install the MCP extension for VS Code
# (Check VS Code marketplace for the latest MCP extension)
```

### 2. Configure MCP Servers

Create or edit `.vscode/settings.json` in your workspace:

```json
{
  "mcp.servers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.example.com",
        "GRAFANA_API_KEY": "${env:GRAFANA_API_KEY}"
      }
    },
    "victorialogs": {
      "command": "node",
      "args": ["${workspaceFolder}/mcp-servers/victorialogs/server.js"],
      "env": {
        "VICTORIALOGS_URL": "https://victorialogs.example.com"
      }
    }
  }
}
```

### 3. Set Environment Variables

Create `.env` file in your home directory:

```bash
# ~/.env
export GRAFANA_API_KEY="glsa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export VICTORIALOGS_API_KEY="your-victorialogs-token"
```

Load environment variables:

```bash
# Add to ~/.zshrc or ~/.bashrc
source ~/.env
```

### 4. Verify Configuration

Restart VS Code and check that MCP servers are running:

1. Open Command Palette (Cmd+Shift+P)
2. Type "MCP: Show Server Status"
3. Verify both servers are connected

## Usage Examples

### With GitHub Copilot Chat

Open Copilot Chat and try:

```
@mcp Show CPU metrics for blog namespace
```

```
@mcp Search errors in auth service logs
```

### With Continue.dev

If using Continue.dev extension:

1. Open Continue chat (Cmd+L)
2. Ask questions about your infrastructure
3. MCP servers will provide real-time data

## Troubleshooting

### Server Not Starting

```bash
# Check Node.js version
node --version  # Should be 18+

# Check if MCP package is installed
npm list -g @modelcontextprotocol/server-grafana

# Install manually if needed
npm install -g @modelcontextprotocol/server-grafana
```

### Environment Variables Not Loaded

```bash
# Verify environment variables
echo $GRAFANA_API_KEY

# If empty, reload shell config
source ~/.zshrc
```

### Permission Errors

```bash
# Fix npm global permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

## Advanced Configuration

### Custom Server Timeout

```json
{
  "mcp.servers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.example.com",
        "GRAFANA_API_KEY": "${env:GRAFANA_API_KEY}"
      },
      "timeout": 30000
    }
  }
}
```

### Debug Mode

Enable debug logging:

```json
{
  "mcp.debug": true,
  "mcp.logLevel": "debug"
}
```

View logs in Output panel:
1. View -> Output
2. Select "MCP" from dropdown

## Security Best Practices

1. **Never commit API keys** - Always use environment variables
2. **Use read-only tokens** - Create service accounts with minimal permissions
3. **Rotate keys regularly** - Update API keys every 90 days
4. **Restrict workspace** - Only enable MCP in trusted workspaces

## Next Steps

- [Claude Desktop Setup](claude-mcp-setup.md)
- [API Reference](api-reference.md)
- [Troubleshooting Guide](troubleshooting.md)
