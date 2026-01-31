# Troubleshooting Guide

Common issues and solutions for AI-Ops MCP setup.

## MCP Server Issues

### Server Not Starting

**Symptoms:**
- MCP server shows as disconnected
- Timeout errors in logs

**Solutions:**

1. Check Node.js version:
```bash
node --version  # Should be 18+
```

2. Reinstall MCP packages:
```bash
npm install -g @modelcontextprotocol/server-grafana
```

3. Check permissions:
```bash
which npx
ls -la $(which npx)
```

4. Try running manually:
```bash
npx -y @modelcontextprotocol/server-grafana
```

### Environment Variables Not Loaded

**Symptoms:**
- "GRAFANA_API_KEY is not set" error
- Authentication failures

**Solutions:**

1. Verify environment variable:
```bash
echo $GRAFANA_API_KEY
```

2. Reload shell configuration:
```bash
source ~/.zshrc  # or ~/.bashrc
```

3. For Claude Desktop, hardcode in config (less secure):
```json
{
  "mcpServers": {
    "grafana": {
      "env": {
        "GRAFANA_API_KEY": "glsa_actual_key_here"
      }
    }
  }
}
```

## Grafana Connection Issues

### Connection Refused

**Symptoms:**
- "Connection refused" error
- Cannot reach Grafana API

**Solutions:**

1. Test Grafana connectivity:
```bash
curl https://grafana.pud.ink/api/health
```

2. Check if service is running:
```bash
kubectl get pods -n monitoring -l app=grafana
```

3. Verify ingress configuration:
```bash
kubectl get ingress -n monitoring
```

4. Check DNS resolution:
```bash
dig grafana.pud.ink
```

### Unauthorized / 401 Error

**Symptoms:**
- "Unauthorized" or "Invalid API key" error

**Solutions:**

1. Verify API key is valid:
```bash
curl -H "Authorization: Bearer $GRAFANA_API_KEY" \
  https://grafana.pud.ink/api/org
```

2. Check API key permissions:
   - Log into Grafana UI
   - Go to Administration -> Service Accounts
   - Verify token has required permissions

3. Create new API key with correct permissions

4. Update key in MCP config

### No Data Returned

**Symptoms:**
- Queries return empty results
- "No data" errors

**Solutions:**

1. Check datasource configuration:
```bash
# Via Grafana API
curl -H "Authorization: Bearer $GRAFANA_API_KEY" \
  https://grafana.pud.ink/api/datasources
```

2. Verify Prometheus is scraping metrics:
```bash
kubectl get servicemonitors -A
kubectl logs -n monitoring deployment/prometheus
```

3. Test Prometheus query directly:
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090
```

## VictoriaLogs Issues

### Server Not Responding

**Symptoms:**
- Timeout when querying logs
- "Connection timeout" error

**Solutions:**

1. Check VictoriaLogs is running:
```bash
kubectl get pods -n monitoring -l app=victorialogs
```

2. Check logs:
```bash
kubectl logs -n monitoring deployment/victorialogs
```

3. Test connectivity:
```bash
kubectl port-forward -n monitoring svc/victorialogs 9428:9428
curl http://localhost:9428/health
```

### No Logs Found

**Symptoms:**
- Queries return empty results
- "No matching logs" error

**Solutions:**

1. Verify logs are being collected:
```bash
# Check log collector (e.g., fluent-bit)
kubectl get pods -n monitoring -l app=fluent-bit
kubectl logs -n monitoring daemonset/fluent-bit
```

2. Check VictoriaLogs is receiving data:
```bash
curl 'http://localhost:9428/select/logsql/query?query={namespace=~".*"}&limit=10'
```

3. Verify log collector configuration:
```bash
kubectl get configmap -n monitoring fluent-bit-config -o yaml
```

### Invalid LogsQL Syntax

**Symptoms:**
- "Syntax error" in query
- Query fails to parse

**Solutions:**

1. Refer to LogsQL documentation:
   https://docs.victoriametrics.com/victorialogs/logsql/

2. Test query manually:
```bash
curl 'http://localhost:9428/select/logsql/query?query={namespace="blog"}'
```

3. Common syntax fixes:
```logsql
# Wrong: {namespace=blog}
# Right: {namespace="blog"}

