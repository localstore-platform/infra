# EC2 Module Variables

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.small"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2 instance"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "admin_ip" {
  type        = string
  description = "Admin IP for SSH access (CIDR format, e.g., 1.2.3.4/32)"
}

variable "create_eip" {
  type        = bool
  description = "Create Elastic IP for instance"
  default     = true
}
