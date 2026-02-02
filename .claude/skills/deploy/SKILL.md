---
name: deploy
description: Upgrade Kubernetes application to a new version with full verification workflow
disable-model-invocation: true
argument-hint: "<app-name> <version>"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(helm *)
  - Bash(kubectl *)
  - Bash(curl *)
  - mcp__kubernetes__*
  - mcp__victorialogs__*
  - mcp__grafana__*
---

# Deploy Workflow

Upgrade a Kubernetes application with GitOps workflow and MCP-based verification.

## Arguments

- `$ARGUMENTS` = `<app-name> <version>`
- Example: `/deploy victorialogs 0.12.0`

## Step 1: Discover Application

Find the app in one of these locations (check in order):
1. `deploys/<app-name>/` - single cluster repos
2. `clusters/<cluster-name>/<app-name>/` - multi-cluster GitOps repos
3. `apps/<app-name>/` - ArgoCD-style repos

Read `README.md` to get:
- Current version (from Cluster Info table)
- Helm chart name and repo
- Release name
- Namespace
- K8s context

## Step 2: Pre-flight Checks

Use **Kubernetes MCP** to verify current state:
```
mcp__kubernetes__list-k8s-resources (kind: Pod/Deployment/StatefulSet)
mcp__kubernetes__get-k8s-resource (get current image version)
```

Confirm:
- [ ] App exists in cluster
- [ ] Pods are healthy before upgrade
- [ ] Note current version for rollback

## Step 3: Create Branch & PR

```bash
git checkout -b upgrade/<app-name>-<version>

# Update README.md:
# - Current Version: <new-version>
# - App Version: <new-app-version> (from helm search)
# - Version History: add entry with date and notes

git add <app-folder>/README.md
git commit -m "Upgrade <app-name> to <version>"
git push -u origin upgrade/<app-name>-<version>

gh pr create --title "Upgrade <app-name> to <version>" --body "## Summary
- Chart: <old> → <new>
- App: <old-app> → <new-app>

## Verification
- [ ] Pod running
- [ ] Health check OK
- [ ] No errors in logs

🤖 Generated with Claude Code"
```

## Step 4: Apply Helm Upgrade

```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f <app-folder>/values.yaml \
  --version <version> \
  --kube-context <context>
```

Wait for rollout:
```bash
kubectl rollout status deployment/<name> -n <namespace> --timeout=300s
# or for StatefulSet:
kubectl rollout status statefulset/<name> -n <namespace> --timeout=300s
```

## Step 5: Verify with MCP

### Kubernetes MCP
```
mcp__kubernetes__get-k8s-resource - verify new image
mcp__kubernetes__get-k8s-pod-logs - check for errors
mcp__kubernetes__list-k8s-events - check for warnings
```

### VictoriaLogs MCP (if available)
```logsql
{kubernetes.pod_namespace="<namespace>", kubernetes.pod_name=~"<app>.*"}
| filter level:"error" OR level:"warn"
| limit 50
```

### Grafana MCP (if available)
```
# TODO: Check dashboard for app metrics
# - Error rate
# - Latency p99
# - Resource usage
```

### Health Endpoint (if available)
```bash
curl -s <health-url>
```

## Step 6: Update PR

### On Success ✅
```bash
gh pr comment <pr-number> --body "## ✅ Upgrade Verified

| Check | Status |
|-------|--------|
| Pod | \`<pod-name>\` |
| Image | \`<new-image>\` |
| Status | Running |
| Ready | True |
| Restarts | 0 |
| Health | OK |
| Logs | No errors |

**Ready to merge.**

🤖 Verified by Claude Code"
```

### On Failure ❌

**CRITICAL: Rollback first, then report!**

```bash
# 1. ROLLBACK IMMEDIATELY
helm rollback <release-name> -n <namespace> --kube-context <context>

# 2. Verify rollback
kubectl get pods -n <namespace> -l app=<app-name>

# 3. Comment with details
gh pr comment <pr-number> --body "## ❌ Upgrade Failed - ROLLED BACK

### Issue
<what went wrong>

### Error Logs
\`\`\`
<relevant errors>
\`\`\`

### Actions Taken
- Rolled back to previous version
- Current state: <status>

### Next Steps
- [ ] Check release notes for breaking changes
- [ ] Review values.yaml compatibility
- [ ] Fix and retry OR close PR

🤖 Rolled back by Claude Code"
```

## Step 7: Merge or Close

Ask user:
- **Success**: Merge PR? `gh pr merge <pr-number> --merge --delete-branch`
- **Failure**: Close PR? `gh pr close <pr-number>`

---

## Reference

### Folder Structure Patterns

```
# Single cluster (this repo)
deploys/
├── vector/
├── victorialogs/
└── vmauth/

# Multi-cluster GitOps
clusters/
├── production/
│   ├── vector/
│   └── victorialogs/
└── staging/
    ├── vector/
    └── victorialogs/

# ArgoCD style
apps/
├── base/
└── overlays/
    ├── prod/
    └── staging/
```

### README Template

Each app folder must have README.md with:

```markdown
## Cluster Info

| Parameter | Value |
|-----------|-------|
| **Context** | `<context>` |
| **Namespace** | `<namespace>` |
| **Release Name** | `<release>` |
| **Chart** | `<repo>/<chart>` |
| **Current Version** | `<version>` |
| **App Version** | `<app-version>` |

## Version History

| Date | Version | Changed By | Notes |
|------|---------|------------|-------|
```

### LogsQL Fields

- `kubernetes.pod_namespace` - namespace
- `kubernetes.pod_name` - pod name
- `kubernetes.container_name` - container

### Useful Helm Commands

```bash
# Check available versions
helm search repo <chart> --versions | head -10

# Show release history
helm history <release> -n <namespace>

# Get current values
helm get values <release> -n <namespace>
```
