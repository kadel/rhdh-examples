#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"


# Delete resources created by kustomize (secret and configmaps)
oc delete -k "$SCRIPT_DIR" || echo "Kustomize resources not found or already deleted"

echo "RHDH Operator installation cleaned up successfully"

