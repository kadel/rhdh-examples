# Backstage RDS Terraform Setup

This directory contains Terraform configuration to provision a **publicly accessible** AWS RDS PostgreSQL database tailored for Backstage testing/development.

**⚠️ WARNING: NOT FOR PRODUCTION USE**
- The database is publicly accessible (0.0.0.0/0).
- Backups are disabled.
- Secrets Manager integration is disabled (password is in Terraform state).
- SSL is enforced.

## Prerequisites

1.  **Terraform**: Ensure you have Terraform installed (v1.0+).
2.  **AWS Credentials**: You need an IAM user with sufficient permissions (VPC, RDS, IAM, KMS). Export your credentials:

    ```bash
    export AWS_ACCESS_KEY_ID="<YOUR_ACCESS_KEY_ID>"
    export AWS_SECRET_ACCESS_KEY="<YOUR_SECRET_ACCESS_KEY>"
    ```

## Deployment

1.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

2.  **Apply Configuration**:
    ```bash
    terraform apply
    ```
    Type `yes` when prompted.

## Outputs

After a successful apply, Terraform will output:
- `rds_endpoint`: The hostname and port of the database.
- `vpc_id`: The ID of the created VPC.
- `db_password`: The auto-generated master password (marked as sensitive).

## Connecting to the Database

Ensure you have the PostgreSQL client installed. The RDS instance will create a default database (typically `postgres`). You can use the following script block to retrieve the credentials and connect immediately to the default database:

```bash
# Retrieve credentials from Terraform output
export DB_PASSWORD=$(terraform output -raw db_password)
export DB_HOST=$(terraform output -raw rds_endpoint | cut -d: -f1)

# Connect to the default PostgreSQL database
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" \
  -p 5432 \
  -U postgres \
  -d "dbname=postgres sslmode=require"
```

*Note: `sslmode=require` is mandatory because the RDS instance is configured to enforce SSL. 

or use 
```
    8       ssl:
    9         # Important: You must replace 'path/to/your/global-bundle.pem'
   10         # with the actual absolute or relative path to where you saved the file.
   11         # For example, if you saved it in <backstage_root>/certs/global-bundle.pem
   12         # and your app-config.yaml is also in the root, it might be 'certs/global-bundle.pem'
   13         ca: './path/to/your/global-bundle.pem'
   14         # Set to true because you are now providing a trusted CA bundle
   15         rejectUnauthorized: true
```


## Clean Up

To destroy all resources and avoid costs:

```bash
terraform destroy
```
Type `yes` when prompted.
