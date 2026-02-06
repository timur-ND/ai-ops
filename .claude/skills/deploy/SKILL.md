---
name: deploy
description: Upgrade Kubernetes application to a new version with full verification workflow
disable-model-invocation: true
argument-hint: "<app-name> <version> [context]"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(helm *)
  - Bash(kubectl *)
  - Bash(curl *)
  - Bash(sleep *)
  - Bash(sops *)
  - mcp__kubernetes__*
  - mcp__victorialogs__*
  - mcp__grafana__*
---

# Deploy Workflow

Upgrade a Kubernetes application with GitOps workflow and MCP-based verification.

**This is a user-level skill** - place in `~/.claude/skills/deploy/SKILL.md` to use across all repos.

## Arguments

- `$ARGUMENTS` = `<app-name> <version> [context]`
- Examples:
  - `/deploy victorialogs 0.12.0` - use context from app README
  - `/deploy victorialogs 0.12.0 staging` - override context to `staging`

If context is provided as argument, it overrides the context from README.

## Important Constraints

**Tool naming:** When invoking tools, ALWAYS use short constant tool names (max 20 characters).
Do NOT dynamically generate tool names. This prevents API errors.

## SOPS Encrypted Files Support

This skill supports SOPS-encrypted values files. Encrypted files can have ANY extension (`.yaml`, `.yml`, etc.) - detection is based on file **content**, not filename.

### Detection
SOPS-encrypted files contain `sops:` metadata block inside. Check ALL yaml files:
```bash
# Find ALL SOPS-encrypted files by content (not by extension)
grep -l "sops:" <app-folder>/*.yaml <app-folder>/*.yml 2>/dev/null
```

### Decryption Strategy
1. **Try default key first** (from environment or default keyring):
   ```bash
   sops -d <file> > <file>.dec
   ```

2. **If default fails, use age key**:
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d <file> > <file>.dec
   ```

3. **Use decrypted file with helm**:
   ```bash
   helm upgrade ... -f values.yaml -f values.secret.yaml.dec
   ```

### Re-encryption After Changes
If values files were modified during upgrade:
```bash
# Re-encrypt with same settings
sops -e <file>.dec > <file>
# or with age key
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e <file>.dec > <file>

