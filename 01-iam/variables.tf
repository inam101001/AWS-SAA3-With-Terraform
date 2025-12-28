variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "developer_users" {
  description = "List of IAM user names for developers"
  type        = list(string)
  default     = ["dev-alice", "dev-bob"]
}

variable "admin_users" {
  description = "List of IAM user names for administrators"
  type        = list(string)
  default     = ["admin-john"]
}

variable "trusted_account_id" {
  description = "AWS Account ID that can assume the cross-account role"
  type = string
  default = "123456789012"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.trusted_account_id))
    error_message = "Account ID must be exactly 12 digits."
  }
}