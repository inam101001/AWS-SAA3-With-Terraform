# ============================================
# Terraform Configuration
# ============================================
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
      ManagedBy = "Terraform"
      Project = "SAA-C03-Prep"
      Topic = "IAM"
    }
  }
}

# ============================================
# TASK 1: IAM USERS
# ============================================

# Create developer users
resource "aws_iam_user" "developers" {
    for_each = toset(var.developer_users)

    name = each.value
    path = "/developers/"

    tags = {
        Role = "Developers"
    }
}

# Create admin users
resource "aws_iam_user" "admins" {
    for_each = toset(var.admin_users)

    name = each.value
    path = "/admins/"

    tags = {
        Role = "Administrator"
    }
}

# ============================================
# TASK 2: IAM GROUPS
# ============================================

# Developers Group
resource "aws_iam_group" "developers" {
    name = "developers"
    path = "/"
}

# Administrators Group
resource aws_iam_group "administrators" {
    name = "administrators"
    path = "/"
}

# Read-Only Users Group
resource aws_iam_group "readonly" {
    name = "readonly-users"
    path = "/"
}

# ============================================
# TASK 3: GROUP MEMBERSHIP
# ============================================

# Add developer users to developers group
resource "aws_iam_user_group_membership" "developers" {
    for_each = toset(var.developer_users)

    user = aws_iam_user.developers[each.value].name

    groups = [
        aws_iam_group.developers.name
    ]
}

# Add admin users to administrators group
resource "aws_iam_user_group_membership" "admins" {
    for_each = toset(var.admin_users)

    user = aws_iam_user.admins[each.value].name

    groups = [
        aws_iam_group.administrators.name
    ]
}