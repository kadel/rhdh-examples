#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Apply Kubernetes resources
oc apply -f "$SCRIPT_DIR/resources/"

# Apply the RHDH Backstage CR
oc apply -f "$SCRIPT_DIR/rhdh.yaml"

echo "Waiting for RHDH route to be available..."
sleep 5

RHDH_URL=$(oc get route backstage-my-rhdh -o=jsonpath='{.spec.host}' 2>/dev/null || echo "Route not yet available")
echo "RHDH URL: https://$RHDH_URL"
