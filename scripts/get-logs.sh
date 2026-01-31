#!/bin/bash

# Get logs for a service
# Usage: ./scripts/get-logs.sh <service-name> [namespace] [options]

SERVICE_NAME=$1
NAMESPACE=${2:-default}
TAIL_LINES=${3:-100}

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <service-name> [namespace] [tail-lines]"
    echo "Example: $0 blog production 200"
    exit 1
fi

echo "📋 Getting logs for $SERVICE_NAME in namespace $NAMESPACE"
echo ""

# Get all pods for the service
PODS=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "❌ No pods found for service $SERVICE_NAME in namespace $NAMESPACE"
    exit 1
fi

echo "📦 Found pods: $PODS"
echo ""

# Get logs from each pod
for POD in $PODS; do
    echo "================================"
    echo "📄 Logs from pod: $POD"
    echo "================================"
    
    # Check if pod has multiple containers
    CONTAINERS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}')
    
    for CONTAINER in $CONTAINERS; do
        echo ""
        echo "--- Container: $CONTAINER ---"
        kubectl logs $POD -n $NAMESPACE -c $CONTAINER --tail=$TAIL_LINES
        
        # Also show previous logs if pod has restarted
        RESTART_COUNT=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[?(@.name=="'$CONTAINER'")].restartCount}')
        if [ "$RESTART_COUNT" -gt 0 ]; then
            echo ""
            echo "⚠️  Pod has restarted $RESTART_COUNT times. Showing previous logs:"
            kubectl logs $POD -n $NAMESPACE -c $CONTAINER --previous --tail=$TAIL_LINES 2>/dev/null || echo "Previous logs not available"
        fi
    done
    
    echo ""
done

# Follow logs option
read -p "Do you want to follow logs in real-time? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📡 Following logs (Ctrl+C to stop)..."
    kubectl logs -f -n $NAMESPACE -l app=$SERVICE_NAME --all-containers=true --tail=50
fi
