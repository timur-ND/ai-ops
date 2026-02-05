#!/bin/bash
#
# Generate merged kubeconfig for multiple clusters
#
# Usage:
#   ./generate-kubeconfig-multi.sh <context1> [context2] [context3] ...
#
# Examples:
#   ./generate-kubeconfig-multi.sh production staging
#   ./generate-kubeconfig-multi.sh prod-us prod-eu staging
#
# Prerequisites:
#   - kubectl configured with access to all target clusters
#   - ai-ops ServiceAccount created in each cluster (see k8s-mcp-rbac.yaml)
#
# Output:
#   ./kubeconfig-ai-ops-multi.yaml
#

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <context1> [context2] [context3] ..."
    echo ""
    echo "Examples:"
    echo "  $0 production staging"
    echo "  $0 prod-us prod-eu staging"
    echo ""
    echo "Available contexts:"
    kubectl config get-contexts -o name
    exit 1
fi

NAMESPACE="monitoring"
SERVICE_ACCOUNT="ai-ops"
OUTPUT_FILE="kubeconfig-ai-ops-multi.yaml"
CONTEXTS=("$@")

echo "=== Multi-Cluster Kubeconfig Generator ==="
echo ""
echo "Contexts to include: ${CONTEXTS[*]}"
echo "ServiceAccount: $SERVICE_ACCOUNT"
echo "Namespace: $NAMESPACE"
echo ""

# Initialize kubeconfig structure
CLUSTERS=""
CONTEXTS_YAML=""
USERS=""

for CTX in "${CONTEXTS[@]}"; do
    echo "Processing context: $CTX"

    # Switch to target context
    kubectl config use-context "$CTX" > /dev/null 2>&1 || {
        echo "  ERROR: Context '$CTX' not found. Skipping."
        continue
    }

    # Get cluster info
    CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
    CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

    # Check if ServiceAccount exists
    if ! kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" > /dev/null 2>&1; then
        echo "  WARNING: ServiceAccount '$SERVICE_ACCOUNT' not found in namespace '$NAMESPACE'"
        echo "  Run: kubectl apply -f k8s-mcp-rbac.yaml --context $CTX"
        continue
    fi

    # Create token (valid for 1 year)
    echo "  Creating token..."
    TOKEN=$(kubectl create token "$SERVICE_ACCOUNT" \
        --namespace "$NAMESPACE" \
        --duration=8760h 2>/dev/null) || {
        echo "  ERROR: Failed to create token for context '$CTX'"
        continue
    }

    # Use context name as unique identifier
    UNIQUE_NAME="$CTX"

    # Append cluster
    CLUSTERS+="  - name: $UNIQUE_NAME
    cluster:
      server: $CLUSTER_SERVER
      certificate-authority-data: $CLUSTER_CA
"

    # Append context
    CONTEXTS_YAML+="  - name: $UNIQUE_NAME
    context:
      cluster: $UNIQUE_NAME
      namespace: $NAMESPACE
      user: $UNIQUE_NAME
"

    # Append user
    USERS+="  - name: $UNIQUE_NAME
    user:
      token: $TOKEN
"

    echo "  OK: Added context '$UNIQUE_NAME'"
done

# Check if we have any valid contexts
if [ -z "$CLUSTERS" ]; then
    echo ""
    echo "ERROR: No valid contexts processed. Ensure:"
    echo "  1. Contexts exist in your kubeconfig"
    echo "  2. ServiceAccount '$SERVICE_ACCOUNT' is created in each cluster"
    echo "  3. You have permissions to create tokens"
    exit 1
fi

# Determine default context (first one)
DEFAULT_CONTEXT="${CONTEXTS[0]}"

# Generate merged kubeconfig
cat > "$OUTPUT_FILE" << EOF
apiVersion: v1
kind: Config
current-context: $DEFAULT_CONTEXT
clusters:
$CLUSTERS
contexts:
$CONTEXTS_YAML
users:
$USERS
EOF

echo ""
echo "=== Kubeconfig Generated ==="
echo "File: $OUTPUT_FILE"
echo ""
echo "Included contexts:"
for CTX in "${CONTEXTS[@]}"; do
    echo "  - $CTX"
done
echo ""
echo "Default context: $DEFAULT_CONTEXT"
echo ""
echo "Permissions per cluster:"
echo "  - Read-only: entire cluster"
echo "  - Full access: namespace '$NAMESPACE'"
echo ""
echo "Usage:"
echo "  # Test specific context"
echo "  kubectl --kubeconfig=$OUTPUT_FILE --context=<context> get pods -A"
echo ""
echo "  # Use with MCP server"
echo "  docker run -i --rm -v \$(pwd)/$OUTPUT_FILE:/home/nonroot/.kube/config:ro mcpk8s/server:latest"
