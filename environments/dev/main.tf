locals {
  environment = "dev"
  region     = "us-east-1"
}

module "networking" {
  source = "../../modules/networking"

  environment = local.environment
  vpc_cidr    = "10.0.0.0/16"
  
  # Reduce to single public subnet for free tier
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = []  # Remove private subnets as they require NAT Gateway
  
  enable_nat_gateway  = false  # Disable NAT Gateway
  single_nat_gateway = false   # Disable NAT Gateway

  tags = {
    Environment = local.environment
    Terraform   = "true"
  }
}

# Security group for common services
resource "aws_security_group" "common" {
  name        = "${local.environment}-common-sg"
  description = "Common security group for ${local.environment} environment"
  vpc_id      = module.networking.vpc_id

  # Allow internal VPC traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.networking.vpc_cidr]
    description = "Allow internal VPC traffic"
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${local.environment}-common-sg"
    Environment = local.environment
  }
}

# S3 bucket for application assets (Free tier eligible)
resource "aws_s3_bucket" "assets" {
  bucket = "${local.environment}-app-assets-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = local.environment
  }
}

# Enable versioning (free feature)
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (free feature)
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add lifecycle rule to clean up old versions (cost control)
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {
      prefix = ""  # Apply to all objects
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {} 