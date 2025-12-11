#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Merge values.yaml with dynamic-plugins.yaml under global.dynamic
yq eval-all 'select(fileIndex == 0) * {"global": {"dynamic": select(fileIndex == 1)}}' \
  "$SCRIPT_DIR/values.yaml.tmpl" "$SCRIPT_DIR/configs/dynamic-plugins.yaml"