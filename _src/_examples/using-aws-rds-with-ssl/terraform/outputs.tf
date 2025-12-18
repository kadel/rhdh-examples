output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "rds_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.default.endpoint
}

output "db_password" {
  description = "The master password for the database"
  value       = random_password.master.result
  sensitive   = true
}

output "backstage_app_role_arn" {
  description = "The ARN of the IAM role for the Backstage application"
  value       = aws_iam_role.backstage_app_role.arn
}