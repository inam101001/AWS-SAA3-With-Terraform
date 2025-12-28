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

# ============================================
# TASK 6: IAM ROLES
# ============================================

# Role 1: EC2 Role for S3 Access
resource "aws_iam_role" "ec2_s3_access" {
  name        = "EC2-S3-Access-Role"
  description = "Allows EC2 instances to access S3 buckets"

  # TRUST POLICY - Who can assume this role?
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Purpose = "EC2-Instance-S3-Access"
  }
}

# Attach permission policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2-s3-readonly" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Role 2: Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name        = "Lambda-Basic-Execution-Role"
  description = "Allows Lambda functions to write logs to CloudWatch"

  # TRUST POLICY - Lambda service can assume this
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Purpose = "Lambda-Execution"
  }
}

# Attach AWS managed Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Role 3: Cross-Account Access Role (Advanced)
resource "aws_iam_role" "cross_account_access" {
  name        = "Cross-Account-Access-Role"
  description = "Allows users from another AWS account to assume this role"

  # TRUST POLICY - Another AWS account can assume this
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "my-unique-external-id-12345"
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "Cross-Account-Access"
  }
}

# Attach read-only policy to cross-account role
resource "aws_iam_role_policy_attachment" "cross_account_readonly" {
  role       = aws_iam_role.cross_account_access.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ============================================
# TASK 7: INSTANCE PROFILE (Wrapper for EC2 Role)
# ============================================

# Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "EC2-S3-Instance-Profile"
  role = aws_iam_role.ec2_s3_access.name

  tags = {
    Purpose = "Attach-EC2-Role-To-Instances"
  }
}

# ============================================
# TASK 8: ACCOUNT PASSWORD POLICY
# ============================================

resource "aws_iam_account_password_policy" "strict_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
  hard_expiry                    = false
}