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