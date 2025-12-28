# Output ARNs of developer users
output "developer_user_arns" {
  description = "ARNs of developer IAM users created"
  value       = { for k, v in aws_iam_user.developers : k => v.arn }
}

# Output ARNs of admin users
output "admin_user_arns" {
  description = "ARNs of admin IAM users created"
  value       = { for k, v in aws_iam_user.admins : k => v.arn }
}

# Output group information
output "iam_groups" {
  description = "IAM groups created with their ARNs"
  value = {
    developers     = aws_iam_group.developers.arn
    administrators = aws_iam_group.administrators.arn
    readonly       = aws_iam_group.readonly.arn
  }
}

# Output custom policy ARNs
output "custom_policies" {
  description = "Custom IAM policies created with their ARNs"
  value = {
    s3_bucket_read = aws_iam_policy.s3_specific_bucket_read.arn
    ec2_readonly   = aws_iam_policy.ec2_readonly.arn
  }
}

# Output policy attachments summary
output "group_policy_attachments" {
  description = "Summary of which policies are attached to which groups"
  value = {
    administrators = {
      group = aws_iam_group.administrators.name
      policies = [
        "AdministratorAccess (AWS Managed)"
      ]
    }
    developers = {
      group = aws_iam_group.developers.name
      policies = [
        aws_iam_policy.s3_specific_bucket_read.name,
        aws_iam_policy.ec2_readonly.name
      ]
    }
    readonly = {
      group = aws_iam_group.readonly.name
      policies = [
        "ReadOnlyAccess (AWS Managed)"
      ]
    }
  }
}