#!/bin/bash

# Deploy service script for AI-driven deployments
# Usage: ./scripts/deploy-service.sh <service-name> <version> [namespace]

set -e

SERVICE_NAME=$1
VERSION=$2
NAMESPACE=${3:-default}

if [ -z "$SERVICE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <service-name> <version> [namespace]"
    echo "Example: $0 blog 2.0.0 production"
    exit 1
fi

echo "🚀 Deploying $SERVICE_NAME version $VERSION to namespace $NAMESPACE"

# Check if helm chart exists
CHART_PATH="./helm-charts/$SERVICE_NAME"
if [ ! -d "$CHART_PATH" ]; then
    echo "❌ Helm chart not found at $CHART_PATH"
    exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy using Helm
echo "📦 Installing/Upgrading Helm release..."
helm upgrade --install $SERVICE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --set image.tag=$VERSION \
    --wait \
    --timeout 5m

echo "✅ Deployment completed successfully"

# Show deployment status
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME

echo ""
echo "🔗 Services:"
kubectl get svc -n $NAMESPACE -l app=$SERVICE_NAME

# Get deployment rollout status
echo ""
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE --timeout=5m

echo ""
echo "✨ Deployment of $SERVICE_NAME version $VERSION completed successfully!"
