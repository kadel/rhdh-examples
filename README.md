# RHDH Examples

A collection of examples demonstrating various configurations and deployment patterns for Red Hat Developer Hub (RHDH).

## Quick Start

### Browse Examples

See the [examples/](examples/) directory for ready-to-use deployment configurations:

| Example | Description |
|---------|-------------|
| [using-single-psql-db](examples/using-single-psql-db/) | Configure RHDH to use a single PostgreSQL database with schemas |

Each example includes:
- **README.md** - Documentation and explanation
- **helm/** - Helm-based deployment
- **operator/** - RHDH Operator-based deployment

### Deploy an Example

```bash
cd examples/<example-name>

# Using Helm
cd helm && ./install.sh

# OR using the RHDH Operator
cd operator && ./install.sh
```

## Project Structure

```
rhdh-examples/
├── README.md                  # This file
├── examples/                  # Generated deployment-ready examples
│   └── <example-name>/
│       ├── README.md
│       ├── helm/
│       │   ├── install.sh
│       │   ├── uninstall.sh
│       │   ├── values.yaml.tmpl
│       │   └── configs/
│       └── operator/
│           ├── install.sh
│           ├── uninstall.sh
│           ├── rhdh.yaml
│           └── configs/
└── _src/                      # Source files for building examples
    ├── build.sh               # Build script
    ├── new-example.sh         # Scaffold new examples
    ├── validate.sh            # Validate examples
    ├── _base/                  # Shared base configurations
    │   ├── configs/           # Shared app configs
    │   ├── helm/              # Helm deployment base
    │   ├── operator/          # Operator deployment base
    │   └── templates/         # Shared README templates
    └── _examples/             # Example-specific sources
        └── <example-name>/
            ├── README.md.tmpl
            ├── configs/
            ├── helm/patches/
            └── operator/patches/
```

## For Contributors

### Prerequisites

- [yq](https://github.com/mikefarah/yq) - YAML processor (install with `brew install yq`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) or `oc` CLI
- Access to an OpenShift cluster (for testing)

### Creating a New Example

1. **Scaffold the example:**
   ```bash
   cd _src
   ./new-example.sh my-new-example --title "My New Example"
   ```

2. **Edit the configuration files:**
   - `_src/_examples/my-new-example/configs/app-config.yaml` - RHDH app configuration
   - `_src/_examples/my-new-example/helm/patches/values.yaml` - Helm values overrides
   - `_src/_examples/my-new-example/operator/patches/rhdh.yaml` - Operator CR patches
   - `_src/_examples/my-new-example/README.md.tmpl` - Documentation template

3. **Build the example:**
   ```bash
   ./build.sh my-new-example
   ```

4. **Test the deployment** on an OpenShift cluster

5. **Commit your changes** (both `_src/` and `examples/`)

### Build Commands

```bash
cd _src

# Build all examples
./build.sh

# Build a specific example
./build.sh using-single-psql-db

# List available examples
./build.sh list

# Clean generated examples
./build.sh clean

# Validate examples
./validate.sh
```

### How It Works

The build system reduces code duplication by:

1. **Shared Base Configs** (`_src/_base/configs/`) - Common app-config.yaml, dynamic-plugins.yaml, and secrets.env used by all examples

2. **Deployment Base** (`_src/_base/helm/` and `_src/_base/operator/`) - Shared install scripts, kustomization files, and base resource definitions

3. **Example Patches** (`_src/_examples/<name>/`) - Only the configuration differences specific to each example

4. **YAML Merging** - Base configs are merged with example patches using `yq`

5. **Templated READMEs** - Documentation uses `{{include:path}}` syntax to embed config snippets, keeping docs in sync with actual configs

### Template Syntax

README templates support including file contents:

```markdown
The configuration looks like this:

\`\`\`yaml
{{include:configs/app-config.yaml}}
\`\`\`
```

Files are looked up in order:
1. Example directory (`_src/_examples/<name>/`)
2. Base directory (`_src/_base/`)

## References

- [Red Hat Developer Hub Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/)
- [Backstage Documentation](https://backstage.io/docs/)
- [RHDH Helm Chart](https://github.com/redhat-developer/rhdh-chart)
- [RHDH Operator](https://github.com/redhat-developer/rhdh-operator)
