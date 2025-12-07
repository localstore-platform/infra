# LocalStore Platform - Variables
# Workspace-based configuration for dev, staging, prod

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (overrides workspace default if set)"
  default     = ""
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for EC2 instances"
}

variable "admin_ip" {
  type        = string
  description = "Admin IP CIDR for SSH access (e.g., 1.2.3.4/32)"
  default     = "0.0.0.0/0" # Restrict in production!
}

variable "create_eip" {
  type        = bool
  description = "Create Elastic IP for consistent public IP (overrides workspace default if set)"
  default     = null
}

# Database variables (for future RDS module)
variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "localstore"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "localstore"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
  default     = "" # Must be provided via tfvars or environment
}

# CloudFlare variables
variable "cloudflare_proxied" {
  type        = bool
  description = "Enable CloudFlare proxy (provides free SSL, DDoS protection, CDN)"
  default     = true
}
