# LocalStore Platform - Outputs

output "environment" {
  description = "Current environment (workspace)"
  value       = terraform.workspace
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

# EC2 Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "EC2 instance public DNS"
  value       = module.ec2.public_dns
}

# Connection info
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.ec2.public_ip}"
}

# Resource Group Outputs
output "resource_group_name" {
  description = "AWS Resource Group name for cost management"
  value       = module.resource_group.resource_group_name
}

output "resource_group_arn" {
  description = "AWS Resource Group ARN"
  value       = module.resource_group.resource_group_arn
}

# CloudFlare Outputs
output "api_hostname" {
  description = "API hostname (CloudFlare managed)"
  value       = module.cloudflare_dns.api_hostname
}

output "api_url" {
  description = "API URL (HTTPS via CloudFlare)"
  value       = "https://${module.cloudflare_dns.api_hostname}"
}
