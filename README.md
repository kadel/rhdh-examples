# RHDH Examples

A collection of examples demonstrating various configurations and deployment patterns for Red Hat Developer Hub (RHDH).

## Documentation

| Guide | Description |
|-------|-------------|
| [Plugin Development Getting Started](docs/plugin-getting-started.md) | Complete guide for creating, developing, and packaging dynamic plugins for RHDH |

## Examples

| Example | Description |
|---------|-------------|
| [using-aws-rds-with-ssl](examples/using-aws-rds-with-ssl/) | Configure RHDH to use an AWS RDS PostgreSQL database with SSL connection |
| [using-single-psql-db](examples/using-single-psql-db/) | Configure RHDH to use a single PostgreSQL database with schemas |

Each example includes:
- **README.md** - Documentation and explanation
- **helm/** - Helm-based deployment
- **operator/** - RHDH Operator-based deployment (⚠️ **WORK IN PROGRESS not tested yet** ⚠️)
