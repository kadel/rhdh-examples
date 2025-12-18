variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name to be used for naming resources"
  type        = string
  default     = "backstage"
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    ManagedBy = "Terraform"
    Project   = "Backstage"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
