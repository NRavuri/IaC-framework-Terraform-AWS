variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "enable_ssh_access" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = []
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring for instances"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "Duration in days before KMS key is deleted"
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation for KMS keys"
  type        = bool
  default     = true
} 