# Wrong: {namespace="blog"} AND level="error"
# Right: {namespace="blog"} | filter level:"error"
```

## Kubernetes Issues

### Pod Not Starting

**Symptoms:**
- Deployment stuck in "Pending" or "CrashLoopBackOff"

**Solutions:**

1. Check pod status:
```bash
kubectl describe pod <pod-name> -n <namespace>
```

2. Check logs:
```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container
```

3. Check events:
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

4. Check resources:
```bash
kubectl top nodes
kubectl top pods -n <namespace>
```

### Service Not Accessible

**Symptoms:**
- Cannot reach service via ingress
- 404 or 503 errors

**Solutions:**

1. Check service:
```bash
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>
```

2. Check endpoints:
```bash
kubectl get endpoints <service-name> -n <namespace>
```

3. Check ingress:
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
```

4. Test service directly:
```bash
kubectl port-forward -n <namespace> svc/<service-name> 8080:80
curl http://localhost:8080
```

## Helm Issues

### Chart Installation Failed

**Symptoms:**
- `helm install` returns error
- Resources not created

**Solutions:**

1. Check Helm version:
```bash
helm version  # Should be 3.x+
```

2. Validate chart:
```bash
helm lint ./helm-charts/grafana
```

3. Dry-run installation:
```bash
helm install grafana ./helm-charts/grafana --dry-run --debug
```

4. Check for existing resources:
```bash
helm list -A
kubectl get all -n monitoring
```

5. Uninstall and reinstall:
```bash
helm uninstall grafana -n monitoring
helm install grafana ./helm-charts/grafana -n monitoring
```

## AI Assistant Issues

### Commands Not Working

**Symptoms:**
- AI doesn't use MCP servers
- Commands are ignored

**Solutions:**

1. Verify MCP servers are connected:
   - For Claude: Ask "Are MCP servers connected?"
   - For VS Code: Check MCP status in status bar

2. Be explicit in commands:
```
# Instead of: "Check metrics"
# Say: "Use Grafana MCP to show CPU metrics for blog namespace"
```

3. Check MCP server logs for errors

### Slow Responses

**Symptoms:**
- AI takes long time to respond
- Timeouts

**Solutions:**

1. Increase timeout in config:
```json
{
  "mcpServers": {
    "grafana": {
      "timeout": 60000  // 60 seconds
    }
  }
}
```

2. Simplify queries:
```
# Instead of: "Show everything about blog service"
# Say: "Show CPU usage for blog pods"
```

3. Check network connectivity to Grafana/VictoriaLogs

## Getting Help

### Collect Debug Information

```bash
# System info
uname -a
node --version
npm --version
kubectl version

# MCP server status
ps aux | grep mcp

# Check MCP logs
# For Claude Desktop:
tail -f ~/Library/Application\ Support/Claude/logs/*

# For VS Code:
# View -> Output -> Select "MCP"
```

### Report Issue

Include in bug report:
1. Error message
2. MCP server config (remove API keys!)
3. Debug logs
4. Steps to reproduce
5. Expected vs actual behavior

## Useful Commands

### Reset Everything

```bash
# Remove MCP global packages
npm uninstall -g @modelcontextprotocol/server-grafana

# Clear npm cache
npm cache clean --force

# Reinstall
npm install -g @modelcontextprotocol/server-grafana

# Restart Claude Desktop / VS Code
```

### Check All Services

```bash
./scripts/check-health.sh
```

### Get Full System Status

```bash
kubectl get all -A | grep -E '(grafana|victoria|prometheus)'
```

## Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [VictoriaLogs Documentation](https://docs.victoriametrics.com/victorialogs/)
- [MCP Documentation](https://modelcontextprotocol.io/docs)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
