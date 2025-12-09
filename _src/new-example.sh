#!/bin/bash
#
# Scaffolds a new example overlay with proper Kustomize structure.
#
# Usage: ./new-example.sh <example-name> [description]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAYS_DIR="$SCRIPT_DIR/_overlays"

if [[ -z "$1" ]]; then
    echo "Usage: $0 <example-name> [description]"
    echo ""
    echo "Example: $0 using-github-oauth 'Configuring GitHub OAuth authentication'"
    exit 1
fi

EXAMPLE_NAME="$1"
DESCRIPTION="${2:-$EXAMPLE_NAME}"
EXAMPLE_DIR="$OVERLAYS_DIR/$EXAMPLE_NAME"

if [[ -d "$EXAMPLE_DIR" ]]; then
    echo "Error: Example '$EXAMPLE_NAME' already exists at $EXAMPLE_DIR" >&2
    exit 1
fi

echo "Creating example: $EXAMPLE_NAME"

# Create directory structure
mkdir -p "$EXAMPLE_DIR"/{helm,operator}/{configs,patches}

# Create operator kustomization
cat > "$EXAMPLE_DIR/operator/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Inherit from base
resources:
  - ../../../_base/operator
  # - secret.yaml  # Uncomment to add example-specific secrets

# Patch the Backstage CR as needed
# patches:
#   - path: patches/backstage-patch.yaml

# Add example-specific app config (separate ConfigMap, Backstage loads both)
# configMapGenerator:
#   - name: my-rhdh-example-config
#     files:
#       - app-config-example.yaml=configs/app-config.yaml
#     options:
#       disableNameSuffixHash: true
EOF

# Create helm kustomization
cat > "$EXAMPLE_DIR/helm/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Inherit from base
resources:
  - ../../../_base/helm
  # - secret.yaml  # Uncomment to add example-specific secrets
EOF

# Create helm values overlay
cat > "$EXAMPLE_DIR/helm/values-overlay.yaml" << EOF
# Helm values overlay for $EXAMPLE_NAME
# These values will be deep-merged with _src/_base/helm/values.yaml
#
# Example: Add database configuration
# upstream:
#   backstage:
#     appConfig:
#       backend:
#         database:
#           client: pg
EOF

# Create README template
cat > "$EXAMPLE_DIR/README.md.tmpl" << EOF
# $DESCRIPTION

## Overview

TODO: Describe what this example demonstrates.

## Prerequisites

- OpenShift cluster with RHDH Operator installed (for operator deployment)
- Helm 3.x (for helm deployment)

## Configuration

TODO: Explain the key configuration settings.

## Usage

### Using the RHDH Operator

\`\`\`bash
cd operator/
./install.sh
\`\`\`

### Using Helm

\`\`\`bash
cd helm/
./install.sh
\`\`\`

## Files

- \`operator/resources.yaml\` - All Kubernetes resources for operator deployment
- \`helm/resources.yaml\` - Prerequisite resources for helm deployment
- \`helm/values.yaml\` - Merged Helm values file
EOF

echo ""
echo "Created example scaffold at: $EXAMPLE_DIR"
echo ""
echo "Directory structure:"
echo "  $EXAMPLE_NAME/"
echo "  ├── operator/"
echo "  │   ├── kustomization.yaml    # Edit to add patches and configs"
echo "  │   ├── configs/              # Add app-config overlays here"
echo "  │   └── patches/              # Add Backstage CR patches here"
echo "  ├── helm/"
echo "  │   ├── kustomization.yaml    # Edit to add resources"
echo "  │   └── values-overlay.yaml   # Add Helm value overrides here"
echo "  └── README.md.tmpl            # Documentation template"
echo ""
echo "Next steps:"
echo "  1. Add your patches/configs to the overlay directories"
echo "  2. Edit README.md.tmpl with documentation"
echo "  3. Run 'make generate' to create README.md"
echo "  4. Run 'make build' to generate examples/$EXAMPLE_NAME"
