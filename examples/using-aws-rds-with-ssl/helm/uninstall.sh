#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Uninstall the Helm release
helm uninstall rhdh

# Delete Kubernetes resources
oc delete -f "$SCRIPT_DIR/resources/" --ignore-not-found
