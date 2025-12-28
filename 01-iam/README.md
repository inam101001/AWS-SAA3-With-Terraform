# IAM - Identity and Access Management

## Overview
This folder contains Terraform configurations for AWS IAM resources including users, groups, policies, roles, and account settings.

**Cost:** ✅ **100% FREE** - IAM has no charges

---

## Architecture Diagram

### User & Group Structure
```
┌──────────────────┐
│  IAM Users       │
│  - dev-alice     │ ───┐
│  - dev-bob       │ ───┤ (Membership)
│  - admin-john    │ ─┐ │
└──────────────────┘  │ │
                      ↓ ↓
┌──────────────────┐  Groups inherit policies
│  IAM Groups      │  ↓
│  - developers    │ ← [S3 Read, EC2 Read]
│  - admins        │ ← [AdminAccess]
│  - readonly      │ ← [ReadOnlyAccess]
└──────────────────┘
```

### Roles & Instance Profiles
```
┌────────────────────────────────────┐
│  IAM Roles (For AWS Services)      │
│                                     │
│  EC2 Role                          │
│    ├─ Trust: ec2.amazonaws.com     │
│    ├─ Permissions: S3 ReadOnly     │
│    └─ Instance Profile: Wrapper    │
│                                     │
│  Lambda Role                       │
│    ├─ Trust: lambda.amazonaws.com  │
│    └─ Permissions: CloudWatch Logs │
│                                     │
│  Cross-Account Role                │
│    ├─ Trust: External Account      │
│    └─ Permissions: ReadOnly        │
└────────────────────────────────────┘
```

---

## Tasks Completed

### Task 1: IAM Users
**Resource:** `aws_iam_user` (Official AWS Resource)

**What it does:** Creates individual IAM user identities

**Required Parameters:**
- `name` - Username (string)

**Optional Parameters:**
- `path` - Organizational path (string, default: `/`)
- `tags` - Key-value metadata (map)

**Key Concepts:**
- Used `for_each` to create multiple users from a list
- Organized users with paths (`/developers/`, `/admins/`)

**Files:** `main.tf`, `variables.tf`, `outputs.tf`

---

### Task 2: IAM Groups
**Resource:** `aws_iam_group` (Official AWS Resource)

**What it does:** Creates groups to organize users

**Required Parameters:**
- `name` - Group name (string)

**Optional Parameters:**
- `path` - Organizational path (string, default: `/`)

**Key Concepts:**
- Created individual resources (no loops) for known groups
- Groups are containers for users and policies

**Files:** `main.tf`, `outputs.tf`

---

### Task 3: Group Membership
**Resource:** `aws_iam_user_group_membership` (Official AWS Resource)

**What it does:** Adds users to groups (relationship resource)

**Required Parameters:**
- `user` - Username (string)
- `groups` - List of group names (list of strings)

**Key Concepts:**
- Relationship resource (connects users to groups)
- Used `for_each` to create memberships for each user
- Implicit dependencies on both users and groups

**Files:** `main.tf`

---

### Task 4: Custom IAM Policies
**Resource:** `aws_iam_policy` (Official AWS Resource)

**What it does:** Defines custom permission policies

**Required Parameters:**
- `name` - Policy name (string)
- `policy` - JSON policy document (string)

**Optional Parameters:**
- `description` - Policy description (string)
- `path` - Organizational path (string, default: `/`)
- `tags` - Key-value metadata (map)

**Key Concepts:**
- Used `jsonencode()` to convert HCL to JSON
- Policy structure: Version, Statement, Effect, Action, Resource
- Created S3 and EC2 read-only policies

**Files:** `main.tf`, `outputs.tf`

---

### Task 5: Attach Policies to Groups
**Resource:** `aws_iam_group_policy_attachment` (Official AWS Resource)

**What it does:** Attaches managed policies to groups

**Required Parameters:**
- `group` - Group name (string)
- `policy_arn` - Policy ARN (string)

**Key Concepts:**
- Attached both AWS managed and custom policies
- Multiple attachments to same group (permissions are additive)
- Implicit dependencies on groups and policies

**Files:** `main.tf`, `outputs.tf`

---

### Task 6: IAM Roles
**Resource:** `aws_iam_role` (Official AWS Resource)

**What it does:** Creates roles for AWS services or cross-account access

**Required Parameters:**
- `name` - Role name (string)
- `assume_role_policy` - Trust policy in JSON (string)

**Optional Parameters:**
- `description` - Role description (string)
- `max_session_duration` - Max session time in seconds (number, default: 3600)
- `tags` - Key-value metadata (map)

**Key Concepts:**
- **Trust Policy** (assume_role_policy): WHO can use the role
- **Permission Policy** (attached separately): WHAT the role can do
- Created roles for EC2, Lambda, and cross-account access
- Used `aws_iam_role_policy_attachment` to attach permissions

**Files:** `main.tf`, `variables.tf`, `outputs.tf`

---

### Task 7: Instance Profiles
**Resource:** `aws_iam_instance_profile` (Official AWS Resource)

**What it does:** Wraps IAM roles for EC2 instance attachment

**Required Parameters:**
- `name` - Instance profile name (string)
- `role` - Role name (string)

**Key Concepts:**
- Instance profiles are EC2-specific wrappers for roles
- One-to-one relationship with roles
- EC2 instances attach instance profiles, not roles directly

