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
resource "aws_iam_group" "administrators" {
  name = "administrators"
  path = "/"
}

# Read-Only Users Group
resource "aws_iam_group" "readonly" {
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

# ============================================
# TASK 4: CUSTOM IAM POLICIES
# ============================================

# Policy 1: S3 Read-Only Access to specific buckets
resource "aws_iam_policy" "s3_specific_bucket_read" {
  name        = "S3SpecificBucketReadOnly"
  description = "Allows read-only access to specific buckets"
  path        = "/"

  # Policy document in JSON format
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::my-learning-bucket-*"
        ]
      },
      {
        Sid    = "GetObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::my-learning-bucket-*/*"
        ]
      }

    ]
  })

  tags = {
    Purpose = "Learning-S3-Access"
  }
}

# Policy 2: EC2 Read-Only Access
resource "aws_iam_policy" "ec2_readonly" {
  name        = "EC2ReadOnlyCustom"
  description = "Custom EC2 read-only permissions for viewing instances"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Purpose = "Learning-EC2-ReadOnly"
  }
}

# ============================================
# TASK 5: ATTACH POLICIES TO GROUPS
# ============================================

# Attach AWS Managed Policy to Administrators Group
resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.administrators.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Attach AWS Managed Policy to ReadOnly Group
resource "aws_iam_group_policy_attachment" "readonly_access" {
  group      = aws_iam_group.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Attach Custom S3 Policy to Developers Group
resource "aws_iam_group_policy_attachment" "developers_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_specific_bucket_read.arn
}

# Attach Custom EC2 Policy to Developers Group
resource "aws_iam_group_policy_attachment" "developers_ec2" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ec2_readonly.arn
}