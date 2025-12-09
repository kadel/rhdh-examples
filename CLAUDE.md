# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository provides configuration examples for Red Hat Developer Hub (RHDH), demonstrating various deployment patterns. It uses a Kustomize-based overlay system to reuse base configurations across examples.

## Commands

```bash
make all                   # Build examples and generate READMEs (primary command)
make build                 # Build examples/ from _src/_overlays/ using Kustomize
make generate              # Generate README.md files from templates
make verify                # Verify README.md files are up to date
make build-verify          # Verify examples/ is up to date
make clean                 # Remove examples/ directory
./_src/new-example.sh <name>   # Scaffold a new example overlay
```

## Architecture

### Directory Structure

```
rhdh-examples/
├── _src/                  # Source: All internal configuration
│   ├── _base/             # Reusable base configurations
│   │   ├── helm/          # Base Helm values and Kustomize resources
│   │   └── operator/      # Base Backstage CR and Kustomize resources
│   ├── _components/       # Optional reusable Kustomize components
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

| Directory | Type | Purpose |
|-----------|------|---------|
| `_src/` | Source | All internal source files |
| `_src/_base/` | Source | Shared base configurations |
| `_src/_components/` | Source | Optional reusable components |
| `_src/_overlays/` | Source | Per-example customizations |
| `examples/` | **Generated** | Self-contained examples (committed) |

### Build System

1. **Kustomize overlays**: `_src/_overlays/*/operator/kustomization.yaml` references `../../../_base/operator`
2. **build.sh**: Runs `kustomize build` and merges Helm values with `yq`
3. **generate.sh**: Processes `README.md.tmpl` with `{{include:path}}` directives

## Workflow

### Creating a New Example

```bash
./_src/new-example.sh my-example "Description of the example"
# Edit _src/_overlays/my-example/operator/kustomization.yaml
# Add patches in _src/_overlays/my-example/operator/patches/
# Edit _src/_overlays/my-example/README.md.tmpl
make all
```

### Modifying an Example

1. Edit source files in `_src/_overlays/<example>/`
2. Run `make all` to rebuild `examples/`
3. Commit both `_src/_overlays/` and `examples/` changes
