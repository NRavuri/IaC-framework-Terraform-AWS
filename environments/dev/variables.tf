variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "iac-framework"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for compute resources"
  type        = string
  default     = "t3.micro"  # Using smaller instance type for dev environment
}

variable "enable_backup" {
  description = "Enable AWS Backup for resources"
  type        = bool
  default     = false  # Disabled by default in dev environment
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
} 