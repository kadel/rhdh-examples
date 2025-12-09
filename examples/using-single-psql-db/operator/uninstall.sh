#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

oc delete -f "$SCRIPT_DIR/resources.yaml" --ignore-not-found
