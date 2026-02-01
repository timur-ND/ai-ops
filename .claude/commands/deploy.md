# Deploy Workflow

Upgrade a Kubernetes application to a new version with verification.

## Usage

```
/deploy <app-name> <version>
```

Example: `/deploy vector 0.51.0`

## Workflow Steps

When user requests an upgrade, follow these steps:

### 1. Find Application

- Look in `deploys/<app-name>/` folder
- Read the README.md to understand current version and configuration
- Read values.yaml if exists

### 2. Check Current State via MCP

Use Kubernetes MCP to verify current deployment:
```
- List pods/deployments in the namespace
- Get current image version
- Check pod status (Running/CrashLooping)
```

### 3. Create Branch and PR

```bash
git checkout -b upgrade/<app-name>-<version>
# Update README.md with new version
# Update helm command in README if needed
git add deploys/<app-name>/
git commit -m "Upgrade <app-name> to <version>"
git push -u origin upgrade/<app-name>-<version>
gh pr create --title "Upgrade <app-name> to <version>" --body "..."
```

### 4. Apply Upgrade

Run the helm upgrade command from README:
```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f deploys/<app-name>/values.yaml \
  --version <version>
```

### 5. Verify Deployment

Use MCP tools to verify:

**Kubernetes MCP:**
- Check pod status: `list-k8s-resources` (kind: Pod)
- Check pod logs: `get-k8s-pod-logs`
- Verify new image version: `get-k8s-resource`

**VictoriaLogs MCP:**
- Query logs for errors:
  ```logsql
  {kubernetes.pod_namespace="<namespace>", kubernetes.pod_name=~"<app>.*"} | filter level:"error"
  ```
- Check for crash loops or startup issues

### 6. Update PR Status

If successful:
```bash
gh pr comment <pr-number> --body "✅ Upgrade verified:
- Pods running: X/X
- No errors in logs
- Ready to merge"
```

If failed:
```bash
gh pr comment <pr-number> --body "❌ Upgrade failed:
- Issue: <description>
- Logs: <relevant error>
- Action: Rolling back / Investigating"
```

### 7. Rollback (if needed)

```bash
helm rollback <release-name> -n <namespace>
```

## LogsQL Field Reference

Stream fields for VictoriaLogs queries:
- `kubernetes.pod_namespace` - pod namespace
- `kubernetes.pod_name` - pod name
- `kubernetes.container_name` - container name

## Notes

- Always check README.md in deploys/<app>/ for app-specific instructions
- Some apps may have additional steps (HTTPRoute, secrets, etc.)
- Update Version History table in README after successful upgrade
