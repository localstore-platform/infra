# LocalStore Platform - Terraform Configuration
# Uses workspaces to manage environments: dev, staging, prod
#
# Usage:
#   terraform workspace new dev
#   terraform workspace select dev
#   terraform plan -var-file="tfvars/dev.tfvars"
#   terraform apply -var-file="tfvars/dev.tfvars"

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # Remote state with workspace-based key
  # Uses S3-native locking (use_lockfile) instead of DynamoDB
  backend "s3" {
    bucket       = "localstore-terraform-state"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
    # State file path: localstore-terraform-state/env:/{workspace}/terraform.tfstate
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# CloudFlare provider - uses CLOUDFLARE_API_TOKEN env var
provider "cloudflare" {}

# Local values with workspace-aware naming
locals {
  environment = terraform.workspace

  common_tags = {
    Project     = "Local Store Platform"
    Environment = "${local.environment}"
    ManagedBy   = "terraform"
    Workspace   = "${terraform.workspace}"
  }

  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type = "t2.micro"
      create_eip    = false
      min_size      = 1
      max_size      = 1
    }
    staging = {
      instance_type = "t2.small"
      create_eip    = true
      min_size      = 1
      max_size      = 2
    }
    prod = {
      instance_type = "t2.small"
      create_eip    = true
      min_size      = 1
      max_size      = 3
    }
  }

  # Get current environment config, fallback to dev
  current_config = lookup(local.env_config, local.environment, local.env_config["dev"])
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment = local.environment
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  environment   = local.environment
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  instance_type = var.instance_type != "" ? var.instance_type : local.current_config.instance_type
  key_name      = var.key_name
  admin_ip      = var.admin_ip
  create_eip    = var.create_eip != null ? var.create_eip : local.current_config.create_eip
}

# Resource Group Module - for cost management via AWS Systems Manager
module "resource_group" {
  source = "./modules/resource-group"

  environment = local.environment
}

# CloudFlare DNS Module - manages DNS records and enables proxy (SSL, DDoS, CDN)
module "cloudflare_dns" {
  source = "./modules/cloudflare-dns"

  environment = local.environment
  origin_ip   = module.ec2.public_ip
  proxied     = var.cloudflare_proxied
}
