#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Apply all resources
oc apply -f "$SCRIPT_DIR/resources.yaml"

RHDH_URL=$(oc get route backstage-my-rhdh -o=jsonpath='{.spec.host}' 2>/dev/null || echo "pending...")
echo "RHDH URL: https://$RHDH_URL"
