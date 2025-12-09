# Contributing

This document explains how this repository is structured and the steps required to add new examples.

## Repository Structure

This repository uses a Kustomize-based overlay system to reuse base configurations across examples.

```
rhdh-examples/
├── _src/                  # Source: All internal configuration
│   ├── _base/             # Reusable base configurations
│   │   ├── helm/          # Base Helm values and Kustomize resources
│   │   └── operator/      # Base Backstage CR and Kustomize resources
│   │
│   ├── _components/       # Optional reusable Kustomize components
│   │
│   └── _overlays/         # Per-example customizations
│       └── <example-name>/
│           ├── README.md.tmpl # Documentation template
│           ├── operator/
│           │   ├── kustomization.yaml  # References ../../../_base/operator
│           │   ├── patches/            # Strategic merge patches
│           │   └── configs/            # Overlay-specific configs
│           └── helm/
│               ├── kustomization.yaml  # References ../../../_base/helm
│               └── values-overlay.yaml # Merged with base values.yaml
│
└── examples/              # Generated: Self-contained examples
    └── <example-name>/
        ├── README.md
        ├── operator/
        │   ├── resources.yaml      # kustomize build output
        │   └── install.sh
        └── helm/
            ├── resources.yaml
            ├── values.yaml         # Merged values
            └── install.sh
```

### Source vs Generated

| Directory | Type | Description |
|-----------|------|-------------|
| `_src/` | Source | All internal source files |
| `_src/_base/` | Source | Shared base configurations inherited by all examples |
| `_src/_components/` | Source | Optional reusable Kustomize components |
| `_src/_overlays/` | Source | Per-example customizations and patches |
| `examples/` | **Generated** | Built output, committed to git |

## Build System

### Commands

```bash
make all            # Build examples and generate READMEs (primary command)
make build          # Build examples/ from _src/_overlays/ using Kustomize
make generate       # Generate README.md files from templates
make verify         # Verify README.md files are up to date
make build-verify   # Verify examples/ is up to date
make clean          # Remove examples/ directory
```

### How It Works

1. **Kustomize overlays**: Each `_src/_overlays/*/operator/kustomization.yaml` references `../../../_base/operator` and adds patches
2. **build.sh**: Runs `kustomize build` for each overlay and merges Helm values using `yq`
3. **generate.sh**: Processes `README.md.tmpl` files, replacing `{{include:path}}` directives with file contents

### Dependencies

- `kustomize` - For building Kubernetes resources
- `yq` - For merging YAML files (Helm values)

Install on macOS:
```bash
brew install kustomize yq
```

## Adding a New Example

### 1. Scaffold the Example

```bash
./_src/new-example.sh my-example "Description of what this example demonstrates"
```

This creates the directory structure in `_src/_overlays/my-example/`.

### 2. Configure the Operator Overlay

Edit `_src/_overlays/my-example/operator/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../_base/operator
  - secret.yaml  # Add example-specific resources

patches:
  - path: patches/backstage-patch.yaml  # Add patches

configMapGenerator:
  - name: my-rhdh-example-config
    files:
      - app-config-example.yaml=configs/app-config.yaml
    options:
      disableNameSuffixHash: true
```

Add patches in `_src/_overlays/my-example/operator/patches/` and configs in `_src/_overlays/my-example/operator/configs/`.

### 3. Configure the Helm Overlay

Edit `_src/_overlays/my-example/helm/values-overlay.yaml` with Helm value overrides:

```yaml
upstream:
  backstage:
    appConfig:
      # Your configuration here
```

Add any additional Kubernetes resources (secrets, configmaps) to the `kustomization.yaml`.

### 4. Write Documentation

Edit `_src/_overlays/my-example/README.md.tmpl`:

- Use `{{include:path}}` to embed YAML files from the overlay
- Paths are relative to the template file location
- Explain what the example demonstrates and how to use it

### 5. Build and Test

```bash
make all
```

This generates `examples/my-example/` with all resources and documentation.

### 6. Verify the Build

```bash
kustomize build _src/_overlays/my-example/operator
kustomize build _src/_overlays/my-example/helm
```

### 7. Commit

Commit both the source (`_src/_overlays/`) and generated (`examples/`) directories:

```bash
git add _src/_overlays/my-example examples/my-example
git commit -m "Add my-example configuration example"
```

## Modifying an Existing Example

1. Edit files in `_src/_overlays/<example-name>/`
2. Run `make all` to rebuild
3. Commit both `_src/_overlays/` and `examples/` changes

## Updating the Base Configuration

Changes to `_src/_base/` affect all examples. After modifying base:

```bash
make all  # Rebuild all examples
```

Review changes across all examples before committing.
