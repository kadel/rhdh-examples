# Default RHDH Installation

This example provides a minimal default installation of Red Hat Developer Hub (RHDH) with no additional configuration. It uses the built-in local PostgreSQL database and enables guest authentication for development purposes.

## What's Included

- **Local PostgreSQL Database**: Uses the built-in local database (no external database setup required)
- **Guest Authentication**: Enabled for development/testing (not recommended for production)
- **Route Enabled**: Exposes RHDH via an OpenShift route

## Configuration

The default app configuration:

```yaml
app:
  title: My RHDH App

auth:
  providers:
    guest:
      dangerouslyAllowOutsideDevelopment: true
```

## Installation

Choose either Helm or Operator-based deployment:

### Using Helm

```bash
cd helm
./install.sh
```

### Using the RHDH Operator

```bash
cd operator
./install.sh
```

## Uninstallation

### Using Helm

```bash
cd helm
./uninstall.sh
```

### Using the RHDH Operator

```bash
cd operator
./uninstall.sh
```

## Next Steps

This default installation is suitable for development and testing. For production deployments, consider:

- [Using an external PostgreSQL database](../using-single-psql-db/)
- Configuring proper authentication (GitHub, GitLab, OIDC, etc.)
- Setting up TLS certificates
- Configuring dynamic plugins

## References

- [RHDH Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub)
- [Backstage Documentation](https://backstage.io/docs)
