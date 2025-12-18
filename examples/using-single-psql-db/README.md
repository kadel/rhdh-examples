# Using a Single PostgreSQL Database with RHDH

By default, RHDH (Red Hat Developer Hub / Backstage) creates **multiple databases** - one for each plugin that requires database storage. This requires the database user to have permissions to create new databases.

In many production environments, this is not allowed due to security policies. To work around this, you can configure RHDH to use a **single database** with separate **schemas** for each plugin instead.

## Key Configuration

The key setting is `pluginDivisionMode: schema` which tells RHDH to use schemas instead of separate databases for plugin data isolation.
Additionally, `ensureSchemaExists: true` ensures that the required schemas are created if they don't already exist.

```yaml
backend:
  database:
    client: pg
    pluginDivisionMode: schema
    ensureSchemaExists: true
    connection:
      database: ${POSTGRES_DATABASE}
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
```


## Database Requirements

When using `pluginDivisionMode: schema`, the database user needs:

- **CREATE** privilege on the database (to create schemas)
- **USAGE** privilege on schemas
- **CREATE** privilege on schemas (for tables)

Due to the nature of the Backstage architecture the user requires permissions to schemas and tables.
This is due to the fact that Backstage plugins are installed as separate entities and each plugin has its own schema.
Without these permissions the plugins requiring database will not be able to install and will fail.

The user does **NOT** need:
- CREATEDB privilege
- Access to the `postgres` default database

### Granting Privileges

Run the following SQL commands as a database administrator to set up the user and grant the necessary privileges:

```sql
-- Create the database user (if not already created)
CREATE USER rhdh_user WITH PASSWORD 'changeme';

-- Create the database for RHDH
CREATE DATABASE rhdh_db;

-- Grant CREATE privilege on the database (allows creating schemas)
GRANT CREATE ON DATABASE rhdh_db TO rhdh_user;
```

Replace `rhdh_user` and `rhdh_db` with your actual username and database name.


## References

- [Backstage: Switching from SQLite to PostgreSQL](https://backstage.io/docs/tutorials/switching-sqlite-postgres/#using-a-single-database)
- [RHDH: Configuring External PostgreSQL](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html/configuring_red_hat_developer_hub/configuring-external-postgresql-databases)
