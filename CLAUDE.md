# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository provides configuration examples for Red Hat Developer Hub (RHDH), demonstrating various deployment and plugin development 
patterns.

## Commands

```bash
make generate              # Generate all README.md files from templates
make verify                # Verify all README.md files are up to date (for CI)
./generate.sh <dir>        # Generate README for a specific directory
./generate.sh --verify     # Verify mode (returns non-zero if out of date)
```

## Architecture

### Documentation Generation System

README.md files are generated from `.tmpl` templates using `generate.sh`. The template syntax uses `{{include:path}}` directives to inline actual YAML configuration files.

**Flow:** `README.md.tmpl` → `generate.sh` → `README.md`

Example template directive:
```
{{include:operator/secret.yaml}}
```

This ensures documentation always contains working, up-to-date configuration examples.

### Example Structure Pattern

Each example directory follows this structure:
```
example-name/
├── README.md.tmpl          # Template with {{include:...}} directives
├── README.md               # Generated documentation (do not edit directly)
├── operator/               # Kubernetes Operator deployment configs
│   └── *.yaml
└── helm/                   # Helm chart deployment configs
    └── *.yaml
```

## Workflow

1. Edit YAML files in `operator/` or `helm/` directories
2. Edit `README.md.tmpl` if documentation text needs changes
3. Run `make generate` to regenerate README.md
4. Verify with `make verify` before committing