**Files:** `main.tf`, `outputs.tf`

---

### Task 8: Account Password Policy
**Resource:** `aws_iam_account_password_policy` (Official AWS Resource)

**What it does:** Sets account-wide password requirements

**Required Parameters:** None (all are optional, but you should set them)

**Key Optional Parameters:**
- `minimum_password_length` - Minimum chars (number, default: 8)
- `require_lowercase_characters` - Require a-z (bool, default: false)
- `require_uppercase_characters` - Require A-Z (bool, default: false)
- `require_numbers` - Require 0-9 (bool, default: false)
- `require_symbols` - Require !@#$ (bool, default: false)
- `allow_users_to_change_password` - User can change own password (bool, default: true)
- `max_password_age` - Days until expiration (number, default: 0 = never)
- `password_reuse_prevention` - Number of passwords to remember (number, default: 0)
- `hard_expiry` - Prevent login after expiration (bool, default: false)

**Key Concepts:**
- Singleton resource (only one per account)
- Applies to all IAM users in the account
- Security and compliance best practice

**Files:** `main.tf`, `outputs.tf`

---

## Key Terraform Concepts Used

### 1. **for_each Loop**
Used in: Users, Group Memberships
```hcl
for_each = toset(var.developer_users)
```
Creates multiple resources from a set/map.

### 2. **for Expression**
Used in: Outputs
```hcl
{ for k, v in aws_iam_user.developers : k => v.arn }
```
Transforms collections into new data structures.

### 3. **jsonencode() Function**
Used in: Policies, Roles
```hcl
policy = jsonencode({ Version = "2012-10-17", ... })
```
Converts HCL to JSON for AWS policy documents.

### 4. **Resource References**
```hcl
aws_iam_group.developers.name
aws_iam_policy.s3_specific_bucket_read.arn
```
Links resources together, creates implicit dependencies.

### 5. **Variable Validation** (Terraform 004 Feature)
Used in: `trusted_account_id` variable
```hcl
validation {
  condition     = can(regex("^[0-9]{12}$", var.trusted_account_id))
  error_message = "Account ID must be exactly 12 digits."
}
```
Validates input before execution.

### 6. **Implicit Dependencies**
Terraform automatically determines resource creation order from references.

---

## Resource Summary

| Resource Type | Count | Purpose |
|---------------|-------|---------|
| `aws_iam_user` | 3 | Individual user identities |
| `aws_iam_group` | 3 | User collections |
| `aws_iam_user_group_membership` | 3 | User-to-group relationships |
| `aws_iam_policy` | 2 | Custom permissions (S3, EC2) |
| `aws_iam_group_policy_attachment` | 4 | Attach policies to groups |
| `aws_iam_role` | 3 | Roles for services/cross-account |
| `aws_iam_role_policy_attachment` | 3 | Attach policies to roles |
| `aws_iam_instance_profile` | 1 | EC2 role wrapper |
| `aws_iam_account_password_policy` | 1 | Account password rules |
| **Total** | **23** | |

---

## Files Structure
```
01-iam/
├── main.tf                  # All IAM resources
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars         # Variable values (gitignored)
└── README.md                # This file
```

---

## Usage

### Initialize
```bash
terraform init
```

### Plan
```bash
terraform plan
```

### Apply
```bash
terraform apply
```

### View Outputs
```bash
terraform output
terraform output iam_roles
terraform output ec2_instance_profile
```

### Destroy (if needed)
```bash
terraform destroy
```

---

## SAA-C03 Exam Key Points

### Users, Groups, Policies
- ✅ Manage permissions via groups, not individual users
- ✅ Principle of least privilege
- ✅ Policy evaluation: Explicit Deny > Allow > Default Deny

### Roles
- ✅ Use roles for AWS services (EC2, Lambda, etc.)
- ✅ Roles provide temporary credentials (auto-rotate)
- ✅ Trust policy = WHO can assume
- ✅ Permission policy = WHAT they can do

### Cross-Account Access
- ✅ Use roles with trust policies
- ✅ External ID prevents "confused deputy" problem

### Best Practices
- ✅ Enable MFA for privileged users
- ✅ Rotate credentials regularly
- ✅ Use instance profiles for EC2 (not access keys)
- ✅ Monitor with CloudTrail
- ✅ Strong password policy

---

## Common AWS Managed Policies Used

- `AdministratorAccess` - Full access to all services
- `ReadOnlyAccess` - View all resources, no modifications
- `AmazonS3ReadOnlyAccess` - Read S3 buckets and objects
- `AWSLambdaBasicExecutionRole` - Lambda CloudWatch logging

---

## What's Next?

After mastering IAM, you can:
- Create S3 buckets and use the policies
- Launch EC2 instances with the instance profile
- Create Lambda functions with the execution role
- Set up VPCs with proper security groups

IAM is foundational - you'll reference these resources in almost every AWS service!

---

## Notes

- All IAM resources are **global** (not region-specific)
- IAM is **eventually consistent** (changes may take a few seconds)
- Maximum 5000 users per AWS account
- Maximum 300 groups per AWS account
- Users can be in maximum 10 groups
- Maximum 10 managed policies per user/group/role

---

**Created:** December 2025  
**Terraform Version:** >= 1.0  
**AWS Provider Version:** ~> 5.0