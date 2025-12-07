# Outputs for resource-group module

output "resource_group_arn" {
  description = "ARN of the Resource Group"
  value       = aws_resourcegroups_group.localstore.arn
}

output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = aws_resourcegroups_group.localstore.name
}
