resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_db_parameter_group" "default" {
  family = "postgres16"
  name   = "${var.project_name}-${var.environment}-pg"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "random_password" "master" {
  length  = 16
  special = false # Start simple to avoid connection string parsing issues
}

resource "aws_db_instance" "default" {
  identifier        = "${var.project_name}-${var.environment}-db"
  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  username = "postgres"
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.default.name

  # Security Best Practices
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds.arn
  publicly_accessible = true
  
  # Backups DISABLED
  backup_retention_period = 0
  backup_window           = "03:00-06:00"
  copy_tags_to_snapshot   = false
  
  # Maintenance
  auto_minor_version_upgrade = true
  
  # Deletion Protection
  deletion_protection = false 
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
