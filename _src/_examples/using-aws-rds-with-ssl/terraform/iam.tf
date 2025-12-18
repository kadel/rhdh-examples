# This role is for the Backstage application (running on EC2, ECS, or EKS)
# to assume so it can retrieve the database credentials.

resource "aws_iam_role" "backstage_app_role" {
  name = "${var.project_name}-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" # Change to ecs-tasks.amazonaws.com for ECS
        }
      }
    ]
  })

      tags = {

        Name = "${var.project_name}-${var.environment}-app-role"

      }

    }

    

    # Policy to allow decrypting with the specific key

    # Secrets Manager permissions removed since we are using random_password

    resource "aws_iam_policy" "backstage_db_access" {

      name        = "${var.project_name}-${var.environment}-db-access-policy"

      description = "Allow Backstage to decrypt KMS key"

    

      policy = jsonencode({

        Version = "2012-10-17"

        Statement = [

          {

            Effect = "Allow"

            Action = [

              "kms:Decrypt",

              "kms:GenerateDataKey"

            ]

            Resource = aws_kms_key.rds.arn

          }

        ]

      })

    }

    

    resource "aws_iam_role_policy_attachment" "attach_db_access" {

      role       = aws_iam_role.backstage_app_role.name

      policy_arn = aws_iam_policy.backstage_db_access.arn

    }

    

  