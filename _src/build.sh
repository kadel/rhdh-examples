#!/bin/bash
#
# Builds self-contained example distributions from overlays using Kustomize.
# Output goes to examples/ directory (committed to git for easy customer access).
#
# Usage:
#   ./build.sh                    # Build all examples
#   ./build.sh <example-name>     # Build specific example
#   ./build.sh --verify           # Verify examples/ is up to date
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OVERLAYS_DIR="$SCRIPT_DIR/_overlays"
BASE_DIR="$SCRIPT_DIR/_base"
EXAMPLES_DIR="$ROOT_DIR/examples"

# Check for required tools
check_dependencies() {
    if ! command -v kustomize &> /dev/null; then
        echo "Error: kustomize is required but not installed." >&2
        echo "Install with: brew install kustomize" >&2
        exit 1
    fi

    if ! command -v yq &> /dev/null; then
        echo "Error: yq is required but not installed." >&2
        echo "Install with: brew install yq" >&2
        exit 1
    fi
}

# Generate install script for operator deployment
generate_operator_install_script() {
    local output_dir="$1"
    cat > "$output_dir/install.sh" << 'SCRIPT'
#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Apply all resources
oc apply -f "$SCRIPT_DIR/resources.yaml"

RHDH_URL=$(oc get route backstage-my-rhdh -o=jsonpath='{.spec.host}' 2>/dev/null || echo "pending...")
echo "RHDH URL: https://$RHDH_URL"
SCRIPT
    chmod +x "$output_dir/install.sh"

    cat > "$output_dir/uninstall.sh" << 'SCRIPT'
#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

oc delete -f "$SCRIPT_DIR/resources.yaml" --ignore-not-found
SCRIPT
    chmod +x "$output_dir/uninstall.sh"
}

# Generate install script for helm deployment
generate_helm_install_script() {
    local output_dir="$1"
    cat > "$output_dir/install.sh" << 'SCRIPT'
#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add the OpenShift Helm charts repository
helm repo add openshift-helm-charts https://charts.openshift.io/
helm repo update

# Get the cluster router base
CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')
echo "Using cluster router base: https://$CLUSTER_ROUTER_BASE"

# Apply prerequisite resources (secrets, configmaps)
oc apply -f "$SCRIPT_DIR/resources.yaml"

# Install the Red Hat Developer Hub Helm chart
helm upgrade --install rhdh openshift-helm-charts/redhat-developer-hub \
  --values "$SCRIPT_DIR/values.yaml" \
  --set global.clusterRouterBase="$CLUSTER_ROUTER_BASE"

RHDH_URL=$(oc get route rhdh-developer-hub -o=jsonpath='{.spec.host}' 2>/dev/null || echo "pending...")
echo "RHDH URL: https://$RHDH_URL"
SCRIPT
    chmod +x "$output_dir/install.sh"

    cat > "$output_dir/uninstall.sh" << 'SCRIPT'
#!/bin/sh
set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

helm uninstall rhdh --ignore-not-found 2>/dev/null || true
oc delete -f "$SCRIPT_DIR/resources.yaml" --ignore-not-found
SCRIPT
    chmod +x "$output_dir/uninstall.sh"
}

# Merge helm values files (base + overlay)
merge_helm_values() {
    local overlay_dir="$1"
    local output_file="$2"

    local base_values="$BASE_DIR/helm/values.yaml"
    local overlay_values="$overlay_dir/values-overlay.yaml"

    if [[ -f "$overlay_values" ]]; then
        # Deep merge: base * overlay
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$base_values" "$overlay_values" > "$output_file"
    else
        # No overlay, just copy base
        cp "$base_values" "$output_file"
    fi
}

# Build a single example
build_example() {
    local example_name="$1"
    local overlay_dir="$OVERLAYS_DIR/$example_name"
    local output_dir="$EXAMPLES_DIR/$example_name"

    if [[ ! -d "$overlay_dir" ]]; then
        echo "Error: Overlay '$example_name' not found at $overlay_dir" >&2
        return 1
    fi

    echo "Building: $example_name" >&2

    # Create output directory (preserve README.md if it exists)
    mkdir -p "$output_dir"

    # Build operator configuration
    if [[ -d "$overlay_dir/operator" ]]; then
        mkdir -p "$output_dir/operator"
        kustomize build "$overlay_dir/operator" > "$output_dir/operator/resources.yaml"
        generate_operator_install_script "$output_dir/operator"
        echo "  ✓ operator/resources.yaml" >&2
    fi

    # Build helm configuration
    if [[ -d "$overlay_dir/helm" ]]; then
        mkdir -p "$output_dir/helm"
        kustomize build "$overlay_dir/helm" > "$output_dir/helm/resources.yaml"
        merge_helm_values "$overlay_dir/helm" "$output_dir/helm/values.yaml"
        generate_helm_install_script "$output_dir/helm"
        echo "  ✓ helm/resources.yaml" >&2
        echo "  ✓ helm/values.yaml (merged)" >&2
    fi
}

# Verify examples are up to date
verify_example() {
    local example_name="$1"
    local overlay_dir="$OVERLAYS_DIR/$example_name"
    local output_dir="$EXAMPLES_DIR/$example_name"

    if [[ ! -d "$output_dir" ]]; then
        echo "✗ $example_name: examples/$example_name does not exist" >&2
        return 1
    fi

    # Build to temp directory
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Temporarily redirect output
    local orig_examples_dir="$EXAMPLES_DIR"
    EXAMPLES_DIR="$tmp_dir"
    build_example "$example_name" 2>/dev/null
    EXAMPLES_DIR="$orig_examples_dir"

    # Compare
    if diff -r "$tmp_dir/$example_name" "$output_dir" > /dev/null 2>&1; then
        echo "✓ $example_name is up to date"
        rm -rf "$tmp_dir"
        return 0
    else
        echo "✗ $example_name is out of date. Run './build.sh $example_name' to update." >&2
        rm -rf "$tmp_dir"
        return 1
    fi
}

# Main logic
main() {
    local verify=false
    local target=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verify)
                verify=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--verify] [example-name]"
                echo ""
                echo "Builds self-contained example configurations from overlays."
                echo ""
                echo "Options:"
                echo "  --verify        Check if examples/ is up to date"
                echo "  example-name    Build only the specified example"
                echo ""
                echo "Examples are built from _src/_overlays/ to examples/ directory."
                exit 0
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    check_dependencies

    local exit_code=0

    if [[ -n "$target" ]]; then
        if [[ "$verify" == true ]]; then
            verify_example "$target" || exit_code=1
        else
            build_example "$target" || exit_code=1
        fi
    else
        # Process all overlays
        local found=false
        for overlay_dir in "$OVERLAYS_DIR"/*/; do
            if [[ -d "$overlay_dir" ]]; then
                found=true
                local example_name
                example_name=$(basename "$overlay_dir")
                if [[ "$verify" == true ]]; then
                    verify_example "$example_name" || exit_code=1
                else
                    build_example "$example_name" || exit_code=1
                fi
            fi
        done

        if [[ "$found" == false ]]; then
            echo "No overlays found in $_OVERLAYS_DIR" >&2
            exit 1
        fi
    fi

    if [[ "$verify" != true && $exit_code -eq 0 ]]; then
        echo "Build complete!" >&2
    fi

    exit $exit_code
}

main "$@"
