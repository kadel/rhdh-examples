# Using a Single PostgreSQL Database with RHDH

By default, RHDH (Red Hat Developer Hub / Backstage) creates **multiple databases** - one for each plugin that requires database storage. This requires the database user to have permissions to create new databases.

In many production environments, this is not allowed due to security policies. To work around this, you can configure RHDH to use a **single database** with separate **schemas** for each plugin instead.

## Key Configuration

The key settings are:

- `pluginDivisionMode: schema`: Tells RHDH to use schemas instead of separate databases for plugin data isolation.
- `ensureSchemaExists: true`: Ensures that Backstage attempts to create the necessary schemas if they don't exist.

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
      ssl:
        sslmode: verify-full
        sslrootcert: /opt/app-root/src/global-bundle.pem
```

## Using SSL

Depending on the configuration of the database, you may need to use SSL to connect to the database.
If you are using AWS provided CA you will need to download the certificate bundle from https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html#UsingWithRDS.SSL.CertificatesAllRegions.
Mount it to the container and set the `ca` property in the `connection` section of the `app-config.yaml` file.


### Mounting the certificate bundle with Helm
``` yaml
upstream:
  postgresql:
    enabled: false

  backstage:
    # This is required in order to remove POSTGRESQL_ADMIN_PASSWORD from the environment variables
    # https://github.com/redhat-developer/rhdh-chart/blob/dba8d637567b430d6c0b95734b69198ac0b2eb4c/charts/backstage/values.yaml#L127-L137
    extraEnvVars:
      - name: BACKEND_SECRET
        valueFrom:
          secretKeyRef:
            key: backend-secret
            name: '{{ include "janus-idp.backend-secret-name" $ }}'
    extraVolumeMounts:
      # we need to copy whole extraVolumeMounts directory form original values.yaml beucase there is no way to 
      # easily extend arrays in helm
      - mountPath: /opt/app-root/src/dynamic-plugins-root
        name: dynamic-plugins-root
      - name: temp
        mountPath: /tmp
      #  this is what is specific to this example
      - mountPath: /opt/app-root/src/global-bundle.pem
        name: postgres-crt
        subPath: global-bundle.pem
    
    extraVolumes:
      # we need to copy whole extraVolumes directory form original values.yaml beucase there is no way to 
      # easily extend arrays in helm
      - ephemeral:
          volumeClaimTemplate:
            spec:
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 1Gi
        name: dynamic-plugins-root
      - configMap:
          defaultMode: 420
          name: dynamic-plugins
          optional: true
        name: dynamic-plugins
      - name: dynamic-plugins-npmrc
        secret:
          defaultMode: 420
          optional: true
          secretName: '{{ printf "%s-dynamic-plugins-npmrc" .Release.Name }}'
      - name: dynamic-plugins-registry-auth
        secret:
          defaultMode: 416
          optional: true
          secretName: '{{ printf "%s-dynamic-plugins-registry-auth" .Release.Name }}'
      - name: npmcacache
        emptyDir: {}
      - name: temp
        emptyDir: {}
      #  this is what is specific to this example
      - name: postgres-crt
        configMap:
          name: aws-rds-ca-bundle
```


## Database Requirements

When using `pluginDivisionMode: schema`, the database user needs:

- **CREATE** privilege on the database (to create schemas)
- **USAGE** privilege on schemas
- **CREATE** privilege on schemas (for tables)

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
## References

- [Backstage: Switching from SQLite to PostgreSQL](https://backstage.io/docs/tutorials/switching-sqlite-postgres/#using-a-single-database)
- [RHDH: Configuring External PostgreSQL](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.3/html/administration_guide_for_red_hat_developer_hub/assembly-configuring-external-postgresql-databases)
