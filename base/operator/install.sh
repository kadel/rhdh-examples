#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Apply extra app config
oc apply -k "$SCRIPT_DIR"

RHDH_URL=$(oc get route backstage-my-rhdh -o=jsonpath='{.spec.host}')
echo "RHDH URL: https://$RHDH_URL"