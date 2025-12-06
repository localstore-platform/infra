# Terraform Modules

Reusable Terraform modules for LocalStore Platform infrastructure.

## Available Modules

### vpc

Creates VPC, subnets, internet gateway, and route tables.

### ec2

Creates EC2 instances with security groups.

### rds (Planned)

Creates RDS PostgreSQL instances for production scaling.

### s3 (Planned)

Creates S3 buckets for static assets and backups.

## Usage

Modules are called from the root `main.tf` using workspace-based configuration:

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment = terraform.workspace  # dev, staging, or prod
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region
}

module "ec2" {
  source = "./modules/ec2"
  
  environment   = terraform.workspace
  instance_type = local.current_config.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  key_name      = var.key_name
  admin_ip      = var.admin_ip
  create_eip    = local.current_config.create_eip
}
```

See [../WORKSPACES.md](../WORKSPACES.md) for workspace usage guide.
