#!/bin/bash

# Check health of all services
# Usage: ./scripts/check-health.sh [namespace]

NAMESPACE=${1:-default}

echo "🏥 Checking health of services in namespace: $NAMESPACE"
echo ""

# Check pods
echo "📦 Pod Status:"
kubectl get pods -n $NAMESPACE -o wide

# Check deployments
echo ""
echo "🚀 Deployments:"
kubectl get deployments -n $NAMESPACE

# Check services
echo ""
echo "🔗 Services:"
kubectl get svc -n $NAMESPACE

# Check failed pods
echo ""
FAILED_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded -o json | jq -r '.items[].metadata.name' 2>/dev/null)

if [ -n "$FAILED_PODS" ]; then
    echo "❌ Failed/Pending Pods:"
    echo "$FAILED_PODS"
    echo ""
    echo "📋 Details:"
    for pod in $FAILED_PODS; do
        echo "--- Pod: $pod ---"
        kubectl describe pod $pod -n $NAMESPACE | tail -20
        echo ""
    done
else
    echo "✅ All pods are running or succeeded"
fi

# Check resource usage
echo ""
echo "📊 Resource Usage:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "⚠️  Metrics not available (metrics-server might not be installed)"

# Check recent events
echo ""
echo "📰 Recent Events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

# Overall health summary
echo ""
echo "📈 Health Summary:"
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l | tr -d ' ')
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_PODS" -eq 0 ]; then
    echo "⚠️  No pods found in namespace $NAMESPACE"
elif [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    echo "✅ All $TOTAL_PODS pods are running"
else
    echo "⚠️  $RUNNING_PODS/$TOTAL_PODS pods are running"
fi
