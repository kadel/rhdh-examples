# CLAUDE.md - Project Guide for AI Assistants

## Project Overview

This is a **Red Hat Developer Hub (RHDH) Examples Repository** that demonstrates various deployment configurations for RHDH/Backstage. It uses a build system to generate complete deployment examples from reusable base configurations and example-specific overlays.

### Key Features
- **Build System**: Node.js builder that merges base configs with example overlays
- **Dual Output**: Generates both Helm chart and RHDH Operator deployment artifacts
- **Kustomize Integration**: Uses `kubectl kustomize` to generate Kubernetes resources
- **Comment Preservation**: YAML AST manipulation preserves comments during merging
- **Template System**: README templating with file inclusion (`{{include:path}}`)

## Directory Structure

```
rhdh-examples/
├── _src/                          # SOURCE (not deployed)
│   ├── build.js                   # Build script
│   ├── _base/                     # BASE CONFIGURATIONS
│   │   ├── config/
│   │   │   ├── app-config.yaml    # Base Backstage config
│   │   │   ├── dynamic-plugins.yaml
│   │   │   ├── secrets.env
│   │   │   └── kustomization.yaml
│   │   ├── helm/
│   │   │   ├── values.yaml.tmpl   # Base Helm values
│   │   │   ├── install.sh
│   │   │   └── uninstall.sh
│   │   └── operator/
│   │       ├── rhdh.yaml          # Base Backstage CR
│   │       ├── install.sh
│   │       └── uninstall.sh
│   └── _examples/                 # EXAMPLE OVERLAYS
│       └── <example-name>/
│           ├── README.md.tmpl
│           ├── config/            # Config overlays
│           ├── helm/patches/      # Helm values overlay
│           ├── operator/patches/  # Operator CR overlay
│           ├── extra-services/    # Additional K8s resources
│           └── terraform/         # Optional: IaC files
│
├── examples/                      # GENERATED OUTPUT
│   └── <example-name>/
│       ├── README.md
│       ├── config/                # Merged configs
│       ├── helm/                  # Helm deployment
│       │   ├── values.yaml
│       │   ├── install.sh
│       │   ├── uninstall.sh
│       │   └── resources/
│       ├── operator/              # Operator deployment
│       │   ├── rhdh.yaml
│       │   ├── install.sh
│       │   ├── uninstall.sh
│       │   └── resources/
│       └── terraform/             # Copied from source
│
├── package.json
└── README.md
```

## Key Commands

```bash
npm run build    # Build all examples from _src to examples/
npm run clean    # Remove examples/ directory
```

## Build System (`_src/build.js`)

### Build Flow
1. **Discovery**: Scan `_src/_examples/` for example directories
2. **Config Merging**: Deep merge base + overlay configs with comment preservation
3. **Kustomize**: Run `kubectl kustomize` to generate K8s resources
4. **Helm Output**: Generate values.yaml with embedded configs
5. **Operator Output**: Generate merged Backstage CR
6. **Special Dirs**: Copy `extra-services/` to resources/, `terraform/` to output
7. **README**: Process templates with `{{include:path}}` syntax

### Merging Strategies

| File Type | Strategy |
|-----------|----------|
| `app-config.yaml` | Deep merge with comment preservation |
| `secrets.env` | Key-value overlay (overlay wins) |
| `dynamic-plugins.yaml` | Base only (no overlay) |
| `kustomization.yaml` | Array concatenation for generators/resources |
| `values.yaml` | Deep merge with comment preservation |
| `rhdh.yaml` | Deep merge with comment preservation |

### Comment Preservation
Uses `yaml` package (eemeli/yaml) with Document API:
- `YAML.parseDocument()` preserves comments as AST nodes
- `mergeYamlDocuments()` recursively merges while keeping comments
- Overlay comments take precedence when conflicting

## Configuration Patterns

### Adding Config Overlay
```yaml
# _src/_examples/<name>/config/app-config.yaml
backend:
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
```

### Adding Secrets
```bash
# _src/_examples/<name>/config/secrets.env
POSTGRES_HOST=localhost
POSTGRES_PASSWORD=changeme
```

### Helm Values Patch
```yaml
# _src/_examples/<name>/helm/patches/values.yaml
upstream:
  postgresql:
    enabled: false
```

### Operator CR Patch
```yaml
# _src/_examples/<name>/operator/patches/rhdh.yaml
spec:
  database:
    enableLocalDb: false
```

### Extra Kustomize Resources
```yaml
# _src/_examples/<name>/config/kustomization.yaml
configMapGenerator:
  - name: my-cert
    files:
      - ca-bundle.pem
    options:
      disableNameSuffixHash: true
```

## Output Differences: Helm vs Operator

| Aspect | Helm | Operator |
|--------|------|----------|
| Main Config | `values.yaml` (all-in-one) | `rhdh.yaml` + ConfigMaps |
| App Config | Embedded in `upstream.backstage.appConfig` | Separate ConfigMap |
| Dynamic Plugins | Embedded in `global.dynamic` | Separate ConfigMap |
| Deployment | `helm upgrade --install` | `oc apply -f rhdh.yaml` |

## Template System

README templates use `{{include:relative/path}}` syntax:
```markdown
## Configuration
```yaml
{{include:config/app-config.yaml}}
```
```

Paths resolve relative to `_src/_examples/<name>/`.

## Adding a New Example

1. Create directory: `mkdir -p _src/_examples/my-example`
2. Create README template: `_src/_examples/my-example/README.md.tmpl`
3. Add config overlays in `config/` (optional)
4. Add Helm patches in `helm/patches/values.yaml` (optional)
5. Add Operator patches in `operator/patches/rhdh.yaml` (optional)
6. Add extra K8s resources in `extra-services/` (optional)
7. Add Terraform files in `terraform/` (optional)
8. Run `npm run build`
9. Commit both `_src/_examples/my-example/` and `examples/my-example/`

## Dependencies

- **yaml** (^2.6.0): YAML parsing with comment preservation
- **kubectl**: Required for `kubectl kustomize` command

## Conventions

- Example names: `using-<description>` (kebab-case)
- Resource file naming: `<kind>-<name>.yaml`
- Template suffix: `.tmpl` for processed files
- Patches directory: `patches/` under `helm/` or `operator/`

## Common Issues

- **Kustomize fails**: Ensure `kubectl` is installed
- **Comments lost**: Use `YAML.parseDocument()`, not `YAML.parse()`
- **Arrays not merging**: YAML overlays replace arrays entirely
- **Template include fails**: Check path is relative to example source dir
