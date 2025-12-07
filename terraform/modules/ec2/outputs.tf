# EC2 Module Outputs

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "EC2 public IP (Elastic IP if created, otherwise instance IP)"
  value       = var.create_eip ? aws_eip.app[0].public_ip : aws_instance.app.public_ip
}

output "public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.app.public_dns
}

output "security_group_id" {
  description = "API security group ID"
  value       = aws_security_group.api.id
}
