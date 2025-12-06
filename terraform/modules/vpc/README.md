# VPC Module

Creates VPC, subnets, internet gateway, and route tables for LocalStore Platform.

## Resources Created

- VPC
- Public subnet(s)
- Private subnet(s) (optional)
- Internet Gateway
- Route tables
- NAT Gateway (optional, for production)

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment name | string | required |
| vpc_cidr | VPC CIDR block | string | "10.0.0.0/16" |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_id | Public subnet ID |
