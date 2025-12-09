# RHDH Configuration Examples

Configuration examples for [Red Hat Developer Hub (RHDH)](https://developers.redhat.com/rhdh), each highlighting a specific aspect of RHDH configuration.

## Examples

| Example | Description |
|---------|-------------|
| [using-single-psql-db](examples/using-single-psql-db/) | Configure RHDH to use a single PostgreSQL database with schema-based plugin isolation (no CREATEDB privilege required) |

## Usage

Each example provides two deployment options:

### Using the RHDH Operator

```bash
cd examples/<example-name>/operator/
./install.sh
```

### Using Helm

```bash
cd examples/<example-name>/helm/
./install.sh
```

## Example Contents

Each example directory contains:

```
examples/<example-name>/
├── README.md           # Documentation for this example
├── operator/
│   ├── resources.yaml  # All Kubernetes resources
│   ├── install.sh      # Installation script
│   └── uninstall.sh    # Cleanup script
└── helm/
    ├── resources.yaml  # Prerequisite resources (secrets, configmaps)
    ├── values.yaml     # Helm values file
    ├── install.sh      # Installation script
    └── uninstall.sh    # Cleanup script
```

## Prerequisites

- OpenShift cluster
- `oc` CLI configured and logged in
- For operator deployments: RHDH Operator installed
- For Helm deployments: Helm 3.x installed
