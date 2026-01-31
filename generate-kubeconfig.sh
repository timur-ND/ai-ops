#!/bin/bash
#
# Generate kubeconfig for ai-ops ServiceAccount
#
# Usage:
#   ./generate-kubeconfig.sh [context]
#
# Output:
#   ./kubeconfig-ai-ops.yaml
#

set -e

CONTEXT="${1:-pudink}"
NAMESPACE="monitoring"
SERVICE_ACCOUNT="ai-ops"
OUTPUT_FILE="kubeconfig-ai-ops.yaml"

echo "Generating kubeconfig for ServiceAccount '$SERVICE_ACCOUNT' in namespace '$NAMESPACE'"
echo "Using context: $CONTEXT"
echo ""

# Switch to target context
kubectl config use-context "$CONTEXT" > /dev/null

# Get cluster info
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# Create token (valid for 1 year)
echo "Creating token..."
TOKEN=$(kubectl create token "$SERVICE_ACCOUNT" \
  --namespace "$NAMESPACE" \
  --duration=8760h)

# Generate kubeconfig
cat > "$OUTPUT_FILE" << EOF
apiVersion: v1
kind: Config
current-context: ai-ops
clusters:
  - name: $CLUSTER_NAME
    cluster:
      server: $CLUSTER_SERVER
      certificate-authority-data: $CLUSTER_CA
contexts:
  - name: ai-ops
    context:
      cluster: $CLUSTER_NAME
      namespace: $NAMESPACE
      user: ai-ops
users:
  - name: ai-ops
    user:
      token: $TOKEN
EOF

echo ""
echo "Kubeconfig generated: $OUTPUT_FILE"
echo ""
echo "Permissions:"
echo "  - Read-only: entire cluster"
echo "  - Full access: namespace '$NAMESPACE'"
echo ""
echo "Usage with docker-compose:"
echo "  export KUBECONFIG=\$(pwd)/$OUTPUT_FILE"
echo "  docker-compose up -d"
echo ""
echo "Or copy to ~/.kube/:"
echo "  cp $OUTPUT_FILE ~/.kube/config-ai-ops"
echo "  export KUBECONFIG=~/.kube/config-ai-ops"
