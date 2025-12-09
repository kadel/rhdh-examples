#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Uninstall the Red Hat Developer Hub Helm chart
helm uninstall rhdh || echo "Helm release 'rhdh' not found or already uninstalled"

# Delete resources created by kustomize (secret and configmaps)
oc delete -k "$SCRIPT_DIR" || echo "Kustomize resources not found or already deleted"

echo "RHDH Helm installation cleaned up successfully"

