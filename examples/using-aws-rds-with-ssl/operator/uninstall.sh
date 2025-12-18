#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Delete the RHDH Backstage CR
oc delete -f "$SCRIPT_DIR/rhdh.yaml" --ignore-not-found

# Delete Kubernetes resources
oc delete -f "$SCRIPT_DIR/resources/" --ignore-not-found