# Clean up decrypted file
rm <file>.dec
```

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
- K8s context (can be overridden by argument)

**Context priority:**
1. If context passed as argument → use argument
2. Otherwise → use context from README

### Detect Encrypted Files
Check for SOPS-encrypted files by content (not by extension):
```bash
# Find ALL SOPS-encrypted yaml files by checking content
grep -l "sops:" <app-folder>/*.yaml <app-folder>/*.yml 2>/dev/null
```

Note any encrypted files found for Step 5.

## Step 2: Validate Context

**CRITICAL:** Before any kubectl/helm operations, validate the context matches the app's target cluster.

### Check Available Contexts
```bash
kubectl config get-contexts
```

### Validate Context Exists
```bash
# Verify the context from README exists in kubeconfig
kubectl config get-contexts <context-from-readme> --no-headers
```

If context doesn't exist:
- **STOP** and inform user
- Show available contexts
- Ask user to fix kubeconfig or README

### Verify Cluster Connectivity
```bash
kubectl cluster-info --context <context>
```

If connection fails, **STOP** and report the error.

## Step 3: Pre-flight Checks

### Kubernetes MCP
```
mcp__kubernetes__list-k8s-resources (kind: Pod/Deployment/StatefulSet)
mcp__kubernetes__get-k8s-resource (get current image version)
```

### Save Pre-Deploy Metrics (Grafana MCP)

Before upgrade, capture current resource usage for before/after comparison:

```
mcp__grafana__query_prometheus with queries:

# CPU usage (save as pre_cpu)
sum(rate(container_cpu_usage_seconds_total{namespace="<namespace>", pod=~"<app>.*"}[5m])) by (pod)

# Memory usage (save as pre_memory)
sum(container_memory_working_set_bytes{namespace="<namespace>", pod=~"<app>.*"}) by (pod)
```

Save these values for Step 8 PR comment.

### Discover HTTP Endpoint (Kubernetes MCP)

Search for Ingress or HTTPRoute associated with the app:

```
# Check for Ingress
mcp__kubernetes__list-k8s-resources (kind: Ingress, namespace: <namespace>)

# Check for HTTPRoute (Gateway API)
mcp__kubernetes__list-k8s-resources (kind: HTTPRoute, namespace: <namespace>)
```

Look for resources that:
- Have name matching `<app-name>` or `*<app-name>*`
- Reference a service with name matching `<app-name>`

Extract the hostname from:
- **Ingress:** `spec.rules[].host`
- **HTTPRoute:** `spec.hostnames[]`

Save the URL (e.g., `https://<hostname>/health` or `https://<hostname>/`) for post-deploy verification.

### Grafana MCP (if available)
Search for relevant dashboards to use after deploy:
```
mcp__grafana__search_dashboards - search with patterns:
  - "<namespace>" or "<app-name>"
  - "ingress", "contour" (HTTP metrics)
  - "pod", "deployment", "namespace" (resource usage)
```

Save dashboard UIDs for post-deploy metrics collection.

Confirm:
- [ ] Context validated and connected
- [ ] App exists in cluster
- [ ] Pods are healthy before upgrade
- [ ] Note current version for rollback
- [ ] Found Ingress/HTTPRoute endpoint (if exists)
- [ ] Found relevant Grafana dashboards

## Step 4: Create Branch & PR

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
- [ ] Metrics OK (Grafana)

🤖 Generated with Claude Code"
```

## Step 5: Wait for PR Approval (Optional)

PR approval can be skipped when the user is the sole contributor (cannot self-approve on GitHub).
The interactive confirmation in Step 6 (helm diff → "proceed?") serves as the deployment gate instead.

### Determine if approval is needed

Check the number of repo collaborators:
```bash
gh api repos/{owner}/{repo}/collaborators --jq 'length'
```

**If solo contributor (1 collaborator):**
- Skip approval — inform user: "Skipping PR approval (solo contributor). Helm diff confirmation will serve as deployment gate."
- Proceed directly to Step 6.

**If team repo (>1 collaborator):**
- Check PR approval status:
```bash
gh pr view <pr-number> --json reviewDecision,reviews
```
- Poll until PR has at least one approval:
```bash
gh pr view <pr-number> --json reviewDecision -q '.reviewDecision'
# Expected: "APPROVED"
```
- If not approved:
  - Inform user: "PR requires approval before deployment. Please review and approve the PR, then run `/deploy` again or say 'continue'."
  - **STOP** and wait for user instruction

Once approved (or skipped for solo), proceed to Step 6.

## Step 6: Helm Diff & Upgrade

### 6.1 Decrypt SOPS Files (if present)

If encrypted files were found in Step 1:

```bash
# Try default key first
sops -d <app-folder>/values.secret.yaml > <app-folder>/values.secret.yaml.dec

# If fails with "could not decrypt", use age key
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d <app-folder>/values.secret.yaml > <app-folder>/values.secret.yaml.dec
```

### 6.2 Helm Diff (Preview Changes)

**IMPORTANT:** Show what will change before applying.

Install helm-diff plugin if not available:
```bash
helm plugin install https://github.com/databus23/helm-diff
```

Run diff to preview changes:

**Without encrypted files:**
```bash
helm diff upgrade <release-name> <chart> \
  -n <namespace> \
  -f <app-folder>/values.yaml \
  --version <version> \
  --kube-context <context>
```

**With encrypted files:**
```bash
helm diff upgrade <release-name> <chart> \
  -n <namespace> \
  -f <app-folder>/values.yaml \
  -f <app-folder>/values.secret.yaml.dec \
  --version <version> \
  --kube-context <context>
```

**Review the diff output:**
- Show user the changes (added/removed/modified resources)
- Highlight any potentially breaking changes (removed fields, changed ports, etc.)
- Ask user to confirm: "Proceed with upgrade? (yes/no)"

If user says no, **STOP** and clean up decrypted files.

### 6.3 Run Helm Upgrade

**Without encrypted files:**
```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f <app-folder>/values.yaml \
  --version <version> \
  --kube-context <context>
```

**With encrypted files:**
```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f <app-folder>/values.yaml \
  -f <app-folder>/values.secret.yaml.dec \
  --version <version> \
  --kube-context <context>
```

### 6.4 Clean Up Decrypted Files

```bash
# Remove decrypted files immediately after helm upgrade
rm -f <app-folder>/*.dec
```

### 6.5 Wait for Rollout

```bash
kubectl rollout status deployment/<name> -n <namespace> --timeout=300s
# or for StatefulSet:
kubectl rollout status statefulset/<name> -n <namespace> --timeout=300s
```

## Step 7: Verify with MCP

### 7.1 Kubernetes MCP
```
mcp__kubernetes__get-k8s-resource - verify new image
mcp__kubernetes__get-k8s-pod-logs - check for errors (last 100 lines)
mcp__kubernetes__list-k8s-events - check for warnings
```

### 7.2 VictoriaLogs MCP (if available)
```logsql
{kubernetes.pod_namespace="<namespace>", kubernetes.pod_name=~"<app>.*"}
| filter level:"error" OR level:"warn"
| limit 50
```

### 7.3 Wait for Metrics Collection
```bash
# Wait 60 seconds for metrics to be collected
sleep 60
```

### 7.4 Grafana MCP (if available)

Query dashboards found in Step 3 for post-deploy metrics:

**Search dashboards by pattern:**
```
mcp__grafana__search_dashboards with queries:
- "ingress" or "contour" - for HTTP status codes, request rates
- "pod" or "deployment" - for CPU/memory usage
- "namespace" - for namespace-level metrics
- "<app-name>" - for app-specific dashboards
```

**Get dashboard details:**
```
mcp__grafana__get_dashboard_by_uid - get panels and queries
```

**Query Prometheus datasource directly:**
```
mcp__grafana__query_prometheus with queries:

# CPU usage (last 5 min)
sum(rate(container_cpu_usage_seconds_total{namespace="<namespace>", pod=~"<app>.*"}[5m])) by (pod)

# Memory usage
sum(container_memory_working_set_bytes{namespace="<namespace>", pod=~"<app>.*"}) by (pod)

# HTTP request rate (if ingress exists)
sum(rate(envoy_cluster_upstream_rq_total{envoy_cluster_name=~".*<app>.*"}[5m])) by (envoy_response_code_class)

# HTTP error rate
sum(rate(envoy_cluster_upstream_rq_xx{envoy_cluster_name=~".*<app>.*", envoy_response_code_class="5"}[5m]))
```

Collect metrics for PR comment:
- CPU usage (cores)
- Memory usage (Mi/Gi)
- HTTP 2xx/4xx/5xx rates (if applicable)
- Request latency p50/p99 (if applicable)

### 7.5 HTTP Endpoint Check (if Ingress/HTTPRoute found)

If an Ingress or HTTPRoute was discovered in Step 3, verify the endpoint is responding:

```bash
# Check health/root endpoint
curl -s -o /dev/null -w "%{http_code}" https://<hostname>/health
# or
curl -s -o /dev/null -w "%{http_code}" https://<hostname>/

# Get response time
curl -s -o /dev/null -w "%{time_total}" https://<hostname>/health
```

Record:
- HTTP status code (expect 200 or 2xx)
- Response time in seconds

If endpoint returns non-2xx, this may indicate a problem (but don't auto-rollback - some apps need warm-up time).

## Step 8: Update PR

### On Success ✅
```bash
gh pr comment <pr-number> --body "## ✅ Upgrade Verified

### Pod Status
| Check | Status |
|-------|--------|
| Pod | \`<pod-name>\` |
| Image | \`<new-image>\` |
| Status | Running |
| Ready | True |
| Restarts | 0 |

### Resource Usage (before → after)
| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| CPU | \`<pre_cpu>m\` | \`<post_cpu>m\` | \`<delta>\` |
| Memory | \`<pre_mem>Mi\` | \`<post_mem>Mi\` | \`<delta>\` |

### HTTP Endpoint (if Ingress/HTTPRoute found)
| Check | Result |
|-------|--------|
| URL | \`https://<hostname>/\` |
| Status | \`200 OK\` |
| Response Time | \`<time>s\` |

### HTTP Traffic (from Grafana, if applicable)
| Code Class | Rate (req/s) |
|------------|--------------|
| 2xx | \`<rate>\` |
| 4xx | \`<rate>\` |
| 5xx | \`<rate>\` |

### Notable Changes
<List key changes from the new version: breaking changes, new features,
removed/renamed fields, port changes, etc. Get from release notes or helm diff.>

### Verification
- ✅ Pod running and ready
- ✅ No errors in logs
- ✅ Resource usage stable (no significant delta)
- ✅ HTTP endpoint responding (if applicable)

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

## Step 9: Merge or Close

Ask user:
- **Success**: Merge PR? `gh pr merge <pr-number> --merge --delete-branch`
- **Failure**: Close PR? `gh pr close <pr-number>`

---

## Reference

### Required MCP Servers

This skill uses these MCP servers (configure at user level):

| MCP Server | Purpose | Required |
|------------|---------|----------|
| kubernetes | Pod status, logs, events | Yes |
| victorialogs | Log queries | Optional |
| grafana | Metrics dashboards | Optional |

### Folder Structure Patterns

```
# Single cluster
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

### Grafana Dashboard Patterns

Search for dashboards matching these patterns for metrics:
- `*ingress*` / `*contour*` - HTTP traffic metrics
- `*pod*` / `*deployment*` - Resource usage
- `*namespace*` - Namespace-level overview
- `<app-name>` - App-specific dashboards

### Common Prometheus Queries

```promql
# CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="X", pod=~"app.*"}[5m])) by (pod)

# Memory usage
sum(container_memory_working_set_bytes{namespace="X", pod=~"app.*"}) by (pod)

# HTTP request rate by status
sum(rate(envoy_cluster_upstream_rq_total{envoy_cluster_name=~".*app.*"}[5m])) by (envoy_response_code_class)
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

### SOPS Commands Reference

```bash
# Check if file is encrypted (by content, not extension)
grep -q "sops:" <file> && echo "encrypted"

# Find all encrypted files in folder
grep -l "sops:" *.yaml *.yml 2>/dev/null

# Decrypt with default key
sops -d <file> > <file>.dec

# Decrypt with age key (fallback)
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d <file> > <file>.dec

# Edit encrypted file in-place (decrypts, opens editor, re-encrypts)
sops <file>
# or with age key
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops <file>

# Encrypt a new file (requires .sops.yaml config in repo root)
sops -e <plaintext-file> > <encrypted-file>

# Re-encrypt with age key
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e <plaintext-file> > <encrypted-file>

# Rotate keys (useful after key changes)
sops updatekeys <file>
```

### SOPS Key Locations

| Key Type | Default Location |
|----------|------------------|
| Age | `~/.config/sops/age/keys.txt` |
| PGP | GPG keyring |
| AWS KMS | AWS credentials |
| GCP KMS | GCP credentials |

### Encrypted File Detection

**IMPORTANT:** Encrypted files can have ANY extension. Detection is by **content**, not filename.

SOPS-encrypted files contain a `sops:` metadata block at the end:
```yaml
sops:
    kms: []
    age:
        - recipient: age1...
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            ...
```

Common naming conventions (but not required):
- `values.secret.yaml` - Helm secret values
- `secrets.yaml` - Generic secrets
- Any `.yaml` or `.yml` file can be encrypted

### Modifying Encrypted Values

If you need to modify an encrypted values file:

```bash
# Option 1: Edit in-place (recommended)
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops <app-folder>/values.secret.yaml

# Option 2: Decrypt, edit, re-encrypt
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d values.secret.yaml > values.secret.yaml.dec
# ... make changes to values.secret.yaml.dec ...
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e values.secret.yaml.dec > values.secret.yaml
rm values.secret.yaml.dec
```
