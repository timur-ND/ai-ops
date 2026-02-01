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

**If successful:**
```bash
gh pr comment <pr-number> --body "✅ Upgrade verified:
- Pod: <pod-name>
- Image: <new-image>
- Status: Running, Ready
- Restarts: 0
- Health: OK
- Ready to merge"
```

**If failed - ALWAYS ROLLBACK FIRST, then comment:**
```bash
# 1. Rollback immediately
helm rollback <release-name> -n <namespace>

# 2. Verify rollback succeeded
# Check pod status via K8s MCP

# 3. Comment on PR with failure details
gh pr comment <pr-number> --body "❌ Upgrade failed - ROLLED BACK

## Issue
<description of what went wrong>

## Error Logs
\`\`\`
<relevant error messages>
\`\`\`

## Current State
- Rolled back to previous version
- Pod status: <status after rollback>

## Next Steps
- [ ] Investigate root cause
- [ ] Check release notes for breaking changes
- [ ] Fix values.yaml if needed
- [ ] Retry upgrade

🤖 Rolled back by Claude Code"
```

### 7. Failure Handling

On upgrade failure:
1. **Rollback first** - Don't leave broken state
2. **Collect logs** - Get error details before rollback clears them
3. **Comment on PR** - Document what happened
4. **Ask user** - Whether to investigate/fix or close PR

## LogsQL Field Reference

Stream fields for VictoriaLogs queries:
- `kubernetes.pod_namespace` - pod namespace
- `kubernetes.pod_name` - pod name
- `kubernetes.container_name` - container name

## Notes

- Always check README.md in deploys/<app>/ for app-specific instructions
- Some apps may have additional steps (HTTPRoute, secrets, etc.)
- Update Version History table in README after successful upgrade
