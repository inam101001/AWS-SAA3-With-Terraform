# ============================================
# Terraform Configuration
# ============================================
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# AWS Provider Configuration
# ============================================
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to ALL resources created by this provider
  default_tags {
    tags = {
      Environment = "Learning"
      ManagedBy   = "Terraform"
      Project     = "SAA-C03-Prep"
      Topic       = "IAM"
    }
  }
}