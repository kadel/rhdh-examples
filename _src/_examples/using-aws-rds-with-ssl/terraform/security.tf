resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound Rule: Allow PostgreSQL traffic (5432) from ANYWHERE
  # This makes the database publicly accessible.
  ingress {
    description = "PostgreSQL from Internet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}
