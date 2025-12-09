#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

helm uninstall rhdh --ignore-not-found 2>/dev/null || true
oc delete -f "$SCRIPT_DIR/resources.yaml" --ignore-not-found
