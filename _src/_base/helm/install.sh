#!/bin/sh

set -e
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add the OpenShift Helm charts repository
helm repo add openshift-helm-charts https://charts.openshift.io/

# Update the Helm repositories
helm repo update

# Get the cluster router base from the console route of the OpenShift cluster
CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')


echo "Using cluster router base: https://$CLUSTER_ROUTER_BASE"

# Copy the configs to the script directory
rm -rf "$SCRIPT_DIR/configs"
cp -r "$SCRIPT_DIR/../configs" "$SCRIPT_DIR/configs"

# Apply extra app config
oc apply -k "$SCRIPT_DIR"

$SCRIPT_DIR/generate_merged_values.sh > "$SCRIPT_DIR/values.yaml"

# Install the Red Hat Developer Hub Helm chart
helm upgrade --install rhdh openshift-helm-charts/redhat-developer-hub \
  --values "$SCRIPT_DIR/values.yaml" \
  --set global.clusterRouterBase="$CLUSTER_ROUTER_BASE"


RHDH_URL=$(oc get route rhdh-developer-hub -o=jsonpath='{.spec.host}')
echo "RHDH URL: https://$RHDH_URL"