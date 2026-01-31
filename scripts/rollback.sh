#!/bin/bash

# Rollback service to previous version
# Usage: ./scripts/rollback.sh <service-name> [namespace] [revision]

set -e

SERVICE_NAME=$1
NAMESPACE=${2:-default}
REVISION=${3:-0}  # 0 means previous revision

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <service-name> [namespace] [revision]"
    echo "Example: $0 blog production 2"
    echo "         $0 blog production (rollback to previous)"
    exit 1
fi

echo "⏪ Rolling back $SERVICE_NAME in namespace $NAMESPACE"

# Show current revision
echo "📊 Current deployment status:"
kubectl get deployment $SERVICE_NAME -n $NAMESPACE

# Show rollout history
echo ""
echo "📜 Rollout history:"
kubectl rollout history deployment/$SERVICE_NAME -n $NAMESPACE

# Perform rollback
echo ""
if [ "$REVISION" -eq 0 ]; then
    echo "🔄 Rolling back to previous revision..."
    kubectl rollout undo deployment/$SERVICE_NAME -n $NAMESPACE
else
    echo "🔄 Rolling back to revision $REVISION..."
    kubectl rollout undo deployment/$SERVICE_NAME -n $NAMESPACE --to-revision=$REVISION
fi

# Wait for rollback to complete
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE --timeout=5m

# Show final status
echo ""
echo "✅ Rollback completed successfully!"
echo ""
echo "📊 Current status:"
kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME

# Also rollback Helm release if exists
if helm list -n $NAMESPACE | grep -q $SERVICE_NAME; then
    echo ""
    echo "🔄 Rolling back Helm release..."
    if [ "$REVISION" -eq 0 ]; then
        helm rollback $SERVICE_NAME -n $NAMESPACE
    else
        helm rollback $SERVICE_NAME $REVISION -n $NAMESPACE
    fi
    echo "✅ Helm rollback completed"
fi
