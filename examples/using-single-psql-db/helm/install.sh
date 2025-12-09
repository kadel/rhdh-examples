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
