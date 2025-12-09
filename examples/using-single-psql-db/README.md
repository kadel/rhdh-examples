# Using a Single PostgreSQL Database with RHDH

By default, RHDH (Red Hat Developer Hub / Backstage) creates **multiple databases** - one for each plugin that requires database storage. This requires the database user to have permissions to create new databases.

In many production environments, this is not allowed due to security policies. To work around this, you can configure RHDH to use a **single database** with separate **schemas** for each plugin instead.

## Key Configuration

The key setting is `pluginDivisionMode: schema` which tells RHDH to use schemas instead of separate databases for plugin data isolation.

```yaml
backend:
  database:
    client: pg
    pluginDivisionMode: schema
    connection:
      database: ${POSTGRES_DB}
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
```

## Quick Start

### Using the RHDH Operator

```bash
cd operator/
./install.sh
```

### Using Helm

```bash
cd helm/
./install.sh
```

## Configuration Details

### Database Secret

Both deployment methods use the same secret structure:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rhdh-database-secret
type: Opaque
stringData:
  POSTGRES_DB: rhdh
  POSTGRES_HOST: my-postgres.postgres.svc
  POSTGRES_PORT: "5432"
  POSTGRES_USER: rhdh_user
  POSTGRES_PASSWORD: changeme


```

### Operator: Backstage CR Patch

The operator deployment patches the base Backstage CR to:
- Add the database secret to environment variables
- Add a database-specific ConfigMap
- Disable the local database

```yaml
apiVersion: rhdh.redhat.com/v1alpha3
kind: Backstage
metadata:
  name: my-rhdh
spec:
  application:
    appConfig:
      mountPath: /opt/app-root/src
      configMaps:
        - name: my-rhdh-app-config
        - name: my-rhdh-db-config
    extraEnvs:
      secrets:
        - name: my-rhdh-secrets
        - name: rhdh-database-secret
  database:
    enableLocalDb: false
```

### Helm: Values Overlay

The helm deployment merges these values with the base configuration:

```yaml
global:
  dynamic:
    includes:
      - dynamic-plugins.default.yaml
    plugins: []

upstream:
  backstage:
    appConfig:
      backend:
        database:
          client: pg
          pluginDivisionMode: schema
          connection:
            database: ${POSTGRES_DB}
            host: ${POSTGRES_HOST}
            port: ${POSTGRES_PORT}
            user: ${POSTGRES_USER}
            password: ${POSTGRES_PASSWORD}

    extraEnvVarsSecrets:
      - rhdh-database-secret

  postgresql:
    enabled: false


```

## Database Requirements

When using `pluginDivisionMode: schema`, the database user needs:

- **CREATE** privilege on the database (to create schemas)
- **USAGE** privilege on schemas
- **CREATE** privilege on schemas (for tables)

The user does **NOT** need:
- CREATEDB privilege
- Access to the `postgres` default database

## Troubleshooting

### Error: no pg_hba.conf entry

```
Error: no pg_hba.conf entry for host "x.x.x.x", user "user", database "dbname", no encryption
```

This error means PostgreSQL is rejecting non-SSL connections. Solutions:
1. Enable SSL in your RHDH configuration (recommended)
2. Modify `pg_hba.conf` to allow non-SSL connections (not recommended for production)

### Verifying the Connection

You can test the connection from a pod in the same namespace:

```bash
psql "host=${POSTGRES_HOST} port=${POSTGRES_PORT} dbname=${POSTGRES_DB} user=${POSTGRES_USER} sslmode=require"
```

## References

- [Backstage: Switching from SQLite to PostgreSQL](https://backstage.io/docs/tutorials/switching-sqlite-postgres/#using-a-single-database)
- [RHDH: Configuring External PostgreSQL](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.3/html/administration_guide_for_red_hat_developer_hub/assembly-configuring-external-postgresql-databases)
