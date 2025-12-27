# Output ARNs of developer users
output "developer_user_arns" {
    description = "ARNs of developer IAM users created"
    value = { for k, v in aws_iam_user.developers : k => v.arn }
}

# Output ARNs of admin users
output "admin_user_arns" {
    description = "ARNs of admin IAM users created"
    value = { for k, v in aws_iam_user.admins : k => v.arn }
}